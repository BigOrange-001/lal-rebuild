package com.lal.rebuild.manager;

import android.content.Context;
import android.content.Intent;
import android.os.Build;

/**
 * Restarts the manager after a reboot or after the app is updated.
 *
 * <p>Only fires when the player left the server running: an autostart flag is
 * written whenever the server starts or stops, and the boot receiver consults
 * it so a phone restart never resurfaces a server the player had switched off.
 * Android 12+ blocks foreground-service starts from this context, so the work
 * is handed to {@link ServerService} via {@code startForegroundService}.
 */
public class BootReceiver extends android.content.BroadcastReceiver {

    @Override
    public void onReceive(Context context, Intent intent) {
        String action = intent.getAction();
        boolean relevant = Intent.ACTION_BOOT_COMPLETED.equals(action)
                || Intent.ACTION_MY_PACKAGE_REPLACED.equals(action);
        if (!relevant) {
            return;
        }
        boolean shouldRun = context.getSharedPreferences(MainActivity.PREFS, Context.MODE_PRIVATE)
                .getBoolean(MainActivity.KEY_RUNNING, false);
        if (!shouldRun) {
            return;
        }

        // A boot broadcast can arrive with the app's process cold, so the
        // runtime must be up before the service tries to use it. Warm it on a
        // worker thread; Chaquopy's unpack is far too slow for onReceive.
        final Context app = context.getApplicationContext();
        new Thread(() -> Py.ensure(app), "python-init").start();

        Intent start = new Intent(context, ServerService.class)
                .setAction(ServerService.ACTION_START);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(start);
        } else {
            context.startService(start);
        }
    }
}
