"""Material stacks share one roster/equipment slot without changing stored instances."""
import copy
import unittest
from pathlib import Path

from gateway import load_game_config
from gameplay_common import grant_reward
from material_stacks import (STACK_LIMIT, avatar_stack_key, book_stack_key, equipment_slots,
                             roster_slots, roster_slots_after)
from player_store import GameplayFault

ROOT = Path(__file__).resolve().parents[1]
FRESH = {"lv": 1, "slv": 1, "exp": 0, "hp": 0, "ap": 0, "de_ph": 0, "de_ma": 0,
         "phase": 0, "morph": 0, "love_exp": 0, "equips": []}
BOOK = {"eid": "E_6504_5", "lv": 1, "slv": 0, "sexp": 0, "new_4attrs": {"hit": 0, "flee": 0, "crit": 0, "tough": 0},
        "halo": {"lv": 0, "exp": 0}, "haloLv": 0, "haloExp": 0, "alchemy": [0, 0], "rune_lv": 0,
        "magic_stage5": 0, "stat_roll_ppm": 1000000, "equipment_v2_version": 1, "wash_schema_version": 1}


def card(iid, **changes):
    row = dict(FRESH, id=iid, aid=iid)
    row.update(changes)
    return row


class MaterialStackTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.config = load_game_config(ROOT / "config/reconstruction/full-config.json")
        cls.equip = cls.config["cfg"]["equip"]

    def profile(self, avatars=(), equips=(), capacity=1000):
        return {"avatars": {iid: row for iid, row in avatars}, "my_equips": {eqid: row for eqid, row in equips},
                "as_equips": [[None] * 6], "team": [[None] * 5], "attrs": {"avatar_len": capacity}}

    def test_only_untouched_material_cards_stack(self):
        self.assertEqual(avatar_stack_key("A_6996_5|1", card("A_6996_5|1")), "A_6996_5")
        self.assertEqual(avatar_stack_key("A_6992_4|2", card("A_6992_4|2", limit_break=0)), "A_6992_4")
        self.assertEqual(avatar_stack_key("A_1001_5|3", card("A_1001_5|3")), "")
        for changes in ({"lv": 2}, {"exp": 10}, {"slv": 2}, {"lock": True}, {"talent": "T_01_01"},
                        {"hp": 5}, {"equips": ["eq1"]}, {"pith_max": 3}, {"limit_break": 1}):
            self.assertEqual(avatar_stack_key("A_3001_2|4", card("A_3001_2|4", **changes)), "", changes)
        # Blank growth fields, schema tags and client display fields do not split a stack.
        self.assertEqual(avatar_stack_key("A_3001_2|5", card("A_3001_2|5", lock=False, talent="",
                                                             culture_schema="weighted-v2", star=2, power=9, type=1)),
                         "A_3001_2")

    def test_stack_uses_one_slot_per_limit(self):
        avatars = [(f"A_6996_5|{n}", card(f"A_6996_5|{n}")) for n in range(STACK_LIMIT + 1)]
        avatars += [("A_1001_5|hero", card("A_1001_5|hero")), ("A_6996_5|locked", card("A_6996_5|locked", lock=True))]
        profile = self.profile(avatars)
        self.assertEqual(roster_slots(profile), 2 + 1 + 1)
        self.assertEqual(roster_slots_after(profile, [("A_6996_5", STACK_LIMIT - 1)]), 4)
        self.assertEqual(roster_slots_after(profile, [("A_6996_5", STACK_LIMIT)]), 5)
        self.assertEqual(roster_slots_after(profile, [("A_6997_5", 3), ("A_1002_5", 2)]), 7)

    def test_full_roster_still_accepts_copies_of_a_stacked_material(self):
        avatars = [(f"A_1001_5|{n}", card(f"A_1001_5|{n}")) for n in range(9)] + [("A_6996_5|90", card("A_6996_5|90"))]
        profile = self.profile(avatars, capacity=10)
        grant_reward(profile, {"heroes": [{"aid": "A_6996_5", "num": 40}]}, self.config)
        self.assertEqual(len(profile["avatars"]), 50)
        self.assertEqual(roster_slots(profile), 10)
        before = copy.deepcopy(profile)
        for reward in ({"heroes": [{"aid": "A_6997_5", "num": 1}]}, {"heroes": [{"aid": "A_1002_5", "num": 1}]}):
            with self.assertRaises(GameplayFault) as caught:
                grant_reward(profile, reward, self.config)
            self.assertEqual(caught.exception.code, "AvatarCapacity")
            self.assertEqual(profile, before)

    def test_spare_books_stack_but_equipped_locked_or_grown_books_do_not(self):
        equips = [(f"eq{n}", dict(BOOK)) for n in range(5)]
        equips += [("eqA", dict(BOOK, slv=3)), ("eqB", dict(BOOK, lock=True)), ("eqC", dict(BOOK)),
                   ("eqE", dict(BOOK, magic=[0, 0, 0, 0], symp=1)), ("eqF", dict(BOOK, magic=[5, 0, 0, 0])),
                   ("eqD", {"eid": "E_1504_6", "lv": 1})]
        profile = self.profile(equips=equips)
        profile["as_equips"] = [["eqC", None, None, None, None, None]]
        self.assertEqual(book_stack_key("eq0", BOOK, self.equip), "E_6504_5|1000000")
        self.assertEqual(book_stack_key("eqD", {"eid": "E_1504_6", "lv": 1}, self.equip), "")
        self.assertEqual(equipment_slots(profile, self.equip), 1 + 5)

    def test_granted_books_join_their_stack_when_the_bag_is_full(self):
        capacity = int(self.config["cfg"]["system_simple"]["equip_config"][0])
        equips = [(f"eq{n}", {"eid": "E_1504_6", "lv": 1}) for n in range(capacity - 1)] + [("eqbook", dict(BOOK))]
        profile = self.profile(equips=equips)
        grant_reward(profile, {"items": [{"eid": "E_6504_5", "num": 3}]}, self.config)
        self.assertEqual(equipment_slots(profile, self.equip), capacity)
        with self.assertRaises(GameplayFault) as caught:
            grant_reward(profile, {"items": [{"eid": "E_1504_6", "num": 1}]}, self.config)
        self.assertEqual(caught.exception.code, "EquipCapacity")


if __name__ == "__main__":
    unittest.main()
