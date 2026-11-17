# 公会 AI 社交系统设计（2026-11-17，待确认）

目标：把单机版公会从原型做成能玩的系统。玩家可以自己建公会；一批 AI 玩家有持久档案，会随游戏时间成长、有性格，会申请入会、退会，也会自己组建公会；公会里的 NPC 会捐献、膜拜、打 Boss、聊天；聊天可以接入大模型。

本文先确认方案，确认后再写实现。下文的“现状”都以 origin/main（PR #38 之后）的代码为依据。

---

## 1. 现状

| 模块 | 现状 | 问题 |
|---|---|---|
| `server/gameplay_guild_boss.py` `_guild(create=True)` | 建会时插入 6 个写死名字的成员（`npc-{gid}-1..6`，名字是“守望者/远征者…”），贡献和战力都是固定值 | 这些成员永远不变，也不在 `guild_companions` 里，不能助战、不能加好友 |
| `_guild_suggestions` | 3 个写死的“（NPC）”公会，ID 10001–10003 | 申请写进 `records.guild_applications` 后就一直是 pending，永远不会被处理；`join_type==2` 时“加入”其实是把玩家自己设成会长（`association_lv:0`），并且复用了 `_guild(p,True)` 的建会逻辑 |
| `server/guild_companions.py` | 玩家当会长时，每个游戏小时重新生成 10 个申请人，战力取玩家队伍战力的 30%；已入会的成员每小时被覆盖名字/等级/战力 | 每小时整批换人，没有身份延续；入会后 `contribute` 一直是 0，什么都不做 |
| `_show_war_data` / `_get_war_rank` / `_get_fight_result` / `_get_reward_data` | 返回空 | 公会战是空壳 |
| `_inspire_association_race` | 直接报“暂未开放” | — |
| `_association_rank_index` | 返回那 3 个写死的公会 | 排行没有意义 |
| Boss（`_boss_state`） | 状态存在 `p.boss_state.guild_boss`，伤害排行只有玩家一个人 | 公会 Boss 实际上是单人 Boss |
| 聊天 | 客户端 `PanelChatRoom` 第 4 个页签是公会频道，发送走 `user.chat_guild`，接收靠 `SocketManager.setMsg` 推送；服务端**没有实现任何 chat_* 方法** | 公会聊天在单机版完全不能用 |
| `server/gameplay_social.py` | 12 个固定好友 bot + Mod bot + 已入会的公会伙伴；`_dynamic_bot` 通过 `GuildCompanions.find` 找伙伴 | 可以沿用 |

存档注意点：
- 玩家档案是 `players.profile` 里的一个 JSON。`guild_companions` 不在 `CLIENT_PROFILE_SYNC_*_FIELDS` 里，只存在服务端，不会同步到客户端。新增的世界状态也按这个方式处理。
- 存档有 10 MiB 的总预算（`docs/lightweight-saves-20261113.md`），每次 `atomic_update` 都会重写整个 profile JSON。所以世界状态要控制体积，聊天记录不放进 profile。

---

## 2. AI 玩家（下文简称“AI”）

### 2.1 数量与身份
- 每个存档有一个固定的 AI 池，默认 **36 人**（可配置）。每个 AI 的 UID 固定，名字一旦生成不再改变。
- UID 沿用 `930000000000 + owner*100 + n` 这个号段（`GuildCompanions.uid`），不和 `BOT_UID_START=92000000` 的好友 bot 冲突。旧伙伴占用的序号是 1–10，新 AI 从 11 开始编号。
- 名字仍然用 `bot_name_for_uid`。如果撞名，就换种子重抽，保证同一存档内名字不重复。

