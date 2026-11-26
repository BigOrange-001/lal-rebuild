"""Hero challenges: config, shared VIP quota, energy, drops, helpers and no sweeps."""
import random
import sqlite3
import unittest
from pathlib import Path

from gameplay_combat import GameplayCombat
from gateway import load_game_config
from game_calendar import next_daily_reset
from player_store import GameplayFault, PlayerStore
from power_balance_104 import normalize_team_power
import hero_challenge

ROOT = Path(__file__).resolve().parents[1]
STAGES = ("P_300_1", "P_300_2", "P_300_3")


class HeroChallengeTests(unittest.TestCase):
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
            p["coin"] = 1000; p["lv"] = 125; p["attrs"]["avatar_len"] = 1000
            p["energy"] = {"$date": self.clock.now() - 10 ** 7}; p["attrs"]["energy_extra"] = 1000
            return p, {}
        self.store.atomic_update(self.uid, seed)
        self.team = [[aid, i, .2] for i, aid in enumerate(list(self.store.profile_raw(self.uid)["avatars"])[:3])]

    def action(self):
        self.sequence += 1
        return f"a{self.sequence}"

    def start(self, cid):
        return self.combat._start_main(self.uid, {"cid": cid, "diff": 0, "team": self.team, "actionID": self.action()})

    def finish(self, started, win=True):
        return self.combat._finish(self.uid, {"cid": started["cid"], "diff": 0, "fight_id": started["fight_id"],
                                              "sign": 1 if win else 2, "combat_star": 3 if win else 0,
                                              "actionID": self.action()})

    def left(self):
        stage = self.config["cfg"]["combat_ploy"]["P_300_1"]
        return hero_challenge.remaining(self.store.profile_raw(self.uid), stage, self.clock.now())

    def set_vip(self, level):
        def vip(p):
            p["vip_lv"] = level; return p, {}
        self.store.atomic_update(self.uid, vip)

    def test_config_tiers_power_energy_and_drops(self):
        cfg = self.config["cfg"]
        chapter = cfg["battle_ploy"]["P_300"]
        self.assertEqual((chapter["name"], chapter["combat"]), ("英雄挑战", 3))
        self.assertIs(self.config["combat_ploy"], cfg["combat_ploy"])
        expected = ((30, 2_000_000, 3000), (50, 50_000_000, 6600), (70, 1_000_000_000, 10000))
        for cid, (energy, power, chance) in zip(STAGES, expected):
            stage = cfg["combat_ploy"][cid]
            self.assertEqual(stage["energy"], energy)
            self.assertEqual(stage["recommended_power_by_diff"], {"0": power})
            # The fitted enemy budget is what the shown recommendation stands for.
            self.assertAlmostEqual(normalize_team_power(stage["enemy_snapshot_power"]) / power, 1, places=3)
            self.assertEqual(stage["hero_challenge"]["aid"], "A_1803_5")
            self.assertEqual(stage["hero_challenge"]["chance_bp"], chance)
            self.assertEqual(stage["team2"][0][0], "A_1803_6")
            self.assertEqual(stage["team2"][0][5], 1)
            self.assertTrue(stage["sweep_disabled"])
        self.assertEqual(cfg["avatar"]["A_1803_5"]["res"], "MOD_DEMONBLADE_5")
        self.assertEqual(cfg["system_simple"]["hero_challenge"], {"base_attempts": 2, "vip_step": 3, "consume": "victory"})

    def test_roll_drop_chances(self):
        stages = self.config["cfg"]["combat_ploy"]
        for cid, chance in zip(STAGES, (.30, .66, 1.0)):
            rng = random.Random(cid)
            hits = sum(hero_challenge.roll_drop(self.config, stages[cid], rng) == "A_1803_5" for _ in range(20000))
            self.assertAlmostEqual(hits / 20000, chance, delta=.015)

    def test_tiers_share_two_daily_wins_and_losses_are_free(self):
        lost = self.start("P_300_3")
        self.assertEqual(lost["energy_cost"], 70)
        self.finish(lost, win=False)
        self.assertEqual(self.left(), 2)
        won = self.finish(self.start("P_300_3"))
        self.assertIn("A_1803_5", [str(hero.get("aid", "")).split("|")[0] for hero in won["get_avatars"].values()])
        self.assertEqual(self.left(), 1)
        self.finish(self.start("P_300_1"))
        self.assertEqual(self.left(), 0)
        before = self.store.profile_raw(self.uid)
        for cid in STAGES:
            with self.assertRaises(GameplayFault) as caught:
                self.start(cid)
            self.assertEqual(caught.exception.code, "ActivityAttemptsExhausted")
        self.assertEqual(self.store.profile_raw(self.uid)["energy"], before["energy"])
        self.clock.value = next_daily_reset(self.clock.now())
        self.assertEqual(self.left(), 2)

    def test_vip_adds_one_attempt_per_three_levels(self):
        for vip, limit in ((0, 2), (2, 2), (3, 3), (5, 3), (6, 4), (15, 7)):
            self.set_vip(vip)
            self.assertEqual(self.left(), limit, vip)

    def test_energy_cost_per_tier(self):
        for cid, cost in zip(STAGES, (30, 50, 70)):
            self.assertEqual(self.start(cid)["energy_cost"], cost)

    def test_sweep_is_refused_even_with_three_stars(self):
        self.finish(self.start("P_300_1"))
        before = self.store.profile_raw(self.uid)
        with self.assertRaises(GameplayFault) as caught:
            self.combat.dispatch(self.uid, "user.stage_sweep",
                                 {"cid": "P_300_1", "diff": 0, "times": 1, "max_coin": 0, "actionID": "sweep"})
        self.assertEqual(caught.exception.code, "SweepLocked")
        after = self.store.profile_raw(self.uid)
        self.assertEqual(after["records"].get("hero_challenge"), before["records"].get("hero_challenge"))
        self.assertEqual(after["energy"], before["energy"])

    def test_reapplying_overlay_is_a_no_op(self):
        import copy
        document = copy.deepcopy({"cfg": self.config["cfg"]})
        snapshot = copy.deepcopy(document)
        hero_challenge.apply_hero_challenge(document)
        self.assertEqual(document, snapshot)


if __name__ == "__main__":
    unittest.main()
