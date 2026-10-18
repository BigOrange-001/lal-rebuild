"""Isolated A11 data setup for the real AIR probe, without replacing combat.

Call ``setup_a11_scope(backend, owner, work)`` after the probe's new-hero setup
and before client login. Merge the returned settings into probe.json. The
normal M_001_1 battle already contains the target Garen on the enemy side.
Inspect real Avatar.avatarData.id/skill0 on both teams, then let the original
client execute and settle the battle. This helper itself proves no AIR result.
"""
from __future__ import annotations

import copy
import json
import sys
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
sys.path.insert(0, str(ROOT / "server"))
from mod_tools import pack_directory
from gameplay_common import grant_reward


def setup_a11_scope(backend, owner, work):
    work = Path(work).resolve()
    if not backend.mods.root.resolve().is_relative_to(work):
        raise ValueError("A11 setup requires an isolated backend beneath work")
    uid = str(owner["uid"])
    source = work / ("a11-scope-" + uuid.uuid4().hex)
    source.mkdir()
    target = "A_1001_3"
    original_skill = backend.config["cfg"]["avatar"][target]["pl"][10]
    package_id = str(uuid.uuid4())
    manifest = {"format": "lal-mod-v1", "kind": "patch", "packageId": package_id,
                "name": "A11 原生同场作用域验收", "author": "Isolated runtime QA",
                "version": "1.0.0", "engineApi": "1",
                "requiredCapabilities": ["hero.patch.skill", "skill.damage", "patch.scopes"],
                "entrypoints": {"patches": "patches.json", "skills": "skills.json"},
                "dependencies": [], "files": [],
                "sourceNotes": {"kind": "authored", "description": "仅用于独立原生运行验收，不声称原版技能。"}}
    patch = {"id": "owned-normal-only", "target": "builtin:avatar/" + target,
             "expect": {"path": "skills.normal", "value": "builtin:skill/" + original_skill},
             "patchScopes": {"owned": True, "arenaEnemy": False, "pveEnemy": False,
                             "assist": False, "summoned": False},
             "operations": [{"op": "replace", "path": "skills.normal", "value": "self:skill/a11_normal"}]}
    skill = {"id": "a11_normal", "name": "A11 玩家侧专用打击",
             "description": "同场玩家盖伦使用本技能；敌方盖伦保留基础技能。",
             "timingUnit": "ownerTurns", "warmup": 0, "cooldown": 2, "range": 1000,
             "targetPolicy": "enemy_lane_frontmost",
             "actions": [{"type": "damage", "coefficient": 2, "damageType": "physical", "effect": None}],
             "upgrades": []}
    for name, value in (("manifest", manifest), ("patches", {"patches": [patch]}), ("skills", {"skills": [skill]})):
        (source / (name + ".json")).write_text(json.dumps(value, ensure_ascii=False, indent=2), "utf-8")
    archive = source.with_suffix(".heropack")
    pack_directory(source, archive)
    installed = backend.mods.install_bytes(archive.read_bytes())
    info = backend.mods.info(uid)
    selections = copy.deepcopy(info["selections"])
    selections.append({"packageId": package_id, "version": installed["version"],
                       "contentDigest": installed["contentDigest"], "enabled": True})
    params = {"expectedRevision": info["revision"], "selections": selections}
    plan = backend.mods.plan(uid, params)
    if not plan["valid"]:
        raise RuntimeError("A11 scope fixture conflicts: " + json.dumps(plan, ensure_ascii=False))
    backend.mods.apply(uid, {**params, "planDigest": plan["planDigest"], "requestId": "a11-apply-" + package_id})
    config = backend.mods.config(uid)
    context = backend.players.context_for(uid)

    def grant_and_form(profile):
        before = set(profile["avatars"])
        grant_reward(profile, {"avatar": {target: 1}}, context.config)
        iid = next(iter(set(profile["avatars"]) - before))
        selected = [card for card in profile["team"][0] if card]
        # Keep the originally expected new hero in slot zero and put this Garen
        # on lane one, matching the authored enemy Garen's lane in M_001_1.
        selected = selected[:1] + [iid] + selected[1:4]
        profile["team"][0] = selected + [None] * (6 - len(selected))
        return profile, {"id": iid}

    receipt, _ = context.atomic_update(uid, grant_and_form, "a11-grant-" + package_id, {})
    runtime = config["mod_runtime"]
    enemy_definition = runtime["scopedAvatarIds"]["pveEnemy"][target]
    result = {"scopeTargetAid": target, "scopeOwnedInstance": receipt["id"],
              "scopeOwnedSkill": config["cfg"]["avatar"][target]["pl"][10],
              "scopeEnemyDefinition": enemy_definition,
              "scopeEnemySkill": config["cfg"]["avatar"][enemy_definition]["pl"][10],
              "scopePackage": package_id}
    if result["scopeOwnedSkill"] == result["scopeEnemySkill"] or result["scopeEnemySkill"] != original_skill:
        raise AssertionError("A11 fixture did not produce two distinct normal skills")
    (work / "a11-scope-fixture.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), "utf-8")
    return result
