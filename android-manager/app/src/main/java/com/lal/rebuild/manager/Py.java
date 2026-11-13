package com.lal.rebuild.manager;

import android.content.Context;

import com.chaquo.python.Python;
import com.chaquo.python.android.AndroidPlatform;

/**
 * Starts the embedded CPython runtime on first use.
 *
 * <p>In the standalone manager this was an {@link android.app.Application}
 * subclass whose {@code onCreate} kicked the runtime off on a background
 * thread. The merged APK cannot use that: the manifest's application class must
 * stay {@code androidx.multidex.MultiDexApplication} verbatim, because that
 * class resolves out of the AIR client's prebuilt dex and is what loads
 * {@code classes2.dex} — replacing it would edit the client's bytecode
 * untouched-but-for-this, for no gain.
 *
 * <p>So the init became lazy and explicit. Call {@link #ensure} before touching
 * any {@code PyObject}; it blocks until the runtime is up, so it must only run
 * on worker threads. {@link ServerService#onCreate} is the load-bearing call —
 * it covers the boot receiver path, the activity path and the notification
 * action path, since all three start the service.
 */
final class Py {

    private Py() {
    }

    /** Starts Python if it is not already up. Blocks; never call on the UI thread. */
    static synchronized void ensure(Context context) {
        if (Python.isStarted()) {
            return;
        }
        Python.start(new AndroidPlatform(context.getApplicationContext()));
    }
}
