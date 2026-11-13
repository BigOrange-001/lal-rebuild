package com.lal.rebuild.manager;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

/** Publish a bounded, complete input stream for the existing authenticated Mod scanner. */
final class HeroPackageInbox {
    static final long MAX_BYTES = 64L * 1024 * 1024;
    interface Cancellation { boolean cancelled(); }

    private HeroPackageInbox() { }

    static synchronized File copy(InputStream input, File inbox, Cancellation cancellation)
            throws IOException {
        if (input == null) throw new IOException("文件提供程序未返回可读取的内容。");
        if (!inbox.isDirectory() && !inbox.mkdirs()) throw new IOException("无法创建英雄包导入目录。");
        File part = File.createTempFile(".hero-import-", ".part", inbox);
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            long total = 0;
            try (FileOutputStream output = new FileOutputStream(part)) {
                byte[] buffer = new byte[64 * 1024];
                int count;
                while ((count = input.read(buffer)) != -1) {
                    if (cancellation.cancelled()) throw new IOException("已取消导入。");
                    if (count == 0) continue;
                    total += count;
                    if (total > MAX_BYTES) throw new IOException("英雄包超过 64 MiB，未导入。");
                    output.write(buffer, 0, count);
                    digest.update(buffer, 0, count);
                }
                if (total == 0) throw new IOException("英雄包为空，未导入。");
                output.getFD().sync();
            }
            if (cancellation.cancelled()) throw new IOException("已取消导入。");
            StringBuilder hex = new StringBuilder(64);
            for (byte value : digest.digest()) hex.append(String.format(java.util.Locale.ROOT, "%02x", value & 255));
            File target = new File(inbox, "native-import-" + hex + ".heropack");
            // The staging file shares the target filesystem. The scanner ignores
            // .part files, so it can never observe an incomplete hero package.
            File marker = new File(inbox, target.getName() + ".native-owned");
            byte[] ownership = "lal-saf-import-v1\n".getBytes(java.nio.charset.StandardCharsets.UTF_8);
            boolean ownedBefore = marker.isFile();
            if (ownedBefore && (marker.length() != ownership.length ||
                    !java.util.Arrays.equals(Files.readAllBytes(marker.toPath()), ownership)))
                throw new IOException("原生导入归属标记无效。");
            if (!ownedBefore) Files.write(marker.toPath(), ownership, java.nio.file.StandardOpenOption.CREATE_NEW);
            try {
                if (cancellation.cancelled()) throw new IOException("已取消导入。");
                if (!target.isFile()) Files.move(part.toPath(), target.toPath(), StandardCopyOption.ATOMIC_MOVE);
            } catch (IOException error) {
                if (!ownedBefore) Files.deleteIfExists(marker.toPath());
                throw error;
            }
            return target;
        } catch (NoSuchAlgorithmException error) {
            throw new IOException("SHA-256 unavailable", error);
        } finally {
            Files.deleteIfExists(part.toPath());
        }
    }
}
