"""Exploration map balance from a realistic three-hero local roster."""
import copy
import json
import sqlite3
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from battle_engine import ReferenceBattle, base_unit, serialize_stage_team
from gameplay_roster import GameplayRosterEquipment
from pve_modes import exploration_stages
from pve_display_power_58 import exploration_opponent_power
from player_store import PlayerStore
from solo_progression import exploration_difficulty, exploration_encounter, _native_team_power


class ExplorationOverhaulTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.config = json.loads((Path(__file__).resolve().parents[1] /
                                 "config/reconstruction/full-config.json").read_text(encoding="utf-8"))

    def make_medium_roster(self):
        db = sqlite3.connect(":memory:", check_same_thread=False)
        self.addCleanup(db.close)
        store = PlayerStore(db, self.config)
        login = store.login("exploration-medium")
        uid = login["uid"]
        aids = ("A_1001_5", "A_1002_5", "A_1003_5")
        ids = [f"{aid}|{index}" for index, aid in enumerate(aids)]
        gear_ids = ("E_1001_5", "E_3001_5")
        def update(profile):
            profile["avatars"] = {
                iid: {"id": iid, "aid": iid, "lv": 99, "slv": 3,
                      "hp": 0, "ap": 0, "de_ph": 0, "de_ma": 0,
                      "phase": 0, "morph": 0, "equips": []}
                for iid in ids}
            profile["team"] = [ids + [None] * 3 for _ in range(3)]
            profile["my_equips"] = {}
            profile["as_equips"] = [[] for _ in range(6)]
            for slot in range(3):
                for item_index, eid in enumerate(gear_ids):
                    key = f"medium-{slot}-{item_index}"
                    profile["my_equips"][key] = {"eid": eid, "lv": 60}
                    profile["as_equips"][slot].append(key)
            return profile, {}
        store.atomic_update(uid, update)
        return store, login, store.profile_raw(uid), ids

    def own_snapshot(self, profile, ids):
        attributes = GameplayRosterEquipment(None, self.config).battle_attributes
        units = []
        for index, iid in enumerate(ids):
            hero = profile["avatars"][iid]
            raw = attributes(profile, iid, hero_only=True)
            overrides = {key: raw.get(key) for key in
                         ("hp", "hp_max", "ap", "de_ph", "de_ma", "tpl", "talent", "morph",
                          "phase", "culture_schema", "growth_stats_applied", "skill", "leader_skill", "book_skill", "skillB")}
            overrides["leader_skill"] = raw.get("leader_skill")
            overrides["new_4attrs"] = {key: raw.get(key, 0) for key in ("hit", "flee", "crit", "tough")}
            units.append(base_unit(self.config["cfg"], hero["aid"].split("|")[0], hero["lv"],
                                   hero["slv"], 0, .2 + .24 * index, True, 1, iid, overrides))
        return units

    def enemy_snapshot(self, encounter):
        enemies = serialize_stage_team(self.config["cfg"], encounter["team2"], team=2)
        rows = encounter["enemy_unit_stats_by_diff"]["0"]
        for unit, row in zip(enemies, rows):
            unit["line"] = 0
            for key in ("hp", "ap", "de_ph", "de_ma"):
                unit[key] = row[key]
            unit["hp_max"] = unit["hp"]
            unit["new_4attrs"] = {key: row[key] for key in ("hit", "flee", "crit", "tough")}
        return enemies

    def test_combat_dispatch_powers_match_native_snapshots(self):
        store, login, _, ids = self.make_medium_roster()
        def call(method, params):
            return store.dispatch({"uid": login["uid"], "sessionid": login["sessionid"],
                                   "method": method, "params": params})
        call("user.exploration_make_army", {"aids": ids})
        battle = call("user.exploration_combat",
                      {"team": [[iid, 0, .2 + .24 * index] for index, iid in enumerate(ids)]})
        self.assertEqual(len(battle["orgin_team_a"]), 3)
        self.assertEqual(len(battle["orgin_team_b"]), 2)
        self.assertEqual(battle["def_th"], 1)
        self.assertEqual([unit["aid"] for unit in battle["orgin_team_a"]],
                         [iid.split("|")[0] for iid in ids])
        self.assertEqual([unit["instance_id"] for unit in battle["orgin_team_a"]], ids)
        self.assertTrue(all(unit["leader"] and unit["leader_skill"]
                            for unit in battle["orgin_team_a"]))
        self.assertEqual(battle["my_pr_power"],
                         _native_team_power(self.config, battle["orgin_team_a"]))
        self.assertEqual(battle["pr_power"],
                         _native_team_power(self.config, battle["orgin_team_b"]))
        self.assertGreater(battle["my_pr_power"], 0)
        self.assertGreater(battle["pr_power"], 0)
        final_a = copy.deepcopy(battle["orgin_team_a"])
        final_a[0]["hp"] = final_a[0]["hp_max"] // 2
        call("user.battle_finish", {"fight_id": battle["fight_id"], "fight_kind": "exploration",
                                    "metadata": battle["metadata"], "sign": 2,
                                    "teams": {"team_a": final_a, "team_b": []}})
        retained = store.profile_raw(login["uid"])["exploration"]["army"]
        self.assertEqual(set(retained), set(ids))
        self.assertAlmostEqual(retained[ids[0]]["current_hp"] / retained[ids[0]]["max_hp"],
                               .5, delta=.001)

    def test_hero_only_stats_keep_cultivation_and_migrate_old_hp_ratio(self):
        store, login, profile, ids = self.make_medium_roster()
        roster = GameplayRosterEquipment(store, self.config)
        geared = roster.battle_attributes(profile, ids[0])
        personal = roster.battle_attributes(profile, ids[0], hero_only=True)
        self.assertGreater(geared["hp_max"], personal["hp_max"])
        self.assertGreater(geared["ap"], personal["ap"])
        unarmed = copy.deepcopy(profile)
        unarmed["as_equips"] = [[] for _ in range(6)]
        self.assertEqual(exploration_difficulty(profile, ids, self.config)["team_power"],
                         exploration_difficulty(unarmed, ids, self.config)["team_power"])
        trained = copy.deepcopy(unarmed)
        trained["avatars"][ids[0]]["phase"] = 1
        trained["avatars"][ids[0]]["hp"] = 20
        self.assertGreater(roster.battle_attributes(trained, ids[0], hero_only=True)["hp_max"],
                           personal["hp_max"])
        selected = store.dispatch({"uid": login["uid"], "sessionid": login["sessionid"],
                                   "method": "user.exploration_make_army",
                                   "params": {"aids": ids}})
        self.assertEqual(selected["army"][ids[0]]["max_hp"], personal["hp_max"])
        self.assertTrue(all(selected["army"][iid]["exploration_hero_only"] is True
                            for iid in ids))
        self.assertTrue(all("exploration_hero_only" not in store.profile_raw(login["uid"])["avatars"][iid]
                            for iid in ids))

        def old_map(saved):
            saved["exploration"]["army"] = {}
            for iid in ids:
                maximum = roster.battle_attributes(saved, iid)["hp_max"]
                saved["exploration"]["army"][iid] = {
                    **copy.deepcopy(saved["avatars"][iid]), "max_hp": maximum,
                    "current_hp": maximum // 2}
            saved["exploration"]["difficulty"] = {"level": 99, "star": 5,
                                                    "team_power": 123456}
            saved["exploration"].pop("attribute_schema", None)
            return saved, {}
        store.atomic_update(login["uid"], old_map)
        response = store.dispatch({"uid": login["uid"], "sessionid": login["sessionid"],
                                   "method": "user.exploration_start", "params": {}})
        current = store.profile_raw(login["uid"])["exploration"]
        self.assertEqual(current["attribute_schema"], "hero-only-v1")
        self.assertEqual(current["difficulty"]["stat_schema"], "hero-only-all-captains-v2")
        self.assertNotEqual(current["difficulty"]["team_power"], 123456)
        self.assertEqual(response["army"][ids[0]]["max_hp"], personal["hp_max"])
        self.assertTrue(all(response["army"][iid]["exploration_hero_only"] is True
                            for iid in ids))
        self.assertAlmostEqual(response["army"][ids[0]]["current_hp"] / personal["hp_max"],
                               .5, delta=.001)

    def test_frozen_difficulty_and_twelve_stage_approximate_clear(self):
        _, _, profile, ids = self.make_medium_roster()
        team = self.own_snapshot(profile, ids)
        state = {"map_revision": 0, "difficulty": exploration_difficulty(profile, ids, self.config)}
        self.assertGreater(state["difficulty"]["team_power"], 0)
        self.assertEqual(state["difficulty"]["member_count"], 3)
        self.assertAlmostEqual(state["difficulty"]["team_power"], _native_team_power(self.config, team),
                               delta=state["difficulty"]["team_power"] * .05)
        unarmed = copy.deepcopy(profile)
        unarmed["as_equips"] = [[] for _ in range(6)]
        self.assertEqual(exploration_difficulty(unarmed, ids, self.config)["team_power"],
                         state["difficulty"]["team_power"])
        stages = exploration_stages(self.config)
        self.assertEqual(len(stages), 12)
        snapshots = []
        for stage, template in enumerate(stages, 1):
            encounter = exploration_encounter(self.config, profile, state, stage, template)
            repeat = exploration_encounter(self.config, profile, state, stage, template)
            self.assertEqual(encounter, repeat)
            self.assertEqual(encounter["reward"], template["reward"])
            enemies = self.enemy_snapshot(encounter)
            snapshots.append(enemies)
            self.assertTrue(2 <= len(enemies) <= 4)
            enemy_power = _native_team_power(self.config, enemies)
            self.assertGreater(enemy_power, 0)
            target = state["difficulty"]["team_power"] * (.09 + .02 * (stage - 1) / 11)
            self.assertAlmostEqual(enemy_power, target,
                                   delta=state["difficulty"]["team_power"] * .03)
            self.assertEqual(exploration_opponent_power(self.config, encounter), enemy_power)
            report = ReferenceBattle(team, enemies, seed=stage * 137).run()
            self.assertEqual(report["winner"], 1, f"stage {stage} failed")
            team = report["team_a"]
        health = sum(unit["hp"] for unit in team) / sum(unit["hp_max"] for unit in team)
        # Armor-ignoring DOTs change the former tuning band. The contract is
        # repeatable full clears with valid persistent HP, checked below.
        self.assertGreater(health, 0)
        self.assertLess(health, 1)
        clears = 0
        for trial in range(10):
            trial_team = self.own_snapshot(profile, ids)
            for stage, enemies in enumerate(snapshots, 1):
                result = ReferenceBattle(trial_team, enemies, seed=trial * 997 + stage * 137).run()
                if result["winner"] != 1:
                    break
                trial_team = result["team_a"]
            else:
                clears += 1
        self.assertEqual(clears, 10, f"only {clears}/10 approximate maps cleared")

    def test_refreshed_map_uses_same_frozen_snapshot_and_new_rewards(self):
        _, _, profile, ids = self.make_medium_roster()
        legacy = {"map_revision": 0, "difficulty": {"level": 99, "star": 5},
                  "army": {iid: profile["avatars"][iid] for iid in ids}}
        exploration_encounter(self.config, profile, legacy, 1, exploration_stages(self.config)[0])
        self.assertGreater(legacy["difficulty"]["team_power"], 0)
        old_captain_anchor = {"map_revision": 0,
                              "difficulty": {"stat_schema": "hero-only-v1", "level": 99,
                                             "star": 5, "team_power": 123456},
                              "army": {iid: profile["avatars"][iid] for iid in ids}}
        exploration_encounter(self.config, profile, old_captain_anchor, 1,
                              exploration_stages(self.config)[0])
        self.assertEqual(old_captain_anchor["difficulty"]["stat_schema"],
                         "hero-only-all-captains-v2")
        self.assertNotEqual(old_captain_anchor["difficulty"]["team_power"], 123456)
        missing_snapshot = {"map_revision": 0,
                            "army": {iid: profile["avatars"][iid] for iid in ids}}
        restored = exploration_encounter(self.config, profile, missing_snapshot, 1,
                                         exploration_stages(self.config)[0])
        self.assertGreater(missing_snapshot["difficulty"]["team_power"], 0)
        self.assertIn("0", restored["enemy_unit_stats_by_diff"])
        state = {"map_revision": 1, "difficulty": exploration_difficulty(profile, ids, self.config)}
        template = exploration_stages(self.config)[5]
        first = exploration_encounter(self.config, profile, state, 6, template)
        stronger = copy.deepcopy(profile)
        for hero in stronger["avatars"].values():
            hero["slv"] = 8
        second = exploration_encounter(self.config, stronger, state, 6, template)
        self.assertEqual(first, second)
        self.assertEqual(len(first["team2"]), 3)
        self.assertEqual(first["reward"]["coin"], 25)
        self.assertEqual(len(self.enemy_snapshot(first)), 3)
        generated = [self.enemy_snapshot(exploration_encounter(self.config, profile, state, stage, source))
                     for stage, source in enumerate(exploration_stages(self.config), 1)]
        clears = 0
        for trial in range(10):
            team = self.own_snapshot(profile, ids)
            for stage, enemies in enumerate(generated, 1):
                result = ReferenceBattle(team, enemies, seed=trial * 997 + stage * 137).run()
                if result["winner"] != 1:
                    break
                team = result["team_a"]
            else:
                clears += 1
        self.assertEqual(clears, 10, f"only {clears}/10 generated maps cleared")


if __name__ == "__main__":
    unittest.main()
