"""PR #15: execute the shipped AS3 summon method and the Python action.

AS3 type annotations are removed for Node; rendering and map collision are
stubbed. This is behavioral coverage, not an SWF compilation/runtime test.
"""
import copy
import json
import re
import subprocess
import sys
import unittest
from collections import Counter

from test_avatar_passive import NODE, ROOT, method_body
sys.path.insert(0, str(ROOT / 'server'))
from battle_engine import ReferenceBattle, _native_skill_snapshot

CFG = json.loads((ROOT / 'config/reconstruction/full-config.json').read_text())['cfg']
FAMILY = 'manual-1212-zongzi'

HARNESS = r'''
const fs=require('node:fs'),vm=require('node:vm');
const input=JSON.parse(fs.readFileSync(0,'utf8')),noop=()=>{};
const units=input.units, owner=units[0];
owner.manualSummonFamilies={'manual-1212-zongzi':units.filter(u=>u.owned)};
Object.assign(owner,{lv:100,avatarData:{},skillB:null,
 getDamage(){return 100;},getHpMax(){return 1000;},getDePh(){return 0;},getDeMa(){return 0;}});
const map={winnerList:Array(input.lanes).fill(0),
 getLineAliveList(team,line){return units.filter(u=>u.team===team&&u.line===line&&u.hp>0);},
 getFinalPos(team,line,pos){return Math.max(0,Math.min(3000,pos));},
 addAvatar(u,team,line,pos){Object.assign(u,{team,line,pos,owned:true});units.push(u);}};
function Avatar(){this.hp=1;this.goFight=noop;this.addBuff=noop;this.dead=()=>{this.hp=0;};}
Avatar.isValidSummonMultiplier=v=>Number.isFinite(v)&&v>0;
const math=Object.create(Math); math.random=()=>input.random||0;
const context=vm.createContext({Math:math,Number,String,isFinite,int:v=>Math.trunc(Number(v)),Avatar,
 GameMap:{currentMap:map,actionDelay:0},GameMapTools:{gameTrace:noop},
 Tools:{toInt:Math.trunc},GlobalData:{$mConfig_skill:{}},DisplayTools:{getAttrs(){return null;}},
 GameMapLayer:{gl:{delayCall:noop,effectLayer:{}}}});
function bind(obj,name,params,body){obj[name]=vm.runInContext('(function('+params+'){with(this){'+body+'\n}})',context);}
for(const [name,params,body] of input.avatarMethods)bind(owner,name,params,body);
const skill={avatar:owner,skillSetData:input.row,getActionPolicy(){return 'ally_self';},
 getCustomActionTargets(){return [owner];},getActionPolicyArgs(){return null;},
 isNativeCloneSummonSkill(){return false;}};
for(const [name,params,body] of input.skillMethods)bind(skill,name,params,body);
const history=[];
for(const op of input.ops){
 if(op.kill!==undefined){const live=units.filter(u=>u.owned&&u.hp>0&&u.line===op.kill);if(live.length)live[0].hp=0;}
 else if(op.move!==undefined)owner.line=op.move;
 else skill.executeManualSummon(input.row.skill[0],0,[],{});
 history.push(units.filter(u=>u.owned&&u.hp>0).map(u=>({line:u.line,pos:u.pos})));
}
process.stdout.write(JSON.stringify(history));
'''


def translated(source, name):
    return re.sub(r'new Vector\.<\w+>\(\)', '[]', method_body(source, name))


