package com.lal.rebuild.manager;

import android.content.Context;
import android.content.res.AssetManager;
import android.util.Log;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

/**
 * Copies the bundled server tree out of the APK assets into a real directory so
 * that upstream paths keep working unchanged.
 *
 * <p>The server resolves its own root as {@code parents[1]} of
 * {@code server/gateway.py} and then reads {@code ROOT/VERSION},
 * {@code ROOT/config/...} and writes {@code ROOT/data/logs/...}. APK assets are
 * not readable as ordinary files, so the tree is unpacked to
 * {@code filesDir/runtime} and imported from there. Nothing upstream needs to
 * be modified, and the layout below must be preserved exactly:
 *
 * <pre>
 * filesDir/runtime/VERSION
 * filesDir/runtime/server/*.py
 * filesDir/runtime/config/reconstruction/*.json
 * </pre>
 */
public final class RuntimeInstaller {

    private static final String TAG = "RuntimeInstaller";
    private static final String ASSET_ROOT = "runtime";
    private static final String STAMP = ".runtime-stamp";
    private static final String CONFIG_RELATIVE = "config/reconstruction/full-config.json";
    /** Server-owned runtime scratch space, preserved across app updates. */
    private static final String DATA_DIR = "data";

    private RuntimeInstaller() {
    }

    /** Absolute path to the unpacked server tree. */
    public static File runtimeDir(Context context) {
        return new File(context.getFilesDir(), "runtime");
    }

    /** Absolute path to the writable save/state directory. */
    public static File dataDir(Context context) {
        File dir = new File(context.getFilesDir(), "state");
        if (!dir.isDirectory() && !dir.mkdirs()) {
            Log.w(TAG, "Could not create state directory: " + dir);
        }
        return dir;
    }

    /**
     * Absolute path to the live database. It lives outside {@code runtime} on
     * purpose: unpacking a new server build wipes that directory, and a player's
     * progress must survive an app update.
     */
    public static File databaseFile(Context context) {
        return new File(dataDir(context), "local.sqlite3");
    }

    /** Absolute path to the configuration read by the server at startup. */
    public static File configFile(Context context) {
        return new File(runtimeDir(context), CONFIG_RELATIVE);
    }

    /**
     * Absolute path to the snapshot directory. Internal storage is deliberate:
     * it needs no runtime permission and is removed with the app, so only
     * exported files outlive an uninstall.
     */
    public static File saveDir(Context context) {
        File dir = new File(context.getFilesDir(), "saves");
        if (!dir.isDirectory() && !dir.mkdirs()) {
            Log.w(TAG, "Could not create save directory: " + dir);
        }
        return dir;
    }

    /**
     * Unpacks assets on first launch and whenever the bundled runtime changes.
     * The stamp includes its manifest digest so content updates also refresh
     * the server when the app version is unchanged. The writable
     * {@code state} directory lives outside this one and is never touched.
     */
    public static void ensureInstalled(Context context) throws IOException {
        File root = runtimeDir(context);
        File stampFile = new File(root, STAMP);
        String expected = BuildConfig.VERSION_CODE + "/" + BuildConfig.VERSION_NAME
                + "/" + bundledRuntimeDigest(context);
        if (stampFile.isFile()) {
            String present = new String(Files.readAllBytes(stampFile.toPath()),
                    StandardCharsets.UTF_8).trim();
            if (expected.equals(present)) {
                return;
            }
        }

        // The server writes diagnostics to ROOT/data/logs at runtime, and that
        // path sits inside the tree this method replaces. Carry it across the
        // unpack so an update keeps the player's client-error history.
        File keptData = new File(context.getCacheDir(), "runtime-data-backup");
        deleteTree(keptData);
        File existingData = new File(root, DATA_DIR);
        if (existingData.isDirectory() && !existingData.renameTo(keptData)) {
            Log.w(TAG, "Could not preserve " + existingData);
            keptData = null;
        }

        deleteTree(root);
        if (!root.mkdirs() && !root.isDirectory()) {
            throw new IOException("Could not create runtime directory: " + root);
        }
        copyTree(context.getAssets(), ASSET_ROOT, root);

        if (keptData != null && keptData.isDirectory()) {
            File restored = new File(root, DATA_DIR);
            if (!keptData.renameTo(restored)) {
                copyTree(keptData, restored);
                deleteTree(keptData);
            }
        }

        try (FileOutputStream out = new FileOutputStream(stampFile)) {
            out.write(expected.getBytes(StandardCharsets.UTF_8));
        }
        Log.i(TAG, "Unpacked server tree to " + root);
    }

    private static String bundledRuntimeDigest(Context context) throws IOException {
        final MessageDigest digest;
        try {
            digest = MessageDigest.getInstance("SHA-256");
        } catch (NoSuchAlgorithmException impossible) {
            throw new IOException("SHA-256 is unavailable", impossible);
        }
        try (InputStream in = context.getAssets().open(ASSET_ROOT + "/runtime-manifest.json")) {
            byte[] buffer = new byte[8192];
            int count;
            while ((count = in.read(buffer)) != -1) {
                digest.update(buffer, 0, count);
            }
        }
        StringBuilder hex = new StringBuilder(64);
        for (byte value : digest.digest()) {
            hex.append(Character.forDigit((value & 255) >>> 4, 16));
            hex.append(Character.forDigit(value & 15, 16));
        }
        return hex.toString();
    }

    /** Recursive copy of an ordinary directory tree, used for the data carry-over. */
    private static void copyTree(File source, File target) throws IOException {
        if (source.isDirectory()) {
            if (!target.isDirectory() && !target.mkdirs()) {
                throw new IOException("Could not create directory: " + target);
            }
            File[] children = source.listFiles();
            if (children != null) {
                for (File child : children) {
                    copyTree(child, new File(target, child.getName()));
                }
            }
            return;
        }
        try (InputStream in = new FileInputStream(source);
             FileOutputStream out = new FileOutputStream(target)) {
            byte[] buffer = new byte[64 * 1024];
            int read;
            while ((read = in.read(buffer)) != -1) {
                out.write(buffer, 0, read);
            }
        }
    }

    private static void copyTree(AssetManager assets, String assetPath, File target)
            throws IOException {
        String[] children = assets.list(assetPath);
        if (children == null) {
            children = new String[0];
        }
        if (children.length == 0) {
            copyFile(assets, assetPath, target);
            return;
        }
        if (!target.isDirectory() && !target.mkdirs()) {
            throw new IOException("Could not create directory: " + target);
        }
        for (String child : children) {
            copyTree(assets, assetPath + "/" + child, new File(target, child));
        }
    }

    private static void copyFile(AssetManager assets, String assetPath, File target)
            throws IOException {
        // A directory holding no files is reported by AssetManager.list() as an
        // empty result, the same as a file. open() is what distinguishes them.
        try (InputStream in = assets.open(assetPath);
             FileOutputStream out = new FileOutputStream(target)) {
            byte[] buffer = new byte[64 * 1024];
            int read;
            while ((read = in.read(buffer)) != -1) {
                out.write(buffer, 0, read);
            }
        }
    }

    private static void deleteTree(File target) throws IOException {
        if (!target.exists()) {
            return;
        }
        File[] children = target.listFiles();
        if (children != null) {
            for (File child : children) {
                deleteTree(child);
            }
        }
        if (!target.delete() && target.exists()) {
            throw new IOException("Could not delete: " + target);
        }
    }
}
