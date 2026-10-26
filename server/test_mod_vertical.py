"""Production gateway Mod flows with isolated SQLite saves and real packages.

These test the server's client-result contract, not ActionScript combat parity.
Native AIR combat execution is a separate release check.
"""
import copy
import hashlib
import sys
import unittest
import uuid
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import test_mod_service as fixtures
from gameplay_common import grant_reward
from mod_schema import canonical


class ModVerticalTests(unittest.TestCase):
    setUp = fixtures.ModServiceTests.setUp
    login = fixtures.ModServiceTests.login
    rpc = fixtures.ModServiceTests.rpc
    install = fixtures.ModServiceTests.install
    selection = staticmethod(fixtures.ModServiceTests.selection)
    activate = fixtures.ModServiceTests.activate

    def enabled_new_hero(self, count=1):
        package = fixtures.archive(self.root)
        metadata = self.backend.mods.install_bytes(package.read_bytes())
        self.activate(self.a, [self.selection(metadata)])
        runtime = self.backend.mods.config(self.a["uid"])["mod_runtime"]
        aid = next(aid for aid, row in runtime["heroes"].items() if row["kind"] == "new")
        result = self.rpc(self.a, "user.mods_test_grant", {"aid": aid, "count": count})
        return package, metadata, aid, list(result["new_avatars"])

    def formation(self, ids):
        result = self.rpc(self.a, "user.fix_team", {"team": [ids, ids, ids], "team_num": 0})
        self.assertEqual([member for member in result["team"][0] if member], ids)
        return [[iid, index % 3, .2] for index, iid in enumerate(ids)]

    def patch_archive(self, aid, before, after):
        pid = str(uuid.uuid4())
        payload = canonical({"patches": [{"id": "restore-normal", "target": "builtin:avatar/" + aid,
            "expect": {"path": "skills.normal", "value": "builtin:skill/" + before},
            "operations": [{"op": "replace", "path": "skills.normal", "value": "builtin:skill/" + after}]}]})
        manifest = {"format": "lal-mod-v1", "kind": "patch", "packageId": pid,
            "name": "Scoped skill restore", "author": "Test", "version": "1.0.0", "engineApi": "1",
            "requiredCapabilities": ["hero.patch.skill"], "entrypoints": {"patches": "patches.json"},
            "dependencies": [], "files": [{"path": "patches.json", "sha256": hashlib.sha256(payload).hexdigest()}]}
        path = self.root / (pid + ".heropack")
        with zipfile.ZipFile(path, "w") as bundle:
            bundle.writestr("manifest.json", canonical(manifest))
            bundle.writestr("patches.json", payload)
        return self.backend.mods.install_bytes(path.read_bytes())

    def test_new_hero_real_rpc_formation_battle_settlement_and_retry(self):
        _, _, aid, made = self.enabled_new_hero()
        profile = self.backend.players.profile_raw(self.a["uid"])
        starter = [iid for iid in profile["team"][0] if iid][:2]
        rows = self.formation(made + starter)
        battle = self.rpc(self.a, "user.pk_combat", {"cid": "M_001_1", "diff": 0, "team_num": 0, "team": rows})
        self.assertEqual(battle["orgin_team_a"][0]["aid"], aid)
        self.assertEqual(battle["orgin_team_a"][0]["instance_id"], made[0])
        pending = self.backend.players.profile_raw(self.a["uid"])["pending_pve"][battle["fight_id"]]
        self.assertEqual(pending["mod_digest"], self.backend.mods.config(self.a["uid"])["digest"])
        finish = {"fight_id": battle["fight_id"], "cid": "M_001_1", "diff": 0, "sign": 2,
                  "teams": {"team_a": [], "team_b": []}}
        settled = self.rpc(self.a, "user.pve_finish", finish, action="finish-once")
        replay = self.rpc(self.a, "user.pve_finish", finish, action="finish-once")
        self.assertEqual(settled["sign"], 2)
        self.assertEqual(replay["sign"], 2)
        after = self.backend.players.profile_raw(self.a["uid"])
        self.assertNotIn(battle["fight_id"], after["pending_pve"])
        self.assertIn(made[0], after["avatars"])

    def test_same_battle_owned_and_arena_enemy_use_distinct_skill_definitions(self):
        _, new_package, new_aid, made = self.enabled_new_hero()
        target = "A_1020_4"  # Authored second hero of the first-match arena robot.
        before = self.backend.config["cfg"]["avatar"][target]["pl"][10]
        restored = "S_201001_5"
        self.assertNotEqual(before, restored)
        patch = self.patch_archive(target, before, restored)
        self.activate(self.a, [self.selection(new_package), self.selection(patch, patchScopes={"arenaEnemy": False})])

        def seed(profile):
            previous = set(profile["avatars"])
            grant_reward(profile, {"heroes": [{"aid": target, "num": 1}]}, self.backend.config)
            return profile, next(iid for iid in profile["avatars"] if iid not in previous)
        owned_id = self.backend.players.atomic_update(self.a["uid"], seed)[0]
        profile = self.backend.players.profile_raw(self.a["uid"])
        extra = next(iid for iid in profile["team"][0] if iid)
        rows = self.formation([owned_id, made[0], extra])
        battle = self.rpc(self.a, "user.pk_combat_pvp", {"uid": "r999999999_6_0", "rank": 0,
                           "team_num": 0, "team": rows})
        own = next(unit for unit in battle["orgin_team_a"] if unit["aid"] == target)
        enemy = next(unit for unit in battle["orgin_team_b"] if unit.get("base_aid") == target)
        self.assertEqual(own["skill"]["skid"], restored)
        self.assertEqual(enemy["skill"]["skid"], before)
        self.assertNotEqual(enemy["aid"], own["aid"])
        self.assertIn(new_aid, [unit["aid"] for unit in battle["orgin_team_a"]])
        result = self.rpc(self.a, "user.battle_finish", {"fight_id": battle["fight_id"], "fight_kind": "pvp",
                          "metadata": battle["metadata"], "sign": 2, "teams": {"team_a": [], "team_b": []}})
        self.assertEqual(result["sign"], 2)

    def test_exploration_unclaimed_reward_is_frozen_on_deletion_and_restored(self):
        package, metadata, aid, made = self.enabled_new_hero(count=3)
        self.rpc(self.a, "user.exploration_make_army", {"aids": made})
        battle = self.rpc(self.a, "user.exploration_combat", {"team": [[iid, 0, .2 + .2 * i] for i, iid in enumerate(made)]})
        self.rpc(self.a, "user.battle_finish", {"fight_id": battle["fight_id"], "fight_kind": "exploration",
                 "metadata": battle["metadata"], "sign": 1, "teams": {"team_a": battle["orgin_team_a"], "team_b": []}})
        original = self.backend.players.profile_raw(self.a["uid"])
        frozen = copy.deepcopy(original["exploration"]["mod_pending_reward"])
        self.assertEqual(frozen["mod_digest"], self.backend.mods.config(self.a["uid"])["digest"])
        plan = self.rpc(self.a, "user.mods_plan", {"expectedRevision": 1, "selections": []})
        self.assertFalse(plan["valid"])
        self.assertEqual(plan["errors"][0]["code"], "ModPendingOperation")
        self.backend.mods.catalog.uninstall(metadata["packageId"], metadata["version"], metadata.get("digest", metadata.get("contentDigest")))
        error = self.rpc(self.a, "user.exploration_get_reward", expected=1)
        self.assertEqual(error["error_code"], "ModBattleConfigChanged")
        after = self.backend.players.profile_raw(self.a["uid"])
        self.assertEqual(after["gold"], original["gold"])
        self.assertEqual(after["exploration"]["mod_pending_reward"], frozen)
        self.backend.mods.install_bytes(package.read_bytes())
        self.rpc(self.a, "user.exploration_get_reward")
        restored = self.backend.players.profile_raw(self.a["uid"])
        self.assertEqual(restored["gold"], original["gold"] + frozen["reward"].get("gold", 0))
        self.assertNotIn("mod_pending_reward", restored["exploration"])
        self.assertEqual(restored["exploration"]["stage"], 2)


if __name__ == "__main__":
    unittest.main()