### 2.2 持久档案（存在 `profile.guild_world.agents[uid]`）
```
uid, name, created_hour,
personality: {archetype, activity, generosity, loyalty, ambition, chattiness}  # 0–100 的整数
growth: {talent, days_active, lv, power, power_ratio}
guild_id | null, rank(0/1/3), joined_hour, contribute, last_seen_hour,
mood: 0–100, memory: [最多 6 条短事件，例如 "被会长踢出" "Boss 首杀"]
```
- **性格原型**（archetype）决定模板文本、给大模型的人设，以及各项数值的分布。暂定 6 种：热血冲榜、佛系养老、话痨、老练军师、冷淡独狼、新手萌新。
- **成长**：不会从零开始自己“打”一遍。AI 的战力 = 玩家参考战力 × `power_ratio`。
  - 玩家参考战力：每个游戏日按玩家当前队伍战力（`GuildCompanions._player_power`）做平滑，取 `ref = max(ref*0.8 + now*0.2, 历史最高*0.6)`。这样玩家临时调整阵容时，AI 战力不会跟着大幅跳动。
  - `power_ratio`：初始值 0.2–0.5，此后每个**活跃日**按 `talent` 增加 0.01–0.03，上限由 talent 决定，在 0.6–1.3 之间。少数高天赋 AI 最终会比玩家强，这样才有追赶感。
  - 等级：`lv` 按活跃天数增长，上限是玩家等级 +5。
  - 英雄阵容与助战卡：**调用另一会话正在做的 `server/npc_cultivation.py`**（按羁绊选英雄，属性来自真实装备/天赋/培养/德诺/公会研究，再缩放到目标战力），本方案不另写属性缩放。该模块合入前，暂时沿用 `GuildCompanions._hero`。结果缓存在 agent 上，参考战力变化超过 5% 才重新生成。
  - AI 通过 `GuildCompanions.find` 暴露给好友/助战流程（现有接口），**不修改 `gameplay_social.py` / `bot_names.py`**；它们由另一会话负责（好友 bot 会主动加好友）。
- **活跃**：`activity` 决定每个游戏小时“上线”的概率。时间以 `store.clock.now()` 为准，所以调时间（`advance`）也会推动 AI 世界。

### 2.3 AI 公会（存在 `profile.guild_world.guilds[gid]`）
- 初始时有 3 个 AI 公会，**沿用 10001–10003 这三个 ID 和原来的名字**（去掉“（NPC）”后缀），会长和成员从 AI 池里分配。这样旧存档里 `records.guild_applications` 中的 pending 申请仍然有效。
- 组建新公会：没有公会的 AI 如果 `ambition≥70`、等级≥30，且已经连续 3 个活跃日没进公会，有一定概率建会。名字从模板词库生成，全世界最多 8 个公会。
- 解散：成员少于 3 人并且持续 3 天，公会就会解散，成员变回自由身。
- 列表、搜索、排行榜（`get_association_list` / `find_association` / `association_rank_index`）都改为返回真实的 AI 公会和玩家公会，按繁荣度排序。`ItemGuild` 需要的字段保持不变。

### 2.4 入会、退会
- **AI 申请玩家公会**：替换现在“每小时 10 个”的机制。每个游戏小时，没有公会的 AI 按 `activity` 判断是否行动，再按“公会等级 + 繁荣度 + 会长战力”和自身性格算出偏好，向偏好最高的公会申请。玩家公会每天收到大约 0–4 个申请，申请会保留 24 小时。拒绝后 72 小时内这个 AI 不会再来申请（现在是 1 小时）。
- **玩家申请 AI 公会**：`join_type==1` 的公会在下一个 tick 由会长 AI 审批，按玩家战力和公会门槛判断，结果写入公会日志，并且能在“申请列表”看到。`join_type==2` 的公会直接加入，**玩家以普通成员身份（association_lv 3）加入**，修掉现在“加入即当会长”的问题。
- **AI 退会**：`mood` 低（长期不活跃的公会、被降职、玩家公会连续几天没人捐献）并且 `loyalty` 低时，AI 可能退会，会写日志并发一条聊天。会长 AI 不会主动退会。
- **被踢**：沿用 `_modify_association(num=-1)`。被踢的 AI 会记住这件事（写入 memory），之后 7 天不再申请这个公会。

