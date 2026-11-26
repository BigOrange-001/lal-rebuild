import java.io.*;
import java.util.*;
import com.jpexs.decompiler.flash.SWF;
import com.jpexs.decompiler.flash.abc.ABC;
import com.jpexs.decompiler.flash.abc.avm2.AVM2Code;
import com.jpexs.decompiler.flash.abc.types.traits.*;

/**
 * Qualify the UI kit's Sprite and Event references without recompiling startup
 * code. GlobalFunction imports both the flash.* and starling.* classes, and the
 * bare names in the kit compiled to the flash.* ones.
 */
public class FixUiSpriteTypes {
    /** flash.* QName index -> starling.* QName index. */
    private static final Map<Integer, Integer> swaps = new HashMap<>();
    /** Replacements made per flash.* QName index. */
    private static final Map<Integer, Integer> counts = new HashMap<>();
    private static final Set<Integer> patched = new HashSet<>();

    private static int qname(ABC abc, String pkg, String simple) {
        var pool = abc.constants;
        for (int i = 1; i < pool.getMultinameCount(); i++) {
            var name = pool.getMultiname(i);
            if (name.namespace_index > 0 && name.name_index > 0
                    && simple.equals(pool.getString(name.name_index))
                    && pkg.equals(name.getNamespace(pool).getName(pool).toRawString())) {
                return i;
            }
        }
        throw new IllegalStateException("Missing " + simple + " QName for " + pkg);
    }

    /** The starling.* replacement for a flash.* type index, or -1. */
    private static int swap(int type) {
        Integer replacement = swaps.get(type);
        if (replacement == null) return -1;
        counts.merge(type, 1, Integer::sum);
        return replacement;
    }

    private static void patchSlot(Trait trait) {
        if (trait instanceof TraitSlotConst slot) {
            int replacement = swap(slot.type_index);
            if (replacement > 0) slot.type_index = replacement;
        }
    }

    private static void patchMethod(ABC abc, int method) {
        if (!patched.add(method)) return;
        var info = abc.method_info.get(method);
        for (int i = 0; i < info.param_types.length; i++) {
            int replacement = swap(info.param_types[i]);
            if (replacement > 0) info.param_types[i] = replacement;
        }
        int returned = swap(info.ret_type);
        if (returned > 0) info.ret_type = returned;
        var body = abc.findBody(method);
        if (body == null) throw new IllegalStateException("Missing bytecode for method " + method);
        for (var trait : body.traits.traits) patchSlot(trait);
        var code = body.getCode();
        for (var instruction : code.code) {
            for (int i = 0; i < instruction.definition.operands.length; i++) {
                int kind = instruction.definition.operands[i];
                if (kind == AVM2Code.DAT_MULTINAME_INDEX) {
                    int replacement = swap(instruction.operands[i]);
                    if (replacement > 0) instruction.setOperand(i, replacement, code, body);
                } else if (kind == AVM2Code.DAT_METHOD_INDEX && instruction.definition.instructionName.equals("newfunction")) {
                    patchMethod(abc, instruction.operands[i]);
                }
            }
        }
        body.setModified();
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 2) throw new IllegalArgumentException("Expected input and output SWF paths");
        SWF swf;
        try (var in = new FileInputStream(args[0])) {
            swf = new SWF(in, false);
        }
        if (swf.getAbcList().size() != 1) throw new IllegalStateException("Expected one ABC");
        var tag = swf.getAbcList().get(0);
        ABC abc = tag.getABC();
        int sprite = qname(abc, "flash.display", "Sprite");
        int event = qname(abc, "flash.events", "Event");
        swaps.put(sprite, qname(abc, "starling.display", "Sprite"));
        swaps.put(event, qname(abc, "starling.events", "Event"));
        int owner = abc.findClassByName("com.meng52.game.global.GlobalFunction");
        var methods = new HashSet<>(Set.of("uiText", "uiButton", "uiModal", "uiField", "popToast"));
        for (var trait : abc.class_info.get(owner).static_traits.traits) {
            var name = abc.constants.getString(abc.constants.getMultiname(trait.name_index).name_index);
            if ("uiToast".equals(name)) patchSlot(trait);
            if (methods.remove(name)) {
                patchMethod(abc, ((TraitMethodGetterSetter) trait).method_info);
            }
        }
        int sprites = counts.getOrDefault(sprite, 0);
        int events = counts.getOrDefault(event, 0);
        // A base already given the Sprite patch has none left; otherwise every
        // helper's Sprite (15+) must change. uiButton's click callback is the
        // one Event reference, absent only once it is already qualified.
        if (!methods.isEmpty() || (sprites > 0 && sprites < 15) || sprites + events == 0) {
            throw new IllegalStateException("Incomplete UI kit patch: " + sprites + " Sprite, " + events + " Event, missing " + methods);
        }
        ((com.jpexs.decompiler.flash.tags.Tag) tag).setModified(true);
        try (var out = new FileOutputStream(args[1])) { swf.saveTo(out); }
        System.out.println("Updated " + sprites + " Sprite and " + events + " Event references in the UI helpers only.");
    }
}
