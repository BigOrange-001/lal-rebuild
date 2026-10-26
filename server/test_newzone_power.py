"""The activity power rank uses the same owned-team calculation as arena."""
import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from gameplay_competition import GameplayCompetition
from gameplay_roster import GameplayRosterEquipment
from bot_names import bot_name_for_uid


class _ProfileStore:
    def __init__(self, profile):
        self.value = profile

    def profile_raw(self, uid):
        return self.value


class NewzonePowerTest(unittest.TestCase):
    def test_rank_power_includes_captain_talent_and_equipment(self):
        cfg = json.loads((Path(__file__).resolve().parents[1] /
                          "config/reconstruction/full-config.json").read_text(encoding="utf-8"))
        iid = "A_1078_6|1"
        profile = {
            "team": [[iid, None, None, None, None, None]],
            "avatars": {iid: {"aid": "A_1078_6", "lv": 90, "slv": 9,
                              "phase": 2, "talent": "T_03_02"}},
            "my_equips": {"one": {"eid": "E_1001_1", "lv": 10,
                                  "stat_roll_ppm": 1000000}},
            "as_equips": [["one"], [], [], [], [], []],
            "attrs": {"dn": {}},
        }
        store = _ProfileStore(profile)
        roster = GameplayRosterEquipment(store, cfg)
        arena = GameplayCompetition(store, cfg)
        units = arena._own_team(profile, {"team_num": 0, "team": [[iid, 0, 0.2]]})
        expected = arena._team_power(units)
        ranks = roster._get_newzone_ranks("my-account")["power"]
        actual = next(row[3] for row in ranks if row[0] == "my-account")
        self.assertEqual(actual, expected)
        plain = [{**unit, "leader_skill": None, "talent": None} for unit in units]
        self.assertGreater(actual, arena._team_power(plain))
        npc = next(row for row in ranks if row[0] != "my-account")
        bot = next(bot for bot in arena.pvp_bots if bot["uid"] == npc[0])
        self.assertEqual(npc[1], bot_name_for_uid(npc[0]))
        self.assertEqual(npc[3], arena._team_power(arena._bot_units(bot)))

if __name__ == "__main__":
    unittest.main()
