"""Expose the shipped compound-ability literals as bounded data parameters.

Run once after reviewing Avatar's ability implementations. Regeneration refuses
an already instrumented file; the manifest retains source contexts and defaults.
No user-supplied code is compiled or evaluated by the parameter API.
"""
import hashlib
import json
from pathlib import Path
import re
import sys

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'client/src/stages/137_Avatar.as'
OUTPUT=ROOT/'server/native_ability_parameters.json'
TOKEN=re.compile(r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|//[^\n]*|/\*[\s\S]*?\*/|(?<![\w.])\d+(?:\.\d+)?(?![\w.])')

CALL_LABELS={
    'abilityEnemies':['目标距离','中心对象','最多目标数'],
    'abilityCandidates':['阵营','分路','中心位置','目标距离','最多目标数'],
    'abilityAlly':['友军距离'],'abilityMarkedTarget':['标记','追踪距离'],
    'abilityHit':['目标','伤害倍率','伤害类型','特效','共享伤害基数'],
    'abilityHeal':['目标','治疗倍率'],'abilityShield':['目标','护盾倍率','持续回合'],
    'abilityControl':['目标','状态','持续回合','附加比例'],
    'abilityMark':['目标','标记','持续回合','附加倍率'],
    'abilitySummon':['单位','召唤数量','面板倍率','存续回合'],
    'checkMove':['方向','位移距离','目标','碰撞规则'],
    'addBuff':['状态','持续回合','状态数值'],
}

def purpose(before):
    if re.search(r'Math\.max\(\s*$',before[-50:]):return '最小计算基数'
    stack=[];previous=''
    for match in re.finditer(r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|[A-Za-z_$][\w$]*|[(),]',before):
        token=match[0]
        if token=='(':stack.append([previous,0])
        elif token==')':
            if stack:stack.pop()
        elif token==',' and stack:stack[-1][1]+=1
        previous=token
    for function,index in reversed(stack):
        labels=CALL_LABELS.get(function)
        if labels and index<len(labels):return labels[index]
    tail=before[-130:]
    if 'hp/hpMax' in tail:return '生命比例阈值'
    if re.search(r'(?:until\s*:\s*[^,;{}]*|abilitySerial\s*\+\s*)$',tail):return '状态持续回合'
    if re.search(r'(?:charges|left)\s*:\s*$',tail):return '触发次数'
    if re.search(r'\bi\s*<\s*$',tail):return '连段 / 循环次数'
    if re.search(r'\bcount\s*==\s*$',tail):return '触发层数'
    if re.search(r'Math\.max\(\s*$',tail):return '最小计算基数'
    return '触发 / 状态数值'

def main():
    source=SOURCE.read_text('utf-8')
    if 'nativeAbilityNumber(sourceSkill' in source:
        if '--refresh' not in sys.argv:raise SystemExit('Already exposed; use --refresh after reviewing changes.')
        source=re.sub(r'nativeAbilityNumber\(sourceSkill,kind,"(?:can|cast)_\d+",(\d+(?:\.\d+)?)\)',lambda m:m[1],source)
        helper_start=source.index('      private function nativeAbilityNumber(')
        helper_end=source.index('      public function abilityCanCast(',helper_start)
        source=source[:helper_start]+source[helper_end:]
        source=source.replace('public function abilityCanCast(kind:String, distance:int, sourceSkill:* = null)',
                              'public function abilityCanCast(kind:String, distance:int)')
    original=source
    definitions={}; replacements=[]
    for function,end_marker,prefix in (
        ('abilityCanCast','public function executeAbility','can'),
        ('executeAbility','public var abilityState','cast'),
    ):
        start=source.index('public function '+function)
        if function=='executeAbility':
            # Bound the function by its own braces, not the next field/method.
            brace=source.index('{',start);depth=0;end=None
            for token in re.finditer(r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|//[^\n]*|/\*[\s\S]*?\*/|[{}]',source[brace:]):
                if token[0]=='{':depth+=1
                elif token[0]=='}':
                    depth-=1
                    if depth==0:end=brace+token.end();break
            if end is None:raise ValueError('Unclosed ability function')
        else:end=source.index(end_marker,start)
        body=source[start:end]
        cases=list(re.finditer(r'case "([a-z0-9_]+)":',body))
        aliases=[]
        for i,case in enumerate(cases):
            aliases.append(case[1]);a=case.end();b=cases[i+1].start() if i+1<len(cases) else len(body)
            block=body[a:b]
            if not block.strip():continue
            for number_index,match in enumerate(TOKEN.finditer(block)):
                literal=match[0]
                if not literal[0].isdigit():continue
                before=block[:match.start()];after=block[match.end():]
                # Array positions and structural zero initializers are not
                # tuning values. Keep code structure immutable.
                if re.search(r'\[\s*$',before) or re.match(r'\s*\]',after):continue
                if re.search(r'(?:getType\(\)|getStar\(\))\s*[!=]=?\s*$',before):continue
                if re.search(r'\bteam\s*==\s*$',before) or re.search(r'\blane\s*<\s*$',before):continue
                if literal=='1' and re.search(r'-\s*$',before):continue  # -1 native sentinel
                if literal=='0' and (re.search(r'[=<>]\s*$',before) or re.match(r'\s*[;,]',after)):continue
                value=float(literal) if '.' in literal else int(literal)
                if abs(value)>=10_000_000:continue  # fixed engine sentinels, not tuning values
                key=prefix+'_'+str(number_index)
                line=block[block.rfind('\n',0,match.start())+1:block.find('\n',match.end()) if '\n' in after else len(block)].strip()
                descriptor={'default':value,'integer':type(value) is int,'minimum':0,
                            'maximum':max(32,value) if type(value) is int else max(10,value*10),
                            'context':line[:700],'sourceLine':original[:start+a+match.start()].count('\n')+1}
                descriptor['label']=purpose(before)+' · '+str(number_index)
                # Distances retain the game's bounded coordinate range.
                if value>=100:descriptor['maximum']=10000
                label=purpose(before)
                if label in ('伤害倍率','治疗倍率','护盾倍率','面板倍率','共享伤害基数','附加比例','附加倍率','生命比例阈值','状态数值'):
                    descriptor.update(integer=False,maximum=max(100,value*10))
                if label=='伤害类型':descriptor.update(minimum=1,maximum=3,enum=[1,2,3])
                if label in ('持续回合','存续回合','状态持续回合'):descriptor.update(minimum=1,maximum=100)
                if label in ('最多目标数','召唤数量','连段 / 循环次数'):descriptor.update(minimum=1,maximum=16)
                if label=='最小计算基数':descriptor['minimum']=value if value>0 else 0
                if not descriptor['minimum']<=value<=descriptor['maximum']:raise ValueError('Default outside parameter contract: '+line)
                for kind in aliases:definitions.setdefault(kind,{})[key]=descriptor
                replacement='nativeAbilityNumber(sourceSkill,kind,"'+key+'",'+literal+')'
                replacements.append((start+a+match.start(),start+a+match.end(),replacement))
            aliases=[]
    for a,b,text in sorted(replacements,reverse=True):source=source[:a]+text+source[b:]
    source=source.replace('public function abilityCanCast(kind:String, distance:int) : Boolean',
                          'public function abilityCanCast(kind:String, distance:int, sourceSkill:* = null) : Boolean')
    helper='''      private function nativeAbilityNumber(sourceSkill:*, kind:String, key:String, fallback:Number) : Number
      {
         var row:Object = sourceSkill && sourceSkill.skillSetData && GlobalData.$mConfig_skill ? GlobalData.$mConfig_skill[sourceSkill.skillSetData.id] : null;
         var parameters:Object = row && row.modNativeSource ? row.nativeAbilityParameters : null;
         var values:Object = parameters ? parameters[kind] : null;
         if(!values || !values.hasOwnProperty(key) || typeof values[key] != "number" || !isFinite(Number(values[key]))) return fallback;
         return Number(values[key]);
      }

'''
    source=source.replace('      public function abilityCanCast(',helper+'      public function abilityCanCast(',1)
    manifest={'version':1,'source':'client/src/stages/137_Avatar.as',
              'originalSha256':hashlib.sha256(original.encode()).hexdigest(),
              'mechanisms':definitions}
    OUTPUT.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n','utf-8')
    SOURCE.write_bytes(source.encode('utf-8'))
    print(json.dumps({'mechanisms':len(definitions),'parameters':sum(map(len,definitions.values())),'sites':len(replacements)}))

if __name__=='__main__':main()
