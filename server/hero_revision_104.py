"""Authored Gabriel, Karthus and Zed revisions before bond/output variants."""
import copy

def apply_hero_revision_104(document):
    cfg=document.get('cfg',document)
    if cfg.get('hero_revision_104'):return document
    for aid,hero in cfg['avatar'].items():
        family=aid.rsplit('_',1)[0]
        if family not in ('A_1998','A_1098','A_1132'):continue
        if family=='A_1132':
            row=cfg['skill'].get(hero['pl'][11],{})
            if row.get('manualClonePolicy'):
                row['manualClonePolicy']['panelStatRatio']=1
                row['info']='召唤一个继承自身100%面板属性的影分身，复制自身小技能，持续2次自身行动。'
            continue
        hero['name']='加百列' if family=='A_1998' else '卡尔萨斯'
        for slot in (10,11):
            old=cfg['skill'][hero['pl'][slot]]
            sid=f'S_104{1998 if family=="A_1998" else 1098}{slot}_{aid.rsplit("_",1)[1]}'
            row={'id':sid,'name':'','res':old.get('res',old['id']),'info':'','skillUp':None}
            if family=='A_1998' and slot==10:
                row.update(name='真-幻影连打',pl=[4,4,3000,0,0,0],
                    skill=[['damage',.55/.8,3,'FX_S9004_ARC'] for _ in range(5)],
                    skillUp=[[i,1,.55/.8/9] for i in range(5)],
                    actionTargetPolicies=['enemy_lane_frontmost']*5,
                    actionTargetMaxTargets=[1]*5,
                    rankInfoTemplate='对本路敌人连续攻击5次，每次造成{rank:0:1}攻击力真实伤害，每次攻击重新选择目标。')
            elif family=='A_1998':
                row.update(name='真-天界裁决',pl=[1,5,9999,0,-1,0],
                    skill=[['dispel_good','FX_S9004_ARC'],['damage',2.2/.8,3,'FX_S9004_ARC'],
                           ['purify',3,'FX_S9002_SHIELD'],['strong',.3,3,'FX_S9002_SHIELD'],['bless',-1,'FX_S9002_SHIELD']],
                    actionTargetPolicies=['enemy_lane_all','enemy_lane_all','ally_lane_all','ally_lane_all','ally_self'],
                    actionTargetPolicyArgs=[None,{'laneFilter':'all'},None,None,None],
                    actionTargetMaxTargets=[999,-1,-1,-1,1],
                    rankInfoTemplate='驱散本路全体敌人的增益，对全场敌人造成{rank:1:1}攻击力真实伤害；本路全体友军获得净化和30%力量，持续3回合；自身获得一次神佑。')
            elif slot==10:
                row.update(name='荒芜',pl=[1,2,600,0,0,1],
                    skill=[['manual_ability','karthus_n',1,'FX_A_1098_MAGIC']],skillUp=[[0,2,1/9]],
                    info='对本路目标及其200范围内最多3名敌人造成70%攻击魔法伤害；范围内只有一名敌人时，伤害翻倍。',
                    rankInfoTemplate='对本路目标及其200范围内最多3名敌人造成{scale:0:70}攻击魔法伤害；范围内只有一名敌人时，伤害翻倍。',
                    manualDamageMultiplier=1,manualEffectMultiplier=1)
            else:
                row.update(name='安魂曲',pl=[2,4,9999,0,-1,0],
                    skill=[['manual_ability','karthus_c',1,'FX_A_1098_MAGIC']],
                    info='对全场敌人造成220%攻击魔法伤害，生命低于40%的目标额外受到40%伤害。',
                    manualDamageMultiplier=1,manualEffectMultiplier=1)
            # Manual text begins before the shared 80% output pass too.
            if family=='A_1098':
                row['info']=row['info'].replace('70%','87.5%').replace('220%','275%')
                if row.get('rankInfoTemplate'):row['rankInfoTemplate']=row['rankInfoTemplate'].replace(':70}',':87.5}')
            else:
                row['info']=row['rankInfoTemplate'].replace('{rank:0:1}','68.75%').replace('{rank:1:1}','275%')
            cfg['skill'][sid]=row;hero['pl'][slot]=sid
    cfg['hero_revision_104']=True
    return document
