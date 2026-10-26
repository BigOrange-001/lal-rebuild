import copy
import hashlib
import json
import unittest
import subprocess
import shutil
import sys
from pathlib import Path
from unittest.mock import patch

from gateway import Backend
from orange_ascension_104 import ROOT, MEDIA, apply_orange_ascension_104
from battle_engine import base_unit, _native_skill_snapshot
from manual_ability_sim import SkillCompleteBattle
from battle_mod_events import emit
from bonds_104 import active_bonds
from gameplay_roster import GameplayRosterEquipment
from player_store import GameplayFault
from skill_output_104 import output_paths
from skill_balance_overlay import _get


class OrangeAscension104Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.backend=Backend(':memory:',ROOT/'config/reconstruction/full-config.json')
        cls.doc=cls.backend.config;cls.cfg=cls.doc['cfg']
        with patch('orange_ascension_104.apply_orange_ascension_104',lambda d:d),patch('equipment_bonds_104.apply_equipment_bonds_104',lambda d:d):
            old=Backend(':memory:',ROOT/'config/reconstruction/full-config.json')
        cls.old=old.config['cfg'];old.db.close()

    @classmethod
    def tearDownClass(cls):cls.backend.db.close()

    def test_same_family_panels_normal_ultimate_and_idempotence(self):
        before=copy.deepcopy(self.doc)
        apply_orange_ascension_104(self.doc)
        self.assertEqual(before,self.doc)
        for ident in range(1001,1022):
            with self.subTest(hero=ident):
                purple=self.cfg['avatar'][f'A_{ident}_5'];orange=self.cfg['avatar'][f'A_{ident}_6']
                self.assertEqual(purple,self.old['avatar'][purple['id']])
                self.assertNotIn(orange['id'],self.cfg['system_simple']['skin_hero_ids'])
                self.assertEqual(orange['pl'][8:11],purple['pl'][8:11])
                self.assertEqual(orange['pl'][12],purple['pl'][12])
                for a,b in zip(orange['pl'][:8],purple['pl'][:8]):self.assertAlmostEqual(a,2*b,places=7)
                for level in (1,10):
                    self.assertEqual(_native_skill_snapshot(self.cfg,orange['pl'][10],level),_native_skill_snapshot(self.old,purple['pl'][10],level))
                captain=self.cfg['skill'][orange['pl'][11]];original=self.cfg['skill'][purple['pl'][11]]
                self.assertEqual(captain['name'],'真-'+original['name'])
                self.assertEqual(captain['pl'],original['pl'])
                for i,action in enumerate(original['skill']):
                    for path in output_paths(action):self.assertAlmostEqual(_get(captain['skill'][i],path),_get(action,path)*1.1,places=7)
                passive=self.cfg['skill'][orange['pl'][13]]
                self.assertEqual(passive['pl'][:2],[0,1]);self.assertEqual(orange['skill_diff'],20)

    def test_all_bonds_inherit_and_passive_survives_reworks(self):
        definitions=self.cfg['system_simple']['bonds_104']
        variants=self.cfg['system_simple']['bond_skill_variants_104']
        reworks=0
        for ident in range(1001,1022):
            family=f'A_{ident}';aid=family+'_6'
            related=[b for b in definitions if family in b['families']]
            self.assertGreaterEqual(len(related),2,aid)
            for bond in related:
                lineup=[f+'_6' for f in bond['families']]
                self.assertTrue(all(a in self.cfg['avatar'] for a in lineup))
                self.assertIn(bond,active_bonds(self.cfg,aid,lineup))
                mixed=[a if a==aid else a[:-1]+'5' for a in lineup]
                self.assertNotIn(bond,active_bonds(self.cfg,aid,mixed))
                replacement=variants[aid][bond['id']]
                for slot,sid in replacement.items():
                    self.assertIn(sid,self.cfg['skill'])
                    if slot=='skill':
                        purple_sid=variants[family+'_5'][bond['id']].get(slot)
                        self.assertIsNotNone(purple_sid)
                        self.assertEqual(self.cfg['skill'][sid]['skill'],self.cfg['skill'][purple_sid]['skill'])
                if bond.get('focus')==family and len(bond['families'])>=4:
                    self.assertIn('skill',replacement);self.assertIn('leader_skill',replacement);reworks+=1
                self.assertNotIn('skillB',replacement)
                self.assertIsNotNone(base_unit(self.cfg,aid,60,10)['skillB'])
            equipment=self.cfg['system_simple']['equipment_bonds_104'][aid]
            self.assertEqual(sum(r['kind']=='ordinary' for r in equipment),2)
        self.assertGreater(reworks,0)

    def test_all_promotions_retain_instance_and_skill_level(self):
        store=self.backend.players;uid=store.login('orange-promotion')['uid']
        def seed(p):
            p['avatars']={f'A_{i}_5|asc{i}':dict(id=f'A_{i}_5|asc{i}',aid=f'A_{i}_5|asc{i}',lv=99,slv=7,phase=2,morph=0,exp=0) for i in range(1001,1022)}
            p['team']=[[None]*6 for _ in range(3)];p['attrs']['dn']={}
            p['coin']=100000;p['gold']=10000000;p['attrs']['dust']=[10000]*4
            return p,{}
        store.atomic_update(uid,seed)
        roster=GameplayRosterEquipment(store,self.doc)
        for i in range(1001,1022):
            result=roster.dispatch(uid,'user.star_up',dict(aid=f'A_{i}_5|asc{i}',aids=[],actionID=f'orange-{i}'))
            self.assertEqual(result['id'],f'A_{i}_6|asc{i}')
            self.assertEqual((result['lv'],result['slv'],result['phase']),(99,7,0))

    @unittest.skipUnless(shutil.which('node'), 'Node is needed for native stat checks')
    def test_orange_bond_equipment_preview_matches_battle(self):
        from test_stat_power_103 import StatPower103Tests
        StatPower103Tests.setUpClass()
        checker=StatPower103Tests()
        plan=json.loads((ROOT/'config/reconstruction/equipment-bonds-1.0.4.json').read_text('utf-8'))
        for ident in range(1001,1022):
            family=f'A_{ident}';aid=family+'_6'
            bond=max((b for b in self.cfg['system_simple']['bonds_104'] if family in b['families']),key=lambda b:len(b['families']))
            aids=[aid]+[f+'_6' for f in bond['families'] if f!=family]
            ids=[a+'|'+str(i) for i,a in enumerate(aids)]
            profile=dict(avatars={iid:dict(aid=a,lv=60,slv=10,phase=0) for iid,a in zip(ids,aids)},
                         team=[ids],as_equips=[[] for _ in ids],my_equips={},attrs={'team_num':0,'dn':{}})
            for index,eid in enumerate(plan['heroes'][aid]['equipment']):
                key='equipment'+str(index)
                profile['my_equips'][key]=dict(eid=eid,lv=30,slv=1,stat_roll_ppm=1000000)
                profile['as_equips'][0].append(key)
            with self.subTest(hero=aid):checker.compare(profile,self.doc)

    def test_acquisition_preserves_quality_probabilities(self):
        added={f'A_{i}_6' for i in range(1001,1022)}
        for pool in ('normal','advanced','vip'):
            old=self.old['summon_calibration']['pools'][pool]['qualities']
            new=self.cfg['summon_calibration']['pools'][pool]['qualities']
            for quality,row in new.items():
                self.assertEqual(row['probability_percent'],old[quality]['probability_percent'])
            orange={c['id'] for c in new['orange']['cards']}
            self.assertEqual(added & orange,added if pool!='normal' else set())

    def test_builtin_media_transport_and_mod_compile_preserve_assets(self):
        from mod_policy import runtime
        self.assertEqual(runtime(self.doc), {})
        uid=self.backend.players.login('orange-media')['uid']
        envelope=self.backend.mods.config(uid)
        self.assertEqual(len(envelope['assets']),42)
        compiled=self.backend.mods.catalog.compile(self.doc,{'packages':[]})
        self.assertEqual(len(compiled.runtime['assets']),42)
        for asset in envelope['assets']:
            data,mime=self.backend.mods.asset(asset['contentDigest'],asset['path'])
            self.assertEqual(mime,'image/png');self.assertEqual(hashlib.sha256(data).hexdigest(),asset['sha256'])
            if asset['role']=='icon':self.assertEqual(asset['cardFrame'],[24,16,112,128])
        digest=self.cfg['builtin_assets_104']['digest']
        for path in ('../full-config.json','cards/../manifest.json','manifest.json'):
            with self.assertRaises(GameplayFault):self.backend.mods.asset(digest,path)

    def scenario(self,ident):
        owner=base_unit(self.cfg,f'A_{ident}_6',60,10,0,.5,True,1)
        allies=[owner]+[base_unit(self.cfg,'A_1001_5',60,1,0,.5,False,1) for _ in range(3)]+[base_unit(self.cfg,'A_2001_4',60,1,0,.5,False,1) for _ in range(2)]
        enemies=[base_unit(self.cfg,'A_1001_5',60,1,0,.5,False,2) for _ in range(4)]
        battle=SkillCompleteBattle(allies,enemies,config=self.cfg)
        owner=battle.a[0];owner['hp']=int(owner['hp_max']*.2)
        for j,u in enumerate(battle.a+battle.b):u['pos']=1500+j*10;u['_team']=battle.a if u in battle.a else battle.b
        for u in battle.b:u['hp']=u['hp_max']=10**8
        gate=owner['skillB']['modCondition'];event=gate['event']
        if gate.get('requiredBuff'):battle._add_buff(owner,gate['requiredBuff'],2,.2 if gate['requiredBuff']!='shield' else 10000)
        source,target=(owner,battle.b[0])
        if event in ('dodge','damage_taken','shield_break'):source,target=battle.b[0],owner
        elif event=='skill_cast':source=target=owner
        elif event=='healed':source=target=owner
        elif event=='heal_done':source,target=owner,battle.a[1]
        other=target if source is owner else source
        if 'otherHpBelow' in gate:other['hp']=int(other['hp_max']*.1)
        if gate.get('otherRequiredBuff'):battle._add_buff(other,gate['otherRequiredBuff'],2,0)
        if event=='kill':target['hp']=0
        return battle,owner,source,target

    def test_each_conditional_passive_fires_and_obeys_cooldown(self):
        for ident in range(1001,1022):
            with self.subTest(hero=ident):
                b,u,s,t=self.scenario(ident);g=u['skillB']['modCondition']
                for _ in range(g.get('everyEvents',1)-1):self.assertFalse(emit(b,u,g['event'],s,t,100))
                self.assertTrue(emit(b,u,g['event'],s,t,100))
                self.assertEqual(u['_mod_event_count'],1)
                self.assertFalse(emit(b,u,g['event'],s,t,100))
                self.assertFalse(u.get('_mod_event_busy'));self.assertIsNone(u.get('_mod_event'))

    def test_conditions_do_not_fire_outside_the_authored_situation(self):
        for ident in range(1001,1022):
            with self.subTest(hero=ident):
                b,u,s,t=self.scenario(ident);g=u['skillB']['modCondition']
                if 'hpBelow' in g:u['hp']=u['hp_max']
                elif g.get('requiredBuff'):b._remove_buff(u,g['requiredBuff'])
                elif 'otherHpBelow' in g:(t if s is u else s)['hp']=(t if s is u else s)['hp_max']
                elif g.get('otherRequiredBuff'):b._remove_buff(t if s is u else s,g['otherRequiredBuff'])
                elif g.get('nearbySummons'):
                    for unit in b.a[4:]:unit['hp']=0
                else:
                    for unit in b.b:unit['line']=1
                self.assertFalse(emit(b,u,g['event'],s,t,100))
                self.assertEqual(u.get('_mod_event_count',0),0)

    @unittest.skipUnless(shutil.which('node'),'Node is required for actual ActionScript gate comparison')
    def test_client_event_gates_match_server_for_all_21(self):
        sys.path.insert(0,str(ROOT/'scripts'))
        from test_avatar_passive import method_body
        from test_curse_combat import CurseClientCombatTests
        source=(ROOT/'client/src/stages/137_Avatar.as').read_text('utf-8')
        body=CurseClientCombatTests.translate(method_body(source,'emitModEvent'))
        cases=[]
        for ident in range(1001,1022):
            b,u,s,t=self.scenario(ident);g=u['skillB']['modCondition'];units=b.a+b.b
            values=[]
            for actor in units:
                buffs={key:dict(value=b._buff_value(actor,key)) for key in ('shield','strong','steel','taunt','stun') if b._buff(actor,key) is not None}
                values.append(dict(hp=actor['hp'],hpMax=actor['hp_max'],pos=actor['pos'],line=actor['line'],team=b._team_number(actor),type=b._get_type(actor),buffs=buffs))
            index=lambda actor:next(i for i,v in enumerate(units) if v is actor)
            result=[emit(b,u,g['event'],s,t,100) for _ in range(g.get('everyEvents',1)+1)]
            cases.append(dict(gate=g,units=values,owner=index(u),source=index(s),target=index(t),expected=result))
        script=r'''
const input=JSON.parse(require('fs').readFileSync(0,'utf8'));
const int=Math.trunc; let modEventDepth=0,modEventBudget=0;
const GameMap={currentMap:null},GlobalData={$mConfig_skill:{}};
const emit=new Function('event','source','target','amount','overheal','with(this){'+input.body+'}');
// Function constructor needs these globals just as AS sees its imported classes.
global.GameMap=GameMap;global.GlobalData=GlobalData;global.int=int;
Object.defineProperty(global,'modEventDepth',{get:()=>modEventDepth,set:v=>modEventDepth=v});
Object.defineProperty(global,'modEventBudget',{get:()=>modEventBudget,set:v=>modEventBudget=v});
let results=[];
for(const c of input.cases){
 let units=c.units.map(v=>({...v,getType(){return this.type;},hasModBuff(k){return !!this.buffs[k];}}));
 let owner=units[c.owner];owner.abilityState={};owner.manualOwnerActionSerial=0;
 owner.skillB={isModEffectSequence:()=>true,skillSetData:{id:'test',warmup:0,cooldown:1},canModEventCast:()=>true,useSkill:()=>{}};
 GlobalData.$mConfig_skill.test={modCondition:c.gate};
 GameMap.currentMap={roundNum:0,getAliveList:team=>units.filter(u=>u.team===team&&u.hp>0)};
 results.push(c.expected.map(()=>emit.call(owner,c.gate.event,units[c.source],units[c.target],100,0)));
}
process.stdout.write(JSON.stringify(results));
'''
        run=subprocess.run([shutil.which('node'),'-e',script],input=json.dumps(dict(body=body,cases=cases)),text=True,capture_output=True,encoding='utf-8')
        self.assertEqual(run.returncode,0,run.stderr)
        self.assertEqual(json.loads(run.stdout),[c['expected'] for c in cases])


if __name__=='__main__':unittest.main()
