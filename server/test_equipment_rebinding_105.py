import copy
import json
import unittest
from collections import defaultdict
from pathlib import Path
from unittest.mock import patch

from battle_engine import base_unit
from gateway import load_game_config
from manual_ability_sim import SkillCompleteBattle
from equipment_bonds_104 import equipped_bonds, part_for_skill, skill_id
from equipment_rebinding_105 import SIX_STAR_REDESIGNS, load_plan
from native_skill_snapshot import _native_skill_snapshot
from skill_balance_overlay import _get, _set

ROOT = Path(__file__).resolve().parents[1]


class EquipmentRebindingTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with patch('equipment_rebinding_105.rebind_ordinary', lambda c, p: None), \
             patch('equipment_rebinding_105.apply_six_star_redesigns', lambda c, p: None), \
             patch('equipment_rebinding_105.rebind_new_skins', lambda c, p: None), \
             patch('equipment_rebinding_105.validate_bindings', lambda c: None):
            cls.before = load_game_config(ROOT/'config/reconstruction/full-config.json')['cfg']
        cls.cfg = load_game_config(ROOT/'config/reconstruction/full-config.json')['cfg']

    def test_every_equipment_one_to_three_owners_and_user_assignments(self):
        c = self.cfg
        definitions = c['system_simple']['equipment_bonds_104']
        owners = defaultdict(set)
        for aid, rows in definitions.items():
            for row in rows:
                owners[row['equipment']].add(aid.rsplit('_', 1)[0])
        gear = {e for e, v in c['equip'].items() if v.get('quality') in (5, 6) and v.get('type') != 6}
        self.assertEqual(len(gear), 99)
        self.assertEqual(set(owners), gear)
        demonblade_items = {'E_1004_5', 'E_5001_5'}
        self.assertEqual({eid for eid, families in owners.items() if 'A_1803' in families}, demonblade_items)
        for eid, families in owners.items():
            extra_owners = {'A_1803'} if eid in demonblade_items else set()
            self.assertLessEqual(len(families - extra_owners), 3, eid)
        for row in load_plan()['pinned_assignments']:
            self.assertTrue(equipped_bonds(c, row['hero'], [row['equipment']]), row)
        for aid, rows in definitions.items():
            affinity_kinds = ('mechanic', 'stats') if aid in ('A_1803_5', 'A_1803_6') else ('ordinary', 'stats')
            ordinary = [r for r in rows if r['kind'] in affinity_kinds]
            self.assertEqual(len(ordinary), 2, aid)
            self.assertEqual(len({c['equip'][r['equipment']]['slot'] for r in ordinary}), 2, aid)
            self.assertEqual(len(rows), len({r['equipment'] for r in rows}), aid)

    def test_untouched_equipment_effects_and_growth_are_unchanged(self):
        redesigned = {(aid, eid) for aid, eid, *_ in SIX_STAR_REDESIGNS}
        for aid, rows in self.cfg['system_simple']['equipment_bonds_104'].items():
            old_rows = self.before['system_simple']['equipment_bonds_104'][aid]
            for row, old in zip(rows, old_rows):
                if row.get('passive_extra_105') or (aid, row['equipment']) in redesigned:
                    continue
                self.assertEqual(row['kind'], old['kind'])
                if row['kind'] == 'stats':
                    self.assertEqual(row['stats'], old['stats'])
                    continue
                if row['kind'] == 'mechanic':
                    self.assertEqual(row['mechanics'], old['mechanics'])
                    continue
                slot = {'normal': 10, 'captain': 11, 'passive': 13}.get(row.get('slot'), 10)
                sources = {self.cfg['avatar'][aid]['pl'][slot]}
                field = {10: 'skill', 11: 'leader_skill', 13: 'skillB'}[slot]
                sources.update(v[field] for v in self.cfg['system_simple']['bond_skill_variants_104'][aid].values() if field in v)
                for source in sources:
                    before = skill_id(self.before, aid, source, [old])
                    after = skill_id(self.cfg, aid, source, [row])
                    for level in (1, 10):
                        b = _native_skill_snapshot(self.before, before, level)
                        a = _native_skill_snapshot(self.cfg, after, level)
                        self.assertEqual(a['pl'], b['pl'], (aid, row['equipment']))
                        self.assertEqual(a['skills'], b['skills'], (aid, row['equipment'], level))
                        self.assertEqual(self.cfg['skill'][after].get('equipment_parts_104'), self.before['skill'][before].get('equipment_parts_104'))

    def test_redesigned_affinities_enhance_base_and_team_bond_versions(self):
        c = self.cfg
        simple = c['system_simple']
        slots = {'normal': (10, 'skill'), 'captain': (11, 'leader_skill'), 'passive': (13, 'skillB')}
        for aid, eid, slot, *_ in SIX_STAR_REDESIGNS:
            index, field = slots[slot]
            source = c['avatar'][aid]['pl'][index]
            sources = {source, *(v.get(field, source) for v in simple['bond_skill_variants_104'][aid].values())}
            rows = equipped_bonds(c, aid, [eid])
            self.assertEqual(rows[0]['slot'], slot)
            for sid in sources:
                with self.subTest(hero=aid, equipment=eid, skill=sid):
                    variant = skill_id(c, aid, sid, rows)
                    self.assertNotEqual(sid, variant)
                    effect = part_for_skill(c['skill'][sid], rows[0])
                    factor = 1 + effect['strength']
                    self.assertGreater(factor, 1)
                    for rank in (1, 10):
                        original = _native_skill_snapshot(c, sid, rank)
                        enhanced = _native_skill_snapshot(c, variant, rank)
                        self.assertEqual(original['pl'], enhanced['pl'])
                        actions = copy.deepcopy(original['skills'])
                        idx = effect['index']
                        if isinstance(idx, str):
                            self.assertAlmostEqual(c['skill'][variant]['equipment_parts_104'][idx], factor)
                        else:
                            for path in (effect['path'], *effect.get('extra_paths', ())):
                                value = _get(actions[idx], path)
                                self.assertGreater(value, 0)
                                _set(actions[idx], path, value * factor)
                        self.assertEqual(len(actions), len(enhanced['skills']))
                        for expected, actual in zip(actions, enhanced['skills']):
                            for x, y in zip(expected, actual):
                                if isinstance(x, (int, float)):
                                    self.assertAlmostEqual(x, y, places=7)
                                else:
                                    self.assertEqual(x, y)

    def test_new_manual_parts_change_battle_results_and_stack(self):
        def cast(aid, eids):
            c = self.cfg
            source = c['avatar'][aid]['pl'][10]
            sid = skill_id(c, aid, source, equipped_bonds(c, aid, eids))
            owner = base_unit(c, aid, 60, 7, overrides={'skill': _native_skill_snapshot(c, sid, 7)})
            enemy = base_unit(c, 'A_1001_6', 60, 1, team=2)
            owner.update(pos=1500, hp=owner['hp_max']//5)
            enemy.update(pos=1450, hp=10**7, hp_max=10**7)
            battle = SkillCompleteBattle([owner], [enemy], seed=7, config=c)
            owner, enemy = battle.a[0], battle.b[0]
            owner['_team'], enemy['_team'] = battle.a, battle.b
            before = owner['hp']
            self.assertTrue(battle._apply_native_skill(owner, battle.b, 'skill'))
            return 10**7 - enemy['hp'], [u['hp_max'] for u in battle.a[1:]], owner['hp'] - before

        base = cast('A_1005_6', [])
        weapon = cast('A_1005_6', ['E_1017_6'])
        summon = cast('A_1005_6', ['E_3010_6'])
        self.assertGreater(weapon[0], base[0])
        self.assertEqual(weapon[1], base[1])
        self.assertEqual(summon[0], base[0])
        self.assertGreater(summon[1][0], base[1][0])
        self.assertEqual(cast('A_1005_6', ['E_1017_6', 'E_3010_6']), (weapon[0], summon[1], base[2]))
        before = cast('A_1011_6', [])
        after = cast('A_1011_6', ['E_3004_5'])
        self.assertEqual(before[:2], after[:2])
        self.assertGreater(after[2], before[2])

    def test_annie_passive_requires_personal_core_and_keeps_other_skills(self):
        aid = 'A_1221_6'
        core = equipped_bonds(self.cfg, aid, ['E_4999_6'])
        self.assertEqual(len(core), 1)
        self.assertFalse(equipped_bonds(self.cfg, 'A_1029_6', ['E_4999_6'])[0].get('passive_extra_105'))
        normal, captain = self.cfg['avatar'][aid]['pl'][10:12]
        passive = self.cfg['avatar'][aid]['pl'][13]
        for sid in (normal, captain):
            self.assertEqual(skill_id(self.cfg, aid, sid, core), sid)
        self.assertEqual(skill_id(self.cfg, aid, passive, []), passive)
        revised = self.cfg['skill'][skill_id(self.cfg, aid, passive, core)]
        self.assertIn('不讲道理', revised['name'])
        self.assertEqual(revised['pl'][:2], [0, 1])
        self.assertEqual(revised['annie_core_105']['control_rounds'], 1)
        self.assertTrue(revised['annie_core_105']['stun_enabled'])
        self.assertFalse(self.cfg['skill'][passive]['annie_core_105']['stun_enabled'])
        for level in (1, 10):
            original = _native_skill_snapshot(self.cfg, passive, level)
            extra = _native_skill_snapshot(self.cfg, revised['id'], level)
            self.assertEqual(extra['skills'], original['skills'], 'the bond adds stun without changing other passive actions')
        self.assertIn('annie_companion_105', self.cfg['skill'][normal])

    def test_all_unequipped_hero_skills_keep_current_behavior(self):
        for aid, hero in self.cfg['avatar'].items():
            original = self.before['avatar'][aid]
            for slot in (10, 11, 13):
                if len(hero['pl']) <= slot or not hero['pl'][slot]:
                    continue
                before = self.before['skill'][original['pl'][slot]]
                after = self.cfg['skill'][hero['pl'][slot]]
                self.assertEqual(after['skill'], before['skill'], (aid, slot))
                self.assertEqual(after['pl'], before['pl'], (aid, slot))


if __name__ == '__main__':
    unittest.main()