class Scenarios:
    def test_multilane_six_cap_and_death_reopens_slot(self):
        history = self.simulate([{}]*7 + [{'kill': 0}, {}])
        self.assertEqual([len(h) for h in history], [1,2,3,4,5,6,6,5,6])
        self.assertEqual(Counter(u['line'] for u in history[5]), {0:2,1:2,2:2})
        self.assertEqual(history[5], history[6])  # Full cast must not replace an old summon.
        self.assertTrue(all(max(Counter(u['line'] for u in h).values(), default=0)<=2 for h in history))

    def test_full_neighbor_is_excluded(self):
        initial = [{'line':lane,'pos':1000,'hp':100,'owned':True} for lane in [1,1,0,0]]
        history=self.simulate([{}], initial=initial)
        self.assertEqual(Counter(u['line'] for u in history[0]), {0:2,1:2,2:1})

    def test_zero_based_edges_and_actual_map_size(self):
        for lanes,anchor in [(1,0),(2,0),(2,1),(3,0),(3,2)]:
            history=self.simulate([{}]*5,lanes=lanes,anchor=anchor)
            expected=2 if lanes==1 else 4
            self.assertEqual(len(history[-1]),expected)
            self.assertTrue(all(0<=u['line']<lanes for u in history[-1]))

    def test_both_random_neighbors_are_reachable(self):
        for random,expected in [(0,0),(.9,2)]:
            history=self.simulate([{}, {}, {}],random=random)
            self.assertEqual(history[-1][-1]['line'], expected)

    def test_neighbor_front_placement_and_empty_lane_fallback(self):
        for team in (1,2):
            friends=[{'line':0,'pos':900,'hp':100}, {'line':0,'pos':1400,'hp':100}]
            h=self.simulate([{}, {}, {}],friends=friends,team=team)
            self.assertEqual(h[-1][-1]['pos'], 850 if team==1 else 1450)
            h=self.simulate([{}, {}, {}],team=team)
            self.assertEqual(h[-1][-1]['pos'], 1950 if team==1 else 2050)

    def test_only_adjacent_lane_is_eligible(self):
        h=self.simulate([{}]*5, anchor=0)
        self.assertEqual(Counter(u['line'] for u in h[-1]), {0:2,1:2})


class ServerZongziTests(Scenarios,unittest.TestCase):
    @staticmethod
    def live(owner):
        return [u for u in owner['_team'] if u.get('aid')=='A_2014_5'
                and u.get('summon_owner_token')==owner['_owner_token'] and u['hp']>0]

    def make_battle(self, units, lanes=3, team=1):
        b=ReferenceBattle(units if team==1 else [],units if team==2 else [],config=CFG)
        b.lane_count=lanes
        roster=b.a if team==1 else b.b
        owner=roster[0];owner['_team']=roster
        for u in roster[1:]:
            if u.get('owned'):
                u.update(aid='A_2014_5',summon_owner_token=owner['_owner_token'],
                         _bounded_summon=True,_bounded_summon_skill='S_9162_6')
        return b,owner

    def simulate(self,ops,initial=(),friends=(),lanes=3,anchor=1,team=1,random=0):
        units=[dict(aid='A_1212_6',hp=1000,hp_max=1000,ap=100,lv=100,line=anchor,pos=2000,isme=team==1)]
        units += [dict(u,isme=team==1) for u in list(initial)+list(friends)]
        b,owner=self.make_battle(units,lanes,team)
        b.rng.get_random=lambda maximum: int(random*maximum)
        skill=_native_skill_snapshot(CFG,'S_9162_6');history=[]
        for op in ops:
            if 'kill' in op:
                next(u for u in self.live(owner) if u['line']==op['kill'])['hp']=0
            elif 'move' in op: owner['line']=op['move']
            else: b._act_summon(owner,[],owner['_team'],skill,skill['skills'][0],0,{'targets':{}})
            history.append([dict(line=u['line'],pos=u['pos']) for u in self.live(owner)])
        return history

    def test_owner_isolation_and_scent(self):
        initial=[dict(aid='A_1212_6',line=1,pos=2000,isme=True,hp=100,hp_max=10000,ap=100,
                      new_4attrs={k:100 for k in ('hit','flee','crit','tough')}),
                 dict(aid='A_1212_6',line=2,pos=2000,isme=True,hp=100,hp_max=10000,ap=100)]
        b,owner=self.make_battle(initial);other=b.a[1];other['_team']=b.a
        action=CFG['skill']['S_9162_6']['skill'][0]
        for hero in (owner,owner,other):
            b._act_summon(hero,[],b.a,{'skid':'S_9162_6'},action,0,{'targets':{}})
        self.assertEqual(len(self.live(owner)),2)
        skill=_native_skill_snapshot(CFG,'S_9163_6')
        expected=b._heal_channel_value(owner,.2*3)
        b._act_zongzi_scent(owner,[],b.a,skill,skill['skills'][0],0,{})
        self.assertEqual(other['hp'],100+expected)
        for target in (owner,other):
            self.assertEqual(b._buff_value(target,'hitup'),45)
        self.live(owner)[0]['hp']=0
        self.assertEqual(len(self.live(owner)),1)
        # Dead and foreign-owner summons cannot amplify the next cast.
        for u in b.a:u['_buffs']={}
        b._act_zongzi_scent(owner,[],b.a,skill,skill['skills'][0],0,{})
        self.assertEqual(b._buff_value(other,'hitup'),30)

    def test_other_bounded_families_keep_one_slot(self):
        b,owner=self.make_battle([dict(aid='A_1001_6',hp=1000,line=0,pos=2000,isme=True)])
        b.a.append(dict(hp=100,_bounded_summon=True,_bounded_summon_skill='S_303029_6',
                        summon_owner_token=owner['_owner_token']))
        self.assertTrue(b._has_live_bounded_summon(owner,'S_303029_6'))
        self.assertFalse(b._has_live_bounded_summon(owner,'S_9162_6'))


