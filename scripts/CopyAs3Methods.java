import java.io.*;
import java.util.*;
import com.jpexs.decompiler.flash.SWF;
import com.jpexs.decompiler.flash.abc.*;
import com.jpexs.decompiler.flash.abc.types.*;
import com.jpexs.decompiler.flash.abc.avm2.*;

/** Apply a leaf-method compilation without rewriting unrelated class closures. */
public class CopyAs3Methods {
    static byte[] pool(ABC abc) throws Exception {
        var bytes = new ByteArrayOutputStream(); var out = new ABCOutputStream(bytes); var p = abc.constants;
        out.writeU30(p.getIntCount()); for(int i=1;i<p.getIntCount();i++) out.writeS32(p.getInt(i));
        out.writeU30(p.getUIntCount()); for(int i=1;i<p.getUIntCount();i++) out.writeU32(p.getUInt(i));
        out.writeU30(p.getDoubleCount()); for(int i=1;i<p.getDoubleCount();i++) out.writeDouble(p.getDouble(i));
        out.writeU30(p.getStringCount()); for(int i=1;i<p.getStringCount();i++) out.writeString(p.getString(i));
        out.writeU30(p.getNamespaceCount()); for(int i=1;i<p.getNamespaceCount();i++) out.writeNamespace(p.getNamespace(i));
        out.writeU30(p.getNamespaceSetCount()); for(int i=1;i<p.getNamespaceSetCount();i++){int[] ns=p.getNamespaceSet(i).namespaces;out.writeU30(ns.length);for(int v:ns)out.writeU30(v);}
        out.writeU30(p.getMultinameCount()); for(int i=1;i<p.getMultinameCount();i++) out.writeMultiname(p.getMultiname(i));
        if(p.getFloatCount()>1 || p.getFloat4Count()>1 || p.getDecimalCount()>1)throw new IllegalArgumentException("Unsupported extended constant pool");
        return bytes.toByteArray();
    }
    static byte[] signature(MethodInfo info) throws Exception {
        var bytes=new ByteArrayOutputStream();new ABCOutputStream(bytes).writeMethodInfo(info);return bytes.toByteArray();
    }
    static MethodBody method(ABC abc,String className,String methodName) {
        int index=abc.findClassByName(className);
        if(index<0)throw new IllegalArgumentException("Missing class "+className);
        for(var t:abc.class_info.get(index).static_traits.traits) {
            String name=abc.constants.getString(abc.constants.getMultiname(t.name_index).name_index);
            if(name.equals(methodName) && t instanceof com.jpexs.decompiler.flash.abc.types.traits.TraitMethodGetterSetter)
                return abc.findBody(((com.jpexs.decompiler.flash.abc.types.traits.TraitMethodGetterSetter)t).method_info);
        }
        return null;
    }
    public static void main(String[] args) throws Exception {
        if(args.length<5)throw new IllegalArgumentException("original compiled output qualified-class method...");
        SWF original=new SWF(new FileInputStream(args[0]),false), compiled=new SWF(new FileInputStream(args[1]),false);
        if(original.getAbcList().size()!=1 || compiled.getAbcList().size()!=1)throw new IllegalArgumentException("Expected one ABC");
        var tag=original.getAbcList().get(0);ABC a=tag.getABC(), b=compiled.getAbcList().get(0).getABC();
        if(!Arrays.equals(pool(a),pool(b)))throw new IllegalArgumentException("Constant pools changed; scoped replacement is unsafe");
        for(int k=4;k<args.length;k++){
            MethodBody old=method(a,args[3],args[k]), fresh=method(b,args[3],args[k]);
            if(old==null||fresh==null)throw new IllegalArgumentException("Missing method "+args[k]);
            if(!Arrays.equals(signature(a.method_info.get(old.method_info)),signature(b.method_info.get(fresh.method_info))))throw new IllegalArgumentException("Method signature changed");
            if(fresh.exceptions.length!=0||!fresh.traits.traits.isEmpty())throw new IllegalArgumentException("Only leaf methods supported");
            for(var ins:fresh.getCode().code)for(int type:ins.definition.operands)
                if(type==AVM2Code.DAT_METHOD_INDEX||type==AVM2Code.DAT_CLASS_INDEX)throw new IllegalArgumentException("Method/class index requires remapping");
            old.setCode(fresh.getCode());old.max_stack=fresh.max_stack;old.max_regs=fresh.max_regs;
            old.init_scope_depth=fresh.init_scope_depth;old.max_scope_depth=fresh.max_scope_depth;old.setModified();
            System.out.println("Updated "+args[3]+"."+args[k]+"; signature and constant pool unchanged");
        }
        ((com.jpexs.decompiler.flash.tags.Tag)tag).setModified(true);
        try(var out=new FileOutputStream(args[2])){original.saveTo(out);}
    }
}
