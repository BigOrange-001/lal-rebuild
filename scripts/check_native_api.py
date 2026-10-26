"""Focused game-only native-template acceptance. No editor, packaging or game run."""
from __future__ import annotations
import copy
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import uuid
import zipfile

ROOT=Path(__file__).resolve().parents[1]
sys.path[:0]=[str(ROOT),str(ROOT/'server')]
from scripts.mod_tools import load_base
from mod_native import requires_103,make_template,compile_template,validate_template,reorder_actions,remove_action,argument_label,ability_contract
from mod_schema import ModError,canonical
from mod_packages import ModCatalog,inspect_package
from mod_compile import target_digest


def hero():
    return {'id':'native_hero','variant':'quality5','name':'Native API acceptance','unitType':'hero',
        'quality':5,'signType':'attack','actionType':'forward','damageType':'true',
        'baseStats':{'health':1200,'attack':100,'physicalDefense':60,'magicDefense':40},
        'growth':{'health':100,'attack':8,'physicalDefense':5,'magicDefense':3},
        'speed':245,'attackRange':337,'leadership':26,'levelCap':99,
        'progression':{'preset':'builtin:progression/default-player-hero','starUp':None},
        'skills':{'normal':None,'captain':None,'passive':None},
        'presentation':{'portrait':'builtin:portrait/A_1001_5','icon':'builtin:icon/A_1001_5',
                        'basicAttackEffect':'builtin:effect/E_008','voice':None}}


def package(path,skills,*,patch=False,base=None):
    skills=copy.deepcopy(skills)
    data={'skills':{'skills':skills}}
    if patch:
        data['patches']={'patches':[{'id':'native_patch','target':'builtin:avatar/A_1001_5',
            'expect':{'path':'skills.normal','sha256':target_digest(base,'A_1001_5','skills.normal')},
            'operations':[{'op':'replace','path':'skills.normal','value':'self:skill/'+skills[0]['id']}]}]}
    else:
        row=hero()
        passive = skills[0]['nativeTemplate']['passiveTrigger'] or any(a['type'] in ('cat_passive','polar_basic','santa_kill','nurse_healing','book_passive') for a in skills[0]['actions'])
        row['skills']['passive' if passive else 'normal']='self:skill/'+skills[0]['id']
        data['heroes']={'heroes':[row]}
    payload={name+'.json':canonical(value) for name,value in data.items()}
    manifest={'format':'lal-mod-v1','kind':'patch' if patch else 'new','packageId':str(uuid.uuid4()),
        'name':'Native API acceptance','author':'Acceptance','version':'1.0.0','engineApi':'1',
        'requiredCapabilities':['skill.native-template.v1','hero.patch.skill' if patch else 'hero.register']+([] if patch else ['hero.damage.true'])+(['skill.native-template.103'] if any(requires_103(s) for s in skills) else []),
        'entrypoints':{name:name+'.json' for name in data},'dependencies':[],
        'files':[{'path':name,'sha256':hashlib.sha256(raw).hexdigest()} for name,raw in payload.items()]}
    with zipfile.ZipFile(path,'w',zipfile.ZIP_DEFLATED) as archive:
        for name,raw in payload.items():archive.writestr(name,raw)
        archive.writestr('manifest.json',canonical(manifest))
    return path


def rejected(fn):
    try:fn()
    except ModError:return
    raise AssertionError('Invalid template accepted')


def normalized(result,source):
    row=copy.deepcopy(result)
    for key in ('modNativeSource','modPassiveTrigger','nativeAbilityParameters','modScaleActionIndex','nativeActionSources','nativeActionSettings'):
        if key in source:row[key]=copy.deepcopy(source[key])
        else:row.pop(key,None)
    row['id']=source['id']
    for key in ('manualSummonPolicy','manualClonePolicy'):
        if isinstance(row.get(key),dict) and 'skillId' in row[key]:row[key]['skillId']=source['id']
    return row


def main():
    base=load_base(ROOT/'config/reconstruction/full-config.json');templates=[];reorders=0
    for sid,source in base['cfg']['skill'].items():
        # Effect-sequence skills use their own authoring model, not native templates.
        if source.get('modEffectSequence'):continue
        skill=make_template(sid,source,base);validate_template(skill,base)
        result=compile_template(skill,base,'S_800000_1')
        assert normalized(result,source)==source,sid
        changed=copy.deepcopy(skill);edited=False
        for action in changed['actions']:
            for i,value in enumerate(action['arguments'],1):
                if type(value) in (int,float) and any(w in argument_label(action['type'],i,action['arguments']) for w in ('倍率','比例')):
                    action['arguments'][i-1]=value*1.01 if value else .01;edited=True;break
            if edited:break
        if not edited:changed['description']+=' API acceptance'
        updated=compile_template(changed,base,'S_800000_1')
        assert updated['skill']!=result['skill'] if edited else updated['info']!=result.get('info'),sid
        templates.append(changed)
        for i in range(len(skill['actions'])-1):
            candidate=copy.deepcopy(skill);order=list(range(len(skill['actions'])));order[i],order[i+1]=order[i+1],order[i]
            try:reorder_actions(candidate,order)
            except ModError:continue
            reorder_actions(candidate,order);assert candidate==skill,sid;reorders+=1;break
    with tempfile.TemporaryDirectory() as folder:
        root=Path(folder);catalog=ModCatalog(root/'mods')
        for start in range(0,len(templates),220):
            path=package(root/('batch-%d.heropack'%start),templates[start:start+220])
            assert inspect_package(path,base)
            row=catalog.install(path)
            result=catalog.compile(base,{'packages':[{'packageId':row['packageId'],'version':row['version'],'digest':row['digest']}]})
            assert 'skill.native-template.v1' in result.document['cfg']['mod_runtime']['requiredClientCapabilities']
        row=catalog.install(package(root/'patch.heropack',[templates[0]],patch=True,base=base))
        result=catalog.compile(base,{'packages':[{'packageId':row['packageId'],'version':row['version'],'digest':row['digest']}]})
        assert result.document['cfg']['avatar']['A_1001_5']['pl'][10]!=base['cfg']['avatar']['A_1001_5']['pl'][10]
    broken=copy.deepcopy(templates[0]);broken['nativeTemplate']['sourceDigest']='0'*64;rejected(lambda:validate_template(broken,base))
    broken=copy.deepcopy(templates[0]);broken['actions'][0]['type']='execute_code';rejected(lambda:validate_template(broken,base))
    broken=next(copy.deepcopy(t) for t in templates if t['nativeTemplate']['settings'].get('manualSummonPolicy') and any(a['type']=='summon' for a in t['actions']))
    next(a for a in broken['actions'] if a['type']=='summon')['arguments']=[];rejected(lambda:validate_template(broken,base))
    locked=make_template('S_201001_5',base['cfg']['skill']['S_201001_5'],base);before=copy.deepcopy(locked)
    rejected(lambda:remove_action(locked,0));assert locked==before
    print(json.dumps({'ok':True,'skills':len(templates),'reorders':reorders,'packageBatches':(len(templates)+219)//220,
        'compoundMechanisms':len(ability_contract()['mechanisms']),'editorRequired':False,'gameLaunched':False}))


if __name__=='__main__':main()
