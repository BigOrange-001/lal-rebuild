package com.lal.rebuild.manager;

import android.content.Context;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.graphics.drawable.ShapeDrawable;
import android.graphics.drawable.shapes.OvalShape;
import android.util.TypedValue;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.TextView;

/**
 * Programmatic stand-ins for the manager's former XML resources.
 *
 * <p>The merged APK keeps the AIR client's single {@code resources.arsc}, so
 * this module cannot ship a {@code res/} tree at all. Everything the old
 * {@code res/values/colors.xml}, {@code res/values/themes.xml},
 * {@code res/layout/activity_main.xml} and {@code res/layout/item_save.xml}
 * described is expressed here in code instead — the colours and paddings are
 * copied verbatim from those files so the screen looks the same.
 */
final class Ui {

    private Ui() {
    }

    // ------------------------------------------------------------------ palette
    // From the old res/values/colors.xml.
    static final int BG = 0xFF11131A;
    static final int SURFACE = 0xFF1B1F2A;
    static final int SURFACE_ALT = 0xFF232838;
    static final int ACCENT = 0xFF4C8DFF;
    static final int TEXT_PRIMARY = 0xFFEDEFF5;
    static final int TEXT_SECONDARY = 0xFF9AA3B8;
    static final int OK = 0xFF3DD68C;
    static final int WARN = 0xFFFFC14D;
    static final int DANGER = 0xFFFF6B6B;

