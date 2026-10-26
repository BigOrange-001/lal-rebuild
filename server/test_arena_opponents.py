"""Arena refresh, native preview, stale UID and retained-intent boundaries."""
import copy
import json
import sqlite3
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from arena_opponents import combat_config_signature, highest_rarity_heroes
from bot_names import BOT_NAMES
from battle_engine import _native_skill_snapshot
from gameplay_competition import GameplayCompetition
from gameplay_roster import GameplayRosterEquipment
from player_store import GameplayFault, PlayerStore


class ArenaOpponentsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.config = json.loads((Path(__file__).resolve().parents[1] /
                                 "config/reconstruction/full-config.json").read_text(encoding="utf-8"))

    def setUp(self):
        self.db = sqlite3.connect(":memory:", check_same_thread=False)
        self.addCleanup(self.db.close)
        self.store = PlayerStore(self.db, self.config)
        self.uid = self.store.login("arena-generated")["uid"]
        self.comp = GameplayCompetition(self.store, self.config)
        def king(profile):
            profile.setdefault("records", {})["current_rank"] = 1
            profile.setdefault("attrs", {})["pvp_rank"] = 1
            profile["attrs"]["pvp_count"] = 1
            return profile, {}
        self.store.atomic_update(self.uid, king)

    def _team(self):
        saved = self.store.profile_raw(self.uid)["team"][0]
        return [[iid, slot % 3, .2 if slot < 3 else .1]
                for slot, iid in enumerate(iid for iid in saved if iid)]

    def test_king_batch_uses_highest_hero_forms_and_real_power(self):
        pool = highest_rarity_heroes(self.config["cfg"])
        self.assertGreaterEqual(len(pool), 100)
        blocked = set(self.config["cfg"]["system_simple"]["skin_acquisition_blocked_heroes"])
        self.assertTrue(set(pool) & blocked)
        forms = {aid.rsplit("_", 1)[0]: aid for aid in pool}
        self.assertEqual(len(forms), len(pool))
        listed = self.comp.dispatch(self.uid, "user.get_rank_list", {})
        rows = listed[2]
        self.assertEqual([row[0] for row in rows], list(range(2, 11)))
        self.assertEqual(len(rows), 9)
        batch = self.store.profile_raw(self.uid)["records"]["pvp_opponents"]
        self.assertEqual(len({bot["name"] for bot in batch["bots"]}), 9)
        self.assertTrue(all(bot["name"] in BOT_NAMES for bot in batch["bots"]))
        self.assertEqual(batch["source_power"], self.comp._team_power(
            self.comp._current_arena_team(self.store.profile_raw(self.uid))))
        powers = []
        for index, (row, bot) in enumerate(zip(rows, batch["bots"])):
            self.assertEqual(row[1], bot["uid"])
            self.assertNotIn("r", bot["uid"])
            self.assertEqual(len(row[3]), 5)
            self.assertEqual({unit["line"] for unit in bot["units"]}, {0, 1, 2})
            aids = [unit["aid"] for unit in bot["units"]]
            self.assertEqual(len(set(aids)), 5)
            self.assertTrue(all(forms[aid.rsplit("_", 1)[0]] == aid for aid in aids))
            actual = self.comp._team_power(bot["units"])
            powers.append(actual)
            self.assertEqual(actual, bot["power"])
            target = batch["source_power"] * (1.25 - .75 * index / 8)
            # Power 1.5 produces small integer totals for starter teams.
            # A half-point rounded target must not fail a percentage-only bound.
            self.assertLessEqual(abs(actual - target), max(1, target * .015))
            preview = self.comp.dispatch(self.uid, "user.get_battle_users",
                                         {"users": [[bot["uid"]]]})
            self.assertEqual(preview[bot["uid"]]["data"], row[3])
        self.assertEqual(powers, sorted(powers, reverse=True))
        self.assertEqual(self.comp.dispatch(self.uid, "user.get_rank_list", {})[2], rows)

    def test_refresh_rebuilds_roster_and_old_fight_remains_stable(self):
        old = self.comp.dispatch(self.uid, "user.get_rank_list", {})[2]
        rival = old[0]
        started = self.comp.dispatch(self.uid, "user.pk_combat_pvp",
                                     {"uid": rival[1], "rank": rival[0],
                                      "team": self._team(), "actionID": "arena-start-old"})
        self.assertEqual(started["pr_power"], self.comp._team_power(started["orgin_team_b"]))
        changed = self.comp.dispatch(self.uid, "user.refresh_pvp_opponents",
                                     {"actionID": "arena-refresh-one"})
        self.assertEqual(len(changed[2]), 9)
        new_batch = self.store.profile_raw(self.uid)["records"]["pvp_opponents"]
        self.assertEqual([row[0] for row in changed[2]],
                         [bot["rank"] for bot in new_batch["bots"]])
        self.assertEqual([row[1] for row in changed[2]],
                         [bot["uid"] for bot in new_batch["bots"]])
        self.assertEqual([bot["power"] for bot in new_batch["bots"]],
                         sorted((bot["power"] for bot in new_batch["bots"]), reverse=True))
        self.assertNotEqual([row[1] for row in old], [row[1] for row in changed[2]])
        self.assertNotEqual([row[3] for row in old], [row[3] for row in changed[2]])
        replay = self.comp.dispatch(self.uid, "user.refresh_pvp_opponents",
                                    {"actionID": "arena-refresh-one"})
        self.assertEqual(replay, changed)
        self.assertEqual(self.store.profile_raw(self.uid)["records"]["pvp_opponent_generation"], 2)
        with self.assertRaises(GameplayFault) as stale:
            self.comp.dispatch(self.uid, "user.pk_combat_pvp",
                               {"uid": rival[1], "rank": rival[0],
                                "team": self._team(), "actionID": "stale-new-start"})
        self.assertEqual(stale.exception.code, "UnknownOpponent")
        self.assertEqual(self.comp.dispatch(self.uid, "user.pk_combat_pvp",
                                   {"uid": rival[1], "rank": rival[0],
                                    "team": self._team(), "actionID": "arena-start-old"}), started)
        finish = {"fight_kind": "pvp", "fight_id": started["fight_id"], "sign": 1,
                  "metadata": started["metadata"],
                  "teams": {"team_a": started["orgin_team_a"],
                            "team_b": started["orgin_team_b"]},
                  "actionID": "arena-finish-old"}
        won = self.comp.dispatch(self.uid, "user.battle_finish", finish)
        self.assertEqual(won["current_rank"], 1)
        history = self.comp.dispatch(self.uid, "user.get_rank_list", {})[3]
        self.assertTrue(any(row[1] == rival[1] and row[3] == rival[3] for row in history))
        previous = self.comp.dispatch(self.uid, "user.get_battle_users",
                                      {"users": [[rival[1]]]})
        self.assertEqual(previous[rival[1]]["data"], rival[3])
        playback = self.comp.dispatch(self.uid, "user.get_combat_playback",
                                      {"cpb_id": started["fight_id"]})
        self.assertEqual(playback["orgin_team_b"], started["orgin_team_b"])

    def test_existing_first_robot_and_fragment_start_still_work(self):
        def first(profile):
            profile["records"]["current_rank"] = 100
            profile["attrs"]["pvp_rank"] = 100
            profile["attrs"]["pvp_count"] = 0
            return profile, {}
        self.store.atomic_update(self.uid, first)
        robot = self.comp.dispatch(self.uid, "user.pk_combat_pvp",
                                   {"uid": "r999999999_6_0", "rank": 99,
                                    "team": self._team(), "actionID": "first-robot"})
        self.assertTrue(robot["orgin_team_b"])
        one_lane = [[row[0], 0, row[2]] for row in self._team()]
        fragment = self.comp.dispatch(self.uid, "user.pk_combat_fragment",
                                      {"uid": "b_001",
                                       "eid": self.comp.side["fragment_eids"][0],
                                       "fragment_index": 0, "team": one_lane,
                                       "actionID": "fragment-legacy"})
        self.assertTrue(fragment["orgin_team_b"])

    def test_rank_change_rebuilds_nine_without_self_rank_collision(self):
        old = self.comp.dispatch(self.uid, "user.get_rank_list", {})
        def change(profile):
            profile["records"]["current_rank"] = 2
            profile["attrs"]["pvp_rank"] = 2
            return profile, {}
        self.store.atomic_update(self.uid, change)
        current = self.comp.dispatch(self.uid, "user.get_rank_list", {})
        self.assertEqual(current[0], 2)
        self.assertEqual(len(current[2]), 9)
        self.assertNotIn(2, [row[0] for row in current[2]])
        self.assertEqual([row[0] for row in current[2]],
                         sorted(row[0] for row in current[2]))
        updated_batch = self.store.profile_raw(self.uid)["records"]["pvp_opponents"]["bots"]
        self.assertEqual([(row[0], row[1]) for row in current[2]],
                         [(bot["rank"], bot["uid"]) for bot in updated_batch])
        self.assertEqual([bot["power"] for bot in updated_batch],
                         sorted((bot["power"] for bot in updated_batch), reverse=True))
        self.assertNotEqual([row[1] for row in old[2]], [row[1] for row in current[2]])

    def test_existing_legacy_batch_is_rebuilt_on_normal_rank_list_read(self):
        old_rows = self.comp.dispatch(self.uid, "user.get_rank_list", {})[2]
        old_batch = self.store.profile_raw(self.uid)["records"]["pvp_opponents"]

        def legacy(profile):
            profile["records"]["pvp_opponents"].pop("power_order_schema", None)
            return profile, {}

        self.store.atomic_update(self.uid, legacy)
        new_rows = self.comp.dispatch(self.uid, "user.get_rank_list", {})[2]
        new_batch = self.store.profile_raw(self.uid)["records"]["pvp_opponents"]
        self.assertEqual(new_batch["generation"], old_batch["generation"] + 1)
        self.assertNotEqual([row[1] for row in new_rows], [row[1] for row in old_rows])
        self.assertEqual([bot["power"] for bot in new_batch["bots"]],
                         sorted((bot["power"] for bot in new_batch["bots"]), reverse=True))
        self.assertEqual(self.comp.dispatch(self.uid, "user.get_rank_list", {})[2], new_rows)

    def test_config_change_refreshes_skill_snapshots_without_touching_pending_intent(self):
        old_rows = self.comp.dispatch(self.uid, "user.get_rank_list", {})[2]
        old_batch = self.store.profile_raw(self.uid)["records"]["pvp_opponents"]
        old_rival = old_rows[0]
        started = self.comp.dispatch(self.uid, "user.pk_combat_pvp", {
            "uid": old_rival[1], "rank": old_rival[0], "team": self._team(),
            "actionID": "arena-before-balance-update",
        })
        updated_config = copy.deepcopy(self.config)
        old_skill = old_batch["bots"][0]["units"][0]["skill"]["skid"]
        updated_config["cfg"]["skill"][old_skill]["pl"][0] += 1
        updated_comp = GameplayCompetition(self.store, updated_config)
        self.assertNotEqual(combat_config_signature(self.config["cfg"]),
                            combat_config_signature(updated_config["cfg"]))

        with self.assertRaises(GameplayFault) as stale:
            updated_comp.dispatch(self.uid, "user.pk_combat_pvp", {
                "uid": old_rival[1], "rank": old_rival[0], "team": self._team(),
                "actionID": "arena-stale-after-balance-update",
            })
        self.assertEqual(stale.exception.code, "UnknownOpponent")

        fresh_rows = updated_comp.dispatch(self.uid, "user.get_rank_list", {})[2]
        profile = self.store.profile_raw(self.uid)
        fresh_batch = profile["records"]["pvp_opponents"]
        self.assertEqual(fresh_batch["power_order_schema"], old_batch["power_order_schema"])
        self.assertEqual(fresh_batch["combat_config_sha256"],
                         combat_config_signature(updated_config["cfg"]))
        self.assertEqual(fresh_batch["generation"], old_batch["generation"] + 1)
        self.assertNotEqual([row[1] for row in fresh_rows], [row[1] for row in old_rows])
        self.assertEqual([bot["power"] for bot in fresh_batch["bots"]],
                         sorted((bot["power"] for bot in fresh_batch["bots"]), reverse=True))
        for unit in fresh_batch["bots"][0]["units"]:
            skill = unit["skill"]
            self.assertEqual(skill, _native_skill_snapshot(updated_config["cfg"],
                                                           skill["skid"], unit["slv"]))
        pending = profile["pending_battles"]["pvp"][started["fight_id"]]
        self.assertEqual(pending["team_b"], started["orgin_team_b"])
        replay = updated_comp.dispatch(self.uid, "user.pk_combat_pvp", {
            "uid": old_rival[1], "rank": old_rival[0], "team": self._team(),
            "actionID": "arena-before-balance-update",
        })
        self.assertEqual(replay, started)

    def test_empty_captain_slot_does_not_promote_another_hero(self):
        profile = self.store.profile_raw(self.uid)
        profile['team'][0][0] = None
        units = self.comp._current_arena_team(profile)
        self.assertTrue(units)
        self.assertTrue(all(not unit['leader'] and unit['leader_skill'] is None for unit in units))

    def test_high_progression_origin_applies_each_owned_bonus_once(self):
        orange_id = "A_1022_6|arena125"
        bound_id = "A_1003_5|dn"

        def progress(profile):
            old_id = profile["team"][0][0]
            hero = profile["avatars"].pop(old_id)
            hero.update(id=orange_id, aid=orange_id, lv=125, slv=10,
                        phase=3, limit_break=1, talent="T_04_07")
            profile["avatars"][orange_id] = hero
            for squad in profile["team"]:
                squad[0] = orange_id
            bound = copy.deepcopy(profile["avatars"][profile["team"][0][2]])
            bound.update(id=bound_id, aid=bound_id, lv=99, phase=2)
            profile["avatars"][bound_id] = bound
            profile["my_equips"]["arena-eq"] = {
                "eid": "E_1001_6", "lv": 125, "halo": {"lv": 5, "exp": 0},
                "magic": [10, 10, 10, 10], "symp": -1,
            }
            profile["as_equips"][0] = ["arena-eq"]
            profile["attrs"]["dn"] = {"1": [35, bound_id, [99, 0, 0, 0, 0, 2]]}
            profile["attrs"]["guild_graduate_skill"] = {
                "guild_attack": 1, "guild_health": 1, "guild_guard": 1,
            }
            return profile, {}

        self.store.atomic_update(self.uid, progress)
        profile = self.store.profile_raw(self.uid)
        roster = self.comp._attr
        fully_built = roster(profile, orange_id)
        self.assertEqual((fully_built["lv"], fully_built["phase"]), (125, 3))

        no_talent = copy.deepcopy(profile)
        no_talent["avatars"][orange_id]["talent"] = None
        without_talent = roster(no_talent, orange_id)
        self.assertEqual(fully_built["hp"], int(without_talent["hp"] * 1.7))
        self.assertEqual(fully_built["ap"], without_talent["ap"])

        no_guild = copy.deepcopy(no_talent)
        no_guild["attrs"]["guild_graduate_skill"] = {}
        without_guild = roster(no_guild, orange_id)
        no_dn = copy.deepcopy(no_guild)
        no_dn["attrs"]["dn"] = {}
        without_dn = roster(no_dn, orange_id)
        roster_rules = GameplayRosterEquipment(self.store, self.config)
        dn_bonus = roster_rules._destiny_team_bonuses(no_guild)
        researched_dn_bonus = roster_rules._destiny_team_bonuses(no_talent)
        for stat in ("hp", "ap", "de_ph", "de_ma"):
            self.assertEqual(without_guild[stat], without_dn[stat] + dn_bonus[stat])
            # Research also raises the DN-bound donor before its flat share
            # is granted; the receiver then applies its own 2% research.
            self.assertEqual(without_talent[stat],
                             int((without_dn[stat] + researched_dn_bonus[stat]) * 1.02))

        no_equipment = copy.deepcopy(no_dn)
        no_equipment["as_equips"] = [[] for _ in range(6)]
        without_equipment = roster(no_equipment, orange_id)
        self.assertGreater(without_dn["hp"], without_equipment["hp"])
        self.assertGreater(without_dn["ap"], without_equipment["ap"])

        rows = self.comp.dispatch(self.uid, "user.get_rank_list", {})[2]
        opponent = rows[0]
        generated = self.store.profile_raw(self.uid)["records"]["pvp_opponents"]["bots"][0]
        started = self.comp.dispatch(self.uid, "user.pk_combat_pvp", {
            "uid": opponent[1], "rank": opponent[0], "team": self._team(),
            "actionID": "arena-high-progression",
        })
        captain = started["orgin_team_a"][0]
        for stat in ("hp", "hp_max", "ap", "de_ph", "de_ma"):
            self.assertEqual(captain[stat], fully_built[stat], stat)
        self.assertEqual(captain["limit_break"], 1)
        self.assertEqual(started["my_pr_power"],
                         self.comp._team_power(started["orgin_team_a"]))
        self.assertEqual(started["orgin_team_b"], generated["units"])
        self.assertEqual(started["pr_power"], generated["power"])


if __name__ == "__main__":
    unittest.main()
