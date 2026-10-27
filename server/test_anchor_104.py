"""Anchor arithmetic, real client aggregation, and revised UI/config contracts."""
import copy,json,re,unittest
from pathlib import Path
from power_balance_104 import normalize_team_power,apply_power_balance_104
from test_stat_power_103 import StatPower103Tests
from test_avatar_passive import method_body
from test_playtest_client import PlaytestClientTests
from battle_engine import base_unit
from skill_description_104 import scale_manual_output_text
ROOT=Path(__file__).resolve().parents[1]
class Anchor104Tests(unittest.TestCase):
    run_js=PlaytestClientTests.run_js
    def test_anchor_large_and_split_team(self):
        self.assertEqual(normalize_team_power(1_000_000),1_000_000)
        self.assertEqual(normalize_team_power(10_000_000_000),1_000_000_000)
        self.assertEqual(normalize_team_power(0),0)
        self.assertEqual(normalize_team_power(float('nan')),0)
        body=method_body((ROOT/'client/src/stages/137_Avatar.as').read_text('utf8'),'normalizeTeamPower104')
        team=method_body((ROOT/'client/src/stages/170_GlobalFunction.as').read_text('utf8'),'getTeamPower').replace(' is Array',' instanceof Array')
        script='''const int=Number;const GlobalData={$userData:{avatars:{a:{},b:{}},as_equips:[]}};
const Tools={strIsNull:s=>!s};const getRosterTalentPreview=()=>({});
function Avatar(id){this.setEquips=()=>{};this.setDestinyAndDN=()=>{};this.initFightAttr=()=>{};this.clear=()=>{};this.getPowerBase104=()=>id==='a'?250000:750000;this.getPower=()=>{throw Error('per-hero normalization');};}
'''+ 'Avatar.normalizeTeamPower104=function(value){'+body+'};function team(param1,param2=null){'+team+'};console.log(JSON.stringify(team(["a","b"])));'
        self.assertEqual(self.run_js(script),1_000_000)
    def test_recommendations_all_modes_no_stat_change(self):
        stage={'ulv':1,'team2':[['A_1001_6',99,10]],'recommended_power_by_diff':{'0':1e6,'1':1e10},'enemy_unit_stats_by_diff':{'0':[{'hp':123,'ap':45}]}}
        doc={'cfg':{'system_simple':{},'talent':{},'combat_main':{'M_030_1':copy.deepcopy(stage)},'combat_ploy':{'P_001_1':copy.deepcopy(stage),'P_200_151':copy.deepcopy(stage)}}}
        apply_power_balance_104(doc)
        for table in ('combat_main','combat_ploy'):
            for row in doc['cfg'][table].values():
                self.assertEqual(row['recommended_power_by_diff'],{'0':1000000,'1':1000000000})
                for key in ('team2','enemy_unit_stats_by_diff'):self.assertEqual(row[key],stage[key])
        before=copy.deepcopy(doc);apply_power_balance_104(doc);self.assertEqual(doc,before)
    def test_manual_final_values_preserve_control_summon(self):
        row={'info':'伤害100%；破甲20%；分身30%。','rankInfoTemplate':'伤害{scale:100:10}；破甲{scale:20:2}；分身{scale:30:3}。'}
        scale_manual_output_text(row,'wukong_n',1.56,all_effects=True)
        scale_manual_output_text(row,'wukong_n',.8)
        self.assertEqual(row['info'],'伤害124.8%；破甲31.2%；分身46.8%。')
        self.assertIn('{scale:124.8:12.48}',row['rankInfoTemplate'])
        self.assertNotIn('系数',row['info'])
    def test_passive_health_gate_policy(self):
        plan=json.loads((ROOT/'config/reconstruction/orange-ascension-1.0.4.json').read_text('utf8'))
        removed={1002,1003,1007,1008,1009,1010,1018,1019,1020,1021}
        for h in plan['heroes']:
            n=int(h['id'].split('_')[1]);trigger=h['passive']['trigger']
            if n in removed:
                self.assertNotIn('hpBelow',trigger);self.assertNotIn('otherHpBelow',trigger)
                self.assertNotIn('生命不高于',h['passive']['description'])
        jax=next(h['passive'] for h in plan['heroes'] if h['id']=='A_1008_6')
        self.assertEqual(jax['actions'][0]['attackRatio'],4.5)
        self.assertEqual(jax['trigger']['event'],'dodge');self.assertEqual(jax['trigger']['requiredBuff'],'shield')
    def test_popup_status_and_escaped_colored_content(self):
        body=method_body((ROOT/'client/src/stages/143_LOL_DetailAvatar.as').read_text('utf8'),'bondInfoHtml104')
        body=re.sub(r'for each\(var (\w+) in ([^)]+)\)',r'for(var \1 of \2)',body)
        script='const GlobalConfig={FONT_0:"font"};function show(entry){'+body+'};console.log(JSON.stringify([true,false].map(isOK=>show({isOK,info:"组合：甲、乙\\n技能：护盾提高20.0%"}))));'
        active,inactive=self.run_js(script)
        self.assertIn('#167431',active);self.assertIn('已激活',active)
        self.assertIn('#777777',inactive);self.assertIn('未激活',inactive)
        for color in ('#63350D','#55306B','#9C3028'):self.assertIn(color,active)
    def test_equipment_reverse_lookup_includes_ordinary_and_exclusive(self):
        body=method_body((ROOT/'client/src/stages/174_LOL_DetailEquip.as').read_text('utf8'),'equipmentBondInfo104')
        body=re.sub(r'for each\(var (\w+) in ([^)]+)\)',r'for(var \1 of \2)',body)
        script='''const GlobalData={$mConfig_simple:{equipment_bonds_104:{a:[{equipment:'e',info:'伤害提升',kind:'ordinary'}],b:[{equipment:'e',info:'额外护盾',kind:'exclusive'}],c:[{equipment:'other',info:'不显示'}]}},$mConfig_avatar:{a:{name:'甲'},b:{name:'乙'},c:{name:'丙'}}};const SkillSet={conciseInfo104:s=>s};'''+ 'function info(eid){'+body+'};console.log(JSON.stringify(info("e")));'
        result=self.run_js(script)
        self.assertIn('甲装备时',result);self.assertIn('乙装备时',result);self.assertNotIn('丙',result)
if __name__=='__main__':unittest.main()
