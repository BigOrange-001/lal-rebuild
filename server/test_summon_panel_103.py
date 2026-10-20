"""Live summon snapshots, authored ratios and stable post-summon stats."""
import copy
import json
import unittest
from pathlib import Path

from battle_engine import ReferenceBattle, _native_skill_snapshot
from summon_panel_103 import apply_summon_panel_config, NOTICE, OLD_RULE


class SummonPanelTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.config = json.loads((Path(__file__).resolve().parents[1] / 'config/reconstruction/full-config.json').read_text('utf-8'))['cfg']

    def battle(self):
        owner = dict(aid='A_1132_5',isme=True,lv=99,slv=10,line=0,pos=1500,hp=53,hp_max=10001,
                     ap=1001,de_ph=501,de_ma=401,new_4attrs=dict(hit=101,flee=103,crit=107,tough=109),
                     talent=[0,.1,.2,.3],_manual_battle_stacks=dict(attack=.2,defense=.3,flee=7),
                     _timed_stacks=[dict(stat='attack',value=.1,expiresAt=5)])
        battle = ReferenceBattle([owner], [],config=self.config)
        owner=battle.a[0];owner['_team']=battle.a
        for key,value in dict(strong=.5,weak=.2,steel=.4,sunder=.25,armor=.2,
                              hitup=11,fleeup=13,critup=17,toughup=19).items():
            battle._add_buff(owner,key,3,value)
        return battle,owner

    def test_live_buffs_and_battle_stacks_are_inherited_once(self):
        battle,owner=self.battle()
        panel=battle._summon_panel_snapshot(owner)
        self.assertEqual(panel,dict(hp_max=10001,ap=1788,de_ph=1048,de_ma=757,hit=112,flee=123,crit=124,tough=128))
        unit=battle._spawn_summon(owner,'A_2003_2',.5,2)
        self.assertEqual([unit[k] for k in ('hp_max','ap','de_ph','de_ma')],[5000,894,524,378])
        self.assertEqual(unit['new_4attrs'],dict(hit=56,flee=61,crit=62,tough=64))
        self.assertEqual(unit['hp'],unit['hp_max'])
        self.assertEqual([battle._talent(unit,k) for k in (1,2,3)],[0,0,0])
        original=copy.deepcopy(unit['new_4attrs']);owner['_buffs']={};owner['ap']*=2
        self.assertEqual(unit['ap'],894);self.assertEqual(unit['new_4attrs'],original)
        self.assertNotEqual(battle._spawn_summon(owner,'A_2003_2',.5,2)['ap'],unit['ap'])

    def test_team_auras_are_included_once_and_dead_sources_are_ignored(self):
        battle,owner=self.battle()
        battle._config=copy.deepcopy(self.config)
        battle._config['talent']['TEST']={'growth_effect':'team_hit','growth_value':700}
        battle._config['talent']['DEAD']={'growth_effect':'team_hit','growth_value':900}
        battle.a.extend([dict(hp=1,talent='TEST'),dict(hp=0,talent='DEAD')])
        unit=battle._spawn_summon(owner,'A_2003_2',.5,2)
        self.assertEqual(unit['new_4attrs']['hit'],406)
        self.assertEqual(battle._summon_panel_snapshot(unit)['hit'],406)

    def test_explicit_primary_ratios_and_captain_multiplier(self):
        battle,owner=self.battle()
        unit=battle._spawn_summon(owner,'A_2003_2',.5,2,ap_factor=.6,extra_multiplier=1.5)
        self.assertEqual([unit[k] for k in ('hp_max','ap','de_ph','de_ma')],[3000,1608,628,453])
        self.assertEqual(unit['new_4attrs']['hit'],84)

    def test_manual_and_clone_policies_survive_serialization(self):
        battle,owner=self.battle()
        skill=_native_skill_snapshot(self.config,'S_631029_5')
        self.assertEqual(skill['manualSummonPolicy']['apRatio'],.8)
        context={'targets':{}}
        action=next(a for a in skill['skills'] if a[0]=='summon')
        battle._act_summon(owner,[],battle.a,skill,action,0,context)
        self.assertEqual(context['targets'][0]['ap'],int(int(1788*action[1])*skill['captainSummonMultiplier']))
        clone=_native_skill_snapshot(self.config,'S_631132_5')
        battle._act_clone_normal(owner,[],battle.a,clone,clone['skills'][0],0,context)
        self.assertEqual(context['targets'][0]['ap'],2145)

    def test_invalid_ratios_never_create_units_and_zero_stats_stay_zero(self):
        battle,owner=self.battle()
        for ratio in (0,-1,float('nan'),float('inf'),True,101):
            self.assertIsNone(battle._spawn_summon(owner,'A_2003_2',ratio,2))
        self.assertEqual(len(battle.a),1)
        owner.update(de_ph=0,de_ma=0,new_4attrs={});owner['_buffs']={};owner['_manual_battle_stacks']={}
        unit=battle._spawn_summon(owner,'A_2003_2',.01,2)
        self.assertEqual([unit[k] for k in ('de_ph','de_ma')],[0,0])
        self.assertEqual(unit['new_4attrs'],dict(hit=0,flee=0,crit=0,tough=0))

    def test_description_overlay_is_idempotent(self):
        document={'cfg':copy.deepcopy(self.config)}
        apply_summon_panel_config(document);first=copy.deepcopy(document)
        apply_summon_panel_config(document)
        self.assertEqual(first,document)
        text=document['cfg']['skill']['S_301209_4']['info']
        self.assertIn(NOTICE,text);self.assertNotIn(OLD_RULE,text)


if __name__ == '__main__':
    unittest.main()
