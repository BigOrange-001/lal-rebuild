"""The client stack rule (GlobalData, stage 001) matches server/material_stacks.py."""
import json
import re
import shutil
import sys
import unittest
from pathlib import Path

from test_avatar_passive import method_body
import test_playtest_client as harness

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'server'))
from material_stacks import avatar_stack_key, book_stack_key, equipment_slots, roster_slots  # noqa: E402

SOURCE = ROOT / 'client/src/stages/001_GlobalData.as'
METHODS = ('stackFieldRules', 'stackBlank', 'stackNumbersFresh', 'stackAllZero', 'avatarStackKey',
           'bookStackKey', 'stackUsedEquips', 'stackSlotCount', 'rosterSlotCount', 'equipSlotCount',
           'collapseStacks', 'isMaterialCard', 'gameDayKey', 'stageSweepPolicy', 'stageSweepQuote')
FRESH = {"lv": 1, "slv": 1, "exp": 0, "hp": 0, "ap": 0, "de_ph": 0, "de_ma": 0, "phase": 0, "morph": 0,
         "love_exp": 0, "equips": []}
BOOK = {"eid": "E_6504_5", "lv": 1, "slv": 0, "sexp": 0, "new_4attrs": {"hit": 0, "flee": 0, "crit": 0, "tough": 0},
        "halo": {"lv": 0, "exp": 0}, "haloLv": 0, "haloExp": 0, "alchemy": [0, 0], "rune_lv": 0,
        "magic_stage5": 0, "stat_roll_ppm": 1000000, "equipment_v2_version": 1, "wash_schema_version": 1}
EQUIP = {"E_6504_5": {"type": 6}, "E_6501_2": {"type": 6}, "E_1504_6": {"type": 1}}


def js_function(source, name):
    signature = re.search(r'function\s+' + name + r'\s*\(([^)]*)\)', source)
    params = ', '.join(part.split(':')[0].strip() for part in signature.group(1).split(',') if part.strip())
    body = method_body(source, name)
    body = re.sub(r'([\w.\[\]"]+) is (Array|Date)\b', r'(\1 instanceof \2)', body)
    body = re.sub(r'for each\(var (\w+)\s*:\s*\w+ in ([^)]*)\)', r'for (var \1 of \2)', body)
    return f'function {name}({params}) {{{body}}}\n'


def avatar_cases():
    cases = {"fresh": FRESH, "hero": dict(FRESH, aid="A_1001_5|9")}
    for key, value in (("lv", 2), ("lv", 0), ("lv", 1.0), ("lv", "1"), ("lv", True), ("lv", None), ("exp", 5),
                       ("slv", 2), ("hp", 1), ("limit_break", 1), ("pith_max", 2), ("inherit_count", 1),
                       ("equips", ["eq1"]), ("equips", []), ("talent", "T_01_01"), ("talent", ""),
                       ("lock", True), ("lock", False), ("lock", 1), ("lock", 0), ("locked", True),
                       ("culture_legacy_raw", {"hp": 1}), ("culture_legacy_raw", {}), ("worship_info", [1]),
                       ("culture_schema", "weighted-v2"), ("star", 5), ("power", 123), ("type", 1),
                       ("teamNum", 2), ("status", -1), ("give", {"exp": 3})):
        cases[f"{key}={value!r}"] = dict(FRESH, **{key: value})
    return cases


def book_cases():
    cases = {"fresh": BOOK, "gear": {"eid": "E_1504_6", "lv": 1}, "missing": {"eid": "E_0000_1"}}
    for key, value in (("slv", 1), ("slv", 3), ("lv", 2), ("sexp", 4), ("haloLv", 1), ("rune_lv", 2),
                       ("new_4attrs", {"hit": 0, "flee": 5}), ("halo", {"lv": 1, "exp": 0}),
                       ("alchemy", [0, 1]), ("alchemy", []), ("magic", [0, 0, 0, 0]), ("magic", [3, 0, 0, 0]),
                       ("lock", True), ("locked", 1), ("symp", 1), ("stat_roll_ppm", 950000.0),
                       ("stat_roll_ppm", None), ("tag", 0), ("bookselect", 1)):
        cases[f"{key}={value!r}"] = dict(BOOK, **{key: value})
    return cases


