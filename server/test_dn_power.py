"""Native DN nodes floor researched bound stats before the team bonus."""
import copy
import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from gameplay_roster import GameplayRosterEquipment


class DnPowerTest(unittest.TestCase):
    def test_weighted_bound_current_ap_uses_guild_research_before_dn_floor(self):
        cfg = json.loads((Path(__file__).resolve().parents[1] /
                          "config/reconstruction/full-config.json").read_text(encoding="utf-8"))
        roster = GameplayRosterEquipment(None, cfg)
        iid = "A_1003_5|36"
        profile = {
            "avatars": {iid: {"aid": iid, "lv": 99, "phase": 1,
                              "culture_schema": "weighted-v2", "hp": 1200,
                              "ap": 130, "de_ph": 75, "de_ma": 82}},
            "attrs": {"dn": {"1": [2, iid, [90, 0, 0, 0, 0, 1]]},
                      "guild_graduate_skill": {"guild_attack": 1}},
        }
        # A legacy snapshot at level 90 must not hide the owned hero's
        # current level 99. Guild research is applied before the DN floor.
        self.assertEqual(roster._destiny_team_bonuses(profile)["ap"], 75)
        refreshed = copy.deepcopy(profile)
        refreshed['attrs']['dn']['1'] = [2, iid]
        self.assertEqual(roster._destiny_team_bonuses(profile), roster._destiny_team_bonuses(refreshed))
        no_research = copy.deepcopy(profile)
        no_research["attrs"]["guild_graduate_skill"] = {}
        self.assertEqual(roster._destiny_team_bonuses(no_research)["ap"], 74)


if __name__ == "__main__":
    unittest.main()
