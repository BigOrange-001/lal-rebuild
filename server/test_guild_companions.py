"""Guild applications, hourly helper strength, and accepted friend contracts."""
import json
import sqlite3
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from gameplay_competition import GameplayCompetition
from gameplay_guild_boss import GameplayGuildBoss
from gameplay_social import GameplaySocial
from player_store import GameplayFault, PlayerStore


class GuildCompanionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.config = json.loads((Path(__file__).resolve().parents[1] /
                                 "config/reconstruction/full-config.json").read_text(encoding="utf-8"))

    def setUp(self):
        self.db = sqlite3.connect(":memory:", check_same_thread=False)
        self.addCleanup(self.db.close)
        self.store = PlayerStore(self.db, self.config)
        login = self.store.login("guild-companion-test")
        self.uid = login["uid"]
        self.sessionid = login["sessionid"]
        self.guild = next(h for h in self.store.gameplay_handlers if isinstance(h, GameplayGuildBoss))
        self.social = next(h for h in self.store.gameplay_handlers if isinstance(h, GameplaySocial))
        self.competition = next(h for h in self.store.gameplay_handlers if isinstance(h, GameplayCompetition))
        self.store.atomic_update(self.uid, lambda p: (dict(p, gold=1000000, coin=1000000), {}))
        created = self.rpc("user.add_association", {"name": "测试公会", "flag": 0, "icon": 0})
        self.assertEqual(created["res_code"], 1)

    def rpc(self, method, params):
        return self.store.dispatch({"uid": self.uid, "sessionid": self.sessionid,
                                    "method": method, "params": params})

    def test_authenticated_dispatch_to_real_battle_assist(self):
        guild = self.rpc("user.association_is", {})
        self.assertEqual(guild["association_info"]["leader_uid"], self.uid)
        pending = self.rpc("user.get_apply_info", {})
        self.assertEqual(pending["num"], 10)
        bot = pending["member"][0]
        self.assertEqual(self.rpc("user.join_association", {"uid": bot["uid"],
                                                        "zone": bot["zone"], "flag": 1})["res_code"], 1)
        requested = self.rpc("user.get_friends", {})
        self.assertIn(bot["uid"], {card["uid"] for card in requested["apply_list"]})
        self.assertTrue(self.rpc("user.add_friend", {"fid": bot["uid"]})["ok"])
        friends = self.rpc("user.get_friends", {})
        card = next(card for card in friends["friends_list"] if card["uid"] == bot["uid"])
        self.assertIn(bot["uid"], {row["uid"] for row in self.rpc("user.online_user", {})})
        self.assertEqual(self.rpc("user.get", {"uid": bot["uid"]})["uid"], bot["uid"])
        self.assertEqual(card["avatar"]["limit_break"], 1)
        self.assertIn(card["avatar"]["aid"], self.guild.companions.orange)
        self.assertIn(card["avatar"]["aid"], self.guild.companions.skins)
        saved = self.store.profile_raw(self.uid)["team"][0]
        team = [[iid, index % 3, .2 + index * .12] for index, iid in enumerate(saved[:5])]
        team.append([card["avatar"]["aid"], 0, .5, bot["uid"], 1])
        battle = self.rpc("user.pk_combat", {"cid": "M_001_1", "diff": 0,
                                             "team_num": 0, "team": team})
        self.assertEqual(battle["friend_avatar"]["aid"].split("|")[0], card["avatar"]["aid"])
        self.assertEqual(battle["friend_avatar"]["limit_break"], 1)
        self.assertEqual(len(battle["orgin_team_a"]), 6)
        self.assertEqual(battle["orgin_team_a"][-1]["limit_break"], 1)
        old_power = self.competition._team_power([card["avatar"]])
        def strengthen(profile):
            for hero in profile["avatars"].values():
                hero["lv"] = 30
            return profile, {}
        self.store.atomic_update(self.uid, strengthen)
        self.store.clock.advance(3600)
        self.rpc("user.association_is", {})
        current = self.store.profile_raw(self.uid)
        refreshed = next(row for row in self.rpc("user.get_friends", {})["friends_list"]
                         if row["uid"] == bot["uid"])
        new_power = self.competition._team_power([refreshed["avatar"]])
        target = self.guild.companions._player_power(current, self.competition) * .30
        self.assertGreater(new_power, old_power)
        self.assertLessEqual(abs(new_power - target), max(5, target * .10))

    def test_applicants_join_then_request_friend_and_assist_at_real_power(self):
        profile = self.store.profile_raw(self.uid)
        pending = self.guild.dispatch(self.uid, "user.get_apply_info", {})
        self.assertEqual(pending["num"], 10)
        self.assertEqual(pending["association_info"]["association_application"], 10)
        self.assertEqual(len({row["uid"] for row in pending["member"]}), 10)
        pool = set(self.guild.companions.orange)
        self.assertTrue(pool)
        self.assertTrue(all(next(iter(row["avatars"])).split("|")[0] in pool
                            for row in profile["guild_companions"]["bots"]))
        if self.guild.companions.skins:
            first = profile["guild_companions"]["bots"][0]
            self.assertIn(next(iter(first["avatars"])).split("|")[0], self.guild.companions.skins)
        bot = pending["member"][0]
        with self.assertRaises(GameplayFault):
            self.social.lookup_assist(bot["uid"], profile)
        self.assertTrue(bot["uid"] not in self.social.by_uid)
        self.assertEqual(bot["zone"], "local")
        self.assertEqual(bot["lv"], 125)
        denied = self.guild.dispatch(self.uid, "user.join_association",
                                     {"uid": "unknown", "zone": "local", "flag": 1})
        self.assertLess(denied["res_code"], 0)
        joined = self.guild.dispatch(self.uid, "user.join_association",
                                     {"uid": bot["uid"], "zone": bot["zone"], "flag": 1})
        self.assertEqual(joined["res_code"], 1)
        self.assertEqual(joined["association_info"]["association_application"], 9)
        current = self.store.profile_raw(self.uid)
        self.assertEqual(current["attrs"]["association_lv"], 0)
        self.assertEqual(current["association"]["members"][0]["uid"], self.uid)
        self.assertIn(bot["uid"], current["social"]["incoming"])
        requests = self.social.dispatch(self.uid, "user.get_friends", {})
        self.assertIn(bot["uid"], {row["uid"] for row in requests["apply_list"]})
        accepted = self.social.dispatch(self.uid, "user.add_friend", {"fid": bot["uid"]})
        self.assertTrue(accepted["ok"])
        assist = self.social.lookup_assist(bot["uid"], self.store.profile_raw(self.uid))
        self.assertEqual(assist["avatar_id"].split("|")[0], assist["avatar"]["aid"])
        self.assertEqual(assist["avatar"]["lv"], 125)
        self.assertEqual(self.store.profile_raw(self.uid)["guild_companions"]["bots"][0]
                         ["avatars"][assist["avatar_id"]]["limit_break"], 1)
        actual = self.competition._team_power([assist["avatar"]])
        self.assertEqual(actual, current["guild_companions"]["bots"][0]["power"])
        team_power = self.guild.companions._player_power(profile, self.competition)
        self.assertLessEqual(abs(actual - team_power * 0.3), max(5, team_power * 0.03))
        self.guild.dispatch(self.uid, "user.exit_association", {})
        self.assertEqual(self.social.lookup_assist(bot["uid"], self.store.profile_raw(self.uid))["uid"],
                         bot["uid"])

    def test_hourly_refresh_is_stable_then_updates_without_duplicate_applications(self):
        before = self.store.profile_raw(self.uid)["guild_companions"]
        self.guild.dispatch(self.uid, "user.get_apply_info", {})
        self.assertEqual(self.store.profile_raw(self.uid)["guild_companions"], before)
        def strengthen(profile):
            for hero in profile["avatars"].values():
                hero["lv"] = 30
            return profile, {}
        self.store.atomic_update(self.uid, strengthen)
        self.store.clock.advance(3600)
        self.guild.dispatch(self.uid, "user.association_is", {})
        after = self.store.profile_raw(self.uid)["guild_companions"]
        self.assertNotEqual(after["hour"], before["hour"])
        self.assertGreater(after["bots"][0]["power"], before["bots"][0]["power"])
        player_power = self.guild.companions._player_power(self.store.profile_raw(self.uid), self.competition)
        self.assertLessEqual(abs(after["bots"][0]["power"] - player_power * .3),
                             max(5, player_power * .03))
        self.assertEqual([bot["uid"] for bot in after["bots"]],
                         [bot["uid"] for bot in before["bots"]])
        rows = self.guild.dispatch(self.uid, "user.get_apply_info", {})["member"]
        self.assertEqual(len(rows), 10)
        self.assertEqual(len({row["uid"] for row in rows}), 10)

    def test_legacy_approved_bot_gets_one_invitation_after_dismissal(self):
        bot = self.rpc("user.get_apply_info", {})["member"][0]
        self.assertEqual(self.rpc("user.join_association", {"uid": bot["uid"],
                                                         "zone": bot["zone"], "flag": 1})["res_code"], 1)
        def simulate_legacy(profile):
            profile["social"]["incoming"].remove(bot["uid"])
            del profile["guild_companions"]["friend_invites_sent"]
            return profile, {}
        self.store.atomic_update(self.uid, simulate_legacy)
        requests = self.rpc("user.get_friends", {})["apply_list"]
        self.assertEqual(sum(row["uid"] == bot["uid"] for row in requests), 1)
        self.assertTrue(self.store.profile_raw(self.uid)["guild_companions"]
                        ["friend_invites_sent"][bot["uid"]])
        self.assertTrue(self.rpc("user.unapply_friend", {"fid": bot["uid"]})["ok"])
        for _ in range(2):
            self.assertNotIn(bot["uid"], {row["uid"] for row in
                             self.rpc("user.get_friends", {})["apply_list"]})
        self.store.clock.advance(3600)
        self.assertNotIn(bot["uid"], {row["uid"] for row in
                         self.rpc("user.get_friends", {})["apply_list"]})

    def test_full_friend_list_keeps_invitation_until_space_is_available(self):
        bot = self.rpc("user.get_apply_info", {})["member"][0]
        def fill(profile):
            profile["attrs"]["friend_len"] = len(profile.get("social", {}).get("friends", []))
            return profile, {}
        self.store.atomic_update(self.uid, fill)
        self.assertEqual(self.rpc("user.join_association", {"uid": bot["uid"],
                                                         "zone": bot["zone"], "flag": 1})["res_code"], 1)
        self.assertIn(bot["uid"], {row["uid"] for row in
                                    self.rpc("user.get_friends", {})["apply_list"]})
        with self.assertRaises(GameplayFault) as caught:
            self.rpc("user.add_friend", {"fid": bot["uid"]})
        self.assertEqual(caught.exception.code, "FriendListFull")
        def expand(profile):
            profile["attrs"]["friend_len"] = 40
            return profile, {}
        self.store.atomic_update(self.uid, expand)
        self.assertTrue(self.rpc("user.add_friend", {"fid": bot["uid"]})["ok"])


if __name__ == "__main__":
    unittest.main()
