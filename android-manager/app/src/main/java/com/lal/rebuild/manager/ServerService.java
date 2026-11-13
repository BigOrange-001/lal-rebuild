package com.lal.rebuild.manager;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.os.Binder;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.os.PowerManager;
import android.util.Log;

import org.json.JSONObject;

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * Keeps the bundled server running in the foreground so the companion client
 * can connect to it at any time.
 *
 * <p>The service owns three pieces of mutable state — the run phase, the last
 * status payload and the log tail — and publishes every change to the activity
 * through {@link #ACTION_STATE}. That broadcast is used instead of a binding
 * callback because the activity may be recreated at any moment and the state
 * must survive it.
 */
public class ServerService extends Service implements PythonBridge.Events {

    /** Broadcast carrying {@link #EXTRA_PHASE} and friends. */
    static final String ACTION_STATE = "com.lal.rebuild.manager.STATE";

    static final String EXTRA_PHASE = "phase";
    static final String EXTRA_DETAIL = "detail";
    static final String EXTRA_STATS = "stats";
    static final String EXTRA_LOG = "log";

    static final String PHASE_STOPPED = "stopped";
    static final String PHASE_STARTING = "starting";
    static final String PHASE_RUNNING = "running";
    static final String PHASE_STOPPING = "stopping";
    static final String PHASE_FAILED = "failed";

    static final String ACTION_START = "com.lal.rebuild.manager.START";
    static final String ACTION_STOP = "com.lal.rebuild.manager.STOP";
    static final String ACTION_TOGGLE = "com.lal.rebuild.manager.TOGGLE";
    static final String ACTION_SAVE = "com.lal.rebuild.manager.SAVE";

    /**
     * Starts the service as a <em>started</em> foreground service rather than
     * leaving it purely bound.
     *
     * <p>This distinction is what keeps the server alive when the player leaves
     * the manager to play the game. A bound-only service is destroyed the
     * moment its last client unbinds — and the activity unbinds in
     * {@code onStop()} — so {@code onDestroy()} would run
     * {@code worker.shutdownNow()} and kill the Python server underneath the
     * running game. Being "started" gives the service a lifetime independent of
     * any activity.
     */
    static void request(Context context, String action) {
        Intent intent = new Intent(context, ServerService.class).setAction(action);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(intent);
        } else {
            context.startService(intent);
        }
    }

    /** Sent by the activity when the autosave switch moves. */
    static final String ACTION_PREFERENCE = "com.lal.rebuild.manager.PREFERENCE";
    static final String EXTRA_AUTOSAVE = "enabled";

    private static final String TAG = "ServerService";
    private static final String CHANNEL_ID = "lal-server";
    private static final int NOTIFICATION_ID = 1001;
    private static final int PORT = 8080;
    private static final String HOST = "127.0.0.1";

    /** Autosave cadence. Frequent enough to matter, rare enough to be free. */
    private static final long AUTOSAVE_INTERVAL_MS = 5 * 60 * 1000L;
    private static final long SHUTDOWN_GRACE_MS = 8_000L;
    private static final int LOG_TAIL_LINES = 200;

    private final IBinder binder = new LocalBinder();
    private final Handler main = new Handler(Looper.getMainLooper());
    private final List<String> logTail = new ArrayList<>();
    private final List<Runnable> observers = new ArrayList<>();

    private final ExecutorService worker = Executors.newSingleThreadExecutor(
            runnable -> new Thread(runnable, "lal-service-work"));

    private PythonBridge bridge;
    private SaveStore saves;

    private volatile String phase = PHASE_STOPPED;
    private volatile String detail = "";
    private JSONObject stats;
    private boolean autosaveEnabled = true;
    private PowerManager.WakeLock wakeLock;

    private final Runnable autosaveTask = new Runnable() {
        @Override
        public void run() {
            if (autosaveEnabled && PHASE_RUNNING.equals(phase)) {
                captureAsync(SaveStore.KIND_AUTO);
            }
            if (autosaveEnabled && bridge.isRunning()) {
                main.postDelayed(this, AUTOSAVE_INTERVAL_MS);
            }
        }
    };

    /** Receives the autosave preference from the activity. */
    private final BroadcastReceiver preferenceReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            autosaveEnabled = intent.getBooleanExtra(EXTRA_AUTOSAVE, true);
            main.removeCallbacks(autosaveTask);
            if (autosaveEnabled && bridge.isRunning()) {
                main.postDelayed(autosaveTask, AUTOSAVE_INTERVAL_MS);
            }
        }
    };

    public final class LocalBinder extends Binder {
        ServerService service() {
            return ServerService.this;
        }
    }

    @Override
    public void onCreate() {
        super.onCreate();
        createChannel();
        // Constructing the bridge does not touch Python. Cold initialization
        // belongs to the worker, after onStartCommand posts the notification.
        bridge = new PythonBridge(this, this);
        saves = new SaveStore(this, RuntimeInstaller.databaseFile(this));
        autosaveEnabled = getSharedPreferences(MainActivity.PREFS, MODE_PRIVATE)
                .getBoolean(MainActivity.KEY_AUTOSAVE, true);
        IntentFilter preferenceFilter = new IntentFilter(ACTION_PREFERENCE);
        if (Build.VERSION.SDK_INT >= 33) {
            registerReceiver(preferenceReceiver, preferenceFilter, Context.RECEIVER_NOT_EXPORTED);
        } else {
            registerReceiver(preferenceReceiver, preferenceFilter);
        }
    }

    @Override
    public IBinder onBind(Intent intent) {
        return binder;
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        String action = intent == null ? null : intent.getAction();
        // The foreground notification must exist within seconds of start, so it
        // is posted before any real work; the phase is corrected once Python
        // reports the gateway is listening.
        startForeground(NOTIFICATION_ID, buildNotification());

        if (ACTION_START.equals(action)) {
            startServer();
        } else if (ACTION_STOP.equals(action)) {
            stopServer();
        } else if (ACTION_TOGGLE.equals(action)) {
            if (bridge.isRunning()) {
                stopServer();
            } else {
                startServer();
            }
        } else if (ACTION_SAVE.equals(action)) {
            captureAsync(SaveStore.KIND_MANUAL);
        }

        // Not sticky: a restart would come back with no Python state and no way
        // to tell the client what happened.
        return START_NOT_STICKY;
    }

    @Override
    public void onDestroy() {
        main.removeCallbacks(autosaveTask);
        main.removeCallbacks(consoleUpdate);
        try {
            unregisterReceiver(preferenceReceiver);
        } catch (IllegalArgumentException alreadyGone) {
            // onCreate never reached registerReceiver, or it ran twice.
        }
        releaseWakeLock();
        worker.shutdownNow();
        super.onDestroy();
    }

    // ------------------------------------------------------------------
    // Server lifecycle
    // ------------------------------------------------------------------

    void startServer() {
        if (bridge.isRunning() || PHASE_STARTING.equals(phase)) {
            return;
        }
        acquireWakeLock();
        publish(PHASE_STARTING, "正在解压运行时…");

        worker.execute(() -> {
            try {
                // This single worker also serializes save/import operations;
                // PythonBridge.facade guards their stopped-server path too.
                Py.ensure(ServerService.this);
                RuntimeInstaller.ensureInstalled(ServerService.this);
            } catch (Exception error) {
                Log.e(TAG, "Could not initialize the server runtime", error);
                releaseWakeLock();
                publish(PHASE_FAILED, "运行时初始化失败：" + message(error));
                return;
            }
            File runtime = RuntimeInstaller.runtimeDir(ServerService.this);
            File database = RuntimeInstaller.databaseFile(ServerService.this);
            File config = RuntimeInstaller.configFile(ServerService.this);
            if (!config.isFile()) {
                releaseWakeLock();
                publish(PHASE_FAILED, "缺少服务器配置：" + config.getName());
                return;
            }
            publish(PHASE_STARTING, "正在启动网关 " + HOST + ":" + PORT + " …");
            // start() spawns its own thread; the worker call just gets us off
            // the UI thread while the Chaquopy objects are created.
            bridge.start(runtime, database, config, HOST, PORT);
        });

        main.postDelayed(autosaveTask, AUTOSAVE_INTERVAL_MS);
    }

    void stopServer() {
        if (!bridge.isRunning() && !PHASE_STARTING.equals(phase)) {
            return;
        }
        publish(PHASE_STOPPING, "正在保存并停止…");
        main.removeCallbacks(autosaveTask);
        worker.execute(() -> {
            // An explicit final snapshot: the interval timer may have fired
            // minutes ago, and this is the last chance before the database closes.
            if (autosaveEnabled && saves.exists()) {
                try {
                    saves.capture(SaveStore.KIND_AUTO, bridge);
                } catch (Exception error) {
                    Log.w(TAG, "Final snapshot failed", error);
                }
            }
            bridge.stop();
            bridge.awaitStop(SHUTDOWN_GRACE_MS);
            // The service is "started", so nothing else would ever take it
            // down; an explicit stop has to do it here or a stopped server
            // would keep a foreground notification alive forever.
            main.post(() -> stopSelf());
        });
    }

    void toggle() {
        if (bridge.isRunning()) {
            stopServer();
        } else {
            startServer();
        }
    }

    void saveNow() {
        if (!saves.exists()) {
            publish(phase, "还没有可保存的进度，请先启动一次服务器。");
            return;
        }
        captureAsync(SaveStore.KIND_MANUAL);
    }

    /** Raw console input; no catalog, recipient picker or grant API. */
    boolean executeCommand(String line) {
        if (!PHASE_RUNNING.equals(phase) || line.isEmpty() || line.contains("\n") || line.contains("\r")) return false;
        onLogLine("server> " + line);
        if ("exit".equalsIgnoreCase(line.trim())) {
            stopServer();
        } else {
            worker.execute(() -> {
                if (!bridge.sendCommand(line)) onLogLine("Console input is closed.");
            });
        }
        return true;
    }

    SaveStore store() {
        return saves;
    }

    /** Exposed so the activity can run save operations on the service's worker. */
    PythonBridge bridge() {
        return bridge;
    }

    /** Runs a save/restore/import off the UI thread and reports the outcome. */
    void submit(String label, Work work) {
        worker.execute(() -> {
            try {
                work.run();
                onLogLine(label + "完成");
                publish(phase, label + "完成");
            } catch (Exception error) {
                Log.e(TAG, label + " failed", error);
                onLogLine(label + "失败：" + message(error));
                publish(phase, label + "失败：" + message(error));
            }
        });
    }

    interface Work {
        void run() throws Exception;
    }

    // ------------------------------------------------------------------
    // Python events
    // ------------------------------------------------------------------

    @Override
    public void onReady(String address) {
        publish(PHASE_RUNNING, address);
        // Recorded so BootReceiver can tell a deliberate stop from a reboot.
        setRunningPreference(true);
        bridge.sendCommand("status");
        submit("整理自动备份", () -> saves.prune());
        if (autosaveEnabled) {
            main.removeCallbacks(autosaveTask);
            main.postDelayed(autosaveTask, AUTOSAVE_INTERVAL_MS);
        }
    }

    @Override
    public void onStats(JSONObject payload) {
        stats = payload;
        publish(phase, detail);
    }

    @Override
    public void onLogLine(String line) {
        appendLog(line);
        main.removeCallbacks(consoleUpdate);
        main.postDelayed(consoleUpdate, 100);
    }

    private final Runnable consoleUpdate = () -> sendBroadcast(
            new Intent(ACTION_STATE).setPackage(getPackageName()));

    @Override
    public void onStopped(String error) {
        releaseWakeLock();
        main.removeCallbacks(autosaveTask);
        stats = null;
        // Either a clean stop or a crash: both mean the server is not running,
        // so a reboot must not resurrect it.
        setRunningPreference(false);
        if (error != null) {
            publish(PHASE_FAILED, error);
        } else {
            publish(PHASE_STOPPED, "");
        }
        stopForegroundCompat();
        // A crash reaches here without going through stopServer(), so the
        // started service must be ended here too or it would idle on.
        main.post(() -> stopSelf());
    }

    /** Mirrors the run state into the flag {@link BootReceiver} consults. */
    private void setRunningPreference(boolean running) {
        getSharedPreferences(MainActivity.PREFS, MODE_PRIVATE)
                .edit()
                .putBoolean(MainActivity.KEY_RUNNING, running)
                .apply();
    }

    // ------------------------------------------------------------------
    // State publication
    // ------------------------------------------------------------------

    void addObserver(Runnable observer) {
        observers.add(observer);
    }

    void removeObserver(Runnable observer) {
        observers.remove(observer);
    }

    String phase() {
        return phase;
    }

    String detail() {
        return detail;
    }

    JSONObject stats() {
        return stats;
    }

    List<String> log() {
        synchronized (logTail) { return new ArrayList<>(logTail); }
    }

    private void publish(String nextPhase, String nextDetail) {
        phase = nextPhase;
        detail = nextDetail == null ? "" : nextDetail;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            startForeground(NOTIFICATION_ID, buildNotification());
        } else {
            NotificationManager manager = getSystemService(NotificationManager.class);
            if (manager != null) {
                manager.notify(NOTIFICATION_ID, buildNotification());
            }
        }
        Intent update = new Intent(ACTION_STATE).setPackage(getPackageName());
        update.putExtra(EXTRA_PHASE, phase);
        update.putExtra(EXTRA_DETAIL, detail);
        if (stats != null) {
            update.putExtra(EXTRA_STATS, stats.toString());
        }
        sendBroadcast(update);
        main.post(() -> {
            for (Runnable observer : new ArrayList<>(observers)) {
                observer.run();
            }
        });
    }

    private void appendLog(String line) {
        synchronized (logTail) {
            logTail.add(line);
            while (logTail.size() > LOG_TAIL_LINES) logTail.remove(0);
        }
    }

    private void captureAsync(String kind) {
        submit(kind.equals(SaveStore.KIND_AUTO) ? "自动存档" : "存档", () -> {
            SaveStore.Save saved = saves.capture(kind, bridge);
            if (SaveStore.KIND_AUTO.equals(kind)) {
                saves.prune();
            }
            Log.i(TAG, saved == null ? "自动备份已按容量上限跳过" : "Saved " + saved.file.getName());
        });
    }

    // ------------------------------------------------------------------
    // Notification and power
    // ------------------------------------------------------------------

    private void createChannel() {
        // Notification channels only exist from API 26; below that the platform
        // uses the builder's own priority field.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return;
        }
        NotificationManager manager = getSystemService(NotificationManager.class);
        if (manager == null || manager.getNotificationChannel(CHANNEL_ID) != null) {
            return;
        }
        NotificationChannel channel = new NotificationChannel(
                CHANNEL_ID,
                ManagerStrings.notif_channel_name,
                NotificationManager.IMPORTANCE_LOW);
        channel.setDescription(ManagerStrings.notif_channel_desc);
        manager.createNotificationChannel(channel);
    }

    /**
     * Builds the ongoing server notification.
     *
     * <p>Plain {@link Notification.Builder} rather than the compat one: nothing
     * from AndroidX can ship in this module. The two-argument constructor
     * requires API 26, so on API 24–25 the deprecated one-argument form is used
     * and the channel is never named — there is no channel to name.
     */
    @SuppressWarnings("deprecation")
    private Notification buildNotification() {
        PendingIntent content = PendingIntent.getActivity(
                this,
                0,
                new Intent(this, MainActivity.class),
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

        String text = ManagerStrings.notif_text;
        if (stats != null) {
            text = stats.optString("address", text)
                    + " · 账号 " + stats.optInt("accounts")
                    + " · 存档 " + stats.optInt("players");
        }

        Notification.Builder builder = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
                ? new Notification.Builder(this, CHANNEL_ID)
                : new Notification.Builder(this);
        builder.setSmallIcon(android.R.drawable.stat_sys_download)
                .setContentTitle(ManagerStrings.notif_title)
                .setContentText(text)
                .setOngoing(true)
                .setShowWhen(false)
                .setPriority(Notification.PRIORITY_LOW)
                .setContentIntent(content);

        if (PHASE_RUNNING.equals(phase)) {
            builder.addAction(0, ManagerStrings.notif_action_save, broadcast(ACTION_SAVE));
            builder.addAction(0, ManagerStrings.notif_action_stop, broadcast(ACTION_STOP));
        }
        return builder.build();
    }

    private PendingIntent broadcast(String action) {
        Intent intent = new Intent(this, ServerService.class).setAction(action);
        return PendingIntent.getService(
                this,
                action.hashCode(),
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
    }

    @SuppressWarnings("deprecation")
    private void stopForegroundCompat() {
        stopForeground(true);
    }

    private void acquireWakeLock() {
        if (wakeLock != null) {
            return;
        }
        PowerManager power = getSystemService(PowerManager.class);
        if (power == null) {
            return;
        }
        wakeLock = power.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK, "lal-rebuild:server");
        wakeLock.setReferenceCounted(false);
        wakeLock.acquire(SHUTDOWN_GRACE_MS * 30L);
    }

    private void releaseWakeLock() {
        if (wakeLock != null && wakeLock.isHeld()) {
            wakeLock.release();
        }
        wakeLock = null;
    }

    // ------------------------------------------------------------------
    // Client launch
    // ------------------------------------------------------------------

    /**
     * Identifies this service for a component name.
     *
     * <p>The package is read from the live context rather than hard-coded: the
     * merged APK is installed under the AIR client's {@code applicationId}, so a
     * literal {@code "com.lal.rebuild.manager"} would name a package that no
     * longer exists.
     */
    static ComponentName component(Context context) {
        return new ComponentName(context, ServerService.class);
    }

    private static String message(Throwable error) {
        String text = error.getMessage();
        return text == null || text.isEmpty() ? error.getClass().getSimpleName() : text;
    }
}
