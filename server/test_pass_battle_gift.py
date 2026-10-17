"""Chapter and full-tower reward claims use settled progress and one-time markers."""
import copy
import json
import sqlite3
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from gameplay_economy import GameplayEconomy
from gameplay_combat import GameplayCombat
from player_store import GameplayFault, PlayerStore


class PassBattleGiftTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = json.loads((Path(__file__).resolve().parents[1] /
                                 "config/reconstruction/full-config.json").read_text(encoding="utf-8"))

    def setUp(self):
        self.config = copy.deepcopy(self.source)
        cfg = self.config["cfg"]
        for diff, multiplier in (("0", 1), ("1", 2)):
            for number in range(1, 31):
                bid = f"M_{number:03d}"
                cfg["pass_battle_gift"][diff][bid] = {
                    "need_star": int(cfg["battle_main"][bid]["combat"]) * 3,
                    "gift": {"coin": number * 60 * multiplier},
                }
        cfg["pass_battle_gift"].setdefault("-1", {})["P_200"] = {
            "need_star": 450, "gift": {"coin": 66666666},
        }
        self.tower_floors = int(cfg["battle_ploy"]["P_200"]["combat"])
        self.assertEqual(self.tower_floors, 150)
        self.db = sqlite3.connect(":memory:", check_same_thread=False)
        self.addCleanup(self.db.close)
        self.store = PlayerStore(self.db, self.config)
        self.uid = self.store.login("reward-tester")["uid"]
        self.economy = GameplayEconomy(self.store, self.config)

    def _progress(self, bid, diff, stars, *, tower_wins=True, claimed=False):
        bucket = "normal" if diff == 0 else "hard" if diff == 1 else "ploy"

        def mutate(profile):
            profile["combat_score"][bucket][bid] = ["1" if claimed else "0", stars]
            if bid == "P_200" and tower_wins:
                floors = [f"P_200_{number}" for number in range(1, self.tower_floors + 1)]
                profile.setdefault("ploy_cids", {})[bid] = floors
                profile.setdefault("records", {})["combat_ploy"] = {cid: 1 for cid in floors}
                profile["records"]["tower_floor"] = self.tower_floors + 1
            elif bid == "P_200":
                profile.setdefault("ploy_cids", {}).pop(bid, None)
                profile.setdefault("records", {}).pop("combat_ploy", None)
            return profile, {}

        self.store.atomic_update(self.uid, mutate)

    def _claim(self, bid, diff, action_id):
        return self.economy.get_pass_battle_gift(
            self.uid, {"bid": bid, "diff": diff, "actionID": action_id})

    def _locked(self, bid, diff, action_id, code):
        with self.assertRaises(GameplayFault) as failure:
            self._claim(bid, diff, action_id)
        self.assertEqual(failure.exception.code, code)

    def test_normal_hard_values_and_existing_claim_marker(self):
        self._progress("M_010", 0, [3] * 6)
        self._progress("M_010", 1, [3] * 6)
        before = self.store.profile_raw(self.uid)["coin"]
        normal = self._claim("M_010", 0, "normal-claim")
        hard = self._claim("M_010", 1, "hard-claim")
        self.assertEqual(hard["coin"] - before, 1800)
        self.assertEqual(normal["coin"] - before, 600)
        self.assertEqual(self.store.profile_raw(self.uid)["combat_score"]["hard"]["M_010"][0], "1")
        self._locked("M_010", 1, "hard-new", "AlreadyClaimed")
        self._progress("M_009", 0, [3] * 6, claimed=True)
        self._locked("M_009", 0, "old-claimed", "AlreadyClaimed")

    def test_replaying_cleared_stage_keeps_chapter_claimed(self):
        self._progress("M_001", 0, [3] * 3, claimed=True)
        profile = self.store.profile_raw(self.uid)
        team = [[aid, line, .2] for line, aid in enumerate(profile['team'][0][:3])]
        combat = GameplayCombat(self.store, self.config)
        started = combat._start_main(self.uid, {'cid': 'M_001_1', 'diff': 0, 'team': team})
        combat._finish(self.uid, {'cid': 'M_001_1', 'diff': 0,
                                  'fight_id': started['fight_id'], 'sign': 1,
                                  'combat_star': 3, 'actionID': 'repeat-cleared'})
        self.assertEqual(self.store.profile_raw(self.uid)['combat_score']['normal']['M_001'][0], '1')
        self._locked('M_001', 0, 'no-second-reward', 'AlreadyClaimed')

    def test_tower_requires_every_floor_and_three_stars(self):
        self._progress("P_200", -1, [3] * (self.tower_floors - 1), tower_wins=False)
        self._locked("P_200", -1, "short-stars", "StageRewardLocked")
        self._progress("P_200", -1, [3] * (self.tower_floors - 1) + [2])
        self._locked("P_200", -1, "two-star", "StageRewardLocked")
        self._progress("P_200", -1, [3] * self.tower_floors, tower_wins=False)
        self._locked("P_200", -1, "no-floor-records", "StageRewardLocked")
        self._progress("P_200", -1, [3] * self.tower_floors)
        def remove_final_win(profile):
            del profile["records"]["combat_ploy"][f"P_200_{self.tower_floors}"]
            return profile, {}
        self.store.atomic_update(self.uid, remove_final_win)
        self._locked("P_200", -1, "missing-last-win", "StageRewardLocked")

    def test_tower_one_time_reward_action_replay_and_new_action(self):
        self._progress("P_200", -1, [3] * self.tower_floors)
        before = self.store.profile_raw(self.uid)["coin"]
        first = self._claim("P_200", -1, "tower-once")
        self.assertFalse(first["replayed"])
        self.assertEqual(first["coin"] - before, 66666666)
        self.assertEqual(first["combat_score"]["ploy"]["P_200"][0], "1")
        self.assertIn("P_200", first["records"]["pass_battle_gift"]["-1"])
        replay = self._claim("P_200", -1, "tower-once")
        self.assertTrue(replay["replayed"])
        self.assertEqual(replay["coin"], first["coin"])
        self._locked("P_200", -1, "tower-again", "AlreadyClaimed")
        self.assertEqual(self.store.profile_raw(self.uid)["coin"], first["coin"])

    def test_legacy_100_floor_claim_stays_claimed_without_new_payout(self):
        old_stars = [3] * 100
        self._progress("P_200", -1, old_stars, tower_wins=False)
        self._locked("P_200", -1, "old-progress-only", "StageRewardLocked")
        def mark_old_claim(profile):
            profile["records"].setdefault("pass_battle_gift", {}).setdefault("-1", []).append("P_200")
            return profile, {}
        self.store.atomic_update(self.uid, mark_old_claim)
        before = self.store.profile_raw(self.uid)["coin"]
        self._locked("P_200", -1, "old-durable-claim", "AlreadyClaimed")
        self.assertEqual(self.store.profile_raw(self.uid)["coin"], before)
        self._progress("P_200", -1, old_stars, tower_wins=False, claimed=True)
        self._locked("P_200", -1, "old-score-marker", "AlreadyClaimed")


if __name__ == "__main__":
    unittest.main()
