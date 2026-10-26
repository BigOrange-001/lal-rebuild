"""Author equipment affinities from classic build roles and exclusive themes."""
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
ROLES={
 '射手': [1025,1030,1053,1078,1083,1099,1115,1136,1142,1202,1206,1211,1213,1222,1223],
 '物理战士/刺客': [1023,1024,1026,1028,1041,1056,1097,1101,1108,1113,1119,1123,1130,1132,1135,1143,1201,1210,1215,1219,1226,1311],
 '坦克': [1032,1049,1054,1073,1074,1077,1085,1090,1112,1138,1204,1205],
 '法术输出': [1022,1027,1029,1033,1036,1040,1052,1060,1063,1068,1071,1079,1081,1082,1086,1096,1098,1103,1105,1106,1109,1114,1117,1120,1124,1125,1126,1127,1128,1129,1133,1134,1137,1203,1207,1209,1214,1216,1217,1218,1221,1227,1309,1310],
 '辅助': [1045,1093,1094,1095,1131,1139,1208,1212,1228,1998],
}
# One additional effect per exclusive item, attached to the ordinary skill.
# These are authored tactical budgets around 20%, not measured win-rate gains.
# Damage/healing/shield coefficients subsequently receive the global output pass.
EXCLUSIVES=[
 ('E_1002_6',[1127],'镜花破障',['dispel_good',1,'FX60_PURIFY'],'enemy_global_lowest_hp_ratio_hero','小技能额外驱散全场最低生命比例敌方英雄的一个增益。'),
 ('E_1006_6',[1101,1113],'切开重甲',['sunder_percent',0,1,.12,1,'FX60_SUNDER'],'enemy_lane_frontmost','小技能额外削弱本路前排12%双防，持续1回合。'),
 ('E_1011_6',[1210],'兔跃护锋',['caster_ap_shield',.4,1,'FX60_SHIELD'],'ally_self','小技能后获得40%攻击护盾，持续1回合。'),
 ('E_1012_6',[1081,1216],'冰羽迟滞',['weak_percent',0,2,.12,1,'FX60_WEAK'],'enemy_lane_frontmost','小技能额外削弱本路前排12%攻击，持续1回合。'),
 ('E_1013_6',[1082,1309,1310],'斥候余毒',['burn',.175,2,'FX60_BURN'],'enemy_lane_frontmost','小技能给本路前排附加两次灼伤，总计35%攻击，并触发灼伤减疗。'),
 ('E_1014_5',[1030],'弹幕追猎',['damage',.35,1,'FX60_SLASH_COMBO'],'enemy_global_lowest_hp_ratio_hero','小技能追加跨路追击：对最低生命比例敌方英雄造成35%攻击物理伤害。'),
 ('E_1017_6',[1078],'回旋护步',['caster_ap_shield',.35,1,'FX60_SHIELD'],'ally_self','小技能回收刀刃时获得35%攻击护盾，持续1回合。'),
 ('E_1018_6',[1204],'过载外壳',['armor',.12,1,'FX60_SHIELD'],'ally_self','小技能后自身双防提高12%，持续1回合。'),
 ('E_1019_6',[1219],'风刃穿阵',['damage',.35,1,'FX60_SLASH_COMBO'],'enemy_lane_highest_attack_hero_fallback_any','小技能额外斩击本路最高攻击英雄，造成35%攻击物理伤害。'),
 ('E_1021_6',[1206],'穿心剥离',['dispel_good',1,'FX60_PURIFY'],'enemy_lane_frontmost','小技能额外驱散本路前排的一个增益。'),
 ('E_1022_6',[1068],'余烬封疗',['burn',.175,2,'FX60_BURN'],'enemy_lane_frontmost','小技能额外灼烧本路前排，总计35%攻击分两次结算，并附带灼伤减疗。'),
 ('E_1023_6',[1201],'日冕护体',['caster_ap_shield',.4,1,'FX60_SHIELD'],'ally_self','小技能结束后获得40%攻击护盾，持续1回合。'),
 ('E_1024_6',[1211],'沙漠狙击',['damage',.35,1,'FX60_SLASH_COMBO'],'enemy_global_lowest_hp_ratio_hero','小技能追击全场最低生命比例英雄，额外造成35%攻击物理伤害。'),
 ('E_1025_6',[1202],'寒霜压制',['weak_percent',0,1,.12,1,'FX60_WEAK'],'enemy_lane_frontmost','小技能额外削弱本路前排12%攻击，持续1回合。'),
 ('E_1026_6',[1213,1222],'奥能回流',['caster_ap_shield',.35,1,'FX60_SHIELD'],'ally_self','小技能回收奥能，获得35%攻击护盾，持续1回合。'),
 ('E_1027_6',[1115],'爆破余焰',['burn',.175,2,'FX60_BURN'],'enemy_lane_frontmost','小技能额外灼烧本路前排，总计35%攻击分两次结算。'),
 ('E_1028_6',[1221],'年兽护佑',['caster_ap_shield',.35,1,'FX60_SHIELD'],'ally_self','小技能获得年兽护盾，数值为35%攻击，持续1回合。'),
 ('E_1029_6',[1053],'贴身破甲',['sunder_percent',0,1,.12,1,'FX60_SUNDER'],'enemy_lane_frontmost','小技能额外削弱本路前排12%双防，持续1回合。'),
 ('E_1030_6',[1079],'噩梦蚀力',['weak_percent',0,2,.12,1,'FX60_WEAK'],'enemy_lane_frontmost','小技能额外削弱本路前排12%攻击，持续1回合。'),
 ('E_1031_6',[1208],'急救补针',['caster_hp_heal',.025,'FX60_HEAL'],'ally_all_lowest_hp_ratio','小技能额外救治全场最低生命比例友方英雄，恢复施法者2.5%最大生命。'),
 ('E_1032_6',[1137],'冥铁护壳',['caster_ap_shield',.4,1,'FX60_SHIELD'],'ally_self','小技能将冥铁铸成40%攻击护盾，持续1回合。'),
 ('E_1033_6',[1114],'雷云击穿',['sunder_percent',0,2,.12,1,'FX60_SUNDER'],'enemy_lane_frontmost','小技能雷云削弱本路前排12%双防，持续1回合。'),
 ('E_1041_6',[1045],'仙灵补护',['caster_ap_shield',.35,1,'FX60_SHIELD'],'ally_all_lowest_hp_ratio','小技能为全场最低生命比例友方英雄补充35%攻击护盾，持续1回合。'),
 ('E_1051_6',[1028],'恶魔汲血',['caster_hp_heal',.025,'FX60_HEAL'],'ally_self','小技能额外恢复自身2.5%最大生命。'),
 ('E_1061_6',[1129],'暗刃拆盾',['dispel_good',1,'FX60_PURIFY'],'enemy_global_lowest_hp_ratio_hero','小技能额外驱散全场最低生命比例敌方英雄的一个增益。'),
 ('E_3006_6',[1109],'猩红回涌',['caster_hp_heal',.025,'FX60_HEAL'],'ally_self','小技能结束后额外恢复自身2.5%最大生命。'),
 ('E_3007_6',[1133],'暗翼庇护',['caster_ap_shield',.35,1,'FX60_SHIELD'],'ally_all_lowest_hp_ratio','小技能给全场最低生命比例友方英雄补充35%攻击护盾，持续1回合。'),
 ('E_4013_6',[1218],'幽魂蚀甲',['sunder_percent',0,2,.12,1,'FX60_SUNDER'],'enemy_lane_frontmost','小技能额外削弱本路前排12%双防，持续1回合。'),
 ('E_4014_6',[1228],'返场和弦',['caster_hp_heal',.025,'FX60_HEAL'],'ally_all_lowest_hp_ratio','小技能额外治疗全场最低生命比例友方英雄，恢复施法者2.5%最大生命。'),
 ('E_4016_6',[1093],'晶体折光',['caster_ap_shield',.35,1,'FX60_SHIELD'],'ally_all_lowest_hp_ratio','小技能为全场最低生命比例友方英雄附加35%攻击护盾，持续1回合。'),
 ('E_4018_6',[1054],'龙血余焰',['burn',.175,2,'FX60_BURN'],'enemy_lane_frontmost','小技能额外灼烧本路前排，总计35%攻击分两次结算。'),
 ('E_4020_6',[1029],'提伯斯守护',['caster_ap_shield',.35,1,'FX60_SHIELD'],'ally_self','小技能由提伯斯提供35%攻击护盾，持续1回合。'),
 ('E_4021_6',[1128],'欺诈护幕',['caster_ap_shield',.35,1,'FX60_SHIELD'],'ally_self','小技能结束后获得35%攻击护盾，持续1回合。'),
 ('E_4022_6',[1135],'猎物剥甲',['sunder_percent',0,1,.12,1,'FX60_SUNDER'],'enemy_lane_frontmost','小技能额外削弱本路前排12%双防，持续1回合。'),
 ('E_4024_6',[1134],'虚空回护',['caster_ap_shield',.35,1,'FX60_SHIELD'],'ally_self','小技能结束后获得35%攻击护盾，持续1回合。'),
]


