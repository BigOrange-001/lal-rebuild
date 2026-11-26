"""Three-star sweeps: quota, price confirmation, attempts, energy, rewards and replay."""
import sqlite3
import unittest
from pathlib import Path

from gameplay_combat import GameplayCombat
from gateway import load_game_config
from game_calendar import next_daily_reset
from player_store import GameplayFault, PlayerStore
import stage_sweep

ROOT = Path(__file__).resolve().parents[1]


class StageSweepTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.config = load_game_config(ROOT / "config/reconstruction/full-config.json", 1792425600)

    def setUp(self):
        class Clock:
            value = 1792425600
            def now(self):
                return self.value
        self.clock = Clock()
        db = sqlite3.connect(":memory:", check_same_thread=False)
        self.addCleanup(db.close)
        self.store = PlayerStore(db, self.config, self.clock)
        self.uid = self.store.login(self.id())["uid"]
        self.combat = GameplayCombat(self.store, self.config)
        self.sequence = 0
        def seed(p):
            p["coin"] = 1000; p["lv"] = 125; p["attrs"]["energy_extra"] = 100000; p["attrs"]["avatar_len"] = 1000
            return p, {}
        self.store.atomic_update(self.uid, seed)
        self.team = [[aid, i, .2] for i, aid in enumerate(list(self.store.profile_raw(self.uid)["avatars"])[:3])]

    def action(self):
        self.sequence += 1
        return f"a{self.sequence}"

    def clear(self, cid, diff=0, stars=3):
        started = self.combat._start_main(self.uid, {"cid": cid, "diff": diff, "team": self.team, "actionID": self.action()})
        return self.combat._finish(self.uid, {"cid": cid, "diff": diff, "fight_id": started["fight_id"], "sign": 1,
                                              "combat_star": stars, "actionID": self.action()})

    def refill(self):
        def full(p):
            p["energy"] = {"$date": self.clock.now() - 10 ** 7}; return p, {}
        self.store.atomic_update(self.uid, full)

    def sweep(self, cid, times, diff=0, max_coin=0, action=None, refill=True):
        if refill and action is None:
            self.refill()
        return self.combat.dispatch(self.uid, "user.stage_sweep", {"cid": cid, "diff": diff, "times": times,
                                                                   "max_coin": max_coin, "actionID": action or self.action()})

    def profile(self):
        return self.store.profile_raw(self.uid)

    def energy(self):
        from gameplay_energy import energy_state
        return energy_state(self.profile(), self.config, self.clock.now())["current"]

    def test_sweep_needs_three_stars_and_is_atomic_when_refused(self):
        with self.assertRaises(GameplayFault) as caught:
            self.sweep("M_001_1", 1)
        self.assertEqual(caught.exception.code, "SweepLocked")
        self.clear("M_001_1", stars=2)
        self.refill()
        before = self.profile()
        with self.assertRaises(GameplayFault):
            self.sweep("M_001_1", 1, refill=False)
        self.assertEqual(self.profile(), before)
        self.clear("M_001_1", stars=3)
        self.assertEqual(self.sweep("M_001_1", 1)["sweep"]["times"], 1)

    def test_sweep_spends_energy_attempts_and_grants_repeat_rewards(self):
        self.clear("M_001_1")
        stage = self.config["cfg"]["combat_main"]["M_001_1"]
        self.refill()
        before, energy = self.profile(), self.energy()
        result = self.sweep("M_001_1", 3, refill=False)
        after = self.profile()
        self.assertEqual(energy - self.energy(), 3 * int(stage["energy"]))
        self.assertEqual(after["records"]["daily_stage_attempts"]["combat_main"]["M_001_1"], 4)
        self.assertEqual(after["gold"] - before["gold"], 3 * int(stage["gold"]))
        gift = result["sweep"]["gift_dict"]
        self.assertEqual(gift["gold"], 3 * int(stage["gold"]))
        self.assertNotIn("coin", gift)  # first-clear bricks are never repeated
        for row in stage["reward"].get("heroes", []):
            self.assertGreaterEqual(gift["avatar"][row["aid"]], 3 * row["num"])
        self.assertEqual(after["coin"], before["coin"])
        self.assertEqual(after["records"]["stage_sweep"]["used"], 3)
        self.assertEqual(after["pending_pve"], {})

    def test_free_quota_grows_with_vip_then_costs_bricks_without_cap(self):
        self.clear("M_001_1")
        def vip(p):
            p["vip_lv"] = 2; return p, {}
        self.store.atomic_update(self.uid, vip)
        free = stage_sweep.FREE_SWEEPS + 2 * stage_sweep.VIP_BONUS
        self.assertEqual(self.sweep("M_001_1", 25)["sweep"]["free_left"], free - 25)
        self.refill()
        before = self.profile()
        with self.assertRaises(GameplayFault) as caught:  # 5 free left, 7 paid: client showed too little
            self.sweep("M_001_1", 12, max_coin=6 * stage_sweep.EXTRA_COST, refill=False)
        self.assertEqual(caught.exception.code, "SweepPriceChanged")
        self.assertEqual(self.profile(), before)
        result = self.sweep("M_001_1", 12, max_coin=7 * stage_sweep.EXTRA_COST)["sweep"]
        self.assertEqual((result["free_used"], result["paid"], result["coin_cost"]), (5, 7, 140))
        self.assertEqual(self.profile()["coin"], before["coin"] - 140)
        def poor(p):
            p["coin"] = stage_sweep.EXTRA_COST - 1; return p, {}
        self.store.atomic_update(self.uid, poor)
        self.refill()
        before = self.profile()
        with self.assertRaises(GameplayFault) as caught:
            self.sweep("M_001_1", 1, max_coin=stage_sweep.EXTRA_COST, refill=False)
        self.assertEqual(caught.exception.code, "InsufficientCoin")
        self.assertEqual(self.profile(), before)

    def test_replay_returns_the_first_result_without_charging_again(self):
        self.clear("M_001_1")
        first = self.sweep("M_001_1", 2, action="same")
        after = self.profile()
        again = self.sweep("M_001_1", 2, action="same")
        self.assertTrue(again["replayed"])
        self.assertEqual(again["sweep"], first["sweep"])
        self.assertEqual(self.profile(), after)

    def test_material_sweeps_share_the_daily_victories(self):
        self.clear("P_102_1")
        from material_attempts_103 import remaining
        left = remaining(self.profile(), "P_102", self.clock.now())
        self.refill()
        before = self.profile()
        with self.assertRaises(GameplayFault) as caught:
            self.sweep("P_102_1", left + 1, refill=False)
        self.assertEqual(caught.exception.code, "SweepAttemptsShort")
        self.assertEqual(self.profile(), before)
        self.sweep("P_102_1", left)
        self.assertEqual(remaining(self.profile(), "P_102", self.clock.now()), 0)

    def test_elite_stage_sweeps_use_hard_stars(self):
        self.clear("M_001_1")
        with self.assertRaises(GameplayFault):
            self.sweep("M_001_1", 1, diff=1)
        self.clear("M_001_1", diff=1)
        result = self.sweep("M_001_1", 2, diff=1)
        self.assertEqual(result["sweep"]["diff"], 1)
        self.assertEqual(self.profile()["records"]["daily_stage_attempts"]["combat_main_hard"]["M_001_1"], 3)

    def test_insufficient_energy_and_bad_counts_are_refused(self):
        self.clear("M_001_1")
        for times in (0, stage_sweep.MAX_TIMES + 1, "3"):
            with self.assertRaises(GameplayFault):
                self.sweep("M_001_1", times)
        def tired(p):
            p["attrs"]["energy_extra"] = 0; p["energy"] = {"$date": self.clock.now()}; return p, {}
        self.store.atomic_update(self.uid, tired)
        with self.assertRaises(GameplayFault) as caught:
            self.sweep("M_001_1", 1, refill=False)
        self.assertEqual(caught.exception.code, "InsufficientEnergy")

    def test_new_game_day_restores_the_free_quota(self):
        self.clear("M_001_1")
        self.sweep("M_001_1", 3)
        self.clock.value = next_daily_reset(self.clock.value) + 1
        self.assertEqual(self.sweep("M_001_1", 1)["sweep"]["free_left"], stage_sweep.FREE_SWEEPS - 1)

    def test_config_publishes_the_sweep_rule_for_the_client(self):
        self.assertEqual(self.config["cfg"]["system_simple"]["stage_sweep"],
                         {"free": 20, "vip_bonus": 5, "extra_cost": 20, "stars": 3, "max_times": stage_sweep.MAX_TIMES})


if __name__ == "__main__":
    unittest.main()
