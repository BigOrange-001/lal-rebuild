import java.io.*;
import java.nio.file.*;
import java.util.*;
import com.jpexs.decompiler.flash.SWF;
import com.jpexs.decompiler.flash.flexsdk.*;

/** Compile a script with AIR's real mxmlc, preserving the template via FFDec. */
public class CompileAirAs3 {
    public static void main(String[] args) {
        try {run(args);System.exit(0);}
        catch(Throwable error){error.printStackTrace();System.exit(1);}
    }
    private static void run(String[] args) throws Exception {
        if(args.length!=5)throw new IllegalArgumentException("input output class source air-sdk");
        String sdk=Path.of(args[4]).toAbsolutePath().toString();
        SWF swf=new SWF(new FileInputStream(args[0]),false);
        var packs=swf.getScriptPacksByClassNames(List.of(args[2]));
        if(packs.size()!=1)throw new IllegalArgumentException("Expected one host script");
        var replacer=new MxmlcAs3ScriptReplacer(sdk){
            @Override public void mxmlc(List<String> options) throws IOException,InterruptedException,MxmlcException {
                var command=new ArrayList<String>();
                command.add(Path.of(System.getProperty("java.home"),"bin","java.exe").toString());
                command.add("-Dflexlib="+Path.of(sdk,"frameworks"));
                command.add("-jar");command.add(Path.of(sdk,"lib","mxmlc-cli.jar").toString());
                command.add("-load-config="+Path.of(sdk,"frameworks","air-config.xml"));
                // AIR's Adobe compiler predates this Apache Flex-only switch.
                // Existing template types are external; only this source emits code.
                for(int i=0;i<options.size();i++){
                    String option=options.get(i);
                    if(option.equals("-include-inheritance-dependencies-only"))continue;
                    if(option.equals("-library-path"))command.add("-external-library-path+="+options.get(++i));
                    else command.add(option);
                }
                var process=new ProcessBuilder(command).redirectErrorStream(true).start();
                String output=new String(process.getInputStream().readAllBytes(),java.nio.charset.StandardCharsets.UTF_8);
                int code=process.waitFor();System.out.print(output);
                if(code!=0)throw new MxmlcException(output);
            }
        };
        try {
            replacer.replaceScript(packs.get(0),Files.readString(Path.of(args[3])),List.of());
            try(var out=new FileOutputStream(args[1])){swf.saveTo(out);}
        } finally {replacer.deinitReplacement(packs.get(0));}
    }
}
