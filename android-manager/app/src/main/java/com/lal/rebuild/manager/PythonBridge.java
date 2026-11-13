package com.lal.rebuild.manager;

import android.util.Log;

import com.chaquo.python.PyObject;
import com.chaquo.python.Python;

import org.json.JSONObject;

import java.io.File;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * Runs the unpacked server inside the embedded CPython runtime and translates
 * its output into callbacks.
 *
 * <p>The upstream server is driven exactly as a desktop user would drive it:
 * it is started with the same arguments {@code start-server.ps1} passes, and it
 * stops when the console command {@code exit} reaches it. Nothing in
 * {@code server/} needs to know it is running on Android.
 */
final class PythonBridge {

    interface Events {
        /** The gateway has bound its port and is accepting connections. */
        void onReady(String address);

        /** The server answered a {@code status} query. */
        void onStats(JSONObject payload);

        /** A line of server output for the log pane. */
        void onLogLine(String line);

        /** The run loop finished, cleanly or not. */
        void onStopped(String error);
    }

    static final String MODULE = "run_server";

    private static final String TAG = "PythonBridge";

    private final AtomicBoolean running = new AtomicBoolean(false);
    private final Events events;
    /** Only used to reach a Context for the Chaquopy runtime; the service owns it. */
    private final android.content.Context context;

    private volatile PyObject bridge;
    private volatile Thread worker;

    PythonBridge(Events events, android.content.Context context) {
        this.events = events;
        this.context = context.getApplicationContext();
    }

    boolean isRunning() {
        return running.get();
    }

    /**
     * Starts the server on a worker thread. Must not run on the UI thread:
     * {@code serve_forever()} blocks for the whole lifetime of the server.
     */
    void start(File runtimeDir, File database, File config, String host, int port) {
        if (!running.compareAndSet(false, true)) {
            return;
        }
        Py.ensure(context);

        final PyObject module = Python.getInstance().getModule(MODULE);
        final PyObject facade = Python.getInstance().getModule("manager_bridge");
        facade.callAttr("install", new Callback());
        bridge = facade;

        final String runtimePath = runtimeDir.getAbsolutePath();
        final String databasePath = database.getAbsolutePath();
        final String configPath = config.getAbsolutePath();

        worker = new Thread(() -> {
            String failure = null;
            try {
                module.callAttr("main", runtimePath, host, port, databasePath, configPath);
            } catch (Throwable error) {
                failure = describe(error);
                Log.e(TAG, "Server stopped with an error", error);
            } finally {
                running.set(false);
                worker = null;
                events.onStopped(failure);
            }
        }, "lal-server");
        worker.start();
    }

    /**
     * Asks the server to shut down. The upstream console thread is blocked on
     * {@code input()}, so the command has to arrive through the bridge's stdin
     * replacement; {@code stop()} also releases that read afterwards.
     */
    void stop() {
        PyObject current = bridge;
        if (current == null || !running.get()) {
            return;
        }
        try {
            current.callAttr("stop");
        } catch (Throwable error) {
            Log.w(TAG, "Could not ask the server to stop", error);
            Thread thread = worker;
            if (thread != null) {
                thread.interrupt();
            }
        }
    }

    /** Runs a server console command, e.g. {@code status} or a mail grant. */
    boolean sendCommand(String line) {
        PyObject current = bridge;
        if (current == null || !running.get()) return false;
        try {
            return current.callAttr("command", line).toBoolean();
        } catch (Throwable error) {
            events.onLogLine("Console command failed: " + describe(error));
            return false;
        }
    }

    /** Waits briefly for an orderly shutdown so the database closes cleanly. */
    void awaitStop(long timeoutMillis) {
        Thread thread = worker;
        if (thread == null) {
            return;
        }
        try {
            thread.join(timeoutMillis);
        } catch (InterruptedException interrupted) {
            Thread.currentThread().interrupt();
        }
    }

    /**
     * Takes a consistent copy of the live database. Safe to call while the
     * server is serving, because SQLite's backup API owns the locking.
     */
    void snapshot(File source, File target) throws Exception {
        facade().callAttr("snapshot", source.getAbsolutePath(), target.getAbsolutePath());
    }

    /** Validates a candidate save file before it is allowed to replace one. */
    JSONObject verify(File candidate) throws Exception {
        PyObject result = facade().callAttr("verify", candidate.getAbsolutePath());
        return new JSONObject(result.callAttr("__str__").toString());
    }

    /**
     * Replaces the live database with a verified copy. The server must not be
     * running; the caller stops it first.
     */
    void importDatabase(File source, File target) throws Exception {
        facade().callAttr("import_database", source.getAbsolutePath(), target.getAbsolutePath());
    }

    private PyObject facade() throws Exception {
        PyObject current = bridge;
        if (current != null) {
            return current;
        }
        // Save verification must also work while the gateway is stopped.
        RuntimeInstaller.ensureInstalled(context);
        Py.ensure(context);
        PyObject module = Python.getInstance().getModule("manager_bridge");
        module.callAttr("prepare", RuntimeInstaller.runtimeDir(context).getAbsolutePath());
        return module;
    }

    private static String describe(Throwable error) {
        String message = error.getMessage();
        if (message == null || message.isEmpty()) {
            return error.getClass().getSimpleName();
        }
        return message;
    }

    /**
     * Receives the bridge's events. Chaquopy exposes this object to Python as a
     * proxy, so the method names here are the ones {@code manager_bridge}
     * calls by name.
     */
    public final class Callback {

        public void onReady(String text) {
            events.onReady(text);
        }

        public void onStats(String json) {
            try {
                events.onStats(new JSONObject(json));
            } catch (Exception error) {
                Log.w(TAG, "Malformed status payload: " + json, error);
            }
        }

        public void onLog(String line) {
            events.onLogLine(line);
        }
    }
}
