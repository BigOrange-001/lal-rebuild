"""Guild migration, offline caps and save-local Mod compatibility."""
import copy
import datetime
from unittest.mock import patch

from game_calendar import game_day_number
from gameplay_guild_boss import GameplayGuildBoss
from gameplay_social import GameplaySocial
from mod_policy import channel_enabled, hero_available
from player_store import PlayerStore
from test_guild_world import GuildWorldBase


class GuildReviewRegressionTests(GuildWorldBase):
    def test_legacy_social_contacts_survive_after_leaving_guild(self):
        companions = self.guild.companions
        competition = companions._competition()
        bots = [companions._build(companions.uid(self.profile(), i), f"旧伙伴{i}", companions.orange[:3],
                                  30, 5000, competition) for i in range(3)]

        def legacy(profile):
            profile.pop("guild_world", None)
            profile["association"] = {}
            profile["guild_companions"] = {"bots": bots}
            profile["social"] = {"friends": [bots[0]["uid"]], "incoming": [bots[1]["uid"]],
                                 "outgoing": [bots[2]["uid"]], "bootstrapped": True}
        self.edit(legacy)
        self.call("user.association_is")
        profile = self.profile()
        for bot in bots:
            agent = profile["guild_world"]["agents"][bot["uid"]]
            self.assertEqual(agent["name"], bot["name"])
            self.assertGreaterEqual(agent["power"], bot["power"])
        social = next(h for h in self.store.gameplay_handlers if isinstance(h, GameplaySocial))
        listed = social.dispatch(self.uid, "user.get_friends", {})
        self.assertIn(bots[0]["uid"], {row["uid"] for row in listed["friends_list"]})
        self.assertIn(bots[1]["uid"], {row["uid"] for row in listed["apply_list"]})
        self.assertEqual(social.lookup_assist(bots[0]["uid"], self.profile())["uid"], bots[0]["uid"])

    def _assert_changed_mod_policy(self, missing):
        self.create_guild()
        uid = self.profile()["association"]["members"][1]["uid"]
        self.edit(lambda p: p.setdefault("social", {}).update(friends=[uid]))
        social = next(h for h in self.store.gameplay_handlers if isinstance(h, GameplaySocial))
        original = social.lookup_assist(uid, self.profile())["avatar"]["aid"]
        config = copy.deepcopy(self.config)
        runtime = {"digest": "changed-assist-policy", "heroes": {}}
        if missing:
            runtime["missingHeroIds"] = [original]  # Placeholder remains in avatar table.
        else:
            runtime["heroes"][original] = {"channels": {"appearance.assist_bot": False}}
        config["cfg"]["mod_runtime"] = runtime
        store = PlayerStore(self.db, config, clock=self.store.clock)
        social = next(h for h in store.gameplay_handlers if isinstance(h, GameplaySocial))
        # Read friends before making any guild request: stale cached cards
        # must be repaired on this path too.
        listed = social.dispatch(self.uid, "user.get_friends", {})
        card = next(row for row in listed["friends_list"] if row["uid"] == uid)
        self.assertNotEqual(card["avatar"]["aid"], original)
        self.assertTrue(hero_available(config, card["avatar"]["aid"]))
        self.assertTrue(channel_enabled(config, card["avatar"]["aid"], "appearance.assist_bot"))
        guild = next(h for h in store.gameplay_handlers if isinstance(h, GameplayGuildBoss))
        self.assertIn(uid, {row["uid"] for row in guild.dispatch(self.uid, "user.association_is", {})["member_list"]})

    def test_disabled_mod_captain_is_replaced_before_reading_friend_cards(self):
        self._assert_changed_mod_policy(missing=True)

    def test_disallowed_assist_captain_is_replaced_before_reading_friend_cards(self):
        self._assert_changed_mod_policy(missing=False)

    def test_catchup_preserves_caps_for_original_day_until_its_ticks_finish(self):
        self.store.clock.value = int(datetime.datetime.fromisoformat("2026-11-17T22:00:00+08:00").timestamp())
        self.create_guild()
        hour = self.store.clock.now() // 3600
        day = game_day_number(self.store.clock.now())

        def capped(profile):
            world = profile["guild_world"]
            gid = profile["association"]["id"]
            agent = profile["association"]["members"][1]["uid"]
            world["counters"][f"alive:{gid}:{day}"] = 6
            world["counters"][f"pw:{day}"] = 5
            profile["association"]["total_alive"] = 6
            profile["attrs"]["association_worship_gold"] = 250
            world["plan"] = {"w": hour // 6, "source": "rule", "events": [
                {"h": (hour + 1) % 6, "uid": agent, "act": "worship_guild", "tier": 2},
                {"h": (hour + 1) % 6, "uid": agent, "act": "worship_member", "target": self.uid}]}
        self.edit(capped)
        self.store.clock.advance(26 * 3600)
        with patch.object(self.world, "rule_plan", return_value=[]):
            self.call("user.association_is")
        self.assertEqual(self.profile()["association"]["total_alive"], 6)
        self.assertEqual(self.profile()["attrs"]["association_worship_gold"], 250)
