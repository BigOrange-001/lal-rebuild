"""Auditable numeric calibration of the explicitly tested non-skin families."""
from pathlib import Path
import copy,hashlib,json,math,re
from collections import defaultdict
from captain_strength import _scale_captain_row

PLAN=Path(__file__).resolve().parents[1]/'config/reconstruction/hero-iteration-1.0.3.json'
SCHEMA='hero-iteration-1.0.3-v1'
_RANK_TOKEN=re.compile(r'\{(rank|flat):(\d+):(\d+)\}')


def _render_base_info(row):
    template=row.get('rankInfoTemplate')
    if not isinstance(template,str) or not _RANK_TOKEN.search(template):return
    def replace(match):
        try:value=row['skill'][int(match[2])][int(match[3])]
        except (IndexError,KeyError,TypeError):return match[0]
        if type(value) not in (int,float) or not math.isfinite(value):return match[0]
        return f'{value*100:g}%' if match[1]=='rank' else f'{value:g}'
    row['info']=_RANK_TOKEN.sub(replace,template)

def apply_hero_iteration_103(document,plan=None):
    plan=json.loads(PLAN.read_text('utf8')) if plan is None else plan
    if plan.get('schema')!=SCHEMA:raise ValueError('Invalid iterative hero calibration schema')
    rows=plan.get('heroes')
    if not isinstance(rows,list):raise ValueError('Missing iterative hero rows')
    if not rows:return document
    cfg=document.get('cfg',document)
    digest=hashlib.sha256(json.dumps(plan,sort_keys=True,ensure_ascii=False).encode()).hexdigest()
    old=cfg.get('hero_iteration_103')
    if old:
        if old.get('plan_sha256')==digest:return document
        raise ValueError('A different iterative calibration is already applied')
    factors={};skill_factors={}
    for row in rows:
        aid=row.get('aid');factor=row.get('panel_factor')
        if (not isinstance(aid,str) or not re.fullmatch(r'A_1\d{3}_[56]',aid)
                or aid not in cfg['avatar'] or type(factor) not in (int,float)
                or not math.isfinite(factor) or not .5<=factor<=2):
            raise ValueError('Invalid iterative hero calibration')
        family=aid.rsplit('_',1)[0]
        if family in factors:raise ValueError('Duplicate iterative hero family')
        factors[family]=factor
        skill_factor=row.get('skill_factor',1)
        if type(skill_factor) not in (int,float) or not math.isfinite(skill_factor) or not .25<=skill_factor<=4:
            raise ValueError('Invalid iterative skill factor')
        if plan.get('scope')=='skill-magnitudes-only' and factor!=1:
            raise ValueError('Skill-only calibration cannot change hero panels')
        skill_factors[family]=skill_factor
    avatars=copy.deepcopy(cfg['avatar']);changed=[]
    for aid,hero in avatars.items():
        factor=factors.get(aid.rsplit('_',1)[0],1)
        if factor==1:continue
        if len(hero.get('pl',[]))<8:raise ValueError('Incomplete calibrated hero stats')
        hero['pl'][:8]=[round(x*factor,10) for x in hero['pl'][:8]]
        changed.append(aid)
    consumers=defaultdict(list)
    for aid,hero in avatars.items():
        for slot in (10,11,13):
            if len(hero.get('pl',[]))>slot and hero['pl'][slot] in cfg['skill']:
                consumers[hero['pl'][slot]].append((aid,slot,skill_factors.get(aid.rsplit('_',1)[0],1)))
    skills=dict(cfg['skill']);skill_changes=[]
    for sid,refs in consumers.items():
        demands={factor for _,_,factor in refs}
        source=cfg['skill'][sid]
        if len(demands)>1 and any(a[0] in ('manual_ability','summon','summon_turret','clone_normal') for a in source.get('skill',[])):
            raise ValueError('Cannot split a shared native skill during calibration: '+sid)
        for factor in sorted(demands):
            if factor==1:continue
            scaled,_,_=_scale_captain_row(source,factor,scale_displacement=False)
            _render_base_info(scaled)
            target=sid
            if len(demands)>1:
                target='S_87'+str(int(hashlib.sha256(f'{SCHEMA}:{sid}:{factor}'.encode()).hexdigest()[:12],16))+'_'+sid.rsplit('_',1)[1]
                if target in skills:raise ValueError('Iterative skill ID collision')
                scaled['id']=target
                for aid,slot,requested in refs:
                    if requested==factor:avatars[aid]['pl'][slot]=target
            skills[target]=scaled
            skill_changes.append({'source':sid,'target':target,'factor':factor})
    cfg['avatar']=avatars;cfg['skill']=skills
    cfg['hero_iteration_103']={'schema':SCHEMA,'plan_sha256':digest,'changed_ids':changed,'skill_changes':skill_changes}
    return document
