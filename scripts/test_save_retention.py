"""Run the real SaveStore on the JVM with only Android/Python bridge stubs."""
from pathlib import Path
import shutil,subprocess,tempfile
ROOT=Path(__file__).resolve().parents[1]
FILES={
'android/content/Context.java':'''package android.content; import java.io.*; public class Context { public final File root; public Context(File f){root=f;root.mkdirs();} public Context getApplicationContext(){return this;} public File getFilesDir(){return root;} }''',
'android/util/Log.java':'''package android.util; public class Log { public static int i(String a,String b){return 0;} public static int w(String a,String b){return 0;} public static int w(String a,String b,Throwable t){return 0;} }''',
'com/lal/rebuild/manager/RuntimeInstaller.java':'''package com.lal.rebuild.manager; import java.io.*; import android.content.Context; class RuntimeInstaller { static File saveDir(Context c){File f=new File(c.root,"saves");f.mkdirs();return f;} }''',
'com/lal/rebuild/manager/PythonBridge.java':'''package com.lal.rebuild.manager; import java.io.*; import java.nio.file.*; import java.util.zip.*; class PythonBridge {void snapshot(File a,File b)throws Exception{Files.copy(a.toPath(),b.toPath(),StandardCopyOption.REPLACE_EXISTING);}void verify(File a)throws Exception{} void importDatabase(File a,File b)throws Exception{try(InputStream raw=new FileInputStream(a);BufferedInputStream in=new BufferedInputStream(raw)){in.mark(2);boolean gz=in.read()==31&&in.read()==139;in.reset();InputStream data=gz?new GZIPInputStream(in):in;Files.copy(data,b.toPath(),StandardCopyOption.REPLACE_EXISTING);}} }''',
'com/lal/rebuild/manager/RetentionChecks.java':r'''package com.lal.rebuild.manager;
import java.io.*;import java.nio.file.*;import java.util.*;import java.util.zip.*;import android.content.Context;
public class RetentionChecks {
 static void check(boolean ok,String why){if(!ok)throw new AssertionError(why);}
 static long used(SaveStore s){long n=s.source().length();for(SaveStore.Save x:s.list())if(x.kind.equals("auto"))n+=x.bytes;return n;}
 static int count(SaveStore s){int n=0;for(SaveStore.Save x:s.list())if(x.kind.equals("auto"))n++;return n;}
 static SaveStore make(File root,int bytes)throws Exception {root.mkdirs();File db=new File(root,"live.sqlite3");byte[] data=new byte[bytes];new Random(29).nextBytes(data);Files.write(db.toPath(),data);return new SaveStore(new Context(root),db);}
 static void change(SaveStore s,int n)throws Exception {try(RandomAccessFile f=new RandomAccessFile(s.source(),"rw")){f.seek(0);f.writeInt(n);}}
 public static void main(String[] args)throws Exception {
  File root=new File(args[0]);PythonBridge bridge=new PythonBridge();int checks=0;
  SaveStore small=make(new File(root,"small"),65536);
  for(int i=0;i<8;i++){change(small,i);small.capture("auto",bridge);}
  check(count(small)==5,"retain newest five");checks++;
  int before=count(small);small.capture("auto",bridge);check(count(small)==before,"deduplicate unchanged progress");checks++;
  SaveStore.Save oldest=null;for(SaveStore.Save save:small.list())if(save.kind.equals("auto"))oldest=save;
  byte[] expected;try(InputStream in=new GZIPInputStream(new FileInputStream(oldest.file))){expected=in.readAllBytes();}
  change(small,99);small.restore(oldest,bridge);check(Arrays.equals(expected,Files.readAllBytes(small.source().toPath())),"restore selected oldest backup despite pruning");checks++;
  SaveStore large=make(new File(root,"large"),3*1024*1024);
  SaveStore.Save manual=large.capture("manual",bridge);
  for(int i=0;i<6;i++){change(large,i);large.capture("auto",bridge);}
  check(used(large)<=SaveStore.STORAGE_LIMIT&&count(large)<5,"enforce combined byte budget");check(manual.file.isFile(),"never prune manual save");checks++;
  byte[] imported=Files.readAllBytes(manual.file.toPath());large.importFrom(new ByteArrayInputStream(imported),bridge);
  check(large.source().length()==3*1024*1024,"gzip import is not double-compressed");checks++;
  SaveStore legacy=make(new File(root,"legacy"),65536);
  for(int i=0;i<7;i++){byte[] data=new byte[10000];data[0]=(byte)i;Files.write(new File(legacy.directory(),"auto-"+(1000+i)+".sqlite3").toPath(),data);}
  legacy.prune();check(count(legacy)==5,"migrate old automatic saves");
  for(SaveStore.Save save:legacy.list())if(save.kind.equals("auto"))check(save.file.getName().endsWith(".gz"),"legacy backup compressed");checks++;
  SaveStore oversized=make(new File(root,"oversized"),11*1024*1024);long bytes=oversized.source().length();
  check(oversized.capture("auto",bridge)==null&&count(oversized)==0,"skip backup which cannot fit");check(oversized.source().length()==bytes,"never trim live progress");checks++;
  check(new File(new File(root,"small"),"staging").list().length==0,"temporary save files cleaned");checks++;
  System.out.println("SaveStore boundary checks passed: "+checks);
 }
}'''
}

def main():
 with tempfile.TemporaryDirectory(prefix='lal-save-check-') as directory:
  work=Path(directory)
  for name,body in FILES.items():
   p=work/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(body,encoding='utf-8')
  shutil.copy2(ROOT/'android-manager/app/src/main/java/com/lal/rebuild/manager/SaveStore.java',work/'com/lal/rebuild/manager/SaveStore.java')
  subprocess.run(['javac','-encoding','UTF-8','-d',str(work/'classes'),*[str(p) for p in work.rglob('*.java')]],check=True,capture_output=True)
  p=subprocess.run(['java','-cp',str(work/'classes'),'com.lal.rebuild.manager.RetentionChecks',str(work/'data')],capture_output=True,text=True,encoding='utf-8')
  if p.returncode:raise RuntimeError(p.stdout+p.stderr)
  print(p.stdout.strip())
if __name__=='__main__':main()
