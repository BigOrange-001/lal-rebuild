import copy
import json
import unittest
from pathlib import Path
from gateway import Backend
from battle_engine import ReferenceBattle,base_unit,_native_skill_snapshot
from hero_packs_104 import ROOT,SKIN_FAMILIES,compile_builtin,apply_hero_packs_104
from skill_output_104 import output_paths
from recruit_exchange import daily_orange_pool


class HeroPacks104Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        path=ROOT.parent/'full-config.json'
        backend=Backend(':memory:',path);cls.cfg=copy.deepcopy(backend.config['cfg']);backend.db.close()

    def battle(self,aid,leader=False):
        a=base_unit(self.cfg,aid,60,10,0,.5,leader,1)
        b=base_unit(self.cfg,'A_1001_5',60,1,0,.5,False,2)
        b['hp']=b['hp_max']=10**8;b['pos']=a['pos']+40
        battle=ReferenceBattle([a],[b],config=self.cfg)
        battle.a[0]['_team']=battle.a;battle.b[0]['_team']=battle.b
        return battle,battle.a[0],battle.b[0]

    def test_event_summons_respect_conditions_capacity_and_no_recursion(self):
        battle,owner,enemy=self.battle('A_1132_6')
        owner['_mod_owner_turn']=1
        self.assertFalse(battle._emit_mod_event(owner,'turn_start',owner,owner))
        battle._add_buff(owner,'burn',3,1)
        for _ in range(17):battle._emit_mod_event(owner,'turn_start',owner,owner)
        self.assertEqual(len(battle.a),9)
        self.assertTrue(all(u.get('skillB') for u in battle.a[1:]))
        battle,owner,enemy=self.battle('A_1223_6')
        enemy['hp']=1;battle._injured(enemy,100,3,source=owner)
        self.assertEqual(len(battle.a),2)
        self.assertFalse(battle.a[1]['skillB'])

    def test_zed_passive_recognizes_non_native_burn(self):
        for route in ('manual', 'relic'):
            with self.subTest(route=route):
                battle, owner, enemy = self.battle('A_1132_6')
                owner['_mod_owner_turn'] = 1
                if route == 'manual':
                    battle._add_manual_skill_dot(owner, 'test_burn', 'burn', 100, 0, 2, enemy, 7, False)
                else:
                    owner['_relic_dots'] = [{'kind': 'burn', 'left': 2, 'amount': 100, 'source': enemy}]
                self.assertIsNone(battle._buff(owner, 'burn'))
                self.assertTrue(battle._emit_mod_event(owner, 'turn_start', owner, owner))
                self.assertEqual(len(battle.a), 2)

    def test_zed_shadows_stop_at_generation_three_and_share_the_captain_cap(self):
        battle, owner, enemy = self.battle('A_1132_6', True)
        battle._apply_native_skill(owner, [enemy], 'leader_skill')
        first = battle.a[-1]

        def burn_and_trigger(unit):
            unit['_mod_owner_turn'] = 1
            battle._add_buff(unit, 'burn', 2, 1, source=enemy)
            return battle._emit_mod_event(unit, 'turn_start', unit, unit)

        self.assertFalse(battle._emit_mod_event(first, 'turn_start', first, first))
        self.assertEqual(first['_zed_shadow_generation'], 1)
        self.assertTrue(burn_and_trigger(first))
        second = battle.a[-1]
        self.assertEqual(second['_zed_shadow_generation'], 2)
        self.assertTrue(burn_and_trigger(second))
        third = battle.a[-1]
        self.assertEqual(third['_zed_shadow_generation'], 3)
        self.assertFalse(burn_and_trigger(third))
        for _ in range(5):
            self.assertTrue(burn_and_trigger(owner))
        self.assertFalse(burn_and_trigger(second))
        self.assertEqual(sum(u['hp'] > 0 for u in battle.a[1:]), 8)
        battle._apply_native_skill(owner, [enemy], 'leader_skill')
        self.assertEqual(sum(u['hp'] > 0 for u in battle.a[1:]), 8)
        self.assertEqual(first['hp'], 0)
        third['hp'] = 0
        self.assertTrue(burn_and_trigger(second))
        self.assertEqual(sum(u['hp'] > 0 for u in battle.a[1:]), 8)

    def test_all_imported_slots_execute_without_missing_actions(self):
        for aid in self.cfg['hero_packs_104']['heroes']:
            battle,owner,enemy=self.battle(aid,True)
            for slot in ('skill','leader_skill','skillB'):
                skill=owner.get(slot)
                if not skill:continue
                if (skill.get('modCondition') or {}).get('kind')=='event':continue
                battle._apply_native_skill(owner,[enemy],slot)

    def test_zed_captain_copies_revised_normal_and_shares_shadow_passive(self):
        battle,owner,enemy=self.battle('A_1132_6',True)
        for _ in range(2):battle._apply_native_skill(owner,[enemy],'leader_skill')
        clones=[u for u in battle.a if u.get('_clone_of')]
        self.assertEqual(len(clones),2)
        self.assertEqual(sum(u['hp']>0 for u in clones),1)
        self.assertEqual(clones[-1]['skill'],owner['skill'])
        self.assertEqual(clones[-1]['skillB'],owner['skillB'])
        for aid,combinations in self.cfg['system_simple']['bond_skill_variants_104'].items():
            for bindings in combinations.values():
                for sid in bindings.values():
                    row=self.cfg['skill'][sid]
                    if row.get('modEffectSequence'):
                        self.assertEqual(row['skill'][0][0],'mod_step')


if __name__=='__main__':unittest.main()
