# 测试分类与关联测试

日常改动只跑关联测试，不跑全量。全量（`server/` 下 `python -m unittest discover`）只在发版前跑一次。

## 用法

```powershell
. .\env.ps1            # 包目录下，准备 Python 与 Node
cd project
& $Python scripts/run_related_tests.py                      # 自动取工作区改动（相对 HEAD，含未暂存与新文件）
& $Python scripts/run_related_tests.py --base origin/main   # 整个分支相对 main 的改动
& $Python scripts/run_related_tests.py server/arena_raids.py client/src/stages/046_PanelCenterPVP.as
& $Python scripts/run_related_tests.py --category economy   # 跑整个分类
& $Python scripts/run_related_tests.py --list               # 查看分类和其中的测试
& $Python scripts/run_related_tests.py --dry-run            # 只列出会跑哪些测试
```

脚本会自动加上工具链里的 Python 依赖、`server/`、`scripts/` 和 Node 路径，所以客户端测试（`scripts/test_*.py`，需要 Node）也能直接跑。

## 怎么挑测试

对每个改动的文件：

1. 改的是测试文件：跑它自己。
2. 直接引用了这个文件的测试：Python 模块看 `import` / `from`，客户端源码、配置和脚本看路径或文件名。
3. 文件属于某个分类：加上该分类的测试。
4. 核心公共模块（`battle_engine`、`gameplay_roster`、`player_store`、`gateway`、`gameplay_common`、`mod_policy` 等）几乎被所有测试引用，只跑 `core` 分类里精选的那几个。要把直接引用它的测试也跑上，加 `--wide`。

## 分类

| 分类 | 覆盖内容 |
|---|---|
| core | 战斗引擎、阵容与属性、存档、网关等公共核心 |
| platform | 时钟、每日重置、存档压缩与保留、活动时间、打包 |
| arena | 竞技场、阵容分享、NPC 培养、前十来袭 |
| social | 好友 NPC、助战 |
| guild | 公会、公会 Boss、公会 AI |
| economy | 商店、充值、VIP、签到、冒险任务、召唤、兑换 |
| equipment | 装备、光环、附魔、星辉、技能书 |
| roster | 培养、预设、队长、德诺、橙卡升阶、羁绊 |
| combat | 战斗规则、技能、状态、持续伤害、伤害公式 |
| heroes | 英雄与皮肤的技能和数值 |
| pve | 主线、塔、远古试炼、资源本、掉落、探索 |
| abyss | 深渊回廊与遗物 |
| mod | Mod 系统 |
| ui | 通用界面、视口、提示 |

每个测试文件都必须属于某个分类。新增测试文件后运行 `--list` 检查；名字能被现有通配规则匹配上的会自动归类，匹配不上的就在 `scripts/run_related_tests.py` 的 `CATEGORIES` 里补一条。

`--list` 会列出未分类的测试并返回非零状态；`--base` 无效或 Git 查询失败时也会明确报错，不会把失败当成“没有改动”。
