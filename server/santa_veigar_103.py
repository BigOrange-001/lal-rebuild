"""Santa Veigar: permanent attack stacks and kill-count normal repeats."""
from hero_skills_103 import _skill

def apply_santa_veigar_103(document):
    cfg=document.get('cfg',document)
    for q in (5,6):
        hero=cfg['avatar'][f'A_1217_{q}'];skills=cfg['skill']
        n,c,p=(f'S_{family}_{q}' for family in (271217,371217,471217))
        normal_res=skills[hero['pl'][10]].get('res',hero['pl'][10])
        captain_res=skills[hero['pl'][11]].get('res',hero['pl'][11])
        skills[n]=_skill(n,'圣诞黑暗祭祀',normal_res,[0,0,3000,0,0,0],
            [['manual_ability','santa_n',1,'FX_S9004_ARC',1.3]],['enemy_lane_all'],
            '准备0，冷却0。每次释放开始时锁定结算次数为1＋本局累计击杀数；每次结算重新随机选择本路一名存活敌人，'
            '造成{rank:0:4}攻击魔法伤害，随后获得1层永久5%攻击增益。本次新增击杀从下次释放起增加结算次数。'
            '本技能伤害1～10级线性成长至两倍，每层5%不随等级成长。层内加算，与其他攻击增益独立乘算。',
            upgrades=[[0,4,1.3/9]])
        skills[c]=_skill(c,'圣诞终焉',captain_res,[0,6,3000,0,-1,1],
            [['manual_ability','santa_c',1,'FX_S9004_ARC']],['enemy_all'],
            '准备0，冷却6。对全图所有敌人造成30%攻击真实伤害，命中后眩晕1回合。')
        skills[p]=_skill(p,'邪恶圣诞礼物',normal_res,[0,0,3000,0,-1,1],
            [['santa_kill',2,1,.05]],['enemy_all'],
            '每击杀一名敌方单位（包括召唤物），获得2层永久5%攻击增益，并累计1次本局击杀。'
            '之后每次小技能在释放开始时，按1＋累计击杀数锁定结算次数；击杀不立即额外施法。'
            '同层攻击加算，与其他攻击增益独立乘算，持续到战斗结束。每层5%固定，不随技能等级成长。')
        hero['pl'][10:12]=[n,c];hero['pl'][13]=p;hero['tl'][2]=2;hero['skill_diff']=0
    cfg['santa_veigar_103']={'schema':'santa-veigar-1.0.3-v2','heroes':['A_1217_5','A_1217_6']}
    return document
