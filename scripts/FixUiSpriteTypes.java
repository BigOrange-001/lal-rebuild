import java.io.*;
import java.util.*;
import com.jpexs.decompiler.flash.SWF;
import com.jpexs.decompiler.flash.abc.ABC;
import com.jpexs.decompiler.flash.abc.avm2.AVM2Code;
import com.jpexs.decompiler.flash.abc.types.traits.*;

/** Qualify the UI kit's Sprite references without recompiling startup code. */
public class FixUiSpriteTypes {
    private static int count;
    private static int oldType;
    private static int newType;
    private static final Set<Integer> patched = new HashSet<>();

    private static int qname(ABC abc, String pkg) {
        var pool = abc.constants;
        for (int i = 1; i < pool.getMultinameCount(); i++) {
            var name = pool.getMultiname(i);
            if (name.namespace_index > 0 && name.name_index > 0
                    && "Sprite".equals(pool.getString(name.name_index))
                    && pkg.equals(name.getNamespace(pool).getName(pool).toRawString())) {
                return i;
            }
        }
        throw new IllegalStateException("Missing Sprite QName for " + pkg);
    }

    private static void patchSlot(Trait trait) {
        if (trait instanceof TraitSlotConst slot && slot.type_index == oldType) {
            slot.type_index = newType;
            count++;
        }
    }

    private static void patchMethod(ABC abc, int method) {
        if (!patched.add(method)) return;
        var info = abc.method_info.get(method);
        for (int i = 0; i < info.param_types.length; i++) {
            if (info.param_types[i] == oldType) {
                info.param_types[i] = newType;
                count++;
            }
        }
        if (info.ret_type == oldType) {
            info.ret_type = newType;
            count++;
        }
        var body = abc.findBody(method);
        if (body == null) throw new IllegalStateException("Missing bytecode for method " + method);
        for (var trait : body.traits.traits) patchSlot(trait);
        var code = body.getCode();
        for (var instruction : code.code) {
            for (int i = 0; i < instruction.definition.operands.length; i++) {
                int kind = instruction.definition.operands[i];
                if (kind == AVM2Code.DAT_MULTINAME_INDEX && instruction.operands[i] == oldType) {
                    instruction.setOperand(i, newType, code, body);
                    count++;
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
        oldType = qname(abc, "flash.display");
        newType = qname(abc, "starling.display");
        int owner = abc.findClassByName("com.meng52.game.global.GlobalFunction");
        var methods = new HashSet<>(Set.of("uiText", "uiButton", "uiModal", "uiField", "popToast"));
        for (var trait : abc.class_info.get(owner).static_traits.traits) {
            var name = abc.constants.getString(abc.constants.getMultiname(trait.name_index).name_index);
            if ("uiToast".equals(name)) patchSlot(trait);
            if (methods.remove(name)) {
                patchMethod(abc, ((TraitMethodGetterSetter) trait).method_info);
            }
        }
        if (!methods.isEmpty() || count < 15) throw new IllegalStateException("Incomplete Sprite patch: " + count + " " + methods);
        ((com.jpexs.decompiler.flash.tags.Tag) tag).setModified(true);
        try (var out = new FileOutputStream(args[1])) { swf.saveTo(out); }
        System.out.println("Updated " + count + " Sprite references in the UI helpers only.");
    }
}
