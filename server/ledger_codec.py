"""Lossless on-disk receipt compression; the JSON RPC contract stays unchanged."""
import zlib,lzma,json,struct
from functools import lru_cache

MAGIC = b'LALZ1\0'
REFERENCE = b'LALR1\0'


@lru_cache(maxsize=2)
def _block_texts(payload):
    return tuple(json.loads(lzma.decompress(payload).decode('utf-8')))


def pack_json(text):
    raw = text.encode('utf-8')
    if len(raw) < 512:
        return text
    packed = MAGIC + zlib.compress(raw, 9)
    return packed if len(packed) + 32 < len(raw) else text


def unpack_json_text(value, db=None):
    if isinstance(value, str):
        return value
    raw = bytes(value)
    if raw.startswith(REFERENCE):
        if db is None:
            raise ValueError('A receipt block requires its database')
        block, index = struct.unpack('>QI', raw[len(REFERENCE):])
        row = db.execute('SELECT payload FROM receipt_blocks WHERE id=?', (block,)).fetchone()
        if row is None:
            raise ValueError('Missing receipt block')
        return _block_texts(bytes(row[0]))[index]
    if raw.startswith(MAGIC):
        raw = zlib.decompress(raw[len(MAGIC):])
    return raw.decode('utf-8')


def compact_ledger(db):
    """Migrate legacy receipts atomically, retaining every key and exact reply."""
    if db.in_transaction:
        raise RuntimeError('Receipt compaction requires an idle connection')
    exists = db.execute("SELECT 1 FROM sqlite_master WHERE type='table' AND name='operation_ledger'").fetchone()
    if not exists:
        return 0
    saved = 0
    last = 0
    with db:
        db.execute('CREATE TABLE IF NOT EXISTS receipt_blocks(id INTEGER PRIMARY KEY,payload BLOB NOT NULL)')
        while True:
            rows = db.execute("SELECT rowid,result FROM operation_ledger WHERE rowid>? AND length(result)>=512 ORDER BY rowid LIMIT 64", (last,)).fetchall()
            if not rows:
                break
            selected, texts, old_size, expanded_size = [], [], 0, 0
            for rowid, value in rows:
                text = unpack_json_text(value, db)
                size = len(text.encode('utf-8'))
                if selected and expanded_size + size > 4*1024*1024:
                    break
                selected.append(rowid);texts.append(text);expanded_size += size
                old_size += len(value.encode('utf-8')) if isinstance(value,str) else len(value)
            last = selected[-1]
            packed = lzma.compress(json.dumps(texts,ensure_ascii=False,separators=(',',':')).encode('utf-8'),preset=3)
            new_size = len(packed) + len(selected) * (len(REFERENCE)+12)
            if new_size + 128 >= old_size:
                continue
            block = db.execute('INSERT INTO receipt_blocks(payload) VALUES(?)',(packed,)).lastrowid
            for index, rowid in enumerate(selected):
                db.execute('UPDATE operation_ledger SET result=? WHERE rowid=?',(REFERENCE+struct.pack('>QI',block,index),rowid))
            saved += old_size - new_size
    # Reclaim pages after a successful commit, never while gameplay is writing.
    if saved >= 65536:
        db.execute('VACUUM')
    return saved
