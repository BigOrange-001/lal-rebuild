package com.lal.rebuild.manager;

import android.content.Context;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;

import java.util.ArrayList;
import java.util.List;

/**
 * Renders the save list; each row carries its own restore/export/delete actions.
 *
 * <p>A {@link BaseAdapter} over a {@link android.widget.ListView}, not the
 * RecyclerView this used to be. The merged APK preserves the AIR client's one
 * resource table, so the module cannot ship {@code res/layout/item_save.xml} or
 * the {@code com.google.android.material.button.MaterialButton} the rows used;
 * both are built in code instead. {@link #getView} follows the usual
 * convertView-recycling contract, which is what ListView relies on and what the
 * old {@code onCreateViewHolder}/{@code onBindViewHolder} pair implied.
 */
final class SaveAdapter extends BaseAdapter {

    interface Actions {
        void onRestore(SaveStore.Save save);

        void onExport(SaveStore.Save save);

        void onDelete(SaveStore.Save save);

        /** Clears the live database so the next launch starts a new game. */
        void onReset(SaveStore.Save save);
    }

    private final List<SaveStore.Save> items = new ArrayList<>();
    private final Actions actions;

    SaveAdapter(Actions actions) {
        this.actions = actions;
    }

    void submit(List<SaveStore.Save> saves) {
        items.clear();
        items.addAll(saves);
        notifyDataSetChanged();
    }

    @Override
    public int getCount() {
        return items.size();
    }

    @Override
    public SaveStore.Save getItem(int position) {
        return items.get(position);
    }

    @Override
    public long getItemId(int position) {
        return items.get(position).file.getName().hashCode();
    }

    @Override
    public boolean hasStableIds() {
        return true;
    }

    @Override
    public View getView(int position, View recycled, ViewGroup parent) {
        Context context = parent.getContext();
        Row row = recycled instanceof RowHolder ? ((RowHolder) recycled).row : null;
        if (row == null) {
            row = new Row(context);
        }

        SaveStore.Save save = items.get(position);
        row.name.setText(labelFor(save.kind));
        row.meta.setText(save.label());

        // The live row is reset-only: it cannot be deleted (it *is* the game),
        // exported (its own file is already in the app's storage) or restored
        // onto itself. Its third button is repurposed as 重开.
        boolean live = save.isLive();
        row.restore.setVisibility(live ? View.GONE : View.VISIBLE);
        row.export.setVisibility(live ? View.GONE : View.VISIBLE);
        row.delete.setText(live ? ManagerStrings.action_reset : ManagerStrings.action_delete);

        row.restore.setOnClickListener(view -> actions.onRestore(save));
        row.export.setOnClickListener(view -> actions.onExport(save));
        row.delete.setOnClickListener(view -> {
            if (live) {
                actions.onReset(save);
            } else {
                actions.onDelete(save);
            }
        });
        return row.root;
    }

    static String labelFor(String kind) {
        switch (kind) {
            case SaveStore.KIND_AUTO:
                return ManagerStrings.kind_auto;
            case SaveStore.KIND_IMPORTED:
                return ManagerStrings.kind_imported;
            case SaveStore.KIND_LIVE:
                return ManagerStrings.kind_live;
            default:
                return ManagerStrings.kind_manual;
        }
    }

    /** Wraps the row's root so ListView's recycling can hand it back to us. */
    private static final class RowHolder extends LinearLayout {
        final Row row;

        RowHolder(Context context, Row row) {
            super(context);
            this.row = row;
        }
    }

    /** One save entry: title, metadata line, and three flat text actions. */
    private static final class Row {
        final LinearLayout root;
        final TextView name;
        final TextView meta;
        final Button restore;
        final Button export;
        final Button delete;

        Row(Context context) {
            root = new LinearLayout(context);
            root.setOrientation(LinearLayout.VERTICAL);
            root.setBackground(Ui.rounded(Ui.SURFACE_ALT, 12f, context));
            int pad = Ui.dp(context, 14);
            root.setPadding(pad, pad, pad, pad);

            name = Ui.cardTitle(context, "");
            root.addView(name);

            meta = Ui.mono(context, "", 12f, Ui.TEXT_SECONDARY);
            Ui.topMargin(meta, 3f, context);
            root.addView(meta);

            LinearLayout buttons = Ui.row(context);
            Ui.topMargin(buttons, 10f, context);

            restore = Ui.textButton(context, ManagerStrings.action_restore, Ui.ACCENT, 13f);
            restore.setLayoutParams(weighted(context));
            buttons.addView(restore);

            export = Ui.textButton(context, ManagerStrings.action_export, Ui.TEXT_SECONDARY, 13f);
            export.setLayoutParams(weighted(context));
            buttons.addView(export);

            delete = Ui.textButton(context, ManagerStrings.action_delete, Ui.DANGER, 13f);
            delete.setLayoutParams(weighted(context));
            buttons.addView(delete);

            root.addView(buttons);
        }

        private static LinearLayout.LayoutParams weighted(Context context) {
            LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                    0, Ui.dp(context, 40), 1f);
            return params;
        }
    }
}
