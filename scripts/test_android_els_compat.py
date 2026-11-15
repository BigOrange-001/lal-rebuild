"""Exercise the actual startup backup helper without real user data."""
import re
import subprocess
import unittest
from pathlib import Path
from test_avatar_passive import method_body

ROOT=Path(__file__).resolve().parents[1]


class AndroidELSCompatibilityTests(unittest.TestCase):
    def test_original_cache_and_key_survive_migration_and_repeated_startup(self):
        source=(ROOT/'client/src/stages/136_MainLLOL.as').read_text('utf-8')
        body=method_body(source,'preserveLegacyELS104')
        body=re.sub(r'\bvar (\w+)\s*:\w+',r'var \1',body)
        body=body.replace('for each(var source in sources)','for(var source of sources)')
        script='''const assert=require('node:assert/strict');
const Capabilities={manufacturer:'Android'},data=new Map(),writes=[];
const root='/data/user/0/air.com.meng52.lol.android',app=root+'/air.com.meng52.lol.android';
class File {
 constructor(path){this.nativePath=path;}
 get name(){return this.nativePath.split('/').at(-1);}
 get exists(){return data.has(this.nativePath);}
 get size(){return data.get(this.nativePath).length;}
 resolvePath(path){return new File(this.nativePath+'/'+path);}
 createDirectory(){}
 copyTo(dest,overwrite){assert(overwrite||!dest.exists);data.set(dest.nativePath,Buffer.from(data.get(this.nativePath)));writes.push(dest.nativePath);}
 moveTo(dest,overwrite){this.copyTo(dest,overwrite);data.delete(this.nativePath);}
}
File.applicationStorageDirectory=new File(app+'/Local Store');
// AIR's app-storage URI root has no parent; use its native path explicitly.
File.applicationStorageDirectory.parent=null;
const paths=[app+'/ELS/air.com.meng52.lol.android.dat',root+'/shared_prefs/com.harman.air.els.air.com.meng52.lol.android.xml',root+'/shared_prefs/air.com.meng52.lol.android.xml'];
for(const [i,p] of paths.entries())data.set(p,Buffer.from('original '+i));
const backup=()=>{BODY};
backup();const count=writes.length;
for(const [i,p] of paths.entries()){
 const target=File.applicationStorageDirectory.resolvePath('els-before-compat-20261116/'+p.split('/').at(-1));
 assert.equal(data.get(target.nativePath).toString(),'original '+i);
 assert.equal(data.get(p).toString(),'original '+i);
 data.set(p,Buffer.from('migrated cache'));
}
backup();assert.equal(writes.length,count,'must preserve first backup after later starts');
assert(writes.every(p=>p.startsWith(app+'/Local Store/els-before-compat-20261116/')));
Capabilities.manufacturer='Windows';backup();assert.equal(writes.length,count);
'''.replace('BODY',body)
        result=subprocess.run(['node'],input=script,text=True,capture_output=True,encoding='utf-8')
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)
        descriptor=(ROOT/'client/air/application.xml').read_text('utf-8')
        self.assertIn('<fallbackMode>never</fallbackMode>',descriptor)


if __name__=='__main__':unittest.main()