def part_info(name,part,strength,share,budget):
    return f'《{name}》：仅{part}提高{strength*100:.2f}%。该部分按技能等效收益的{share*100:.2f}%估值，整项技能目标提升{budget*100:g}%；其他部分不变。'


def build():
    import sys
    from unittest.mock import patch
    from equipment_affinity_designs_104 import DESIGNS, REWORKS, SHARES, REWORK_SHARES
    sys.path.insert(0,str(ROOT/'server'))
    from gateway import Backend
    with patch('equipment_bonds_104.apply_equipment_bonds_104',lambda d:d):
        backend=Backend(':memory:',ROOT/'config/reconstruction/full-config.json')
    cfg=backend.config['cfg'];backend.db.close()
    heroes={}
    for role,families in ROLES.items():
        for family in families:
            aid=f'A_{family}_6'
            if aid in heroes:raise ValueError(aid)
            heroes[aid]={'role':role,'equipment':['E_'+r[4] for r in DESIGNS[family]],
                         'basis':'逐英雄审阅当前技能，装备强化指定结算项；皮肤按自己的实际技能独立设计。'}
    exclusive=[{'equipment':eid,'heroes':[f'A_{n}_6' for n in families],'name':name,
                'action':action,'policy':policy,'info':info,'power_budget':.20}
               for eid,families,name,action,policy,info in EXCLUSIVES]
    for aid,hero in heroes.items():
        hero['affinities']=[]
        for number,(slot,index,path,part,eid) in enumerate(DESIGNS[int(aid.split('_')[1])]):
            slot={'n':'normal','c':'captain','p':'passive'}[slot]
            source=cfg['skill'][cfg['avatar'][aid]['pl'][{'normal':10,'captain':11,'passive':13}[slot]]]
            share=SHARES[int(aid.split('_')[1])][number]
            budget=.12 if cfg['equip']['E_'+eid]['quality']==5 else .08
            summon_curve=1.5 if '继承比例' in part else 1
            strength=(1+budget/share)**(1/summon_curve)-1
            target=dict(slot=slot,index=index,path=path,part=part,strength=strength,equipment='E_'+eid,
                        benefit_share=share,benefit_curve=summon_curve,skill_budget=budget,
                        skill_name=source['name'],mode='part',action=None)
            if isinstance(index,int):
                action=source['skill'][index];target['operator']=action[0]
                target['signature']=[a[0] for a in source['skill']]
                value=action
                for item in path:value=value[item]
                if type(value) not in (float,int) or value<=0:raise ValueError((aid,part,value))
            else:
                assert source['skill'][0][0]=='manual_ability'
                target['manual_kind']=source['skill'][0][1]
            target['info']=part_info(source['name'],part,strength,share,budget)
            target['reworks']={}
            for (family,item,name),(ri,rp,rpart) in REWORKS.items():
                if family!=int(aid.split('_')[1]) or item!=eid:continue
                sources=[cfg['skill'][sid] for v in cfg['system_simple']['bond_skill_variants_104'][aid].values() for sid in v.values() if cfg['skill'][sid]['name']==name]
                assert sources,(aid,name)
                rewritten=sources[0];assert isinstance(rewritten['skill'][ri][rp[0]],(float,int))
                share2=REWORK_SHARES[(family,item,name)];strength2=budget/share2
                target['reworks'][name]=dict(index=ri,path=rp,part=rpart,strength=strength2,
                    benefit_share=share2,benefit_curve=1,skill_budget=budget,
                    signature=[a[0] for a in rewritten['skill']],operator=rewritten['skill'][ri][0],
                    info=part_info(name,rpart,strength2,share2,budget))
            hero['affinities'].append(target)
    doc={'schema':'equipment-bonds-1.0.4-v4',
         'stacking':'hero-specific existing skill components; no generic extra effects',
         'heroes':heroes,'exclusive':exclusive}
    (ROOT/'config/reconstruction/equipment-bonds-1.0.4.json').write_bytes((json.dumps(doc,ensure_ascii=False,indent=2)+'\n').encode())

if __name__=='__main__':build()
