"""Player's 2026-10-27 review, applied before bond/equipment variants.

Authored output coefficients below are final (after the shared 80% pass).
Existing card identities, media, acquisition and explicit keep decisions survive.
"""
import copy
from mod_effects import compile_skill
from hero_packs_104 import scale_outputs


def effect(kind, target='self', ratio=0, **kw):
    return dict(type=kind, target=target, attackRatio=ratio, **kw)


def sequence(name, text, actions, event=None, warmup=0, cooldown=1, **gate):
    trigger=dict(kind='event',event=event,maxPerRound=1,allowChain=False,**gate) if event else dict(kind='ready')
    return dict(id='review',name=name,description=text,model='effect-sequence-v1',
                warmup=warmup,cooldown=cooldown,range=9999,trigger=trigger,
                actions=actions,rankInfoTemplate=text,maxLevel=1)


def replace_sequence(cfg, hero, slot, design):
    old=cfg['skill'].get(hero['pl'][slot],{})
    sid='S_984'+hero['id'].split('_')[1]+str(slot)+'_'+hero['id'].rsplit('_',1)[1]
    row=compile_skill(design,sid,lambda ref,*_:ref.rsplit('/',1)[-1] if ref else None)
    row['res']=old.get('res',old.get('id',sid))
    # One common final output pass is still responsible for all variants.
    scale_outputs(row,1/.8)
    row['calibration_104']=True
    cfg['skill'][sid]=row;hero['pl'][slot]=sid
    if slot==13:hero['skill_diff']=20
    return row


def private_skill(cfg, hero, slot):
    old=cfg['skill'].get(hero['pl'][slot])
    if not old:return None
    sid='S_984'+hero['id'].split('_')[1]+str(slot)+'_'+hero['id'].rsplit('_',1)[1]
    row=copy.deepcopy(old);row.update(id=sid,calibration_104=True)
    row.setdefault('res',old['id'])
    for key in ('manualSummonPolicy','manualClonePolicy'):
        # Native policies deliberately retain their verified source identity.
        if row.get(key):
            row['equipment_source_skill_104']=old.get('equipment_source_skill_104',old['id'])
            row[key]['skillId']=sid
    cfg['skill'][sid]=row;hero['pl'][slot]=sid
    return row


def set_text(row,text):
    row['info']=row['rankInfoTemplate']=text


def append_self(row,action):
    count=len(row['skill']);row['skill'].append(action)
    for field,default,value in [('actionTargetPolicies',None,'ally_self'),('actionTargetMaxTargets',1,1),
                                ('actionTargetLocks',None,None),('actionTargetGroups',None,None),('actionTargetPolicyArgs',None,None)]:
        row[field]=list(row.get(field) or [])
        row[field].extend([default]*(count-len(row[field])));row[field].append(value)


