import datetime,json,sqlite3,tempfile,unittest
from pathlib import Path
from ledger_codec import pack_json,unpack_json_text,compact_ledger
from player_store import PlayerStore,GameplayFault


class LedgerCodecTests(unittest.TestCase):
 def test_replay_after_shared_block_compaction_keeps_original_reply(self):
  db=sqlite3.connect(':memory:');store=PlayerStore(db,{'cfg':{}});uid=store.login('block-test')['uid'];calls=[]
  for index in range(64):
   def mutate(profile,index=index):
    calls.append(index);return profile,{'counter':index,'data':list(range(4000))}
   store.atomic_update(uid,mutate,'block-'+str(index),{'n':index})
  from ledger_codec import REFERENCE
  self.assertTrue(db.execute("SELECT result FROM operation_ledger WHERE operation_key='block-0'").fetchone()[0].startswith(REFERENCE))
  def fail(profile):raise AssertionError('replay must not execute')
  replay,repeated=store.atomic_update(uid,fail,'block-0',{'n':0})
  self.assertTrue(repeated);self.assertEqual(replay,{'counter':0,'data':list(range(4000))});self.assertEqual(len(calls),64);db.close()

 def test_small_and_large_receipts_keep_exact_unicode_and_json(self):
  for value in ({'ok':True},{'英雄':'卡莎'*20000,'date':{'$date':123}}):
   raw=json.dumps(value,ensure_ascii=False)
   self.assertEqual(unpack_json_text(pack_json(raw)),raw)
  self.assertIsInstance(pack_json(json.dumps({'data':'x'*10000})),bytes)

 def test_migration_keeps_all_receipts_and_reclaims_file_pages(self):
  with tempfile.TemporaryDirectory() as directory:
   p=Path(directory)/'old.sqlite3'; db=sqlite3.connect(p)
   db.execute('CREATE TABLE operation_ledger(uid TEXT,operation_key TEXT,payload_hash TEXT,result TEXT,created INTEGER)')
   raw=json.dumps({'profile':'same progress '*10000})
   db.executemany('INSERT INTO operation_ledger VALUES(?,?,?,?,?)',[('u',str(n),'hash',raw,n) for n in range(12)])
   db.commit(); before=p.stat().st_size
   self.assertGreater(compact_ledger(db),100000)
   self.assertLess(p.stat().st_size,before/5)
   rows=db.execute('SELECT uid,operation_key,payload_hash,result,created FROM operation_ledger ORDER BY created').fetchall()
   self.assertEqual(len(rows),12)
   for n,row in enumerate(rows):self.assertEqual((row[0],row[1],row[2],unpack_json_text(row[3],db),row[4]),('u',str(n),'hash',raw,n))
   self.assertEqual(compact_ledger(db),0)
   self.assertEqual(db.execute('PRAGMA integrity_check').fetchone()[0],'ok'); db.close()

 def test_compressed_replay_preserves_dates_and_never_repeats_mutation(self):
  db=sqlite3.connect(':memory:'); store=PlayerStore(db,{'cfg':{}})
  uid=store.login('receipt-test')['uid']; calls=[]
  def mutate(profile):
   calls.append(1);profile['gold']+=1
   return profile,{'text':'卡莎'*10000,'when':datetime.datetime(2026,1,1)}
  first=store.atomic_update(uid,mutate,'same',{'n':1})
  repeated=store.atomic_update(uid,mutate,'same',{'n':1})
  self.assertFalse(first[1]);self.assertTrue(repeated[1]);self.assertEqual(first[0],repeated[0]);self.assertEqual(len(calls),1)
  self.assertEqual(db.execute('SELECT typeof(result) FROM operation_ledger').fetchone()[0],'blob')
  with self.assertRaises(GameplayFault):store.atomic_update(uid,mutate,'same',{'n':2})
  self.assertEqual(len(calls),1);db.close()

if __name__=='__main__':unittest.main()
