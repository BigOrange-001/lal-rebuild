package com.lal.rebuild.manager;

import android.app.Activity;
import android.os.Bundle;
import android.text.InputType;
import android.view.ViewGroup;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.RadioButton;
import android.widget.RadioGroup;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

/**
 * Edits llm.json beside the save database. The server re-reads the file when
 * it changes, so no restart is needed. The key stays in app-private storage;
 * save exports copy only the database, never this file.
 */
public class GuildAiSettingsActivity extends Activity {
    private static final String DEFAULT_OPENAI_URL = "https://api.deepseek.com";
    private static final String DEFAULT_OPENAI_MODEL = "deepseek-chat";
    private static final String DEFAULT_ANTHROPIC_URL = "https://api.anthropic.com";

    private RadioGroup protocol;
    private EditText baseUrl;
    private EditText model;
    private EditText apiKey;
    private CheckBox sendPlayerText;
    private TextView keyState;
    private JSONObject current = new JSONObject();

    static File settingsFile(Activity activity) {
        return new File(RuntimeInstaller.databaseFile(activity).getParentFile(), "llm.json");
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        current = read(settingsFile(this));
        setContentView(build());
    }

    private ScrollView build() {
        ScrollView scroll = new ScrollView(this);
        scroll.setBackgroundColor(Ui.BG);
        scroll.setFillViewport(true);
        LinearLayout root = Ui.column(this);
        int pad = Ui.dp(this, 20);
        root.setPadding(pad, pad, pad, pad);

        root.addView(Ui.sectionTitle(this, "公会 AI 对话设置"));
        TextView intro = Ui.meta(this, "填写你自己的大模型密钥后，公会里的 AI 成员会由模型安排发言和行动，并回应你在公会频道的发言。"
                + "不填写时使用内置台词，其他公会玩法照常可用。保存后立即生效。");
        Ui.topMargin(intro, 6f, this);
        root.addView(intro);

        LinearLayout card = Ui.sectionCard(this);
        Ui.topMargin(card, 16f, this);
        root.addView(card);

        card.addView(Ui.body(this, "接口协议"));
        protocol = new RadioGroup(this);
        protocol.setOrientation(RadioGroup.HORIZONTAL);
        RadioButton openai = radio("OpenAI 兼容（DeepSeek 等）", 1);
        RadioButton anthropic = radio("Anthropic", 2);
        protocol.addView(openai);
        protocol.addView(anthropic);
        protocol.check("anthropic".equals(current.optString("protocol")) ? 2 : 1);
        protocol.setOnCheckedChangeListener((group, id) -> fillDefaults(id == 2));
        card.addView(protocol);

        baseUrl = field(card, "服务器地址", current.optString("base_url", DEFAULT_OPENAI_URL),
                InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_URI);
        model = field(card, "模型名称", current.optString("model", DEFAULT_OPENAI_MODEL),
                InputType.TYPE_CLASS_TEXT);
        apiKey = field(card, "API Key", "",
                InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_PASSWORD);
        keyState = Ui.meta(this, keyStateText());
        Ui.topMargin(keyState, 4f, this);
        card.addView(keyState);

        sendPlayerText = new CheckBox(this);
        sendPlayerText.setText("把我在公会频道的发言发给模型（用于回复）");
        sendPlayerText.setTextColor(Ui.TEXT_PRIMARY);
        sendPlayerText.setChecked(current.optBoolean("send_player_messages", true));
        Ui.topMargin(sendPlayerText, 12f, this);
        card.addView(sendPlayerText);

        LinearLayout actions = Ui.row(this);
        Ui.topMargin(actions, 18f, this);
        android.widget.Button save = Ui.button(this, "保存");
        save.setLayoutParams(Ui.weighted(1f));
        save.setOnClickListener(view -> save(false));
        android.widget.Button clear = Ui.outlinedButton(this, "清除密钥");
        LinearLayout.LayoutParams clearParams = Ui.weighted(1f);
        clearParams.leftMargin = Ui.dp(this, 12);
        clear.setLayoutParams(clearParams);
        clear.setOnClickListener(view -> save(true));
        actions.addView(save);
        actions.addView(clear);
        root.addView(actions);

        TextView privacy = Ui.meta(this, "密钥只保存在本机的应用目录中，不会随导出的存档一起分享。"
                + "调用次数和用量有每日上限，费用由你的模型服务商收取。");
        Ui.topMargin(privacy, 16f, this);
        root.addView(privacy);

        scroll.addView(root);
        return scroll;
    }

