import copy
import json
import unittest
from pathlib import Path
from unittest.mock import patch
from gateway import Backend
from battle_engine import ReferenceBattle,base_unit,_native_skill_snapshot
from hero_packs_104 import ROOT,SKIN_FAMILIES,compile_builtin,apply_hero_packs_104
from skill_output_104 import output_paths
from recruit_exchange import daily_orange_pool


class HeroPacks104Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        path=ROOT.parent/'full-config.json'
        with patch('equipment_bonds_104.apply_equipment_bonds_104',side_effect=lambda d:d), patch('hero_packs_104.apply_hero_packs_104',side_effect=lambda d:d), patch('bonds_104.apply_bonds_104',side_effect=lambda d:d):
            before=Backend(':memory:',path);cls.old=copy.deepcopy(before.config['cfg']);before.db.close()
        backend=Backend(':memory:',path);cls.cfg=copy.deepcopy(backend.config['cfg']);backend.db.close()

    def battle(self,aid,leader=False):
        a=base_unit(self.cfg,aid,60,10,0,.5,leader,1)
        b=base_unit(self.cfg,'A_1001_5',60,1,0,.5,False,2)
        b['hp']=b['hp_max']=10**8;b['pos']=a['pos']+40
        battle=ReferenceBattle([a],[b],config=self.cfg)
        battle.a[0]['_team']=battle.a;battle.b[0]['_team']=battle.b
        return battle,battle.a[0],battle.b[0]

    def test_source_coefficients_and_growth_quality_and_unchanged_buffs(self):
        for key,rate in [('nine',2/3*.8),('zongzi',.8)]:
            project=json.loads((ROOT/(key+'.json')).read_text('utf-8'))
            authored={s['id']:s for s in project['data']['skills']['skills']}
            for sid in self.cfg['hero_packs_104']['skills']:
                row=self.cfg['skill'][sid]
                if row['builtin_pack_104']!=key:continue
                source=compile_builtin(authored[row['builtin_skill_key_104']],sid,lambda ref,*_:ref.rsplit("/",1)[1] if ref and ref.startswith("builtin:") else ref)
                for level in (1,10):
                    expected=_native_skill_snapshot({'skill':{sid:source}},sid,level)['skills']
                    actual=_native_skill_snapshot(self.cfg,sid,level)['skills']
                    for i,action in enumerate(expected):
                        paths=output_paths(action)
                        for j,value in enumerate(action):
                            if action[0]=='mod_step' and j in (11,17):continue
                            if (j,) in paths:self.assertAlmostEqual(actual[i][j],value*rate,places=7,msg=(sid,level,i,j))
                            else:self.assertEqual(actual[i][j],value,(sid,level,i,j))
        for aid in self.cfg['hero_packs_104']['heroes']+self.cfg['hero_packs_104']['summons']:
            for index in (10,11,13):
                sid=self.cfg['avatar'][aid]['pl'][index]
                if sid and self.cfg['skill'][sid].get('builtin_pack_104'):self.assertEqual(sid[-1],aid[-1])

    def test_skin_classification_bonds_pools_and_morde_skill_preservation(self):
        skins=set(self.cfg['system_simple']['skin_hero_ids'])
        for aid in self.cfg['avatar']:
            if int(aid.split('_')[1]) in SKIN_FAMILIES:self.assertIn(aid,skins)
        self.assertFalse(skins & set(daily_orange_pool(self.cfg)))
        for b in self.cfg['system_simple']['bonds_104']:
            self.assertEqual(len({any(a.startswith(f+'_') for a in skins) for f in b['families']}),1,b['name'])
        for aid in ('A_1137_5','A_1137_6'):
            self.assertEqual(self.cfg['avatar'][aid]['pl'],self.old['avatar'][aid]['pl'])
            for index in (10,11,13):
                sid=self.old['avatar'][aid]['pl'][index]
                self.assertEqual(self.cfg['skill'][sid],self.old['skill'][sid])
        self.assertEqual(self.cfg['avatar']['A_1212_6']['pl'][:10],self.old['avatar']['A_1212_6']['pl'][:10])
        self.assertEqual(apply_hero_packs_104(copy.deepcopy(self.cfg)),self.cfg)

    def test_zongzi_inherits_panel_has_level_one_skill_and_replaces_oldest(self):
        battle,owner,enemy=self.battle('A_1212_6')
        for _ in range(3):self.assertTrue(battle._apply_native_skill(owner,[enemy]))
        units=[u for u in battle.a if u is not owner]
        self.assertEqual(len(units),3);self.assertEqual(units[0]['hp'],0)
        self.assertEqual(sum(u['hp']>0 for u in units),2)
        last=units[-1]
        self.assertEqual(last['ap'],int(battle._get_damage(owner)*.8))
        self.assertEqual(last['hp_max'],int(owner['hp_max']*.8))
        self.assertEqual(last['slv'],1)
        self.assertAlmostEqual(last['skill']['skills'][0][1],.6*.8)
        self.assertEqual(battle._buff(last,'summon').round,99)
        self.assertFalse(last['skillB'])

    def test_event_summons_respect_conditions_capacity_and_no_recursion(self):
        battle,owner,enemy=self.battle('A_1132_6')
        owner['_mod_owner_turn']=1
        self.assertFalse(battle._emit_mod_event(owner,'turn_start',owner,owner))
        battle._add_buff(owner,'burn',3,1)
        for _ in range(17):battle._emit_mod_event(owner,'turn_start',owner,owner)
        self.assertEqual(len(battle.a),17)
        self.assertTrue(all(not u.get('skillB') for u in battle.a[1:]))
        battle,owner,enemy=self.battle('A_1223_6')
        enemy['hp']=1;battle._injured(enemy,100,3,source=owner)
        self.assertEqual(len(battle.a),2)
        self.assertFalse(battle.a[1]['skillB'])

    def test_all_imported_slots_execute_without_missing_actions(self):
        for aid in self.cfg['hero_packs_104']['heroes']:
            battle,owner,enemy=self.battle(aid,True)
            for slot in ('skill','leader_skill','skillB'):
                skill=owner.get(slot)
                if not skill:continue
                if (skill.get('modCondition') or {}).get('kind')=='event':continue
                battle._apply_native_skill(owner,[enemy],slot)

    def test_existing_zed_captain_copies_revised_normal_without_recursive_passive(self):
        battle,owner,enemy=self.battle('A_1132_6',True)
        for _ in range(2):battle._apply_native_skill(owner,[enemy],'leader_skill')
        clones=[u for u in battle.a if u.get('_clone_of')]
        self.assertEqual(len(clones),2)
        self.assertEqual(sum(u['hp']>0 for u in clones),1)
        self.assertEqual(clones[-1]['skill'],owner['skill'])
        self.assertFalse(clones[-1]['skillB'])
        for aid,combinations in self.cfg['system_simple']['bond_skill_variants_104'].items():
            for bindings in combinations.values():
                for sid in bindings.values():
                    row=self.cfg['skill'][sid]
                    if row.get('modEffectSequence'):
                        self.assertEqual(row['skill'][0][0],'mod_step')


if __name__=='__main__':unittest.main()
