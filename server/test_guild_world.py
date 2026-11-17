"""Persistent guild AI players: migration, growth, membership, boss share and LLM plans."""
import json
import datetime
import sqlite3
import sys
import unittest
import urllib.error
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import guild_chat
from game_calendar import game_day
from gameplay_guild_boss import GameplayGuildBoss
from guild_llm import GuildLLM, parse_events
from player_store import PlayerStore


class FakeClock:
    def __init__(self):
        self.value = int(datetime.datetime.fromisoformat("2026-11-17T12:00:00+08:00").timestamp())

    def now(self):
        return self.value

    def advance(self, seconds):
        before = self.value
        self.value += seconds
        return before, self.value


class GuildWorldBase(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.config = json.loads((Path(__file__).resolve().parents[1] /
                                 "config/reconstruction/full-config.json").read_text(encoding="utf-8"))

    def setUp(self):
        self.db = sqlite3.connect(":memory:", check_same_thread=False)
        self.addCleanup(self.db.close)
        self.store = PlayerStore(self.db, self.config, clock=FakeClock())
        self.uid = self.store.login("guild-world-test")["uid"]
        self.guild = next(h for h in self.store.gameplay_handlers if isinstance(h, GameplayGuildBoss))
        self.world = self.guild.world
        self.world.llm = GuildLLM(self.store, settings={"enabled": True, "api_key": ""}, threaded=False)
        self.store.atomic_update(self.uid, lambda p: (dict(p, gold=10 ** 7, coin=10 ** 6), {}))

    def call(self, method, params=None):
        return self.guild.dispatch(self.uid, method, params or {})

    def profile(self):
        return self.store.profile_raw(self.uid)

    def edit(self, fn):
        def mutate(profile):
            fn(profile)
            return profile, {}
        self.store.atomic_update(self.uid, mutate)

    def create_guild(self, name="测试公会"):
        self.assertEqual(self.call("user.add_association", {"name": name, "flag": 0})["res_code"], 1)

    def hours(self, count, approve=False):
        for _ in range(count):
            self.store.clock.advance(3600)
            rows = self.call("user.get_apply_info").get("member", [])
            if approve:
                for row in rows[:1]:
                    self.call("user.join_association", {"uid": row["uid"], "zone": "local", "flag": 1})


class GuildWorldTests(GuildWorldBase):
    def test_new_guild_has_real_ai_founders_not_static_members(self):
        self.create_guild()
        members = self.call("user.association_is")["member_list"]
        self.assertEqual(members[0]["uid"], self.uid)
        agents = self.profile()["guild_world"]["agents"]
        self.assertEqual(len(members), 4)
        self.assertTrue(all(row["uid"] in agents for row in members[1:]))
        self.assertFalse(any(str(row["uid"]).startswith("npc-") for row in members))

    def test_legacy_save_migrates_without_losing_approved_companions(self):
        legacy_uid = self.guild.companions.uid(self.profile(), 2)

        def legacy(profile):
            day = "2026-11-17"
            profile["association"] = {
                "id": "10002", "name": "旧公会", "icon": 0, "level": 1, "exp": 0, "total_alive": 3,
                "notice": "", "created": 1, "guild_graduate_skill_list": [], "boss": {}, "logs": [],
                "shop": {}, "fund": 0,
                "members": [{"uid": self.uid, "zone": "1-01", "name": "测试玩家", "lv": 1, "association_lv": 0,
                             "contribute": 0, "status": 1, "worship_info": {}}] +
                           [{"uid": f"npc-10002-{i}", "zone": "local", "name": "守望者", "lv": 1,
                             "association_lv": 3, "contribute": 100, "power": 10000, "status": 1}
                            for i in range(1, 7)] +
                           [{"uid": legacy_uid, "zone": "local", "name": "旧伙伴", "lv": 125, "power": 4321,
                             "association_lv": 1, "contribute": 0, "status": 1, "guild_companion": True,
                             "worship_info": {"member_worship_day": day}}],
                "applications": [{"uid": "930000000099", "guild_companion": True, "name": "过期申请人"}],
            }
            profile["attrs"].update({"association_id": "10002", "association_lv": 0})
            profile["guild_companions"] = {"hour": 1, "bots": [{"uid": legacy_uid, "name": "旧伙伴",
                                                               "power": 4321, "lv": 125}],
                                           "friend_invites_sent": {legacy_uid: True}}
            profile["records"]["guild_applications"] = {"10001": {"id": "10001", "status": "pending"}}
            profile.pop("guild_world", None)
        self.edit(legacy)
        response = self.call("user.association_is")
        world = self.profile()["guild_world"]
        rows = {row["uid"]: row for row in response["member_list"]}
        self.assertNotIn("npc-10002-1", rows)
        self.assertIn(legacy_uid, rows)
        self.assertEqual(rows[legacy_uid]["name"], "旧伙伴")
        self.assertEqual(rows[legacy_uid]["association_lv"], 1)
        self.assertGreaterEqual(world["agents"][legacy_uid]["power"], 4321)
        self.assertEqual(world["agents"][legacy_uid]["guild"], "10002")
        self.assertEqual(len(rows), 2 + 3)  # player, kept companion, three replacement founders
        self.assertEqual(self.call("user.get_apply_info")["num"], 0)
        # The AI guild that used to share the player's ID moved to a new ID.
        self.assertNotIn("10002", world["guilds"])
        self.assertIn("10001", world["guilds"])
        self.assertIn("10001", self.profile()["records"].get("guild_applications", {}))

    def test_growth_is_steady_and_bounded(self):
        self.create_guild()
        snapshots = []
        for _ in range(20):
            self.store.clock.advance(86400)
            self.call("user.association_is")
            snapshots.append({uid: (a["power"], a["lv"], a["owned"])
                              for uid, a in self.profile()["guild_world"]["agents"].items()})
        for before, after in zip(snapshots, snapshots[1:]):
            for uid in before:
                self.assertGreaterEqual(after[uid][0], before[uid][0])
                self.assertGreaterEqual(after[uid][1], before[uid][1])
                self.assertGreaterEqual(after[uid][2], before[uid][2])
        first, last = snapshots[0], snapshots[-1]
        self.assertGreater(sum(v[0] for v in last.values()), sum(v[0] for v in first.values()))
        self.assertGreater(sum(v[2] for v in last.values()), sum(v[2] for v in first.values()))
        world = self.profile()["guild_world"]
        cap = int(self.profile()["lv"]) + 5
        for agent in world["agents"].values():
            self.assertLessEqual(agent["lv"], max(agent["lv0"], min(125, cap)))
            self.assertLessEqual(agent["owned"], len(agent["pool"]))
            self.assertTrue(8 <= len(agent["pool"]) <= 12)

    def test_ai_members_donate_worship_and_leave_kill_to_player(self):
        self.create_guild()
        # A noon start spans four calendar dates over 72 hours. Check each
        # day's awards instead of assuming the interval covers three dates.
        awarded_by_day = {}
        previous_gold = self.profile()["attrs"].get("association_worship_gold", 0)
        for _ in range(72):
            self.hours(1, approve=True)
            gold = self.profile()["attrs"].get("association_worship_gold", 0)
            day = game_day(self.store.clock.now())
            awarded_by_day[day] = awarded_by_day.get(day, 0) + gold - previous_gold
            previous_gold = gold
        profile = self.profile()
        guild = profile["association"]
        self.assertGreater(len(guild["members"]), 4)
        self.assertGreater(guild["total_alive"], 0)
        texts = [log[1] for log in guild["logs"]]
        self.assertTrue(any("兑换公会贡献" in text for text in texts))
        self.assertTrue(any(row.get("contribute", 0) > 0 for row in guild["members"][1:]))
        state = profile["boss_state"]["guild_boss"]
        boss = state["boss"]
        self.assertGreaterEqual(boss["current_hp"], int(boss["max_hp"] * 0.3))
        self.assertFalse(boss.get("is_end"))
        if state.get("ai_ranks"):
            ranks = [row["damage"] for row in state["rank_list"]]
            self.assertEqual(ranks, sorted(ranks, reverse=True))
        self.assertEqual(len(awarded_by_day), 4)
        worship_cap = (self.world.settings["worship_gold_daily_ai_limit"] *
                       self.world.settings["worship_gold_per_ai"])
        self.assertGreater(sum(awarded_by_day.values()), 0)
        for day, awarded in awarded_by_day.items():
            with self.subTest(day=day):
                self.assertGreaterEqual(awarded, 0)
                self.assertLessEqual(awarded, worship_cap)

    def test_rejected_and_kicked_ai_players_remember_and_stay_away(self):
        self.create_guild()
        self.hours(1)
        for _ in range(96):
            rows = self.call("user.get_apply_info")["member"]
            if rows:
                break
            self.store.clock.advance(3600)
        target = rows[0]["uid"]
        self.call("user.join_association", {"uid": target, "zone": "local", "flag": 0})
        agent = self.profile()["guild_world"]["agents"][target]
        gid = self.profile()["association"]["id"]
        self.assertGreater(agent["cool"][gid], self.store.clock.now() // 3600 + 70)
        for _ in range(48):
            self.store.clock.advance(3600)
            self.assertNotIn(target, {row["uid"] for row in self.call("user.get_apply_info")["member"]})
        founder = self.profile()["association"]["members"][1]["uid"]
        self.assertEqual(self.call("user.modify_association", {"uid": founder, "zone": "local", "num": -1})["res_code"], 1)
        self.call("user.association_is")
        kicked = self.profile()["guild_world"]["agents"][founder]
        self.assertIsNone(kicked["guild"])
        self.assertTrue(any("被移出" in memory for memory in kicked["memory"]))
        self.assertGreater(kicked["cool"][gid], self.store.clock.now() // 3600 + 160)

    def test_player_joins_open_ai_guild_as_member_and_guild_survives_exit(self):
        cards = self.call("user.get_association_list")["info"]
        open_guild = next(card for card in cards if card["join_type"] == 2)
        joined = self.call("user.apply_member", {"id": open_guild["id"]})
        self.assertTrue(joined["join_flag"])
        profile = self.profile()
        self.assertEqual(profile["attrs"]["association_lv"], 3)
        self.assertEqual(profile["association"]["id"], open_guild["id"])
        leader = next(row for row in profile["association"]["members"] if row["association_lv"] == 0)
        self.assertNotEqual(leader["uid"], self.uid)
        self.assertEqual(self.call("user.over_association")["res_code"], -2)
        self.assertEqual(self.call("user.exit_association")["res_code"], 1)
        cards = {card["id"]: card for card in self.call("user.get_association_list")["info"]}
        self.assertIn(open_guild["id"], cards)
        self.assertEqual(cards[open_guild["id"]]["member_count"], open_guild["member_count"])

    def test_application_to_ai_guild_is_decided_by_its_leader(self):
        cards = self.call("user.get_association_list")["info"]
        target = next(card for card in cards if card["join_type"] == 1)
        response = self.call("user.apply_member", {"id": target["id"]})
        self.assertFalse(response["join_flag"])
        self.assertEqual(self.call("user.association_is")["flag"], 0)
        self.store.clock.advance(3600)
        result = self.call("user.association_is")
        if result["flag"]:
            self.assertEqual(result["association_info"]["id"], target["id"])
        self.assertNotIn(target["id"], self.profile()["records"].get("guild_applications", {}))

    def test_disbanding_frees_members_and_ai_players_found_guilds(self):
        self.create_guild()
        founders = [row["uid"] for row in self.profile()["association"]["members"][1:]]
        self.assertEqual(self.call("user.over_association")["res_code"], 1)
        agents = self.profile()["guild_world"]["agents"]
        self.assertTrue(all(agents[uid]["guild"] is None for uid in founders))

        def ambitious(profile):
            agent = profile["guild_world"]["agents"][founders[0]]
            agent.update({"amb": 90, "lv": 40})
        self.edit(ambitious)
        before = len(self.call("user.get_association_list")["info"])

        def found(profile):
            world = self.world.state(profile)
            hour = self.store.clock.now() // 3600
            self.assertTrue(self.world.execute(profile, world, {"uid": founders[0], "act": "found", "name": "龙魂殿"},
                                               hour, "llm"))
        self.edit(found)
        cards = self.call("user.get_association_list")["info"]
        self.assertEqual(len(cards), before + 1)
        self.assertIn("龙魂殿", {card["name"] for card in cards})

    def test_long_absence_catches_up_with_bounded_work(self):
        self.create_guild()
        self.store.clock.advance(30 * 86400)
        self.call("user.association_is")
        world = self.profile()["guild_world"]
        self.assertEqual(world["last_hour"], self.store.clock.now() // 3600)
        self.assertLess(len(json.dumps(world, ensure_ascii=False)), 40000)

    def test_player_boss_attack_uses_selected_team(self):
        self.create_guild()
        for _ in range(48):
            if self.guild._boss_window_open("guild_boss"):
                break
            self.store.clock.advance(1800)
        self.assertTrue(self.guild._boss_window_open("guild_boss"))

        def select_empty_team(profile):
            profile["team"][1] = [None] * 6
            profile["attrs"]["team_num"] = 1
        self.edit(select_empty_team)
        state = self.call("user.get_associationboss")
        before = state["boss"]["current_hp"]
        result = self.call("user.attack_associationboss", {})
        base = self.config["guild_boss_reconstruction"]["guild_boss"]["attack"]["base_damage"]
        self.assertEqual(result["attack_hp"], min(base, before))
        self.assertIn(self.uid, [row["uid"] for row in result["rank_list"]])

    def test_rule_plan_is_deterministic(self):
        self.create_guild()
        profile = self.profile()
        world = profile["guild_world"]
        self.assertEqual(self.world.rule_plan(profile, world, 1234), self.world.rule_plan(profile, world, 1234))

    def test_guild_chat_records_and_sanitizes_player_text(self):
        self.create_guild()
        self.call("user.chat_guild", {"s": "大家好<b>看这里</b> http://example.com"})
        record = self.call("user.chat_record", {"channel": "guild"})["record"]
        mine = [row for row in record if row["uid"] == self.uid]
        self.assertEqual(mine[-1]["method"], "chat_guild")
        self.assertEqual(mine[-1]["zone"], self.profile()["zone"])
        self.assertIsInstance(mine[-1]["t"], int)
        self.assertEqual(self.call("user.chat_record")["record"], [])
        self.assertNotIn("http", mine[-1]["s"])
        self.assertNotIn("<", mine[-1]["s"])
        self.assertTrue(mine[-1]["s"].startswith("大家好"))


class GuildLLMTests(GuildWorldBase):
    def fake(self, content=None, error=None):
        calls = []

        def transport(url, headers, body, timeout):
            calls.append({"url": url, "headers": headers, "body": body})
            if error:
                raise error
            return {"choices": [{"message": {"content": content}}],
                    "usage": {"prompt_tokens": 500, "completion_tokens": 100}}
        return transport, calls

    def enable(self, transport, **settings):
        values = {"enabled": True, "api_key": "test-key", "min_interval_seconds": 0, **settings}
        self.world.llm = GuildLLM(self.store, settings={**__import__("guild_llm").DEFAULT_SETTINGS, **values},
                                  transport=transport, threaded=False)

    def member_uid(self):
        return self.profile()["association"]["members"][1]["uid"]

    def test_no_key_never_calls_the_network(self):
        transport, calls = self.fake("{}")
        self.world.llm = GuildLLM(self.store, settings={"enabled": True, "api_key": ""},
                                  transport=transport, threaded=False)
        self.create_guild()
        self.hours(13)
        self.call("user.chat_guild", {"s": "有人吗"})
        self.world.llm.drain()
        self.assertEqual(calls, [])

    def test_structured_plan_is_requested_ahead_and_executed_by_rules(self):
        self.create_guild()
        uid = self.member_uid()
        content = json.dumps({"events": [
            {"h": h, "uid": uid, "act": "chat", "text": f"第{h}小时的模型发言"} for h in range(6)] + [
            {"h": 0, "uid": uid, "act": "donate", "tier": 0},
            {"h": 1, "uid": uid, "act": "donate", "tier": 0},
            {"h": 0, "uid": "no-such-agent", "act": "donate"},
            {"h": 0, "uid": uid, "act": "teleport"},
        ]}, ensure_ascii=False)
        transport, calls = self.fake(content)
        self.enable(transport)
        self.hours(1)
        self.assertEqual(len(calls), 0)
        self.world.llm.drain()
        self.assertEqual(len(calls), 1)
        body = calls[0]["body"]
        self.assertEqual(calls[0]["url"], "https://api.deepseek.com/chat/completions")
        self.assertEqual(calls[0]["headers"]["Authorization"], "Bearer test-key")
        self.assertEqual(body["model"], "deepseek-chat")
        self.assertEqual(body["response_format"], {"type": "json_object"})
        self.assertNotIn("guild-world-test", json.dumps(body, ensure_ascii=False))
        self.hours(12)
        world = self.profile()["guild_world"]
        llm_lines = [row for row in guild_chat.recent(self.db, self.uid, self.profile()["association"]["id"], 200)
                     if row["source"] == "llm"]
        self.assertTrue(llm_lines)
        self.assertTrue(all("模型发言" in row["text"] for row in llm_lines))
        donations = [log for log in self.profile()["association"]["logs"]
                     if log[1].startswith(world["agents"][uid]["name"] + "兑换")]
        self.assertLessEqual(len(donations), 2)  # once per game day at most
        usage = self.db.execute("SELECT calls,input_tokens,output_tokens FROM llm_usage").fetchall()
        self.assertTrue(usage and usage[0][0] >= 1)

    def test_invalid_output_and_network_errors_fall_back_to_rule_plans(self):
        self.create_guild()
        for transport, calls in (self.fake("这不是JSON"),
                                 self.fake(error=urllib.error.URLError("offline"))):
            self.enable(transport)
            self.hours(6)
            self.world.llm.drain()
            self.assertTrue(calls)
            self.hours(6)
            self.assertEqual(self.profile()["guild_world"]["plan"]["source"], "rule")

    def test_daily_budget_stops_further_calls(self):
        self.create_guild()
        transport, calls = self.fake(json.dumps({"events": []}))
        self.enable(transport, max_calls_per_day=1)
        for _ in range(4):
            self.hours(6)
            self.world.llm.drain()
        per_day = [row[0] for row in self.db.execute("SELECT calls FROM llm_usage")]
        self.assertEqual(sum(per_day), len(calls))
        self.assertTrue(per_day and all(count == 1 for count in per_day))
        self.assertLess(len(calls), 4)

    def test_player_message_gets_model_replies_with_cooldown(self):
        self.create_guild()
        uid = self.member_uid()
        transport, calls = self.fake(json.dumps({"events": [
            {"h": 0, "uid": uid, "act": "chat", "text": "会长好！我在呢"}]}, ensure_ascii=False))
        self.enable(transport)
        self.call("user.chat_guild", {"s": "大家今晚一起打Boss"})
        self.call("user.chat_guild", {"s": "听到了吗"})
        self.world.llm.drain()
        replies = [c for c in calls if "大家今晚一起打Boss" in json.dumps(c["body"], ensure_ascii=False)]
        self.assertEqual(len(replies), 1)
        self.assertFalse(any("听到了吗" in json.dumps(c["body"], ensure_ascii=False) for c in calls))
        record = self.call("user.chat_record", {"channel": "guild"})["record"]
        self.assertIn("会长好！我在呢", [row["s"] for row in record])

    def test_private_switch_keeps_player_text_local(self):
        self.create_guild()
        transport, calls = self.fake(json.dumps({"events": []}))
        self.enable(transport, send_player_messages=False)
        self.call("user.chat_guild", {"s": "这句话不发给模型"})
        self.hours(7)
        self.world.llm.drain()
        self.assertTrue(calls)  # Exercise periodic planning as well as replies.
        self.assertFalse(any("这句话不发给模型" in json.dumps(c["body"], ensure_ascii=False) for c in calls))

    def test_anthropic_protocol_is_one_setting_away(self):
        self.create_guild()
        uid = self.member_uid()
        calls = []

        def transport(url, headers, body, timeout):
            calls.append((url, headers, body))
            return {"content": [{"type": "text", "text": json.dumps(
                        {"events": [{"h": 0, "uid": uid, "act": "chat", "text": "来自另一种协议"}]},
                        ensure_ascii=False)}],
                    "usage": {"input_tokens": 300, "output_tokens": 40}}
        self.enable(transport, protocol="anthropic", base_url="https://api.anthropic.com", model="test-model")
        self.call("user.chat_guild", {"s": "测试一下"})
        self.world.llm.drain()
        url, headers, body = calls[0]
        self.assertEqual(url, "https://api.anthropic.com/v1/messages")
        self.assertEqual(headers["x-api-key"], "test-key")
        self.assertIn("公会系统", body["system"])
        self.assertTrue(all(m["role"] != "system" for m in body["messages"]))
        self.assertIn("来自另一种协议", [row["s"] for row in self.call("user.chat_record", {"channel": "guild"})["record"]])
        self.assertEqual(self.db.execute("SELECT input_tokens,output_tokens FROM llm_usage").fetchone(), (300, 40))

    def test_llm_json_changes_apply_without_restart(self):
        import os
        import tempfile
        folder = tempfile.mkdtemp()
        path = os.path.join(folder, "llm.json")
        self.addCleanup(lambda: os.path.exists(path) and os.remove(path))
        saved = {key: os.environ.pop(key, None) for key in
                 ("LAL_LLM_CONFIG", "LAL_LLM_API_KEY", "LAL_LLM_BASE_URL", "LAL_LLM_MODEL", "LAL_LLM_PROTOCOL")}
        self.addCleanup(lambda: [os.environ.__setitem__(k, v) for k, v in saved.items() if v is not None])
        os.environ["LAL_LLM_CONFIG"] = path
        self.addCleanup(os.environ.pop, "LAL_LLM_CONFIG", None)
        llm = GuildLLM(self.store, threaded=False)
        self.assertFalse(llm.enabled())
        with open(path, "w", encoding="utf-8") as handle:
            json.dump({"api_key": "k", "protocol": "anthropic", "model": "m", "unknown": 1}, handle)
        self.assertTrue(llm.enabled())
        self.assertEqual(llm.settings["protocol"], "anthropic")
        self.assertNotIn("unknown", llm.settings)
        with open(path, "w", encoding="utf-8") as handle:
            json.dump({"api_key": "", "enabled": True}, handle)
        self.assertFalse(llm.enabled())

    def test_parse_events_validates_shape(self):
        events = parse_events('```json\n{"events":[{"h":2,"uid":"a","act":"chat","text":"<a href=x>hi</a> www.x.com 好"},'
                              '{"h":9,"uid":"a","act":"donate"},{"h":1,"uid":"a","act":"hack"},'
                              '{"h":1,"uid":"a","act":"found","name":"超长的公会名字一二三四"}]}\n```', 6)
        self.assertEqual([e["act"] for e in events], ["found", "chat"])
        self.assertNotIn("www", events[1]["text"])
        self.assertLessEqual(len(events[0]["name"]), 8)
        self.assertIsNone(parse_events("nope", 6))


if __name__ == "__main__":
    unittest.main()
