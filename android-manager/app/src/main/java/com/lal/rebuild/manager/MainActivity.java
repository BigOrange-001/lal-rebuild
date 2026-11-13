package com.lal.rebuild.manager;

import android.Manifest;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.ServiceConnection;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.graphics.Typeface;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.IBinder;
import android.text.InputType;
import android.view.Gravity;
import android.view.KeyEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.inputmethod.EditorInfo;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

import java.io.InputStream;
import java.io.OutputStream;
import java.util.List;

/** Two controls and a raw terminal. No graphical GM operations are exposed. */
public class MainActivity extends Activity implements SaveAdapter.Actions, ServiceConnection {
    static final String PREFS = "manager";
    static final String KEY_AUTOSAVE = "autosave";
    static final String KEY_RUNNING = "server-running";
    private static final int REQUEST_EXPORT = 4001;
    private static final int REQUEST_IMPORT = 4002;
    private static final int REQUEST_NOTIFICATIONS = 4003;

    private TextView statusText;
    private TextView logText;
    private ScrollView terminal;
    private EditText commandInput;
    private Button toggleButton;
    private Button backupsButton;
    private TextView savesEmpty;
    private TextView storageSummary;
    private ListView savesList;
    private SaveAdapter adapter;
    private ServerService service;
    private boolean bound;
    private AlertDialog savesDialog;
    private String renderedLog = "";
    private SaveStore.Save pendingExportSave;
    private SaveStore.Save pendingRestore;
    private SaveStore.Save pendingDelete;
    private Uri exportTarget;
    private Uri importSource;

    private final BroadcastReceiver stateReceiver = new BroadcastReceiver() {
        @Override public void onReceive(Context context, Intent intent) { render(); }
    };

    @Override protected void onCreate(Bundle state) {
        super.onCreate(state);
        setContentView(buildContent());
        adapter = new SaveAdapter(this);
        if (state != null) commandInput.setText(state.getString("console-command", ""));
        requestNotificationPermission();
    }

    @Override protected void onSaveInstanceState(Bundle state) {
        state.putString("console-command", commandInput.getText().toString());
        super.onSaveInstanceState(state);
    }

    @Override protected void onStart() {
        super.onStart();
        IntentFilter filter = new IntentFilter(ServerService.ACTION_STATE);
        if (Build.VERSION.SDK_INT >= 33) registerReceiver(stateReceiver, filter, Context.RECEIVER_NOT_EXPORTED);
        else registerReceiver(stateReceiver, filter);
        bound = bindService(new Intent(this, ServerService.class), this, Context.BIND_AUTO_CREATE);
    }

    @Override protected void onStop() {
        unregisterReceiver(stateReceiver);
        if (bound) { unbindService(this); bound = false; }
        service = null;
        super.onStop();
    }

    @Override protected void onDestroy() {
        if (savesDialog != null) savesDialog.dismiss();
        super.onDestroy();
    }

    @Override public void onServiceConnected(ComponentName name, IBinder binder) {
        service = ((ServerService.LocalBinder) binder).service();
        render();
        finishStorageResult();
    }

    @Override public void onServiceDisconnected(ComponentName name) {
        service = null;
        commandInput.setEnabled(false);
        toggleButton.setEnabled(false);
    }

    private LinearLayout buildContent() {
        LinearLayout root = Ui.column(this);
        root.setBackgroundColor(Color.BLACK);
        int pad = Ui.dp(this, 12);
        root.setPadding(pad, pad, pad, pad);
        ProjectNotice.attach(this, root);
        toggleButton = Ui.button(this, ManagerStrings.action_start_server);
        root.addView(toggleButton, fixedHeight(50));
        toggleButton.setEnabled(false);
        toggleButton.setOnClickListener(v -> ServerService.request(this, ServerService.ACTION_TOGGLE));
        backupsButton = Ui.outlinedButton(this, ManagerStrings.action_backups);
        root.addView(backupsButton, fixedHeight(48));
        backupsButton.setOnClickListener(v -> showBackups());
        statusText = Ui.mono(this, ManagerStrings.state_stopped, 12f, Color.LTGRAY);
        statusText.setPadding(0, pad, 0, pad);
        root.addView(statusText);

        terminal = new ScrollView(this);
        terminal.setFillViewport(true);
        logText = Ui.mono(this, "", 12f, Color.LTGRAY);
        logText.setTextIsSelectable(true);
        terminal.addView(logText);
        root.addView(terminal, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f));

