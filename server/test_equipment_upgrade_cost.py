"""Focused equipment-upgrade cost, gate, and critical-step boundaries."""
import copy
import json
import sqlite3
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from equipment_upgrade_cost import apply_equipment_upgrade_config, cost_table
from gameplay_roster import GameplayRosterEquipment
from player_store import GameplayFault, PlayerStore


class FixedRandom:
    def random(self):
        return .86

    def randint(self, low, high):
        return low


class EquipmentUpgradeCostTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = json.loads((Path(__file__).resolve().parents[1] /
                                 "config/reconstruction/full-config.json").read_text(encoding="utf-8"))

    def setUp(self):
        self.config = apply_equipment_upgrade_config(copy.deepcopy(self.source))
        self.db = sqlite3.connect(":memory:", check_same_thread=False)
        self.addCleanup(self.db.close)
        self.store = PlayerStore(self.db, self.config)
        self.uid = self.store.login("equipment-upgrade-test")["uid"]
        self.roster = GameplayRosterEquipment(self.store, self.config)
        self.roster.rng = FixedRandom()
        def seed(profile):
            profile["lv"] = 10
            profile["vip_lv"] = 15
            profile["gold"] = 1_000_000
            profile["my_equips"] = {"eq": {"eid": "E_1001_3", "lv": 54,
                                          "alchemy": [0, 0]}}
            return profile, {}
        self.store.atomic_update(self.uid, seed)

    def rise(self, level, action):
        return self.roster.dispatch(self.uid, "user.equip_rise",
                                    {"eqid": "eq", "lv": level, "actionID": action})

    def test_cost_table_and_preview_config(self):
        table = cost_table()
        self.assertEqual((table[1], table[100], table[200]), (9, 100_000, 0))
        self.assertTrue(all(table[i] <= table[i + 1] for i in range(1, 199)))
        self.assertEqual(self.config["cfg"]["system_simple"]["equip_rise_cost"], table)
        self.assertEqual(self.config["cfg"]["vip"]["15"]["equip_lvmax"], 45)
        self.assertIs(apply_equipment_upgrade_config(self.config), self.config)

    def test_crit_overshoots_dynamic_gate_then_ten_attempt_loop_stops_without_charge(self):
        # Account 10 + VIP 15*3 = 55. The first paid attempt may crit beyond 55.
        first = self.rise(54, "batch-1")
        self.assertEqual(first[0], 64)  # VIP15 draw .86: +10.
        before = self.store.profile_raw(self.uid)["gold"]
        self.assertEqual(before, 1_000_000 - cost_table()[54])
        self.assertEqual(self.rise(54, "batch-1"), first)
        for index in range(2, 11):
            with self.assertRaises(GameplayFault) as caught:
                self.rise(first[0], f"batch-{index}")
            self.assertEqual(caught.exception.code, "MaxLevel")
        profile = self.store.profile_raw(self.uid)
        self.assertEqual(profile["my_equips"]["eq"]["lv"], first[0])
        self.assertEqual(profile["gold"], before)

    def test_global_200_cap_and_existing_above_dynamic_gate(self):
        def old_item(profile):
            profile["my_equips"]["eq"]["lv"] = 199
            return profile, {}
        self.store.atomic_update(self.uid, old_item)
        with self.assertRaises(GameplayFault) as caught:
            self.rise(199, "old-over-cap")
        self.assertEqual(caught.exception.code, "MaxLevel")
        def eligible(profile):
            profile["lv"] = 200
            profile["vip_lv"] = 15
            return profile, {}
        self.store.atomic_update(self.uid, eligible)
        self.assertEqual(self.rise(199, "at-global-cap")[0], 200)
        with self.assertRaises(GameplayFault):
            self.rise(200, "past-global-cap")


if __name__ == "__main__":
    unittest.main()
