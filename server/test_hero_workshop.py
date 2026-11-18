"""Test hero claims through authenticated RPCs and normal acquisition guards."""
import copy
import tempfile
import unittest
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from random import Random
from uuid import uuid4
from unittest.mock import patch

from gameplay_common import grant_reward
from gateway import Backend, load_game_config
from hero_catalog_105 import apply_hero_catalog
from mod_policy import candidate_ids
from player_store import GameplayFault
from recruit_exchange import daily_orange_pool
from summon_pools import SummonPools


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

    def test_regular_rewards_and_mail_reject_test_cards_and_souls(self):
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
