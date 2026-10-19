# Mod API 1：接口与持久化契约

作者字段、动作和配额见 `mod-authoring.md`、`schemas/mod-engine-api-v1.json`。这里描述当前服务端与 AIR 客户端使用的接口。真实平台验证状态以实施验收记录为准。

## 鉴权与配置绑定

Mod 业务沿用 `/gateway/` 的 AMF 请求：顶层 `method`、`uid`、`sessionid`，`params` 内必须有非空 `actionID`。参数中的存档名或包路径不能代替会话鉴权。服务端通过 UID 选择独立配置与玩法处理器，不临时修改共享基础字典。

登录响应增加 `data.mod_config`。内容包含 `uid`、存档 Mod `revision`、有效 `digest`、完整 `config`、`cfg`、`mod_runtime` 和素材 `assets`。客户端在构造英雄前清理上个账号配置、应用当前配置并完成素材预载。异步响应必须同时匹配当前账号和修订上下文。

对于存在 Mod 上下文的存档，普通玩法请求顶层附带 `mod_digest`。摘要不符返回 `ModConfigurationChanged`，要求重新进入；包括全部补丁被暂停、最终已回退基础配置的情况。Mod 管理／配置同步接口允许在该错误后恢复。没有 Mod 元数据的旧存档仍使用原业务流程。

## RPC

| 方法 | 参数与结果 | 持久化语义 |
| --- | --- | --- |
| `user.mods_info` | 当前存档 `revision`、`digest`、`selections`，安装包与英雄、渠道／范围描述、缺失和错误 | 查询；目录检查只导入全局可用包，不启用存档。 |
| `user.mods_plan` | `expectedRevision`、完整 `selections`；返回 `valid`、`planDigest`、`errors`、`warnings`、`changes`、`details`、候选有效摘要 | 不修改存档；验证依赖、冲突、资源、身份、养成和未结算操作。 |
| `user.mods_apply` | 相同选择、`expectedRevision`、`planDigest`、稳定 `requestId` | 事务内重算计划，校验存档修订和目录指纹，写入活动清单、已知身份与映射；返回新 `revision`、`digest`、`reloginRequired:true`、`replayed`。 |
| `user.mods_config` | 无额外参数 | 返回当前 UID 的有效配置与资源索引；不会发放英雄。 |
| `user.mods_reclaim_equipment` | `heroId`（实际英雄实例 ID）、`requestId` | 只允许缺失英雄；解除普通装备及相应共享位置装备归属。原装备本来就在 `my_equips` 中，不新建物品。返回 `recovered`、`remaining`、`affectedSlots`、`as_equips`。 |
| `user.mods_test_grant` | 当前启用的新增英雄 `aid`、`count:1..10`、`requestId` | 显式测试获取；通过既有奖励和容量校验，在操作账本中去重，不伴随普通安装自动执行。 |
| `user.mods_uninstall_plan` | `packageId`、`version`、`contentDigest` | 返回依赖的存档数量 `affectedSaves`、未结算阻塞项及 `planDigest`；不删除文件。 |
| `user.mods_uninstall` | 相同包选择、`planDigest`、`actionID` | 重新检查所有受影响存档和指纹后删除活动安装文件，保留身份及元数据；操作账本去重。所有存档随后重新解析。 |
| `user.mods_backup` | 无额外参数获取当前状态；`previous:true` 获取上一次应用／恢复前自动保存的状态 | 返回 `lal-mod-backup-v1` 对象及完整性摘要。它是 Mod 元数据备份，不包含整个玩家进度或包文件；没有上一份时返回 `ModBackupUnavailable`。 |
| `user.mods_restore_plan` | `backup` | 验证备份摘要、选择、已知英雄、身份／系列一致性及现有号段冲突；在隔离内存注册表上试编译，不分配磁盘编号。返回 `planDigest`、警告和候选摘要。 |
| `user.mods_restore` | 同一 `backup`、`planDigest`、`requestId` | 重验计划后保留永久身份，写入新存档 Mod 修订；缺少活动文件的内容仍缺失；不发卡、不自动导入备份素材。 |

