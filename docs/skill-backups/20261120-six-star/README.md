# 六星英雄旧版技能备份

基线为 `08dc636e87a9e5b14e8e0a6e80ff71a28ff7be8b`，即本次英雄平衡进入 PR 分支前的主线版本。该基线已包含新版对抗四属性公式。英雄平衡在 PR 分支上的提交为 `a0903d5d403652c1e8543ff4253627bff51915cb`。

| 文件 | 内容 |
| --- | --- |
| [old-skills.xlsx](old-skills.xlsx) | 56 个英雄的 168 个技能位，按角色编号和技能位查找。141 个已配置的技能保留旧编号、名称、准备、冷却和客户端说明。小技能显示 10 级，队长技和被动显示 1 级。 |
| [old-skill-config.json](old-skill-config.json) | 按原编号保存旧版有效配置。包含目标英雄和关联召唤模板、完整技能动作与成长数据、施放和选取条件，以及英雄羁绊、装备羁绊的技能变体映射。共 1,020 条旧技能定义。 |
| [old-skill-source.zip](old-skill-source.zip) | 20 个原始代码与构建配置文件，位于压缩包的 `08dc636/` 目录下，内部沿用仓库路径。文件字节与基线 Git 版本一致，可通过配置快照中的 `sourceSha256` 校验。 |

## 旧代码索引

- `client/src/stages/137_Avatar.as` 和 `client/src/stages/139_SkillSet.as` 对应旧版客户端技能执行、命中结算、召唤和事件处理。
- `client/src/combat_rules_104.aspart`、`client/build.json` 和 `config/reconstruction/combat-rules-1.0.4.json` 保存基线客户端战斗公式、阶段构建配置和规则参数。
- `server/battle_engine.py`、`server/manual_ability_sim.py`、`server/battle_mod_effects.py`、`server/battle_mod_events.py`、`server/nightbringer_yasuo_sim.py`、`server/combat_math.py` 和 `server/combat_rules.py` 对应旧版战斗模拟、技能处理和公式。
- `server/gateway.py`、`server/native_skill_snapshot.py`、`server/mod_native.py`、`server/skill_output_104.py`、`server/skill_rank_growth_104.py`、`server/bonds_104.py`、`server/equipment_bonds_104.py` 和 `server/equipment_rebinding_105.py` 对应旧版配置加载、技能成长和羁绊处理。

## 回退

如果英雄平衡已合入主线，从最新主线建回退分支，并反向提交英雄平衡代码。备份文件由独立提交保存。若使用压缩合并且本地找不到英雄平衡提交，先从对应 PR 取回提交记录。

```bash
git fetch origin main
git switch -c rollback/six-star-balance origin/main
git revert a0903d5d403652c1e8543ff4253627bff51915cb
```

反向应用英雄平衡差异已在隔离索引中验证，得到的文件树与基线完全一致。回退时保留基线中的新版对抗四属性公式。
