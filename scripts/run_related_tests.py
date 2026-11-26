"""Run only the tests related to a change, instead of the full suite.

Selection for each changed file:

1. A changed test file runs itself.
2. Tests that reference the file directly: ``import module`` / ``from module``
   for Python, or the path / file name for client sources, configs and scripts.
3. The curated tests of every category whose sources match the file.
4. Core shared modules (battle engine, roster, store, gateway...) are imported
   by most tests; they select the curated ``core`` list instead of every
   importer. Use ``--wide`` to also add their direct importers.

Usage::

    python scripts/run_related_tests.py                 # changes vs HEAD (staged + unstaged + new)
    python scripts/run_related_tests.py --base origin/main
    python scripts/run_related_tests.py server/arena_raids.py client/src/stages/046_PanelCenterPVP.as
    python scripts/run_related_tests.py --category arena economy
    python scripts/run_related_tests.py --list           # show categories
    python scripts/run_related_tests.py --dry-run ...    # print the selection only

The full suite is still ``python -m unittest discover`` in ``server/``; use it
only for release checks.
"""
from __future__ import annotations

import argparse
import fnmatch
import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# Each category: source globs (repo-relative) and its curated test globs.
CATEGORIES = {
    "core": {
        "sources": ["server/battle_engine.py", "server/gameplay_roster.py", "server/player_store.py",
                    "server/gateway.py", "server/gameplay_common.py", "server/mod_policy.py",
                    "server/battle_intents.py", "server/combat_math.py", "server/combat_rules.py"],
        "tests": ["server/test_reference_battle_actions.py", "server/test_combat_redesign.py",
                  "server/test_equipment_flows.py", "server/test_progression_integration.py",
                  "server/test_team_presets.py", "server/test_arena_gateway.py",
                  "server/test_ledger_codec.py", "server/test_release_campaign_config.py"],
    },
    "platform": {
        "sources": ["server/game_clock.py", "server/game_calendar.py", "server/ledger_codec.py",
                    "server/config_fingerprint.py", "server/activity_windows_105.py",
                    "scripts/build_client.py", "scripts/prepare_android_runtime.py", "scripts/run_related_tests.py", "android-manager/**"],
        "tests": ["server/test_game_clock.py", "server/test_daily_midnight_reset.py",
                  "server/test_ledger_codec.py", "server/test_activity_windows_105.py",
                  "scripts/test_compressed_saves.py", "scripts/test_save_retention.py",
                  "scripts/test_build_version.py", "scripts/test_daily_reset_client.py",
                  "scripts/test_air_release_payload.py", "scripts/test_android_els_compat.py",
                  "scripts/test_run_related_tests.py"],
    },
    "arena": {
        "sources": ["server/gameplay_competition.py", "server/arena_*.py", "server/formation_share.py",
                    "server/npc_cultivation.py", "server/bot_names.py",
                    "client/src/formation_*.aspart", "client/src/arena_*.aspart",
                    "client/src/stages/*PanelCenterPVP.as", "client/src/stages/*ItemPVP*.as"],
        "tests": ["server/test_arena_*.py", "server/test_formation_share.py", "server/test_bot_names.py",
                  "server/test_friend_npcs.py", "scripts/test_formation_share_client.py",
                  "scripts/test_arena_*.py"],
    },
    "social": {
        "sources": ["server/gameplay_social.py", "server/npc_cultivation.py", "server/bot_names.py",
                    "client/src/stages/*PanelPVEfriend.as"],
        "tests": ["server/test_friend_npcs.py", "server/test_bot_names.py", "server/test_mod_assist.py",
                  "server/test_guild_companions.py"],
    },
    "guild": {
        "sources": ["server/gameplay_guild_boss.py", "server/guild_*.py", "server/help_pages.py",
                    "client/src/stages/*Guild*.as", "client/src/stages/*PanelChatRoom.as"],
        "tests": ["server/test_guild_*.py", "scripts/test_guild_chat_polling_client.py"],
    },
    "economy": {
        "sources": ["server/gameplay_economy.py", "server/shop_balance_105.py", "server/daily_exchange_105.py", "server/vip_reward_mail.py",
                    "server/spending_budget.py", "server/vip_campaign.py", "server/recruit_exchange.py",
                    "server/check_in_rewards.py", "server/adventure_tasks.py", "server/zhuabao.py",
                    "server/summon_pools.py", "server/skin_acquisition_104.py", "server/gameplay_energy.py",
                    "server/summon_panel_103.py", "client/src/vip_*.aspart",
                    "client/src/stages/*Shop*.as", "client/src/stages/*VIP*.as", "client/src/stages/*Pay*.as",
                    "client/src/stages/*Exchange*.as", "client/src/stages/*Casino*.as"],
        "tests": ["server/test_spending_budget.py", "server/test_vip_campaign.py", "server/test_vip_rewards_105.py", "server/test_recruit_exchange.py",
                  "server/test_skin_acquisition_104.py", "server/test_check_in_rewards.py",
                  "server/test_adventure_tasks.py", "server/test_zhuabao.py", "server/test_summon_pools.py",
                  "server/test_energy_purchase.py", "server/test_shop_balance_105.py", "server/test_daily_exchange_105.py",
                  "server/test_pass_battle_gift.py", "server/test_summon_panel_103.py",
                  "server/test_tower_skin_exchange.py", "scripts/test_adventure_client.py",
                  "scripts/test_energy_purchase_client.py", "scripts/test_summon_panel_103_client.py",
                  "scripts/test_vip_pack_rewards_client.py", "scripts/test_daily_exchange_client.py"],
    },
    "equipment": {
        "sources": ["server/equipment_*.py", "server/halo_progression.py", "server/inventory_locks.py",
                    "server/skill_books.py", "client/src/stages/*Equip*.as"],
        "tests": ["server/test_equipment_*.py", "server/test_eight_star_alchemy_105.py",
                  "server/test_halo_progression.py", "server/test_inventory_magic_103.py",
                  "server/test_skill_books.py", "scripts/test_equipment_*.py", "scripts/test_skill_books_client.py",
                  "scripts/test_annie_core_visual_105.py"],
    },
    "roster": {
        "sources": ["server/cultivation_rules.py", "server/team_presets.py", "server/captain_*.py",
                    "server/orange_ascension_104.py", "server/talent_stats_103.py", "server/bonds_104.py",
                    "server/power_balance_104.py", "server/pve_display_power_58.py", "server/material_stacks.py",
                    "client/src/stages/*PanelSocialMainAvatar.as", "client/src/stages/*BetterSelect.as"],
        "tests": ["server/test_cultivation_weighted.py", "server/test_team_presets.py", "server/test_dn_*.py",
                  "server/test_captain_*.py", "server/test_roster_sale_promotion.py", "server/test_growth_overhaul.py",
                  "server/test_orange_ascension_104.py", "server/test_zongzi_binding_104.py",
                  "server/test_stat_power_103.py", "server/test_newzone_power.py", "server/test_balance_104.py",
                  "server/test_power_role_balance.py",
                  "scripts/test_team_presets_client.py", "scripts/test_roster_magic_103_client.py",
                  "server/test_material_stacks.py", "scripts/test_material_stacks_client.py"],
    },
    "combat": {
        "sources": ["server/battle_*.py", "server/combat_*.py", "server/dot_rules_103.py", "server/skill_*.py",
                    "server/manual_ability_sim.py", "server/hero_damage_types.py", "server/upstream_skill_priority.py",
                    "server/native_skill_snapshot.py", "server/native_fx_wiring_106.py",
                    "client/src/combat_rules_104.aspart",
                    "client/src/battle_effects_104.aspart", "client/src/native_effect_*.aspart",
                    "client/src/stages/*Avatar.as", "client/src/stages/*SkillSet.as", "client/src/stages/*GameMap.as"],
        "tests": ["server/test_battle_status_effects.py", "server/test_native_fx_wiring_106.py",
                  "server/test_combat_*.py", "server/test_dot_rules_103.py",
                  "server/test_reference_battle_actions.py", "server/test_manual_ability_sim.py",
                  "server/test_skill_*.py", "server/test_hero_damage_types.py", "server/test_upstream_skill_priority.py",
                  "scripts/test_curse_combat.py", "scripts/test_damage_formula_client_104.py",
                  "scripts/test_battle_*.py", "scripts/test_parallel_aoe_client.py", "scripts/test_avatar_passive.py",
                  "scripts/test_combat_calibration_104.py", "scripts/test_dot_rules_103_client.py",
                  "scripts/test_attack_range_preview.py", "scripts/test_manual_ability_oracle_103.py",
                  "scripts/test_skill_rank_growth_104.py", "scripts/test_summon_formation.py",
                  "scripts/test_training_dummy_104.py"],
    },
    "heroes": {
        "sources": ["server/hero_*.py", "server/skin_*.py", "server/new_skin_bonds_104.py", "server/annie_reaction_105.py",
                    "server/cat_katarina_103.py", "server/polar_ashe_103.py", "server/santa_veigar_103.py",
                    "server/nurse_akali_103.py", "server/dragonmancer_kaisa_*.py", "server/nightbringer_yasuo_*.py",
                    "server/upstream_hero_config*.py", "server/orange_four_stat_buff_overlay.py", "server/player_copy_104.py",
                    "server/copy_polish_104.py", "client/src/skin_revision_v2.aspart",
                    "client/src/new_skin_bonds_104.aspart", "client/src/dragonmancer_kaisa.aspart",
                    "client/src/nightbringer_yasuo*.aspart"],
        "tests": ["server/test_hero_*.py", "server/test_skin_*.py", "server/test_new_skin_bonds_104.py", "server/test_annie_reaction_105.py",
                  "server/test_cat_katarina_103.py", "server/test_polar_ashe_103.py",
                  "server/test_santa_veigar_103.py", "server/test_nurse_akali_103.py",
                  "server/test_dragonmancer_kaisa.py", "server/test_nightbringer_yasuo.py",
                  "server/test_anchor_104.py", "server/test_review_104.py",
                  "scripts/test_hero_*.py", "scripts/test_skin_*.py", "scripts/test_nightbringer_yasuo_*.py",
                  "scripts/test_dragonmancer_kaisa_native.py", "scripts/test_soraka_targets_104.py",
                  "scripts/test_newyear_annie_104.py", "scripts/test_teemo_combat.py", "scripts/test_review_combat_105.py",
                  "server/test_orange_four_stat_buff_overlay.py", "server/test_player_copy_104.py"],
    },
    "pve": {
        "sources": ["server/gameplay_combat.py", "server/pve_*.py", "server/campaign_*.py", "server/tower_*.py",
                    "server/ancient_trial*.py", "server/activity_tower_overlay.py", "server/material_attempts_103.py",
                    "server/loot_rates_104.py", "server/resource_drops_104.py", "server/hero_drop.py",
                    "server/solo_progression.py", "server/progression_overhaul.py", "server/stage_sweep.py",
                    "client/src/stages/*ItemPVEcombat.as"],
        "tests": ["server/test_pve_feedback_overlay.py", "server/test_campaign_tower_difficulty_104.py",
                  "server/test_tower_*.py", "server/test_ancient_trial*.py", "server/test_activity_tower.py",
                  "server/test_material_attempts_103.py", "server/test_loot_rates_104.py",
                  "server/test_resources_overhaul.py", "server/test_progression_integration.py",
                  "server/test_exploration_*.py", "scripts/test_exploration_client.py",
                  "scripts/test_material_attempts_103_client.py", "server/test_stage_sweep.py",
                  "scripts/test_stage_sweep_client.py"],
    },
    "abyss": {
        "sources": ["server/roguelite_abyss.py", "server/gameplay_abyss.py", "server/abyss_*.py",
                    "client/src/abyss_*.aspart"],
        "tests": ["server/test_roguelite_abyss*.py", "server/test_abyss_*.py", "scripts/test_abyss_*.py",
                  "scripts/test_avatar_detail_relic_lock_104.py"],
    },
    "mod": {
        "sources": ["server/mod_*.py", "server/mod_*.json"],
        "tests": ["server/test_mod_*.py", "scripts/test_mod_client.py"],
    },
    "ui": {
        "sources": ["client/src/ui_kit_105.aspart", "client/src/stages/*UiLayer.as", "client/src/stages/*GlobalFunction.as"],
        "tests": ["scripts/test_ui_layers_103.py", "scripts/test_fullscreen_viewport.py",
                  "scripts/test_notice_viewport.py", "scripts/test_description_ui_104.py",
                  "scripts/test_vital_bar_104.py", "scripts/test_rainbow_frame_105.py", "scripts/test_playtest_client.py"],
    },
}
CORE = set(CATEGORIES["core"]["sources"])
TOOLCHAIN = ROOT.parent / "toolchain"


