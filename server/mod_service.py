"""Authenticated, revisioned per-save Mod activation and immutable store contexts."""
from __future__ import annotations

import copy
import hashlib
import json
import mimetypes
import re
import secrets
from collections import OrderedDict
from pathlib import Path

from player_store import GameplayFault, PlayerStore, native_dates
from mod_packages import ModCatalog, ModError


def canonical(value):
    return json.dumps(PlayerStore._profile_json(value), ensure_ascii=False,
                      sort_keys=True, separators=(",", ":"), allow_nan=False)


def digest(value):
    return hashlib.sha256(canonical(value).encode("utf-8")).hexdigest()


def _mod_fault(error):
    message = str(getattr(error, "message", str(error)))
    path = getattr(error, "path", None)
    return GameplayFault(getattr(error, "code", "InvalidModPackage"),
                         message + (" (" + str(path) + ")" if path else ""))


class ModService:
    METHODS = frozenset({
        "user.mods_info", "user.mods_plan", "user.mods_apply", "user.mods_config",
        "user.mods_reclaim_equipment", "user.mods_uninstall_plan", "user.mods_uninstall",
        "user.mods_test_grant", "user.mods_backup", "user.mods_restore_plan", "user.mods_restore",
    })
    MAX_UPLOAD_BYTES = 64 * 1024 * 1024
    MAX_CONTEXTS = 4

    def __init__(self, store, base_document, root, roster_side=None):
        self.store = store
        self.base = copy.deepcopy(base_document or {})
        self.root = Path(root)
        self.catalog = ModCatalog(self.root, self.base)
        if roster_side is None:
            side_path = Path(__file__).resolve().parents[1] / "config/reconstruction/roster-config.json"
            roster_side = json.loads(side_path.read_text("utf-8-sig")) if side_path.is_file() else {}
        self.roster = copy.deepcopy(roster_side)
        self._contexts = OrderedDict()
        self._identity_errors = {}
        self._identity_cache = {}
        self._inbox_errors = []
        # A platform backup can restore SQLite before restoring the shared Mod
        # directory. Reserve saved identities before any scan allocates new IDs.
        for uid, raw in store.db.execute("SELECT uid,profile FROM players ORDER BY uid"):
            state = json.loads(raw).get("mod_state", {})
            if isinstance(state, dict):
                self._restore_saved_bindings(str(uid), state)
        self._base_digest = digest(self.base)
        from gameplay_common import game_day
        self._calendar_year = int(game_day(store.clock.now())[:4])
        store.mod_service = self

    def _refresh_base_calendar(self):
        """Track the only runtime base-table update without hashing per RPC.

        The gateway and sign-in handler project this table for the game year.
        Mod compilation must use that same projection, including after a cached
        or remembered save is selected without a prior sys.get_config call.
        """
        from gameplay_common import game_day
        year = int(game_day(self.store.clock.now())[:4])
        if year == self._calendar_year or not isinstance(self.store.config, dict):
            return
        from check_in_rewards import apply_check_in_rewards
        with self.store.lock:
            if year == self._calendar_year:
                return
            apply_check_in_rewards(self.store.config, year)
            self.base.setdefault("cfg", {})["check_in"] = copy.deepcopy(self.store.config["cfg"]["check_in"])
            self._base_digest = digest(self.base)
            self._calendar_year = year
            self._contexts.clear()

    def _restore_saved_bindings(self, uid, state):
        snapshot = state.get("identityMap")
        if snapshot is None:
            return
        def stamp():
            try:
                stat = self.catalog.registry_path.stat()
                return stat.st_mtime_ns, stat.st_size
            except OSError:
                return None
        marker = digest(snapshot), stamp()
        if self._identity_cache.get(str(uid)) == marker:
            return
        try:
            if not isinstance(snapshot, dict):
                raise ModError("InvalidModBackup", "身份映射必须是对象。", "identityMap")
            self.catalog.restore_identities(snapshot)
            self._identity_errors.pop(str(uid), None)
        except ModError as error:
            self._identity_errors[str(uid)] = {
                "code": "ModIdentityMigrationRequired", "path": getattr(error, "path", ""),
                "message": "存档身份映射与当前安装注册表不兼容，已冻结此存档的 Mod。请恢复匹配的注册表或先完成身份迁移：" + str(error),
            }
        self._identity_cache[str(uid)] = digest(snapshot), stamp()

    def state(self, uid):
        profile = self.store.profile_raw(uid)
        state = profile.get("mod_state", {})
        if not isinstance(state, dict):
            raise GameplayFault("InvalidModState", "Mod 存档元数据损坏，请先从备份恢复。")
        revision = state.get("revision", 0)
        if type(revision) is not int or revision < 0:
            raise GameplayFault("InvalidModState", "Mod 配置修订号无效。")
        return profile, {**state, "revision": revision,
                         "selections": state.get("selections", []),
                         "knownHeroes": state.get("knownHeroes", {})}

    @staticmethod
    def normalize_selections(value):
        if not isinstance(value, list) or len(value) > 256:
            raise GameplayFault("InvalidModSelection", "英雄包列表必须是最多 256 项的数组。")
        result, seen = [], set()
        for row in value:
            if not isinstance(row, dict):
                raise GameplayFault("InvalidModSelection", "英雄包选择项必须是对象。")
            allowed = {"packageId", "version", "digest", "contentDigest", "enabled",
                       "channels", "heroes", "patchScopes"}
            if set(row) - allowed:
                raise GameplayFault("InvalidModSelection", "英雄包选择包含未知字段。")
            package_id, version = row.get("packageId"), row.get("version")
            if not isinstance(package_id, str) or not isinstance(version, str) or not version:
                raise GameplayFault("InvalidModSelection", "每项都需要包 ID 和固定版本。")
            if package_id in seen:
                raise GameplayFault("ModVersionConflict", "同一存档不能同时启用同一包的多个版本。")
            seen.add(package_id)
            enabled = row.get("enabled", True)
            if type(enabled) is not bool:
                raise GameplayFault("InvalidModSelection", "启用状态必须是布尔值。")
            content_digest = row.get("digest", row.get("contentDigest"))
            if (not isinstance(content_digest, str) or len(content_digest) != 64
                    or any(c not in "0123456789abcdef" for c in content_digest)):
                raise GameplayFault("InvalidModSelection", "需要固定包内容的 SHA-256 摘要。")
            if "digest" in row and "contentDigest" in row and row["digest"] != row["contentDigest"]:
                raise GameplayFault("InvalidModSelection", "包内容摘要不一致。")
            normalized = {"packageId": package_id, "version": version, "digest": content_digest,
                          "enabled": enabled}
            for field in ("channels", "patchScopes"):
                settings = row.get(field, {})
                if not isinstance(settings, dict) or any(not isinstance(k, str) or type(v) is not bool
                                                         for k, v in settings.items()):
                    raise GameplayFault("InvalidModSelection", field + " 必须是布尔开关映射。")
                normalized[field] = copy.deepcopy(settings)
            heroes = row.get("heroes", {})
            if not isinstance(heroes, dict) or len(heroes) > 2048:
                raise GameplayFault("InvalidModSelection", "英雄覆盖设置无效。")
            normalized["heroes"] = {}
            for identity, overrides in heroes.items():
                if (not isinstance(identity, str) or not isinstance(overrides, dict)
                        or set(overrides) - {"channels", "patchScopes"}):
                    raise GameplayFault("InvalidModSelection", "英雄覆盖设置包含未知字段。")
                normalized["heroes"][identity] = {}
                for field in ("channels", "patchScopes"):
                    settings = overrides.get(field, {})
                    if not isinstance(settings, dict) or any(not isinstance(k, str) or type(v) is not bool
                                                             for k, v in settings.items()):
                        raise GameplayFault("InvalidModSelection", "英雄开关必须是布尔映射。")
                    normalized["heroes"][identity][field] = copy.deepcopy(settings)
            result.append(normalized)
        return sorted(result, key=lambda row: row["packageId"])

    @staticmethod
    def wire_selections(rows):
        return [{**copy.deepcopy(row), "contentDigest": row["digest"]} for row in rows]

    def _scan(self):
        try:
            return self.catalog.scan()
        except ModError as error:
            raise _mod_fault(error) from error

    def _fingerprint(self, rows=None):
        rows = self._scan() if rows is None else rows
        fields = ("packageId", "version", "digest", "contentDigest", "status", "reason")
        return digest(sorted(({k: row.get(k) for k in fields} for row in rows), key=canonical))

    def _compile(self, state, selections=None, *, strict=False):
        self._refresh_base_calendar()
        selected = state["selections"] if selections is None else selections
        settings = {"packages": self.normalize_selections(selected),
                    "knownHeroes": copy.deepcopy(state.get("knownHeroes", {}))}
        try:
            result = self.catalog.compile(self.base, settings, self.roster, allow_missing=not strict)
        except ModError as error:
            raise _mod_fault(error) from error
        result.document["mod_roster"] = result.roster
        return result

    def context(self, uid):
        """Get an owner-bound store without temporarily replacing shared state."""
        uid = str(uid)
        with self.store.lock:
            self._refresh_base_calendar()
            _, state = self.state(uid)
            # A save that has applied Mod settings still needs an owner-bound
            # digest after its final patch is removed. Returning the legacy
            # base store here would accept requests from its stale client.
            if not state["selections"] and not state.get("knownHeroes") and state["revision"] == 0:
                return self.store
            self._restore_saved_bindings(uid, state)
            fingerprint = self._fingerprint()
            error = self._identity_errors.get(uid)
            key = digest({"base": self._base_digest, "catalog": fingerprint, "state": state, "identityError": error})
            previous = self._contexts.get(uid)
            if previous is not None and previous[0] == key:
                self._contexts.move_to_end(uid)
                return previous[1]
            selected = [{**row, "enabled": False} for row in state["selections"]] if error else None
            result = self._compile(state, selected)
            if error:
                result.runtime.setdefault("errors", []).append(copy.deepcopy(error))
                result.document.setdefault("cfg", {})["mod_runtime"] = result.runtime
            context = copy.copy(self.store)
            context._mod_uid = uid
            context.config = result.document
            context.mod_resolved = result
            context.configure_handlers(result.document)
            self._contexts[uid] = (key, context)
            self._contexts.move_to_end(uid)
            while len(self._contexts) > self.MAX_CONTEXTS:
                self._contexts.popitem(last=False)
            return context

    def config(self, uid):
        _, state = self.state(uid)
        context = self.context(uid)
        document = copy.deepcopy(context.config or self.base)
        document.pop("mod_roster", None)
        runtime = document.get("cfg", {}).get("mod_runtime", {})
        value = getattr(context, "mod_resolved", None)
        effective_digest = value.digest if value is not None else self._base_digest
        return {"uid": str(uid), "revision": state["revision"], "digest": effective_digest,
                "cfg": document.get("cfg", {}), "config": document, "mod_runtime": runtime,
                "assets": runtime.get("assets", [])}

    @staticmethod
    def require_client(compiled, capabilities=None):
        supported=set(capabilities) if isinstance(capabilities,list) and all(isinstance(v,str) for v in capabilities) else set()
        required=set(getattr(compiled,'runtime',{}).get('requiredClientCapabilities',[]))
        if required-supported:
            raise GameplayFault('ModClientIncompatible','此存档启用了需要新版客户端的 Mod 内容，请更新游戏客户端后进入；如需继续使用旧客户端，请先通过新版客户端停用相关包。')

    def check_request(self, uid, request, context):
        expected = getattr(context, "mod_resolved", None)
        self.require_client(expected,request.get('client_capabilities'))
        if expected is not None and request.get("mod_digest") != expected.digest:
            raise GameplayFault("ModConfigurationChanged", "当前存档的 Mod 内容已变化，请重新进入游戏完成配置同步。")

    @staticmethod
    def _descriptors():
        try:
            from mod_policy import channel_descriptors, patch_scope_descriptors
            return channel_descriptors(), patch_scope_descriptors()
        except ImportError:
            return [], []

    def info(self, uid, *, rescan=False):
        imported = self.catalog.import_inbox() if rescan else []
        if rescan:
            self._inbox_errors = [row for row in imported if not row.get("ok")]
        profile, state = self.state(uid)
        packages = self._scan()
        packages.extend(copy.deepcopy(self._inbox_errors))
        config = self.config(uid)
        runtime = config["mod_runtime"]
        by_package = {}
        for aid, hero in runtime.get("heroes", {}).items():
            by_package.setdefault(hero.get("packageId"), []).append({**copy.deepcopy(hero), "aid": aid})
        for package in packages:
            package.setdefault("contentDigest", package.get("digest"))
            active = by_package.get(package.get("packageId"), [])
            active_by_identity = {row.get("identity"): row for row in active}
            authored = package.get("heroes", [])
            rows = []
            for hero in authored:
                identity = hero.get("identity")
                if identity is None and hero.get("id") and hero.get("variant"):
                    identity = "mod:" + str(package.get("packageId")) + "/hero/" + hero["id"] + "/" + hero["variant"]
                combined = {**hero, **active_by_identity.get(identity, {}), "identity": identity}
                for field in ("defaultChannels", "defaultPatchScopes"):
                    if field in hero:
                        combined[field] = copy.deepcopy(hero[field])
                rows.append(combined)
            known = {row.get("identity") for row in rows}
            rows.extend(row for row in active if row.get("identity") not in known)
            package["heroes"] = rows
        channels, scopes = self._descriptors()
        present = {(p.get("packageId"), p.get("version"), p.get("contentDigest")) for p in packages}
        for row in state["selections"]:
            if (row["packageId"], row["version"], row.get("digest")) not in present:
                packages.append({"packageId": row["packageId"], "version": row["version"],
                                 "contentDigest": row.get("digest"), "name": row["packageId"],
                                 "kind": "unknown", "status": "missing", "reason": "包文件缺失或已卸载",
                                 "heroes": by_package.get(row["packageId"], [])})
        return {"revision": state["revision"], "digest": config["digest"], "saveName": profile.get("name", str(uid)),
                "uid": str(uid), "selections": self.wire_selections(state["selections"]),
                "packages": packages, "channels": channels, "patchScopes": scopes,
                "missing": runtime.get("missingHeroIds", []), "errors": runtime.get("errors", []),
                "importResults": imported}

    def _pending(self, profile):
        now = int(self.store.clock.now())
        pending = []
        for key, row in profile.get("pending_pve", {}).items():
            if isinstance(row, dict) and not row.get("settled") and int(row.get("expires", now + 1)) > now:
                pending.append("战斗 " + str(key))
        for kind, bucket in profile.get("pending_battles", {}).items():
            if not isinstance(bucket, dict):
                continue
            for key, row in bucket.items():
                if isinstance(row, dict) and int(row.get("expires", now + 1)) > now:
                    pending.append("战斗 " + str(kind) + "/" + str(key))
        attrs = profile.get("attrs", {})
        for field in ("avatar_culture", "avatar_talent", "equip_wash"):
            if attrs.get(field):
                pending.append("待确认操作 " + field)
        for field in ("pending_limit_break", "pending_cultivation", "pending_talent"):
            if profile.get(field):
                pending.append("待确认操作 " + field)
        exploration = profile.get("exploration", {})
        if isinstance(exploration, dict) and exploration.get("current_stage_finish") == 1:
            pending.append("待领取探险战斗奖励")
        return pending

    @staticmethod
    def _error_row(error):
        return {"code": getattr(error, "code", "InvalidModPlan"),
                "message": getattr(error, "message", str(error)), "path": getattr(error, "path", "")}

    def _owned_compatible(self, profile, compiled):
        cfg = compiled.document.get("cfg", {})
        runtime = cfg.get("mod_runtime", {})
        for iid, hero in profile.get("avatars", {}).items():
            aid = str(hero.get("aid", iid)).split("|", 1)[0]
            meta = runtime.get("heroes", {}).get(aid, {})
            if meta.get("kind") != "new" or not meta.get("available", True):
                continue
            definition = cfg.get("avatar", {}).get(aid, {})
            tl = definition.get("tl", [])
            cap = int(tl[4]) if len(tl) > 4 else 1
            if hero.get("limit_break"):
                cap = max(cap, 125)
            if int(hero.get("lv", 1)) > cap:
                raise GameplayFault("ModMigrationRequired", "更新会使已拥有英雄超过等级上限，需要明确的存档迁移：" + iid)

    def _seed_instance_sequence(self, uid, profile, document):
        from gameplay_common import MOD_HERO_SEQUENCE, preserve_mod_hero_sequence
        from mod_policy import runtime
        if MOD_HERO_SEQUENCE in profile or not runtime(document):
            return
        # Adopt only this save's existing references, streaming its receipts
        # rather than loading all players or whole decoded response histories.
        minimum_next = 0
        pattern = re.compile(r'"A_[0-9]+_[0-9]+\|([0-9]+)"')
        for (receipt,) in self.store.db.execute("SELECT result FROM operation_ledger WHERE uid=?", (str(uid),)):
            for match in pattern.finditer(receipt):
                minimum_next = max(minimum_next, int(match.group(1)) + 1)
        preserve_mod_hero_sequence(profile, document, minimum_next=minimum_next)

    def plan(self, uid, params):
        profile, state = self.state(uid)
        if type(params.get("expectedRevision")) is not int or params["expectedRevision"] != state["revision"]:
            raise GameplayFault("ModRevisionConflict", "Mod 设置已变化，请重新打开管理页。")
        selections = self.normalize_selections(params.get("selections"))
        errors = []
        try:
            self._restore_saved_bindings(str(uid), state)
            if str(uid) in self._identity_errors and any(row["enabled"] for row in selections):
                error = self._identity_errors[str(uid)]
                raise GameplayFault(error["code"], error["message"])
            compiled = self._compile(state, selections, strict=True)
            self.require_client(compiled,params.get('_clientCapabilities'))
            self._owned_compatible(profile, compiled)
        except GameplayFault as error:
            compiled = None
            errors.append(self._error_row(error))
        pending = self._pending(profile)
        if pending and canonical(selections) != canonical(state["selections"]):
            errors.append({"code": "ModPendingOperation", "message": "请先完成或取消未结算操作：" + "、".join(pending[:8]), "path": ""})
        proposed_digest = compiled.digest if compiled is not None else None
        token = digest({"uid": str(uid), "revision": state["revision"],
                        "profileRevision": self.store.state_revision(uid), "selections": selections,
                        "catalog": self._fingerprint(), "effective": proposed_digest})
        preview = getattr(compiled, "preview", []) if compiled is not None else []
        changes = []
        if isinstance(preview, dict):
            for kind in ("added", "patches", "missing"):
                for row in preview.get(kind, []):
                    item = row if isinstance(row, dict) else {"target": str(row)}
                    changes.append({"type": kind, **item,
                                    "message": str(item.get("message", item.get("target", item.get("name", item.get("identity", canonical(item))))))})
        elif isinstance(preview, list):
            changes = preview
        warnings = getattr(compiled, "warnings", []) if compiled is not None else []
        return {"revision": state["revision"], "planDigest": token, "valid": not errors,
                "errors": errors, "warnings": warnings, "changes": changes, "details": preview,
                "selections": self.wire_selections(selections), "digest": proposed_digest}

    def apply(self, uid, params):
        selections = self.normalize_selections(params.get("selections"))
        request_id = params.get("requestId", params.get("actionID"))
        if not isinstance(request_id, str) or not 1 <= len(request_id) <= 180:
            raise GameplayFault("InvalidRequestKey", "需要有效的 Mod 设置请求编号。")
        payload = {"expectedRevision": params.get("expectedRevision"), "selections": selections,
                   "planDigest": params.get("planDigest")}

        def mutate(profile):
            state = profile.get("mod_state", {})
            revision = state.get("revision", 0)
            # Plan checks are deliberately inside the same SQLite transaction.
            check = self.plan(uid, {"expectedRevision": payload["expectedRevision"], "selections": selections,'_clientCapabilities':params.get('_clientCapabilities')})
            if check["planDigest"] != payload["planDigest"]:
                raise GameplayFault("ModPlanExpired", "预览后存档或包文件已变化，请重新预览。")
            if not check["valid"]:
                reason = check["errors"][0]
                raise GameplayFault(reason["code"], reason["message"])
            old = {**state, "revision": revision, "selections": state.get("selections", []),
                   "knownHeroes": state.get("knownHeroes", {})}
            compiled = self._compile(old, selections, strict=True)
            self._seed_instance_sequence(uid, profile, compiled.document)
            known = copy.deepcopy(old["knownHeroes"])
            for aid, row in compiled.runtime.get("heroes", {}).items():
                if row.get("kind") == "new" and row.get("available", True):
                    known[aid] = copy.deepcopy(row)
            profile["mod_state"] = {"schema": "lal-mod-save-v1", "revision": revision + 1,
                                     "selections": selections, "knownHeroes": known,
                                     "digest": compiled.digest,
                                     "previous": self._backup_value(old, old.get("identityMap", self.catalog.identity_snapshot())),
                                     "identityMap": copy.deepcopy(old.get("identityMap")) if str(uid) in self._identity_errors else self.catalog.identity_snapshot()}
            result = {"revision": revision + 1, "digest": compiled.digest, "reloginRequired": True}
            return profile, result

        result, replayed = self.store.atomic_update(uid, mutate, "user.mods_apply:" + request_id, payload)
        self._contexts.pop(str(uid), None)
        return {**result, "replayed": replayed}

    def reclaim_equipment(self, uid, params):
        iid = params.get("heroId", params.get("avatarId", params.get("aid")))
        if not isinstance(iid, str) or len(iid) > 240:
            raise GameplayFault("InvalidParameter", "需要有效英雄实例编号。")
        request_id = self._request_key(params)

        def mutate(profile):
            context = self.context(uid)
            runtime = context.config.get("cfg", {}).get("mod_runtime", {})
            hero = profile.get("avatars", {}).get(iid)
            if not isinstance(hero, dict):
                raise GameplayFault("UnknownHero", "找不到英雄实例。")
            aid = str(hero.get("aid", iid)).split("|", 1)[0]
            if aid not in runtime.get("missingHeroIds", []):
                raise GameplayFault("ModHeroNotMissing", "此操作只用于取回缺失英雄的正常装备。")
            assigned = hero.get("equips", [])
            if not isinstance(assigned, list):
                raise GameplayFault("InvalidEquipment", "英雄装备记录损坏。")
            equipment = profile.get("my_equips", {})
            definitions = self.base.get("cfg", {}).get("equip", {})
            recovered = []

            def recoverable(eid):
                if not eid:
                    return False
                item = equipment.get(eid)
                if not isinstance(item, dict):
                    raise GameplayFault("InvalidEquipment", "装备归属记录缺失，保留原记录等待修复。")
                definition_id = str(item.get("eid", eid)).split("|", 1)[0]
                if definition_id not in definitions:
                    return False
                if eid not in recovered:
                    recovered.append(eid)
                return True

            hero["equips"] = [eid for eid in assigned if not recoverable(eid)]
            groups = profile.get("as_equips", [])
            if not isinstance(groups, list):
                raise GameplayFault("InvalidEquipment", "阵容装备记录损坏。")
            slots = sorted({index for team in profile.get("team", []) if isinstance(team, list)
                            for index, member in enumerate(team) if member == iid})
            affected = []
            for slot in slots:
                if slot >= len(groups):
                    continue
                group = groups[slot]
                if not isinstance(group, list):
                    raise GameplayFault("InvalidEquipment", "阵容位置装备记录损坏。")
                cleared = [None if recoverable(eid) else eid for eid in group]
                if cleared != group:
                    affected.append(slot)
                    groups[slot] = cleared
            # Owned equipment already occupies the inventory. Detaching creates
            # no item, so neither a full bag nor a retried request can mint gear.
            return profile, {"heroId": iid, "recovered": recovered, "remaining": hero["equips"],
                             "affectedSlots": affected, "as_equips": copy.deepcopy(groups),
                             "message": "位置装备在各套阵容间共享，已解除所列位置的正常装备归属。" if affected else "已取回正常装备。"}

        return self.store.atomic_update(uid, mutate, "user.mods_reclaim_equipment:" + request_id, {"heroId": iid})[0]

    @staticmethod
    def _request_key(params):
        value = params.get("requestId", params.get("actionID"))
        if not isinstance(value, str) or not 1 <= len(value) <= 180:
            raise GameplayFault("InvalidRequestKey", "需要有效的操作请求编号。")
        return value

    def test_grant(self, uid, params):
        aid, count = params.get("aid"), params.get("count", 1)
        request_id = self._request_key(params)
        if not isinstance(aid, str) or len(aid) > 240:
            raise GameplayFault("InvalidParameter", "需要有效英雄编号。")
        if type(count) is not int or not 1 <= count <= 10:
            raise GameplayFault("InvalidParameter", "单次测试发放数量必须为 1 至 10。")

        def mutate(profile):
            context = self.context(uid)
            self._seed_instance_sequence(uid, profile, context.config)
            runtime = context.config.get("cfg", {}).get("mod_runtime", {})
            row = runtime.get("heroes", {}).get(aid, {})
            if row.get("kind") != "new" or not row.get("available", True):
                raise GameplayFault("UnknownHero", "测试发放只支持当前存档已启用的新增英雄。")
            from gameplay_common import grant_reward
            before = set(profile.get("avatars", {}))
            grant_reward(profile, {"heroes": [{"aid": aid, "num": count}]}, context.config)
            added = {key: value for key, value in profile["avatars"].items() if key not in before}
            return profile, {"new_avatars": added}

        return self.store.atomic_update(uid, mutate, "user.mods_test_grant:" + request_id, {"aid": aid, "count": count})[0]

    @staticmethod
    def _uninstall_reference(params):
        package_id, version = params.get("packageId"), params.get("version")
        content_digest = params.get("contentDigest", params.get("digest"))
        if not all(isinstance(x, str) and x for x in (package_id, version, content_digest)):
            raise GameplayFault("InvalidModSelection", "卸载需要包 ID、固定版本和内容摘要。")
        if (len(content_digest) != 64 or any(c not in "0123456789abcdef" for c in content_digest)
                or ("digest" in params and "contentDigest" in params and params["digest"] != params["contentDigest"])):
            raise GameplayFault("InvalidModSelection", "卸载的包内容摘要无效或不一致。")
        return package_id, version, content_digest

    def uninstall_plan(self, uid, params):
        package_id, version, content_digest = self._uninstall_reference(params)
        catalog_rows = self._scan()
        if not any(row.get("packageId") == package_id and row.get("version") == version
                   and row.get("contentDigest", row.get("digest")) == content_digest for row in catalog_rows):
            raise GameplayFault("ModStalePlan", "安装包的版本或内容已变化，请重新检查目录。")
        affected, errors, revisions = [], [], []
        for owner, raw in self.store.db.execute("SELECT uid,profile FROM players ORDER BY uid"):
            profile = json.loads(raw)
            rows = profile.get("mod_state", {}).get("selections", [])
            if any(row.get("enabled", True) and row.get("packageId") == package_id
                   and row.get("version") == version and row.get("digest", row.get("contentDigest")) == content_digest for row in rows):
                affected.append(owner)
                revisions.append((owner, self.store.state_revision(owner)))
                if self._pending(profile):
                    errors.append({"code": "ModPendingOperation", "message": "受影响存档有未结算操作，请先完成。", "path": ""})
        token = digest({"uid": str(uid), "packageId": package_id, "version": version,
                        "digest": content_digest, "owners": revisions, "catalog": self._fingerprint()})
        _, state = self.state(uid)
        return {"revision": state["revision"], "planDigest": token, "affectedSaves": len(affected),
                "valid": not errors, "errors": errors,
                "changes": ["卸载后新增英雄显示缺失，补丁目标恢复其余有效定义；存档数据保留。"]}

    def uninstall(self, uid, params):
        request_id = self._request_key(params)
        package_id, version, content_digest = self._uninstall_reference(params)
        payload = {"packageId": package_id, "version": version,
                   "contentDigest": content_digest, "planDigest": params.get("planDigest")}

        def mutate(profile):
            check = self.uninstall_plan(uid, params)
            if check["planDigest"] != params.get("planDigest"):
                raise GameplayFault("ModPlanExpired", "卸载预览已变化，请重新预览。")
            if not check["valid"]:
                raise GameplayFault(check["errors"][0]["code"], check["errors"][0]["message"])
            try:
                result = self.catalog.uninstall(package_id, version, content_digest)
            except ModError as error:
                raise _mod_fault(error) from error
            return profile, {"ok": True, "package": result, "affectedSaves": check["affectedSaves"]}

        result, replayed = self.store.atomic_update(uid, mutate, "user.mods_uninstall:" + request_id, payload)
        self._contexts.clear()
        return {**result, "replayed": replayed}

    def install_bytes(self, data):
        if not isinstance(data, bytes) or not 0 < len(data) <= self.MAX_UPLOAD_BYTES:
            raise GameplayFault("InvalidModPackage", "英雄包为空或超过 64 MiB。")
        try:
            with self.store.lock, self.catalog._transaction():
                staging = self.catalog.root / "staging"
                self.catalog._guard_storage(staging)
                staging.mkdir(parents=True, exist_ok=True)
                path = staging / ("upload-" + secrets.token_hex(16) + ".heropack")
                self.catalog._guard_storage(path)
                created = False
                try:
                    with path.open("xb") as stream:
                        created = True
                        stream.write(data)
                    self.catalog._guard_storage(path)
                    result = self.catalog.install(path)
                    self._contexts.clear()
                    return result
                finally:
                    if created:
                        try:
                            self.catalog._guard_storage(path)
                        except ModError:
                            # A changed parent link must never redirect cleanup
                            # to unrelated files outside the configured root.
                            pass
                        else:
                            path.unlink(missing_ok=True)
        except ModError as error:
            raise _mod_fault(error) from error

    def asset(self, content_digest, path):
        try:
            file = self.catalog.resolve_digest_asset(content_digest, path)
        except ModError as error:
            raise _mod_fault(error) from error
        media_type = mimetypes.guess_type(file.name)[0] or "application/octet-stream"
        return file.read_bytes(), media_type

    @staticmethod
    def _backup_value(state, identity_map):
        saved = copy.deepcopy(state)
        saved.pop("previous", None)
        body = {"schema": "lal-mod-backup-v1", "state": saved,
                "identityMap": copy.deepcopy(identity_map)}
        return {**body, "digest": digest(body)}

    def backup(self, uid, *, previous=False):
        _, state = self.state(uid)
        if previous:
            saved = state.get("previous")
            if not isinstance(saved, dict):
                raise GameplayFault("ModBackupUnavailable", "当前存档还没有上一次配置备份。")
            return copy.deepcopy(saved)
        return self._backup_value(state, self.catalog.identity_snapshot())

    @staticmethod
    def _merge_known(old, restored):
        result = copy.deepcopy(old.get("knownHeroes", {}))
        incoming = restored.get("knownHeroes", {})
        if not isinstance(result, dict) or not isinstance(incoming, dict):
            raise GameplayFault("InvalidModBackup", "Mod 备份的英雄身份记录无效。")
        for aid, meta in incoming.items():
            if (not isinstance(aid, str) or not isinstance(meta, dict)
                    or (aid in result and result[aid].get("identity") != meta.get("identity"))):
                raise GameplayFault("InvalidModBackup", "Mod 备份的英雄身份记录无效或与当前存档冲突。")
            result[aid] = copy.deepcopy(meta)
        return result

    def restore_plan(self, uid, params):
        backup = params.get("backup")
        if not isinstance(backup, dict) or backup.get("schema") != "lal-mod-backup-v1":
            raise GameplayFault("InvalidModBackup", "Mod 备份格式无效。")
        body = {k: v for k, v in backup.items() if k != "digest"}
        if digest(body) != backup.get("digest"):
            raise GameplayFault("InvalidModBackup", "Mod 备份摘要不一致。")
        profile, old = self.state(uid)
        state = backup.get("state")
        if not isinstance(state, dict):
            raise GameplayFault("InvalidModBackup", "Mod 备份缺少状态。")
        selections = self.normalize_selections(state.get("selections", []))
        known = self._merge_known(old, state)
        if not isinstance(known, dict) or any(not isinstance(k, str) or not isinstance(v, dict)
                                              for k, v in known.items()):
            raise GameplayFault("InvalidModBackup", "Mod 备份的英雄身份记录无效。")
        # Never silently renumber an identity already referenced by saved entities.
        current = self.catalog.identity_snapshot()
        incoming = backup.get("identityMap", {})
        try:
            self.catalog.validate_identity_snapshot(incoming)
        except ModError as error:
            raise _mod_fault(error) from error
        for aid, meta in known.items():
            identity = meta.get("identity")
            binding = incoming.get("identities", {}).get(identity, current.get("identities", {}).get(identity, {}))
            if meta.get("kind") != "new" or binding.get("aid") != aid:
                raise GameplayFault("InvalidModBackup", "缺失英雄记录与备份的永久身份映射不一致。")
        if (not isinstance(incoming, dict) or set(incoming) != {"identities", "families"}
                or any(not isinstance(incoming[key], dict) for key in incoming)):
            raise GameplayFault("InvalidModBackup", "Mod 备份的身份映射格式无效。")
        current_ids = current.get("identities", {})
        occupied = {row["aid"]: identity for identity, row in current_ids.items()}
        for identity, row in incoming["identities"].items():
            if not isinstance(row, dict) or not isinstance(row.get("aid"), str):
                raise GameplayFault("InvalidModBackup", "Mod 身份映射记录无效。")
            if ((identity in current_ids and current_ids[identity]["aid"] != row["aid"])
                    or (row["aid"] in occupied and occupied[row["aid"]] != identity)):
                raise GameplayFault("ModIdentityMigrationRequired", "目标设备的编号已绑定其他身份，需要完整迁移后再恢复。")
        for family, number in incoming["families"].items():
            if family in current.get("families", {}) and current["families"][family] != number:
                raise GameplayFault("ModIdentityMigrationRequired", "目标设备的英雄系列编号冲突，需要完整迁移后再恢复。")
        if self._pending(profile):
            raise GameplayFault("ModPendingOperation", "请先完成未结算操作。")
        try:
            candidate = self.catalog.preview_restore(
                incoming, self.base, {"packages": selections, "knownHeroes": known}, self.roster,
                allow_missing=True,
            )
        except ModError as error:
            raise _mod_fault(error) from error
        self.require_client(candidate, params.get("_clientCapabilities"))
        self._owned_compatible(profile, candidate)
        token = digest({"uid": str(uid), "revision": old["revision"], "backup": backup,
                        "profileRevision": self.store.state_revision(uid), "catalog": self._fingerprint()})
        return {"valid": True, "revision": old["revision"], "planDigest": token,
                "warnings": candidate.warnings, "digest": candidate.digest,
                "changes": ["恢复 Mod 清单及映射；缺少的活动包仍显示缺失，不从备份自动启用素材。"]}

    def restore(self, uid, params):
        request_id = self._request_key(params)
        payload = {"backup": params.get("backup"), "planDigest": params.get("planDigest")}

        def mutate(profile):
            plan = self.restore_plan(uid, params)
            if params.get("planDigest") != plan["planDigest"]:
                raise GameplayFault("ModPlanExpired", "恢复预览已过期。")
            backup = params["backup"]
            try:
                self.catalog.restore_identities(backup.get("identityMap", {}))
            except ModError as error:
                raise _mod_fault(error) from error
            old = profile.get("mod_state", {})
            restored = copy.deepcopy(backup["state"])
            restored["revision"] = old.get("revision", 0) + 1
            restored["selections"] = self.normalize_selections(restored.get("selections", []))
            restored["knownHeroes"] = self._merge_known(old, restored)
            restored["identityMap"] = self.catalog.identity_snapshot()
            compiled = self._compile(restored)
            self._seed_instance_sequence(uid, profile, compiled.document)
            restored["digest"] = compiled.digest
            restored["previous"] = self._backup_value(old, old.get("identityMap", self.catalog.identity_snapshot()))
            profile["mod_state"] = restored
            return profile, {"revision": restored["revision"], "digest": compiled.digest, "reloginRequired": True}

        result, replayed = self.store.atomic_update(uid, mutate, "user.mods_restore:" + request_id, payload)
        self._contexts.pop(str(uid), None)
        return {**result, "replayed": replayed}

    def dispatch(self, uid, method, params, client_capabilities=None):
        params={**params,'_clientCapabilities':client_capabilities}
        if method in ('user.mods_config','user.mods_test_grant'):
            self.require_client(getattr(self.context(uid),'mod_resolved',None),client_capabilities)
        functions = {"user.mods_info": lambda: self.info(uid, rescan=params.get("rescan") is True),
                     "user.mods_config": lambda: self.config(uid),
                     "user.mods_plan": lambda: self.plan(uid, params),
                     "user.mods_apply": lambda: self.apply(uid, params),
                     "user.mods_reclaim_equipment": lambda: self.reclaim_equipment(uid, params),
                     "user.mods_test_grant": lambda: self.test_grant(uid, params),
                     "user.mods_uninstall_plan": lambda: self.uninstall_plan(uid, params),
                     "user.mods_uninstall": lambda: self.uninstall(uid, params),
                     "user.mods_backup": lambda: self.backup(uid, previous=params.get("previous") is True),
                     "user.mods_restore_plan": lambda: self.restore_plan(uid, params),
                     "user.mods_restore": lambda: self.restore(uid, params)}
        try:
            return functions[method]()
        except ModError as error:
            raise _mod_fault(error) from error
        except OSError as error:
            raise GameplayFault("ModFileError", "无法完成英雄包文件操作，请检查文件状态和可用空间。") from error
