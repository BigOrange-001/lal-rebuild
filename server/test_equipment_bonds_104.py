import copy
import json
import unittest
from collections import Counter
from unittest.mock import patch
from gateway import Backend
from equipment_bonds_104 import PLAN,equipped_bonds,profile_equipment_bonds,skill_id,output_rate
from gameplay_roster import GameplayRosterEquipment
from battle_engine import base_unit,_native_skill_snapshot
from manual_ability_sim import SkillCompleteBattle
import test_stat_power_103 as stat_tests


class EquipmentBonds104Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        b=Backend(':memory:',PLAN.parent/'full-config.json');cls.doc=b.config;cls.cfg=b.config['cfg'];b.db.close()

    def profile(self,aid,eids):
        iid=aid+'|1'
        return {'avatars':{iid:{'aid':aid,'lv':60,'slv':7}},'team':[[iid]],
                'my_equips':{str(i):{'eid':e,'lv':1} for i,e in enumerate(eids)},
                'as_equips':[[str(i) for i in range(len(eids))]],'attrs':{'team_num':0,'dn':{}}},iid

    def test_complete_catalogue_two_ordinary_distinct_slots_and_exclusive_coverage(self):
        definitions=self.cfg['system_simple']['equipment_bonds_104']
        eligible={a for a in self.cfg['avatar'] if a.endswith('_6') and a.rsplit('_',1)[0] in {f for b in self.cfg['system_simple']['bonds_104'] for f in b['families']}}
        self.assertEqual(set(definitions),eligible);self.assertEqual(len(eligible),125);self.assertIn("A_1140_6",eligible)
        exclusive=set(self.cfg['system_simple']['equipment_roll_policy']['exclusive_ids'])
        found=set();counts=Counter()
        for aid,rows in definitions.items():
            ordinary=[r for r in rows if r['kind']=='ordinary']
            self.assertEqual(len(ordinary),2)
            self.assertEqual(len({(r['slot'],str(r['index']),str(r['path'])) for r in ordinary}),2)
            self.assertEqual(len({self.cfg['equip'][r['equipment']]['slot'] for r in ordinary}),2)
            for row in ordinary:
                e=self.cfg['equip'][row['equipment']];self.assertNotIn(e['id'],exclusive)
                self.assertEqual(row['power_budget'],.12 if e['quality']==5 else .08);counts[e['quality']]+=1
            found.update(r['equipment'] for r in rows if r['kind']=='exclusive')
            self.assertFalse(equipped_bonds(self.cfg,aid[:-1]+'5',[r['equipment'] for r in rows]))
        self.assertEqual(found,exclusive);self.assertGreater(counts[5],counts[6])

    def test_personal_equipment_duplicates_unwear_and_helpers(self):
        aid='A_1137_6';eids=['E_1002_5','E_3003_5'];profile,iid=self.profile(aid,eids)
        rows=profile_equipment_bonds(self.cfg,profile,iid)
        self.assertEqual(output_rate(self.cfg,aid,eids),1)
        self.assertEqual(equipped_bonds(self.cfg,aid,eids*2),rows)
        self.assertFalse(profile_equipment_bonds(self.cfg,profile,iid,True))
        profile['as_equips'].append(profile['as_equips'][0]);profile['as_equips'][0]=[]
        self.assertFalse(profile_equipment_bonds(self.cfg,profile,iid))
        profile,iid=self.profile(aid,eids)
        raw=GameplayRosterEquipment(None,self.doc).battle_attributes(profile,iid)
        unit=base_unit(self.cfg,aid,60,7,leader=True,overrides=raw)
        self.assertEqual(set(unit['equipment_bonds_104']),set(eids))
        self.assertEqual(unit['skill']['skid'],raw['skill']['skid'])
        self.assertEqual(unit['skill']['skills'],raw['skill']['skills'])

    def test_output_growth_scaling_buffs_timing_and_global_pass_once(self):
        aid='A_1134_6';base=self.cfg['avatar'][aid]['pl'][10]
        rows=equipped_bonds(self.cfg,aid,['E_1002_5','E_5004_5'])
        sid=skill_id(self.cfg,aid,base,rows)
        for level in (1,10):
            before=_native_skill_snapshot(self.cfg,base,level);after=_native_skill_snapshot(self.cfg,sid,level)
            self.assertEqual(before['pl'],after['pl'])
            self.assertAlmostEqual(after['skills'][0][1],before['skills'][0][1]*(1+.12/.30))
            self.assertAlmostEqual(after['skills'][1][1],before['skills'][1][1]*(1+.12/.55))
            self.assertEqual(after['skills'][0][3],before['skills'][0][3])
        self.assertAlmostEqual(self.cfg['skill'][sid]['hero_output_rate_104'],.8)

    def test_defensive_affinity_changes_only_captain_and_preserves_base_actions(self):
        aid='A_1137_6';rows=equipped_bonds(self.cfg,aid,['E_3003_5'])
        normal,captain=self.cfg['avatar'][aid]['pl'][10:12]
        self.assertEqual(skill_id(self.cfg,aid,normal,rows),normal)
        changed=self.cfg['skill'][skill_id(self.cfg,aid,captain,rows)]
        self.assertEqual(changed['skill'][0],self.cfg['skill'][captain]['skill'][0])
        self.assertAlmostEqual(changed['skill'][1][1],self.cfg['skill'][captain]['skill'][1][1]*(1+.12/.55))
        self.assertEqual(changed['skill'][2:],self.cfg['skill'][captain]['skill'][2:])
        self.assertEqual(changed['pl'],self.cfg['skill'][captain]['pl'])

    def test_each_ordinary_affinity_changes_only_its_authored_component(self):
        from skill_balance_overlay import _get,_set
        for aid,rows in self.cfg['system_simple']['equipment_bonds_104'].items():
            for row in rows:
                if row['kind']!='ordinary':continue
                slot={'normal':10,'captain':11,'passive':13}[row['slot']]
                source=self.cfg['avatar'][aid]['pl'][slot]
                result=skill_id(self.cfg,aid,source,[row])
                self.assertNotEqual(source,result,(aid,row['equipment']))
                for level in (1,10):
                    before=_native_skill_snapshot(self.cfg,source,level)
                    after=_native_skill_snapshot(self.cfg,result,level)
                    self.assertEqual(before['pl'],after['pl'])
                    expected=copy.deepcopy(before['skills'])
                    if isinstance(row['index'],int):
                        action=expected[row['index']];path=tuple(row['path'])
                        _set(action,path,_get(action,path)*(1+row['strength']))
                        self.assertEqual(len(expected),len(after['skills']))
                        def close(a,b):
                            if type(a) in (float,int) and type(b) in (float,int):self.assertAlmostEqual(a,b,places=6)
                            elif isinstance(a,list):
                                self.assertEqual(len(a),len(b))
                                for x,y in zip(a,b):close(x,y)
                            else:self.assertEqual(a,b)
                        close(expected,after['skills'])
                    else:
                        self.assertEqual(before['skills'],after['skills'])
                        self.assertEqual(self.cfg['skill'][result]['equipment_parts_104'],{row['index']:1+row['strength']})

    def test_damage_sequence_budget_matches_actual_coefficient_sum(self):
        # Single-target, both boomerang passes / all five projectiles land.
        for aid,eid,slot in [('A_1078_6','E_1004_5',10),('A_1222_6','E_5002_5',11)]:
            source=self.cfg['avatar'][aid]['pl'][slot]
            rows=equipped_bonds(self.cfg,aid,[eid])
            after=self.cfg['skill'][skill_id(self.cfg,aid,source,rows)]
            before=self.cfg['skill'][source]
            total=lambda r:sum(a[1] for a in r['skill'] if a[0]=='damage')
            self.assertAlmostEqual(total(after)/total(before),1.12,places=8)
            self.assertNotIn('整项技能目标提升',after['info'])
            self.assertEqual(len(after['skill']),len(before['skill']))

    def test_component_weights_recover_whole_skill_budget_including_reworks(self):
        for rows in self.cfg['system_simple']['equipment_bonds_104'].values():
            for effect in rows:
                if effect['kind']!='ordinary':continue
                for target in [effect,*effect['reworks'].values()]:
                    achieved=target['benefit_share']*((1+target['strength'])**target['benefit_curve']-1)
                    self.assertAlmostEqual(achieved,effect['power_budget'],places=9)
                    self.assertGreaterEqual(target['strength'],0)

    def test_all_existing_hero_bond_variants_have_reviewed_equipment_targets(self):
        from equipment_bonds_104 import apply_part
        for aid,rows in self.cfg['system_simple']['equipment_bonds_104'].items():
            for effect in rows:
                if effect['kind']!='ordinary' or effect['slot']=='passive':continue
                field={'normal':'skill','captain':'leader_skill'}[effect['slot']]
                for bindings in self.cfg['system_simple']['bond_skill_variants_104'][aid].values():
                    if field in bindings:
                        source=self.cfg['skill'][bindings[field]]
                        self.assertTrue(apply_part(copy.deepcopy(source),effect),(aid,effect['equipment'],source['name']))

    def test_replaced_components_do_not_buff_unrelated_reworked_skills(self):
        from equipment_bonds_104 import apply_part
        for rows in self.cfg['system_simple']['equipment_bonds_104'].values():
            for effect in rows:
                if effect['kind']!='ordinary':continue
                unrelated={'skill':[['purify',1,'FX']]}
                self.assertFalse(apply_part(unrelated,effect))
                self.assertEqual(unrelated,{'skill':[['purify',1,'FX']]})

    def test_exclusives_add_exactly_one_effect_to_normal_and_keep_base_mechanics(self):
        for aid,rows in self.cfg['system_simple']['equipment_bonds_104'].items():
            for row in rows:
                if row['kind']!='exclusive':continue
                normal=self.cfg['avatar'][aid]['pl'][10]
                sid=skill_id(self.cfg,aid,normal,[row]);old=self.cfg['skill'][normal];new=self.cfg['skill'][sid]
                self.assertEqual(new['skill'][:-1],old['skill'],(aid,row['equipment']))
                self.assertEqual(new['pl'],old['pl']);self.assertEqual(new['equipment_base_action_count_104'],len(old['skill']))
                self.assertEqual(new['skill'][-1][0],row['action'][0])
                captain=self.cfg['avatar'][aid]['pl'][11]
                self.assertEqual(skill_id(self.cfg,aid,captain,[row]),captain)

    def test_all_equipped_exclusive_kits_execute_in_full_skill_simulator(self):
        for aid,rows in self.cfg['system_simple']['equipment_bonds_104'].items():
            for row in rows:
                profile,iid=self.profile(aid,[row['equipment']])
                raw=GameplayRosterEquipment(None,self.doc).battle_attributes(profile,iid)
                owner=base_unit(self.cfg,aid,60,7,leader=True,overrides=raw)
                enemy=base_unit(self.cfg,'A_1001_5',60,1,team=2)
                owner['pos']=1000;enemy['pos']=1040;enemy['hp']=enemy['hp_max']=10**9
                battle=SkillCompleteBattle([owner],[enemy],config=self.cfg);o=battle.a[0];o['_team']=battle.a
                battle.b[0]['_team']=battle.b
                battle._apply_native_skill(o,battle.b,{'captain':'leader_skill','passive':'skillB'}.get(row.get('slot'),'skill'))


class EquipmentNativePower104Tests(stat_tests.StatPower103Tests):
    def test_equipment_affinities_preview_and_battle_power_match(self):
        for eids in (['E_1002_5'],['E_1002_5','E_3003_5'],['E_1032_6','E_3003_5'],[]):
            profile=self.profile();profile['my_equips']={str(i):{'eid':e,'lv':1} for i,e in enumerate(eids)}
            profile['as_equips']=[[str(i) for i in range(len(eids))]]+[[] for _ in range(5)]
            self.compare(profile)


if __name__=='__main__':unittest.main()