def rel(path):
    path = Path(path)
    if path.is_absolute():
        try:
            path = path.resolve().relative_to(ROOT)
        except ValueError:
            return path.as_posix()
    return path.as_posix()


def changed_files(base):
    def git(*args):
        out = subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True, encoding="utf-8")
        if out.returncode:
            raise subprocess.CalledProcessError(out.returncode, ["git", *args], out.stdout, out.stderr)
        return [line for line in out.stdout.splitlines() if line.strip()]
    files = set(git("diff", "--name-only", base)) | set(git("diff", "--name-only", "--cached", base))
    files |= set(git("ls-files", "--others", "--exclude-standard"))
    return sorted(files)


def all_tests():
    return sorted(rel(p) for folder in ("server", "scripts") for p in (ROOT / folder).glob("test_*.py"))


def expand(patterns, tests):
    return {t for t in tests for pattern in patterns if fnmatch.fnmatch(t, pattern)}


def references(path, tests):
    """Tests that import the module or mention the file by path or name."""
    name = Path(path).name
    stem = Path(path).stem
    hits = set()
    if path.endswith(".py"):
        pattern = re.compile(r"^\s*(from|import)\s+" + re.escape(stem) + r"\b", re.M)
    else:
        pattern = re.compile(re.escape(name))
    for test in tests:
        text = (ROOT / test).read_text("utf-8", errors="replace")
        if pattern.search(text) or (not path.endswith(".py") and path in text):
            hits.add(test)
    return hits


