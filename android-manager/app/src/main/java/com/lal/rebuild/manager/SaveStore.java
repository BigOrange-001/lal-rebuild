package com.lal.rebuild.manager;

import android.content.Context;
import android.util.Log;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.zip.GZIPOutputStream;

/**
 * Snapshot storage for the game database.
 *
 * <p>New saves are losslessly compressed copies of {@code state/local.sqlite3},
 * named {@code <kind>-<millis>-<digest>.sqlite3.gz}. Legacy SQLite saves remain
 * readable and exported files can be imported into another install. Metadata
 * lives in the file name rather than a sidecar index: a save stays readable
 * even if the app that wrote it is gone.
 */
final class SaveStore {

    static final String KIND_AUTO = "auto";
    static final String KIND_MANUAL = "manual";
    static final String KIND_IMPORTED = "imported";
    /**
     * Virtual kind for the live database itself. It has no file of its own in
     * this directory: it is {@link #source}, listed first so the progress the
     * player is actually playing is always visible and resettable.
     */
    static final String KIND_LIVE = "live";

    private static final String TAG = "SaveStore";
    private static final String EXTENSION = ".sqlite3";
    private static final String COMPRESSED_EXTENSION = ".sqlite3.gz";
    private static final String STAGING = "staging";

    /** Keeps the list usable on a phone and the disk use bounded. */
    static final int AUTO_KEEP = 5;
    static final long STORAGE_LIMIT = 10L * 1024 * 1024;

    private static final SimpleDateFormat STAMP =
            new SimpleDateFormat("yyyy-MM-dd HH:mm", Locale.US);
    private static final SimpleDateFormat FILE_STAMP =
            new SimpleDateFormat("yyyy-MM-dd-HHmmss", Locale.US);

    static final class Save {
        final File file;
        final String kind;
        final long createdAt;
        final long bytes;

        Save(File file, String kind, long createdAt, long bytes) {
            this.file = file;
            this.kind = kind;
            this.createdAt = createdAt;
            this.bytes = bytes;
        }

        String digest() {
            String name = file.getName();
            String stem = saveStem(name);
            int dash = stem.lastIndexOf('-');
            return dash > 0 ? stem.substring(dash + 1) : "";
        }

        /** True for the synthetic entry standing in for the live database. */
        boolean isLive() {
            return KIND_LIVE.equals(kind);
        }

        String label() {
            String stamp = STAMP.format(new Date(createdAt));
            if (isLive()) {
                // No digest to show: the live database has no name to hash.
                return stamp + " · " + formatBytes(bytes);
            }
            String shortDigest = digest();
            if (shortDigest.length() > 6) {
                shortDigest = shortDigest.substring(0, 6);
            }
            return stamp + " · " + formatBytes(bytes) + " · " + shortDigest;
        }
    }

    private final Context context;
    private final File source;

    SaveStore(Context context, File source) {
        this.context = context.getApplicationContext();
        this.source = source;
    }

    File directory() {
        return RuntimeInstaller.saveDir(context);
    }

    File source() {
        return source;
    }

    boolean exists() {
        return source.isFile();
    }

    /**
     * The live database, wrapped as a save so it can be listed and reset
     * alongside the snapshots. Null until the server has created it.
     */
    Save live() {
        if (!source.isFile()) {
            return null;
        }
        return new Save(source, KIND_LIVE, source.lastModified(), source.length());
    }

    /** Newest first. Unparsable files are surfaced rather than silently hidden. */
    List<Save> list() {
        File[] files = directory().listFiles(
                (dir, name) -> (name.endsWith(EXTENSION) || name.endsWith(COMPRESSED_EXTENSION)) && !name.startsWith(".tmp"));
        List<Save> saves = new ArrayList<>();
        // The live database is deliberately not a file in this directory, so it
        // is prepended by hand. Callers that index into the list rely on it
        // coming first.
        Save current = live();
        if (current != null) {
            saves.add(current);
        }
        if (files == null) {
            return saves;
        }
        for (File file : files) {
            saves.add(describe(file));
        }
        saves.sort(Comparator.comparingLong((Save save) -> save.createdAt).reversed());
        return saves;
    }

