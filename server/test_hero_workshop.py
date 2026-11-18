"""Test hero claims through authenticated RPCs and normal acquisition guards."""
import copy
import io
import tempfile
import unittest
from concurrent.futures import ThreadPoolExecutor
from contextlib import redirect_stdout
from pathlib import Path
from random import Random
from types import SimpleNamespace
from unittest.mock import patch
from uuid import uuid4

from arena_opponents import combat_config_signature, highest_rarity_heroes
from gameplay_common import grant_reward
from gameplay_competition import GameplayCompetition
from gameplay_abyss import GameplayAbyss
from gateway import Backend, _console_loop, load_game_config
from hero_catalog_105 import apply_hero_catalog
from mod_policy import candidate_ids
from player_store import GameplayFault
from recruit_exchange import daily_orange_pool
from roguelite_abyss import generate_enemy_preview, rules
from solo_progression import exploration_encounter
from summon_pools import SummonPools
from tower_rewards_103 import _enemy_pools


CONFIG = Path(__file__).resolve().parents[1] / "config/reconstruction/full-config.json"
HERO = "A_19995_5"
INFO = "user.test_hero_workshop_info"
CLAIM = "user.test_hero_workshop_claim"


class TestHeroWorkshop(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.base = load_game_config(CONFIG)

    def setUp(self):
        self.doc = copy.deepcopy(self.base)
        self.cfg = self.doc["cfg"]
        self.cfg["avatar"][HERO] = {**self.cfg["avatar"]["A_1001_5"],
                                    "id": HERO, "name": "工坊测试用英雄", "test_hero": True}
        tmp = self.enterContext(tempfile.TemporaryDirectory())
        with patch("gateway.load_game_config", return_value=self.doc):
            self.backend = Backend(":memory:", CONFIG, mods_root=Path(tmp) / "mods")
        self.addCleanup(self.backend.db.close)
        self.addCleanup(self.backend.clock.close)
        self.store = self.backend.players
        self.owner = self.store.login("workshop-player")
        self.uid = self.owner["uid"]

    def rpc(self, method, **params):
        params.setdefault("actionID", uuid4().hex)
        return self.backend.call({"method": method, "params": params, "uid": self.uid,
                                  "sessionid": self.owner["sessionid"]})

    def change_profile(self, change):
        def mutate(profile):
            change(profile)
            return profile, {}
        self.store.atomic_update(self.uid, mutate)

    def test_empty_and_unavailable_heroes(self):
        self.cfg["avatar"][HERO]["test_hero"] = False
        self.assertEqual(self.rpc(INFO)["data"], {"heroes": []})
        for aid in (HERO, "A_1001_5", "A_1001_5|0", ["A_1001_5"], None):
            with self.subTest(aid=aid):
                self.assertEqual(self.rpc(CLAIM, aid=aid)["data"]["error_code"], "TestHeroUnavailable")

    def test_free_claim_is_atomic_and_persists_after_sale(self):
        before = self.store.profile_raw(self.uid)
        listing = self.rpc(INFO)
        self.assertEqual(listing["return_code"], 0)
        self.assertEqual(listing["data"]["heroes"],
                         [{"aid": HERO, "name": "工坊测试用英雄", "claimed": False}])
        with ThreadPoolExecutor(max_workers=4) as pool:
            claims = list(pool.map(lambda n: self.rpc(CLAIM, aid=HERO, actionID=f"claim-{n}"), range(4)))
        self.assertTrue(all(reply["return_code"] == 0 for reply in claims))
        self.assertEqual(sum(reply["data"]["granted"] for reply in claims), 1)
        first = next(reply for reply in claims if reply["data"]["granted"])
        self.assertEqual(self.rpc(CLAIM, aid=HERO, actionID=first["params"]["actionID"])["data"], first["data"])
        after = self.store.profile_raw(self.uid)
        for currency in ("coin", "gold", "medal", "score", "mark"):
            self.assertEqual(after[currency], before[currency])
        [iid] = set(after["avatars"]) - set(before["avatars"])
        self.assertEqual(iid.split("|")[0], HERO)
        self.assertIn(iid, first["state_sync"]["profile"]["avatars"])
        self.assertEqual(self.rpc("user.sell_avatars", aids=[iid])["return_code"], 0)
        self.assertNotIn(HERO, self.store.profile_raw(self.uid)["avatar_soul"])
        self.assertTrue(self.rpc(INFO)["data"]["heroes"][0]["claimed"])
        self.assertFalse(self.rpc(CLAIM, aid=HERO)["data"]["granted"])

    def test_old_save_that_already_owns_hero_cannot_receive_another_copy(self):
        iid = HERO + "|209"
        self.change_profile(lambda p: p["avatars"].update({iid: {"id": iid, "aid": iid, "lv": 1}}))
        self.assertTrue(self.rpc(INFO)["data"]["heroes"][0]["claimed"])
        self.assertFalse(self.rpc(CLAIM, aid=HERO)["data"]["granted"])
        self.assertEqual(sum(key.split("|")[0] == HERO for key in
                             self.store.profile_raw(self.uid)["avatars"]), 1)

    def test_full_roster_leaves_claim_available(self):
        self.change_profile(lambda p: p["attrs"].update(avatar_len=len(p["avatars"])))
        full = self.rpc(CLAIM, aid=HERO, actionID="retry-after-full")
        self.assertEqual(full["data"]["error_code"], "AvatarCapacity")
        self.assertFalse(self.rpc(INFO)["data"]["heroes"][0]["claimed"])
        self.change_profile(lambda p: p["attrs"].update(avatar_len=len(p["avatars"]) + 1))
        self.assertTrue(self.rpc(CLAIM, aid=HERO, actionID="retry-after-full")["data"]["granted"])

    def test_regular_rewards_and_automated_mail_still_reject_test_cards_and_souls(self):
        profile = self.store.profile_raw(self.uid)
        for reward in ({"avatar": {HERO: 1}}, {"avatar_soul": {HERO: 1}},
                       {"heroes": [{"aid": HERO, "num": 1}]}):
            with self.subTest(reward=reward), self.assertRaisesRegex(GameplayFault, "测试英雄"):
                grant_reward(profile, {"coin": 1, **reward}, self.cfg, allow_skin=True)
        self.assertEqual(profile, self.store.profile_raw(self.uid))
        with self.assertRaisesRegex(GameplayFault, "测试英雄"):
            self.store.send_mail("workshop-player", "测试", {"avatar": {HERO: 1}}, "mail", allow_skin=True)
        self.change_profile(lambda p: p["avatar_soul"].update({HERO: 500}))
        result = self.rpc("user.soul_exchange_avatar", aid=HERO, num=1)
        self.assertEqual(result["data"]["error_code"], "TestHeroWorkshopOnly")
        self.assertEqual(self.store.profile_raw(self.uid)["avatar_soul"][HERO], 500)

    def test_management_mail_delivers_only_once_and_marks_workshop_claimed(self):
        before = self.store.profile_raw(self.uid)
        command = f'''mail workshop-player test-hero-mail "测试英雄" '{{"avatar":{{"{HERO}":1}}}}' '''
        service = SimpleNamespace(backend=self.backend, shutdown=lambda: None)
        with patch("builtins.input", side_effect=[command, command, "exit"]), redirect_stdout(io.StringIO()):
            _console_loop(service)
        [mail] = self.backend.db.execute(
            "SELECT id, allow_test_hero FROM gift_mail WHERE request_key='test-hero-mail'").fetchall()
        self.assertEqual(mail[1], 1)
        self.assertFalse(self.rpc(INFO)["data"]["heroes"][0]["claimed"])
        self.assertEqual(self.rpc("user.get_gift_msg", gk=str(mail[0]))["return_code"], 0)
        self.assertEqual(self.rpc("user.get_gift_msg", gk=str(mail[0]))["return_code"], 0)
        [iid] = set(self.store.profile_raw(self.uid)["avatars"]) - set(before["avatars"])
        self.assertEqual(iid.split("|")[0], HERO)
        self.assertEqual(self.rpc("user.sell_avatars", aids=[iid])["return_code"], 0)
        self.assertTrue(self.rpc(INFO)["data"]["heroes"][0]["claimed"])
        self.assertFalse(self.rpc(CLAIM, aid=HERO)["data"]["granted"])

    def test_arena_fragment_and_tower_enemy_pools_exclude_test_heroes(self):
        orange = "A_1001_6"
        comp = GameplayCompetition(self.store, self.doc)
        fragment_aid = comp.fragment_bots[0]["team"][0][0]
        for aid in (orange, fragment_aid):
            self.cfg["avatar"][aid]["test_hero"] = True
        comp = GameplayCompetition(self.store, self.doc)
        arena = comp.cultivator.family_forms("appearance.arena_enemy")
        self.assertNotIn(orange, arena["A_1001"].values())
        self.assertNotIn(orange, highest_rarity_heroes(self.cfg))
        self.assertNotIn(orange, _enemy_pools(self.cfg)["orange"])
        self.assertTrue(comp.fragment_bots)
        self.assertFalse(any(row[0] == fragment_aid for bot in comp.fragment_bots for row in bot["team"]))
        with self.assertRaisesRegex(GameplayFault, "测试英雄"):
            comp._bot_units({"units": [{"base_aid": HERO}]})
        profile = self.store.profile_raw(self.uid)
        cached = {"player_rank": comp._rank(profile), "power_order_schema": "real-cultivation-v2",
                  "combat_config_sha256": combat_config_signature(self.cfg),
                  "bots": [{"units": [{"base_aid": HERO}]}] * 10}
        profile["records"]["pvp_opponents"] = cached
        with patch("gameplay_competition.generate_opponents", return_value={"bots": []}) as regenerate:
            self.assertIsNot(comp._ensure_opponents(profile, self.uid), cached)
            regenerate.assert_called_once()

    def test_random_exploration_and_abyss_replace_test_enemies(self):
        profile = self.store.profile_raw(self.uid)
        families = ["A_1001", "A_1004", "A_1007", "A_1009"]
        self.cfg["system_simple"]["solo_hero_families"] = families
        for aid, avatar in self.cfg["avatar"].items():
            if aid.rsplit("_", 1)[0] == families[0]:
                avatar["test_hero"] = True
        encounter = exploration_encounter(self.doc, profile, {"map_revision": 1}, 6, {})
        self.assertEqual({row[0].rsplit("_", 1)[0] for row in encounter["team2"]}, set(families[1:]))

        node = {"id": "boss", "type": "boss", "act": 3, "layer": 10}
        old = generate_enemy_preview(17, 7, node, self.cfg)
        for aid in (old[0]["aid"], next(row["aid"] for row in old if row["is_skin"])):
            self.cfg["avatar"][aid]["test_hero"] = True
        node.update(enemy_preview=old, enemies=old, enemy_rules_schema=rules(self.cfg)["schema"])
        GameplayAbyss(self.store, self.doc)._update_enemy_rules({"seed": 17, "difficulty": 7}, node)
        self.assertNotIn("enemies", node)
        self.assertEqual(len(node["enemy_preview"]), len(old))
        self.assertFalse(any(self.cfg["avatar"][row["aid"]].get("test_hero") for row in node["enemy_preview"]))

    def test_test_heroes_leave_summon_recruitment_and_cached_shop_stock(self):
        ordinary = daily_orange_pool(self.cfg)[0]
        self.cfg["avatar"][ordinary]["test_hero"] = True
        self.assertNotIn(ordinary, daily_orange_pool(self.cfg))
        self.assertEqual(candidate_ids(self.cfg, [ordinary, HERO], "acquisition.summon.advanced"), [])
        alt = self.cfg["summon_calibration"]["pools"]["advanced"]["qualities"]["purple"]["cards"]
        alt.append({"id": HERO, "weight": 10 ** 20})
        self.assertNotIn(HERO, SummonPools.from_config(self.cfg).draw_quality("advanced", "purple", Random(1)))
        apply_hero_catalog(self.doc)
        self.assertNotIn(HERO, {row["id"] for row in
                                self.cfg["summon_calibration"]["pools"]["advanced"]["qualities"]["purple"]["cards"]})

        sheet = self.rpc("user.mystery_shop_info", s_type="normal")["data"]
        def add_old_stock(profile):
            stock = profile["attrs"]["mystery_shop"]["normal"]
            stock["items"].insert(0, [{"avatar_soul": {HERO: 1}}, {"gold": 1}])
            stock["b"] = [1]
        self.change_profile(add_old_stock)
        result = self.rpc("user.mystery_shop_buy", s_type="normal", index=0, time=sheet["t"])
        self.assertEqual(result["data"]["error_code"], "TestHeroWorkshopOnly")
        active = self.rpc("user.mystery_shop_info", s_type="normal")["data"]
        self.assertEqual(active["items"], sheet["items"])
        self.assertEqual(active["b"], [0])
