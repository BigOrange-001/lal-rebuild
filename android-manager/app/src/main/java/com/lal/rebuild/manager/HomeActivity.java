package com.lal.rebuild.manager;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Intent;
import android.os.Bundle;
import android.view.Gravity;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

/**
 * The merged APK's only launcher entry: two buttons, one for the game and one
 * for the manager pages.
 *
 * <p>This activity exists purely to split one icon into two destinations. The
 * AIR client's own entry point keeps every attribute it had — it is still the
 * activity that loads {@code MainLLOL.swf} — but its {@code MAIN}/{@code LAUNCHER}
 * filter moved here, so the merged app presents a single launcher icon and the
 * player picks a destination from inside.
 */
public class HomeActivity extends Activity {

    /** The AIR client's entry point, named by string because its class is in the other dex. */
    private static final String GAME_ACTIVITY = "air.com.meng52.lol.android.AIRAppEntry";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(buildContent());
    }

    private ScrollView buildContent() {
        ScrollView scroll = new ScrollView(this);
        scroll.setBackgroundColor(Ui.BG);
        scroll.setFillViewport(true);

        LinearLayout root = Ui.column(this);
        int pad = Ui.dp(this, 20);
        root.setPadding(pad, pad, pad, pad);
        ProjectNotice.attach(this, root);

        TextView title = new TextView(this);
        title.setText(ManagerStrings.home_title);
        title.setTextColor(Ui.TEXT_PRIMARY);
        title.setTextSize(android.util.TypedValue.COMPLEX_UNIT_SP, 26f);
        title.setTypeface(title.getTypeface(), android.graphics.Typeface.BOLD);
        root.addView(title);

        TextView subtitle = Ui.meta(this, ManagerStrings.home_subtitle);
        Ui.topMargin(subtitle, 4f, this);
        root.addView(subtitle);

        root.addView(entry(
                ManagerStrings.home_play,
                ManagerStrings.home_play_desc,
                view -> launchGame()));

        root.addView(entry(
                ManagerStrings.home_manager,
                ManagerStrings.home_manager_desc,
                view -> startActivity(new Intent(this, MainActivity.class))));

        TextView note = Ui.meta(this, ManagerStrings.footer_note);
        Ui.topMargin(note, 24f, this);
        root.addView(note);

        scroll.addView(root);
        return scroll;
    }

    /** Starts the AIR entry point inside this same package. */
    private void launchGame() {
        Intent intent = new Intent()
                .setComponent(new ComponentName(this, GAME_ACTIVITY))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        startActivity(intent);
    }

    /** One tappable card: a bold title with a one-line description under it. */
    private LinearLayout entry(String name, String description, ViewGroup.OnClickListener tap) {
        LinearLayout card = Ui.card(this, Ui.SURFACE, 14f);
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        params.topMargin = Ui.dp(this, 16);
        card.setLayoutParams(params);
        card.setMinimumHeight(Ui.dp(this, 76));
        card.setGravity(Gravity.CENTER_VERTICAL);
        card.setClickable(true);
        card.setFocusable(true);

        TextView label = Ui.body(this, name);
        label.setTextSize(android.util.TypedValue.COMPLEX_UNIT_SP, 18f);
        label.setTypeface(label.getTypeface(), android.graphics.Typeface.BOLD);
        card.addView(label);

        TextView hint = Ui.meta(this, description);
        Ui.topMargin(hint, 3f, this);
        card.addView(hint);

        card.setOnClickListener(tap);
        return card;
    }
}
