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
import android.graphics.drawable.GradientDrawable;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.IBinder;
import android.text.InputType;
import android.util.TypedValue;
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
import java.io.File;
import java.util.List;

/** A status card, two controls and a raw terminal. No graphical GM operations are exposed. */
public class MainActivity extends Activity implements SaveAdapter.Actions, ServiceConnection {
    static final String PREFS = "manager";
    static final String KEY_AUTOSAVE = "autosave";
    static final String KEY_RUNNING = "server-running";
    private static final int REQUEST_EXPORT = 4001;
    private static final int REQUEST_IMPORT = 4002;
    private static final int REQUEST_NOTIFICATIONS = 4003;

    private TextView statusText;
    private TextView statusDetail;
    private GradientDrawable statusDot;
    private Button sendButton;
    private boolean toggleShowsStop;
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
        if (state != null) {
            commandInput.setText(state.getString("console-command", ""));
            Bundle selected = state.getBundle("pending-export-save");
            if (selected != null && selected.getString("path") != null) {
                pendingExportSave = new SaveStore.Save(new File(selected.getString("path")),
                        selected.getString("kind"), selected.getLong("created"), selected.getLong("bytes"));
            }
            exportTarget = state.getParcelable("export-target");
            importSource = state.getParcelable("import-source");
        }
        requestNotificationPermission();
    }

    @Override protected void onSaveInstanceState(Bundle state) {
        state.putString("console-command", commandInput.getText().toString());
        // The system document picker can outlive this activity/process. Keep
        // the exact selected file, including while waiting for service rebind.
        if (pendingExportSave != null) {
            Bundle selected = new Bundle();
            selected.putString("path", pendingExportSave.file.getAbsolutePath());
            selected.putString("kind", pendingExportSave.kind);
            selected.putLong("created", pendingExportSave.createdAt);
            selected.putLong("bytes", pendingExportSave.bytes);
            state.putBundle("pending-export-save", selected);
        }
        state.putParcelable("export-target", exportTarget);
        state.putParcelable("import-source", importSource);
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
        sendButton.setEnabled(false);
        toggleButton.setEnabled(false);
    }

    private LinearLayout buildContent() {
        LinearLayout root = Ui.column(this);
        root.setBackgroundColor(Ui.BG);
        int pad = Ui.dp(this, 16);
        root.setPadding(pad, pad, pad, pad);
        ProjectNotice.attach(this, root);

        TextView title = Ui.body(this, ManagerStrings.home_manager);
        title.setTextSize(TypedValue.COMPLEX_UNIT_SP, 22f);
        title.setTypeface(title.getTypeface(), Typeface.BOLD);
        Ui.topMargin(title, 10f, this);
        root.addView(title);
        TextView subtitle = Ui.meta(this, ManagerStrings.notif_text);
        Ui.topMargin(subtitle, 2f, this);
        root.addView(subtitle);

        // Status card: a coloured dot and phase, any detail, then the two actions.
        LinearLayout status = Ui.sectionCard(this);
        Ui.topMargin(status, 14f, this);
        LinearLayout phaseRow = Ui.row(this);
        phaseRow.setGravity(Gravity.CENTER_VERTICAL);
        statusDot = new GradientDrawable();
        statusDot.setShape(GradientDrawable.OVAL);
        statusDot.setColor(Ui.TEXT_SECONDARY);
        View dot = new View(this);
        dot.setBackground(statusDot);
        int dotSize = Ui.dp(this, 10);
        phaseRow.addView(dot, new LinearLayout.LayoutParams(dotSize, dotSize));
        statusText = Ui.cardTitle(this, ManagerStrings.state_stopped);
        statusText.setTextSize(TypedValue.COMPLEX_UNIT_SP, 17f);
        phaseRow.addView(statusText);
        Ui.leftMargin(statusText, 10f, this);
        status.addView(phaseRow);
        statusDetail = Ui.meta(this, "");
        statusDetail.setTextIsSelectable(true);
        statusDetail.setVisibility(View.GONE);
        status.addView(statusDetail);
        Ui.topMargin(statusDetail, 6f, this);

        LinearLayout actions = Ui.row(this);
        toggleButton = Ui.button(this, ManagerStrings.action_start_server);
        toggleButton.setEnabled(false);
        toggleButton.setOnClickListener(v -> ServerService.request(this, ServerService.ACTION_TOGGLE));
        actions.addView(toggleButton, new LinearLayout.LayoutParams(0, Ui.dp(this, 46), 1f));
        backupsButton = Ui.outlinedButton(this, ManagerStrings.action_backups);
        backupsButton.setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f);
        backupsButton.setOnClickListener(v -> showBackups());
        actions.addView(backupsButton, new LinearLayout.LayoutParams(0, Ui.dp(this, 46), 1f));
        Ui.leftMargin(backupsButton, 10f, this);
        status.addView(actions);
        Ui.topMargin(actions, 14f, this);
        root.addView(status);

        TextView logTitle = Ui.sectionTitle(this, ManagerStrings.section_log);
        Ui.margin(logTitle, 18f, 8f, this);
        root.addView(logTitle);

        // Console card: the log fills the rest of the screen, the prompt sits under it.
        LinearLayout console = Ui.column(this);
        GradientDrawable consoleBg = Ui.rounded(Ui.CONSOLE, 14f, this);
        consoleBg.setStroke(Ui.dp(this, 1), Ui.HAIRLINE);
        console.setBackground(consoleBg);
        int inner = Ui.dp(this, 12);
        console.setPadding(inner, inner, inner, Ui.dp(this, 6));
        root.addView(console, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f));

        terminal = new ScrollView(this);
        terminal.setFillViewport(true);
        logText = Ui.mono(this, "", 11.5f, 0xFFB8C0D0);
        logText.setHint(ManagerStrings.log_empty);
        logText.setHintTextColor(Ui.TEXT_SECONDARY);
        logText.setLineSpacing(0f, 1.15f);
        logText.setTextIsSelectable(true);
        terminal.addView(logText);
        console.addView(terminal, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f));

        View rule = new View(this);
        rule.setBackgroundColor(Ui.HAIRLINE);
        LinearLayout.LayoutParams ruleParams = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, Math.max(1, Ui.dp(this, 1)));
        ruleParams.topMargin = Ui.dp(this, 8);
        console.addView(rule, ruleParams);

        LinearLayout inputRow = Ui.row(this);
        inputRow.setGravity(Gravity.CENTER_VERTICAL);
        TextView prompt = Ui.mono(this, "›", 18f, Ui.ACCENT);
        prompt.setTypeface(Typeface.MONOSPACE, Typeface.BOLD);
        inputRow.addView(prompt);
        commandInput = new EditText(this);
        commandInput.setBackground(null);
        commandInput.setTypeface(Typeface.MONOSPACE);
        commandInput.setTextColor(Ui.TEXT_PRIMARY);
        commandInput.setHintTextColor(0xFF5C6478);
        commandInput.setHint(ManagerStrings.console_hint_idle);
        commandInput.setTextSize(13f);
        commandInput.setSingleLine(true);
        commandInput.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS
                | InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD);
        commandInput.setImeOptions(EditorInfo.IME_ACTION_SEND | EditorInfo.IME_FLAG_NO_EXTRACT_UI);
        commandInput.setEnabled(false);
        commandInput.setPadding(Ui.dp(this, 8), Ui.dp(this, 6), Ui.dp(this, 8), Ui.dp(this, 6));
        inputRow.addView(commandInput, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        commandInput.setOnEditorActionListener((view, action, event) -> {
            if (action == EditorInfo.IME_ACTION_SEND || (event != null
                    && event.getKeyCode() == KeyEvent.KEYCODE_ENTER && event.getAction() == KeyEvent.ACTION_DOWN)) {
                sendCommand();
                return true;
            }
            return event != null && event.getKeyCode() == KeyEvent.KEYCODE_ENTER;
        });
        sendButton = Ui.button(this, ManagerStrings.action_send);
        sendButton.setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f);
        Ui.tint(sendButton, Ui.ACCENT, 9f);
        sendButton.setMinWidth(0);
        sendButton.setMinimumWidth(0);
        sendButton.setPadding(Ui.dp(this, 14), 0, Ui.dp(this, 14), 0);
        sendButton.setEnabled(false);
        sendButton.setOnClickListener(v -> sendCommand());
        inputRow.addView(sendButton, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT, Ui.dp(this, 34)));
        console.addView(inputRow);
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
        int color;
        switch (phase) {
            case ServerService.PHASE_RUNNING: label = ManagerStrings.state_running; color = Ui.OK; break;
            case ServerService.PHASE_STARTING: label = ManagerStrings.state_starting; color = Ui.WARN; break;
            case ServerService.PHASE_STOPPING: label = ManagerStrings.state_stopping; color = Ui.WARN; break;
            case ServerService.PHASE_FAILED: label = ManagerStrings.state_failed; color = Ui.DANGER; break;
            default: label = ManagerStrings.state_stopped; color = Ui.TEXT_SECONDARY;
        }
        statusText.setText(label);
        statusDot.setColor(color);
        String detail = service.detail();
        statusDetail.setText(detail);
        statusDetail.setVisibility(detail.isEmpty() ? View.GONE : View.VISIBLE);
        if (running != toggleShowsStop) {
            toggleShowsStop = running;
            Ui.tint(toggleButton, running ? Ui.STOP : Ui.ACCENT, 12f);
        }
        toggleButton.setText(running ? ManagerStrings.action_stop_server : ManagerStrings.action_start_server);
        toggleButton.setEnabled(!busy);
        backupsButton.setEnabled(!busy);
        commandInput.setEnabled(running);
        sendButton.setEnabled(running);
        commandInput.setHint(running ? ManagerStrings.console_hint : ManagerStrings.console_hint_idle);
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
        LinearLayout secondary = Ui.row(this);
        Button importSave = Ui.outlinedButton(this, ManagerStrings.action_import);
        secondary.addView(importSave, new LinearLayout.LayoutParams(0, Ui.dp(this, 44), 1f));
        importSave.setOnClickListener(v -> pickImportSource());
        Button prune = Ui.outlinedButton(this, ManagerStrings.action_prune);
        secondary.addView(prune, new LinearLayout.LayoutParams(0, Ui.dp(this, 44), 1f));
        Ui.leftMargin(prune, 10f, this);
        prune.setOnClickListener(v -> confirmPrune());
        content.addView(secondary);
        Ui.topMargin(secondary, 10f, this);
        storageSummary = Ui.meta(this, "");
        content.addView(storageSummary);
        Ui.margin(storageSummary, 12f, 4f, this);
        savesEmpty = Ui.meta(this, ManagerStrings.saves_empty);
        content.addView(savesEmpty);
        savesList = new ListView(this);
        savesList.setDivider(new android.graphics.drawable.ColorDrawable(Color.TRANSPARENT));
        savesList.setDividerHeight(Ui.dp(this, 8));
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
        if (storageSummary != null) storageSummary.setText(service.store().storageSummary(saves));
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
