import copy
import json
import unittest
from collections import Counter
from pathlib import Path
from unittest.mock import patch

from gateway import load_game_config
from equipment_bonds_104 import equipped_bonds, skill_id
from equipment_rebinding_105 import load_plan
from native_skill_snapshot import _native_skill_snapshot

ROOT = Path(__file__).resolve().parents[1]


class EquipmentRebindingTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with patch('equipment_rebinding_105.rebind_ordinary', lambda c, p: None), \
             patch('equipment_rebinding_105.rebind_new_skins', lambda c, p: None), \
             patch('equipment_rebinding_105.validate_bindings', lambda c: None):
            cls.before = load_game_config(ROOT/'config/reconstruction/full-config.json')['cfg']
        cls.cfg = load_game_config(ROOT/'config/reconstruction/full-config.json')['cfg']

    def test_every_equipment_one_to_three_owners_and_user_assignments(self):
        c = self.cfg
        definitions = c['system_simple']['equipment_bonds_104']
        counts = Counter(r['equipment'] for rows in definitions.values() for r in rows)
        gear = {e for e, v in c['equip'].items() if v.get('quality') in (5, 6) and v.get('type') != 6}
        self.assertEqual(len(gear), 99)
        self.assertEqual(set(counts), gear)
        self.assertTrue(all(1 <= count <= 3 for count in counts.values()))
        for row in load_plan()['pinned_assignments']:
            self.assertTrue(equipped_bonds(c, row['hero'], [row['equipment']]), row)
        for aid, rows in definitions.items():
            ordinary = [r for r in rows if r['kind'] in ('ordinary', 'stats')]
            self.assertEqual(len(ordinary), 2, aid)
            self.assertEqual(len({c['equip'][r['equipment']]['slot'] for r in ordinary}), 2, aid)
            self.assertEqual(len(rows), len({r['equipment'] for r in rows}), aid)

    def test_non_annie_skill_effects_and_growth_are_unchanged(self):
        for aid, rows in self.cfg['system_simple']['equipment_bonds_104'].items():
            old_rows = self.before['system_simple']['equipment_bonds_104'][aid]
            for row, old in zip(rows, old_rows):
                if row.get('passive_extra_105'):
                    continue
                self.assertEqual(row['kind'], old['kind'])
                if row['kind'] == 'stats':
                    self.assertEqual(row['stats'], old['stats'])
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
