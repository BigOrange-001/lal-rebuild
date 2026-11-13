package com.lal.rebuild.manager;

/**
 * Every user-visible string the manager shows, as ordinary Java constants.
 *
 * <p>These used to be {@code R.string.*} entries in {@code res/values/strings.xml}.
 * The merged APK keeps the AIR client's single resource table untouched, so this
 * module must contribute no resources at all — see {@code build/merged/} and the
 * empty {@code dependencies} block in {@code app/build.gradle}. Format strings
 * keep their {@code %}-placeholders and are fed to {@link String#format} exactly
 * as {@code getString(id, args)} used to feed them.
 *
 * <p>{@code android.R.string.ok} and {@code android.R.string.cancel} are
 * <em>framework</em> resources and stay referenced directly at their call sites;
 * they do not live in our table.
 */
final class ManagerStrings {

    private ManagerStrings() {
    }

    static final String app_name = "撸啊撸 管理器";

    // ---------------------------------------------------------------- notification
    static final String notif_channel_name = "游戏服务器";
    static final String notif_channel_desc = "保持本地游戏服务器运行，供游戏客户端连接";
    static final String notif_title = "游戏服务器运行中";
    static final String notif_action_save = "保存";
    static final String notif_action_stop = "停止";
    static final String notif_text = "127.0.0.1:8080 · 纯离线";

    // ---------------------------------------------------------------- server state
    static final String state_stopped = "服务器未运行";
    static final String state_starting = "正在启动…";
    static final String state_running = "服务器运行中";
    static final String state_stopping = "正在停止…";
    static final String state_failed = "服务器启动失败";
    static final String state_detail_idle = "点击下方按钮启动";

    // ---------------------------------------------------------------- actions
    static final String action_start_server = "打开本地服务端";
    static final String action_stop_server = "关闭本地服务端";
    static final String action_launch_game = "打开游戏客户端";

    // ---------------------------------------------------------------- saves
    static final String action_backups = "备份与回档";
    static final String section_saves = "存档";
    static final String action_autosave = "自动存档";
    static final String autosave_hint = "每5分钟及停止时备份，最多5份；当前进度与自动备份合计10 MB，相同内容不重复保存";
    static final String action_save_now = "立即保存存档";
    static final String action_import = "从文件导入";
    static final String action_prune = "清理旧存档";

    static final String section_snapshot_list = "存档列表";
    static final String saves_empty = "暂无存档。";

    static final String section_log = "运行日志";
    static final String log_empty = "（暂无输出）";

    static final String footer_note =
            "服务器只监听本机 127.0.0.1，不联网。导出存档后即使卸载重装也能恢复进度。";

    static final String action_restore = "恢复";
    static final String action_export = "导出";
    static final String action_delete = "删除";
    static final String action_reset = "重开";

    static final String kind_auto = "自动";
    static final String kind_manual = "手动";
    static final String kind_imported = "导入";
    static final String kind_live = "当前进度";

    // ---------------------------------------------------------------- confirmations
    static final String confirm_restore_title = "恢复存档";
    static final String confirm_restore_msg =
            "当前进度将被此存档覆盖。恢复前会自动保留一份当前进度。确定继续吗？";
    static final String confirm_delete_title = "删除存档";
    static final String confirm_delete_msg = "此操作无法撤销，确定删除该存档吗？";
    static final String confirm_prune_title = "清理旧存档";
    static final String confirm_prune_msg = "压缩并清理最旧的自动备份，最多保留5份，当前进度与自动备份合计不超过10 MB。手动和导入存档保留。确定继续吗？";
    static final String confirm_reset_title = "重开游戏";
    static final String confirm_reset_msg =
            "当前进度将被清空，重新进入游戏后会从零开始。已有的存档列表不会受影响，之后仍可恢复。确定重开吗？";

    // ---------------------------------------------------------------- toasts
    static final String toast_saved = "存档已保存";
    static final String toast_restored = "存档已恢复，请重新进入游戏";
    static final String toast_deleted = "存档已删除";
    static final String toast_exported = "存档已导出";
    static final String toast_imported = "存档已导入";
    static final String toast_reset = "已重开，请重新进入游戏";
    static final String toast_game_missing = "未找到游戏客户端，请先安装 lal-rebuild 客户端";
    static final String toast_server_needed = "请先启动服务器";

    // ---------------------------------------------------------------- home page
    static final String home_title = "撸啊撸";
    static final String home_subtitle = "离线版 · 单机运行";
    static final String home_play = "进入游戏";
    static final String home_play_desc = "启动游戏客户端";
    static final String home_manager = "本地服务与存档";
    static final String home_manager_desc = "本地服务、备份回档、命令行控制台";
}
