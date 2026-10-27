"""Distinct event-driven kits for legacy skin cards; final output budgets."""
import copy
from hero_calibration_104 import effect as E, sequence as S, replace_sequence


def D(r,target='lane_front',kind='magic'):
    return E('damage',target,r,damageType=kind,effect='builtin:effect/FX60_MAGIC' if kind=='magic' else 'builtin:effect/FX60_SLASH')

def H(r,target='self',**kw):return E('heal',target,r,effect='builtin:effect/FX60_HEAL',**kw)
def B(buff,target='self',amount=0,duration=2,ratio=0,**kw):
    if buff in ('weak','sunder'):amount=amount/(1-amount)
    return E('buff',target,ratio,buff=buff,amount=amount,duration=duration,effect='builtin:effect/FX60_SHIELD' if buff=='shield' else 'builtin:effect/FX60_STRONG',**kw)
def lane(a):return dict(a,target='lane_all',radius=9999)
def allies(a):return dict(a,target='ally_radius',radius=9999)


def designs():
    # Every passive has a condition established by its own active kit. Distinct
    # events (shield break, third hit, healing, control, summons) avoid requiring
    # a specific teammate or an unreliable low-health gate.
    return {
    'A_1201':[
      S('金狮冲锋','突进本路前排，造成{rank:1:5}攻击力物理伤害；自身获得{rank:2:5}攻击力护盾，持续2回合。',
        [E('move','lane_front',distance=125),D(2.8,kind='physical'),B('shield',ratio=2)],cooldown=2),
      S('王者裁决','对本路生命比例最低的敌人造成{rank:0:5}攻击力真实伤害；自身获得净化和40%双抗，持续2回合。',
        [D(3.6,'lane_lowest_hp','true'),B('purify'),B('steel',amount=.4)],warmup=2,cooldown=4),
      S('金狮不屈','护盾被敌人击破时，对攻击者造成{rank:0:5}攻击力真实伤害，并恢复{rank:1:5}攻击力生命。',
        [D(1.8,'event_source','true'),H(1.2)],event='shield_break',relation='enemy')],
    'A_1203':[
      S('恶魔契约','诅咒本路前排2回合，并造成{rank:1:5}攻击力魔法伤害。',
        [B('curse','lane_front'),D(3.2)],cooldown=2),
      S('地狱敕令','诅咒本路全体敌人2回合，并造成{rank:1:5}攻击力魔法伤害；自身获得{rank:2:5}攻击力护盾2回合。',
        [lane(B('curse')),lane(D(4)),B('shield',ratio=2)],warmup=2,cooldown=4),
      S('契约汲取','对诅咒中的敌人造成伤害时，恢复本次伤害{rank:0:18}的生命，并获得{rank:1:5}攻击力护盾2回合。',
        [H(0,eventRatio=.35),B('shield',ratio=1.2)],event='damage_dealt',otherRequiredBuff='curse',minAmount=1)],
    'A_1204':[
      S('强制配对','突进本路前排并眩晕1回合，造成{rank:2:5}攻击力物理伤害；自身获得{rank:3:5}攻击力护盾2回合。',
        [E('move','lane_front',distance=125),B('stun','lane_front',duration=1),D(2.4,kind='physical'),B('shield',ratio=2.4)],cooldown=2),
      S('过载重启','净化自身，对本路全体敌人造成{rank:1:5}攻击力魔法伤害，并为本路全体友军提供{rank:2:5}攻击力护盾2回合。',
        [B('purify'),lane(D(3.8)),allies(B('shield',ratio=2))],warmup=2,cooldown=4),
      S('应急电容','护盾被击破时，对本路敌人造成{rank:0:5}攻击力魔法伤害，并眩晕攻击者1回合。',
        [lane(D(1.6)),B('stun','event_source',duration=1)],event='shield_break',relation='enemy')],
    'A_1206':[
      S('三重心弦','对本路前排连射3箭，每箭造成{rank:0:5}攻击力物理伤害。',
        [D(1.1,kind='physical') for _ in range(3)],cooldown=2),
      S('心动追猎','自身获得30%力量和6000闪避2回合；对本路生命比例最低的敌人连射3箭，每箭造成{rank:2:5}攻击力物理伤害。',
        [B('strong',amount=.3),B('fleeup',amount=6000)]+[D(1.5,'lane_lowest_hp','physical') for _ in range(3)],warmup=1,cooldown=4),
      S('穿心誓约','每命中3次，追加{rank:0:5}攻击力真实伤害，并恢复{rank:1:5}攻击力生命。',
        [D(1.8,'event_target','true'),H(.9)],event='hit',everyEvents=3,relation='enemy',minAmount=1)],
    'A_1207':[
      S('魅力主打歌','对本路前排造成{rank:0:5}攻击力魔法伤害，并为本路友军恢复{rank:1:5}攻击力生命。',
        [D(2.7),allies(H(1.2))],cooldown=2),
      S('九尾演唱会','眩晕本路敌人1回合，造成{rank:1:5}攻击力魔法伤害；为本路友军恢复{rank:2:5}攻击力生命。',
        [lane(B('stun',duration=1)),lane(D(3.8)),allies(H(2))],warmup=2,cooldown=4),
      S('心跳安可','每完成2次有效治疗，对本路前排追加{rank:0:5}攻击力魔法伤害，并使被治疗者获得30%力量2回合。',
        [D(2),B('strong','event_target',amount=.3)],event='heal_done',everyEvents=2,minAmount=1)],
    'A_1209':[
      S('彩蛋投掷','对本路前排造成{rank:0:5}攻击力魔法伤害，并施加诅咒2回合。',
        [D(2.8),B('curse','lane_front')],cooldown=1),
      S('复活节惊喜','召唤2只继承自身55%面板的蘑菇，持续4次行动；对本路敌人造成{rank:2:5}攻击力魔法伤害。',
        [E('summon',unit='builtin:hero/A_2003_2',statRatio=.55,lifetime=4,maxAlive=1) for _ in range(2)]+[lane(D(2.5))],warmup=1,cooldown=4),
      S('守蛋小队','本路有召唤物时，每次自身行动结束，为本路友军提供{rank:0:5}攻击力护盾1回合，并对前排追加{rank:1:5}攻击力魔法伤害。',
        [allies(B('shield',ratio=.9,duration=1)),D(1.3)],event='turn_end',nearbySummons=1,nearbyRadius=9999)],
    'A_1210':[
      S('跃兔三连舞','突进本路前排，连续3次造成{rank:1:5}攻击力物理伤害。',
        [E('move','lane_front',distance=125)]+[D(1.2,kind='physical') for _ in range(3)],cooldown=2),
      S('月兔终幕斩','对本路敌人连续3次造成{rank:0:5}攻击力物理伤害，随后恢复{rank:3:5}攻击力生命。',
        [lane(D(1.5,kind='physical')) for _ in range(3)]+[H(1.5)],warmup=2,cooldown=4),
      S('舞步护身','每命中3次，获得{rank:0:5}攻击力护盾和30%力量，持续2回合。',
        [B('shield',ratio=2),B('strong',amount=.3)],event='hit',everyEvents=3,minAmount=1,relation='enemy')],
    'A_1211':[
      S('通缉射击','对本路生命比例最低的敌人造成{rank:0:5}攻击力物理伤害，破甲35%，持续2回合。',
        [D(3.2,'lane_lowest_hp','physical'),B('sunder','lane_lowest_hp',amount=.35)],cooldown=2),
      S('荒漠处决','眩晕本路生命比例最低的敌人1回合，连续两次造成{rank:1:5}攻击力物理伤害。',
        [B('stun','lane_lowest_hp',duration=1)]+[D(2.8,'lane_lowest_hp','physical') for _ in range(2)],warmup=2,cooldown=4),
      S('悬赏兑现','击杀敌人后，恢复{rank:0:5}攻击力生命，并对本路生命比例最低的敌人追加{rank:1:5}攻击力真实伤害。',
        [H(1.5),D(2,'lane_lowest_hp','true')],event='kill',relation='enemy')],
    'A_1213':[
      S('弧线传射','对本路前排造成{rank:0:5}攻击力魔法伤害，并为本路友军提供{rank:1:5}攻击力护盾1回合。',
        [D(3),allies(B('shield',ratio=.8,duration=1))],cooldown=2),
      S('绝杀世界波','对本路敌人造成{rank:0:5}攻击力魔法伤害并击退300码；本路友军获得30%力量2回合。',
        [lane(D(4.4)),E('push','lane_all',radius=9999,distance=300),allies(B('strong',amount=.3))],warmup=2,cooldown=4),
      S('团队配合','自身具有护盾时，每命中2次，对命中目标追加{rank:0:5}攻击力魔法伤害，并为本路友军恢复{rank:1:5}攻击力生命。',
        [D(1.6,'event_target'),allies(H(.8))],event='hit',everyEvents=2,requiredBuff='shield',minAmount=1)],
    'A_1214':[
      S('异议举证','诅咒本路前排2回合，再造成{rank:1:5}攻击力魔法伤害。',
        [B('curse','lane_front'),D(2.8)],cooldown=2),
      S('终审判决','诅咒本路全体敌人2回合，再造成{rank:1:5}攻击力魔法伤害；自身获得净化2回合。',
        [lane(B('curse')),lane(D(4.2)),B('purify')],warmup=2,cooldown=4),
      S('证据确凿','命中被诅咒的敌人后，追加{rank:0:5}攻击力真实伤害，并眩晕1回合。',
        [D(1.8,'event_target','true'),B('stun','event_target',duration=1)],event='hit',otherRequiredBuff='curse',minAmount=1)],
    'A_1215':[
      S('双龙探海','对本路前排连续2次造成{rank:0:5}攻击力物理伤害，获得{rank:2:5}攻击力护盾2回合。',
        [D(1.6,kind='physical'),D(1.6,kind='physical'),B('shield',ratio=1.8)],cooldown=2),
      S('神龙摆尾','对本路敌人造成{rank:0:5}攻击力物理伤害并击退350码；自身获得50%双抗2回合。',
        [lane(D(4.8,kind='physical')),E('push','lane_all',radius=9999,distance=350),B('steel',amount=.5)],warmup=2,cooldown=4),
      S('龙鳞反震','护盾被击破时，眩晕攻击者1回合，对其造成{rank:1:5}攻击力物理伤害，并恢复{rank:2:5}攻击力生命。',
        [B('stun','event_source',duration=1),D(2,'event_source','physical'),H(1.2)],event='shield_break',relation='enemy')],
    'A_1216':[
      S('寒霜棱羽','眩晕本路前排1回合，再造成{rank:1:5}攻击力魔法伤害。',
        [B('stun','lane_front',duration=1),D(2.6)],cooldown=2),
      S('极寒领域','眩晕本路敌人1回合，造成{rank:1:5}攻击力魔法伤害，并使其伤害降低30%，持续2回合。',
        [lane(B('stun',duration=1)),lane(D(4)),lane(B('weak',amount=.3))],warmup=2,cooldown=4),
      S('碎冰回响','命中眩晕中的敌人时，追加{rank:0:5}攻击力魔法伤害，并获得{rank:1:5}攻击力护盾2回合。',
        [D(1.8,'event_target'),B('shield',ratio=1.5)],event='hit',otherRequiredBuff='stun',minAmount=1)],
    'A_1218':[
      S('幽魂索命','诅咒本路前排2回合，再造成{rank:1:5}攻击力魔法伤害。',
        [B('curse','lane_front'),D(3.2)],cooldown=2),
      S('群鸦夜宴','诅咒本路敌人2回合，连续2次造成{rank:1:5}攻击力魔法伤害。',
        [lane(B('curse')),lane(D(2.3)),lane(D(2.3))],warmup=2,cooldown=4),
      S('灵魂收割','对被诅咒的敌人造成伤害时，恢复该次伤害{rank:0:18}的生命，并对其追加{rank:1:5}攻击力魔法伤害。',
        [H(0,eventRatio=.5),D(1.5,'event_target')],event='damage_dealt',otherRequiredBuff='curse',minAmount=1)],
    'A_1219':[
      S('脉冲三式','对本路前排连续3次造成{rank:0:5}攻击力物理伤害。',
        [D(1.2,kind='physical') for _ in range(3)],cooldown=2),
      S('超载绝息斩','眩晕本路敌人1回合，再连续3次造成{rank:1:5}攻击力物理伤害。',
        [lane(B('stun',duration=1))]+[lane(D(1.45,kind='physical')) for _ in range(3)],warmup=2,cooldown=4),
      S('风刃充能','每命中3次，眩晕命中目标1回合，并获得{rank:1:5}攻击力护盾2回合。',
        [B('stun','event_target',duration=1),B('shield',ratio=2.2)],event='hit',everyEvents=3,minAmount=1)],
    'A_1221':[
      S('迎春爆竹','对本路敌人造成{rank:0:5}攻击力魔法伤害；自身获得{rank:1:5}攻击力护盾2回合。',
        [lane(D(2.2)),B('shield',ratio=1.2)],cooldown=2),
      S('新岁提伯斯','召唤继承自身80%面板的提伯斯，持续5次行动；眩晕本路敌人1回合，造成{rank:2:5}攻击力魔法伤害。',
        [E('summon',unit='builtin:hero/A_2002_5',statRatio=.8,lifetime=5,maxAlive=1),lane(B('stun',duration=1)),lane(D(3))],warmup=2,cooldown=5),
      S('团圆烟火','本路有召唤物时，施放主动技能后，对本路敌人追加{rank:0:5}攻击力魔法伤害，并为本路友军恢复{rank:1:5}攻击力生命。',
        [lane(D(1.5)),allies(H(.8))],event='skill_cast',nearbySummons=1,nearbyRadius=9999)],
    'A_1228':[
      S('动感节拍','为本路友军恢复{rank:0:5}攻击力生命，提供{rank:1:5}攻击力护盾2回合。',
        [allies(H(1.8)),allies(B('shield',ratio=1.2))],cooldown=2),
      S('狂欢终乐章','眩晕本路敌人1回合，造成{rank:1:5}攻击力魔法伤害；本路友军获得净化和30%力量2回合。',
        [lane(B('stun',duration=1)),lane(D(3.8)),allies(B('purify')),allies(B('strong',amount=.3))],warmup=2,cooldown=4),
      S('低音共振','每完成3次有效治疗，对本路敌人造成{rank:0:5}攻击力魔法伤害，并使其伤害降低25%，持续2回合。',
        [lane(D(1.8)),lane(B('weak',amount=.25))],event='heal_done',everyEvents=3,minAmount=1)]
    }


