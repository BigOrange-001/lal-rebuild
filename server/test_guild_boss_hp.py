"""Guild boss stages need a day's attacks instead of one capped hit."""
import json
import sqlite3
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))

from gameplay_guild_boss import GUILD_BOSS_HP, GameplayGuildBoss
from player_store import GameplayFault, PlayerStore


class GuildBossHpTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.config = json.loads((Path(__file__).resolve().parents[1] /
                                 "config/reconstruction/full-config.json").read_text(encoding="utf-8"))

    def setUp(self):
        db = sqlite3.connect(":memory:", check_same_thread=False)
        self.addCleanup(db.close)
        self.store = PlayerStore(db, self.config)
        self.guild = next(h for h in self.store.gameplay_handlers if isinstance(h, GameplayGuildBoss))

    def test_each_stage_outlasts_many_capped_hits_and_grows(self):
        attack = self.guild.rules["guild_boss"]["attack"]
        cap = int(attack["damage_cap"])
        hp = [self.guild._boss_template("guild_boss", stage)["max_hp"] for stage in range(1, 6)]
        self.assertEqual(hp, list(GUILD_BOSS_HP))
        self.assertEqual(hp, sorted(hp))
        self.assertGreater(hp[0], cap * 5)
        # World boss is unchanged.
        world = self.guild.rules["world_boss"]["bosses"][0]["max_hp"]
        self.assertEqual(self.guild._boss_template("world_boss", 1)["max_hp"], world)


    def test_stage_five_can_be_defeated_with_the_real_daily_attack_budget(self):
        profile = self.store.initial_profile("123", "guild-boss-test")
        self.guild._guild(profile, create=True)
        profile["boss_state"] = {"guild_boss": {"stage": 5}}
        now = 1_800_000_000
        attacks = self.guild.rules["guild_boss"]["attack"]
        with patch.object(self.guild, "_require_boss_window"), \
             patch.object(self.store.clock, "now", side_effect=lambda: now), \
             patch("gameplay_roster.GameplayRosterEquipment.battle_attributes", return_value={"ap": 200_000}):
            state = self.guild._boss_state(profile, "guild_boss")
            # Start at the configured AI damage floor and spend the real limit.
            floor = self.guild.world.settings["ai_boss_hp_floor"]
            state["boss"]["current_hp"] = round(state["boss"]["max_hp"] * floor)
            for _ in range(5):
                self.guild._buy_attack_number(profile, {})
            with self.assertRaisesRegex(GameplayFault, "purchase limit"):
                self.guild._buy_attack_number(profile, {})
            self.assertEqual(state["free_num"], 8)
            damage = []
            for _ in range(8):
                damage.append(self.guild._attack_associationboss(profile, {})[1]["attack_hp"])
                now += attacks["cooldown_seconds"]
        self.assertEqual(damage, [40_000] * 7 + [20_000])
        self.assertEqual(state["free_num"], 0)
        self.assertTrue(state["boss"]["is_end"])


if __name__ == "__main__":
    unittest.main()