`requestId` 可省略而沿用 `actionID`，重试必须保留相同请求编号和载荷。编号复用于不同载荷返回既有 `RequestKeyConflict`。计划摘要同时绑定 UID、存档 Mod 修订、玩家状态修订、包内容和目录状态；预览后任何相关变化都要求重新预览。保存成功不意味着客户端已同步；收到配置并预载资源后才可进入玩法。

## 选择项格式

```json
{
  "packageId": "11111111-1111-4111-8111-111111111111",
  "version": "1.0.0",
  "contentDigest": "64位小写SHA-256",
  "enabled": true,
  "channels": {"acquisition.summon.normal": false},
  "patchScopes": {"arenaEnemy": false},
  "heroes": {
    "builtin:avatar/A_1001_5": {
      "channels": {"appearance.arena_enemy": false},
      "patchScopes": {"owned": true}
    }
  }
}
```

服务端内部存成 `digest`，线上也返回同值 `contentDigest`；同时提供两个字段时必须相同。一个存档同一包只能锁定一个版本。`heroes` 的首选键是永久身份，新英雄为 `mod:<UUID>/hero/<id>/<variant>`，补丁目标为精确目标引用；错误、未知的覆盖目标会被拒绝。

显示值与原始默认值分别保存。包行的 `defaultChannels` 是引擎默认加作者包默认，`defaultPatchScopes` 是原始范围默认；英雄行再叠加对应实体默认。它们不包含玩家设置。`channels` 是当前有效值，`channelSupport[key]` 提供 `supported`、`applicable`、`reason`。玩家的单英雄覆盖优先于包覆盖；内容不完整和渠道不适用优先于任何勾选。管理页恢复默认应清除覆盖，不能把一次解析后的有效值写成永久默认。

## 素材与本地安装 HTTP

`POST /mods/install` 接收完整 `.heropack` 二进制，`Content-Type: application/octet-stream`，明确 `Content-Length`，最大 64 MiB；使用 `X-Lal-Uid` 和 `X-Lal-Session` 鉴权。服务端先验证会话再读取大包，写入受限暂存文件，校验后原子安装。鉴权失败使用 HTTP 401；已鉴权请求的业务校验失败使用 HTTP 200 和 JSON `{ok:false,error:{code,message}}`，让 AIR 能读取具体错误正文。成功为 HTTP 200 和 `{ok:true,package:{...}}`。客户端必须检查 `ok`，不能仅按 HTTP 200 判断安装成功，也不能通过该接口指定磁盘目的路径。

`GET /mods/assets/<contentDigest>/<相对路径>` 只返回当前已安装、摘要与完整性仍正确的已声明图像或声音。路径解码后再检查；不接受目录穿越、任意文件或卸载内容。安装的 Mod 媒体属于本地游戏公开内容，该只读端点不携带账号数据。

`mod_runtime.assets` 每项包含 `alias`、`kind:image|sound`、`role`、`contentDigest`、包内 `path`、`sha256`、`packageId`、`version`、`bytes`；图像另含 `width`、`height`。客户端先做合计内存检查，再加载并验证，失败阻止混用定义进入游戏。`textureAliases` 将未自带的图像映射到内置纹理，编译器预先展平引用链。

## 持久目录和备份

服务端 `--mods-root <目录>` 可显式指定统一安装位置。默认使用 SQLite 数据库所在目录的 `mods/`。便携 Windows 启动器明确采用游戏包的 `data/mods/`，与 `data/local.sqlite3` 同属持久内容，源码和运行时更新不应删除它们。

目录包含 `inbox/`、`packages/<UUID>/<version>/<digest>/`、`staging/`、`registry.json` 和跨进程 `registry.lock`。`packages` 是唯一活动内容来源。目录导入按同一校验器安装，原始 inbox 文件可保留；相同文件重复检查去重，不重复注册或发奖。

