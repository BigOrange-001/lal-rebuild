"""Differential checks: execute real AS getters and compare server snapshots."""
import copy
import json
import re
import shutil
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
from test_avatar_passive import method_body
from battle_engine import base_unit, _native_skill_snapshot
from gameplay_competition import GameplayCompetition
from gameplay_roster import GameplayRosterEquipment
from gateway import Backend
from talent_stats_103 import apply_talent_stats_103


def methods(filename, definitions):
    source = (ROOT / 'client/src/stages' / filename).read_text('utf-8')
    result = {}
    for name, params in definitions.items():
        body = method_body(source, name)
        body = re.sub(r'for each\(var (\w+) in (\w+\(\)|[^)]+)\)', r'for(var \1 of Object.values(\2))', body)
        body = re.sub(r'for each\((\w+) in ([^)]+)\)', r'for(\1 of Object.values(\2))', body)
        body = re.sub(r'(\w+(?:\.\w+|\[\w+\])*) is Array', r'Array.isArray(\1)', body)
        body = re.sub(r'(\w+) is String', r'typeof \1 === "string"', body)
        result[name] = [params, body]
    return result


HARNESS = r'''
const input=JSON.parse(require('fs').readFileSync(0,'utf8'));
const cfg=input.cfg,profile=input.profile,int=v=>Math.trunc(Number(v)||0),uint=int,trace=()=>{};
const Tools={toInt:v=>int(Number(Number(v).toFixed(5)))};
const GlobalData={modChannelAllowed:(aid,key)=>cfg.mod_runtime?.heroes?.[aid]?.channels?.[key]!==false,$userData:profile,$mConfig_simple:cfg.system_simple,$mGuild_simple:cfg.association_simple,$mConfig_talent:cfg.talent,$mConfig_avatar:cfg.avatar,$mConfig_skill:cfg.skill};
const GameMap={currentMap:null};
const GlobalFunction={setOtherCfgAvatar:()=>{throw Error('stale owned DN snapshot was used');}};
function attach(unit,definitions){for(const [name,[params,body]] of Object.entries(definitions))unit[name]=eval('(function('+params+'){with(this){'+body+String.fromCharCode(10)+'}})');return unit;}
function Skill(sid,lv=1,superSkill=false,book=false){
 if(!sid||!cfg.skill[sid])return null;
 let row=cfg.skill[sid],actions=JSON.parse(JSON.stringify(row.skill||[]));
 let up=row.skillUp;
 if(Array.isArray(up)&&up.length){if(Array.isArray(up[0])){for(let [a,v,step] of up)actions[a][v]+=step*(lv-1);}
 else actions[up[0]][1]+=up[1]*(lv-1);}
 return attach({skills:actions,skillSetData:row,lv,isSuper:superSkill,isBookSkill:book||!!row.bookRule,
 isEquipUp:actions[0]?.[0]==='equipup',getStar:()=>int(sid.split('_').at(-1))},input.skillMethods);
}
function SkillSet(sid,owner,lv=1,superSkill=false){return Skill(sid,lv,superSkill);}
function Equipment(id){
 let row=profile.my_equips[id],d=cfg.equip[row.eid],p=d.pl;
 let unit=attach({my_data:row,id,lv:row.lv||1,slv:row.slv||1,haloLv:row.halo?.lv||row.haloLv||0,
 magic:row.magic||[0,0,0,0],magicStage5:row.magic_stage5||0,symp:row.symp??-1,runeLv:row.rune_lv||0,
 _Properties_rate:1,equipData:{id:row.eid,hp0:p[0],ap0:p[1],d10:p[2],d20:p[3],speed:p[4],range:p[5],hasAttr:k=>p.slice(6,8).includes(k)}},input.equipMethods);
 for(let key of ['hit','flee','crit','tough'])unit[key]=(row.new_4attrs||row)[key]||0;
 if(row.alchemy){let key=(int(row.eid.split('_').at(-1))+int(row.alchemy[1]))+'_'+row.alchemy[0];
 if(cfg.system_simple.equip_alchemy.phase[key])unit._Properties_rate=unit.getEquipAlchemyRate(row,0);}
 return unit;
}
function Avatar(id,data=null){
 let row=data||profile.avatars[id],aid=(row.aid||id).split('|')[0],d=cfg.avatar[aid],p=d.pl;
 let tid=typeof row.talent==='string'?row.talent:row.talent?.id,t=cfg.talent[tid];
 let unit=attach({id,mData:row,team:0,otherTeam:0,isOthers:false,lv:row.lv||1,slv:row.slv||1,phase:row.phase||0,
 hp:0,hpMax:0,ap:0,dePh:0,deMa:0,hit:0,flee:0,crit:0,tough:0,speed:0,range:0,
 hpP:row.hp||0,apP:row.ap||0,dePhP:row.de_ph||0,deMaP:row.de_ma||0,cultureSchema:row.culture_schema||'',
 equips:[],bondLineup104:profile.team[0],mDestiny:null,mDNdata:null,buffs:{},abilityState:{},abilityEntryAttack:0,manualAttackRangeOverride:NaN,
 initializingFightAttributes:false,previewTeamTalentBonuses:null,getManualBattleStack:()=>0,getManualTimedStack:()=>0,clear:()=>{},
 avatarData:{id:aid,hp0:p[0],hp1:p[1],ap0:p[2],ap1:p[3],d10:p[4],d11:p[5],d20:p[6],d21:p[7],speed:p[8],range:p[9],skill0:p[10],skill1:p[11]},
 skill0:Skill(p[10],row.slv||1),skill1:Skill(p[11],1,true),skillB:Skill(p[13]),skill2:null,
 talent:t?{my_HaloData:{dataObj:t,plType:t.pl[0],plNum:t.pl[1],plUse:t.pl[2],getStar:()=>int(tid.split('_').at(-1))}}:null},input.avatarMethods);
 if(unit.talent)attach(unit.talent,input.talentMethods);
 return unit;
}
Avatar.POWER_SKILL_0_STAR=.1;Avatar.POWER_SKILL_0_LV=.1;Avatar.POWER_SKILL_1_STAR=.5;
const POWER_HP=.5,POWER_DAMAGE=2,POWER_DE_PH=.625,POWER_DE_MA=.625,POWER_SPEED_RANGE=1000,POWER_RATE=1e-8;
const dn=attach({getDNattrName:k=>k},input.dnMethods);
attach(GlobalFunction,input.projectionMethods);
const preview=GlobalFunction.getRosterTalentPreview(profile.team[0]);
let bonus=dn.getDNAttrsAllValue();
let out=[];
for(let [slot,id] of profile.team[0].entries()){
 if(!id)continue;
 let unit=new Avatar(id);
 unit.equips=(profile.as_equips[slot]||[]).filter(id=>profile.my_equips[id]).map(Equipment);
 unit.mDNdata=bonus;
 unit.previewTeamTalentBonuses=preview;
 for(let eid of profile.as_equips[slot]||[]){let e=profile.my_equips[eid];if(!e)continue;
 let row=cfg.equip[e.eid];if(row.type===6&&row.skill){unit.skill2=Skill(row.skill,e.slv||1,false,true);break;}}
 const barePower=unit.getPower(slot===0,-1,true);
 unit.initFightAttr();
 out.push({id,hp:unit.getHpMax(),ap:unit.getDamage(),de_ph:unit.getDePh(),de_ma:unit.getDeMa(),
 speed:unit.getSpeed(),range:unit.getRange(),hit:unit.hit,flee:unit.flee,crit:unit.crit,tough:unit.tough,
 power:unit.getPower(slot===0,-1,true),beforeInitPower:barePower,skillId:unit.skill0?.skillSetData.id,captainId:unit.skill1?.skillSetData.id});
}
console.log(JSON.stringify({units:out,dn:bonus}));
'''