@unittest.skipUnless(shutil.which('node'), 'Node is required for the AS behavior harness')
class MaterialStackClientTests(unittest.TestCase):
    def run_rule(self, payload, expression):
        source = SOURCE.read_text('utf-8-sig')
        script = '''const int=v=>Math.trunc(Number(v))||0;
const STACK_LIMIT=999;
const SendAndSelect={$systemTimer_nowSecond:0};
for (const [name,fn] of [['fullYearUTC','getUTCFullYear'],['monthUTC','getUTCMonth'],['dateUTC','getUTCDate']])
  Object.defineProperty(Date.prototype,name,{get(){return this[fn]();}});
const input=PAYLOAD;
const GlobalData={STACK_LIMIT, $mConfig_equip:input.equip, $mConfig_simple:input.simple||{}, $userData:input.profile};
'''.replace('PAYLOAD', json.dumps(payload))
        for name in METHODS:
            script += js_function(source, name)
        script += 'console.log(JSON.stringify(' + expression + '));\n'
        return harness.PlaytestClientTests.run_js(self, script)

    def test_card_and_book_keys_match_the_server(self):
        avatars = {f"A_6996_5|{i}": dict(row, aid=row.get("aid", f"A_6996_5|{i}"), id=f"A_6996_5|{i}")
                   for i, row in enumerate(avatar_cases().values())}
        books = {f"eq{i}": row for i, row in enumerate(book_cases().values())}
        used = {"eq3": True}
        actual = self.run_rule({"equip": EQUIP, "avatars": avatars, "books": books, "used": used},
                               '{cards:Object.fromEntries(Object.entries(input.avatars).map(([k,v])=>[k,avatarStackKey(k,v)])),'
                               'books:Object.fromEntries(Object.entries(input.books).map(([k,v])=>[k,bookStackKey(k,v,input.used)]))}')
        expected_cards = {k: avatar_stack_key(k, v) for k, v in avatars.items()}
        expected_books = {k: book_stack_key(k, v, EQUIP, set(used)) for k, v in books.items()}
        self.assertEqual(actual["cards"], expected_cards)
        self.assertEqual(actual["books"], expected_books)
        self.assertEqual(expected_cards["A_6996_5|0"], "A_6996_5")
        self.assertIn("", expected_cards.values())

    def test_slot_counts_and_collapsed_rows_match_the_server(self):
        avatars = {f"A_6996_5|{i}": dict(FRESH, id=f"A_6996_5|{i}", aid=f"A_6996_5|{i}") for i in range(1003)}
        avatars.update({"A_1001_5|2000": dict(FRESH, id="A_1001_5|2000", aid="A_1001_5|2000", equips=["eq9"]),
                        "A_3001_2|2001": dict(FRESH, id="A_3001_2|2001", aid="A_3001_2|2001", lv=3),
                        "A_3001_2|2002": dict(FRESH, id="A_3001_2|2002", aid="A_3001_2|2002", star=2)})
        equips = {f"eq{i}": dict(BOOK) for i in range(6)}
        equips.update({"eq9": dict(BOOK), "eq10": {"eid": "E_1504_6", "lv": 1}, "eq11": dict(BOOK, slv=4)})
        profile = {"avatars": avatars, "my_equips": equips, "as_equips": [["eq5", None]],
                   "attrs": {"equip_wash": {"eqid": "eq4"}}}
        rows = [dict(avatars[k], id=k) for k in sorted(avatars)]
        actual = self.run_rule({"equip": EQUIP, "profile": profile, "rows": rows},
                               '{roster:rosterSlotCount(),equip:equipSlotCount(),'
                               'stacks:collapseStacks(input.rows,input.rows.map(r=>avatarStackKey(r.id,r)))'
                               '.map(r=>[r.id,r.stack_count||1,(r.stack_ids||[]).length])}')
        self.assertEqual(actual["roster"], roster_slots(profile))
        self.assertEqual(actual["equip"], equipment_slots(profile, EQUIP))
        self.assertEqual(actual["roster"], 2 + 1 + 1 + 1)
        counts = sorted(n for _, n, _ in actual["stacks"])
        self.assertEqual(counts, [1, 1, 1, 4, 999])


if __name__ == '__main__':
    unittest.main()
