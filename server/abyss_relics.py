"""Relic inventory, independent seventh slot, rolls and serialized skill variants."""
import copy
import hashlib
import secrets

from player_store import GameplayFault
from roguelite_abyss import rng_for, rules

SUBSTATS = {'hp':('生命',.06,.12), 'ap':('攻击',.04,.08),
            'de_ph':('物防',.06,.12), 'de_ma':('魔防',.06,.12),
            'hit':('精准',.2,.5), 'flee':('闪避',.2,.5),
            'crit':('暴击',.2,.5), 'tough':('韧性',.2,.5)}
A_TYPES = (8,9,10,11,13,20)
NAMES = ['不灭圣盾','先声夺人','坚守誓约','复苏之羽','荆棘之躯','疾风步','嗜血',
         '破军','斩首','余烬','剧毒','碎盾','寒霜','圣佑','坚城','统御','同心','召唤契约','时之沙','真理之刃']


def main_effect(kind, ancient=False):
    factor = 1.25 if ancient and kind!=19 else 1
    values = {1:1,2:1,3:0,4:.5,5:.2,6:.1,7:.25,8:.4,9:.6,10:.4,11:.4,
              12:1,13:.2,14:.5,15:.06,16:.06,17:.15,18:.35,19:2,20:.4}
    value = values[kind]*factor
    if kind==12 and ancient: value=1.5  # Authored 2.5x total shield damage.
    return {'id':kind,'ancient':bool(ancient and kind!=19),'value':value,
            'shield_rate':.25 if kind==3 and ancient else 0,
            'duration':3 if kind in (1,3) else 2 if kind in (10,11) else 1 if kind==13 else 0,
            'per_round':2 if kind==6 else 0, 'threshold':.5 if kind in (3,8,9) else 0}


def main_text(effect):
    kind, value = effect['id'], effect['value']
    percent = f'{value*100:g}%'
    texts = {
        1:f'登场时获得{percent}生命上限的护盾，持续3回合。',
        2:f'第1回合造成的伤害提高{percent}。',
        3:'每场首次生命低于50%时恢复至满生命。'+('并获得25%生命上限的护盾，持续3回合。' if effect['ancient'] else ''),
        4:f'每场首次阵亡时以{percent}生命复活，并净化自身。',
        5:f'受到攻击时，对攻击者反弹{percent}所受伤害，造成真实伤害。',
        6:f'闪避后获得{percent}生命上限的护盾，每回合最多2次。',
        7:f'自身造成的伤害的{percent}转为自身治疗，不触发护士阿卡丽的受治疗反击。',
        8:f'小技能对生命高于50%的目标额外造成{percent}伤害。',
        9:f'小技能对生命低于50%的目标伤害提高{percent}。',
        10:f'小技能附加灼烧，持续2回合，每段{percent}攻击力。',
        11:f'小技能附加中毒，持续2回合，每段{percent}攻击力。',
        12:f'自身对护盾造成的伤害为{1+value:g}倍，溢出伤害按原伤害计算。',
        13:f'小技能有{percent}概率眩晕目标1回合。',
        14:f'自身施加的治疗量与护盾量提高{percent}。',
        15:f'作为队长时，全队受到的伤害独立降低{percent}。',
        16:f'作为队长时，全队攻击提高{percent}。',
        17:f'同路每有1名其他友军存活，自身伤害提高{percent}。',
        18:f'召唤物继承面板提高{percent}。',
        19:'大招准备减少2。',
        20:f'小技能{percent}伤害转为真实伤害。',
    }
    return ('*' if effect['ancient'] else '')+texts[kind]


def roll_substat(rng, cfg, key):
    plan = rules(cfg)
    _, lower, upper = SUBSTATS[key]
    ancient = rng.random()<plan['ancient_chance']
    value = upper*plan['ancient_multiplier'] if ancient else round(rng.uniform(lower,upper),6)
    return {'stat':key,'value':value,'ancient':ancient,'text':substat_text(key,value,ancient)}


def substat_text(key, value, ancient):
    return ('*' if ancient else '')+f'{SUBSTATS[key][0]}+{value*100:.1f}%'


def roll_substats(rng, cfg):
    return [roll_substat(rng,cfg,key) for key in rng.sample(list(SUBSTATS),3)]


def new_relic(cfg, rng, kind=None, item_id=None):
    kind = rng.randint(1,20) if kind is None else kind
    ancient = rng.random()<rules(cfg)['ancient_chance'] and kind!=19
    effect = main_effect(kind,ancient)
    return {'id':item_id or 'relic-'+secrets.token_hex(12),'type':'relic','relic_id':kind,
            'name':NAMES[kind-1], 'main':{**effect,'text':main_text(effect)},
            'substats':roll_substats(rng,cfg), 'schema':1}


def normalize_relic_slots(profile):
    profile.setdefault('abyss_relics',{})
    for item in profile['abyss_relics'].values():
        for affix in item.get('substats',[]):
            affix['text'] = substat_text(affix['stat'],affix['value'],affix['ancient'])
    groups = profile.setdefault('as_equips',[[] for _ in range(6)])
    if not isinstance(groups,list): groups = []; profile['as_equips'] = groups
    while len(groups)<6: groups.append([])
    for index in range(6):
        row = groups[index] if isinstance(groups[index],list) else []
        groups[index] = (row+[None]*7)[:7]


