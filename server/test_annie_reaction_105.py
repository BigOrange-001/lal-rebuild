import unittest
from pathlib import Path
from unittest.mock import patch

from battle_engine import ReferenceBattle, base_unit
from gateway import load_game_config
from equipment_bonds_104 import equipped_bonds, skill_id
from native_skill_snapshot import _native_skill_snapshot
from skill_rank_growth_104 import hero_skill_references

ROOT=Path(__file__).resolve().parents[1]


class AnnieReactionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with patch('annie_reaction_105.apply_annie_reaction',lambda d:d), \
             patch('hero_passive_quality_105.restrict_low_star_passives'):
            cls.before=load_game_config(ROOT/'config/reconstruction/full-config.json')['cfg']
        cls.cfg=load_game_config(ROOT/'config/reconstruction/full-config.json')['cfg']

    def test_unbonded_only_lacks_stun_and_core_does_not_change_other_effects(self):
        c=self.cfg;aid='A_1221_6';sid=c['avatar'][aid]['pl'][13]
        rows=equipped_bonds(c,aid,['E_4999_6'])
        upgraded=c['skill'][skill_id(c,aid,sid,rows)]
        base=c['skill'][sid]
        self.assertEqual(base['name'],'不讲道理')
        self.assertEqual(base['pl'][:2],[0,1])
        self.assertFalse(base['annie_core_105']['stun_enabled'])
        self.assertTrue(upgraded['annie_core_105']['stun_enabled'])
        for key in ('warmup','cooldown','sunder','weak','poison_ap','debuff_rounds','control_rounds','purify_rounds'):
            self.assertEqual(base['annie_core_105'][key],upgraded['annie_core_105'][key])
        self.assertNotIn('提伯斯每完成',base['info'])
        self.assertEqual(base['skin_v2_keys'],[])

    def test_tibbers_roar_hits_only_its_lane_and_uses_its_own_cooldown(self):
        cfg = self.cfg
        annie = base_unit(cfg, 'A_1221_6', 60, team=1)
        foes = [base_unit(cfg, 'A_1001_5', 60, line=line, team=2) for line in (0, 0, 1)]
        battle = ReferenceBattle([annie], foes, config=cfg)
        owner = battle.a[0]
        owner['_team'] = battle.a
        bear = battle._spawn_summon(owner, 'A_2020_6', .7, 99)
        skill = bear['skill']
        self.assertEqual(skill['pl'][:2], [0, 2])
        battle._roll_attack = lambda *_args, **_kwargs: 1
        initial = [foe['hp'] for foe in battle.b]
        battle._tick_slot_cd(bear, '_skill_cd')
        with patch.object(battle, '_native_damage', wraps=battle._native_damage) as damage:
            self.assertTrue(battle._use_skill_slot(bear, battle.b, 'skill', '_skill_cd'))
        self.assertEqual([call.args[1] for call in damage.call_args_list], battle.b[:2])
        self.assertTrue(all(call.args[2:] == (battle._true_skill_coefficient(2), 3) for call in damage.call_args_list))
        for foe, hp in zip(battle.b[:2], initial):
            self.assertLess(foe['hp'], hp)
            self.assertEqual(battle._buff(foe, 'weak').round, 2)
            self.assertAlmostEqual(battle._buff_value(foe, 'weak'), .33 / .67)
        self.assertEqual(battle.b[2]['hp'], initial[2])
        self.assertIsNone(battle._buff(battle.b[2], 'weak'))
        for _ in range(2):
            battle._tick_slot_cd(bear, '_skill_cd')
            self.assertFalse(battle._use_skill_slot(bear, battle.b, 'skill', '_skill_cd'))
        battle._tick_slot_cd(bear, '_skill_cd')
        self.assertTrue(battle._use_skill_slot(bear, battle.b, 'skill', '_skill_cd'))

    def test_companion_moves_to_all_normal_variants_without_rank_scaling(self):
        c=self.cfg
        for quality in (5,6):
            aid=f'A_1221_{quality}'
            old=self.before['skill'][self.before['avatar'][aid]['pl'][13]]
            expected=_native_skill_snapshot(self.before,old['id'],1)['skills'][0][4:]
            for sid,slot in hero_skill_references(c,{'A_1221'}).items():
                if slot!=10 or not sid.endswith('_'+str(quality)):continue
                row=c['skill'][sid]
                self.assertEqual(row['annie_companion_105']['values'],expected)
                self.assertEqual(row['annie_companion_105']['keys'],old['skin_v2_keys'])
                self.assertIn('提伯斯每完成',row['info'])
                self.assertIn('受到敌方主动伤害',row['rankInfoTemplate'])
                if quality == 6:
                    self.assertNotIn('提伯斯每完成',c['skill'][c['avatar'][aid]['pl'][13]]['info'])
                else:
                    self.assertIsNone(c['avatar'][aid]['pl'][13])
                for level in (1,10):
                    before=_native_skill_snapshot(self.before,sid,level)
                    after=_native_skill_snapshot(c,sid,level)
                    self.assertEqual(after['skills'],before['skills'])


if __name__=='__main__':unittest.main()