### 2.5 旧存档迁移（只增加数据，不删除）
1. `guild_world` 不存在时初始化，`version: 1`。
2. 已经在玩家公会里且 `guild_companion: true` 的成员：把对应的 `guild_companions.bots` 记录转成 AI 档案，**保留 UID、名字和当前战力**（据此反推 `power_ratio`），性格按 UID 种子随机生成。
3. 建会时写死的 `npc-{gid}-{n}` 成员：保留在成员列表里，标记为 `legacy_static`，不参与模拟。另外提供一个可选操作“替换为 AI 成员”，默认不执行，以免玩家已有的成员凭空消失。
4. `guild.applications` 里还在有效期内的伙伴申请保留；在 AI 池里找不到对应 AI 的申请就丢弃（它们本来每小时就会被刷新掉）。
5. 新建公会时不再插入 6 个写死的成员，改为从 AI 池里挑 2–3 个“开会元老”，并写入日志。

---

## 3. 公会内 AI 的实际行为

模拟在 guild / social 的 RPC 进入 `atomic_update` 时**按需推进**（和现在 `companions.refresh` 的时机一样），按游戏小时一步一步补算。一次最多补 **48 个 tick**，超出的部分合并成“离线期间摘要”，只结算每日行为。每个 tick 的随机数种子是 `(owner, uid, hour)`，同一个 tick 重放结果一致，测试也能复现。

| 行为 | 规则 | 对玩家的效果 |
|---|---|---|
| **捐献**（贡献兑换） | 每个游戏日，每个 AI 按 `generosity` 决定是否捐献、捐普通档还是高级档，使用 `guild_contribute_info.exchange_cost_info` 的配置 | 成员 `contribute` 增加，公会 `total_alive`（繁荣度）增加，公会会升级，商店和研究会解锁。日志：“XX 兑换公会贡献 N” |
| **公会供奉**（`guild_worship`） | 每日一次，按 `guild_worship` 选项和性格选择档位 | 繁荣度增加 |
| **膜拜成员**（`member_worship`） | 每个 AI 每天最多膜拜 1–2 个成员，优先膜拜战力高的人或会长。被膜拜时写入对方的 `worship_info.member_worship_user_list` | AI 膜拜玩家时，玩家的 `attrs.association_worship_gold` 增加（现有的“领取膜拜金币”接口就能领），**每日有上限**（建议 5 次 × 配置额） |
| **公会 Boss** | Boss 开放时间内（`_boss_window_open`），在线的 AI 会出手，伤害按自己的战力用和玩家相同的公式计算（`base_damage + power*damage_per_power`，受 cap 限制）。伤害进入 `rank_list` / `report_list` | 排行榜里会出现真实的公会成员。**AI 的总伤害每天最多打到 Boss 最大血量的 70%**，最后一击和击杀奖励留给玩家。待确认，见第 7 节 |
| **聊天** | 见第 4 节。触发时机：每天第一次上线问候、捐献或 Boss 之后、成员加入/退出、玩家在公会频道发言后 1–2 个 AI 回应、偶尔闲聊 | 公会频道和公会日志里都能看到 |
| **职位** | 玩家是会长时，AI 不会自己改职位。AI 当会长的公会，会长 AI 每周把贡献最高的成员任命为副会长 | — |

经济上的约束：AI 不会给玩家**直接发放**金币、钻石、道具。玩家能拿到的只有：①现有“膜拜金币”渠道的有限金币；②公会繁荣度提升后解锁的商店和研究。各项上限都放进配置 `guild_ai` 节，方便以后调整。

公会战和竞速鼓舞这一期**不做**，接口保持原样。不过排行榜会接入真实的公会数据，以后做公会战时可以直接拿 AI 公会当对手。

---

## 4. 聊天

### 4.1 存储
- 新建 SQLite 表 `guild_chat(owner_uid, id INTEGER PK, ts, channel, speaker_uid, speaker_name, text, source)`，和存档放在同一个数据库，用 `CREATE TABLE IF NOT EXISTS` 创建，旧存档不受影响。每个存档最多保留 200 条，多出的删掉最旧的。聊天记录不进 profile，所以不会让每次存档变大。
- `source` 取值为 `template`、`llm`、`player`，方便排查问题，也方便统计用了多少次大模型。

### 4.2 服务端接口
- `user.chat_guild {s}`：玩家在公会频道发言。服务端检查长度和字符集（与客户端 `chat_send_msg` 的正则一致），把消息入库，并安排 1–2 个 AI 回应。返回 `server_now`，这是客户端 `reFun3` 要读的字段。
- `user.get_chat_info` / `user.chat_record`：返回最近的公会聊天，格式与原版推送的消息对象一致（`method:"chat_guild"` 以及 `LOL_ChatItem` 需要的字段，实现时从 `LOL_ChatItem` 的反编译结果核对）。
- 其他 chat_* 方法（世界频道、私聊、黑名单）不在这次范围内，保持不实现。

