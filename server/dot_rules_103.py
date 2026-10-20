"""Unified 1.0.3 DOT budgets and descriptions, applied after hero balance."""
from __future__ import annotations
import copy
import re
from native_skill_snapshot import _native_skill_snapshot

SCHEMA='dot-rules-1.0.3-v1'
RULES='持续伤害无视物防和魔防；中毒期间受到伤害提高20%（不叠加）；灼伤期间受到治疗降低40%（不叠加）。'

def _direct(actions):
    total=0.0
    for a in actions:
        kind=a[0]
        if kind in ('damage','conditional_damage','stun_by_condition','poison','weak','sunder','silence','stun'):
            total+=float(a[1])*(.3 if len(a)>2 and a[2]==3 else 1)
        elif kind=='true_damage':total+=float(a[1])
        elif kind in ('locked_sequence','locked_sequence_area'):
            # The area form has one shared coefficient; legacy sequence has one per hit.
            total+=int(a[1])*float(a[2]) if kind.endswith('_area') else sum(float(x) for x in a[2:2+int(a[1])])
        elif kind=='damage_chain':total+=float(a[2][0])
        elif kind=='combo':total+=float(a[1])*int(a[3])
    return total

def _curve(row, i, column, low, high):
    up=row.get('skillUp') or []
    up=copy.deepcopy(up if up and isinstance(up[0],list) else [[int(up[0]),1,up[1]]] if up else [])
    up=[x for x in up if (x[0],x[1])!=(i,column)]
    paths=row.get('skillUpPaths') or []
    row['skillUpPaths']=[x for x in paths if not (x[0]==i and x[1]==[column])]
    row['skill'][i][column]=round(low,10)
    step=round((high-low)/9,10)
    if step:up.append([i,column,step])
    row['skillUp']=up or None

def _description(row, details):
    # Retain target/control/direct-hit prose, remove stale DOT formula fragments.
    text=row.get('rankInfoTemplate') or row.get('info') or ''
    text=re.sub(r'该次中毒每次基础结算为[^。]*。','',text)
    text=re.sub(r'毒值为[^，。；]*','中毒基础值按下述持续伤害规则结算',text)
    text=re.sub(r'每(?:层每)?回合(?:造成)?(?:施加时)?(?:自身)?(?:攻击面板)?(?:[\d.]+%|\{rank:[^}]+\})(?:面板)?(?:物理|魔法|真实)?伤害', '每次按下述倍率造成无视双防的持续伤害',text)
    text=text.replace('面板魔法伤害的毒dot持续伤害','无视双防的中毒').replace('面板物理伤害的流血','无视双防的流血')
    text=re.sub(r'每层每回合造成自身攻击面板[\d.]+%的真实伤害','每层按下述倍率造成持续伤害',text)
    text=text.replace('施加每次按下述倍率造成无视双防的持续伤害的','施加')
    kinds={a[1] if a[0]=='manual_dot' else a[0] for a in row['skill'] if a[0] in ('manual_dot','poison','burn')}
    if row.get('chainDot'):kinds.add(row['chainDot'][0])
    rules='持续伤害无视物防和魔防。'
    if 'poison' in kinds:rules+='中毒期间受到伤害提高20%（不叠加）。'
    if 'burn' in kinds:rules+='灼伤期间受到治疗降低40%（不叠加）。'
    row['rankInfoTemplate']=text+'\n'+'；'.join(details)+'。'+rules
    def render(m):
        value=row['skill'][int(m[1])]
        for index in m[2].split('.'):value=value[int(index)]
        return f'{float(value)*100:g}%'
    row['info']=re.sub(r'\{rank:(\d+):([\d.]+)\}',render,row['rankInfoTemplate'])
    row['info']=re.sub(r'\{flat:(\d+):([\d.]+)\}',lambda m: str(round(row['skill'][int(m[1])][int(m[2])])),row['info'])