@unittest.skipUnless(NODE,'Node is required to execute translated AS3 methods')
class ClientZongziTests(Scenarios,unittest.TestCase):
    def test_scent_uses_only_living_owner_family_across_lanes(self):
        source=(ROOT/'client/src/stages/139_SkillSet.as').read_text()
        av=(ROOT/'client/src/stages/137_Avatar.as').read_text()
        case=source.split('case "zongzi_scent":',1)[1].split('case "locked_sequence":',1)[0]
        body=translated('function scent():void {'+case.replace('break;', 'return;')+'}', 'scent')
        harness=r'''const vm=require('node:vm'),fs=require('node:fs');
const input=JSON.parse(fs.readFileSync(0,'utf8'));
const targets=[{line:0},{line:1},{line:2}], calls=[];
const avatar={team:1,hit:100,flee:200,crit:300,tough:400,
 manualSummonFamilies:{'manual-1212-zongzi':[{hp:1,line:0},{hp:1,line:2},{hp:0,line:1}]},
 findAimList(list){return list;},getSortOnFun(){return null;},
 attackAimList(list,type,value,aoe,fx,unused,buff){calls.push({n:list.length,type,value,buff});}};
const context=vm.createContext({avatar,int:Math.trunc,Tools:{toInt:Math.trunc},GameMap:{actionDelay:0},
 Buff:function(name,turns,value){Object.assign(this,{name,turns,value});},
 _loc20_:['zongzi_scent',.2,.15,2,'FX'],_loc26_:{getAliveList(){return targets;}},
 _loc14_:0,_loc24_:0,_loc2_:0,_loc7_:0,actionTargets:{},targetGroups:{},
 applyActionTargetLinks:x=>x,applyActionTargetPolicy:x=>x,
 getActionSortFunction:()=>null,getActionRange:()=>3000,getActionAoeIndex:()=>0});
vm.runInContext('avatar.countManualSummonAlive=function(param1){with(this){'+input.count+'}}',context);
vm.runInContext('(function(){'+input.body+'})()',context);
process.stdout.write(JSON.stringify(calls));'''
        result=subprocess.run([NODE,'-e',harness],input=json.dumps(dict(body=body,
            count=translated(av,'countManualSummonAlive'))),text=True,capture_output=True)
        self.assertEqual(result.returncode,0,result.stderr)
        calls=json.loads(result.stdout)
        self.assertAlmostEqual(calls[0]['value'],.6)
        self.assertEqual([c['buff']['value'] for c in calls[1:]],[45,90,135,180])
        self.assertTrue(all(c['n']==3 for c in calls))

    def simulate(self,ops,initial=(),friends=(),lanes=3,anchor=1,team=1,random=0):
        source=(ROOT/'client/src/stages/139_SkillSet.as').read_text()
        av=(ROOT/'client/src/stages/137_Avatar.as').read_text()
        skills=[('executeManualSummon','param1,param2,param3,param4'),
                ('chooseZongziSummonLine','anchorLine'),('isManualSummonPolicyAllowed','')]
        avatars=[('getManualSummonSlots','param1,param2'),('registerManualSummon','param1,param2,param3')]
        units=[dict(line=anchor,pos=2000,hp=1000,team=team)]
        units += [dict(u,team=team) for u in list(initial)+list(friends)]
        payload=dict(units=units,lanes=lanes,ops=ops,random=random,row=CFG['skill']['S_9162_6'],
                     skillMethods=[(n,p,translated(source,n)) for n,p in skills if 'function '+n+'(' in source],
                     avatarMethods=[(n,p,translated(av,n)) for n,p in avatars])
        result=subprocess.run([NODE,'-e',HARNESS],input=json.dumps(payload),text=True,capture_output=True)
        self.assertEqual(result.returncode,0,result.stderr)
        return json.loads(result.stdout)

if __name__=='__main__':unittest.main()