### 4.3 客户端（最小改动，复用原版聊天面板）
原版靠 socket 推送消息，单机版没有 socket。打算在 `PanelChatRoom` 切到公会页签以及发送成功后，调一次 `user.chat_record`，把返回的每条消息 `SocketManager.setMsg` 进去，再 `set_msg_to_ScrollContainer(3)`。这和现有 `chat_private_record_backFun` 的做法相同。不新增界面，羊皮纸底上的文字仍然用 0x4B2C1B。
在客户端改完之前，服务端会同时把 AI 发言以“【聊天】XX：……”的形式写进公会日志，日志面板是原版现成的，这样不改客户端也能先看到效果。

### 4.4 模板文本（默认，离线可用）
- 6 种性格 × 约 15 种事件，每种 3–6 条模板，带 `{name}{boss}{damage}{guild}` 这类占位符。
- 选模板用确定性随机，同一个 AI 连续 10 条内不重复同一模板。
- 没有 Key、离线、大模型调用失败或超时时，都直接用模板，玩家看不出“坏了”。

---

## 5. 大模型接入

### 5.1 原则
- **只在服务端调用**，客户端不接触 Key。
- **不阻塞 RPC**：RPC 里只把请求放进队列，然后马上返回。后台线程负责调用 API，结果写进 `guild_ai_plan` 表，下一次公会请求时由执行器取用。计划是提前一个时间窗预取的，取不到（离线、超时、出错、超额）就用规则计划和模板，玩家不会等待网络。
- 后台线程使用自己的 SQLite 连接，只写 `guild_chat` 表，不修改 profile，所以不会和 `atomic_update` 抢锁，也不会改坏存档。

### 5.2 配置与 Key
- 配置文件 `llm.json` 放在数据库同一目录，也就是电脑端的 `server/`。`/server/*.sqlite*` 已经被忽略，另外在 `.gitignore` 里加上 `llm.json`。环境变量 `LAL_LLM_API_KEY` 可以覆盖文件里的 Key。
  ```json
  {"enabled": true, "provider": "<待定>", "base_url": "...", "model": "...",
   "api_key": "...", "max_calls_per_hour": 20, "max_tokens_per_day": 60000,
   "send_player_messages": true}
  ```
- 仓库里提交 `llm.example.json`，Key 留空。启动日志只打印“大模型：已启用/未配置”，不打印 Key。
- `send_player_messages=false` 时，只把事件摘要发给模型，玩家自己打的字不会发出去（隐私开关）。

### 5.3 一次调用做什么
- **批量**：一次调用生成一小段对话，包含 1–3 个 AI 的发言，按 JSON 输出 `[{uid, text}]`。不按每条消息单独调用。
- 提示词包含：公会名和等级、在场 AI 的人设摘要（性格原型和 memory 的前几条）、最近 8 条聊天、触发事件。不包含账号、设备、存档路径之类的信息。
- 输出处理：每条最多 40 个汉字；去掉链接和不在客户端字符集里的字符；说话人的 uid 必须在公会成员里；校验不通过就用模板替代。

### 5.4 限频与成本
- 每小时最多调用 `max_calls_per_hour` 次，默认 20；每天 token 数有上限，默认 60k（按 API 返回的 usage 累计，存在表 `llm_usage(day, calls, input_tokens, output_tokens)` 里）。超过上限的部分当天全部用模板。
- **只在玩家在线时调用**，即 5 分钟内有过 RPC。离线补算的那些 tick 一律用模板，避免玩家关游戏以后还在花钱。
- 玩家发言触发的回应排在最前面；闲聊和问候排在最后，配额紧张时先丢掉。
- 估算：每次输入大约 600–900 token、输出大约 150 token，默认上限下每天最多 2 万到 6 万 token。具体花多少钱取决于选哪家，选定后在文档里补上。

