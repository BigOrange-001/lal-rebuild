"""Run the actual skill popup layout methods (skill_tips_105.aspart) under Node with stubs."""
import json
from pathlib import Path
import re
import subprocess
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(ROOT / 'scripts'), str(ROOT / 'server')]
from test_skin_revision_native_104 import balanced
from test_dragonmancer_kaisa_native import strip_as_comments


def translate():
    source = strip_as_comments((ROOT / 'client/src/skill_tips_105.aspart').read_text('utf-8'))
    out = []
    for match in re.finditer(r'(?:private|public) static (?:const|var) (\w+):\w+ = (.*?);\n', source, re.S):
        out.append(f'methods.{match[1]}={match[2]};')
    for match in re.finditer(r'(?:private|public)(?: static)? function (\w+)\((.*?)\)\s*:\s*[\w.<>*]+\s*\{', source, re.S):
        start = match.end() - 1
        body = source[start + 1:balanced(source, start)]
        args = re.sub(r':(?:[\w.<>]+|\*)', '', match[2])
        body = re.sub(r'\bvar (\w+)\s*:(?:[\w.<>]+|\*)', r'var \1', body)
        body = re.sub(r'function\(\.\.\. (\w+)\):\w+', r'function(...\1)', body)
        body = re.sub(r'function\((\w+):\w+, (\w+):\w+\):\w+', r'function(\1, \2)', body)
        body = body.replace(' is Array', ' instanceof Array')
        # Static state lives on the shared object, as in ActionScript.
        body = re.sub(r'\btipTerms105 = ', 'methods.tipTerms105 = ', body)
        while 'for each(' in body:
            a = body.index('for each(')
            b = balanced(body, a + 8)
            left, right = body[a + 9:b].split(' in ', 1)
            body = body[:a] + 'for (' + left + ' of Object.values(' + right + '))' + body[b + 1:]
        out.append(f'methods.{match[1]}=function({args}){{with(methods)with(this){{{body}}}}};')
    return '\n'.join(out)


FIXTURE = r'''
const assert=require('assert');
const uint=x=>Number(x)>>>0,int=x=>Math.trunc(Number(x)||0);
const methods={};
let wrapAt=0;
const Tools={formatLineX:(text,colors)=>{assert.equal(colors,'W_W_Y_G');return wrapAt&&text.length>wrapAt?text.slice(0,wrapAt)+'\n'+text.slice(wrapAt):text}};
const GlobalTextStyle={COLOR_W_W_Y_G:'W_W_Y_G'};
const GameMapTools={toPercentage:v=>Math.round(v*100)+'%'};
const Avatar={damageAttack104:()=>{const a=[];a[20]=.5;return a}};
const GlobalLanguageStr={getLanguageStr:(id,v)=>'HP'+id+':'+v};
const GlobalData={$mConfig_skill:{},$mConfig_avatar:{}};
/*METHODS*/
function skill(id,info,warmup,cooldown,aid){
 const s=Object.create(methods);
 s.skillSetData={id,warmup,cooldown,hpType:0};
 s.avatar=aid?{avatarData:{id:aid}}:null;
 s.getInfo=()=>info;
 return s;
}
let cases=0;
{ // Header, body, gray range clause and a glossary note in the native markup.
 const text=skill('S1','对目标造成150%攻击力物理伤害并施加破甲2回合。本分路内不受施法距离限制。',1,3).getInfoDetails();
 assert.equal(text,'{准备:1  冷却:3}\n对目标造成150%攻击力物理伤害并施加破甲2回合。\n(本分路内不受施法距离限制)\n\n[破甲：物防和法防降低]');
 cases++;
}
{ // An effect clause that also mentions reach stays in the main text.
 const text=skill('S2','发射电能攻击一名敌人，造成物理伤害，对其后方所有敌人造成同等伤害并眩晕1回合，可跨路攻击。',0,2).getInfoDetails();
 assert.ok(text.includes('可跨路攻击。'));assert.ok(!text.includes('(可跨路'));
 assert.ok(text.includes('[眩晕：无法行动]'));
 cases++;
}
{ // Authored ASCII brackets cannot turn into color markers.
 const text=skill('S3','造成(测试)[伤害]{x}',0,0).getInfoDetails();
 assert.ok(text.includes('造成（测试）【伤害】｛x｝'));
 cases++;
}
{ // Hero notes come first; mechanic names are not explained by the glossary.
 GlobalData.$mConfig_avatar.A_T={tipTerms105:{'怒气':0xFF8A1E,'无尽怒火':0xFF3D6E}};
 GlobalData.$mConfig_skill.S4={tipNotes105:[['怒气','上限100。'],['无尽怒火','免疫诅咒，期间生命不低于1。']]};
 const s=skill('S4','受到致死伤害时进入无尽怒火，获得神佑。',0,0,'A_T');
 const text=s.getInfoDetails();
 assert.equal(text.split('\n\n')[1],'[怒气：上限100。]\n[无尽怒火：免疫诅咒，期间生命不低于1。]\n[诅咒：无法获得增益效果]\n[神佑：阵亡时立即复活并恢复50%生命]');
 // Colors apply after formatting, longest name first, across a forced wrap.
 wrapAt=text.indexOf('尽怒');
 const html=methods.formatTip105(text);
 assert.ok(html.includes('<font color="#ff3d6e">无\n尽怒火</font>'));
 assert.ok(html.includes('<font color="#ff8a1e">怒气</font>'));
 assert.equal(methods.tipTerms105.length,0);
 wrapAt=0;
 cases++;
}
{ // Generic notes stop at the line budget; hero notes always stay.
 const long='眩晕沉默嘲讽虚弱破甲诅咒中毒灼烧流血神佑净化真实伤害附加伤害'+'。'.repeat(0)+'甲'.repeat(21*10);
 const text=skill('S5',long,0,0).getInfoDetails();
 let used=0;for(const line of text.split('\n'))used+=Math.max(1,Math.ceil(line.replace(/[()\[\]{}]/g,'').length/21));
 assert.ok(used<=methods.TIP_LINE_BUDGET105,used);
 assert.ok(text.includes('[眩晕：无法行动]'));assert.ok(!text.includes('附加伤害：'));
 cases++;
}
{ // Skills without a hero leave no stale colors behind.
 methods.formatTip105(skill('S6','造成伤害。',0,0).getInfoDetails());
 assert.equal(methods.tipTerms105.length,0);
 cases++;
}
console.log(`Skill popup layout cases passed: ${cases}`);
'''