    static int dp(Context context, float value) {
        return Math.round(TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value,
                context.getResources().getDisplayMetrics()));
    }

    private static int sp(Context context, float value) {
        return Math.round(TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_SP, value,
                context.getResources().getDisplayMetrics()));
    }

    // ------------------------------------------------------------------ drawing
    /** A filled, optionally rounded rectangle. Replaces the drawable XMLs. */
    static GradientDrawable rounded(int color, float radiusDp, Context context) {
        GradientDrawable shape = new GradientDrawable();
        shape.setShape(GradientDrawable.RECTANGLE);
        shape.setColor(color);
        shape.setCornerRadius(dp(context, radiusDp));
        return shape;
    }

    static GradientDrawable outlined(Context context, float radiusDp, int strokeColor) {
        GradientDrawable shape = rounded(Color.TRANSPARENT, radiusDp, context);
        shape.setStroke(dp(context, 1.5f), strokeColor);
        return shape;
    }

    /** The round status indicator; the four old status_dot_*.xml as one shape. */
    static ShapeDrawable dot(Context context, int color, float sizeDp) {
        ShapeDrawable shape = new ShapeDrawable(new OvalShape());
        shape.getPaint().setColor(color);
        int size = dp(context, sizeDp);
        shape.setIntrinsicWidth(size);
        shape.setIntrinsicHeight(size);
        return shape;
    }

    // ------------------------------------------------------------------ factory
    static LinearLayout column(Context context) {
        LinearLayout layout = new LinearLayout(context);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setLayoutParams(new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        return layout;
    }

    static LinearLayout row(Context context) {
        LinearLayout layout = new LinearLayout(context);
        layout.setOrientation(LinearLayout.HORIZONTAL);
        layout.setLayoutParams(new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        return layout;
    }

    /** A MaterialCardView stand-in: a rounded surface panel with 16dp of padding. */
    static LinearLayout card(Context context, int background, float radiusDp) {
        LinearLayout card = new LinearLayout(context);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setBackground(rounded(background, radiusDp, context));
        int pad = dp(context, 16);
        card.setPadding(pad, pad, pad, pad);
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        card.setLayoutParams(params);
        return card;
    }

    static LinearLayout sectionCard(Context context) {
        return card(context, SURFACE, 14f);
    }

    /** The small all-caps-ish heading above each card. */
    static TextView sectionTitle(Context context, String text) {
        TextView view = new TextView(context);
        view.setText(text);
        view.setTextColor(TEXT_SECONDARY);
        view.setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f);
        view.setTypeface(view.getTypeface(), android.graphics.Typeface.BOLD);
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        params.topMargin = dp(context, 22);
        params.bottomMargin = dp(context, 8);
        view.setLayoutParams(params);
        return view;
    }

    static TextView body(Context context, String text) {
        TextView view = new TextView(context);
        view.setText(text);
        view.setTextColor(TEXT_PRIMARY);
        view.setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f);
        return view;
    }

    /** The old {@code @style/CardMeta}: 12sp secondary text. */
    static TextView meta(Context context, String text) {
        TextView view = new TextView(context);
        view.setText(text);
        view.setTextColor(TEXT_SECONDARY);
        view.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f);
        return view;
    }

    static TextView mono(Context context, String text, float sizeSp, int color) {
        TextView view = new TextView(context);
        view.setText(text);
        view.setTextColor(color);
        view.setTextSize(TypedValue.COMPLEX_UNIT_SP, sizeSp);
        view.setTypeface(android.graphics.Typeface.MONOSPACE);
        return view;
    }

    /** The old {@code @style/CardTitle}: 15sp bold primary text. */
    static TextView cardTitle(Context context, String text) {
        TextView view = new TextView(context);
        view.setText(text);
        view.setTextColor(TEXT_PRIMARY);
        view.setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f);
        view.setTypeface(view.getTypeface(), android.graphics.Typeface.BOLD);
        return view;
    }

    static android.widget.Button button(Context context, String text) {
        android.widget.Button button = new android.widget.Button(context);
        button.setText(text);
        button.setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f);
        button.setAllCaps(false);
        button.setBackground(rounded(ACCENT, 12f, context));
        button.setTextColor(Color.WHITE);
        return button;
    }

    /** A secondary action: transparent fill with a thin accent border. */
    static android.widget.Button outlinedButton(Context context, String text) {
        android.widget.Button button = new android.widget.Button(context);
        button.setText(text);
        button.setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f);
        button.setAllCaps(false);
        button.setBackground(outlined(context, 10f, 0xFF2E5AA8));
        button.setTextColor(TEXT_PRIMARY);
        return button;
    }

    /** A row action inside the save list: flat, coloured text only. */
    static android.widget.Button textButton(Context context, String text, int color, float sizeSp) {
        android.widget.Button button = new android.widget.Button(context);
        button.setText(text);
        button.setTextSize(TypedValue.COMPLEX_UNIT_SP, sizeSp);
        button.setAllCaps(false);
        button.setTextColor(color);
        button.setBackgroundColor(Color.TRANSPARENT);
        button.setMinWidth(0);
        button.setMinimumWidth(0);
        button.setPadding(0, 0, 0, 0);
        return button;
    }

    /** Gives a view equal share of a horizontal {@link LinearLayout}. */
    static LinearLayout.LayoutParams weighted(float weight) {
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.WRAP_CONTENT, weight);
        return params;
    }

    static void margin(View view, float topDp, float bottomDp, Context context) {
        ViewGroup.LayoutParams raw = view.getLayoutParams();
        if (!(raw instanceof LinearLayout.LayoutParams)) {
            return;
        }
        LinearLayout.LayoutParams params = (LinearLayout.LayoutParams) raw;
        params.topMargin = dp(context, topDp);
        params.bottomMargin = dp(context, bottomDp);
        view.setLayoutParams(params);
    }

    static void topMargin(View view, float topDp, Context context) {
        margin(view, topDp, 0f, context);
    }

    static void leftMargin(View view, float leftDp, Context context) {
        ViewGroup.LayoutParams raw = view.getLayoutParams();
        if (!(raw instanceof LinearLayout.LayoutParams)) {
            return;
        }
        LinearLayout.LayoutParams params = (LinearLayout.LayoutParams) raw;
        params.leftMargin = dp(context, leftDp);
        params.setMarginStart(dp(context, leftDp));
        view.setLayoutParams(params);
    }
}