### 5.5 Android
- Android 版的服务端 Python 通过 Chaquopy 在设备上运行，`android-manager/app/src/main/AndroidManifest.xml` 已经声明了 `INTERNET` 权限。所以同一套 `urllib` HTTPS 调用可以直接用，不需要额外的依赖库。
- Key 的存放：写在 App 私有目录下的 `llm.json` 里，与存档同目录，`scripts/prepare_android_runtime.py` 不会把它打进安装包。管理器里加一个“大模型设置”页（填 Key、选模型、开关），由 Java 写这个文件。**这部分放到第三期**；在那之前 Android 默认只用模板，功能照常可用。
- 移动网络下的超时设为 8 秒，失败就用模板。导出存档时**不包含** `llm.json`，避免分享存档时把 Key 一起带出去。
- 国内网络问题：如果选的是境外服务，Android 上可能连不上，这一点会影响选哪家（见第 7 节）。

---

## 6. 实现拆分

| 期 | 内容 | 涉及文件 |
|---|---|---|
| 一 | `guild_world` 数据结构、AI 档案与成长、tick 补算、旧存档迁移；AI 公会、列表/排行、申请与审批（双向）、退会、建会；捐献、供奉、膜拜、Boss 参与；模板聊天写进公会日志；`user.chat_guild` / `chat_record` 服务端 | 新增 `server/guild_world.py`、`server/guild_chat.py`；修改 `gameplay_guild_boss.py`、`guild_companions.py`（变成兼容层）。不改 `gameplay_social.py`、`bot_names.py`、`arena_opponents.py`、`npc_cultivation.py` |
| 二 | 大模型适配器、后台线程、限频、`llm.json` | 新增 `server/llm_client.py`；`gateway.py` 启动时创建线程；`.gitignore`、`llm.example.json` |
| 三 | 前端：功能说明与无遮挡（见第 8 节）；公会聊天页签拉取记录；Android 管理器的大模型设置页 | `server/help_pages.py`、公会相关 `client/src/stages/*Guild*.as`、`018_PanelChatRoom.as`、`android-manager/` |

测试（`server/test_guild_world.py`，用内存 SQLite 和可以推进的游戏时钟）：
- 旧存档迁移：已入会的伙伴保留 UID、名字和战力；写死的成员不丢；pending 申请还在。
- 时间推进 N 天后：AI 等级和战力上升但不超过上限；捐献让公会繁荣度和等级上升；AI 的 Boss 伤害不超过 70%。
- 申请、拒绝冷却、踢人后的记忆、AI 退会、AI 建会和解散。
- 补算上限（离线 30 天只算 48 个 tick 外加摘要）；同一个 tick 重放结果一致。
- 大模型：用假的 HTTP 接口测试成功、超时、配额用完、输出不合法这几种情况，都能正确退回模板；没有 Key 时一次请求都不发。
- 现有的 `test_guild_companions.py`：其中“每小时 10 个申请人”的断言会随这次改动更新，其余断言（助战、好友邀请、审批权限）保持通过。

另一个会话正在修改的 `server/arena_opponents.py`，本方案不碰。

---

## 7. 需要你确认的问题

1. **用哪家大模型、哪个模型**（必须由你来定）。
   - Anthropic Claude（例如 Claude Haiku 5.5）：中文角色扮演质量好、价格低；但国内网络（尤其是 Android）可能需要代理。
   - 国内的 OpenAI 兼容接口（DeepSeek、通义千问、Kimi 等）：国内能直连，价格很低。
   - 本地 Ollama：完全离线、免费；但电脑需要显卡，Android 上用不了。
   - 我的建议：服务端做一个统一的适配层，同时支持“OpenAI 兼容协议”（可以覆盖 DeepSeek、通义、Kimi、Ollama）和“Anthropic 协议”，默认值由你来选。
2. AI 打公会 Boss 最多打到 70% 血量、把击杀留给玩家，这样可以吗？还是允许 AI 击杀、奖励按伤害比例分？
3. 建会时写死的 6 个成员：保留不动（默认），还是迁移时直接换成 AI 成员？
4. AI 池 36 人、每天 0–4 个申请、全世界最多 8 个公会，这个规模合适吗？
5. 是否同意把聊天记录放进独立的 SQLite 表（不进 profile）？