def apply_skin_calibration(cfg):
    plans=designs();changed=[]
    for aid in ('A_2003_2','A_2002_5'):
        cfg['avatar'][aid]['modUnitType']='summon'
    for aid,h in list(cfg['avatar'].items()):
        family=aid.rsplit('_',1)[0]
        if family in plans:
            h['pl'] += [None]*max(0,14-len(h['pl']))
            for slot,design in zip((10,11,13),plans[family]):
                design=copy.deepcopy(design)
                if slot==10:
                    design['maxLevel']=10
                    for a in design['actions']:
                        if a.get('attackRatio',0)>0:
                            a['attackRatio']/=2;a['growth']={'attackRatio':a['attackRatio']/9}
                row=replace_sequence(cfg,h,slot,design)
                if family=='A_1204' and slot==10:
                    row['skill'][0]=['pull',0,1,200,'FX_S9003_JUDGMENT']
                    row['actionTargetPolicies']=['enemy_lane_frontmost']+[None]*(len(row['skill'])-1)
                    row['actionTargetMaxTargets']=[1]*len(row['skill'])
                    for field in ('info','rankInfoTemplate'):
                        row[field]=row[field].replace('突进本路前排','将本路前排拉近200码')
                if family=='A_1209' and slot==10:
                    row['skill'][1]=['poison',0,2,.3/.8,2,'FX_S9140_POISON']
                    row['skillUp'].append([1,3,.3/.8/9])
                    row['actionTargetPolicies']=[None,'enemy_lane_frontmost']
                    row['actionTargetMaxTargets']=[1,1]
                    for field in ('info','rankInfoTemplate'):
                        row[field]=row[field].replace('并施加诅咒2回合','并施加{rank:1:3}攻击力中毒2回合')
            changed.append(aid)
        elif family=='A_1227':
            replace_sequence(cfg,h,11,S('水漫金山','诅咒本路敌人2回合，造成{rank:1:5}攻击力魔法伤害；为本路友军恢复{rank:2:5}攻击力生命并提供{rank:3:5}攻击力护盾2回合。',
                [lane(B('curse')),lane(D(4.6)),allies(H(1.8)),allies(B('shield',ratio=1.8))],warmup=2,cooldown=4))
            changed.append(aid)
    return changed