@unittest.skipUnless(shutil.which('node'), 'Node is needed to execute native AS arithmetic')
class StatPower103Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        backend = Backend(':memory:', ROOT / 'config/reconstruction/full-config.json')
        cls.document = copy.deepcopy(backend.config)
        backend.db.close()
        cls.avatar_methods = methods('137_Avatar.as', {
            'getBondRows104':'','bondPanel104':'stat,value','updateBondSkills104':'','getEquipmentBondRows104':'','equipmentSkillId104':'source','equipmentOutputRate104':'',
            'getHpMax':'param1=-1,param2=-1,param3=false','getDamage':'param1=-1,param2=-1,param3=false',
            'getDePh':'param1=-1,param2=-1,param3=false','getDeMa':'param1=-1,param2=-1,param3=false',
            'getPhysicalDefense':'param1,param2,param3,ignoreSunder','getMagicDefense':'param1,param2,param3,ignoreSunder',
            'getSpeed':'param1=false','getRange':'param1=false','getHit':'','getFlee':'','getCrit':'','getTough':'',
            'getStar':'','getType':'','getPhaseList':'','getPhaseLv':'','getSymp':'',
            'isWeightedCultivation':'','getCultivationGainFromSlope':'param1,param2',
            'applyOwnedGuildResearch':'param1,param2','getBookCombatBonus':'stat','ownGrowthValue':'effect',
            'teamTalentFlat':'effect','getPower':'param1=false,param2=-1,param3=false','initFightAttr':''})
        cls.equip_methods = methods('084_Equip.as', {
            'getHpMax':'param1=-1,param2=false','getDamage':'param1=-1,param2=false',
            'getDePh':'param1=-1','getDeMa':'param1=-1','getSpeed':'','getRange':'',
            'getHit':'param1=-1,param2=false','getFlee':'param1=-1,param2=false',
            'getCrit':'param1=-1,param2=false','getTough':'param1=-1,param2=false',
            'hasHit':'','hasFlee':'','hasCrit':'','hasTough':'','getPoint':'param1=-1',
            'getStar':'','getAddStar':'','getHaloUpAttrs':'','getNativeStatGrowth':'param1',
            'getPersistedStatRollRate':'','getMagicBonus':'param1','getMagicStage':'',
            'getMagicMainStatRate':'','getRuneBonus':'param1','getEquipAlchemyRate':'param1,param2'})
        cls.skill_methods = methods('139_SkillSet.as', {'getPower':'','getEquipRate':'param1'})
        cls.dn_methods = methods('142_PanelDetailDN.as', {'getDNAttrsAllValue':'param1=null','getDNaddValue':'param1,param2'})
        cls.projection_methods = methods('045_GlobalFunction.as', {'getRosterTalentPreview':'ids,extra=null'})
        cls.talent_methods = methods('145_Talent.as', {'getPower':''})

    def profile(self, talent='T_01_06', book='E_6001_5'):
        return {'avatars': {
            'A_1137_6|1': {'aid':'A_1137_6','lv':83,'slv':7,'phase':2,'culture_schema':'weighted-v2',
                            'hp':10452,'ap':2378,'de_ph':1367,'de_ma':1241,'talent':talent},
            'A_1003_5|2': {'aid':'A_1003_5','lv':91,'phase':1,'culture_schema':'weighted-v2',
                            'hp':3210,'ap':278,'de_ph':133,'de_ma':199,'talent':'T_01_04'}},
                'team':[['A_1137_6|1',None,None,None,None,None]],
                'as_equips':[['weapon',None,None,None,None,'book']] + [[] for _ in range(5)],
                'my_equips':{
                    'weapon':{'eid':'E_1001_3','lv':43,'stat_roll_ppm':875123,'alchemy':[1,0],
                              'halo':{'lv':2,'exp':0},'magic':[12,9,8,6],'magic_stage5':1,'symp':0,'rune_lv':3,
                              'new_4attrs':{'hit':25,'crit':45,'flee':0,'tough':0}},
                    'book':{'eid':book,'lv':1,'slv':10,'stat_roll_ppm':1000000}},
                'attrs':{'dn':{'1':[3,'A_1003_5|2',[1,0,0,0,0,0]]},
                         'guild_graduate_skill':{'guild_attack':2,'guild_hp':1}}}

    def native(self, profile, cfg):
        selected = {key:cfg[key] for key in ('system_simple','association_simple','avatar','equip','skill','talent')}
        selected['mod_runtime']=cfg.get('mod_runtime',{})
        payload = {'cfg':selected,'profile':profile,'avatarMethods':self.avatar_methods,'equipMethods':self.equip_methods,
                   'skillMethods':self.skill_methods,'dnMethods':self.dn_methods,'talentMethods':self.talent_methods,
                   'projectionMethods':self.projection_methods}
        run = subprocess.run([shutil.which('node'), '-e', HARNESS], input=json.dumps(payload,default=str),
                             capture_output=True, encoding='utf-8', timeout=20)
        self.assertEqual(run.returncode, 0, run.stderr)
        return json.loads(run.stdout)

    def compare(self, profile, document=None):
        doc = document or self.document
        cfg = doc['cfg']
        native = self.native(profile, cfg)
        roster = GameplayRosterEquipment(None, doc)
        units = []
        for row in native['units']:
            raw = roster.battle_attributes(profile, row['id'])
            for key in ('hp','ap','de_ph','de_ma','speed','range','hit','flee','crit','tough'):
                self.assertEqual(row[key], raw[key], (key, row, raw))
            self.assertEqual(row['power'], row['beforeInitPower'])
            leader = row['id'] == profile['team'][0][0]
            unit = base_unit(cfg, raw['aid'], level=raw['lv'], slv=raw['slv'], leader=leader,
                             overrides={**raw,'leader_skill':raw['leader_skill'] if leader else None,
                                        'new_4attrs':{key:raw[key] for key in ('hit','flee','crit','tough')}})
            units.append(unit)
        self.assertEqual(GameplayCompetition(None, doc)._team_power(units), sum(r['power'] for r in native['units']))
        self.assertEqual(roster._destiny_team_bonuses(profile), {key:native['dn'][key] for key in ('hp','ap','de_ph','de_ma')})

    def test_equipped_panel_and_cached_battle_match_all_three_stat_talents(self):
        for talent in ('T_01_06','T_02_06','T_04_06'):
            for book in ('E_6001_5','E_6002_5'):
                with self.subTest(talent=talent,book=book):
                    self.compare(self.profile(talent,book))

    def test_bare_legacy_cultivation_and_owned_secondary_stats_match(self):
        profile = self.profile()
        profile['attrs']['dn'] = {}
        profile['attrs']['guild_graduate_skill'] = {}
        profile['as_equips'] = [[] for _ in range(6)]
        row = profile['avatars']['A_1137_6|1']
        row.pop('culture_schema')
        row.update(hp=100,ap=50,de_ph=20,de_ma=30,hit=100,flee=50,crit=30,tough=20)
        self.compare(profile)

    def test_speed_and_range_gear_use_native_halo_only_scaling(self):
        doc = copy.deepcopy(self.document)
        doc['cfg']['equip']['E_1001_3']['pl'][4:6] = [17,31]
        self.compare(self.profile(),doc)

    def test_multiple_members_captain_and_living_team_aura_match(self):
        profile = self.profile('T_06_06')
        profile['avatars']['A_1311_5|3'] = {'aid':'A_1311_5','lv':91,'slv':5,'phase':1,
                                           'culture_schema':'weighted-v2','hp':2000,'ap':100,'talent':'T_06_04'}
        profile['team'][0][1] = 'A_1311_5|3'
        self.compare(profile)

    def test_nurse_tank_growth_matches_panel_and_battle_power_for_both_qualities(self):
        for q in (5,6):
            profile=self.profile('T_02_06')
            iid=f'A_1208_{q}|1'
            row=profile['avatars'].pop('A_1137_6|1')
            row['aid']=f'A_1208_{q}'
            profile['avatars'][iid]=row
            profile['team'][0][0]=iid
            self.compare(profile)

    def test_scaling_overlay_is_idempotent_and_does_not_change_other_branches(self):
        original = copy.deepcopy(self.document)
        apply_talent_stats_103(original)
        self.assertEqual(original,self.document)
        self.assertEqual(original['cfg']['talent']['T_01_06']['growth_value'],18)
        self.assertEqual(original['cfg']['talent']['T_04_06']['growth_value'],36)
        self.assertEqual(original['cfg']['talent']['T_03_06']['growth_value'],35)
        self.assertEqual(original['cfg']['talent']['T_06_06']['growth_value'],1750)

    def test_legacy_lowest_talent_and_invalid_weight_produce_finite_matching_power(self):
        self.compare(self.profile('T_01_01'))
        for weight in (-1, 'invalid'):
            document = copy.deepcopy(self.document)
            document['cfg']['system_simple']['talent_power'][4] = weight
            self.compare(self.profile('T_01_06'),document)


if __name__ == '__main__':
    unittest.main()