---

## 8. 前端：让公会功能更明确、页面无遮挡

需求原话：“前端修改 让竞技场和工会的功能更加明确 页面无遮挡”。本方案只负责公会部分，竞技场由另一会话处理。

### 8.1 功能说明（说清“做什么、得到什么”）
- 原版公会各面板的“？”按钮打开的是服务端 `server/help_pages.py` 提供的页面（`MainConfig` 里的 `guild_pvp/guild_shop/guild_boss/guild_research/guild_study.html`，以及 `guild`）。这是原版现成的说明入口，不用新做控件。
- 现在这些页面多是“以页面显示为准”，没有说清用途和收益。改为从配置读出实际数值后生成，例如：
  - 公会供奉：三档各自的消耗、增加的繁荣度、个人贡献、公会币；每日次数。
  - 膜拜成员：消耗、给自己回复多少体力；被别人（包括 AI）膜拜时攒下的膜拜金币，以及每日上限。
  - 贡献兑换：普通/高级各消耗什么、得多少贡献，VIP 对应的每日次数。
  - 公会 Boss：开放时段、免费次数、伤害档位奖励、击杀奖励、繁荣度；说明 AI 成员会一起出手，以及 AI 伤害上限。
  - 公会研究/学习/商店：解锁所需的公会等级、消耗的贡献、效果。
  - 公会战：明确写“暂未开放”，避免玩家以为点了没反应是 bug。
- 每个按钮的文字沿用原版语言表，不改按钮；只有说明不足的地方才在原版说明文字里补一句。
- 新增的 AI 行为（申请、退会、捐献、聊天）都写进原版的公会日志，玩家能看到“谁做了什么、公会得到了什么”。

### 8.2 无遮挡
- 逐个检查公会相关面板：公会列表、公会主页（成员页、日志页）、成员管理、申请列表、供奉、膜拜成员、贡献兑换（普通/高级）、商店、研究/学习/技能替换、Boss、鼓舞、聊天公会页签。
- 检查方法：在雷电模拟器里用 ADB 截图（`D:\leidian\LDPlayer9\adb.exe exec-out screencap -p`），不用 computer use。重点看长名字（AI 名字最长 6 个字加符号）、成员数多时的滚动列表、数值位数变大后的文字、弹窗与底部按钮是否互相盖住。
- 修复只调整位置、宽度、换行和滚动区域，复用原版控件（`LOL_Scale9Button` 等）。羊皮纸底上的文字用 0x4B2C1B。
- 每处修改前后各留一张截图，放在文档附录里作为验收依据。

---

## 9. 已确认的决定（2026-11-17）

1. **大模型**：不绑定厂商。服务端只实现 OpenAI 兼容的 `chat/completions` 协议，玩家自己填 `base_url`、`api_key`、`model`。默认值是 DeepSeek（`https://api.deepseek.com`，`deepseek-chat`），可以手动改。我们提供的是系统提示词和规范的结构化接口。
   - **低频、整批**：一次调用拿到“接下来一个时间窗（默认 6 个游戏小时）里所有 AI 的一整套操作”，包括聊天、捐献、供奉、膜拜、申请、退会、建会、打 Boss。不按单条消息调用。
   - 统一的计划结构：规则规划器（无 Key）和大模型规划器输出**同一种 JSON 计划**，由同一个执行器按游戏规则逐条校验后执行，非法操作直接丢弃。大模型只能“选择”做什么，不能越过次数、消耗、成员资格等规则。
   - 没有 Key 时：规则规划器照常推动 AI 的捐献、申请、Boss 等行为，聊天只用模板；**AI 回复玩家发言**这一项需要大模型，无 Key 时不可用（只在帮助页说明）。
   - 预取：进入第 W 个时间窗时，后台为 W+1 请求计划；玩家在公会频道发言后，最多每 10 分钟额外请求一次“回复计划”。默认每天最多 30 次调用。
