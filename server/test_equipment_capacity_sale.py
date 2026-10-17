"""Real gateway sale receipts and the enlarged equipment warehouse."""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from equipment_capacity import apply_equipment_capacity
from gameplay_common import grant_reward
from gateway import Backend
from player_store import GameplayFault


CONFIG = Path(__file__).resolve().parents[1] / "config" / "reconstruction" / "full-config.json"


class EquipmentCapacitySaleTests(unittest.TestCase):
    def setUp(self):
        self.backend = Backend(":memory:", CONFIG)
        self.addCleanup(self.backend.db.close)
        self.backend.call({"method": "user.register", "params": {
            "actionID": "register", "pf": "local", "session_key": "equip-owner", "sessionid": "password"}})
        login = self.backend.call({"method": "user.login", "params": {
            "actionID": "login", "pf": "local", "session_key": "equip-owner", "sessionid": "password"}})
        self.uid, self.token = login["data"]["uid"], login["data"]["sessionid"]

    def rpc(self, method, action, **params):
        return self.backend.call({"method": method, "uid": self.uid, "sessionid": self.token,
                                  "params": {"actionID": action, **params}})

    def test_capacity_1000_and_legacy_inventory_retained(self):
        simple = self.backend.config["cfg"]["system_simple"]
        self.assertEqual(simple["equip_config"][0], 1000)
        apply_equipment_capacity(self.backend.config)
        self.assertEqual(simple["equip_config"][0], 1000)
        preview = self.backend.call({"method": "sys.get_config", "params": {"actionID": "config"}})
        self.assertEqual(preview["data"]["cfg"]["system_simple"]["equip_config"][0], 1000)

        def legacy_inventory(profile):
            profile["my_equips"] = {f"eq{i}": {"eid": "E_1001_3", "lv": 1,
                                              "new_4attrs": {"hit": 0, "flee": 0,
                                                               "crit": 0, "tough": 0}}
                                    for i in range(600)}
            return profile, {}
        self.backend.players.atomic_update(self.uid, legacy_inventory)
        relogin = self.backend.call({"method": "user.login", "params": {
            "actionID": "relogin", "pf": "local", "session_key": "equip-owner", "sessionid": "password"}})
        self.assertEqual(len(relogin["data"]["my_equips"]), 600)
        self.assertEqual(len(relogin["state_sync"]["profile"]["my_equips"]), 600)

        profile = {"my_equips": {f"eq{i}": {"eid": "E_1001_3"} for i in range(999)},
                   "attrs": {}}
        grant_reward(profile, {"equip": {"E_1001_3": 1}}, self.backend.config)
        self.assertEqual(len(profile["my_equips"]), 1000)
        with self.assertRaises(GameplayFault) as caught:
            grant_reward(profile, {"equip": {"E_1001_3": 1}}, self.backend.config)
        self.assertEqual(caught.exception.code, "EquipCapacity")
        self.assertEqual(len(profile["my_equips"]), 1000)

    def test_batch_sale_guard_rollback_and_replay_are_native_compatible(self):
        def seed(profile):
            profile["my_equips"] = {f"eq{i}": {"eid": "E_1001_3", "lv": 1,
                                              "new_4attrs": {"hit": 20, "flee": 0,
                                                               "crit": 0, "tough": 0},
                                              "alchemy": [0, 0]}
                                    for i in range(4)}
            profile["as_equips"] = [["eq0"], [], [], [], [], []]
            profile["my_equips"]["eq2"]["lock"] = 1
            return profile, {}
        self.backend.players.atomic_update(self.uid, seed)
        before = self.backend.players.profile_raw(self.uid)
        for action, ids, code in (
            ("worn", ["eq0"], "EquipmentInUse"),
            ("locked", ["eq1", "eq2"], "EquipmentLocked"),
            ("duplicate", ["eq1", "eq1"], "InvalidSelection"),
            ("unknown", ["eq1", "not-owned"], "UnknownEquipment"),
        ):
            result = self.rpc("user.equip_sell", action, eqids=ids)
            self.assertEqual((result["return_code"], result["data"]["error_code"]), (1, code))
            self.assertEqual(self.backend.players.profile_raw(self.uid), before)
        sold = self.rpc("user.equip_sell", "sell-two", eqids=["eq1", "eq3"])
        self.assertEqual(sold["return_code"], 0)
        self.assertIsInstance(sold["data"], list)
        self.assertEqual(len(sold["data"]), 3)
        after = self.backend.players.profile_raw(self.uid)
        self.assertEqual(set(after["my_equips"]), {"eq0", "eq2"})
        self.assertEqual((after["mark"], after["gold"], after["attrs"]["dust"]), tuple(sold["data"]))
        self.assertGreater(after["gold"], before["gold"])
        self.assertEqual(set(sold["state_sync"]["profile"]["my_equips"]), {"eq0", "eq2"})
        replay = self.rpc("user.equip_sell", "sell-two", eqids=["eq1", "eq3"])
        self.assertEqual(replay["data"], sold["data"])
        self.assertEqual(self.backend.players.profile_raw(self.uid), after)


if __name__ == "__main__":
    unittest.main()
