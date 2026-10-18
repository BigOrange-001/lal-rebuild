"""Mod gameplay boundaries use only synthetic profiles and temporary state."""
import copy
import json
import sys
import unittest
from pathlib import Path
from types import SimpleNamespace

sys.path.insert(0, str(Path(__file__).resolve().parent))

from arena_opponents import combat_config_signature, highest_rarity_heroes
from battle_engine import base_unit, serialize_player_team
from battle_intents import create_intent, consume_intent
from gameplay_common import grant_reward
from gameplay_economy import GameplayEconomy
from gameplay_roster import GameplayRosterEquipment
from gameplay_social import GameplaySocial
from mod_policy import draw_categories, candidate_ids, activity_categories
from player_store import GameplayFault
from cultivation_rules import normalize_profile as normalize_culture_profile


class ModGameplayTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        root = Path(__file__).resolve().parents[1] / "config/reconstruction"
        cls.base = json.loads((root / "full-config.json").read_text(encoding="utf-8"))
        cls.side = json.loads((root / "roster-config.json").read_text(encoding="utf-8"))

    def setUp(self):
        self.doc = copy.deepcopy(self.base)
        self.doc["mod_roster"] = copy.deepcopy(self.side)
        self.cfg = self.doc["cfg"]
        self.runtime = self.cfg["mod_runtime"] = {
            "digest": "config-one", "heroes": {}, "scopedAvatarIds": {},
            "missingHeroIds": [], "knownHeroIds": []}
        self.store = SimpleNamespace(clock=SimpleNamespace(now=lambda: 1800000000),
                                     adventure=SimpleNamespace(record_draw=lambda p: None))

    def new_hero(self, aid="A_180000_5", channels=None):
        row = copy.deepcopy(self.cfg["avatar"]["A_1001_5"])
        row.update(id=aid, name="测试自制英雄")
        self.cfg["avatar"][aid] = row
        self.runtime["heroes"][aid] = {"kind": "new", "packageId": "test-package",
            "identity": "test-package/hero/test/quality5", "available": True,
            "unitType": "hero", "channels": channels or {}, "progression": {"starUp": None}}
        return aid

    def profile(self, aid="A_1001_5"):
        iid = aid + "|0"
        hero = {"aid": iid, "id": iid, "lv": 1, "slv": 1, "exp": 0, "phase": 0,
                "hp": 0, "ap": 0, "de_ph": 0, "de_ma": 0, "equips": []}
        return {"avatars": {iid: hero}, "attrs": {"avatar_len": 100, "dn": {}},
                "records": {}, "team": [[iid]], "my_equips": {}, "as_equips": [[]],
                "coin": 100000, "score": 100000, "gold": 100000}

    def test_new_heroes_join_existing_quality_bands_without_weight_change(self):
        aid = self.new_hero()
        before = self.side["wager_pools"]["coin"]
        after = draw_categories(self.doc, before, "coin")
        self.assertEqual([(r["category"], r["weight"]) for r in before],
                         [(r["category"], r["weight"]) for r in after])
        self.assertIn(aid, next(r["ids"] for r in after if r["category"] == "purple_hero"))
        self.runtime["heroes"][aid]["channels"]["acquisition.summon.advanced"] = False
        disabled = draw_categories(self.doc, before, "coin")
        self.assertFalse(any(aid in r["ids"] for r in disabled))
        self.assertIn(aid, candidate_ids(self.doc, [], "acquisition.summon.normal", include_new=True))
        self.assertNotIn(aid, self.side["wager_pools"]["coin"][1]["ids"])

    def test_empty_summon_category_rejects_before_currency_and_pity_mutation(self):
        roster = GameplayRosterEquipment(self.store, self.doc)
        purple = next(r["ids"] for r in roster.draw_pools["coin"] if r["category"] == "purple_hero")
        for aid in purple:
            self.runtime["heroes"][aid] = {"channels": {"acquisition.summon.advanced": False}}
        profile = self.profile()
        original = copy.deepcopy(profile)
        with self.assertRaisesRegex(GameplayFault, "品阶池为空"):
            roster._mutate(profile, "user.wager_avatar", {"wager_type": "coin", "times": 1})
        self.assertEqual(profile, original)

    def test_context_aliases_keep_same_hero_identity_and_distinct_skills(self):
        base = "A_1001_5"
        alias = "A_170000_5"
        self.cfg["avatar"][alias] = copy.deepcopy(self.cfg["avatar"][base])
        self.cfg["avatar"][alias]["id"] = alias
        self.cfg["avatar"][alias]["pl"][2] *= 2
        self.runtime["heroes"][alias] = {"baseAid": base}
        self.runtime["scopedAvatarIds"] = {"arenaEnemy": {base: alias}}
        owned = base_unit(self.cfg, base, scope="owned")
        enemy = base_unit(self.cfg, base, team=2, scope="arenaEnemy")
        self.assertEqual(owned["aid"], base)
        self.assertEqual(enemy["aid"], alias)
        self.assertEqual(enemy["base_aid"], base)
        self.assertEqual(enemy["ap"], owned["ap"] * 2)
        self.assertEqual(enemy["mod_digest"], "config-one")
        self.assertEqual(candidate_ids(self.cfg, [base, alias], "appearance.assist_bot"), [base])

    def test_missing_hero_is_frozen_without_changing_raw_progress_or_formation(self):
        aid = self.new_hero()
        profile = self.profile(aid)
        instance = aid + "|0"
        profile["avatars"][instance].update(lv=80, exp=777, phase=2, hp=120, equips=["E_1001_2|1"])
        original = copy.deepcopy(profile)
        self.runtime["missingHeroIds"] = [aid]
        self.runtime["heroes"][aid]["available"] = False
        roster = GameplayRosterEquipment(self.store, self.doc)
        with self.assertRaisesRegex(GameplayFault, "内容缺失"):
            roster._hero(profile, instance)
        with self.assertRaisesRegex(GameplayFault, "内容缺失"):
            serialize_player_team(self.cfg, profile, 0, [[instance, 0, .2]])
        roster._normalize_available_culture(profile)
        roster._migrate_hero_level_caps(profile)
        self.assertEqual(profile["avatars"], original["avatars"])
        self.assertEqual(profile["team"], original["team"])

    def test_player_store_culture_normalizer_does_not_migrate_missing_placeholder(self):
        aid = self.new_hero()
        profile = self.profile(aid)
        iid = aid + "|0"
        profile["avatars"][iid].update(lv=80, slv=9, exp=12345, hp=12, ap=23, de_ph=34,
                                       de_ma=45, pith_max=17, phase=2, equips=["eq1"])
        profile["attrs"]["avatar_culture"] = {"aid": iid, "hp": 2, "ap": 3, "de_ph": 4, "de_ma": 5}
        self.cfg["avatar"][aid] = {"id": aid, "modMissing": True, "pl": [0] * 14}
        self.runtime["heroes"][aid]["available"] = False
        original = copy.deepcopy(profile)
        normalize_culture_profile(profile, self.cfg)
        self.assertEqual(profile, original)

    def test_unchanged_missing_auxiliary_slots_are_retained_without_allowing_new_assignment(self):
        aid = self.new_hero()
        profile = self.profile(aid)
        iid = aid + "|0"
        self.runtime["heroes"][aid]["available"] = False
        roster = GameplayRosterEquipment(self.store, self.doc)
        roster.simple["dn"] = {"1": ["0", 1, 1, 0, 0, "hp", .01, .01],
                               "2": ["0", 1, 1, 0, 0, "hp", .01, .01]}
        profile["attrs"]["dn"] = {"1": [1, iid], "2": [1, None]}
        submitted = copy.deepcopy(profile["attrs"]["dn"])
        self.assertEqual(roster._validate_dn_assignment(profile, submitted, []), submitted)
        self.assertEqual(roster._destiny_team_bonuses(profile), {"hp": 0, "ap": 0, "de_ph": 0, "de_ma": 0})
        moved = {"1": [1, None], "2": [1, iid]}
        with self.assertRaises(GameplayFault):
            roster._validate_dn_assignment(profile, moved, [])

    def test_external_deletion_keeps_unsettled_intent_and_blocks_reward(self):
        aid = self.new_hero()
        profile = self.profile(aid)
        unit = base_unit(self.cfg, aid)
        token = create_intent(profile, "pvp", {}, [unit], [unit], now=1000, config=self.cfg)
        self.runtime["digest"] = "degraded-two"
        self.runtime["missingHeroIds"] = [aid]
        with self.assertRaisesRegex(GameplayFault, "配置已变化"):
            consume_intent(profile, "pvp", {**token, "sign": 1}, now=1001, config=self.cfg)
        self.assertIn(token["fight_id"], profile["pending_battles"]["pvp"])
        original = copy.deepcopy(profile)
        with self.assertRaises(GameplayFault):
            grant_reward(profile, {"gold": 50, "avatar_soul": {aid: 5}}, self.doc)
        self.assertEqual(profile, original)

    def test_starting_another_fight_does_not_prune_expired_missing_intent(self):
        aid = self.new_hero()
        profile = self.profile(aid)
        unit = base_unit(self.cfg, aid)
        old = create_intent(profile, "pvp", {}, [unit], [unit], ttl=60, now=1000, config=self.cfg)
        self.runtime["digest"] = "degraded-two"
        create_intent(profile, "pvp", {}, [], [], now=2000, config=self.cfg)
        self.assertIn(old["fight_id"], profile["pending_battles"]["pvp"])
        with self.assertRaisesRegex(GameplayFault, "配置已变化"):
            consume_intent(profile, "pvp", {**old, "sign": 1}, now=2000, config=self.cfg)
        self.assertIn(old["fight_id"], profile["pending_battles"]["pvp"])

    def test_shop_policy_change_narrows_stock_and_preserves_purchase_ledger(self):
        aid = self.new_hero()
        economy = GameplayEconomy(self.store, self.doc)
        rows = [[{"avatar_soul": {"A_1001_5": 5}}, {"coin": 100}],
                [{"avatar_soul": {aid: 5}}, {"coin": 100}],
                [{"avatar_soul": {"A_1002_5": 5}}, {"coin": 100}]]
        sheet = {"t": 1800000000000, "items": rows, "b": [0, 2], "refresh_seq": 9, "mod_digest": "config-one"}
        profile = self.profile()
        profile["attrs"]["mystery_shop"] = {"normal": sheet}
        self.runtime["digest"] = "config-two"
        self.runtime["heroes"][aid]["channels"]["acquisition.shop.hero_soul"] = False
        economy._shop_info_mutation(profile, "test", "normal", {"refresh_interval": 120})
        self.assertEqual(sheet["items"], [rows[0], rows[2]])
        self.assertEqual(sheet["b"], [0, 1])
        self.assertEqual(sheet["refresh_seq"], 9)
        self.assertEqual(profile["coin"], 100000)

    def test_arena_pool_includes_explicit_registered_ids_and_policy_signature(self):
        aid = self.new_hero()
        first = combat_config_signature(self.cfg)
        self.assertIn(aid, highest_rarity_heroes(self.cfg))
        self.runtime["heroes"][aid]["channels"]["appearance.arena_enemy"] = False
        self.assertNotIn(aid, highest_rarity_heroes(self.cfg))
        self.assertNotEqual(first, combat_config_signature(self.cfg))

    def test_activity_whole_card_shard_odds_and_empty_groups(self):
        aid = self.new_hero()
        pool = [{"kind": "avatar", "aid": "A_1001_5", "weight": 10},
                {"kind": "avatar_soul", "aid": "A_1001_5", "weight": 30, "amount": 15}]
        groups = activity_categories(self.doc, pool)
        self.assertEqual([group["weight"] for group in groups], [10, 30])
        self.assertTrue(all(any(row["aid"] == aid for row, _ in group["rows"]) for group in groups))
        self.runtime["heroes"][aid]["channels"]["acquisition.summon.activity"] = False
        self.runtime["heroes"]["A_1001_5"] = {"channels": {"acquisition.summon.activity": False}}
        with self.assertRaisesRegex(GameplayFault, "类别池为空"):
            activity_categories(self.doc, pool)

    def test_new_assist_hero_is_a_selectable_captain_and_usage_toggle_is_checked(self):
        aid = self.new_hero()
        social = GameplaySocial(self.store, self.doc)
        bot = next(bot for bot in social.bots if next(iter(bot["avatars"])).startswith(aid + "|"))
        helper = social.lookup_assist(bot["uid"])
        self.assertEqual(helper["avatar"]["aid"], aid)
        self.runtime["heroes"][aid]["channels"]["usage.friend_assist"] = False
        with self.assertRaisesRegex(GameplayFault, "此玩法中禁用"):
            social.lookup_assist(bot["uid"])


if __name__ == "__main__":
    unittest.main()