def select(paths, *, wide=False):
    tests = all_tests()
    chosen, reasons = set(), {}
    for path in paths:
        picked = set()
        if re.fullmatch(r"(server|scripts)/test_[^/]+\.py", path) and path in tests:
            picked.add(path)
        for name, category in CATEGORIES.items():
            if any(fnmatch.fnmatch(path, glob) for glob in category["sources"]):
                picked |= expand(category["tests"], tests)
        if path not in CORE or wide:
            picked |= references(path, tests)
        for test in picked:
            reasons.setdefault(test, set()).add(path)
        chosen |= picked
    return sorted(chosen), reasons


def environment():
    env = dict(os.environ)
    extra = [str(TOOLCHAIN / "pythonlibs"), str(ROOT / "server"), str(ROOT / "scripts")]
    env["PYTHONPATH"] = os.pathsep.join(extra + [env.get("PYTHONPATH", "")])
    env["PYTHONIOENCODING"] = "utf-8"
    node = TOOLCHAIN / "node"
    if node.exists():
        env["PATH"] = str(node) + os.pathsep + env.get("PATH", "")
    return env


def run(selected):
    env = environment()
    status = 0
    for folder in ("server", "scripts"):
        modules = [Path(t).stem for t in selected if t.startswith(folder + "/")]
        if not modules:
            continue
        print(f"\n== {folder}: {len(modules)} test modules", flush=True)
        result = subprocess.run([sys.executable, "-m", "unittest", *modules], cwd=ROOT / folder, env=env)
        status = status or result.returncode
    return status


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("paths", nargs="*", help="changed files (default: git changes vs --base)")
    parser.add_argument("--base", default="HEAD", help="git base for changed files (default HEAD)")
    parser.add_argument("--category", nargs="+", help="run whole categories instead")
    parser.add_argument("--wide", action="store_true", help="also add direct importers of core modules")
    parser.add_argument("--list", action="store_true", help="list categories and their tests")
    parser.add_argument("--dry-run", action="store_true", help="print the selection without running")
    args = parser.parse_args()
    tests = all_tests()
    if args.list:
        covered = set()
        for name, category in CATEGORIES.items():
            covered |= expand(category['tests'], tests)
            print(f"{name}: {len(expand(category['tests'], tests))} tests")
            for test in sorted(expand(category["tests"], tests)):
                print("   ", test)
        missing = sorted(set(tests) - covered)
        if missing:
            print("Uncategorized test modules:\n  " + "\n  ".join(missing), file=sys.stderr)
            return 1
        return 0
    if args.category:
        unknown = set(args.category) - set(CATEGORIES)
        if unknown:
            parser.error("unknown category: " + ", ".join(sorted(unknown)))
        selected = sorted(set().union(*(expand(CATEGORIES[c]["tests"], tests) for c in args.category)))
        reasons = {}
    else:
        try:
            paths = [rel(p) for p in args.paths] or changed_files(args.base)
        except subprocess.CalledProcessError as error:
            parser.error("Cannot read Git changes: " + error.stderr.strip())
        if not paths:
            print("No changed files.")
            return 0
        selected, reasons = select(paths, wide=args.wide)
        if any(p in CORE for p in paths) and not args.wide:
            print("Note: core module changed; running the curated core tests (add --wide for every importer).")
    print(f"Selected {len(selected)} of {len(tests)} test modules:")
    for test in selected:
        why = ", ".join(sorted(reasons.get(test, [])))
        print("   ", test, f"  <- {why}" if why else "")
    if args.dry_run or not selected:
        return 0
    return run(selected)


if __name__ == "__main__":
    sys.exit(main())
