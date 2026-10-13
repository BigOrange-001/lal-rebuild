"""Generated arena names and persistent local-helper names stay safe and stable."""
import json
import random
import sqlite3
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from bot_names import BOT_NAMES, bot_name_for_uid, sample_bot_names
from gameplay_social import GameplaySocial
from player_store import PlayerStore


class BotNamesTest(unittest.TestCase):
    def test_safe_pool_distinct_sample_and_uid_stability(self):
        self.assertGreater(len(BOT_NAMES), 100)
        self.assertEqual(len(BOT_NAMES), len(set(BOT_NAMES)))
        self.assertTrue(all(len(name) <= 12 and name.strip() == name for name in BOT_NAMES))
        rng = random.Random(2020)
        chosen = sample_bot_names(rng, 9)
        self.assertEqual(len(set(chosen)), 9)
        self.assertEqual(bot_name_for_uid("92000001"), bot_name_for_uid("92000001"))
        self.assertIn(bot_name_for_uid("92000001"), BOT_NAMES)

    def test_social_preview_and_assist_keep_same_uid_name(self):
        cfg = json.loads((Path(__file__).resolve().parents[1] /
                          "config/reconstruction/full-config.json").read_text(encoding="utf-8"))
        db = sqlite3.connect(":memory:", check_same_thread=False)
        self.addCleanup(db.close)
        store = PlayerStore(db, cfg)
        social = GameplaySocial(store, cfg)
        repeat = GameplaySocial(store, cfg)
        for bot in social.bots:
            uid = bot["uid"]
            self.assertEqual(bot["name"], repeat.by_uid[uid]["name"])
            self.assertEqual(bot["name"], social.lookup_assist(uid)["name"])
            self.assertEqual(bot["name"], social._friend_card(uid)["name"])
        bot = social.bots[0]
        hero_id = next(iid for iid in bot["team"][0] if iid)
        bot["my_equips"]["wash-example"] = {
            "eid": "E_1001_1", "lv": 10, "stat_roll_ppm": 1_000_000,
            "wash_schema_version": 1, "new_4attrs": {"hit": 50, "flee": 0, "crit": 20, "tough": 0},
        }
        bot["as_equips"][0] = ["wash-example"]
        derived = social.roster.battle_attributes(bot, hero_id)
        self.assertGreater(derived["hit"], 0)
        self.assertEqual(social._avatar_card(bot, hero_id)["new_4attrs"],
                         {key: derived[key] for key in ("hit", "flee", "crit", "tough")})


if __name__ == "__main__":
    unittest.main()
