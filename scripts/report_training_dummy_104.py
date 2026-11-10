"""Verify the completed benchmark and export all-hero comparison tables."""
import argparse
import csv
import gzip
import hashlib
import json
from pathlib import Path
import statistics

from benchmark_training_dummy_104 import ROOT,OFFENSE,DEFENSE


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--input',type=Path,default=ROOT/'build/dummy-benchmark-20261110')
    p.add_argument('--output',type=Path,default=ROOT/'docs/dummy-benchmark-20261110')
    a=p.parse_args();folder=a.input.resolve();out=a.output.resolve();out.mkdir(parents=True,exist_ok=True)
    payload=json.loads((folder/'ratio/frozen-config.json').read_text('utf8'))
    cfg=payload['cfg'];aids=payload['aids'];lookup={};verified=0;early=[];checks={}
    for model in ('legacy','ratio'):
        rows=json.loads((folder/model/'results.json').read_text('utf8'))
        assert len(rows)==len(aids)*4
        for r in rows:
            key=(model,r['aid'],r['loadout'],r['target']);assert key not in lookup;lookup[key]=r
            path=folder/model/'battles'/f"{r['aid']}-{r['loadout']}-{r['target']}.jsonl.gz"
            with gzip.open(path,'rt',encoding='utf8') as stream:raw=[json.loads(s) for s in stream]
            assert len(raw)==r['trials']
            assert len({x['seed'] for x in raw})==len(raw)
            assert statistics.mean(x['damage'] for x in raw)==r['mean']
            assert all(x['damage']==sum(x['channels'].values())==sum(x['by_round'].values()) for x in raw)
            assert all(x['casts'].get('book',0)==0 for x in raw)
            if any(x['rounds']!=100 for x in raw):early.append(key)
            verified+=len(raw)
        core=['server/battle_engine.py','server/manual_ability_sim.py','server/combat_math.py',
              'server/combat_rules.py','scripts/benchmark_training_dummy_104.py']
        checks[model+'_core_matches_frozen']=all((ROOT/f).read_bytes()==(folder/model/'sources'/f).read_bytes() for f in core)
        assert checks[model+'_core_matches_frozen']
    names={'naked':'裸装','offense':'输出装','zero':'零属性桩','armored':'满防桩'}
    summary=[]
    skins=set(cfg['system_simple'].get('skin_hero_ids',[]))
    for aid in aids:
        u=cfg['avatar'][aid];row=dict(英雄ID=aid,英雄=u['name'],类别='皮肤' if aid in skins or u.get('hero_category_104')=='skin' else '普通',品质=int(aid.rsplit('_',1)[1]))
        for loadout in ('naked','offense'):
            source=payload['sources'][aid+'|'+loadout]
            row[names[loadout]+'攻击']=source['ap'];row[names[loadout]+'生命']=source['hp_max']
            for target in ('zero','armored'):
                for model,label in (('ratio','新公式'),('legacy','旧公式')):
                    r=lookup[model,aid,loadout,target];base=names[loadout]+'_'+names[target]+'_'+label
                    row[base]=round(r['mean'],2);row[base+'_标准差']=round(r['stdev'],2)
        summary.append(row)
    ranked=sorted(summary,key=lambda r:-r['输出装_满防桩_新公式'])
    for i,r in enumerate(ranked,1):r['满防桩装备组排名']=i
    fields=['满防桩装备组排名']+[k for k in summary[0] if k!='满防桩装备组排名']
    with (out/'all-heroes.csv').open('w',encoding='utf-8-sig',newline='') as stream:
        w=csv.DictWriter(stream,fieldnames=fields);w.writeheader();w.writerows(ranked)
    # Detailed per-condition sample ranges, casts and damage channels.
    detail=[]
    for key,r in sorted(lookup.items()):
        row=dict(model=key[0],**{k:v for k,v in r.items() if k not in ('channels','casts')})
        for k,v in r['channels'].items():row['damage_'+k]=v
        for k,v in r['casts'].items():row['casts_'+k]=v
        detail.append(row)
    fields=list(dict.fromkeys(k for row in detail for k in row))
    with (out/'details.csv').open('w',encoding='utf-8-sig',newline='') as stream:
        w=csv.DictWriter(stream,fieldnames=fields);w.writeheader();w.writerows(detail)
    (out/'targets.json').write_text(json.dumps(payload['targets'],ensure_ascii=False,indent=2),encoding='utf8')
    (out/'loadout-definitions.json').write_text(json.dumps(dict(offense=OFFENSE,defense=DEFENSE,
        example_offense=payload['profiles']['A_1210_6|offense'],target_profile=payload['target_profile']),ensure_ascii=False,indent=2),encoding='utf8')
    checks.update(heroes=len(aids),verified_battles=verified,conditions=len(lookup),early_endings=early,
                  exactly_100_rounds=not early,raw_damage_channels_and_round_totals_equal=True,
                  no_passive_book_casts=True,samples_per_condition=next(iter(lookup.values()))['trials'])
    (out/'verification.json').write_text(json.dumps(checks,ensure_ascii=False,indent=2),encoding='utf8')
    hashes={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in
            [ROOT/'scripts/benchmark_training_dummy_104.py',ROOT/'scripts/report_training_dummy_104.py',
             ROOT/'scripts/test_training_dummy_104.py',ROOT/'server/battle_engine.py']}
    (out/'source-hashes.json').write_text(json.dumps(hashes,indent=2),encoding='utf8')
    # All amounts below are per 100-round battle, in ten-thousands.
    number=lambda r,l,t:f"{r[l+'_'+t+'_新公式']/10000:,.2f}"
    table=['| 排名 | 英雄 | 裸装·零属性桩 | 裸装·满防桩 | 输出装·零属性桩 | 输出装·满防桩 |',
           '| ---: | --- | ---: | ---: | ---: | ---: |']
    table += [f"| {r['满防桩装备组排名']} | {r['英雄']} | {number(r,'裸装','零属性桩')} | {number(r,'裸装','满防桩')} | {number(r,'输出装','零属性桩')} | {number(r,'输出装','满防桩')} |" for r in ranked]
    target=payload['targets']['armored'];zero=payload['targets']['zero']
    def gear_text(gear):return '、'.join(cfg['equip'][eid]['name'] for eid in gear if eid)
    text=f'''# 全英雄100回合打桩（2026-11-10）

覆盖 **{len(aids)}名英雄**。主表为本轮新公式，每个条件30个种子的100回合伤害均值；新旧两模型、两组装备、两种靶子共核验 **{verified:,}场**。本轮只测试，没有改英雄数值或切换默认公式。

全部结果见 [all-heroes.csv](all-heroes.csv)，含新旧公式的八组均值、标准差和每名英雄的实际攻击面板；[details.csv](details.csv)另列施法次数、DOT及召唤物贡献、样本最低/最高伤害。

## 测试口径

英雄使用各自实际最高品质，125级、突破3阶、普通技能10级；培养按合法总预算填满，四项各占25%的培养预算。橙卡培养预算90,000，紫卡45,000；紫卡专属英雄保留实际5★面板，不作橙卡翻倍归一。天赋统一为强攻7阶（总攻击+21%），不挂队伍羁绊、天命或公会加成。每名英雄独立担任队长，队长技和被动按当前游戏固定等级；没有人为把不可升级的技能升到10级。

- 裸装组：满级满培养，不装备任何物品。
- 输出装组：{gear_text(OFFENSE)}。其他两个装备位留空，不额外塞入防装。
- 普通装备170级，炼化至7星，洗练光环5级、附魔四项100级并解锁第5阶、符文10级；洗练总预算在装备声明的两项属性上平分。专属装备固定120%面板，普通装备取合法最高115%；输出装用攻击符文。红色符印10级，总攻击+30%，不套用普通装备的洗练附魔。

装备是全英雄同一套指定输出装，**没有逐英雄搜索最优配装**。如果这套物品恰好触发某英雄的个人装备羁绊，其实际加成保留；具体快照见 [loadout-definitions.json](loadout-definitions.json)。

两种桩均以生命上限 **{zero['hp_max']:,}** 为百分比伤害的参考值，受伤后立即补满，不触发死亡。不会把生命设成一个极大数，也不截断超过参考生命的一次伤害。这样百分比生命伤害有有限基准，两种桩也能横向比较。桩始终视为满血，因此不提供残血斩杀或击杀收益。

| 桩 | 物防 | 魔防 | 精准 | 闪避 | 暴击 | 韧性 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 零属性桩 | 0 | 0 | 0 | 0 | 0 | 0 |
| 满防桩 | {target['de_ph']:,} | {target['de_ma']:,} | {target['new_4attrs']['hit']:,} | {target['new_4attrs']['flee']:,} | {target['new_4attrs']['crit']:,} | {target['new_4attrs']['tough']:,} |

满防面板来自盖伦125级、三阶突破、满培养、坚韧7阶，穿{gear_text(DEFENSE)}。普通装备同为170级7星全满，防御符文在物防/魔防之间交替。钢铁符印10级提供总双抗+30%；这个效果已写入上表，没有在战斗中再次叠乘。桩保留生成面板，不携带盖伦的技能、反击或复活机制，不主动攻击且固定原地。四属性来自这套实际防装；满防桩并非只增加双抗。

普攻、普通技能、队长技、被动、DOT和归属于受测英雄的召唤物伤害全部计入。各组使用对应的相同种子；随机命中、暴击照常执行。100回合后的DOT不追加结算。新公式保留p=1.5、c=0.7、全局倍率0.66、原生真伤0.5及显式真伤修正0.8的研究初值；旧公式数据列在CSV中。

## 全英雄结果

**单位：万伤害/100回合。** 按新公式输出装打满防桩排序，全部英雄如下。

'''+ '\n'.join(table)+f'''

## 验证与读表范围

每场都重新核对了逐回合伤害、分通道伤害与总伤害，合计{verified:,}场；提前结束的条件数为{len(early)}。完整性记录见 [verification.json](verification.json)。靶场专项7项、战斗动作41项、服务端技能书19项测试通过。客户端技能书检查8项中有2项失败，均为旧测试没有提供穿透方法中新使用的`s2LiveMark`环境；本轮没有修改客户端，也没有用这些失败宣称实机已验证。

小样本发现被动符印会被离线模拟器误计为主动施法、挤掉普攻。本轮在服务端技能槽入口排除了无主动参数的被动技能书，并用“被动书保留100次普攻、主动书仍按冷却施放”的对照测试验证。全部正式结果生成于修正之后。之前试验批次不作为本表依据。

这是不还手、满血、单目标桩的离线输出测试。治疗、护盾、控制、反击、击杀续接和范围覆盖的团队价值没有被换算成伤害；低打桩伤害不能直接当成低实战强度。百分比生命伤害使用上述347.815万参考生命，换其他生命基准时需要重跑。未做AIR客户端或手机实测。

复现：先执行项目外层`env.ps1`，在`project`目录运行`python -B scripts/benchmark_training_dummy_104.py --trials 30 --workers 8 --output build/dummy-benchmark-rerun`，再用`report_training_dummy_104.py --input build/dummy-benchmark-rerun`导出。冻结配置、源代码及逐场记录保留在`build/dummy-benchmark-20261110/`。
'''
    (out/'report.md').write_text(text,encoding='utf8')
    print(json.dumps(checks,ensure_ascii=False),flush=True)
    for r in ranked[:12]:print(r['英雄'],number(r,'裸装','零属性桩'),number(r,'裸装','满防桩'),number(r,'输出装','零属性桩'),number(r,'输出装','满防桩'))


if __name__=='__main__':main()
