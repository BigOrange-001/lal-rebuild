import unittest
from pathlib import Path
from unittest.mock import patch

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