def apply_hero_calibration_104(document):
    cfg=document.get('cfg',document)
    if cfg.get('hero_calibration_104'):return document
    changed=[]
    for aid,h in list(cfg['avatar'].items()):
        family=aid.rsplit('_',1)[0];quality=int(aid.rsplit('_',1)[1])
        if family=='A_1003':
            s=private_skill(cfg,h,10);append_self(s,['caster_hp_shield',.06/.8,2,'FX60_SHIELD'])
            for f in ('info','rankInfoTemplate'):s[f]=s.get(f,'')+'自身获得6%生命上限的护盾，持续2回合。'
        elif family=='A_1006' and len(h['pl'])>13 and h['pl'][13]:
            s=private_skill(cfg,h,13)
            if s.get('modCondition'):
                s['modCondition']['nearbyAllies']=2
                for f in ('info','rankInfoTemplate'):s[f]=s.get(f,'').replace('至少3名其他友军','至少3名友军（包括自身）')
        elif family=='A_1012':
            s=private_skill(cfg,h,10);s['reviewFleeQuality104']= {2:.0625,3:.125,4:.25,5:.5,6:1}.get(quality,1)
            flat=600*s['skill'][0][2]*5*s['reviewFleeQuality104']*s.get('manualEffectMultiplier',1)
            index=len(s['skill']);append_self(s,['stat_flat','flee',flat,1,'FX_S9140_FLEE'])
            s.setdefault('skillUp',[]).append([index,2,flat/9])
            import re
            for field in ('info','rankInfoTemplate'):
                s[field]=re.sub(r'增加[\d.]+点闪避',f'增加{{flat:{index}:2}}点闪避',s.get(field,''))
            # Native helper applies quality after its calibrated flat-stat value.
            if len(h['pl'])>13 and h['pl'][13]:
                p=private_skill(cfg,h,13)
                if p.get('modCondition'):
                    p['modCondition']={k:v for k,v in p['modCondition'].items() if k not in ('requiredBuff','nearbyEnemies','nearbyRadius','unitType')}
                    for a in p['skill']:
                        if a[0]=='mod_step':a[5]*=.5
                    set_text(p,'击杀敌人后，为自身恢复{rank:0:5}攻击力生命，并获得{rank:1:5}攻击力护盾，持续2回合。')
        elif family=='A_1029':
            s=private_skill(cfg,h,10)
            for i,a in enumerate(s['skill']):
                if a[0]=='manual_dot':
                    a[2]=.4/.8
                    s['skillUp']=[u for u in s.get('skillUp',[]) if u[:2]!=[i,2]]+[[i,2,.4/.8/9]]
        elif family=='A_1002':
            s=private_skill(cfg,h,11)
            s['actionTargetPolicies']=[('enemy_global_highest_attack_hero' if x=='enemy_global_lowest_hpmax' else x) for x in s.get('actionTargetPolicies',[])]
            for f in ('info','rankInfoTemplate'):s[f]=s.get(f,'').replace('生命上限最低的敌方单位','攻击力最高的敌方英雄')
        elif family=='A_1015' and len(h['pl'])>13 and h['pl'][13]:
            n=private_skill(cfg,h,10);append_self(n,['arm_dash_response_104'])
            p=private_skill(cfg,h,13)
            if p.get('modCondition'):
                p['modCondition'].update(event='damage_taken',requiredBuff='steel')
                p['modCondition'].pop('nearbyEnemies',None);p['modCondition'].pop('nearbyRadius',None)
                p['modCondition']['reviewDashResponse104']=True
                set_text(p,'突进后首次受击或闪避时，对攻击者造成{rank:0:5}攻击力魔法伤害，并恢复{rank:1:5}攻击力生命。')
        elif family=='A_1017' and len(h['pl'])>13 and h['pl'][13]:
            p=private_skill(cfg,h,13)
            if p.get('modCondition'):
                p['modCondition'].pop('nearbyEnemies',None);p['modCondition'].pop('nearbyRadius',None)
                set_text(p,'护盾被敌人击破时，对攻击者造成{rank:0:5}攻击力物理伤害，并眩晕1回合。')
        elif family=='A_1126':private_skill(cfg,h,11)['pl'][:2]=[2,4]
        elif family=='A_1124':
            s=cfg['skill'][h['pl'][11]]
            s['calibration_104']=True
            if s['skill'][2][0]=='summon':
                s['skill'][2][0]='rally_soldiers'
                s['skill']=s['skill'][:3]
                for key in ('actionTargetPolicies','actionTargetMaxTargets','actionTargetGroups','actionTargetLocks','actionTargetPolicyArgs'):
                    if key in s:s[key]=s[key][:3]
                set_text(s,'对本路最多3名敌人造成{rank:0:1}攻击力魔法伤害并击退350码。已有沙兵恢复30%最大生命、获得50%力量2回合，剩余存在时间延长至至少3次行动；没有沙兵时召唤2名沙兵。')
        elif family=='A_1132':
            s=private_skill(cfg,h,11)
            if s.get('manualClonePolicy'):s['manualClonePolicy']['ttlOwnTurns']=5
            set_text(s,'召唤继承自身100%面板的影分身，复制自身小技能，持续5次自身行动。')
        elif family=='A_1208':
            p=private_skill(cfg,h,13);p['skill'][0][2]=.7
            set_text(p,'受到治疗时，对本路全体敌人造成真实伤害，数值为有效治疗量的{rank:0:1}与溢出治疗量的70%。')
        elif family=='A_1212':
            replace_sequence(cfg,h,13,sequence('粽香回甘','治疗友军后，为本路友军提供{rank:0:5}攻击力护盾，持续2回合，并净化1回合。',[
                effect('buff','ally_radius',1.2,radius=9999,buff='shield',duration=2),
                effect('buff','ally_radius',radius=9999,buff='purify',duration=1)],event='heal_done',minAmount=1,relation='ally'))
        elif family=='A_1217':
            s=private_skill(cfg,h,10);s['pl'][:2]=[1,1]
            s['skill'][0][4]=1.05/.8;s['skillUp']=[[0,4,1.05/.8/9]]
            s['rankDisplayFactors104']={'0:4':.8}
            set_text(s,'随机攻击本路敌人，每次造成{rank:0:4}攻击力魔法伤害并获得1层5%攻击增益；每累计击杀2名敌方英雄，后续施放增加一次攻击。')
            p=private_skill(cfg,h,13)
            set_text(p,'击杀敌方英雄获得2层5%攻击增益；每累计击杀2名敌方英雄，小技能增加一次攻击。')
            s=private_skill(cfg,h,11)
            for f in ('info','rankInfoTemplate'):s[f]=s.get(f,'')+'本次施放获得10000精准。'
        elif family=='A_1085':
            s=private_skill(cfg,h,10)
            s['manualDamageMultiplier']=s.get('manualDamageMultiplier',1)*.75
            append_self(s,['caster_hp_shield',.12/.8,2,'FX60_SHIELD'])
            from skill_description_104 import scale_manual_output_text
            scale_manual_output_text(s,'alistar_n',.75,damage_only=True)
            for f in ('info','rankInfoTemplate'):s[f]=s.get(f,'')+'自身获得12%生命上限护盾2回合。'
            s=private_skill(cfg,h,11)
            set_text(s,'清除自身负面效果并恢复生命，随后获得80%减伤，持续至下次自身行动。')
        elif family=='A_1073':
            s=private_skill(cfg,h,11)
            for f in ('info','rankInfoTemplate'):
                s[f]=s.get(f,'').replace('蓄力期间被成功施加眩晕、沉默，或位置发生改变，立即取消爆炸。','蓄力期间不可阻挡。')
        elif family=='A_1123':
            s=private_skill(cfg,h,10)
            for f in ('info','rankInfoTemplate'):s[f]=s.get(f,'').replace('仅使用小纳尔形态。','')
            # Two incoming attacks build rage; existing boomerang weakness
            # keeps Gnar alive until his defensive crowd-control payoff.
            h['pl'] += [None]*max(0,14-len(h['pl']))
            replace_sequence(cfg,h,13,sequence('狂怒迸发','每受到2次敌人攻击，对本路敌人造成{rank:0:5}攻击力物理伤害并眩晕1回合；自身获得50%双抗2回合。',[
                effect('damage','lane_all',1.8,radius=9999,damageType='physical'),
                effect('buff','lane_all',radius=9999,buff='stun',duration=1),
                effect('buff',buff='steel',amount=.5,duration=2)],event='damage_taken',everyEvents=2,relation='enemy',minAmount=1,cooldown=2))
            s=private_skill(cfg,h,11);s['name']='狂野连击'
            for f in ('info','rankInfoTemplate'):s[f]=s.get(f,'').replace('保持小纳尔形态，','')
        else:continue
        changed.append(aid)
    from skin_calibration_104 import apply_skin_calibration
    skins=apply_skin_calibration(cfg)
    cfg['hero_calibration_104']={'schema':'player-review-20261027-v1','heroes':changed,'skins':skins}
    return document