Android 的文件选择使用 AIR 的平台选择器，选中的包通过同一本地宿主 HTTP 接口上传，不需要玩家查找应用私有绝对路径。Android 宿主应将 SQLite 和 `--mods-root` 指向应用专属持久目录，而非会随更新替换的运行时目录；具体设备路径由宿主决定。本仓库的接口和客户端构建不能代替 Android 实机导入、播放与恢复验收。

每个玩家 `profile.mod_state` 包含 `schema:lal-mod-save-v1`、Mod 修订、锁定版本／摘要的 `selections`、`knownHeroes`、身份 `identityMap` 和有效摘要。玩家明确取消项保留到更新后。缺失英雄只从本存档已知身份生成，不从其他账号或全局注册表新增占位。

每次成功应用或恢复配置，在同一玩家事务中将先前 Mod 状态保存为 `mod_state.previous`。只保留单份，生成时去除旧 `previous`，避免备份递归增长；失败事务或相同幂等请求重试不重复推进历史。可用 `user.mods_backup {previous:true}` 取出，再交给现有恢复预览与恢复接口。这个回退不撤销后来获得的卡牌、装备、货币或其他玩家进度。

恢复 SQLite 时，服务启动先恢复各存档记录的身份绑定，再扫描安装包；这避免空的新设备注册表先分配错误编号。映射冲突的存档冻结其 Mod 并报告迁移错误，其他存档不被替换。手动恢复先在内存中校验与试编译，再发布映射及存档状态；号码冲突明确阻止，不能部分改写现有英雄引用。

## 失败与恢复

新设置校验失败保留当前活动方案；活动文件被外部删除时则重新构建降级方案。一个补丁任一作用域失败会暂停整包及其依赖链，从基础重新编译，不保留局部成功。新增身份保留缺失占位；补丁卸载回退。缺失不是战斗胜利或清空付费结果的理由。

`ModRevisionConflict`、`ModPlanExpired` 要求刷新预览；`ModPendingOperation` 要求先完成未结算内容；`ModConfigurationChanged` 要求配置同步；`ModPatchConflict`／`ModTargetMismatch` 要求修正补丁组合或兼容合同；`ModMissingPackage`／`ModMissingDependency` 要求补回固定内容；`ModMigrationRequired`／`ModIdentityMigrationRequired` 要求完整身份或进度迁移；`ModRegistryCorrupt` 保留原注册表并阻止新分配，不能重建空号表蒙混恢复。具体路径和原因显示在管理页，不统一改成网络错误。

## 作者工具与服务端 Python API

`scripts/mod_tools.py` 提供 `template new|patch|data-patch`、`pack`、`validate`、`install`、`list`、`uninstall`、`target-digest`、`fork` 和 `capabilities`；命令示例与作者字段见 `mod-authoring.md`。这些命令不直接写玩家数据库。

`ModCatalog(root,base_document)` 提供 `scan()`、`import_inbox()`、`install(path)`、`uninstall(id,version,digest)`、`get(id,version,digest)`、`resolve_digest_asset(digest,path)`、`identity_snapshot()`、`validate_identity_snapshot(snapshot)`、`restore_identities(snapshot)` 和 `preview_restore(snapshot,base,settings,roster_side,allow_missing)`。`compile(base,settings,roster_side,allow_missing)` 返回 `CompiledModConfig.document/roster/runtime/digest/preview/warnings`。

目录变更和编号分配使用注册表原子发布与 Windows 字节锁／POSIX 文件锁，同一根目录同线程可重入。内存恢复预览完全覆盖磁盘写入方法，不占用或泄漏编号。包安装与 SQLite 不能组成同一个数据库事务，重启时依靠已发布清单重新验证和登记；玩家存档激活及奖励继续由既有事务／操作账本保护。


## 待测试的效果序列扩展

本轮增加 `skill.effect-sequence.v1` 和 `unit.summon.v1`。新旧模型并存，详情见 [条件与召唤物接口](mod-effect-sequence.md)。尚未运行测试、构建游戏安装包或合并。