def update_equipment_parts(cfg,plan):
    """Retain the chosen items; bind their benefits to the new actual effects."""
    for aid,design in plan['heroes'].items():
        hero=cfg['avatar'][aid]
        for order,affinity in enumerate(design['affinities']):
            candidates=[]
            # The second item favors protection when the kit has it; otherwise
            # it enhances a distinct captain damage component.
            for slot,index in [('normal',10),('captain',11)]:
                row=cfg['skill'][hero['pl'][index]]
                if not row.get('modEffectSequence') or not row.get('calibration_104'):continue
                for i,a in enumerate(row['skill']):
                    if a[0]!='mod_step' or a[5]<=0:continue
                    if a[1]=='damage':label='伤害';priority=(0 if slot=='normal' else 2) if order==0 else (3 if slot=='captain' else 4)
                    elif a[1]=='heal':label='治疗';priority=5 if order==0 else 0
                    elif a[1]=='buff' and a[8]=='shield':label='护盾';priority=5 if order==0 else 1
                    else:continue
                    if order and affinity.get('_first_binding')==(slot,i):continue
                    candidates.append((priority,slot,i,label,row))
            if not candidates:continue
            _,slot,i,label,row=min(candidates,key=lambda x:(x[0],x[2]))
            action=row['skill'][i]
            weights=[a[5]*(3 if a[2] in ('lane_all','ally_radius','all_allies','all_enemies') else 1)
                     if a[0]=='mod_step' and (a[1] in ('damage','heal') or a[1]=='buff' and a[8]=='shield') else 0 for a in row['skill']]
            for j,a in enumerate(row['skill']):
                if a[0]=='poison':weights[j]=a[1]+a[3]*a[4]
            share=weights[i]/max(sum(weights),weights[i])
            budget=.12 if cfg['equip'][affinity['equipment']]['quality']==5 else .08
            affinity.update(slot=slot,index=i,path=[5],signature=[a[0] for a in row['skill']],
                            strength=budget/share,benefit_share=share,benefit_curve=1,skill_name=row['name'],part=label,
                            info=f'{row["name"]}的{label}提高{budget/share*100:.1f}%。',review_source_104=True)
            affinity.pop('manual_kind',None)
            if order==0 and len(design['affinities'])>1:design['affinities'][1]['_first_binding']=(slot,i)
    # Azir's captain no longer replaces two summons; its existing damage
    # affinity stays on the very same damage action.
    for affinity in plan['heroes']['A_1124_6']['affinities']:
        if affinity['slot']=='captain':affinity['signature']=['damage','push_aoe','rally_soldiers']
    # Rebind only known authored bond rewrites of affected heroes. These are
    # stored explicit definitions, never a runtime fallback to another effect.
    from skill_output_104 import output_paths
    from skill_balance_overlay import _get
    for aid,design in plan['heroes'].items():
        for affinity in design['affinities']:
            affinity.pop('_first_binding',None)
            if not affinity.get('review_source_104'):continue
            field={'normal':'skill','captain':'leader_skill'}.get(affinity['slot'])
            if not field:continue
            for bindings in cfg['system_simple'].get('bond_skill_variants_104',{}).get(aid,{}).values():
                if field not in bindings:continue
                row=cfg['skill'][bindings[field]]
                if row.get('modEffectSequence'):continue
                old=affinity.get('reworks',{}).get(row['name'])
                if old and old.get('signature')==[a[0] for a in row['skill'][:len(old['signature'])]]:continue
                candidates=[]
                for i,action in enumerate(row['skill']):
                    for path in output_paths(action):
                        value=_get(action,path)
                        if isinstance(value,(int,float)) and value>0:candidates.append((i,path,value))
                if not candidates:raise ValueError('Review equipment part required: '+aid+' '+row['name'])
                i,path,value=candidates[-1 if affinity['slot']=='captain' else 0]
                share=value/sum(item[2] for item in candidates)
                budget=.12 if cfg['equip'][affinity['equipment']]['quality']==5 else .08
                label='护盾' if 'shield' in row['skill'][i][0] else '治疗' if row['skill'][i][0] in ('cure','heal_ap','heal_max_hp') else '伤害'
                affinity.setdefault('reworks',{})[row['name']]=dict(index=i,path=list(path),signature=[a[0] for a in row['skill']],
                    part=label,strength=budget/share,benefit_share=share,benefit_curve=1,skill_budget=budget,
                    info=f'{row["name"]}的第{i+1}项{label}提高{budget/share*100:.1f}%。')
