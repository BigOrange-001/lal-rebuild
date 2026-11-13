package com.lal.rebuild.manager;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;
import android.view.Gravity;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import java.io.File;
import java.io.InputStream;

/** Android SAF owns the URI grant; AIR never turns the document into a filesystem path. */
public final class ModImportActivity extends Activity {
    private static final int PICK_HERO = 9201;
    private volatile boolean cancelled;
    private volatile InputStream activeInput;
    private boolean copying;
    private String selectedUri;

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setGravity(Gravity.CENTER);
        layout.setPadding(32, 32, 32, 32);
        layout.setBackgroundColor(0xff171e2b);
        TextView text = new TextView(this);
        text.setText("导入英雄包\n请选择 .heropack 文件");
        text.setTextColor(0xfff4d693);
        text.setTextSize(20);
        text.setGravity(Gravity.CENTER);
        layout.addView(text);
        layout.addView(new ProgressBar(this));
        setContentView(layout);
        if (state != null) {
            selectedUri = state.getString("selectedUri");
            if (selectedUri != null) { copyDocument(Uri.parse(selectedUri)); return; }
            if (state.getBoolean("pickerStarted")) return;
        }
        try {
            Intent picker = new Intent(Intent.ACTION_OPEN_DOCUMENT)
                    .addCategory(Intent.CATEGORY_OPENABLE)
                    .setType("*/*")
                    .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
            startActivityForResult(picker, PICK_HERO);
        } catch (Exception error) { showFailure(error); }
    }

    @Override protected void onSaveInstanceState(Bundle state) {
        super.onSaveInstanceState(state);
        state.putBoolean("pickerStarted", true);
        state.putString("selectedUri", selectedUri);
    }

    @Override protected void onActivityResult(int request, int result, Intent data) {
        super.onActivityResult(request, result, data);
        if (request != PICK_HERO) return;
        if (result != RESULT_OK || data == null || data.getData() == null) { finish(); return; }
        Uri uri = data.getData();
        if (!"content".equals(uri.getScheme())) {
            showFailure(new java.io.IOException("系统未返回授权的文档地址。")); return;
        }
        selectedUri = uri.toString();
        copyDocument(uri);
    }

    private void copyDocument(Uri uri) {
        if (copying) return;
        copying = true;
        new Thread(() -> {
            try (InputStream input = getContentResolver().openInputStream(uri)) {
                activeInput = input;
                // gateway.Backend uses database.parent/mods. The phone database
                // is filesDir/state/local.sqlite3; runtime files are separate.
                File inbox = new File(RuntimeInstaller.dataDir(this), "mods/inbox");
                HeroPackageInbox.copy(input, inbox, () -> cancelled);
                runOnUiThread(() -> { if (!cancelled && !isDestroyed()) finish(); });
            } catch (Exception error) {
                Log.e("HeroPackImport", "Document import failed", error);
                runOnUiThread(() -> { if (!cancelled && !isDestroyed()) showFailure(error); });
            } finally { activeInput = null; }
        }, "hero-package-import").start();
    }

    private void showFailure(Exception error) {
        copying = false;
        String message = error.getMessage();
        new AlertDialog.Builder(this).setTitle("英雄包读取失败")
                .setMessage(error.getClass().getSimpleName() + "：" + (message == null ? "未知原因" : message))
                .setPositiveButton("返回游戏", (dialog, which) -> finish())
                .setOnCancelListener(dialog -> finish()).show();
    }

    @Override public void onBackPressed() {
        cancelled = true;
        finish();
    }

    @Override protected void onDestroy() {
        cancelled = true;
        InputStream input = activeInput;
        if (input != null) {
            new Thread(() -> { try { input.close(); } catch (Exception ignored) { } }, "hero-import-cancel").start();
        }
        super.onDestroy();
    }
}
