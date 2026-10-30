import copy
import json
import re
import subprocess
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts'))
from gateway import Backend
from skill_output_104 import apply_skill_output_104, output_paths
from battle_engine import _native_skill_snapshot, ReferenceBattle
from test_avatar_passive import method_body
import test_curse_combat


class SkillOutput104Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with patch('skill_output_104.apply_skill_output_104',side_effect=lambda d:d), patch('skill_rank_growth_104.apply_skill_rank_growth_104',side_effect=lambda d:d):
            backend=Backend(':memory:',ROOT/'config/reconstruction/full-config.json')
        cls.before=copy.deepcopy(backend.config);backend.db.close()
        cls.after=apply_skill_output_104(copy.deepcopy(cls.before))

    def test_all_selected_coefficients_and_growth_scale_once_buffs_remain_exact(self):
        old=self.before['cfg'];new=self.after['cfg']
        for sid in new['skill_output_104']['skills']:
            base=old['skill'].get(sid)
            if base is None:
                base=old['skill'][new['skill'][sid]['res']]
            row=new['skill'][sid]
            for level in (1,10):
                before=_native_skill_snapshot({'skill':{sid:base}},sid,level)['skills']
                after=_native_skill_snapshot(new,sid,level)['skills']
                expected=copy.deepcopy(before)
                for action in expected:
                    for path in output_paths(action):
                        target=action
                        for index in path[:-1]:target=target[index]
                        target[path[-1]]*=.8
                def compare(actual,wanted):
                    if isinstance(wanted,list):
                        self.assertEqual(len(actual),len(wanted),(sid,level))
                        for a,b in zip(actual,wanted):compare(a,b)
                    elif type(wanted) in (int,float):
                        self.assertAlmostEqual(actual,wanted,places=8,msg=(sid,level))
                    else:self.assertEqual(actual,wanted,(sid,level))
                compare(after,expected)
            for key in ('pl','actionTargetPolicies','actionTargetPolicyArgs','actionTargetMaxTargets',
                        'manualEffectMultiplier','manualDefenseBuffMultiplier','manualSummonPolicy'):
                self.assertEqual(row.get(key),base.get(key),(sid,key))
        twice=apply_skill_output_104(copy.deepcopy(self.after))
        self.assertEqual(twice,self.after)

    def test_damage_heal_shield_and_mixed_buff_example(self):
        actions=[['weak_percent',5,2,.3,2,'fx'],['caster_hp_shield',.5,2,'fx'],
                 ['cure',4,'fx'],['strong',.25,2,'fx'],['manual_dot','burn',3,.1,4]]
        self.assertEqual(output_paths(actions[0]),{(1,)})
        self.assertEqual(output_paths(actions[1]),{(1,)})
        self.assertEqual(output_paths(actions[2]),{(1,)})
        self.assertEqual(output_paths(actions[3]),set())
        self.assertEqual(output_paths(actions[4]),{(2,),(3,)})

    def test_shared_monster_and_equipment_rows_and_hero_panels_are_unchanged(self):
        old=self.before['cfg'];new=self.after['cfg']
        foreign={h['pl'][i] for aid,h in old['avatar'].items() if not aid.startswith('A_1') and not h.get('builtin_pack_104')
                 for i in (10,11,13) if len(h['pl'])>i and h['pl'][i]}
        foreign.update(e.get('skill') for e in old['equip'].values())
        for sid in foreign:
            if sid:self.assertEqual(old['skill'][sid],new['skill'][sid],sid)
        for aid,hero in old['avatar'].items():
            self.assertEqual(hero['pl'][:10],new['avatar'][aid]['pl'][:10],aid)

    def test_native_manual_helpers_scale_damage_healing_shield_not_control(self):
        source=(ROOT/'client/src/stages/137_Avatar.as').read_text('utf-8')
        params={'heroSkillOutputRate104':'','abilityHit':'target,coefficient,kind,effect,sharedTotal=0,visualSource=null',
                'abilityHeal':'target,coefficient','abilityShield':'target,coefficient,duration=2,healthOnly=false',
                'abilityControl':'target,kind,duration,value=0'}
        methods={n:[p,test_curse_combat.CurseClientCombatTests.translate(method_body(source,n))] for n,p in params.items()}
        script=r'''
const input=JSON.parse(require('fs').readFileSync(0,'utf8')),out=[],int=Math.trunc;
const GlobalData={$mConfig_simple:{hero_skill_output_rate_104:.8}},Tools={toInt:Math.trunc},REAL_DAMAGE_RATE=.3;
const unit={flushParallelVisualBatch:()=>{},equipmentOutputRate104:()=>1,hp:1000,getType:()=>1,getHpMax:()=>10000,getDamage:()=>1000,purpleBondMultiplier:()=>1};
const context={owner:unit,manualDamageMultiplier:1.5,hitSerial:0};
unit.currentAbilityAttack=()=>context;
unit.attackAimList=(targets,type,coef)=>out.push(['output',type,coef]);
for(const [n,[p,b]] of Object.entries(input))unit[n]=eval('(function('+p+'){with(this){'+b+'}})');
const target={hp:10000,buffs:{},abilityState:{},addBuff:(...args)=>out.push(args)};
unit.abilityHit(target,2,1,'fx');unit.abilityHeal(target,2);unit.abilityShield(target,.5);
unit.abilityControl(target,'weak',3,.25);
unit.getType=()=>2;unit.abilityHit(target,2,1,'fx');
console.log(JSON.stringify(out));
'''
        run=subprocess.run(['node','-e',script],input=json.dumps(methods),text=True,capture_output=True,encoding='utf-8')
        self.assertEqual(run.returncode,0,run.stderr)
        out=json.loads(run.stdout)
        self.assertAlmostEqual(out[0][2],2.4)
        self.assertEqual(out[1:], [['output',4,1.6],['shield',2,800],['weak',3,.25],['output',1,3]])

    def test_poison_health_damage_rate_does_not_change_poison_debuff(self):
        target={'aid':'A_1001_5','hp':10000,'hp_max':10000,'_buffs':{}}
        battle=ReferenceBattle([],[],config=self.after['cfg'])
        battle._add_buff(target,'poison',2,100,poison_hp_rate_104=.8)
        poison=target['_buffs']['poison']
        self.assertEqual(poison.poison_hp_rate_104,.8)
        self.assertEqual(poison.value,100)
        battle._add_buff(target,'poison',2,100,poison_hp_rate_104=.8)
        self.assertEqual(poison.poison_hp_rate_104,.8)
        battle._add_buff(target,'poison',2,100,poison_hp_rate_104=1)
        self.assertEqual(poison.poison_hp_rate_104,1)


if __name__=='__main__':unittest.main()
