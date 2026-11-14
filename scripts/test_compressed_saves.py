import gzip,hashlib,importlib.util,json,sqlite3,sys,tempfile,unittest
from pathlib import Path
from contextlib import closing
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'server'))
spec=importlib.util.spec_from_file_location('save_bridge',ROOT/'android-manager/app/src/main/python/manager_bridge.py')
bridge=importlib.util.module_from_spec(spec);spec.loader.exec_module(bridge)

class CompressedSaveTests(unittest.TestCase):
 def make_save(self,path):
  with closing(sqlite3.connect(path)) as db:
   db.executescript('CREATE TABLE accounts(name TEXT);CREATE TABLE players(uid TEXT,profile TEXT);CREATE TABLE operation_ledger(result TEXT);')
   db.execute('INSERT INTO accounts VALUES(?)',('owner',));db.execute('INSERT INTO players VALUES(?,?)',('u','{"gold":12345}'))
   db.execute('INSERT INTO operation_ledger VALUES(?)',(json.dumps({'profile':'卡莎'*20000}),))
   db.commit()
 def test_snapshot_compacts_copy_without_changing_source(self):
  with tempfile.TemporaryDirectory() as d:
   source=Path(d)/'old.sqlite3';self.make_save(source);digest=hashlib.sha256(source.read_bytes()).digest()
   target=Path(d)/'snapshot.sqlite3';bridge.snapshot(str(source),str(target))
   self.assertLess(target.stat().st_size,source.stat().st_size)
   self.assertEqual(hashlib.sha256(source.read_bytes()).digest(),digest)
   self.assertGreater(json.loads(bridge.verify(str(target)))['tables'],1)
 def test_legacy_and_compressed_import_keep_progress(self):
  with tempfile.TemporaryDirectory() as d:
   source=Path(d)/'old.sqlite3';self.make_save(source)
   compressed=Path(d)/'save.sqlite3.gz'
   with gzip.open(compressed,'wb') as output:output.write(source.read_bytes())
   for candidate in (source,compressed):
    self.assertEqual(json.loads(bridge.verify(str(candidate)))['tables'],3)
    target=Path(d)/'live.sqlite3';bridge.import_database(str(candidate),str(target))
    with closing(sqlite3.connect(target)) as db:
     self.assertEqual(db.execute('SELECT profile FROM players').fetchone()[0],'{"gold":12345}')
     self.assertEqual(db.execute('PRAGMA integrity_check').fetchone()[0],'ok')
 def test_corrupt_archive_never_replaces_current_progress(self):
  with tempfile.TemporaryDirectory() as d:
   target=Path(d)/'live.sqlite3';self.make_save(target);before=target.read_bytes()
   bad=Path(d)/'broken.gz';bad.write_bytes(b'\x1f\x8bgarbage')
   with self.assertRaises(Exception):bridge.import_database(str(bad),str(target))
   self.assertEqual(target.read_bytes(),before)
   self.assertFalse(target.with_suffix('.sqlite3.importing').exists())

 def test_legacy_save_over_10_mib_imports_losslessly_in_both_formats(self):
  from ledger_codec import unpack_json_text
  with tempfile.TemporaryDirectory() as d:
   source=Path(d)/'large-legacy.sqlite3'
   raw=json.dumps({'profile':'旧版进度'*40000,'英雄':'卡莎','gold':12345},ensure_ascii=False)
   with closing(sqlite3.connect(source)) as db:
    db.executescript('CREATE TABLE accounts(name TEXT);CREATE TABLE players(uid TEXT,profile TEXT);CREATE TABLE operation_ledger(uid TEXT,operation_key TEXT,payload_hash TEXT,result TEXT,created INTEGER);')
    db.execute('INSERT INTO accounts VALUES(?)',('old-player',))
    db.execute('INSERT INTO players VALUES(?,?)',('u','{"gold":12345,"heroes":["A_1801_6","A_1802_6"]}'))
    db.executemany('INSERT INTO operation_ledger VALUES(?,?,?,?,?)',[('u',f'old-{i}','hash',raw,i) for i in range(32)])
    db.commit()
   self.assertGreater(source.stat().st_size,10*1024*1024)
   original=hashlib.sha256(source.read_bytes()).digest()
   compressed=source.with_suffix('.sqlite3.gz')
   with gzip.open(compressed,'wb') as out,source.open('rb') as inp:
    import shutil
    shutil.copyfileobj(inp,out)
   for candidate in (source,compressed):
    bridge.verify(str(candidate))
    target=Path(d)/'live.sqlite3'
    bridge.import_database(str(candidate),str(target))
    with closing(sqlite3.connect(target)) as db:
     self.assertEqual(db.execute('SELECT profile FROM players').fetchone()[0],'{"gold":12345,"heroes":["A_1801_6","A_1802_6"]}')
     rows=db.execute('SELECT uid,operation_key,payload_hash,result,created FROM operation_ledger ORDER BY created').fetchall()
     self.assertEqual(len(rows),32)
     for i,row in enumerate(rows):
      self.assertEqual((row[0],row[1],row[2],unpack_json_text(row[3],db),row[4]),('u',f'old-{i}','hash',raw,i))
     self.assertEqual(db.execute('PRAGMA integrity_check').fetchone()[0],'ok')
    self.assertLess(target.stat().st_size,10*1024*1024)
   self.assertEqual(hashlib.sha256(source.read_bytes()).digest(),original)

if __name__=='__main__':unittest.main()
