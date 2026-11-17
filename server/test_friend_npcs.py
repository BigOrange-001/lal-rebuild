"""Friend NPCs: real cultivation, bond lineups, growth and timed friend requests."""
import sqlite3
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from gateway import load_game_config
from gameplay_competition import GameplayCompetition
from gameplay_social import (GameplaySocial, MAX_PENDING_REQUESTS, REQUEST_WINDOW_SECONDS,
                             IGNORE_COOLDOWN_WINDOWS)
from player_store import PlayerStore

CONFIG_PATH = Path(__file__).resolve().parents[1] / "config/reconstruction/full-config.json"


class FakeClock:
    def __init__(self, now):
        self.value = now

    def now(self):
        return self.value


class FriendNpcTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # The runtime pipeline installs bonds and equipment bonds.
        cls.config = load_game_config(CONFIG_PATH)

    def setUp(self):
        self.db = sqlite3.connect(":memory:", check_same_thread=False)
        self.addCleanup(self.db.close)
        self.clock = FakeClock(1_800_000_000)
        self.store = PlayerStore(self.db, self.config, clock=self.clock)
        self.uid = self.store.login("friend-npcs")["uid"]
        self.store.gameplay_handlers = [GameplayCompetition(self.store, self.config)]
        self.social = GameplaySocial(self.store, self.config)

    def _grow(self, level, gear_level):
        def change(profile):
            team = [iid for iid in profile["team"][0] if iid]
            for iid in team:
                profile["avatars"][iid]["lv"] = level
            profile["my_equips"]["friend-test-eq"] = {
                "eid": "E_1001_6", "lv": gear_level, "halo": {"lv": 3, "exp": 0},
                "magic": [20, 20, 20, 20], "symp": -1,
            }
            profile["as_equips"][0] = ["friend-test-eq"]
            return profile, {}
        self.store.atomic_update(self.uid, change)

    def test_friend_npcs_use_real_cultivation_and_bonds(self):
        self._grow(30, 40)
        self.social.dispatch(self.uid, "user.get_friends", {})
        profile = self.store.profile_raw(self.uid)
        roster = profile["social"]["npc_roster"]
        self.assertEqual(set(roster["bots"]), {bot["uid"] for bot in self.social.bots})
        with_bonds = 0
        for bot in self.social.bots:
            built = self.social._bot_or_fail(bot["uid"], profile)
            self.assertEqual(built["name"], bot["name"])
            team = [iid for iid in built["team"][0] if iid]
            self.assertEqual(len(team), 5)
            # Gear copied from the player's own pattern, with real levels.
            self.assertTrue(built["my_equips"])
            self.assertTrue(all(item["lv"] >= 1 for item in built["my_equips"].values()))
            # Displayed card equals the roster serializer's output.
            card = self.social._friend_card(bot["uid"], profile)["avatar"]
            derived = self.social.roster.battle_attributes(built, team[0], scope="assist")
            for stat in ("hp", "ap", "de_ph", "de_ma"):
                self.assertEqual(card[stat], derived[stat])
            if any(self.social.roster.battle_attributes(built, iid, scope="assist")["bonds_104"]
                   for iid in team):
                with_bonds += 1
        self.assertGreaterEqual(with_bonds, len(self.social.bots) // 2)
        # Assist uses the cultivated captain with a native "aid|number" id.
        helper = self.social.lookup_assist(self.social.bots[0]["uid"], profile)
        base, sequence = helper["avatar_id"].split("|")
        self.assertTrue(sequence.isdigit())
        self.assertEqual(base, helper["avatar"]["aid"])

    def test_roster_is_stable_within_a_day_and_grows_with_the_player(self):
        self.social.dispatch(self.uid, "user.get_friends", {})
        first = self.store.profile_raw(self.uid)["social"]["npc_roster"]
        self._grow(40, 60)
        self.social.dispatch(self.uid, "user.get_friends", {})
        same_day = self.store.profile_raw(self.uid)["social"]["npc_roster"]
        self.assertEqual(same_day, first)
        self.clock.value += 86_400
        self.social.dispatch(self.uid, "user.get_friends", {})
        next_day = self.store.profile_raw(self.uid)["social"]["npc_roster"]
        self.assertNotEqual(next_day["day"], first["day"])
        before = sum(row["power"] for row in first["bots"].values())
        after = sum(row["power"] for row in next_day["bots"].values())
        self.assertGreater(after, before)

    def test_npcs_send_friend_requests_over_time_with_limits(self):
        self.social.dispatch(self.uid, "user.get_friends", {})
        social = self.store.profile_raw(self.uid)["social"]
        start = list(social["incoming"])
        for _ in range(40):
            self.clock.value += REQUEST_WINDOW_SECONDS
            self.social.dispatch(self.uid, "user.get_friends", {})
        social = self.store.profile_raw(self.uid)["social"]
        pending = [uid for uid in social["incoming"] if uid in self.social.by_uid]
        self.assertLessEqual(len(pending), max(MAX_PENDING_REQUESTS, len(start)))
        self.assertGreater(len(set(social["incoming"]) - set(start)) + len(social["friends"]), 0)
        # A dismissed NPC does not ask again during its cooldown.
        dismissed = pending[0]
        self.social.dispatch(self.uid, "user.unapply_friend", {"fid": dismissed})
        for _ in range(IGNORE_COOLDOWN_WINDOWS):
            self.clock.value += REQUEST_WINDOW_SECONDS
            self.social.dispatch(self.uid, "user.get_friends", {})
            self.assertNotIn(dismissed, self.store.profile_raw(self.uid)["social"]["incoming"])
        # Accepting a request makes the NPC a real friend card.
        remaining = [uid for uid in self.store.profile_raw(self.uid)["social"]["incoming"]
                     if uid in self.social.by_uid]
        if remaining:
            accepted = self.social.dispatch(self.uid, "user.add_friend", {"fid": remaining[0]})
            self.assertTrue(accepted["ok"])
            self.assertEqual(accepted["friend"]["uid"], remaining[0])


if __name__ == "__main__":
    unittest.main()
