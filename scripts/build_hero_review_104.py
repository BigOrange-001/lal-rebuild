"""Build the offline player review desk from the current effective catalogue."""
import json,re,sys,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path[:0]=[str(ROOT/'server'),str(ROOT/'scripts')]
from gateway import Backend
from native_skill_snapshot import _native_skill_snapshot
from test_avatar_passive import method_body

# Editorial concerns, not automatic balance changes or measured win rates.
FINDINGS={
'A_1085':('高','过强','减伤成长越过100%，成为连续三次免伤','实际直接伤害倍率使用 max(0, 1 − 0.55 × 效果倍率)。橙卡当前效果倍率已超过临界值，且一整段技能只消耗一次保护。','比较凯尔的一次庇护；建议把牛头定位为较高减伤，而非同时获得多次完全免伤。'),
'A_1208':('高','过强','溢出治疗转全场真伤，可能鼓励无效治疗','被动把过量治疗按100%转换为对每名敌人的真实伤害。大招选中自己时可治疗两次，治疗目标数和敌人数可能共同放大收益。','重点核查满血自疗、治疗增益、召唤物群以及大招自选的组合。考虑降低溢出收益或限制反击目标。'),
'A_1029':('高','过强','全路叠层灼烧与永久闪避同时成长','小技能冷却0，灼烧可独立叠层并持续5回合；每次施放还叠加闪避，最多99层。伤害与生存一起增长。','先观察第3至第8回合，而不是只比较首轮伤害；考虑在持续伤害和闪避成长之间做取舍。'),
'A_1003':('高','过强','多目标四段爆发兼具高额吸血','大招对主目标及附近最多两名敌人各打四段，按伤害总量的88%回血。目标越多，爆发和续航同时增大。','核查三目标和高攻击羁绊场景；若续航替代了辅助，可降低吸血或限制用于回血的目标数。'),
'A_1217':('高','过强','召唤物击杀可推动攻击次数与攻击力双重成长','小技能次数随累计击杀增加，每次攻击又叠永久攻击；被动将召唤物击杀也计入。','用低血召唤物阵容测试滚雪球，考虑只由英雄击杀增加次数，或分别限制次数和层数。'),
'A_1129':('高','过强','击杀连锁叠加跨路随机真伤','被动击杀可以继续触发，每次触发三次全场重新索敌的真实伤害。低血召唤物可能成为连锁起点。','比较一名残血英雄与一群残血召唤物时的收益；保留收割特色，但限制无关召唤物提供的连锁次数。'),
'A_1212':('高','逻辑','本体少有直接输出，却要求本体击杀','普通技能召唤、队长技能治疗；粽香余韵由自身击杀触发。当前召唤者与召唤物的击杀归属不会因战后统计合并而自动改变。','建议优先核查是否几乎无法触发，再考虑改为粽子退场、治疗或召唤相关事件。'),
'A_1012':('高','偏弱','击杀后仍需附近至少两名敌人，常见分路难触发','被动需力量增益、击杀敌方英雄，且击杀后同路600范围内仍有至少两名敌人。两名敌人的分路无法满足，三名敌人也要求在首次击杀时距离合适。','比较常规排位与九人副本；可考虑把附近人数改为击杀前判定，或降低剩余敌人数要求。'),
'A_1006':('高','偏弱','被动要求三名其他友军，普通三人分路无法自给','救赎和弦要求同路600范围内至少3名其他友军。若每路只有3名英雄，必须依赖召唤物或额外助战。','核查是否把“其他友军”误当成含自身人数；若刻意设计召唤队，则应给出相应技能联动。'),
'A_1093':('中','过强','大招把护盾、双防和攻击集中到同一批友军','守护圣域同时提供高额护盾、数倍双防和力量，准备1、冷却2，防御与进攻收益都很集中。','比较三人同路与分散站位；建议确定主定位，保留护盾或减伤特色，削减另一项大幅增益。'),
'A_1077':('中','过强','石头人大招同时占据爆发、控制和高双防','势崩山裂具有范围伤害、眩晕和数倍双防，并且准备1、冷却2。','与蕾欧娜、阿木木同条件比较，避免三个维度都更优。'),
'A_1124':('高','联动','大招与小技能共享沙兵容量，可能替换已有战力','小技能和大招的沙兵共用最多2个的召唤组；大招召唤2名新沙兵，可能替换已有小技能沙兵。大招本身另有很高范围伤害。','核查替换是否浪费高等级小技能收益；考虑延长/强化已有沙兵，或把大招伤害转移到沙兵协同。'),
'A_1132':('中','风味','灼烧触发分身和中毒手里剑关联偏弱','大招现已改为100%面板分身，但被动仍依赖自己被灼烧，小技能核心为中毒；敌人不带灼烧时被动闲置。','作为皮肤版本可保留另类设计，但建议明确火焰/毒影设定，或改为本体与分身协同触发。'),
'A_1134':('中','风味','虚空行走变为召唤，缺少空间突袭感','队长技能主要召唤分身，被动护盾触发净化和300%双防；整体更像召唤坦克。','保留皮肤差异的前提下，考虑加入位移、反法术或蓄力突袭中的一项作为主线。'),
'A_1123':('中','风味','两个技能都固定小纳尔，形态变化缺席','普通与队长技能都保持小纳尔，缺少怒气到巨型形态的变化。','若不制作新动作，可用条件性重击、范围控制或防御形态体现转换，不必新增美术。'),
'A_1014':('中','风味','炮台会移动普攻，缺少阵地防守感','现有炮台没有技能，主要依靠面板继承并移动攻击；大小技能和被动都围绕再召唤。','考虑固定阵地、协同射击或持续部署中的一个特色，避免三个按钮只是同类召唤。'),
'A_1073':('中','偏弱','蓄力大招承担两次行动和多种打断风险','绝对零度施放当次不伤害，下次行动爆炸且占用行动；眩晕、位移等都可能中断。','与同档即时范围大招比较两轮总收益；若风险明显过高，可给打断补偿或减少行动占用。'),
'A_1008':('中','偏弱','被动要求护盾仍在且闪避，窗口可能互相消耗','宗师反攻要同时保有护盾并闪避；若护盾先被击破就无法触发，小技能提供的盾持续窗口也短。','观察首轮护盾能否撑到闪避事件；考虑保留盾后的短时反击状态而非要求护盾实体一直存在。'),
'A_1015':('中','偏弱','阿卡丽被动叠加双抗、人数和闪避三道门槛','烟中返刃要求双抗增益、附近两名敌人以及成功闪避，本体技能并不稳定提供闪避。','考虑把门槛改为位移后的首次受击/闪避，令技能组自己能打开触发窗口。'),
'A_1002':('中','逻辑','大招按生命上限索敌，可能优先命中弱小召唤物','真-魔法水晶箭选择全场生命上限最低单位，并非当前最残血英雄。','核查是否符合玩家对远程控制箭的预期；可考虑优先英雄或按当前生命比例。'),
'A_1017':('中','偏弱','破盾反击仍要求近处同时有两名敌人','被动需要护盾被敌人击破，并且350范围内至少两名敌人；对单个强敌完全不工作。','若定位反突进，可保留人数门槛；若是单兵战士，可把人数限制换为盾来源或短时窗口。'),
'A_1027':('中','过强','无冷却技能持续成长，队长技还有大额精准','维嘉小技能冷却0并永久叠攻击，大招兼具已损失生命加成和30000精准。','比较中后期命中可靠性与爆发；确认成长速度是否超过同类后期英雄。'),
'A_1126':('中','过强','单体六连击之前同时驱散和高破甲','能量倾泻先驱散增益和施加高比例破甲，再连续六次伤害，常规保护可能很难应对。','核查面对护盾、双防增益和免伤分别的表现，避免驱散加破甲让所有防御都失效。'),
'A_1202':('中','过强','大额固定暴击和精准可能压过培养差异','小技能提供100000暴击，大招提供50000精准；技能成长和羁绊进一步放大时需注意属性边际。','比较同培养橙卡的暴击与闪避，核查是否几乎稳定暴击并无法闪避。'),
'A_1207':('中','风味','偶像皮肤仍主要是伤害与回血，身份差异较少','宝珠、突进、暴击回血缺少舞台、魅惑或群体辅助的明确联动。','可把一项收益集中到魅惑、鼓舞队友或演出节奏，保持与普通阿狸的差异。'),
'A_1216':('中','风味','冰川风暴施加燃烧，命名与效果直觉冲突','队长技能名为冰川风暴，实际说明为让敌人燃烧。','若保留冰焰设定需要明确；否则可换成寒冷持续伤害或缓速控制机制。'),
'A_1219':('中','风味','源计划亚索缺少自身建立的技能联动','技能以三连击、弹射和击杀后命中为主，缺少击飞、风刃蓄层或护盾节奏。','保留机械皮肤方向，但至少加入一个由小技能建立、大招消费的状态。'),
'A_1227':('中','风味','白娘子大招仍叫水晶魔箭','小技能与被动围绕青蛇和咒术，但队长技能沿用其他英雄式的水晶魔箭名称与索敌。','优先决定是名称不符还是机制也需要调整，保持青蛇、水系或保护主题。'),
'A_1226':('中','联动','低冷却全场压制与每回合五雷可能过度集中','二郎真君同时有低冷却全场弱化/诅咒和每回合五道雷，召唤技能未必是主要收益来源。','分开统计普通、被动和召唤物伤害，确认召唤大招是否反而损失输出。'),
'A_1138':('中','过强','塔姆低冷却集火与高额自强化协同过强','小技能无冷却并触发同路集火；大招准备0，提供100%攻击与300%双防。','重点比较同路三名高攻友军时的每轮总伤害，勿只看塔姆自己的伤害。'),
}