    Save capture(String kind, PythonBridge bridge) throws Exception {
        if (!source.isFile()) {
            throw new IOException("数据库尚未生成，请先启动一次服务器。");
        }
        File staging = new File(stagingDir(), "snapshot" + EXTENSION);
        File plainStaging = staging;
        File gzipStaging = new File(staging.getPath() + ".gz");
        try {
            if (staging.isFile() && !staging.delete()) {
                throw new IOException("无法清理上一次的临时存档。");
            }
            bridge.snapshot(source, staging);
            staging = archive(staging);
            String digest = digestOf(staging);
            if (KIND_AUTO.equals(kind)) {
                for (Save existing : list()) {
                    if (!KIND_AUTO.equals(existing.kind)) continue;
                    if (digest.equals(digestOf(existing.file))) {
                        if (!staging.delete()) throw new IOException("无法清理重复备份。");
                        prune();
                        return existing.file.isFile() ? existing : null;
                    }
                    break;
                }
            }
            long timestamp = System.currentTimeMillis();
            File target;
            do { target = new File(directory(), kind + "-" + timestamp++ + "-" + digest + COMPRESSED_EXTENSION); }
            while (target.exists());
            if (!staging.renameTo(target)) {
                move(staging, target);
            }
            Log.i(TAG, "Captured " + target.getName());
            if (KIND_AUTO.equals(kind)) prune();
            return target.isFile() ? describe(target) : null;
        } finally {
            if (plainStaging.isFile()) plainStaging.delete();
            if (gzipStaging.isFile()) gzipStaging.delete();
        }
    }

    /**
     * Makes {@code save} the live database. The current state is captured first,
     * so a restore is itself undoable.
     */
    void restore(Save save, PythonBridge bridge) throws Exception {
        if (!save.file.isFile()) {
            throw new IOException("存档文件已不存在。");
        }
        // Capturing the rollback point may prune the selected oldest auto save.
        File selected = new File(stagingDir(), "restore" + (save.file.getName().endsWith(COMPRESSED_EXTENSION) ? COMPRESSED_EXTENSION : EXTENSION));
        java.nio.file.Files.copy(save.file.toPath(), selected.toPath(), java.nio.file.StandardCopyOption.REPLACE_EXISTING);
        try {
            if (source.isFile() && capture(KIND_AUTO, bridge) == null)
                throw new IOException("容量不足，无法保留回档前的进度；请先导出当前存档。");
            bridge.importDatabase(selected, source);
            prune();
        } finally { if (selected.isFile()) selected.delete(); }
        Log.i(TAG, "Restored " + save.file.getName());
    }

    /** Stages an external file for validation, then installs it as a save. */
    Save importFrom(InputStream input, PythonBridge bridge) throws Exception {
        if (!source.isFile()) {
            throw new IOException("数据库尚未生成，请先启动一次服务器。");
        }
        File staging = new File(stagingDir(), "import" + EXTENSION);
        File plainStaging = staging;
        File gzipStaging = new File(staging.getPath() + ".gz");
        try {
        try (OutputStream output = new java.io.FileOutputStream(staging)) {
            copy(input, output);
        }
        bridge.verify(staging);
        staging = archive(staging);
        String digest = digestOf(staging);
        File target = new File(directory(), KIND_IMPORTED + "-" + System.currentTimeMillis()
                + "-" + digest + COMPRESSED_EXTENSION);
        move(staging, target);

        // Keep the pre-import state so an accidental import can be undone.
        if (capture(KIND_AUTO, bridge) == null) throw new IOException("容量不足，无法保留导入前的进度；请先导出当前存档。");
        bridge.importDatabase(target, source);
        prune();
        Log.i(TAG, "Imported " + target.getName());
        return describe(target);
        } finally {
            if (plainStaging.isFile()) plainStaging.delete();
            if (gzipStaging.isFile()) gzipStaging.delete();
        }
    }

