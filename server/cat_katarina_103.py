"""User-authored Cat Katarina, applied after generic tier and DOT tuning."""
from hero_skills_103 import _skill

def apply_cat_katarina_103(document):
    cfg=document.get('cfg',document)
    for q in (5,6):
        hero=cfg['avatar'][f'A_1129_{q}'];skills=cfg['skill']
        n,c,p=(f'S_{family}_{q}' for family in (271129,371129,471129))
        normal_res=skills[hero['pl'][10]].get('res',hero['pl'][10])
        captain_res=skills[hero['pl'][11]].get('res',hero['pl'][11])
        skills[n]=_skill(n,'猫影突袭',normal_res,[0,2,3000,0,0,0],
            [['manual_ability','cat_n',1,'FX_S9130_COMBO',5000,.6,.5,.3]],['enemy_lane_frontmost'],
            '准备0，冷却2。精准提高{flat:0:4}点，持续2回合；移动至本路最前方敌人附近，'
            '对本路最靠前3名敌人各造成{rank:0:5}攻击真实伤害，再对原主目标追加{rank:0:6}攻击真实伤害。'
            '恢复本技能实际扣血总伤害的{rank:0:7}。1级至10级线性成长至两倍。',
            upgrades=[[0,4,5000/9],[0,5,.6/9],[0,6,.5/9],[0,7,.3/9]])
        skills[c]=_skill(c,'死亡莲华·真',captain_res,[2,4,3000,0,-1,1],
            [['manual_ability','cat_c',1,'FX_S9130_COMBO']],['enemy_all'],
            '准备2，冷却4。清除自身负面状态并获得2层负面抵消，保留至消耗或驱散。'
            '对全图所有敌人分别造成6段30%攻击真实伤害。全部伤害结束后，每次暴击使自身获得2回合3%力量，按本次暴击次数合计。')
        skills[p]=_skill(p,'连环猎杀',normal_res,[0,0,3000,0,-1,1],
            [['cat_passive',.4,3,5]],['enemy_all'],
            '每当击杀敌人，连续3次各随机选择一名全图存活敌人造成40%攻击真实伤害；'
            '每次重新索敌，允许重复选中。同一被动造成击杀可继续触发；每个全局回合最多触发5次。倍率固定。')
        hero['pl'][10:12]=[n,c];hero['pl'][13]=p
        hero['tl'][2]=3
        hero['skill_diff']=0
    cfg['cat_katarina_103']={'schema':'cat-katarina-1.0.3-v1','heroes':['A_1129_5','A_1129_6']}
    return document