def apply_dot_rules_103(document):
    cfg=document.get('cfg',document)
    if cfg.get('dot_rules_103',{}).get('schema')==SCHEMA:return document
    # Work on a private skill table so an invalid curve never partially applies.
    skills=copy.deepcopy(cfg['skill']);source={'skill':copy.deepcopy(skills)}
    refs={}
    for aid,hero in cfg['avatar'].items():
        for i in (10,11,13):
            pl=hero.get('pl') or []
            if len(pl)>i and pl[i]:refs.setdefault(pl[i],[]).append(aid)
    books={e.get('skill') for e in cfg.get('equip',{}).values() if e.get('type')==6}
    audit=[]
    for sid,owners in refs.items():
        if sid not in skills or sid in books:continue
        row=skills[sid];base=source['skill'][sid]
        actions=base.get('skill') or []
        dots=[(i,a) for i,a in enumerate(actions) if a[0] in ('poison','burn','manual_dot')]
        phantom=next((a for a in actions if a[0]=='manual_ability' and a[1]=='malzahar_n'),None)
        chain=base.get('chainDot')
        if not dots and not chain and not phantom:continue
        high=_native_skill_snapshot(source,sid,10)['skills'];direct=[_direct(actions),_direct(high)]
        details=[]
        for i,a in dots:
            col,rounds,kind=(3,int(a[4]),'poison') if a[0]=='poison' else (1,int(a[2]),'burn') if a[0]=='burn' else (2,int(a[4]),a[1])
            if rounds<1:raise ValueError(f'invalid DOT duration: {sid}')
            budget=list(direct)
            if not any(budget):
                # Annie's pure, stackable lane DOT uses a 100%-AP same-tier hit
                # as its reference; its existing growth/balance scale is retained.
                factor=6.25 if any(x.startswith('A_1029_') for x in owners) else 1
                budget=[float(a[col])*factor,float(high[i][col])*factor]
            lo,hi=[3*x/rounds/max(1,len(dots)) for x in budget]
            _curve(row,i,col,lo,hi)
            if a[0]=='manual_dot':row['skill'][i][3]=0
            label={'poison':'中毒','burn':'灼伤','bleed':'流血'}[kind]
            detail=f'{label}每次结算{{rank:{i}:{col}}}施加时攻击力，持续{rounds}次自身行动'
            if a[0]=='poison':detail+='，每次另加目标生命上限5%'
            if kind=='bleed':detail+='；流血对护盾造成3倍伤害，破盾溢出按原伤害额度扣血'
            details.append(detail)
            audit.append(dict(sid=sid,kind=kind,rounds=rounds,old=a[col],new=lo,max=hi,reference=budget))
        if chain:
            row['chainDot'][1]=round(direct[0]*3/int(chain[2]),10)
            details.append(f'每次弹射命中后附加灼伤，每次结算{row["chainDot"][1]*100:g}%施加时攻击力，持续{chain[2]}次；相同来源刷新')
            audit.append(dict(sid=sid,kind='burn-chain',rounds=chain[2],old=chain[1],new=row['chainDot'][1],reference=direct))
        if phantom:
            factor=float(row.get('manualDamageMultiplier') or 1)
            coef=float(phantom[2])*factor
            old=str(row.get('info',''))
            old=re.sub(r'每次结算施加时攻击力[\d.]+%','每次结算施加时攻击力'+f'{coef*100:g}%',old)
            suffix=' 幻象无视双防，对护盾造成3倍伤害；破盾溢出按原伤害额度扣血。'
            row['info']=old+suffix
            row['rankInfoTemplate']=old.replace(f'{coef*100:g}%',f'{{scale:0:{factor*100:g}}}',1)+suffix
            row['dotPhantasmRule']=True
            audit.append(dict(sid=sid,kind='phantasm',rounds=3,new=coef,max=2*coef))
        else:_description(row,details)
        row['dotRule']=True
    # Book coefficients and upgrade curves are intentionally untouched.
    for sid in books:
        row=skills.get(sid)
        if not row:continue
        if any(a[0]=='book_burn' or a[0]=='book_passive' and a[2]=='attack_burn' for a in row.get('skill') or []):
            for field in ('info','rankInfoTemplate'):
                if row.get(field):row[field]+=' 灼伤无视双防，期间受到治疗降低40%。'
    simple=copy.deepcopy(cfg['system_simple']);simple['attack'][18]=.05
    cfg['system_simple']=simple;cfg['skill']=skills
    for aid,hero in cfg['avatar'].items():
        if aid.startswith('A_1139_'):hero['name']='卡尔玛'
    cfg['dot_rules_103']={'schema':SCHEMA,'poison_hp_fraction':.05,'poison_vulnerability':.2,
        'burn_heal_reduction':.4,'shield_multiplier':3,'book_budgets':'preserved','changes':audit}
    return document