class NativeSkillTipTests(unittest.TestCase):
    def test_native_layout(self):
        source = FIXTURE.replace('/*METHODS*/', translate())
        run = subprocess.run(['node'], input=source, text=True, encoding='utf-8', capture_output=True, cwd=ROOT)
        self.assertEqual(run.returncode, 0, run.stdout + '\n' + run.stderr)
        print(run.stdout.strip())

    def test_skill_set_and_every_popup_use_the_layout(self):
        skill = (ROOT / 'client/src/stages/139_SkillSet.as').read_text('utf-8')
        code = (ROOT / 'client/src/skill_tips_105.aspart').read_text('utf-8').replace('\r\n', '\n')
        self.assertIn('      // BEGIN SKILL TIPS 105\n' + code + '      // END SKILL TIPS 105\n', skill)
        self.assertEqual(skill.count('public function getInfoDetails()'), 1)
        self.assertIn('import com.meng52.game.global.GlobalTextStyle;', skill)
        for path, count in (('035_PanelBetterStart', 1), ('141_PanelDetailAll', 2), ('143_LOL_DetailAvatar', 2)):
            text = (ROOT / f'client/src/stages/{path}.as').read_text('utf-8')
            self.assertEqual(text.count('_loc2_ = SkillSet.formatTip105(_loc2_);'), count, path)
            self.assertNotIn('Tools.formatLineX(_loc2_,GlobalTextStyle.COLOR_W_W_Y_G)', text)

    def test_config_enables_popup_art_and_carries_tryndamere_notes(self):
        from gateway import load_game_config
        from demonblade_tryndamere_105 import AID, NORMAL, CAPTAIN, PASSIVE
        cfg = load_game_config(ROOT / 'config/reconstruction/full-config.json')['cfg']
        self.assertEqual(cfg['client_config']['pop_res'], 1)
        terms = cfg['avatar'][AID]['tipTerms105']
        self.assertEqual(set(terms), {'怒气', '无尽怒火'})
        # Mechanic colors stay clear of white, gray, yellow and green markup colors.
        for color in terms.values():
            self.assertNotIn(color, (0xFFFFFF, 0xA0A0A0, 0xFFFF00, 0x62CD62))
        notes = cfg['skill'][PASSIVE]['tipNotes105']
        self.assertEqual([n[0] for n in notes], ['怒气', '无尽怒火'])
        self.assertIn('无尽怒火', cfg['skill'][PASSIVE]['info'])
        for sid in (NORMAL, CAPTAIN):
            self.assertIn('怒气', cfg['skill'][sid]['info'])
        json.dumps(cfg['skill'][PASSIVE], ensure_ascii=False)


if __name__ == '__main__':
    unittest.main()
