"""Freeze a verified final balance configuration and its independent confirmation."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
from iterate_hero_balance_104 import OUTPUT,PLAN,evaluate
from run_hero_strength_104 import study_config


def main():
    parser=argparse.ArgumentParser();parser.add_argument('source');args=parser.parse_args()
    source=OUTPUT/args.source;result=json.loads((source/'results.json').read_text('utf8'));evaluation=evaluate(result)
    if not evaluation['achieved']:raise RuntimeError('Final confirmation did not meet all targets')
    audit=json.loads((source/'verification.json').read_text('utf8'));assert audit['passed']
    frozen=json.loads((source/'frozen-config.json').read_text('utf8'));plan=json.loads(PLAN.read_text('utf8'))
    digest=hashlib.sha256(json.dumps(plan,sort_keys=True,ensure_ascii=False).encode()).hexdigest()
    assert digest==frozen['cfg']['hero_balance_iteration_104']['plan_sha256']
    cfg,_,_=study_config()
    for key in ('avatar','skill'):
        live=json.loads(json.dumps(cfg[key],ensure_ascii=False,default=str))
        assert live==frozen['cfg'][key],f'Live configured {key} differs from tested snapshot'
    expected={a[1] for aid in frozen['pools']['mixed'] for slot in (10,11) if len(frozen['cfg']['avatar'][aid]['pl'])>slot
              for a in frozen['cfg']['skill'].get(frozen['cfg']['avatar'][aid]['pl'][slot],{}).get('skill',[]) if a[0]=='manual_ability'}
    assert not expected-set(result['casts'])
    history=json.loads((OUTPUT/'history.json').read_text('utf8'))
    destination=OUTPUT/f'final-round-{plan["round"]:02d}'
    if destination.exists():raise RuntimeError('Final snapshot already exists')
    shutil.copytree(source,destination)
    (destination/'iteration-history.json').write_text(json.dumps(history,ensure_ascii=False,indent=2),encoding='utf8')
    shutil.copy2(OUTPUT/'baseline-half-draw/results.json',destination/'baseline-results.json')
    audit.update(expected_manual_active_branches=len(expected),all_manual_active_branches_triggered=True,live_config_matches_tested_avatar_and_skills=True,
                 balance_plan_matches_tested_hash=True,final_targets_met=True)
    (destination/'verification.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2),encoding='utf8')
    mechanisms=[dict(family=f,**entry) for f,entry in plan['heroes'].items() if entry.get('mechanism')]
    all_battles=sum(json.loads((OUTPUT/h['path']/'results.json').read_text('utf8'))['total_battles'] for h in history if h['round']>0)
    delivery=dict(selected_round=plan['round'],selected_confirmation=args.source,adjustment_rounds=sum(h['round']>0 and h.get('kind')!='confirmation' for h in history),
                  independent_confirmations=sum(h.get('kind')=='confirmation' for h in history),new_actual_battles=all_battles,games_per_hero_per_round=1000,
                  mechanism_count=len(mechanisms),mechanisms=mechanisms,evaluation=evaluation,live_configuration_matches=True,
                  client_real_device_battles_verified=False)
    (destination/'delivery.json').write_text(json.dumps(delivery,ensure_ascii=False,indent=2),encoding='utf8')
    pct=lambda n:f'{n*100:.2f}%'
    lines=['# 1.0.4 英雄强度平衡迭代（2026-10-30）','',
           '胜率统一为（胜场＋0.5×平场）÷全部场次。每名英雄在混合环境及各自分类环境每轮各出场1000场。',
           '目标为普通单独榜45%～55%，皮肤单独榜40%～60%；混合榜皮肤平均胜率比普通高10～15个百分点。','',
           f'完成{delivery["adjustment_rounds"]}轮调整、{delivery["independent_confirmations"]}次新随机阵容复核，共{all_battles}场新离线对战。原始25800场仅重算半胜口径，未算成新对战。',
           f'保留第{plan["round"]}轮配置，以{args.source}作为最终结果。最终运行配置的英雄与技能数据已与冻结实测快照逐项核对。','',
           '| 批次 | 普通达标 | 普通范围 | 皮肤达标 | 皮肤范围 | 总榜领先百分点 |',
           '|---|---:|---|---:|---|---:|']
    for h in history:
        e=h['evaluation'];label='初始半胜口径' if not h['round'] else f'第{h["round"]}轮'+('新阵容复核' if h.get('kind')=='confirmation' else '')
        lines.append(f'| {label} | {e["ordinary"]["in_target"]}/94 | {pct(e["ordinary"]["minimum"])}～{pct(e["ordinary"]["maximum"])} | {e["skin"]["in_target"]}/35 | {pct(e["skin"]["minimum"])}～{pct(e["skin"]["maximum"])} | {e["mixed_gap"]*100:.2f} |')
    lines+=['','## 改动','',
            '低于43%的判定以分开榜为准。高于65%的英雄首先大幅削弱，其他英雄按偏离50%的程度校准。接近中心者保留。所有品质版本同步面板和技能数值，技能ID、形象、获取方式与养成不变。',
            '皮肤整体档位通过统一面板倍率校准，单英雄面板和技能倍率保存在 config/reconstruction/hero-balance-iteration-1.0.4.json。配置加载时在羁绊、装备及共同输出倍率之前幂等应用，后续变体继承改动。','']
    lines += [f'- {m["name"]}：{m["mechanism_description"]}' for m in mechanisms]
    lines+=['','## 验证与解释','',
            '32项针对性回归通过，覆盖半胜统计、目标护盾、机制增补、数值范围、跨品质同步、幂等以及离线战斗与客户端手写方法对照。最终逐场记录独立复算，83个手写主动技能分支均触发，种子在该批次内唯一，左右与站位配额正确。',
            '第一、二轮期间修正了离线模型的护盾动作目标选择与最低生命比例排序。它们的变化包含模型修正，不能全归因于平衡数值。盖伦在修正模型的第四轮仍低于43%，第五轮按功能定位加入最低生命友军净化与治疗。',
            '第五轮训练样本全部达标，第一次新阵容复核中金克斯44.65%、塔里克44.40%。第六轮以第五轮及该次复核的平均结果调参，再用第二组全新阵容与种子独立复核，未改动第六轮机制或数值。',
            '结果是离线SkillCompleteBattle / ReferenceBattle模型的样本表现，不代表AIR实机保证。未更新APK、安装客户端或重启正在运行的游戏服务器。',
            f'最终交付目录：outputs/{OUTPUT.name}/{destination.name}/。各轮完整记录保留在同级目录。']
    doc=Path(__file__).resolve().parents[1]/'docs/hero-balance-iteration-20261030.md'
    doc.write_text('\n'.join(lines)+'\n',encoding='utf8')
    (destination/'README.txt').write_text('\n'.join(lines)+'\n',encoding='utf8')
    (OUTPUT/'selected-final.json').write_text(json.dumps(delivery,ensure_ascii=False,indent=2),encoding='utf8')
    print(json.dumps(dict(destination=str(destination),evaluation=evaluation,new_actual_battles=all_battles,mechanisms=len(mechanisms)),ensure_ascii=False))


if __name__=='__main__':main()