    void export(Save save, OutputStream output) throws IOException {
        try (InputStream input = new java.io.FileInputStream(save.file)) {
            copy(input, output);
        }
    }

    String exportName(Save save) {
        return "lal-" + save.kind + "-" + FILE_STAMP.format(new Date(save.createdAt))
                + (save.file.getName().endsWith(COMPRESSED_EXTENSION) ? COMPRESSED_EXTENSION : EXTENSION);
    }

    void delete(Save save) throws IOException {
        if (save.file.isFile() && !save.file.delete()) {
            throw new IOException("无法删除存档文件：" + save.file.getName());
        }
    }

    /**
     * Deletes the live database so the next login starts a fresh game.
     *
     * <p>The server rebuilds its schema on startup and {@code PlayerStore.login}
     * mints a new profile for an unknown account, so removing the file is
     * enough — no rows need to be written back. Snapshots are left alone, so a
     * reset stays undoable via 恢复存档.
     *
     * <p>The caller must have stopped the server: SQLite holds the file open,
     * and on Windows an open handle makes the delete fail outright.
     */
    void reset() throws IOException {
        boolean removedAny = false;
        // The -wal and -shm sidecars belong to the same database; a leftover
        // journal alongside a fresh file would be replayed into it.
        for (String suffix : new String[]{"", "-wal", "-shm"}) {
            File part = new File(source.getPath() + suffix);
            if (!part.isFile()) {
                continue;
            }
            if (!part.delete()) {
                throw new IOException("无法删除存档文件：" + part.getName()
                        + "。请先停止服务器。");
            }
            removedAny = true;
        }
        if (removedAny) {
            Log.i(TAG, "Reset the live database");
        }
    }

    /** Compress legacy automatic copies, then enforce count and byte budgets. */
    int prune() {
        int removed = 0;
        for (Save save : list()) {
            if (KIND_AUTO.equals(save.kind) && save.file.getName().endsWith(EXTENSION)) {
                try { archive(save.file); }
                catch (IOException error) { Log.w(TAG, "Could not compress legacy backup", error); }
            }
        }
        List<Save> automatic = new ArrayList<>();
        long bytes = liveBytes();
        for (Save save : list()) {
            if (KIND_AUTO.equals(save.kind)) { automatic.add(save); bytes += save.bytes; }
        }
        for (int i = automatic.size() - 1; i >= 0
                && (automatic.size() - removed > AUTO_KEEP || bytes > STORAGE_LIMIT); i--) {
            Save old = automatic.get(i);
            if (old.file.delete()) { bytes -= old.bytes; removed++; }
        }
        return removed;
    }

    private long liveBytes() {
        long bytes = 0;
        for (String suffix : new String[]{"", "-wal", "-shm", "-journal"}) {
            File part = new File(source.getPath() + suffix);
            if (part.isFile()) bytes += part.length();
        }
        return bytes;
    }

    String storageSummary() {
        long managed = liveBytes(), other = 0;
        int automatic = 0;
        for (Save save : list()) {
            if (save.isLive()) continue;
            if (KIND_AUTO.equals(save.kind)) { managed += save.bytes; automatic++; }
            else other += save.bytes;
        }
        return "当前进度＋自动备份：" + formatBytes(managed) + " / 10 MB（" + automatic + "/5份）\n"
                + "手动及导入存档：" + formatBytes(other) + "，由你管理"
                + (liveBytes() > STORAGE_LIMIT ? "\n当前进度已超限，自动备份暂停；进度继续保留。" : "");
    }

    private static String saveStem(String name) {
        String extension = name.endsWith(COMPRESSED_EXTENSION) ? COMPRESSED_EXTENSION : EXTENSION;
        return name.endsWith(extension) ? name.substring(0, name.length() - extension.length()) : name;
    }