        LinearLayout inputRow = Ui.row(this);
        inputRow.setGravity(Gravity.CENTER_VERTICAL);
        inputRow.addView(Ui.mono(this, "server> ", 13f, Color.LTGRAY));
        commandInput = new EditText(this);
        commandInput.setTypeface(Typeface.MONOSPACE);
        commandInput.setTextColor(Color.WHITE);
        commandInput.setTextSize(13f);
        commandInput.setSingleLine(true);
        commandInput.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS
                | InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD);
        commandInput.setImeOptions(EditorInfo.IME_ACTION_SEND | EditorInfo.IME_FLAG_NO_EXTRACT_UI);
        commandInput.setEnabled(false);
        inputRow.addView(commandInput, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        commandInput.setOnEditorActionListener((view, action, event) -> {
            if (action == EditorInfo.IME_ACTION_SEND || (event != null
                    && event.getKeyCode() == KeyEvent.KEYCODE_ENTER && event.getAction() == KeyEvent.ACTION_DOWN)) {
                sendCommand();
                return true;
            }
            return event != null && event.getKeyCode() == KeyEvent.KEYCODE_ENTER;
        });
        root.addView(inputRow);
        return root;
    }

    private LinearLayout.LayoutParams fixedHeight(int dp) {
        return new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, Ui.dp(this, dp));
    }

    private void sendCommand() {
        String line = commandInput.getText().toString().trim();
        if (!line.isEmpty() && service != null && service.executeCommand(line)) commandInput.setText("");
    }

    private void render() {
        if (service == null) return;
        String phase = service.phase();
        boolean running = ServerService.PHASE_RUNNING.equals(phase);
        boolean busy = ServerService.PHASE_STARTING.equals(phase) || ServerService.PHASE_STOPPING.equals(phase);
        String label;
        switch (phase) {
            case ServerService.PHASE_RUNNING: label = ManagerStrings.state_running; break;
            case ServerService.PHASE_STARTING: label = ManagerStrings.state_starting; break;
            case ServerService.PHASE_STOPPING: label = ManagerStrings.state_stopping; break;
            case ServerService.PHASE_FAILED: label = ManagerStrings.state_failed; break;
            default: label = ManagerStrings.state_stopped;
        }
        statusText.setText(label + (service.detail().isEmpty() ? "" : "\n" + service.detail()));
        toggleButton.setText(running ? ManagerStrings.action_stop_server : ManagerStrings.action_start_server);
        toggleButton.setEnabled(!busy);
        backupsButton.setEnabled(!busy);
        commandInput.setEnabled(running);
        String output = join(service.log());
        if (!output.equals(renderedLog)) {
            boolean atBottom = !terminal.canScrollVertically(1);
            renderedLog = output;
            logText.setText(output);
            if (atBottom) terminal.post(() -> terminal.fullScroll(View.FOCUS_DOWN));
        }
        refreshSaves();
    }

    private static String join(List<String> lines) {
        StringBuilder text = new StringBuilder();
        for (String line : lines) { if (text.length() != 0) text.append('\n'); text.append(line); }
        return text.toString();
    }

    private void showBackups() {
        if (service == null) return;
        LinearLayout content = Ui.column(this);
        int pad = Ui.dp(this, 12);
        content.setPadding(pad, pad, pad, pad);
        Button capture = Ui.button(this, ManagerStrings.action_save_now);
        content.addView(capture, fixedHeight(48));
        capture.setOnClickListener(v -> { if (service != null) service.saveNow(); });
        Button importSave = Ui.outlinedButton(this, ManagerStrings.action_import);
        content.addView(importSave, fixedHeight(48));
        importSave.setOnClickListener(v -> pickImportSource());
        Button prune = Ui.outlinedButton(this, ManagerStrings.action_prune);
        content.addView(prune, fixedHeight(48));
        prune.setOnClickListener(v -> confirmPrune());
        storageSummary = Ui.meta(this, "");
        content.addView(storageSummary);
        savesEmpty = Ui.meta(this, ManagerStrings.saves_empty);
        content.addView(savesEmpty);
        savesList = new ListView(this);
        savesList.setAdapter(adapter);
        content.addView(savesList, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT,
                Ui.dp(this, 280)));
        savesDialog = new AlertDialog.Builder(this).setTitle(ManagerStrings.action_backups)
                .setView(content).setNegativeButton(android.R.string.cancel, null).create();
        savesDialog.setOnDismissListener(d -> { savesDialog = null; savesList = null; savesEmpty = null; storageSummary = null; });
        refreshSaves();
        savesDialog.show();
    }

    private void refreshSaves() {
        if (service == null || savesList == null) return;
        List<SaveStore.Save> saves = service.store().list();
        adapter.submit(saves);
        if (storageSummary != null) storageSummary.setText(service.store().storageSummary());
        savesEmpty.setVisibility(saves.isEmpty() ? View.VISIBLE : View.GONE);
    }

    private boolean serverStopped() {
        return service != null && (ServerService.PHASE_STOPPED.equals(service.phase())
                || ServerService.PHASE_FAILED.equals(service.phase()));
    }

    private interface SaveWork { void run(ServerService owner) throws Exception; }

    private void submit(String label, SaveWork work) {
        ServerService owner = service;
        if (owner != null) owner.submit(label, () -> work.run(owner));
    }

    @Override
    public void onRestore(SaveStore.Save save) {
        pendingRestore = save;
        new AlertDialog.Builder(this)
                .setTitle(ManagerStrings.confirm_restore_title)
                .setMessage(ManagerStrings.confirm_restore_msg)
                .setNegativeButton(android.R.string.cancel, (dialog, which) -> pendingRestore = null)
                .setPositiveButton(ManagerStrings.action_restore, (dialog, which) -> {
                    SaveStore.Save target = pendingRestore;
                    pendingRestore = null;
                    if (target == null || service == null) {
                        return;
                    }
                    if (!serverStopped()) {
                        // The database cannot be swapped under a live server.
                        toast("请先停止服务器，再恢复存档。");
                        return;
                    }
                    submit("恢复存档", owner -> owner.store().restore(target, owner.bridge()));
                })
                .show();
    }

    @Override
    public void onExport(SaveStore.Save save) {
        pendingExportSave = save;
        Intent intent = new Intent(Intent.ACTION_CREATE_DOCUMENT)
                .addCategory(Intent.CATEGORY_OPENABLE)
                .setType(save.file.getName().endsWith(".gz") ? "application/gzip" : "application/vnd.sqlite3")
                .putExtra(Intent.EXTRA_TITLE,
                        service == null ? "lal-save.sqlite3" : service.store().exportName(save));
        startActivityForResult(intent, REQUEST_EXPORT);
    }

    @Override
    public void onDelete(SaveStore.Save save) {
        pendingDelete = save;
        new AlertDialog.Builder(this)
                .setTitle(ManagerStrings.confirm_delete_title)
                .setMessage(ManagerStrings.confirm_delete_msg)
                .setNegativeButton(android.R.string.cancel, (dialog, which) -> pendingDelete = null)
                .setPositiveButton(ManagerStrings.action_delete, (dialog, which) -> {
                    SaveStore.Save target = pendingDelete;
                    pendingDelete = null;
                    if (target == null || service == null) {
                        return;
                    }
                    submit("删除存档", owner -> owner.store().delete(target));
                })
                .show();
    }

    /**
     * Clears the live database so the next launch starts a new game. The server
     * must be stopped first: SQLite holds the file open, and deleting a file
     * that is in use fails on most devices.
     */
    @Override
    public void onReset(SaveStore.Save save) {
        if (service == null) {
            return;
        }
        if (!serverStopped()) {
            toast("请先停止服务器，再重开游戏。");
            return;
        }
        new AlertDialog.Builder(this)
                .setTitle(ManagerStrings.confirm_reset_title)
                .setMessage(ManagerStrings.confirm_reset_msg)
                .setNegativeButton(android.R.string.cancel, null)
                .setPositiveButton(ManagerStrings.action_reset, (dialog, which) -> {
                    submit("重开游戏", owner -> owner.store().reset());
                })
                .show();
    }

    private void confirmPrune() {
        if (service == null) {
            return;
        }
        new AlertDialog.Builder(this)
                .setTitle(ManagerStrings.confirm_prune_title)
                .setMessage(ManagerStrings.confirm_prune_msg)
                .setPositiveButton(android.R.string.ok, (dialog, which) ->
                        submit("清理旧存档", owner -> owner.store().prune()))
                .show();
    }

    // ------------------------------------------------------------------
    // Storage results
    // ------------------------------------------------------------------

    /** The old {@code ActivityResultContracts.OpenDocument} path. */
    private void pickImportSource() {
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT)
                .addCategory(Intent.CATEGORY_OPENABLE)
                .setType("*/*");
        startActivityForResult(intent, REQUEST_IMPORT);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == REQUEST_NOTIFICATIONS) {
            // The server runs regardless; only its notification is lost.
            return;
        }
        Uri target = data == null ? null : data.getData();
        if (requestCode == REQUEST_EXPORT) {
            exportTarget = resultCode == RESULT_OK ? target : null;
            if (exportTarget == null) pendingExportSave = null;
        } else if (requestCode == REQUEST_IMPORT) {
            importSource = resultCode == RESULT_OK ? target : null;
        }
        finishStorageResult();
    }

    /** The document picker may return before the asynchronous service rebind. */
    private void finishStorageResult() {
        if (service == null) return;
        Uri exported = exportTarget;
        exportTarget = null;
        if (exported != null) onExportTargetChosen(exported);
        Uri imported = importSource;
        importSource = null;
        if (imported != null) onImportSourceChosen(imported);
    }

    private void onExportTargetChosen(Uri target) {
        SaveStore.Save save = pendingExportSave;
        pendingExportSave = null;
        if (target == null || save == null || service == null) {
            return;
        }
        submit("导出存档", owner -> {
            try (OutputStream output = getContentResolver().openOutputStream(target, "wt")) {
                if (output == null) {
                    throw new java.io.IOException("无法写入所选位置。");
                }
                owner.store().export(save, output);
            }
        });
    }

    private void onImportSourceChosen(Uri source) {
        if (source == null || service == null) {
            return;
        }
        if (!serverStopped()) {
            toast("请先停止服务器，再导入存档。");
            return;
        }
        submit("导入存档", owner -> {
            try (InputStream input = getContentResolver().openInputStream(source)) {
                if (input == null) {
                    throw new java.io.IOException("无法读取所选文件。");
                }
                owner.store().importFrom(input, owner.bridge());
            }
        });
    }

    private void requestNotificationPermission() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return;
        }
        if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)
                == PackageManager.PERMISSION_GRANTED) {
            return;
        }
        requestPermissions(new String[]{Manifest.permission.POST_NOTIFICATIONS},
                REQUEST_NOTIFICATIONS);
    }

    private void toast(String message) {
        Toast.makeText(this, message, Toast.LENGTH_SHORT).show();
    }

    static Intent serviceIntent(Context context, String action) {
        return new Intent(context, ServerService.class).setAction(action);
    }
}
