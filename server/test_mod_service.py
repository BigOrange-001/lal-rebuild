"""Save isolation, activation receipts and missing-content recovery through real RPCs."""
import copy
import hashlib
import json
import os
import subprocess
import sys
import tempfile
import threading
import unittest
from unittest import mock
import urllib.error
import urllib.request
import uuid
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from gateway import Backend, make_server
from mod_schema import canonical
from mod_service import digest
from mod_packages import ModCatalog
from player_store import GameplayFault


ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "config/reconstruction/full-config.json"


def archive(directory, *, package_id=None, version="1.0.0", kind="new", name="Demo", patches=None):
    package_id = package_id or str(uuid.uuid4())
    hero = {"id": "demo", "variant": "purple", "name": name, "unitType": "hero", "quality": 5,
            "signType": "attack", "actionType": "forward", "damageType": "physical",
            "baseStats": {"health": 1200, "attack": 100, "physicalDefense": 60, "magicDefense": 40},
            "growth": {"health": 100, "attack": 8, "physicalDefense": 5, "magicDefense": 3},
            "speed": 245, "attackRange": 337, "leadership": 26, "levelCap": 99,
            "progression": {"preset": "builtin:progression/default-player-hero", "starUp": None},
            "skills": {"normal": "builtin:skill/S_201001_5", "captain": None, "passive": None},
            "presentation": {"portrait": "builtin:portrait/A_1001_5", "icon": "builtin:icon/A_1001_5",
                             "basicAttackEffect": "builtin:effect/E_008", "voice": None}}
    entry = "heroes" if kind == "new" else "patches"
    payload = canonical({entry: [hero] if kind == "new" else patches})
    manifest = {"format": "lal-mod-v1", "kind": kind, "packageId": package_id, "name": name,
                "author": "Test", "version": version, "engineApi": "1",
                "requiredCapabilities": ["hero.register"] if kind == "new" else ["hero.patch.text"],
                "entrypoints": {entry: entry + ".json"}, "dependencies": [],
                "files": [{"path": entry + ".json", "sha256": hashlib.sha256(payload).hexdigest()}]}
    path = Path(directory) / (package_id + "-" + version + ".heropack")
    with zipfile.ZipFile(path, "w") as bundle:
        bundle.writestr("manifest.json", canonical(manifest))
        bundle.writestr(entry + ".json", payload)
    return path


class ModServiceTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.backend = Backend(self.root / "saves/local.sqlite3", CONFIG, self.root / "mods")
        self.addCleanup(self.backend.clock.close)
        self.addCleanup(self.backend.db.close)
        self.serial = 0
        self.a = self.login("A")
        self.b = self.login("B")

    def login(self, name):
        params = {"pf": "local", "session_key": name, "sessionid": "test-password", "actionID": "register-" + name}
        self.backend.call({"method": "user.register", "params": params})
        return self.backend.call({"method": "user.login", "params": {**params, "actionID": "login-" + name}})["data"]

    def rpc(self, owner, method, params=None, *, action=None, expected=0, mod_digest=None):
        self.serial += 1
        request = {"method": method, "uid": owner["uid"], "sessionid": owner["sessionid"],
                   "params": {"actionID": action or "test-" + str(self.serial), **(params or {})}}
        request["mod_digest"] = mod_digest or self.backend.mods.config(owner["uid"])["digest"]
        result = self.backend.call(request)
        self.assertEqual(result["return_code"], expected, result)
        return result["data"]

    def install(self, **kwargs):
        path = archive(self.root, **kwargs)
        return self.backend.mods.install_bytes(path.read_bytes())

    def test_uploaded_package_refuses_late_staging_junction_and_preserves_external_file(self):
        data=archive(self.root).read_bytes()
        staging=self.backend.mods.root/"staging"
        staging.rmdir()
        outside=self.root/"outside-upload";outside.mkdir()
        sentinel=outside/("upload-"+"a"*32+".heropack")
        sentinel.write_bytes(b"unrelated retained data")
        if os.name=="nt":
            result=subprocess.run(["cmd","/c","mklink","/J",str(staging),str(outside)],capture_output=True)
            self.assertEqual(result.returncode,0,result.stderr)
        else:
            staging.symlink_to(outside,target_is_directory=True)
        try:
            with mock.patch("mod_service.secrets.token_hex",return_value="a"*32):
                with self.assertRaises(GameplayFault) as raised:self.backend.mods.install_bytes(data)
            self.assertEqual(raised.exception.code,"ModUnsafeStorage")
            self.assertEqual(sentinel.read_bytes(),b"unrelated retained data")
            self.assertEqual(list(outside.iterdir()),[sentinel])
        finally:
            if os.name=="nt":staging.rmdir()
            else:staging.unlink()
            staging.mkdir()

    @staticmethod
    def selection(meta, **kwargs):
        return {"packageId": meta["packageId"], "version": meta["version"],
                "contentDigest": meta.get("contentDigest", meta.get("digest")), "enabled": True, **kwargs}

    def activate(self, owner, rows, *, action=None):
        info = self.rpc(owner, "user.mods_info")
        params = {"expectedRevision": info["revision"], "selections": rows}
        plan = self.rpc(owner, "user.mods_plan", params)
        self.assertTrue(plan["valid"], plan)
        result = self.rpc(owner, "user.mods_apply", {**params, "planDigest": plan["planDigest"]}, action=action)
        return result, {**params, "planDigest": plan["planDigest"]}

    def test_two_saves_are_isolated_and_empty_save_has_base_login_config(self):
        self.assertIn("cfg", self.a["mod_config"])
        original = copy.deepcopy(self.backend.config)
        meta = self.install()
        self.activate(self.a, [self.selection(meta)])
        cfg_a = self.backend.mods.config(self.a["uid"])
        cfg_b = self.backend.mods.config(self.b["uid"])
        self.assertTrue(cfg_a["mod_runtime"]["heroes"])
        self.assertEqual(cfg_b["mod_runtime"], {})
        self.assertNotEqual(cfg_a["digest"], cfg_b["digest"])
        self.assertEqual(self.backend.config, original)
        self.assertIsNot(self.backend.players.context_for(self.a["uid"]), self.backend.players)
        self.assertIs(self.backend.players.context_for(self.b["uid"]), self.backend.players)

    def test_apply_retry_is_idempotent_and_revision_bound(self):
        meta = self.install()
        first, payload = self.activate(self.a, [self.selection(meta)], action="apply-once")
        replay = self.rpc(self.a, "user.mods_apply", payload, action="apply-once")
        self.assertEqual(replay["revision"], first["revision"])
        self.assertTrue(replay["replayed"])
        stale = self.rpc(self.a, "user.mods_plan", {"expectedRevision": 0, "selections": []}, expected=1)
        self.assertEqual(stale["error_code"], "ModRevisionConflict")

    def test_mod_instance_sequence_survives_highest_card_removal_and_receipt_retries(self):
        from gameplay_common import grant_reward, MOD_HERO_SEQUENCE
        uid = self.a["uid"]

        def legacy_grant(profile):
            before = set(profile["avatars"])
            grant_reward(profile, {"avatar": {"A_1001_5": 1}}, self.backend.config)
            created = next(iter(set(profile["avatars"]) - before))
            return profile, {"id": created}

        old, _ = self.backend.players.atomic_update(uid, legacy_grant, "old-visible-receipt", {})
        legacy_iid = old["id"]
        self.assertNotIn(MOD_HERO_SEQUENCE, self.backend.players.profile_raw(uid))
        self.rpc(self.a, "user.sell_avatars", {"aids": [legacy_iid]})
        self.assertNotIn(legacy_iid, self.backend.players.profile_raw(uid)["avatars"])

        meta = self.install()
        self.activate(self.a, [self.selection(meta)])
        runtime = self.backend.mods.config(uid)["mod_runtime"]
        aid = next(aid for aid, row in runtime["heroes"].items() if row["kind"] == "new")
        granted = self.rpc(self.a, "user.mods_test_grant", {"aid": aid}, action="sequence-grant-one")
        first_iid = next(iter(granted["new_avatars"]))
        self.assertGreater(int(first_iid.rsplit("|", 1)[1]), int(legacy_iid.rsplit("|", 1)[1]))
        self.rpc(self.a, "user.sell_avatars", {"aids": [first_iid]}, action="sequence-sell-one")
        self.assertNotIn(first_iid, self.backend.players.profile_raw(uid)["avatars"])

        second = self.rpc(self.a, "user.mods_test_grant", {"aid": aid}, action="sequence-grant-two")
        second_iid = next(iter(second["new_avatars"]))
        self.assertGreater(int(second_iid.rsplit("|", 1)[1]), int(first_iid.rsplit("|", 1)[1]))
        before_retry = copy.deepcopy(self.backend.players.profile_raw(uid))
        replay = self.rpc(self.a, "user.mods_test_grant", {"aid": aid}, action="sequence-grant-two")
        self.assertEqual(replay, second)
        self.assertEqual(self.backend.players.profile_raw(uid), before_retry)

        config = self.backend.mods.config(uid)["config"]
        def interrupted(profile):
            grant_reward(profile, {"avatar": {aid: 1}}, config)
            raise GameplayFault("InterruptedForTest", "rollback")
        with self.assertRaises(GameplayFault):
            self.backend.players.atomic_update(uid, interrupted, "sequence-failed", {})
        self.assertEqual(self.backend.players.profile_raw(uid), before_retry)

        # The roster's separate card constructor shares the same counter.
        needed = int(config["cfg"]["system_simple"]["soul_exchange"]["avatar"]["5"])
        def souls(profile):
            profile.setdefault("avatar_soul", {})[aid] = needed
            return profile, {}
        self.backend.players.atomic_update(uid, souls)
        exchanged = self.rpc(self.a, "user.soul_exchange_avatar", {"aid": aid, "num": 1}, action="sequence-soul")
        third_iid = exchanged["new_avatars"][0]["id"]
        self.assertGreater(int(third_iid.rsplit("|", 1)[1]), int(second_iid.rsplit("|", 1)[1]))
        after = self.backend.players.profile_raw(uid)
        self.assertEqual(after[MOD_HERO_SEQUENCE], int(third_iid.rsplit("|", 1)[1]) + 1)
        self.assertNotIn(MOD_HERO_SEQUENCE, self.backend.players.profile_raw(self.b["uid"]))

    def test_plan_is_invalidated_by_profile_change(self):
        meta = self.install()
        params = {"expectedRevision": 0, "selections": [self.selection(meta)]}
        plan = self.rpc(self.a, "user.mods_plan", params)
        self.backend.players.atomic_update(self.a["uid"], lambda p: ({**p, "gold": p["gold"] + 1}, {}))
        result = self.rpc(self.a, "user.mods_apply", {**params, "planDigest": plan["planDigest"]}, expected=1)
        self.assertEqual(result["error_code"], "ModPlanExpired")
        self.assertNotIn("mod_state", self.backend.players.profile_raw(self.a["uid"]))

    def test_pending_fight_blocks_switch_without_losing_intent(self):
        meta = self.install()
        now = self.backend.clock.now()
        self.backend.players.atomic_update(self.a["uid"], lambda p: ({**p, "pending_pve": {"fight": {"expires": now + 100, "settled": False}}}, {}))
        plan = self.rpc(self.a, "user.mods_plan", {"expectedRevision": 0, "selections": [self.selection(meta)]})
        self.assertFalse(plan["valid"])
        self.assertEqual(plan["errors"][0]["code"], "ModPendingOperation")
        self.assertIn("fight", self.backend.players.profile_raw(self.a["uid"])["pending_pve"])

    def test_remove_new_package_freezes_card_and_reinstall_restores_same_instance(self):
        path = archive(self.root)
        meta = self.backend.mods.install_bytes(path.read_bytes())
        self.activate(self.a, [self.selection(meta)])
        runtime = self.backend.mods.config(self.a["uid"])["mod_runtime"]
        aid = next(a for a, h in runtime["heroes"].items() if h["kind"] == "new")
        granted = self.rpc(self.a, "user.mods_test_grant", {"aid": aid}, action="grant-once")
        iid = next(iter(granted["new_avatars"]))
        self.backend.players.atomic_update(self.a["uid"], lambda p: (self._set_level(p, iid, 23), {}))
        self.backend.mods.catalog.uninstall(meta["packageId"], meta["version"], meta.get("digest", meta.get("contentDigest")))
        missing = self.backend.mods.config(self.a["uid"])
        self.assertIn(aid, missing["mod_runtime"]["missingHeroIds"])
        self.assertTrue(missing["cfg"]["avatar"][aid]["modMissing"])
        self.assertEqual(self.backend.players.profile_raw(self.a["uid"])["avatars"][iid]["lv"], 23)
        context = self.backend.players.context_for(self.a["uid"])
        roster = next(h for h in context.gameplay_handlers if h.__class__.__name__ == "GameplayRosterEquipment")
        with self.assertRaises(GameplayFault):
            roster.battle_attributes(context.profile_raw(self.a["uid"]), iid)
        self.backend.mods.install_bytes(path.read_bytes())
        restored = self.backend.mods.config(self.a["uid"])
        self.assertNotIn(aid, restored["mod_runtime"]["missingHeroIds"])
        self.assertEqual(self.backend.players.profile_raw(self.a["uid"])["avatars"][iid]["lv"], 23)
        replay = self.rpc(self.a, "user.mods_test_grant", {"aid": aid}, action="grant-once")
        self.assertEqual(set(replay["new_avatars"]), {iid})

    @staticmethod
    def _set_level(profile, iid, level):
        profile["avatars"][iid]["lv"] = level
        return profile

    def test_patch_keeps_builtin_identity_and_removal_restores_definition(self):
        aid = "A_1001_5"
        original_name = self.backend.config["cfg"]["avatar"][aid]["name"]
        patch = {"id": "rename", "target": "builtin:avatar/" + aid,
                 "expect": {"path": "name", "value": original_name},
                 "operations": [{"op": "set", "path": "name", "value": "Restored Garen"}]}
        meta = self.install(kind="patch", patches=[patch])
        self.activate(self.a, [self.selection(meta)])
        self.assertEqual(self.backend.mods.config(self.a["uid"])["cfg"]["avatar"][aid]["name"], "Restored Garen")
        self.assertEqual(self.backend.mods.config(self.b["uid"])["cfg"]["avatar"][aid]["name"], original_name)
        self.activate(self.a, [])
        self.assertEqual(self.backend.mods.config(self.a["uid"])["cfg"]["avatar"][aid]["name"], original_name)

    def test_stale_client_config_is_rejected_but_manager_remains_accessible(self):
        old_digest = self.a["mod_config"]["digest"]
        meta = self.install()
        self.activate(self.a, [self.selection(meta)])
        error = self.rpc(self.a, "user.init_user", mod_digest=old_digest, expected=1)
        self.assertEqual(error["error_code"], "ModConfigurationChanged")
        self.assertEqual(self.rpc(self.a, "user.mods_info", mod_digest=old_digest)["revision"], 1)

    def test_late_patch_request_is_rejected_after_last_patch_is_disabled(self):
        aid = "A_1001_5"
        patch = {"id": "rename", "target": "builtin:avatar/" + aid,
                 "expect": {"path": "name", "value": self.backend.config["cfg"]["avatar"][aid]["name"]},
                 "operations": [{"op": "set", "path": "name", "value": "Patched"}]}
        meta = self.install(kind="patch", patches=[patch])
        self.activate(self.a, [self.selection(meta)])
        previous = self.backend.mods.config(self.a["uid"])["digest"]
        self.activate(self.a, [self.selection(meta, enabled=False)])
        error = self.rpc(self.a, "user.init_user", mod_digest=previous, expected=1)
        self.assertEqual(error["error_code"], "ModConfigurationChanged")

    def test_missing_shared_slot_equipment_reclaim_preserves_owned_items_and_retries(self):
        meta = self.install()
        self.activate(self.a, [self.selection(meta)])
        aid = next(a for a, h in self.backend.mods.config(self.a["uid"])["mod_runtime"]["heroes"].items() if h["kind"] == "new")
        iid = next(iter(self.rpc(self.a, "user.mods_test_grant", {"aid": aid})["new_avatars"]))
        eid = next(iter(self.backend.config["cfg"]["equip"]))
        owned_id = eid + "|reclaim"

        def equip(profile):
            profile["avatars"][iid]["equips"] = [owned_id]
            profile["my_equips"][owned_id] = {"eid": owned_id, "lv": 17}
            profile["my_equips"]["external|1"] = {"eid": "E_999999|1", "lv": 8}
            profile["team"][0][0] = iid
            profile["team"][1][1] = iid
            profile["as_equips"] = [[owned_id, "external|1"], [owned_id], [], [], [], []]
            return profile, {}

        self.backend.players.atomic_update(self.a["uid"], equip)
        self.backend.players.profile(self.a["uid"])
        before = copy.deepcopy(self.backend.players.profile_raw(self.a["uid"])["my_equips"])
        self.backend.mods.catalog.uninstall(meta["packageId"], meta["version"], meta["digest"])
        first = self.rpc(self.a, "user.mods_reclaim_equipment", {"heroId": iid}, action="reclaim-once")
        self.assertEqual(first["recovered"], [owned_id])
        self.assertEqual(first["affectedSlots"], [0, 1])
        self.assertEqual(first["as_equips"][:2], [[None, "external|1"], [None]])
        self.assertEqual(self.backend.players.profile_raw(self.a["uid"])["my_equips"], before)
        self.assertEqual(self.rpc(self.a, "user.mods_reclaim_equipment", {"heroId": iid}, action="reclaim-once"), first)

    def _copied_backend(self, *, mods=None):
        target = self.root / ("restore-" + uuid.uuid4().hex)
        target.mkdir()
        import sqlite3
        copied = sqlite3.connect(target / "save.sqlite3")
        self.backend.db.backup(copied)
        copied.close()
        other = Backend(target / "save.sqlite3", CONFIG, mods or target / "mods")
        self.addCleanup(other.clock.close)
        self.addCleanup(other.db.close)
        return other

    def test_platform_database_restore_reserves_saved_numbers_before_package_scan(self):
        self.install(name="AAA Unselected")
        path = archive(self.root, name="BBB Selected")
        meta = self.backend.mods.install_bytes(path.read_bytes())
        self.activate(self.a, [self.selection(meta)])
        before = self.backend.mods.config(self.a["uid"])["mod_runtime"]
        aid = next(a for a, h in before["heroes"].items() if h["kind"] == "new")
        self.assertTrue(aid.startswith("A_180001_"), aid)
        other = self._copied_backend()
        self.assertIn(aid, other.mods.config(self.a["uid"])["mod_runtime"]["missingHeroIds"])
        other.mods.install_bytes(path.read_bytes())
        restored = other.mods.config(self.a["uid"])["mod_runtime"]
        self.assertEqual(restored["heroes"][aid]["identity"], before["heroes"][aid]["identity"])
        self.assertNotIn(aid, restored["missingHeroIds"])

    def test_platform_restore_collision_freezes_only_affected_save(self):
        meta = self.install()
        self.activate(self.a, [self.selection(meta)])
        aid = next(iter(self.backend.mods.config(self.a["uid"])["mod_runtime"]["heroes"]))
        destination = self.root / "occupied-mods"
        occupied = ModCatalog(destination, self.backend.config)
        occupied.allocate_hero(str(uuid.uuid4()), "different", "purple", 5)
        other = self._copied_backend(mods=destination)
        config = other.mods.config(self.a["uid"])
        self.assertIn(aid, config["mod_runtime"]["missingHeroIds"])
        self.assertEqual(config["mod_runtime"]["errors"][0]["code"], "ModIdentityMigrationRequired")
        self.assertEqual(other.mods.config(self.b["uid"])["mod_runtime"], {})
        plan = other.mods.plan(self.a["uid"], {"expectedRevision": 1, "selections": [self.selection(meta)]})
        self.assertFalse(plan["valid"])
        self.assertEqual(plan["errors"][0]["code"], "ModIdentityMigrationRequired")

    def test_invalid_restore_state_cannot_mutate_install_registry(self):
        backup = self.rpc(self.a, "user.mods_backup")
        backup["state"]["selections"] = [{"packageId": "invalid"}]
        backup["digest"] = digest({k: v for k, v in backup.items() if k != "digest"})
        original = self.backend.mods.catalog.identity_snapshot()
        error = self.rpc(self.a, "user.mods_restore_plan", {"backup": backup}, expected=1)
        self.assertEqual(error["error_code"], "InvalidModSelection")
        self.assertEqual(self.backend.mods.catalog.identity_snapshot(), original)

    def test_automatic_previous_backup_preserves_later_acquired_hero_when_restored(self):
        meta = self.install()
        self.activate(self.a, [self.selection(meta)])
        aid = next(a for a, h in self.backend.mods.config(self.a["uid"])["mod_runtime"]["heroes"].items() if h["kind"] == "new")
        iid = next(iter(self.rpc(self.a, "user.mods_test_grant", {"aid": aid})["new_avatars"]))
        before = copy.deepcopy(self.backend.players.profile_raw(self.a["uid"])["avatars"][iid])
        backup = self.rpc(self.a, "user.mods_backup", {"previous": True})
        self.assertEqual(backup["state"]["selections"], [])
        self.assertNotIn("previous", backup["state"])
        plan = self.rpc(self.a, "user.mods_restore_plan", {"backup": backup})
        result = self.rpc(self.a, "user.mods_restore", {"backup": backup, "planDigest": plan["planDigest"]}, action="restore-previous")
        self.assertEqual(result["revision"], 2)
        self.assertIn(aid, self.backend.mods.config(self.a["uid"])["mod_runtime"]["missingHeroIds"])
        self.assertEqual(self.backend.players.profile_raw(self.a["uid"])["avatars"][iid], before)
        retry = self.rpc(self.a, "user.mods_restore", {"backup": backup, "planDigest": plan["planDigest"]}, action="restore-previous")
        self.assertTrue(retry["replayed"])

    def test_descriptors_and_saved_false_flags_survive_backend_restart(self):
        meta = self.install()
        self.activate(self.a, [self.selection(meta, channels={"appearance.arena_enemy": False})])
        info = self.rpc(self.a, "user.mods_info")
        self.assertTrue(any(r["key"] == "acquisition.summon.advanced" for r in info["channels"]))
        self.assertFalse(info["selections"][0]["channels"]["appearance.arena_enemy"])
        other = Backend(self.root / "saves/local.sqlite3", CONFIG, self.root / "mods")
        self.addCleanup(other.clock.close)
        self.addCleanup(other.db.close)
        self.assertFalse(other.mods.info(self.a["uid"])["selections"][0]["channels"]["appearance.arena_enemy"])

    def test_rescan_import_errors_and_stale_plan_preserve_progress_and_active_configuration(self):
        installed = self.install(name="Active")
        selected = self.selection(installed)
        self.activate(self.a, [selected])
        aid = next(a for a, row in self.backend.mods.config(self.a["uid"])["mod_runtime"]["heroes"].items()
                   if row["kind"] == "new")
        iid = next(iter(self.rpc(self.a, "user.mods_test_grant", {"aid": aid})["new_avatars"]))

        def progress(profile):
            profile["avatars"][iid].update(lv=23, slv=7, exp=431, phase=1,
                                            hp=12, ap=23, de_ph=34, de_ma=45)
            return profile, {}
        self.backend.players.atomic_update(self.a["uid"], progress)
        self.backend.players.profile(self.a["uid"])
        original = copy.deepcopy(self.backend.players.profile_raw(self.a["uid"]))
        old = self.rpc(self.a, "user.mods_info")
        parameters = {"expectedRevision": old["revision"],
                      "selections": [self.selection(installed, channels={"appearance.arena_enemy": False})]}
        plan = self.rpc(self.a, "user.mods_plan", parameters)
        self.assertTrue(plan["valid"], plan)

        valid = archive(self.root, name="Available only")
        inbox = self.root / "mods/inbox"
        (inbox / "valid.heropack").write_bytes(valid.read_bytes())
        (inbox / "broken.heropack").write_bytes(b"invalid ZIP archive")
        inspected = self.rpc(self.a, "user.mods_info", {"rescan": True})
        self.assertEqual(len(inspected["importResults"]), 2)
        self.assertEqual(sum(row["ok"] is True for row in inspected["importResults"]), 1)
        failure = next(row for row in inspected["importResults"] if not row["ok"])
        self.assertEqual(failure["source"], "broken.heropack")
        self.assertIn("code", failure["error"])
        self.assertEqual(inspected["revision"], old["revision"])
        self.assertEqual(inspected["digest"], old["digest"])
        self.assertEqual(inspected["selections"], old["selections"])
        self.assertTrue(any(row.get("name") == "Available only" for row in inspected["packages"]))
        self.assertTrue(any(row.get("status") == "corrupt" and row.get("source") == "broken.heropack"
                            for row in self.rpc(self.a, "user.mods_info")["packages"]))
        rejected = self.rpc(self.a, "user.mods_apply", {**parameters, "planDigest": plan["planDigest"]}, expected=1)
        self.assertEqual(rejected["error_code"], "ModPlanExpired")
        self.assertEqual(self.backend.players.profile_raw(self.a["uid"]), original)

    def test_uninstall_digest_alias_cannot_bypass_other_save_pending_battle(self):
        installed = self.install()
        self.activate(self.a, [self.selection(installed)])
        now = self.backend.clock.now()
        self.backend.players.atomic_update(self.a["uid"], lambda profile: (
            {**profile, "pending_pve": {"fight": {"expires": now + 100, "settled": False}}}, {}))
        original = copy.deepcopy(self.backend.players.profile_raw(self.a["uid"]))
        valid = {"packageId": installed["packageId"], "version": installed["version"],
                 "digest": installed.get("digest", installed.get("contentDigest"))}
        forged = self.rpc(self.b, "user.mods_uninstall_plan", {**valid, "digest": "0" * 64}, expected=1)
        self.assertEqual(forged["error_code"], "ModStalePlan")
        conflicting = self.rpc(self.b, "user.mods_uninstall_plan", {**valid, "contentDigest": "0" * 64}, expected=1)
        self.assertEqual(conflicting["error_code"], "InvalidModSelection")
        planned = self.rpc(self.b, "user.mods_uninstall_plan", valid)
        self.assertFalse(planned["valid"])
        self.assertEqual(planned["affectedSaves"], 1)
        self.assertEqual(planned["errors"][0]["code"], "ModPendingOperation")
        denied = self.rpc(self.b, "user.mods_uninstall", {**valid, "planDigest": planned["planDigest"]}, expected=1)
        self.assertEqual(denied["error_code"], "ModPendingOperation")
        self.backend.mods.catalog.get(valid["packageId"], valid["version"], valid["digest"])
        self.assertEqual(self.backend.players.profile_raw(self.a["uid"]), original)

    def test_registry_corruption_after_activation_preserves_login_manager_and_hero_progress(self):
        installed = self.install()
        self.activate(self.a, [self.selection(installed)])
        aid = next(a for a, row in self.backend.mods.config(self.a["uid"])["mod_runtime"]["heroes"].items()
                   if row["kind"] == "new")
        iid = next(iter(self.rpc(self.a, "user.mods_test_grant", {"aid": aid})["new_avatars"]))

        def progress(profile):
            profile["avatars"][iid].update(lv=23, slv=7, exp=431, phase=1,
                                            hp=12, ap=23, de_ph=34, de_ma=45)
            return profile, {}
        self.backend.players.atomic_update(self.a["uid"], progress)
        self.backend.players.profile(self.a["uid"])
        original = copy.deepcopy(self.backend.players.profile_raw(self.a["uid"]))
        # Prime the active context before changing the on-disk registry.
        self.assertTrue(self.rpc(self.a, "user.mods_info")["packages"])
        damaged = b'{"schema":"lal-mod-registry-v1","identities": invalid'
        registry = self.backend.mods.catalog.registry_path
        registry.write_bytes(damaged)

        login = self.backend.call({"method": "user.login", "params": {"pf": "local",
            "session_key": "A", "sessionid": "test-password", "actionID": "login-after-damage"}})
        self.assertEqual(login["return_code"], 0, login)
        self.a = login["data"]
        configuration = self.a["mod_config"]
        self.assertIn(aid, configuration["mod_runtime"]["missingHeroIds"])
        self.assertTrue(configuration["cfg"]["avatar"][aid]["modMissing"])
        manager = self.rpc(self.a, "user.mods_info")
        self.assertTrue(any(row.get("status") == "corrupt" and row.get("error", {}).get("code") == "ModRegistryCorrupt"
                            for row in manager["packages"]))
        self.assertEqual(self.backend.players.profile_raw(self.a["uid"])["avatars"][iid], original["avatars"][iid])
        for currency in ("gold", "coin", "score", "medal", "mark"):
            self.assertEqual(self.backend.players.profile_raw(self.a["uid"])[currency], original[currency])

        other = self.backend.call({"method": "user.login", "params": {"pf": "local",
            "session_key": "B", "sessionid": "test-password", "actionID": "base-login-after-damage"}})
        self.assertEqual(other["return_code"], 0, other)
        self.assertEqual(other["data"]["mod_config"]["mod_runtime"], {})
        replacement = archive(self.root, name="Must not allocate")
        with self.assertRaises(GameplayFault) as rejected:
            self.backend.mods.install_bytes(replacement.read_bytes())
        self.assertEqual(rejected.exception.code, "ModRegistryCorrupt")
        self.assertEqual(registry.read_bytes(), damaged)

    def test_http_import_requires_authentication_and_assets_do_not_traverse(self):
        service = make_server("127.0.0.1", 0, self.backend)
        thread = threading.Thread(target=service.serve_forever, daemon=True)
        thread.start()
        self.addCleanup(service.server_close)
        self.addCleanup(service.shutdown)
        base = "http://127.0.0.1:" + str(service.server_address[1])
        data = archive(self.root).read_bytes()
        request = urllib.request.Request(base + "/mods/install", data=data, headers={"Content-Type": "application/octet-stream"})
        with self.assertRaises(urllib.error.HTTPError) as error:
            urllib.request.urlopen(request)
        self.assertEqual(error.exception.code, 401)
        request.add_header("X-Lal-Uid", self.a["uid"])
        request.add_header("X-Lal-Session", self.a["sessionid"])
        with urllib.request.urlopen(request) as response:
            self.assertTrue(json.load(response)["ok"])
        invalid = urllib.request.Request(base + "/mods/install", data=b"broken archive", headers={
            "Content-Type": "application/octet-stream", "X-Lal-Uid": self.a["uid"], "X-Lal-Session": self.a["sessionid"]})
        with urllib.request.urlopen(invalid) as response:
            failure = json.load(response)
            self.assertEqual(response.status, 200)
            self.assertFalse(failure["ok"])
            self.assertIn("code", failure["error"])
        with self.assertRaises(urllib.error.HTTPError) as error:
            urllib.request.urlopen(base + "/mods/assets/" + "0" * 64 + "/%2e%2e/registry.json")
        self.assertEqual(error.exception.code, 404)


if __name__ == "__main__":
    unittest.main()
