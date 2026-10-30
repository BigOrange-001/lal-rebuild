"""Audit and summarize the independent retest without changing balance settings."""
import json
import hashlib
from pathlib import Path
from iterate_hero_balance_104 import evaluate
from run_hero_strength_104 import study_config
from verify_hero_strength_independent_104 import verify

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'outputs/hero-strength-independent-20261030-1000'


def main():
    verify(OUT)
    report=json.loads((OUT/'results.json').read_text('utf8'));frozen=json.loads((OUT/'frozen-config.json').read_text('utf8'))
    assert report['games_per_hero']==1000 and report['total_battles']==258000
    current,_,_=study_config()
    for key in ('avatar','skill'):
        assert json.loads(json.dumps(current[key],default=str))==frozen['cfg'][key],f'{key} configuration changed during retest'
    plan=json.loads((OUT/'balance-plan.json').read_text('utf8'))
    assert hashlib.sha256(json.dumps(plan,sort_keys=True,ensure_ascii=False).encode()).hexdigest()==frozen['cfg']['hero_balance_iteration_104']['plan_sha256']
    expected={a[1] for aid in frozen['pools']['mixed'] for slot in (10,11) if len(frozen['cfg']['avatar'][aid]['pl'])>slot
              for a in frozen['cfg']['skill'].get(frozen['cfg']['avatar'][aid]['pl'][slot],{}).get('skill',[]) if a[0]=='manual_ability'}
    assert not expected-set(report['casts'])
    summary=evaluate(report)
    summary.update(sampling_design='independent-focal-hero',balance_round=6,configuration_unchanged=True,
                   actual_battles=258000,games_per_hero_per_environment=1000,other_hero_appearances_counted=False,
                   manual_branches_triggered=len(expected),balance_adjustments_in_this_retest=0)
    (OUT/'independent-summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf8')
    audit=json.loads((OUT/'verification.json').read_text('utf8'))
    audit.update(live_configuration_matches_frozen=True,all_manual_active_branches_triggered=True,manual_active_branches=len(expected))
    (OUT/'verification.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2),encoding='utf8')
    pct=lambda n:f'{n*100:.2f}%'
    lines=['# 逐英雄独立1000场复测（2026-10-30）','',
           '本次沿用第六轮平衡配置，不改变任何英雄机制或数值。总榜129名、普通榜94名、皮肤榜35名，每名英雄每个适用环境单独抽取1000场。',
           '每场只有一个指定受测英雄进入自己的统计。作为别人队友或对手的出场均不计入该英雄的1000场。',
           '实际运行总榜129000场、普通94000场、皮肤35000场，共258000场。排除2322000次非受测英雄出场，没有用共享场次补足受测样本。','',
           '## 本次结果','',
           '| 环境 | 人数 | 胜率范围 | 目标内人数 |', '|---|---:|---|---:|',
           f'| 普通独立榜 | 94 | {pct(summary["ordinary"]["minimum"])}～{pct(summary["ordinary"]["maximum"])} | {summary["ordinary"]["in_target"]}/94 |',
           f'| 皮肤独立榜 | 35 | {pct(summary["skin"]["minimum"])}～{pct(summary["skin"]["maximum"])} | {summary["skin"]["in_target"]}/35 |','',
           f'总榜普通均胜率{pct(summary["mixed_means"]["ordinary"])}，皮肤均胜率{pct(summary["mixed_means"]["skin"])}，皮肤领先{summary["mixed_gap"]*100:.2f}个百分点。','',
           '## 统计与校验','',
           '- 胜率为（胜场＋0.5×平场）÷1000，40回合后双方仍存活计平局。',
           '- 每名受测英雄左右各500场，五个位置各200场，首位担任队长。',
           '- 每场随机抽4名队友、5名对手。全场十个英雄互不相同，每名受测英雄的1000组队友集合和1000组对手集合分别不重复。',
           '- 125级、小技能10级、其他培养清零、单路五人，品质归一方式及分类沿用上一轮。',
           '- 平均伤害、治疗、抗伤占比均仅对该英雄自己的1000场计算。占比分母仍使用其该场己方队伍的总量，全队该项为零时占比记0。',
           '- 逐场记录独立复算通过，每场只给一个英雄计数，种子全局唯一，专属场次、左右及位置配额、冻结源码和配置哈希核验通过。',
           f'- {len(expected)}个手写主动技能分支均在本次实际触发。抽样测试与原有平衡回归合计7项通过。',
           '- 本轮只复测，没有按照复测结果继续调参。样本区间与是否达标均按本次结果原样报告。',
           '- 结果为离线模型统计，不代表AIR实机对战保证。','',
           '完整逐场记录位于本交付目录的battles，冻结配置和源码分别为frozen-config.json与sources，独立计数核验为verification.json。']
    for mode in ('ordinary','skin'):
        outside=summary[mode]['outside']
        if outside:
            lines+=['',f'## {"普通" if mode=="ordinary" else "皮肤"}榜超出目标区间的英雄','']
            lines += [f'- {r["name"]}：{pct(r["rate"])}。' for r in outside]
    text='\n'.join(lines)+'\n'
    (OUT/'README.txt').write_text(text,encoding='utf8');(ROOT/'docs/hero-strength-independent-20261030.md').write_text(text,encoding='utf8')
    print(json.dumps(summary,ensure_ascii=False))


if __name__=='__main__':main()
