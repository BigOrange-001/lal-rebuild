"""Regressions for the six findings on PR #23, including real Mod compilation."""
import copy,json,subprocess,sys,tempfile,unittest
from pathlib import Path
from gateway import Backend
from bonds_104 import active_bonds,profile_bonds,skill_ids
from battle_engine import base_unit,_native_skill_snapshot
from manual_ability_sim import SkillCompleteBattle
from gameplay_roster import GameplayRosterEquipment
from mod_packages import ModCatalog
from test_mod_service import archive
import test_stat_power_103 as stat

ROOT=Path(__file__).resolve().parents[1]

class Review104Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        b=Backend(':memory:',ROOT/'config/reconstruction/full-config.json');cls.doc=b.config;cls.cfg=b.config['cfg'];b.db.close()
        stat.StatPower103Tests.setUpClass();cls.native=stat.StatPower103Tests()

    def profile(self,aids):
        ids=[a+'|'+str(i) for i,a in enumerate(aids)]
        return dict(avatars={iid:dict(aid=a,lv=60,slv=10) for iid,a in zip(ids,aids)},team=[ids],
                    as_equips=[[] for _ in ids],my_equips={},attrs={'team_num':0,'dn':{}})

    def compile_patch(self,aid,path,value,channels=None):
        with tempfile.TemporaryDirectory() as tmp:
            catalog=ModCatalog(Path(tmp)/'mods',self.doc)
            pack=archive(tmp,kind='patch',patches=[dict(id='review',target='builtin:avatar/'+aid,
                expect={'path':'name','value':self.cfg['avatar'][aid]['name']},
                operations=[{'op':'replace','path':path,'value':value}])])
            meta=catalog.install(pack)
            selection=dict(packageId=meta['packageId'],version=meta['version'],contentDigest=meta['digest'],enabled=True)
            if channels is not None:selection['channels']=channels
            return catalog.compile(self.doc,{'packages':[selection]}).document

    def test_turret_bond_really_summons_at_purple_and_orange(self):
        for aid,sources in self.cfg['system_simple']['bond_skill_sources_104'].items():
            pl=self.cfg['avatar'][aid]['pl']
            self.assertEqual(sources,{'skill':pl[10],'leader_skill':pl[11]})
        for quality in (5,6):
            aid=f'A_1014_{quality}';bond=next(b for b in self.cfg['system_simple']['bonds_104'] if b['id']=='b039')
            sid=skill_ids(self.cfg,aid,[bond])['skill']
            owner=base_unit(self.cfg,aid,60,10,0,.5,False,1)
            enemy=base_unit(self.cfg,'A_1001_5',60,1,0,.5,False,2)
            owner['skill']=_native_skill_snapshot(self.cfg,sid,10)
            battle=SkillCompleteBattle([owner],[enemy],config=self.cfg)
            self.assertTrue(battle._apply_native_skill(battle.a[0],battle.b,'skill'))
            self.assertEqual(len(battle.a),2)
            self.assertEqual(battle.a[1]['aid'],'A_2001_4')

    def test_explicit_mod_skill_patch_wins_over_old_bond_variant(self):
        doc=self.compile_patch('A_1007_5','skills.normal.warmup',7)
        p=self.profile(['A_1007_5','A_1001_5','A_1009_5']);iid=p['team'][0][0]
        raw=GameplayRosterEquipment(None,doc).battle_attributes(p,iid)
        self.assertIn('b001',raw['bonds_104']);self.assertEqual(raw['skill']['pl'][0],7)
        expected=doc['cfg']['avatar']['A_1007_5']['pl'][10]
        self.assertEqual(raw['skill']['skid'],expected)
        self.assertEqual(self.native.native(p,doc['cfg'])['units'][0]['skillId'],expected)
        self.native.compare(p,doc)

    def test_destiny_channel_filters_beneficiary_and_member(self):
        doc=self.compile_patch('A_1001_5','name','channel-test',{'usage.destiny':False})
        p=self.profile(['A_1001_5','A_1007_5','A_1009_5'])
        for iid in p['team'][0]:self.assertFalse(profile_bonds(doc['cfg'],p,iid))
        self.native.compare(p,doc)
        self.assertFalse(active_bonds(doc['cfg'],'A_1007_5',['A_1001_5','A_1007_5','A_1009_5']))

    def test_selected_preset_equipment_stats_book_and_affinity_use_same_slot(self):
        p=self.profile(['A_1137_6','A_1001_6']);ids=p['team'][0]
        p['team'].append(ids[::-1]);p['attrs']['team_num']=1
        p['my_equips']={'weapon':dict(eid='E_1002_5',lv=30),'book':dict(eid='E_6001_5',lv=1,slv=10)}
        p['as_equips']=[[],['weapon','book']]
        normalized=copy.deepcopy(p);normalized['team']=[p['team'][1]];normalized['attrs']['team_num']=0
        roster=GameplayRosterEquipment(None,self.doc)
        for iid in ids:self.assertEqual(roster.battle_attributes(p,iid),roster.battle_attributes(normalized,iid))
        equipped=roster.battle_attributes(p,ids[0]);self.assertIn('E_1002_5',equipped['equipment_bonds_104'])
        self.assertIsNotNone(equipped['book_skill'])
        self.native.compare(normalized,self.doc)
        p['as_equips'][1]=[]
        self.assertGreater(equipped['ap'],roster.battle_attributes(p,ids[0])['ap'])

    def test_riven_bond_boosts_actual_damage_and_buff_not_only_scale(self):
        aid='A_1056_5';bond=next(b for b in self.cfg['system_simple']['bonds_104'] if b['id']=='b012')
        base=self.cfg['avatar'][aid]['pl'][11];boost=skill_ids(self.cfg,aid,[bond])['leader_skill']
        results=[]
        for sid in (base,boost):
            owner=base_unit(self.cfg,aid,60,10,0,.5,True,1);enemy=base_unit(self.cfg,'A_1001_5',60,1,0,.5,False,2)
            owner['leader_skill']=_native_skill_snapshot(self.cfg,sid,1)
            b=SkillCompleteBattle([owner],[enemy],config=self.cfg);coeff=[]
            b.hit=lambda o,t,c,k,shared_total=0:coeff.append(c*b._context(o)['damage_factor']) or True
            self.assertTrue(b._apply_native_skill(b.a[0],b.b,'leader_skill'))
            results.append((coeff,b._buff_value(b.a[0],'strong')))
        self.assertTrue(results[0][0]);self.assertEqual(len(results[0][0]),len(results[1][0]))
        for x,y in zip(results[0][0],results[1][0]):self.assertAlmostEqual(y/x,1.32)
        self.assertAlmostEqual(results[1][1]/results[0][1],1.32)

    def test_nurse_client_heal_matches_server_global_output_and_bond(self):
        sys.path.insert(0,str(ROOT/'scripts'))
        from test_skin_skills_103_client import SkinSkills103ClientTests
        client=SkinSkills103ClientTests()
        for rate in (1,1.32):
            actual=client.run_case('unit.ap=1000;unit.heroSkillOutputRate104=()=>.8;unit.executeNurseSkin("nurse_n",{manualEffectMultiplier:'+str(rate)+',skills:[["manual_ability","nurse_n",1,"FX",.7]]});console.log(JSON.stringify(unit.hp-5000));')
            cfg=copy.deepcopy(self.cfg);aid='A_1208_5';sid=cfg['avatar'][aid]['pl'][10];cfg['skill'][sid]['manualEffectMultiplier']=rate
            owner=base_unit(cfg,aid,1,1,0,.5,False,1);owner.update(ap=1000,hp_max=10000,hp=5000);owner['skillB']=None
            b=SkillCompleteBattle([owner],[],config=cfg);b.a[0]['hp']=5000
            b.execute_nurse_skin(b.a[0],'nurse_n',b.a[0]['skill'])
            self.assertEqual(actual,b.a[0]['hp']-5000);self.assertEqual(actual,int(700*.8*rate))

    def test_effect_sequence_bond_scales_attribute_buffs_and_growth(self):
        from bonds_104 import _scale_skill
        aid=next(a for a,h in self.cfg['avatar'].items() if h['name']=='猎手薇恩' and a.endswith('_6'))
        bond=next(b for b in self.cfg['system_simple']['bonds_104'] if b['id']=='b088')
        original=self.cfg['avatar'][aid]['pl'][11]
        enhanced=skill_ids(self.cfg,aid,[bond])['leader_skill']
        seen=[]
        for before,after in zip(self.cfg['skill'][original]['skill'],self.cfg['skill'][enhanced]['skill']):
            if before[:2]==['mod_step','buff'] and before[8] in ('fleeup','critup'):
                self.assertEqual(before[7],10000);self.assertEqual(after[7],13200);seen.append(before[8])
        self.assertEqual(set(seen),{'fleeup','critup'})
        row=copy.deepcopy(self.cfg['skill'][original]);index=next(i for i,a in enumerate(row['skill']) if a[8]=='fleeup')
        row['skillUp']=[[index,7,100]];scaled=_scale_skill(row,1.32)
        self.assertEqual(scaled['skillUp'],[[index,7,132]])

    def test_native_skill_quality_is_independent_of_mechanism_source(self):
        p=self.profile(['A_1001_6'])
        row=self.native.native(p,self.cfg)['units'][0]
        self.assertEqual(int(row['captainStar']),6)
        self.assertEqual(row['captainMechanism'],'S_301001_5')
        self.native.compare(p,self.doc)

    def test_backup_turret_executes_actual_client_summon_action(self):
        sys.path.insert(0,str(ROOT/'scripts'))
        from test_summon_panel_103_client import translated
        aid='A_1014_6';sid=self.cfg['avatar'][aid]['pl'][13];step=self.cfg['skill'][sid]['skill'][0]
        body=translated((ROOT/'client/src/stages/139_SkillSet.as').read_text('utf-8'),'executeModStep')
        script=r'''
const input=JSON.parse(require('fs').readFileSync(0,'utf8')),int=Math.trunc,added=[];
const GlobalData={$mConfig_avatar:{[input.step[11]]:input.definition},modDefinitionId:id=>id};
const GameMapConfig={SUMMON_POS:200},GameMap={actionDelay:0,currentMap:{addAvatar:u=>added.push(u)}};
const DisplayTools={getAttrs:()=>null};
function Avatar(id){this.id=id;this.hp=1;this.goFight=()=>{};this.addBuff=(name,turns)=>this.buff=[name,turns];this.dead=()=>{};}
const owner={hp:10000,team:1,line:0,pos:1500,lv:60,getDamage:()=>1000,getHpMax:()=>10000,getDePh:()=>300,getDeMa:()=>200,getHit:()=>100,getFlee:()=>100,getCrit:()=>100,getTough:()=>100};
const skill={avatar:owner,skillSetData:{id:input.sid},isModEffectSequence:()=>true,modStepAnchors:[],modEventContext:null,modSelectTargets:()=>[owner]};
skill.execute=eval('(function(step,index){with(this){'+input.body+'}})');
skill.execute(input.step,0);skill.execute(input.step,0);
console.log(JSON.stringify(added.map(u=>({id:u.id,hp:u.hp,ap:u.ap,buff:u.buff}))));
'''
        run=subprocess.run(['node','-e',script],input=json.dumps(dict(body=body,step=step,sid=sid,definition=self.cfg['avatar'][step[11]])),capture_output=True,text=True,encoding='utf-8')
        self.assertEqual(run.returncode,0,run.stderr)
        self.assertEqual(json.loads(run.stdout),[dict(id='A_2001_4',hp=0,ap=1000,buff=['summon',2]),dict(id='A_2001_4',hp=10000,ap=1000,buff=['summon',2])])

if __name__=='__main__':unittest.main()