def grant_boss_rewards(profile, run, node, cfg):
    normalize_relic_slots(profile)
    rng = rng_for(run['seed'], 'boss_reward', node['id'])
    base = [.2,.3,.5][node['act']-1]
    chance = round(base*(1+(run['difficulty']-1)/9),4)
    count = int(rng.random()<chance) + int(node['act']==3)
    for index in range(count):
        item = new_relic(cfg,rng)
        profile['abyss_relics'][item['id']] = item
        run['rewards'].append({'node_id':node['id'],'item_id':item['id'],
                               'guaranteed':node['act']==3 and index==count-1})


def relic_response(profile):
    normalize_relic_slots(profile)
    return {'abyss_relics':copy.deepcopy(profile['abyss_relics']),
            'as_equips':copy.deepcopy(profile['as_equips'])}


def mutate_relic(profile, method, params, cfg):
    normalize_relic_slots(profile)
    if method=='user.abyss_relics': return relic_response(profile)
    iid = params.get('item_id')
    if not isinstance(iid,str) or iid not in profile['abyss_relics']:
        raise GameplayFault('AbyssUnknownRelic','该深渊遗物不存在。')
    item = profile['abyss_relics'][iid]
    if method=='user.abyss_relic_reroll':
        index = params.get('substat_index')
        if type(index) is not int or not 0<=index<=2:
            raise GameplayFault('AbyssInvalidSubstatIndex','请选择第1至3条副词条。')
        material = params.get('material_id')
        if not isinstance(material,str) or material==iid or material not in profile['abyss_relics']:
            raise GameplayFault('AbyssInvalidRelicMaterial','请选择另一件深渊遗物作为材料。')
        if any(row[6]==material for row in profile['as_equips']):
            raise GameplayFault('EquipmentInUse','请先卸下材料深渊遗物。')
        rng = secrets.SystemRandom()
        excluded = {affix['stat'] for i,affix in enumerate(item['substats']) if i!=index}
        key = rng.choice([key for key in SUBSTATS if key not in excluded])
        item['substats'][index] = roll_substat(rng,cfg,key)
        del profile['abyss_relics'][material]
    elif method=='user.abyss_relic_equip':
        slot = params.get('slot')
        if type(slot) is not int or not 0<=slot<6:
            raise GameplayFault('AbyssInvalidRelicSlot','阵位必须为0至5。')
        if any(row[6]==iid for i,row in enumerate(profile['as_equips']) if i!=slot):
            raise GameplayFault('EquipmentInUse','该深渊遗物已在其他阵位穿戴。')
        profile['as_equips'][slot][6] = iid
    elif method=='user.abyss_relic_unequip':
        for row in profile['as_equips']:
            if row[6]==iid: row[6] = None
    return relic_response(profile)


def equipped_relic(profile, slot):
    groups = profile.get('as_equips',[])
    if slot is None or slot>=len(groups) or len(groups[slot])<7: return None
    return profile.get('abyss_relics',{}).get(groups[slot][6])


def apply_panel(stats, relic):
    before = {key:stats.get(key,0) for key in SUBSTATS}
    for affix in relic['substats']:
        key = affix['stat']
        stats[key] = int(stats.get(key,0)*(1+affix['value']))
    return {key:stats[key]-value for key,value in before.items()}


def variant_id(source, kind, ancient):
    digest = hashlib.sha256(source.encode()).hexdigest()[:16]
    return f'S_ABYSS{kind}{int(ancient)}_{digest}_{source.rsplit("_",1)[-1]}'


def ensure_relic_skill_variants(document):
    """Add variants for the effective normal skills, including per-save Mods."""
    cfg = document.get('cfg',document)
    sources = {v['pl'][10] for aid,v in cfg.get('avatar',{}).items() if aid.startswith('A_1')}
    simple = cfg.setdefault('system_simple',{})
    for variants in simple.get('bond_skill_variants_104',{}).values():
        sources.update(row['skill'] for row in variants.values() if row.get('skill'))
    for mapping in simple.get('equipment_skill_variants_104',{}).values():
        for source,variants in mapping.items():
            if source in sources: sources.update(variants.values())
    # Mod heroes may have no normal skill (pl[10] is None); only real skill IDs get variants.
    for source in sorted(s for s in sources if isinstance(s, str) and s):
        if source not in cfg['skill']: continue
        for kind in A_TYPES:
            for ancient in (False,True):
                sid = variant_id(source,kind,ancient)
                if sid in cfg['skill']:continue
                # Configuration arrays are read-only. Share unchanged data so
                # AMF3 and deepcopy preserve references instead of replicating
                # every action matrix for every relic/quality combination.
                row = cfg['skill'][source].copy()
                row['equipment_source_skill_104'] = row.get('equipment_source_skill_104') or source
                row['abyss_relic_A'] = main_effect(kind,ancient)
                row['relic_source_skill'] = source
                for policy in ('manualSummonPolicy','manualClonePolicy'):
                    if isinstance(row.get(policy),dict) and row[policy].get('skillId')==source:
                        row[policy] = copy.deepcopy(row[policy])
                        row[policy]['skillId']=sid
                row['info'] = str(row.get('info',''))+'\n'+main_text(row['abyss_relic_A'])
                cfg['skill'][sid] = row
    return document


def apply_relic_config(document):
    cfg = document.get('cfg',document)
    if cfg.get('system_simple',{}).get('abyss_relic_schema')==1: return document
    ensure_relic_skill_variants(document)
    simple = cfg.setdefault('system_simple',{})
    simple['abyss_relic_schema'] = 1
    simple['abyss_relic_types'] = [{'id':kind,'name':NAMES[kind-1],
        'class':'A' if kind in A_TYPES else 'B', 'normal':main_effect(kind),
        'text':main_text(main_effect(kind)),'ancient_text':main_text(main_effect(kind,True))}
        for kind in range(1,21)]
    simple['abyss_relic_main_power_rate'] = .15
    return document
