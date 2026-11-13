package com.lal.rebuild.manager;

import android.app.Activity;
import android.graphics.Color;
import android.util.Base64;
import android.widget.LinearLayout;
import android.widget.TextView;
import java.nio.charset.StandardCharsets;

final class ProjectNotice {
    private ProjectNotice() {}
    static String text() {
        byte[] value = Base64.decode("tewhQ2Zd5oWVvdseSklB46bNtc4uUWhY7pTFhMUMVmp/9JbPgz4FWG558J/piDAGJ11C/aP8kg4pwgG/g9TZ83wMV6huQw4sGvbSt+VLQDIr9f9Va255Wj8Y9piQ855/RzgY6ImnjpM0ejwVwN6oiGRFEGpHpZ6iimQIMDoe7N+/lAfP4eZnACc8SLLJ1MZuKXE0aKbc5cNvEXUFZZjW6v94An0Ar6rb08N8Mk8KpZis3Pw=", Base64.DEFAULT);
        for (int i = 0; i < value.length; i++) value[i] = (byte)(value[i] ^ ((i * 29 + 83) & 255));
        return new String(value, StandardCharsets.UTF_8);
    }
    static void attach(Activity activity, LinearLayout parent) {
        TextView view = new TextView(activity);
        view.setText(text());
        view.setTextColor(Color.rgb(255, 209, 102));
        view.setTextSize(12f);
        view.setTextIsSelectable(true);
        int pad = Ui.dp(activity, 8);
        view.setPadding(pad, pad, pad, pad);
        view.setBackgroundColor(Color.rgb(30, 35, 45));
        parent.addView(view, new LinearLayout.LayoutParams(-1, -2));
    }
}
