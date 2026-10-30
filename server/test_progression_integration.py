"""Cross-flow checks for the published hero, equipment, DN and activity rules."""

import copy
import json
import sqlite3
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from gameplay_combat import GameplayCombat
from gameplay_roster import GameplayRosterEquipment
from halo_progression import apply_halo_progression
from player_store import GameplayFault, PlayerStore


CONFIG = Path(__file__).resolve().parents[1] / "config/reconstruction/full-config.json"


class ProgressionIntegrationTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.config = apply_halo_progression(json.loads(CONFIG.read_text(encoding="utf-8")))

    def setUp(self):
        db = sqlite3.connect(":memory:", check_same_thread=False)
        self.addCleanup(db.close)
        self.store = PlayerStore(db, self.config)
        self.uid = self.store.login(self.id())["uid"]
        self.roster = GameplayRosterEquipment(self.store, self.config)
        self.combat = GameplayCombat(self.store, self.config)

    @staticmethod
    def hero(aid, suffix, *, level=1, phase=0, exp=0):
        iid = f"{aid}|{suffix}"
        return iid, {"id": iid, "aid": iid, "lv": level, "exp": exp,
                     "phase": phase, "slv": 1, "morph": 0, "limit_break": 0,
                     "hp": 0, "ap": 0, "de_ph": 0, "de_ma": 0}

    def team(self):
        return [[aid, index, .2] for index, aid in
                enumerate(list(self.store.profile_raw(self.uid)["avatars"])[:3])]

    def test_purple_level_base_truncates_before_later_stat_rounding(self):
        # AIR Avatar.getHpMax returns 62594 for this level 99 bare hero.
        # The untruncated Number is 62594.99999999999 and a later rounding
        # helper would incorrectly serialize 62595.
        target = self.hero("A_1101_5", "native-base", level=99)

        def seed(profile):
            profile["avatars"] = {target[0]: copy.deepcopy(target[1])}
            profile["team"] = [[None] * 6 for _ in range(3)]
            return profile, {}

        self.store.atomic_update(self.uid, seed)
        profile = self.store.profile_raw(self.uid)
        self.assertEqual(self.roster.battle_attributes(profile, target[0], hero_only=True)["hp"], 62594)

    def test_free_purple_promotion_then_biscuit_replay(self):
        target = self.hero("A_1101_5", "target", level=99, phase=2, exp=7)
        spare = self.hero("A_1002_4", "spare")
        biscuits = [self.hero("A_6992_4", f"biscuit-{index}") for index in range(5)]

        def seed(profile):
            profile["avatars"] = copy.deepcopy(dict([target, spare, *biscuits]))
            profile["team"] = [[None] * 6 for _ in range(3)]
            profile["gold"] = 100000
            profile["coin"] = 0
            return profile, {}

        self.store.atomic_update(self.uid, seed)
        before = self.store.profile_raw(self.uid)
        promoted = self.roster.dispatch(self.uid, "user.star_up", {
            "aid": target[0], "aids": [], "actionID": "promote-once"})
        self.assertEqual((promoted["id"], promoted["lv"], promoted["exp"], promoted["phase"]),
                         ("A_1101_6|target", 99, 7, 0))
        after_promotion = self.store.profile_raw(self.uid)
        self.assertEqual((after_promotion["gold"], after_promotion["coin"]),
                         (before["gold"], before["coin"]))
        self.assertTrue(all(iid in after_promotion["avatars"] for iid in
                            [spare[0], *(card[0] for card in biscuits)]))
        self.assertEqual(self.roster.dispatch(self.uid, "user.star_up", {
            "aid": target[0], "aids": [], "actionID": "promote-once"}), promoted)

        class CertainRoll:
            def randrange(self, limit):
                return 0

        self.roster.rng = CertainRoll()
        request = {"aid": promoted["id"], "aids": [card[0] for card in biscuits],
                   "actionID": "feed-biscuits-once"}
        fed = self.roster.dispatch(self.uid, "user.swallow_avatar", request)
        self.assertEqual(fed["avatar"]["slv"], 2)
        after_feed = self.store.profile_raw(self.uid)
        self.assertEqual(self.roster.dispatch(self.uid, "user.swallow_avatar", request), fed)
        self.assertEqual(self.store.profile_raw(self.uid), after_feed)
        self.assertIn(spare[0], after_feed["avatars"])
        self.assertTrue(all(card[0] not in after_feed["avatars"] for card in biscuits))

    def test_level_125_six_star_halo_and_hp_talent_bounds(self):
        item = {"eid": "E_1001_6", "lv": 125, "halo": {"lv": 0, "exp": 0}}
        # All equipment levels use the 100-level baseline: 600 paid washes
        # at 20 experience per attempt to complete the five halo ranks.
        self.assertEqual(self.roster._equip_wash_halo(item, 600, "coin"),
                         {"lv": 5, "exp": 0})

        iid, hero = self.hero("A_1101_6", "talent", level=125, phase=3)
        profile = self.store.profile_raw(self.uid)
        profile["avatars"] = {iid: hero}
        profile["team"] = [[iid, None, None, None, None, None] for _ in range(3)]
        base = self.roster.battle_attributes(profile, iid)
        hero["talent"] = "T_04_01"
        ten = self.roster.battle_attributes(profile, iid)
        hero["talent"] = "T_04_07"
        seventy = self.roster.battle_attributes(profile, iid)
        self.assertEqual(ten["hp"], int(base["hp"] * 1.10))
        self.assertEqual(seventy["hp"], int(base["hp"] * 1.70))
        for stat in ("ap", "de_ph", "de_ma"):
            self.assertEqual((ten[stat], seventy[stat]), (base[stat], base[stat]))

    def test_halo_coin_and_mark_ten_wash_boundaries(self):
        for kind in ("coin", "mark"):
            with self.subTest(currency=kind):
                item = {"eid": "E_1001_6", "lv": 125, "halo": {"lv": 0, "exp": 0}}
                for _ in range(59):
                    item["halo"] = self.roster._equip_wash_halo(item, 10, kind)
                self.assertEqual(item["halo"], {"lv": 4, "exp": 4120})
                item["halo"] = self.roster._equip_wash_halo(item, 9, kind)
                self.assertEqual(item["halo"], {"lv": 4, "exp": 4300})
                item["halo"] = self.roster._equip_wash_halo(item, 1, kind)
                self.assertEqual(item["halo"], {"lv": 5, "exp": 0})
                self.assertEqual(self.roster._equip_wash_halo(item, 10, kind),
                                 {"lv": 5, "exp": 0})

    def test_halo_boundaries_are_identical_for_all_equipment_levels(self):
        for equipment_level in (1, 10, 50, 99, 100, 125):
            for kind in ('coin', 'mark'):
                with self.subTest(level=equipment_level, currency=kind):
                    item = {'eid': 'E_1001_6', 'lv': equipment_level, 'halo': {'lv': 0, 'exp': 0}}
                    self.assertEqual(self.roster._equip_wash_halo(item, 47, kind), {'lv': 0, 'exp': 940})
                    self.assertEqual(self.roster._equip_wash_halo(item, 48, kind), {'lv': 1, 'exp': 0})
                    self.assertEqual(self.roster._equip_wash_halo(item, 599, kind), {'lv': 4, 'exp': 4300})
                    self.assertEqual(self.roster._equip_wash_halo(item, 600, kind), {'lv': 5, 'exp': 0})

    def test_dn_maximum_rates_and_final_level_boundary(self):
        simple = self.config["cfg"]["system_simple"]
        self.assertEqual(simple["dn_lv"], 50)
        for key, row in simple["dn"].items():
            maximum = float(row[6]) + 49 * float(row[7])
            self.assertAlmostEqual(maximum, .35 if key == "1" else .07)

        def seed(profile):
            profile["attrs"]["dn"] = {"1": [49, None], "2": [49, None]}
            profile["attrs"]["dn_stone"] = 1000
            profile["lv"] = 125
            return profile, {}

        self.store.atomic_update(self.uid, seed)
        for key in ("1", "2"):
            self.roster.dispatch(self.uid, "user.dn_lvup", {
                "key": key, "lv": 49, "actionID": f"dn-final-{key}"})
        profile = self.store.profile_raw(self.uid)
        self.assertEqual(profile["attrs"]["dn"]["1"][0], 50)
        self.assertEqual(profile["attrs"]["dn"]["2"][0], 50)
        with self.assertRaises(GameplayFault) as caught:
            self.roster.dispatch(self.uid, "user.dn_lvup", {
                "key": "1", "lv": 50, "actionID": "dn-over-cap"})
        self.assertEqual(caught.exception.code, "MaxLevel")

    def test_biscuit_activity_spends_no_attempt_at_fight_start(self):
        team = self.team()
        for index in range(4):
            self.combat._start_main(self.uid, {"cid": "P_109_1", "diff": 0,
                                               "team": team, "actionID": f"biscuit-run-{index}"})
        uses = self.store.profile_raw(self.uid)["records"].get("material_activity", {}).get("uses", {})
        self.assertEqual(uses.get("P_109", 0), 0)

    def test_tower_101_hero_and_soul_issue_once_on_replay(self):
        skin_id = "A_1201_6"
        self.assertIn(skin_id, self.config["cfg"]["system_simple"]["skin_acquisition_blocked_heroes"])
        self.assertIn(skin_id, self.config["pve"]["combat_ploy"]["P_200_101"]["tower_hero_candidates"])

        class SkinChoice:
            def choice(self, values):
                return skin_id if skin_id in values else values[0]

            def random(self):
                return 1.0

        self.combat._reward_rng = lambda uid, fight_id, pending, domain: SkinChoice()

        def unlock(profile):
            profile["records"]["tower_floor"] = 101
            return profile, {}

        self.store.atomic_update(self.uid, unlock)
        before = self.store.profile_raw(self.uid)
        started = self.combat._start_main(self.uid, {"cid": "P_200_101", "diff": 0,
                                                    "team": self.team()})
        finish = {"cid": "P_200_101", "diff": 0, "fight_id": started["fight_id"],
                  "sign": 1, "combat_star": 3,
                  "teams": {"team_a": started["orgin_team_a"],
                            "team_b": started["orgin_team_b"]},
                  "actionID": "tower-101-first"}
        won = self.combat._finish(self.uid, finish)
        after = self.store.profile_raw(self.uid)
        self.assertEqual(len(won["get_avatars"]), 1)
        self.assertEqual(next(iter(won["get_avatars"].values()))["aid"].split("|")[0], skin_id)
        self.assertEqual(len(after["avatars"]), len(before["avatars"]) + 1)
        self.assertEqual(won["tower_soul_reward"], {skin_id: 120})
        self.assertEqual(after["attrs"]["tower_skin_soul_credit"][skin_id], 120)
        replay = self.combat._finish(self.uid, finish)
        self.assertTrue(replay["replayed"])
        self.assertEqual(self.store.profile_raw(self.uid), after)


if __name__ == "__main__":
    unittest.main()