    private RadioButton radio(String text, int id) {
        RadioButton button = new RadioButton(this);
        button.setId(id);
        button.setText(text);
        button.setTextColor(Ui.TEXT_PRIMARY);
        return button;
    }

    private EditText field(LinearLayout parent, String label, String value, int inputType) {
        TextView title = Ui.meta(this, label);
        Ui.topMargin(title, 12f, this);
        parent.addView(title);
        EditText input = new EditText(this);
        input.setSingleLine(true);
        input.setInputType(inputType);
        input.setText(value);
        input.setTextColor(Ui.TEXT_PRIMARY);
        input.setHintTextColor(Ui.TEXT_SECONDARY);
        input.setLayoutParams(new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        parent.addView(input);
        return input;
    }

    /** Switching protocol only replaces the address/model while they are still a known default. */
    private void fillDefaults(boolean anthropicSelected) {
        String url = baseUrl.getText().toString().trim();
        if (url.isEmpty() || url.equals(DEFAULT_OPENAI_URL) || url.equals(DEFAULT_ANTHROPIC_URL)) {
            baseUrl.setText(anthropicSelected ? DEFAULT_ANTHROPIC_URL : DEFAULT_OPENAI_URL);
        }
        String name = model.getText().toString().trim();
        if (name.isEmpty() || name.equals(DEFAULT_OPENAI_MODEL)) {
            model.setText(anthropicSelected ? "" : DEFAULT_OPENAI_MODEL);
        }
    }

    private String keyStateText() {
        return current.optString("api_key", "").trim().isEmpty()
                ? "当前未设置密钥：使用内置台词。"
                : "已设置密钥。留空保存会保留原密钥。";
    }

    private void save(boolean clearKey) {
        try {
            JSONObject next = new JSONObject(current.toString());
            next.put("enabled", true);
            next.put("protocol", protocol.getCheckedRadioButtonId() == 2 ? "anthropic" : "openai");
            next.put("base_url", baseUrl.getText().toString().trim());
            next.put("model", model.getText().toString().trim());
            next.put("send_player_messages", sendPlayerText.isChecked());
            String typed = apiKey.getText().toString().trim();
            if (clearKey) {
                next.put("api_key", "");
            } else if (!typed.isEmpty()) {
                next.put("api_key", typed);
            }
            write(settingsFile(this), next);
            current = next;
            apiKey.setText("");
            keyState.setText(keyStateText());
            Toast.makeText(this, clearKey ? "已清除密钥" : "已保存", Toast.LENGTH_SHORT).show();
        } catch (IOException | JSONException error) {
            Toast.makeText(this, "保存失败：" + error.getClass().getSimpleName(), Toast.LENGTH_LONG).show();
        }
    }

    private static JSONObject read(File file) {
        if (!file.isFile()) return new JSONObject();
        try (InputStream in = new FileInputStream(file)) {
            byte[] data = new byte[(int) Math.min(file.length(), 64 * 1024)];
            int total = 0;
            while (total < data.length) {
                int read = in.read(data, total, data.length - total);
                if (read < 0) break;
                total += read;
            }
            return new JSONObject(new String(data, 0, total, StandardCharsets.UTF_8));
        } catch (IOException | JSONException error) {
            return new JSONObject();
        }
    }

    /** Write beside the target, then rename, so the server never reads half a file. */
    private static void write(File file, JSONObject value) throws IOException, JSONException {
        File temp = new File(file.getParentFile(), file.getName() + ".tmp");
        try (FileOutputStream out = new FileOutputStream(temp)) {
            out.write(value.toString(2).getBytes(StandardCharsets.UTF_8));
            out.getFD().sync();
        }
        if (!temp.renameTo(file)) {
            temp.delete();
            throw new IOException("rename failed");
        }
    }
}
