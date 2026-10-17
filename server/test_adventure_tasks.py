"""Adventure task progress and claims through authenticated service methods."""
import copy
import json
import sqlite3
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from equipment_capacity import apply_equipment_capacity
from gameplay_common import equipment_exclusive_ids, skin_acquisition_blocked_ids
from adventure_tasks import AdventureTasks
from player_store import GameplayFault, PlayerStore


class AdventureTaskTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = json.loads((Path(__file__).resolve().parents[1] /
                                 "config/reconstruction/full-config.json").read_text(encoding="utf-8"))

    def setUp(self):
        self.config = apply_equipment_capacity(copy.deepcopy(self.source))
        self.db = sqlite3.connect(":memory:", check_same_thread=False)
        self.addCleanup(self.db.close)
        self.store = PlayerStore(self.db, self.config)
        login = self.store.login("adventure-test", "gm")
        self.uid, self.session = login["uid"], login["sessionid"]
        def seed(profile):
            profile["attrs"]["avatar_len"] = 1000
            profile["coin"] = 100000
            profile["gold"] = 100000
            profile["score"] = 100000
            profile["lv"] = 30
            return profile, {}
        self.store.atomic_update(self.uid, seed)

    def rpc(self, method, action, **params):
        return self.store.dispatch({"uid": self.uid, "sessionid": self.session,
                                    "method": method, "params": {"actionID": action, **params}})

    @staticmethod
    def row(info, kind, key):
        return next(row for row in info[kind] if row["key"] == key)

    def test_random_pools_exclude_placeholder_and_nonstandard_equipment(self):
        config = copy.deepcopy(self.config)
        heroes = config["cfg"]["avatar"]
        placeholder = next(f"A_{number:04d}_6" for number in range(1000, 1200)
                           if f"A_{number:04d}_6" not in heroes)
        heroes[placeholder] = {"name": "橙阶英雄·占位"}
        config["cfg"]["equip"]["E_1999_6"] = {"type": 2, "name": "占位装备"}
        tasks = AdventureTasks(self.store, config)
        self.assertNotIn(placeholder, tasks.heroes)
        self.assertNotIn("E_1999_6", tasks.equipment)
        self.assertTrue(tasks.heroes)
        self.assertTrue(tasks.equipment)

    def test_daily_events_only_after_real_actions_and_reset_next_day(self):
        initial = self.rpc("user.adventure_tasks_info", "read-1")
        self.assertEqual(self.row(initial, "daily", "login")["count"], 1)
        self.assertEqual(self.row(initial, "daily", "draw")["count"], 0)
        self.assertEqual(self.rpc("user.adventure_tasks_info", "read-2"), initial)
        self.assertTrue(self.rpc("user.adventure_task_claim", "daily-login",
                                 kind="daily", key="login")["ok"])
        def old_session(profile):
            profile.pop("adventure_tasks", None)
            return profile, {}
        self.store.atomic_update(self.uid, old_session)
        self.assertEqual(self.row(self.rpc("user.adventure_tasks_info", "hot-update"),
                                  "daily", "login")["count"], 1)
        with self.assertRaises(GameplayFault):
            self.rpc("user.adventure_task_claim", "early", kind="daily", key="draw")
        self.rpc("user.wager_avatar", "draw-1", wager_type="coin", times=1, free=0)
        self.rpc("user.get_lottery_activity", "vip-draw-1", flag=0)
        after_draw = self.rpc("user.adventure_tasks_info", "read-3")
        self.assertEqual(self.row(after_draw, "daily", "draw")["count"], 2)
        claimed = self.rpc("user.adventure_task_claim", "daily-draw", kind="daily", key="draw")
        self.assertTrue(claimed["ok"])
        self.assertEqual(self.rpc("user.adventure_task_claim", "daily-draw", kind="daily", key="draw")["award"], claimed["award"])
        with self.assertRaises(GameplayFault):
            self.rpc("user.adventure_task_claim", "daily-draw-2", kind="daily", key="draw")
        self.store.clock.advance(86400)
        tomorrow = self.rpc("user.adventure_tasks_info", "read-4")
        self.assertEqual(self.row(tomorrow, "daily", "draw")["count"], 0)
        self.assertEqual(self.row(tomorrow, "daily", "login")["count"], 0)
        self.store.login("adventure-test", "gm")
        self.assertEqual(self.row(self.rpc("user.adventure_tasks_info", "read-5"),
                                  "daily", "login")["count"], 1)
        new_day_claim = self.rpc("user.adventure_task_claim", "daily-login",
                                 kind="daily", key="login")
        self.assertFalse(new_day_claim["replayed"])

    def test_real_normal_and_hard_settlement_only_count_victories(self):
        ids = list(self.store.profile_raw(self.uid)["avatars"])[:3]
        team = [[iid, lane, .2] for lane, iid in enumerate(ids)]
        for diff, sign, action in ((0, 1, "normal-win"), (1, 1, "hard-win"), (0, 2, "normal-loss")):
            started = self.rpc("user.pk_combat", "start-" + action,
                               cid="M_001_1", diff=diff, team=team, team_num=0)
            finish = self.rpc("user.pve_finish", action, fight_id=started["fight_id"],
                              cid="M_001_1", diff=diff, sign=sign, teams={})
            self.assertEqual(finish["sign"], sign)
            self.assertTrue(self.rpc("user.pve_finish", action, fight_id=started["fight_id"],
                                     cid="M_001_1", diff=diff, sign=sign, teams={})["replayed"])
        info = self.rpc("user.adventure_tasks_info", "read-wins")
        self.assertEqual(self.row(info, "daily", "normal_wins")["count"], 1)
        self.assertEqual(self.row(info, "daily", "hard_wins")["count"], 1)

    def test_nominal_payments_repeat_claim_all_and_random_pools(self):
        for index in range(4):
            self.rpc("user.pay" if index % 2 else "user.local_pay_test",
                     "pay-" + str(index), pid="local_10000", order_id="adventure-" + str(index))
        self.rpc("user.appstore_pay", "alias-retry", pid="local_10000", order_id="adventure-0")
        info = self.rpc("user.adventure_tasks_info", "read-pay")
        self.assertEqual(info["paid_yuan"], 4000)
        self.assertEqual(info["repeat"]["available_count"], 2)
        repeated = self.rpc("user.adventure_task_claim", "repeat-1", kind="repeat", key="2000")
        self.assertEqual(repeated["repeat_awarded_count"], 2)
        self.assertEqual(sum(repeated["award"]["avatar"].values()), 2)
        blocked = skin_acquisition_blocked_ids(self.config["cfg"])
        self.assertTrue(set(repeated["award"]["avatar"]).isdisjoint(blocked))
        self.assertEqual(self.rpc("user.adventure_task_claim", "repeat-1", kind="repeat", key="2000")["award"], repeated["award"])
        self.assertEqual(self.rpc("user.adventure_tasks_info", "read-pay-2")["repeat"]["available_count"], 0)
        first = self.rpc("user.adventure_task_claim", "pay-6", kind="milestone", key="6")
        self.assertEqual(sum(first["award"]["avatar"].values()), 1)
        gear = self.rpc("user.adventure_task_claim", "pay-30", kind="milestone", key="30")
        eid = next(iter(gear["award"]["equip"]))
        self.assertNotIn(eid, equipment_exclusive_ids(self.config["cfg"]))
        self.assertIn(eid, self.store.adventure.equipment)

    def test_legacy_total_special_heroes_and_capacity_rollback(self):
        def legacy(profile):
            profile["attrs"]["pay_total"] = 0
            profile["attrs"]["pay_money"] = 0
            profile.setdefault("task", {})["pay_total"] = 10000
            profile["attrs"]["avatar_len"] = len(profile["avatars"])
            return profile, {}
        self.store.atomic_update(self.uid, legacy)
        self.assertEqual(self.rpc("user.adventure_tasks_info", "legacy-read")["paid_yuan"], 10000)
        before = self.store.profile_raw(self.uid)
        with self.assertRaises(GameplayFault) as caught:
            self.rpc("user.adventure_task_claim", "special-full", kind="milestone", key="5000")
        self.assertEqual(caught.exception.code, "AvatarCapacity")
        self.assertEqual(self.store.profile_raw(self.uid)["avatars"], before["avatars"])
        self.assertFalse(self.row(self.rpc("user.adventure_tasks_info", "legacy-unclaimed"),
                                  "milestones", "5000")["claimed"])
        def expand(profile):
            profile["attrs"]["avatar_len"] += 10
            return profile, {}
        self.store.atomic_update(self.uid, expand)
        for key, aid in (("5000", "A_1310_6"), ("10000", "A_1226_6")):
            reward = self.rpc("user.adventure_task_claim", "special-" + key,
                              kind="milestone", key=key)
            self.assertEqual(reward["award"], {"avatar": {aid: 1}})
            self.assertIn(aid, {row["aid"].split("|")[0] for row in
                                self.store.profile_raw(self.uid)["avatars"].values()})

    def test_equipment_capacity_failure_keeps_milestone_unclaimed(self):
        self.config["cfg"]["system_simple"]["equip_config"][0] = 1
        def full(profile):
            profile["attrs"]["pay_total"] = 30
            profile["my_equips"] = {"eq0": {"eid": "E_1001_3", "lv": 1}}
            return profile, {}
        self.store.atomic_update(self.uid, full)
        with self.assertRaises(GameplayFault) as caught:
            self.rpc("user.adventure_task_claim", "gear-full", kind="milestone", key="30")
        self.assertEqual(caught.exception.code, "EquipCapacity")
        self.assertFalse(self.row(self.rpc("user.adventure_tasks_info", "gear-read"),
                                  "milestones", "30")["claimed"])
        self.assertEqual(len(self.store.profile_raw(self.uid)["my_equips"]), 1)
        self.config["cfg"]["system_simple"]["equip_config"][0] = 2
        self.assertEqual(sum(self.rpc("user.adventure_task_claim", "gear-full",
                                      kind="milestone", key="30")["award"]["equip"].values()), 1)


if __name__ == "__main__":
    unittest.main()