    private File archive(File original) throws IOException {
        File compressed = new File(original.getPath() + ".gz");
        boolean alreadyCompressed;
        try (InputStream input = new java.io.FileInputStream(original)) {
            alreadyCompressed = input.read() == 0x1f && input.read() == 0x8b;
        }
        if (alreadyCompressed) {
            java.nio.file.Files.move(original.toPath(), compressed.toPath(), java.nio.file.StandardCopyOption.REPLACE_EXISTING);
            return compressed;
        }
        File temporary = new File(stagingDir(), ".tmp-archive-" + System.nanoTime());
        try {
            try (InputStream input = new java.io.FileInputStream(original);
                 OutputStream output = new GZIPOutputStream(new java.io.FileOutputStream(temporary))) {
                copy(input, output);
            }
            java.nio.file.Files.move(temporary.toPath(), compressed.toPath(), java.nio.file.StandardCopyOption.REPLACE_EXISTING);
            if (!original.delete()) {
                compressed.delete();
                throw new IOException("无法完成压缩存档替换。");
            }
            return compressed;
        } finally { if (temporary.isFile()) temporary.delete(); }
    }

    private Save describe(File file) {
        String name = file.getName();
        String stem = saveStem(name);
        String kind = KIND_MANUAL;
        long createdAt = file.lastModified();
        int first = stem.indexOf('-');
        if (first > 0) {
            kind = stem.substring(0, first);
            String rest = stem.substring(first + 1);
            int second = rest.indexOf('-');
            if (second < 0) second = rest.length();
            if (second > 0) {
                try {
                    createdAt = Long.parseLong(rest.substring(0, second));
                } catch (NumberFormatException ignored) {
                    // A renamed file keeps its modification time instead.
                }
            }
        }
        if (createdAt <= 0) {
            createdAt = file.lastModified();
        }
        return new Save(file, kind, createdAt, file.length());
    }

    private File stagingDir() throws IOException {
        File dir = new File(context.getFilesDir(), STAGING);
        if (!dir.isDirectory() && !dir.mkdirs()) {
            throw new IOException("无法创建临时目录：" + dir);
        }
        return dir;
    }

    private static void move(File from, File to) throws IOException {
        java.nio.file.Files.move(from.toPath(), to.toPath(), java.nio.file.StandardCopyOption.REPLACE_EXISTING);
    }

    private static void copy(InputStream input, OutputStream output) throws IOException {
        byte[] buffer = new byte[64 * 1024];
        int read;
        while ((read = input.read(buffer)) != -1) {
            output.write(buffer, 0, read);
        }
        output.flush();
    }

    private static String digestOf(File file) throws Exception {
        MessageDigest digest = MessageDigest.getInstance("SHA-256");
        try (InputStream input = new java.io.FileInputStream(file)) {
            byte[] buffer = new byte[64 * 1024];
            int read;
            while ((read = input.read(buffer)) != -1) {
                digest.update(buffer, 0, read);
            }
        }
        byte[] bytes = digest.digest();
        StringBuilder text = new StringBuilder(16);
        for (int index = 0; index < 8; index++) {
            text.append(String.format(Locale.US, "%02x", bytes[index]));
        }
        return text.toString();
    }

    static String formatBytes(long bytes) {
        if (bytes < 1024) {
            return bytes + " B";
        }
        if (bytes < 1024 * 1024) {
            return String.format(Locale.US, "%.1f KB", bytes / 1024.0);
        }
        return String.format(Locale.US, "%.1f MB", bytes / (1024.0 * 1024.0));
    }

    static boolean isSqlite(File file) {
        if (!file.isFile() || file.length() < 16) {
            return false;
        }
        byte[] header = new byte[16];
        try (InputStream input = new java.io.FileInputStream(file)) {
            if (input.read(header) != header.length) {
                return false;
            }
        } catch (IOException error) {
            return false;
        }
        return Arrays.equals(header, "SQLite format 3\u0000".getBytes(StandardCharsets.US_ASCII));
    }
}
