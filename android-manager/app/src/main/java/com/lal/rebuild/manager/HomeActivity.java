package com.lal.rebuild.manager;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Intent;
import android.content.Context;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

/**
 * The merged APK's only launcher entry: two buttons, one for the game and one
 * for the manager pages.
 *
 * <p>The game entry starts the local service and waits for gateway readiness.
 * The
 * AIR client's own entry point keeps every attribute it had — it is still the
 * activity that loads {@code MainLLOL.swf} — but its {@code MAIN}/{@code LAUNCHER}
 * filter moved here, so the merged app presents a single launcher icon and the
 * player picks a destination from inside.
 */
public class HomeActivity extends Activity implements ServiceConnection {

    /** The AIR client's entry point, named by string because its class is in the other dex. */
    private static final String GAME_ACTIVITY = "air.com.meng52.lol.android.AIRAppEntry";
    private final Handler main = new Handler(Looper.getMainLooper());
    private ServerService service;
    private boolean bound;
    private boolean active;
    private boolean waitingForServer;
    private int previousAttempt;
    private View playEntry;
    private TextView startupStatus;
    private final Runnable startupObserver = this::checkStartup;
    private final Runnable startupTimeout = () -> failStartup("准备游戏时间较长，请稍后重试。");

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        waitingForServer = savedInstanceState != null && savedInstanceState.getBoolean("enter-game-pending", false);
        setContentView(buildContent());
        renderStartup();
    }

    @Override protected void onSaveInstanceState(Bundle state) {
        state.putBoolean("enter-game-pending", waitingForServer);
        super.onSaveInstanceState(state);
    }

    @Override protected void onStart() {
        super.onStart();
        active = true;
        bound = bindService(new Intent(this, ServerService.class), this, Context.BIND_AUTO_CREATE);
        if (!bound && waitingForServer) failStartup("本地服务暂时无法启动，请重试。");
        if (waitingForServer) armStartupTimeout();
    }

    @Override protected void onStop() {
        active = false;
        main.removeCallbacks(startupTimeout);
        if (service != null) service.removeObserver(startupObserver);
        service = null;
        if (bound) { unbindService(this); bound = false; }
        super.onStop();
    }

    @Override public void onServiceConnected(ComponentName name, IBinder binder) {
        if (!active) return;
        service = ((ServerService.LocalBinder) binder).service();
        service.addObserver(startupObserver);
        if (waitingForServer) beginStartup();
    }

    @Override public void onServiceDisconnected(ComponentName name) { service = null; }

    private ScrollView buildContent() {
        ScrollView scroll = new ScrollView(this);
        scroll.setBackgroundColor(Ui.BG);
        scroll.setFillViewport(true);

        LinearLayout root = Ui.column(this);
        int pad = Ui.dp(this, 20);
        root.setPadding(pad, pad, pad, pad);
        ProjectNotice.attach(this, root);

        TextView title = new TextView(this);
        title.setText(ManagerStrings.home_title);
        title.setTextColor(Ui.TEXT_PRIMARY);
        title.setTextSize(android.util.TypedValue.COMPLEX_UNIT_SP, 26f);
        title.setTypeface(title.getTypeface(), android.graphics.Typeface.BOLD);
        root.addView(title);

        TextView subtitle = Ui.meta(this, ManagerStrings.home_subtitle);
        Ui.topMargin(subtitle, 4f, this);
        root.addView(subtitle);

        playEntry = entry(
                ManagerStrings.home_play,
                "自动准备本地服务，就绪后进入游戏",
                view -> launchGame());
        root.addView(playEntry);
        startupStatus = Ui.meta(this, "正在准备游戏…");
        startupStatus.setVisibility(View.GONE);
        root.addView(startupStatus);

        root.addView(entry(
                ManagerStrings.home_manager,
                ManagerStrings.home_manager_desc,
                view -> startActivity(new Intent(this, MainActivity.class))));

        TextView note = Ui.meta(this, ManagerStrings.footer_note);
        Ui.topMargin(note, 24f, this);
        root.addView(note);

        scroll.addView(root);
        return scroll;
    }

    /** Start once, then enter only after the actual gateway-ready callback. */
    private void launchGame() {
        if (waitingForServer) return;
        waitingForServer = true;
        renderStartup();
        armStartupTimeout();
        if (service != null) beginStartup();
        else if (!bound) failStartup("本地服务暂时无法启动，请重试。");
    }

    private void beginStartup() {
        // Ignore a failure left over from a previous attempt. If the service is
        // already starting, its eventual result belongs to this request too.
        previousAttempt = service.startupAttempt()
                - (ServerService.PHASE_STARTING.equals(service.phase()) ? 1 : 0);
        if (ServerService.PHASE_RUNNING.equals(service.phase()) || ServerService.PHASE_STARTING.equals(service.phase())) {
            checkStartup();
        } else {
            requestStartup();
        }
    }

    private void requestStartup() {
        try { ServerService.request(this, ServerService.ACTION_START); }
        catch (RuntimeException error) { failStartup("本地服务暂时无法启动，请重试。"); }
    }

    private void checkStartup() {
        if (!active || !waitingForServer || service == null) return;
        String phase = service.phase();
        if (ServerService.PHASE_RUNNING.equals(phase)) {
            waitingForServer = false;
            main.removeCallbacks(startupTimeout);
            renderStartup();
            openGame();
        } else if (ServerService.PHASE_FAILED.equals(phase) && service.startupAttempt() > previousAttempt) {
            failStartup("本地服务启动失败，点击“进入游戏”重试，或到管理器查看详情。");
        } else if (ServerService.PHASE_STOPPED.equals(phase)) {
            // An earlier stop may have been completing when Play was pressed.
            requestStartup();
        }
    }

    private void armStartupTimeout() {
        main.removeCallbacks(startupTimeout);
        main.postDelayed(startupTimeout, 120_000L);
    }

    private void renderStartup() {
        playEntry.setEnabled(!waitingForServer);
        startupStatus.setVisibility(waitingForServer ? View.VISIBLE : View.GONE);
        if (waitingForServer) startupStatus.setText("正在准备游戏…");
    }

    private void failStartup(String message) {
        if (!waitingForServer) return;
        waitingForServer = false;
        main.removeCallbacks(startupTimeout);
        renderStartup();
        startupStatus.setText(message);
        startupStatus.setVisibility(View.VISIBLE);
    }

    private void openGame() {
        Intent intent = new Intent()
                .setComponent(new ComponentName(this, GAME_ACTIVITY))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        startActivity(intent);
    }

    /** One tappable card: a bold title with a one-line description under it. */
    private LinearLayout entry(String name, String description, ViewGroup.OnClickListener tap) {
        LinearLayout card = Ui.card(this, Ui.SURFACE, 14f);
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        params.topMargin = Ui.dp(this, 16);
        card.setLayoutParams(params);
        card.setMinimumHeight(Ui.dp(this, 76));
        card.setGravity(Gravity.CENTER_VERTICAL);
        card.setClickable(true);
        card.setFocusable(true);

        TextView label = Ui.body(this, name);
        label.setTextSize(android.util.TypedValue.COMPLEX_UNIT_SP, 18f);
        label.setTypeface(label.getTypeface(), android.graphics.Typeface.BOLD);
        card.addView(label);

        TextView hint = Ui.meta(this, description);
        Ui.topMargin(hint, 3f, this);
        card.addView(hint);

        card.setOnClickListener(tap);
        return card;
    }
}