2. **AI 打 Boss**：AI 当天的总伤害最多打到 Boss 最大血量的 70%，击杀留给玩家。
3. **建会时写死的 6 个成员**：完全重做。迁移时移除 `npc-{gid}-{n}` 成员，换成 AI 池里的真实 AI；新建公会也不再写死成员。
4. **规模**：AI 池 36 人，每天 0–4 个申请，全服最多 8 个公会。
   - **英雄池固定**：每个 AI 创建时确定一个 8–12 名英雄的固定池子（按羁绊挑选，由 `npc_cultivation` 负责，合入前用确定性随机）。
   - **卡变多、练度上升**：拥有的卡数随活跃天数从 3 张逐步增加到池子上限；练度和战力“一部分参考玩家进度、一部分按系统时间稳步上升”：
     `power = max(上次 power, 0.5 × 玩家参考战力 × ratio(talent) + 0.5 × 时间曲线(days, talent))`，只升不降。
5. **聊天记录**放独立 SQLite 表，不进 profile。

平衡补充：配置里公会等级的繁荣度门槛很低（1→10 级只需 10→80），AI 供奉增加的繁荣度按公会每天封顶（默认 6），避免公会一天升满。AI 膜拜玩家每次给玩家 50 膜拜金币，每天最多 5 次。

---

## 10. 实现状态（2026-11-17）

已完成：
- `server/guild_world.py`：AI 档案、成长、AI 公会、迁移、规则规划器、统一执行器、AI 打 Boss（剩余 30% 血量保底）、公会卡片与排行。
- `server/guild_llm.py`：`protocol` 一项设置切换适配器——`openai`（OpenAI 兼容 `chat/completions`，默认 DeepSeek `deepseek-chat`）或 `anthropic`（Messages API）；系统提示词、整窗结构化计划、玩家发言回复、后台线程、限频与 token 预算、计划校验。配置在存档同目录的 `llm.json`（不进仓库、不进 APK）或环境变量 `LAL_LLM_API_KEY / LAL_LLM_BASE_URL / LAL_LLM_MODEL / LAL_LLM_PROTOCOL / LAL_LLM_CONFIG`。无 Key 时用规则计划与模板台词。
- `server/guild_chat.py`：`guild_chat` 表、文本清洗（去链接、尖括号和客户端不支持的字符）、模板。
- `server/gameplay_guild_boss.py`：接入以上模块；新增 `user.chat_guild`、`user.chat_record`（`channel:"guild"`）；加入开放 AI 公会时是普通成员；离开后公会由 AI 接手，`over_association` 解散才释放成员；玩家打 Boss 改用当前选中的阵容（`attrs.team_num`）。
- `server/guild_companions.py`：改为卡片缓存与兼容层，不再每小时换人。
- `server/help_pages.py`：公会、商店、首领、学习页写明实际消耗、奖励、次数和 AI 成员规则（数值来自当前配置）。
- 客户端 `018_PanelChatRoom.as`：切到公会页签和发送后拉取 `user.chat_record`，去重后放入原版消息缓冲，用原版 `LOL_ChatItem` 显示；`t` 为秒、`zone` 用玩家的真实分区（`LOL_ChatItem` 会按分区查表）。增量编译通过。
- `llm.json` 修改后自动重新读取（按文件修改时间和大小判断），PC 改文件或手机改设置都不需要重启服务。
- Android 管理器首页新增“公会 AI 对话”入口（`GuildAiSettingsActivity`）：选择协议、填写服务器地址、模型和密钥，写入 `files/state/llm.json`（与存档同目录、不在存档备份里、应用更新后保留）。密钥输入框留空保存会保留原密钥，另有“清除密钥”。已用 `javac` 对照 `android.jar` 做类型检查；没有跑 Gradle 打包，也没在设备上验证。
- 测试：`server/test_guild_world.py`（21 项）、`server/test_guild_companions.py`（按新机制更新 5 项）。

尚未完成 / 未验证：
- 本机没有可用的模拟器镜像，以上客户端改动**未在设备上验证**；公会面板无遮挡只做了代码层面的尺寸核对（AI 名字 5 字、公会名不超过 8 字，在原版成员行和搜索卡片的宽度内；成员行不显示战力）。
- AI 英雄阵容改用 `server/npc_cultivation.py`（另一会话的分支，合并后接入）。
- 公会 Boss 没有真实战斗、第 1 阶段血量低于单次伤害上限，属于平衡问题，不在本次范围。
