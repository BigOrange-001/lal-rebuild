"""User-authored Polar Ashe and round-based basic-attack followups."""
from hero_skills_103 import _skill

def apply_polar_ashe_103(document):
    cfg=document.get('cfg',document)
    for q in (5,6):
        hero=cfg['avatar'][f'A_1202_{q}'];skills=cfg['skill']
        n,c,p=(f'S_{family}_{q}' for family in (271202,371202,471202))
        normal_res=skills[hero['pl'][10]].get('res',hero['pl'][10])
        captain_res=skills[hero['pl'][11]].get('res',hero['pl'][11])
        skills[n]=_skill(n,'极地齐射',normal_res,[1,0,3000,0,-1,0],
            [['manual_ability','polar_n',1,'FX_S9004_ARC',100000,.35,.7]],['enemy_lane_all'],
            '准备1，冷却0。自身暴击提高{flat:0:4}点，持续1回合；对本路所有敌人造成{rank:0:6}攻击物理伤害，'
            '命中后施加{rank:0:5}破甲，持续1回合。暴击、破甲及伤害在1级至10级线性成长至两倍。',
            upgrades=[[0,4,100000/9],[0,5,.35/9],[0,6,.7/9]])
        skills[c]=_skill(c,'极地魔法水晶箭',captain_res,[3,3,3000,0,-1,1],
            [['manual_ability','polar_c',1,'FX_S9004_ARC']],['enemy_all'],
            '准备3，冷却3。本次施放期间精准额外提高50000点；选择全图实时总攻击最高的敌人，'
            '对其及本路距离其300码以内的全部敌人造成300%攻击魔法伤害；命中后附加诅咒和眩晕，各持续1回合。施放后恢复原精准。')
        skills[p]=_skill(p,'极地追击',normal_res,[0,0,3000,0,-1,1],
            [['polar_basic',.6,4]],['enemy_lane_all'],
            '普通攻击时对本路随机一名存活敌人额外造成60%×n攻击物理伤害。n初始0，每个全局回合首次普攻先增加1，'
            '最多4；同回合再次普攻不重复增加层数。未普攻的完整回合减少1，最低0。额外攻击不会再次触发此被动。')
        hero['pl'][10:12]=[n,c];hero['pl'][13]=p;hero['tl'][2]=1;hero['skill_diff']=0
    cfg['polar_ashe_103']={'schema':'polar-ashe-1.0.3-v1','heroes':['A_1202_5','A_1202_6']}
    return document
