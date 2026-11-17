"""Guild boss stages need a day's attacks instead of one capped hit."""
import json
import sqlite3
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from gameplay_guild_boss import GUILD_BOSS_HP, GameplayGuildBoss
from player_store import PlayerStore


class GuildBossHpTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.config = json.loads((Path(__file__).resolve().parents[1] /
                                 "config/reconstruction/full-config.json").read_text(encoding="utf-8"))

    def setUp(self):
        db = sqlite3.connect(":memory:", check_same_thread=False)
        self.addCleanup(db.close)
        store = PlayerStore(db, self.config)
        self.guild = next(h for h in store.gameplay_handlers if isinstance(h, GameplayGuildBoss))

    def test_each_stage_outlasts_many_capped_hits_and_grows(self):
        attack = self.guild.rules["guild_boss"]["attack"]
        cap = int(attack["damage_cap"])
        hp = [self.guild._boss_template("guild_boss", stage)["max_hp"] for stage in range(1, 6)]
        self.assertEqual(hp, list(GUILD_BOSS_HP))
        self.assertEqual(hp, sorted(hp))
        self.assertGreater(hp[0], cap * 5)
        # The player's share (30% after AI help) is reachable with 8 capped attacks.
        self.assertLessEqual(hp[-1] * 0.30, cap * 8 * 1.25)
        # World boss is unchanged.
        world = self.guild.rules["world_boss"]["bosses"][0]["max_hp"]
        self.assertEqual(self.guild._boss_template("world_boss", 1)["max_hp"], world)


if __name__ == "__main__":
    unittest.main()