def main():
    out=Path(sys.argv[1]) if len(sys.argv)>1 else ROOT.parent.parent/'outputs/hero-calibration-20261027'
    out.mkdir(parents=True,exist_ok=True)
    backend=Backend(':memory:',ROOT/'config/reconstruction/full-config.json')
    cfg=backend.config['cfg'];families={f for b in cfg['system_simple']['bonds_104'] for f in b['families']}
    revised='--revised' in sys.argv
    changed={aid.rsplit('_',1)[0] for key in ('heroes','skins') for aid in cfg.get('hero_calibration_104',{}).get(key,[])}
    entries=[];texts=[]
    skins=set(cfg['system_simple'].get('skin_hero_ids',[]))
    for family in sorted(families):
        variants=[]
        for aid,h in sorted(cfg['avatar'].items()):
            if aid.rsplit('_',1)[0]!=family:continue
            skills=[]
            for slot,idx in [('小技能',10),('队长技',11),('被动',13)]:
                if len(h['pl'])<=idx or not h['pl'][idx]:continue
                sid=h['pl'][idx];row=cfg['skill'].get(sid)
                if not row:continue
                level=10 if idx==10 else 1
                snap=_native_skill_snapshot(cfg,sid,level)
                text=row.get('rankInfoTemplate',row.get('info','')) if idx!=11 else row.get('info','')
                def token(m):
                    kind,a,b=m.groups();a=float(a)
                    if kind=='scale':return f'{a+float(b)*snap["skills"][row.get("modScaleActionIndex",0)][2]:.1f}%'
                    value=snap['skills'][int(a)]
                    for p in b.split('.'):value=value[int(p)]
                    value*=row.get('rankDisplayFactors104',{}).get(f'{int(a)}:{b}',1)
                    return f'{value*100:.1f}%' if kind=='rank' else str(round(value))
                text=re.sub(r'\{(rank|scale|flat):([0-9.]+):([0-9.]+)\}',token,text)
                textindex=len(texts);texts.append(text)
                skills.append(dict(slot=slot,name=row['name'],id=sid,level=level,textIndex=textindex,
                    timing=(row.get('pl') or [0,0])[:2],actions=snap['skills'],condition=row.get('modCondition'),
                    parameters={k:v for k,v in row.items() if k in ('manualDamageMultiplier','manualEffectMultiplier','manualSummonPolicy','manualClonePolicy','hero_output_rate_104','actionTargetPolicies')}))
            variants.append(dict(id=aid,name=h['name'],quality=int(aid.rsplit('_',1)[1]),skills=skills))
        if not variants:continue
        top=max(variants,key=lambda x:x['quality']);issues=[]
        if family in FINDINGS:
            severity,kind,title,evidence,proposal=FINDINGS[family]
            issues.append(dict(severity=severity,kind=kind,title=title,evidence=evidence,proposal=proposal,origin='逐英雄审阅'))
        if revised and family in changed:
            issues=[dict(severity='中',kind='联动',title='已按标定修改，待实战复核',
                         evidence='下方展示本轮修订后的当前等级技能及实际执行参数。',
                         proposal='请重点观察技能之间能否衔接、收益是否明显，以及单体和多目标场景下的强度。',origin='标定后复核')]
        if any(not re.search(r'\d|\{rank',s['info']) for s in [cfg['skill'][x['id']] for x in top['skills']] if '伤害' in s.get('info','')):
            issues.append(dict(severity='低',kind='说明',title='部分技能说明缺少伤害倍率',evidence='可见说明写了造成伤害，但未直接给出倍率。下方执行参数可用于核对。',proposal='把当前等级的实际倍率写入说明，再判断强弱。',origin='文案筛查'))
        bonds=[dict(name=b.get('name'),families=b['families'],effect=b.get('effects',{}).get(family)) for b in cfg['system_simple']['bonds_104'] if family in b['families']]
        equipment=cfg['system_simple'].get('equipment_bonds_104',{}).get(top['id'],[])
        entries.append(dict(id=family,name=top['name'],skin=top['id'] in skins,variants=variants,issues=issues,bonds=bonds,equipment=equipment))
    # Use the same AS prose cleanup as the client, not a parallel website filter.
    body=method_body((ROOT/'client/src/stages/139_SkillSet.as').read_text('utf8'),'conciseInfo104')
    js='function clean(value){'+body+'}\nconsole.log(JSON.stringify(JSON.parse(require("fs").readFileSync(0,"utf8")).map(clean)));'
    clean=json.loads(subprocess.check_output(['node','-e',js],input=json.dumps(texts,ensure_ascii=False).encode('utf8')))
    for h in entries:
        for v in h['variants']:
            for s in v['skills']:s['text']=clean[s.pop('textIndex')]
    data=dict(version='1.0.4 · 2026-10-27',heroes=entries,summary=dict(heroes=len(entries),cards=sum(len(h['variants']) for h in entries),
              skills=len(texts),flagged=sum(bool(h['issues']) for h in entries),editorial=len(FINDINGS)),
              scope='按已具名可玩英雄目录逐卡检查；含普通、皮肤和同人英雄，排除解说、野怪、小兵与未具名模板。基准为小技能10级、队长技/被动固定等级；英雄羁绊与装备羁绊列为额外上下文，不假定全部同时激活。静态机制审阅，不等于实战胜率结论。')
    (out/'review-data.json').write_text(json.dumps(data,ensure_ascii=False,indent=2,default=str),encoding='utf8')
    template=(ROOT/'scripts/hero_review_104.html').read_text('utf8')
    if revised:
        data['version']='1.0.4 · 标定后复核 · 2026-10-27'
        template=template.replace("KEY='lal-skill-review-104-v1'","KEY='lal-skill-review-104-revised-v1'")
        (out/'review-data.json').write_text(json.dumps(data,ensure_ascii=False,indent=2,default=str),encoding='utf8')
    (out/'index.html').write_text(template.replace('__REVIEW_DATA__',json.dumps(data,ensure_ascii=False,default=str).replace('</','<\\/')),encoding='utf8')
    backend.clock.close();backend.db.close();print(json.dumps(data['summary'],ensure_ascii=False))

if __name__=='__main__':main()
