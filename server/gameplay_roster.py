"""Original-client roster, hero growth, talent and equipment RPC module.

All writes pass through PlayerStore.atomic_update so validation and mutation
share one SQLite transaction. Price values come from the configured roster.
"""
from __future__ import annotations
import copy, hashlib, json, math, random, time
from decimal import Decimal, ROUND_HALF_UP
from typing import Any

from player_store import GameplayFault
from gameplay_common import (grant_reward, ensure_hero_acquirable, skin_acquisition_blocked_ids,
                             equipment_exclusive_ids, next_hero_instance_id, preserve_mod_hero_sequence)
from mod_policy import (runtime as mod_runtime, ensure_available, hero_available,
                        channel_enabled, ensure_channel, draw_categories, definition_id, hero_metadata)
from pve_modes import exploration_stages
from equipment_magic import (
    stat_bonus as magic_stat_bonus, symp_bonuses as magic_symp_bonuses,
    upgrade_cost as magic_upgrade_cost, main_stat_multiplier as magic_main_stat_multiplier,
    rune_bonus as equipment_rune_bonus, rune_upgrade_cost as equipment_rune_upgrade_cost,
)
from equipment_growth_v2 import (
    alchemy_upgrade_steps as equipment_alchemy_upgrade_steps,
    bounded_wash_values,
    effective_cap as equipment_effective_cap,
    main_stat as equipment_main_stat,
    migrate_item_wash,
    migrate_pending_save,
    roll_for_new_item,
    upgrade_result as equipment_upgrade_result,
    wash_roll as equipment_wash_roll,
    wash_stats as equipment_wash_stats,
)
from equipment_upgrade_cost import cost_table as equipment_upgrade_cost_table, MAX_EQUIPMENT_LEVEL
from halo_progression import halo_rank_threshold
from cultivation_rules import (
    SCHEMA as WEIGHTED_CULTURE_SCHEMA,
    active as weighted_culture_active,
    allocate_budget as allocate_culture_budget,
    actual_material_gain as culture_actual_material_gain,
    actual_to_legacy_raw as culture_actual_to_legacy_raw,
    cap as weighted_culture_cap,
    clamp_gain as clamp_weighted_culture_gain,
    migrate_hero as migrate_weighted_culture_hero,
    normalize_profile as normalize_culture_profile,
    roll as roll_weighted_culture,
    used as weighted_culture_used,
    weighted_feed as feed_weighted_culture,
)

class GameplayRosterEquipment:
    SKILL_BISCUIT_IDS = frozenset({"A_6992_4", "A_6992_5", "A_6992_6"})
    HERO_METHODS = {
        "user.wager_avatar", "user.fix_team", "user.swallow_avatar", "user.swallow_skillbook",
        "user.star_up", "user.phase_up", "user.avatar_limit_break", "user.sell_avatars", "user.avatar_culture",
        "user.avatar_culture_save", "user.avatar_culture_cancel", "user.get_avatar_talent",
        "user.save_talent", "user.dn_unlock", "user.dn_lvup", "user.morph",
        "user.soul_exchange_avatar",
        "user.soul_exchange_equip", "user.compose_fragment", "user.equip_dress",
        "user.equip_rise", "user.equip_wash", "user.equip_wash_cancel",
        "user.equip_wash_save", "user.equip_sell", "user.equip_alchemy", "user.add_magic",
        "user.equip_rune_up",
        "user.set_defensive_squad", "user.get_newzone_ranks",
        "user.team_preset_save", "user.team_preset_load", "user.team_preset_delete",
        "user.inventory_lock",
    }
    CURRENCY = {"gold", "coin", "score", "medal", "mark"}
    ATTRS = {"dust", "sp", "dn_stone", "culture_book"}

    def __init__(self, store, config):
        self.store = store
        if isinstance(config, str): config = json.loads(config)
        self.full_config = config if isinstance(config, dict) else {}
        side_path = __import__("pathlib").Path(__file__).resolve().parents[1] / "config/reconstruction/roster-config.json"
        side = json.loads(side_path.read_text(encoding="utf-8")) if side_path.exists() else {}
        if isinstance(config, dict) and isinstance(config.get("mod_roster"), dict):
            side = config["mod_roster"]
        if not isinstance(config, dict): self._fail("InvalidConfig", "Expected a game config object")
        if "cfg" in config:
            source = config.get("cfg", {})
            self.ploy_simple = copy.deepcopy(source.get("ploy_system_simple", {})) if isinstance(source, dict) else {}
            self.simple = copy.deepcopy(source.get("system_simple", {}))
            side_simple = side.get("system_simple", {})
            if isinstance(self.simple, dict) and isinstance(side_simple, dict):
                live_culture = self.simple.setdefault("culture", {})
                side_culture = side_simple.get("culture", {})
                if isinstance(live_culture, dict) and isinstance(side_culture, dict):
                    live_culture.setdefault("pith_limit_add", copy.deepcopy(side_culture.get("pith_limit_add", [])))
            source_heroes = source.get("avatar", side.get("heroes", {}))
            configured_heroes = source_heroes
            self.config = {
                "heroes": configured_heroes,
                "skills": source.get("skill", side.get("skills", {})),
                "effects": source.get("effect", side.get("effects", {})),
                "equipment": source.get("equip") or side.get("equipment", {}),
                "talents": source.get("talent") or side.get("talents", {}),
                "rules": side.get("rules", {}),
            }
        else:
            self.config = config
            self.simple = config.get("system_simple", config.get("cfg", {}).get("system_simple", {}))
            self.ploy_simple = copy.deepcopy(config.get("ploy_system_simple", {})) if isinstance(config, dict) else {}
        self.rules = self.config.get("rules", {})
        self.draw_pools = side.get("wager_pools", {}) if isinstance(side, dict) else {}
        cfg_envelope = self.full_config.get("cfg", self.full_config)
        config_rank = cfg_envelope.get("ploy_system_simple", {}).get("rank", {}) if isinstance(cfg_envelope, dict) else {}
        side_rank = side.get("ploy_system_simple", {}).get("rank", {}) if isinstance(side, dict) else {}
        self.rank_config = dict(side_rank) if isinstance(side_rank, dict) else {}
        if isinstance(config_rank, dict):
            self.rank_config.update(config_rank)
            for field in ("gift", "rank_help"):
                if isinstance(side_rank.get(field), dict) and isinstance(config_rank.get(field), dict):
                    self.rank_config[field] = {**side_rank[field], **config_rank[field]}
        self.heroes = self.config.get("heroes", {})
        self.equipment = self.config.get("equipment", {})
        self.skills = self.config.get("skills", {})
        self.talents = self.config.get("talents", {})
        from summon_pools import SummonPools
        self.summon_pools = SummonPools.from_config(self.full_config)
        self.rng = random.SystemRandom()

    @staticmethod
    def _fail(code: str, msg: str):
        raise GameplayFault(code, msg)

    @staticmethod
    def _pending_culture_hero_ids(profile):
        """Return owned hero IDs referenced by an uncommitted cultivation roll."""
        attrs = profile.get("attrs", {}) if isinstance(profile, dict) else {}
        pending = attrs.get("avatar_culture") if isinstance(attrs, dict) else None
        if not isinstance(pending, dict):
            return set()
        # Native and historical pending records may identify the same hero
        # under either field. Protect both if a malformed legacy row differs.
        heroes = profile.get("avatars", {})
        pending_ids = set()
        for field in ("aid", "eqid"):
            hero_id = pending.get(field)
            if isinstance(hero_id, str) and hero_id and hero_id in heroes:
                pending_ids.add(hero_id)
        return pending_ids

    def _check_not_pending_culture(self, profile, hero_id):
        if hero_id in self._pending_culture_hero_ids(profile):
            self._fail("PendingOperation", "Save or cancel the pending cultivation before using this hero")

    @staticmethod
    def _num(value, name, minimum=0, maximum=10_000_000):
        if type(value) not in (int, float) or not math.isfinite(value) or value < minimum or value > maximum:
            GameplayRosterEquipment._fail("InvalidParameter", f"Invalid {name}")
        return int(value)

    @staticmethod
    def _id(value, name="id"):
        if not isinstance(value, str) or not value or len(value) > 128:
            GameplayRosterEquipment._fail("InvalidParameter", f"Invalid {name}")
        return value

    def _profile(self, uid):
        if hasattr(self.store, "profile_raw"):
            return self.store.profile_raw(uid)
        return self.store.profile(uid)

    def _write(self, uid, method, params, change):
        action = params.get("actionID") if isinstance(params, dict) else None
        key = f"{method}:{action}" if isinstance(action, (str, int)) else None
        def mutate(profile):
            preserve_mod_hero_sequence(profile, self.full_config)
            self._migrate_hero_level_caps(profile)
            from inventory_locks import migrate_preset_locks
            migrate_preset_locks(profile)
            self._normalize_available_culture(profile)
            self._normalize_profile_equips(profile)
            result = change(profile) or {}
            self._normalize_profile_equips(profile)
            if not isinstance(result, dict): self._fail("InvalidMutation", "Roster handler must return response fields")
            return profile, {**profile, **result}
        answer, replayed = self.store.atomic_update(uid, mutate, idempotency_key=key, request_payload=params if key else None)
        if not isinstance(answer, dict):
            self._fail("StorageError", "Profile transaction returned an invalid result")
        # RPC responders read updated fields directly from the return object.
        return {**answer, "replayed": bool(replayed)}

    def _write_raw(self, uid, method, params, change):
        """Commit an RPC whose native response data is a scalar or array."""
        action = params.get("actionID") if isinstance(params, dict) else None
        key = f"{method}:{action}" if isinstance(action, (str, int)) else None
        def mutate(profile):
            preserve_mod_hero_sequence(profile, self.full_config)
            # Morphing must not rewrite historical level/XP already present
            # on the transformed hero. Other raw growth/sale requests still
            # run the normal roster-cap migration.
            if method != "user.morph":
                self._migrate_hero_level_caps(profile)
            self._normalize_available_culture(profile)
            self._normalize_profile_equips(profile)
            result = change(profile)
            self._normalize_profile_equips(profile)
            return profile, result
        answer, _replayed = self.store.atomic_update(
            uid, mutate, idempotency_key=key,
            request_payload=params if key else None,
        )
        return answer

    def _normalize_available_culture(self, profile):
        missing = {key: copy.deepcopy(hero) for key, hero in profile.get("avatars", {}).items()
                   if mod_runtime(self.full_config) and not hero_available(self.full_config, hero.get("aid", key))}
        changed = normalize_culture_profile(profile, self.full_config.get("cfg", self.full_config))
        profile.get("avatars", {}).update(missing)
        return changed

    def _normalize_profile_equips(self, profile):
        equips = profile.get("my_equips", {}) if isinstance(profile, dict) else {}
        if not isinstance(equips, dict):
            return False
        changed = False
        attrs = profile.get("attrs", {}) if isinstance(profile, dict) else {}
        pending = attrs.get("equip_wash") if isinstance(attrs, dict) else None
        roll_policy = self.simple.get("equipment_roll_policy", {}) if isinstance(self.simple, dict) else {}
        exclusive_ids = set(roll_policy.get("exclusive_ids", [])) if isinstance(roll_policy, dict) else set()
        for eqid, item in equips.items():
            if not isinstance(item, dict):
                continue
            old_attrs = item.get("new_4attrs")
            flat_present = any(key in item for key in ("hit", "flee", "crit", "tough"))
            if not isinstance(old_attrs, dict) or flat_present:
                self._normalize_equip_attrs(item)
                changed = True
            definition = self.equipment.get(item.get("eid"), {})
            is_book = isinstance(definition, dict) and int(definition.get("type", 0) or 0) == 6
            pl = definition.get("pl", []) if isinstance(definition, dict) else []
            pair = tuple(v for v in pl[6:8] if v in ("hit", "tough", "crit", "flee")) if len(pl) >= 8 else ()
            pending_for_item = isinstance(pending, dict) and pending.get("eqid") == eqid
            if not is_book and not pending_for_item and len(pair) == 2 and migrate_item_wash(item, pair):
                changed = True
            if not is_book and len(pair) == 2 and pair[0] != pair[1]:
                try:
                    migrated = int(item.get("wash_schema_version", 0) or 0) >= 1
                    cfg = self.simple.get("equip_config", [])
                    cap = max(0, int(cfg[3]) * self._equip_star(item) * max(1, int(item.get("lv", 1))))
                except (TypeError, ValueError, IndexError, GameplayFault):
                    migrated = False
                if migrated:
                    values = item.get("new_4attrs", {})
                    bounded = bounded_wash_values(values, pair, cap)
                    if bounded != values:
                        item.setdefault("wash_repair_original_v1", copy.deepcopy(values))
                        item["new_4attrs"] = bounded
                        changed = True
                    if pending_for_item and isinstance(pending.get("rolled"), dict):
                        remaining = max(0, cap - sum(bounded.values()))
                        rolled = bounded_wash_values(pending["rolled"], pair, remaining)
                        if rolled != pending["rolled"]:
                            pending.setdefault("wash_repair_original_v1", copy.deepcopy(pending["rolled"]))
                            pending["rolled"] = rolled
                            changed = True
            eid = item.get("eid")
            if is_book:
                if item.get("stat_roll_ppm") != 1_000_000:
                    item["stat_roll_ppm"] = 1_000_000
                    changed = True
            elif eid in exclusive_ids:
                if item.get("stat_roll_ppm") != 1_200_000:
                    item["stat_roll_ppm"] = 1_200_000
                    changed = True
            else:
                try:
                    saved_roll = int(item.get("stat_roll_ppm"))
                except (TypeError, ValueError, OverflowError):
                    saved_roll = 0
                if not 850_000 <= saved_roll <= 1_150_000:
                    item["stat_roll_ppm"] = (roll_for_new_item(self.rng, False)
                                              if "stat_roll_ppm" not in item else 1_000_000)
                    changed = True
            if item.get("equipment_v2_version") != 1:
                item["equipment_v2_version"] = 1
                changed = True
        return changed

    def _hero(self, p, key):
        key = self._id(key, "aid")
        heroes = p.setdefault("avatars", {})
        if key in heroes:
            if mod_runtime(getattr(self, "full_config", {})):
                ensure_available(self.full_config, heroes[key].get("aid", key))
            return key, heroes[key]
        matches = [(k, v) for k, v in heroes.items() if v.get("aid", "").split("|")[0] == key.split("|")[0]]
        if len(matches) == 1:
            if mod_runtime(getattr(self, "full_config", {})):
                ensure_available(self.full_config, matches[0][1].get("aid", matches[0][0]))
            return matches[0]
        self._fail("UnknownHero", "Hero does not belong to this account")

    def _equip(self, p, key):
        key = self._id(key, "eqid")
        equips = p.setdefault("my_equips", {})
        if key not in equips:
            self._fail("UnknownEquipment", "Equipment does not belong to this account")
        item = equips[key]
        self._normalize_equip_attrs(item)
        definition = self.equipment.get(item.get("eid"), {})
        pl = definition.get("pl", []) if isinstance(definition, dict) else []
        is_book = int(definition.get("type", 0)) == 6 if isinstance(definition, dict) else False
        pair = tuple(v for v in pl[6:8] if v in ("hit", "tough", "crit", "flee")) if len(pl) >= 8 else ()
        if not is_book:
            if len(pair) != 2 or pair[0] == pair[1]:
                self._fail("InvalidConfig", f"Equipment {item.get('eid')} has no valid two-attribute wash pair")
            pending = p.get("attrs", {}).get("equip_wash") if isinstance(p.get("attrs"), dict) else None
            if not (isinstance(pending, dict) and pending.get("eqid") == key):
                migrate_item_wash(item, pair)
        if "stat_roll_ppm" not in item:
            policy = self.simple.get("equipment_roll_policy", {})
            exclusive_ids = policy.get("exclusive_ids", []) if isinstance(policy, dict) else []
            item["stat_roll_ppm"] = 1_000_000 if is_book else roll_for_new_item(self.rng, item.get("eid") in exclusive_ids)
        item["equipment_v2_version"] = 1
        return key, item

    @staticmethod
    def _normalize_equip_attrs(item):
        """Migrate legacy flat wash stats to the client's native object."""
        keys = ("hit", "flee", "crit", "tough")
        if not isinstance(item, dict):
            return {key: 0 for key in keys}
        nested = item.get("new_4attrs")
        source = nested if isinstance(nested, dict) else item
        values = {}
        for key in keys:
            try:
                values[key] = int(source.get(key, 0) or 0)
            except (TypeError, ValueError, OverflowError):
                values[key] = 0
        item["new_4attrs"] = values
        # Keep one source of truth in storage and on the native RPC wire.
        for key in keys:
            item.pop(key, None)
        return values

    def _equip_star(self, item):
        try:
            star = int(str(item.get("eid", "")).rsplit("_", 1)[1])
            alchemy = item.get("alchemy", [0, 0])
            return star + (int(alchemy[1]) if isinstance(alchemy, list) and len(alchemy) > 1 else 0)
        except (IndexError, TypeError, ValueError):
            self._fail("InvalidEquipment", "Equipment has an invalid star tier")

    def _equip_alchemy_rate(self, item, column):
        table = self.simple.get("equip_alchemy", {})
        phases = table.get("phase", {}) if isinstance(table, dict) else {}
        if not isinstance(phases, dict):
            self._fail("InvalidConfig", "Missing equipment alchemy phase table")
        alchemy = item.get("alchemy", [0, 0])
        phase = int(alchemy[0]) if isinstance(alchemy, list) and alchemy else 0
        extra = int(alchemy[1]) if isinstance(alchemy, list) and len(alchemy) > 1 else 0
        base_star = int(str(item.get("eid", "")).rsplit("_", 1)[1])
        start, end = f"{base_star}_0", f"{base_star + extra}_{phase}"
        rate = 1.0
        for key, row in phases.items():
            if str(key) > start and str(key) <= end:
                if not isinstance(row, list) or len(row) <= column:
                    self._fail("InvalidConfig", f"Malformed equipment alchemy row: {key}")
                rate *= float(row[column])
        return rate

    def _equip_rise_price(self, item, definition, level):
        prices = self.simple.get("equip_rise_cost") or equipment_upgrade_cost_table()
        if not isinstance(prices, list) or len(prices) <= level or not 1 <= level < MAX_EQUIPMENT_LEVEL:
            self._fail("InvalidConfig", "Equipment rise cost table is incomplete")
        price = prices[level]
        if type(price) is not int or price < 1:
            self._fail("InvalidConfig", "Equipment rise cost is invalid")
        return price

    @staticmethod
    def _equip_to_int(value):
        rounded = Decimal(str(value)).quantize(Decimal("0.00001"), rounding=ROUND_HALF_UP)
        return int(rounded)

    @staticmethod
    def _native_tools_to_int(value):
        """Mirror native Tools.toInt: round to five decimals, then truncate."""
        rounded = Decimal(str(value)).quantize(Decimal("0.00001"), rounding=ROUND_HALF_UP)
        return int(rounded)

    def _equip_sell_rewards(self, item):
        """Mirror Equip.getSellGold/getSellMark/getSellDust for panel previews."""
        definition = self.equipment.get(item.get("eid"), {})
        cfg = self.simple.get("equip_config", [])
        if not isinstance(cfg, list) or len(cfg) <= 10:
            self._fail("InvalidConfig", "Equipment sale configuration is incomplete")
        if str(item.get("eid", "")).find("E_6") >= 0:
            book = self.simple.get("skill_book_exp", [])
            if not isinstance(book, list) or len(book) <= 6:
                self._fail("InvalidConfig", "Skill-book sale configuration is incomplete")
            lv = max(1, int(item.get("slv", 1)))
            a, b, c = map(float, book[:3])
            d0 = float(definition.get("d0", 0))
            recovered_exp = d0 * (a / 3 * lv ** 3 + (b - a) / 2 * lv ** 2 + (a / 6 - b / 2 + c) * lv - c)
            gold = (recovered_exp + max(0, int(item.get("sexp", 0)))) * float(book[6]) + float(definition.get("offerGold", 0))
        else:
            level = max(1, int(item.get("lv", 1)))
            recovered = sum(self._equip_rise_price(item, definition, lv) for lv in range(level - 1, 0, -1))
            gold = recovered * float(cfg[6]) + float(definition.get("gold", 0))
        attrs = item.get("new_4attrs", {}) if isinstance(item.get("new_4attrs"), dict) else item
        attrs_total = sum(int(attrs.get(k, 0)) for k in ("hit", "flee", "crit", "tough"))
        star = self._equip_star(item)
        mark = int(attrs_total / float(cfg[10]) * star * float(cfg[7])) if float(cfg[10]) else 0

        dust = [0, 0, 0, 0]
        offset = star - 3
        equip_type = int(definition.get("type", 0))
        dust_type = 0 if equip_type == 1 else equip_type - 2
        tear = self.simple.get("dust", {}).get("tear", [])
        if 0 <= dust_type < len(tear) and offset >= 0:
            row = tear[dust_type]
            if offset < 4:
                dust[offset] += int(row[offset])
            elif offset < len(row) and isinstance(row[offset], list):
                bonus = row[offset]
                if bonus:
                    dust[2] += int(bonus[0])
                if len(bonus) > 1:
                    dust[3] += int(bonus[1])
        magic = item.get("magic", [0, 0, 0, 0])
        dust_return = float(self.simple.get("dust", {}).get("return", 0))
        for idx in range(min(4, len(magic)) if isinstance(magic, list) else 0):
            dust[idx] += math.ceil(int(magic[idx]) * dust_return)
        # These getters return AS `int` directly, unlike getRiseGold which
        # explicitly calls Tools.toInt (five-decimal rounding).
        return int(gold), mark, dust

    def _equip_wash_halo(self, item, count, kind):
        cfg = self.simple.get("equipwash", [])
        if not isinstance(cfg, list) or len(cfg) < 6:
            self._fail("InvalidConfig", "Equipment wash progression configuration is incomplete")
        old_halo = item.get("halo", {}) if isinstance(item.get("halo"), dict) else {}
        level = max(0, int(old_halo.get("lv", item.get("haloLv", 0))))
        exp = max(0, int(old_halo.get("exp", item.get("haloExp", 0))))
        cap = max(0, int(cfg[5]))
        if level >= cap:
            return {"lv": cap, "exp": 0}
        exp += int(cfg[3 if kind == "coin" else 2]) * count
        if self.simple.get("wash_halo_curve"):
            item_level = max(1, int(item.get("lv", 1)))
            threshold = lambda lv: halo_rank_threshold(self.simple, item_level, lv)
        elif self.simple.get("wash_halo_sync"):
            item_level = max(1, int(item.get("lv", 1)))
            potential = int(self.simple["equip_config"][3]) * item_level
            attempts = math.ceil(potential / max(5, item_level // 10))
            threshold = lambda lv: max(1, math.ceil(attempts / max(1, cap)))
        else:
            threshold = lambda lv: int(float(cfg[0]) * (float(cfg[1]) ** lv) * self._equip_star(item))
        while level < cap and exp >= threshold(level):
            exp -= threshold(level)
            level += 1
        if level >= cap:
            return {"lv": cap, "exp": 0}
        return {"lv": level, "exp": exp}

    def _hero_is_placed(self, p, hero_id):
        """Return whether a hero is assigned to any persistent or active lineup.

        The original sell/growth selectors treat these as protected inventory:
        every saved squad, destiny node, the PvP defense squad, active
        exploration army, and in-flight battle snapshot. Expedition and other
        temporary selection lists are protected while their intent is active.
        """
        def contains(value):
            if isinstance(value, str):
                return value == hero_id
            if isinstance(value, dict):
                return any(contains(v) for v in value.values())
            if isinstance(value, (list, tuple)):
                return any(contains(v) for v in value)
            return False

        if contains(p.get("team", [])):
            return True
        attrs = p.get("attrs", {}) if isinstance(p.get("attrs"), dict) else {}
        if contains(attrs.get("defensive_squad", [])):
            return True
        if contains(p.get("pending_battles", {})):
            return True
        if self._hero_is_in_active_pve(p, hero_id):
            return True
        # Exploration keeps its selected army in the profile between floors,
        # with hero IDs as dictionary keys.  It remains an assigned lineup
        # until the player submits a replacement army.
        exploration = p.get("exploration", {})
        army = exploration.get("army", {}) if isinstance(exploration, dict) else {}
        if isinstance(army, dict) and hero_id in army:
            try:
                stage = int(exploration.get("stage", 1))
                stage_count = len(exploration_stages(self.full_config))
                reward_pending = int(exploration.get("current_stage_finish", 0)) == 1
            except (GameplayFault, TypeError, ValueError, OverflowError):
                # Keep protection when config or state is malformed; only an
                # explicitly completed, valid exploration sentinel is inactive.
                return True
            if stage <= stage_count or reward_pending:
                return True
        return False

    def _hero_is_in_active_pve(self, p, hero_id):
        """Check the exact owned instance in a live legacy mainline intent."""
        now = self.store.clock.now()
        pending_pve = p.get("pending_pve", {})
        if isinstance(pending_pve, dict):
            for pending in pending_pve.values():
                if not isinstance(pending, dict) or pending.get("settled"):
                    continue
                try:
                    if int(pending.get("expires", 0)) < now:
                        continue
                except (TypeError, ValueError, OverflowError):
                    continue
                team_a = pending.get("team_a", [])
                if isinstance(team_a, list) and any(
                    isinstance(unit, dict)
                    and (unit.get("instance_id") == hero_id or unit.get("id") == hero_id)
                    for unit in team_a
                ):
                    return True
        return False

    def _in_team(self, p, hero_id):
        def contains_id(value):
            if isinstance(value, str): return value == hero_id
            if isinstance(value, (list, tuple)): return any(contains_id(v) for v in value)
            return False
        return any(contains_id(team) for team in p.get("team", []))

    def _check_not_team(self, p, hero_id):
        if self._hero_is_placed(p, hero_id):
            self._fail("HeroInTeam", "Remove the hero from all teams first")

    def _check_not_dn(self, p, hero_id):
        # Native getStarUpItems/getPhaseUpItems omit heroes currently assigned
        # to a destiny node. Reject forged RPCs the same way so a bound hero
        # cannot be consumed while the client still treats it as assigned.
        dn = self._normalize_dn(p)
        if any(isinstance(node, list) and len(node) > 1 and node[1] == hero_id
               for node in dn.values()):
            self._fail("HeroInDestiny", "Remove the hero from its destiny node first")

    def _culture_cap(self, hero):
        if weighted_culture_active(self.simple, hero):
            return weighted_culture_cap(hero, self.simple)
        culture = self.simple.get("culture", {}) if isinstance(self.simple, dict) else {}
        base = max(0, int(culture.get("max_pith_base", 0)))
        absolute = max(0, int(culture.get("max_pith", base)))
        bonus = max(0, int(hero.get("pith_max", 0) or 0))
        return min(absolute, base + bonus)

    def _culture_pith(self, hero):
        if weighted_culture_active(self.simple, hero):
            return weighted_culture_used(hero, self.simple)
        return sum(max(0, int(hero.get(key, 0) or 0)) for key in ("hp", "ap", "de_ph", "de_ma"))

    def _clamp_culture_roll(self, hero, roll):
        """Clamp only the new positive roll to remaining native pith capacity.

        Existing over-cap profiles are preserved; no old stat is reduced.
        Stat insertion order matches the client display/save field order.
        """
        if weighted_culture_active(self.simple, hero):
            return clamp_weighted_culture_gain(hero, roll, self.simple)
        cap = self._culture_cap(hero)
        remaining = max(0, cap - self._culture_pith(hero))
        amounts = {}
        for key in ("hp", "ap", "de_ph", "de_ma"):
            try: amount = max(0, int(roll.get(key, 0)))
            except (TypeError, ValueError): amount = 0
            amounts[key] = amount
        total = sum(amounts.values())
        if total <= remaining:
            return amounts
        clamped = {key: amount * remaining // total for key, amount in amounts.items()}
        left = remaining - sum(clamped.values())
        order = sorted(amounts, key=lambda key: amounts[key] * remaining % total, reverse=True)
        for key in order[:left]:
            clamped[key] += 1
        return clamped

    def _feed_cultivation(self, target, materials):
        """Apply PanelBetterSelect's pith allocation and same-family cap gain.

        The client sums the four raw cultivation fields from selected materials,
        expands the target's cap from same-family materials, then retains at
        most the target's remaining capacity using its two-pass allocation.
        Values stored on Avatar are raw points; culture_pith is display scale.
        """
        keys = ("hp", "ap", "de_ph", "de_ma")
        if weighted_culture_active(self.simple, target):
            sources = []
            for material in materials:
                aid = str(material.get("aid", "")).split("|", 1)[0]
                row = self.heroes.get(aid)
                if not isinstance(row, dict):
                    self._fail("InvalidMaterials", "Cultivation material has no avatar configuration")
                sources.append((material, row))
            feed_weighted_culture(target, sources, self.simple)
            return {key: target[key] for key in keys}
        # Old 2-4-star targets retain raw-point allocation. A new weighted
        # material holds actual stat gains, so convert it conservatively to
        # this target's old raw-point scale before the original two-pass rule.
        if any(material.get("culture_schema") == WEIGHTED_CULTURE_SCHEMA for material in materials):
            target_aid = str(target.get("aid", "")).split("|", 1)[0]
            target_row = self.heroes.get(target_aid)
            if not isinstance(target_row, dict):
                self._fail("InvalidTarget", "Cultivation target has no avatar configuration")
            converted = []
            for material in materials:
                if material.get("culture_schema") == WEIGHTED_CULTURE_SCHEMA:
                    source_aid = str(material.get("aid", "")).split("|", 1)[0]
                    source_row = self.heroes.get(source_aid)
                    if not isinstance(source_row, dict):
                        self._fail("InvalidMaterials", "Cultivation material has no avatar configuration")
                    actual = culture_actual_material_gain(material, source_row, self.simple)
                    item = dict(material)
                    item.update(culture_actual_to_legacy_raw(actual, target_row, self.simple))
                    converted.append(item)
                else:
                    converted.append(material)
            materials = converted
        totals = [sum(max(0, int(material.get(key, 0) or 0)) for material in materials)
                  for key in keys]
        culture = self.simple.get("culture", {}) if isinstance(self.simple, dict) else {}
        base = max(0, int(culture.get("max_pith_base", 0) or 0))
        absolute = max(base, int(culture.get("max_pith", base) or base))
        old_bonus = max(0, int(target.get("pith_max", 0) or 0))
        cap_bonus_room = max(0, absolute - base - old_bonus)
        requested_bonus = 0
        target_family = str(target.get("aid", "")).split("|")[0].split("_")
        target_family = target_family[1] if len(target_family) > 2 else ""
        for material in materials:
            material_aid = str(material.get("aid", "")).split("|")[0]
            parts = material_aid.split("_")
            if len(parts) < 3 or parts[1] != target_family:
                continue
            try: star = int(parts[-1])
            except ValueError: continue
            if star < 2:
                continue
            increments = culture.get("pith_limit_add", [])
            if isinstance(increments, list) and star < len(increments):
                try: requested_bonus += max(0, int(increments[star] or 0))
                except (TypeError, ValueError): pass
        bonus = min(requested_bonus, cap_bonus_room)
        current_max = min(absolute, base + old_bonus)
        room = max(0, current_max - sum(max(0, int(target.get(key, 0) or 0)) for key in keys) + bonus)

        # Exact two-pass behavior from PanelBetterSelect: first reserve up to
        # ceil(room/4) in each stat, then distribute any unused remainder in
        # field order. This yields gains = source totals - remaining totals.
        remaining = totals[:]
        available = room
        per_stat = math.ceil(available / 4) if available else 0
        for index in range(4):
            if available <= 0: break
            if remaining[index] > per_stat:
                remaining[index] -= per_stat
                available -= per_stat
            else:
                available -= remaining[index]
                remaining[index] = 0
        for index in range(4):
            if available <= 0: break
            if remaining[index] > available:
                remaining[index] -= available
                available = 0
                break
            available -= remaining[index]
            remaining[index] = 0
        gains = [totals[i] - remaining[i] for i in range(4)]
        for key, gain in zip(keys, gains):
            target[key] = max(0, int(target.get(key, 0) or 0)) + gain
        if bonus:
            target["pith_max"] = old_bonus + bonus
        return {key: target[key] for key in keys} | ({"pith_max": target["pith_max"]} if "pith_max" in target else {})

    def _cost(self, p, cost):
        for k, amount in cost.items():
            if k == "dust" or k == "sp":
                vec = p.setdefault("attrs", {}).setdefault(k, [0, 0, 0, 0])
                if not isinstance(vec, list): vec = [vec, 0, 0, 0]; p["attrs"][k] = vec
                if isinstance(amount, list):
                    for i, n in enumerate(amount[:4]):
                        if i >= len(vec) or vec[i] < n: self._fail("InsufficientResource", f"Not enough {k}")
                    for i, n in enumerate(amount[:4]): vec[i] -= n
                else:
                    if vec[0] < amount: self._fail("InsufficientResource", f"Not enough {k}")
                    vec[0] -= amount
            elif k in self.ATTRS:
                attrs = p.setdefault("attrs", {})
                if attrs.get(k, 0) < amount: self._fail("InsufficientResource", f"Not enough {k}")
                attrs[k] -= amount
            else:
                if p.get(k, 0) < amount: self._fail("InsufficientResource", f"Not enough {k}")
                p[k] -= amount

    def _refund(self, p, reward):
        currency = {k: int(v) for k, v in reward.items() if k in self.CURRENCY}
        attrs = {k: v for k, v in reward.items() if k in self.ATTRS}
        payload = dict(currency)
        if attrs: payload["attrs"] = attrs
        if payload: grant_reward(p, payload, self.full_config)

    def _normalize_dn(self, profile):
        """Migrate early dict-shaped reconstruction nodes to the client's [lv, aid] rows."""
        attrs = profile.setdefault("attrs", {})
        cfg = self.simple.get("dn", {}) if isinstance(self.simple, dict) else {}
        stored = attrs.get("dn")
        if not isinstance(stored, dict): stored = {}
        normalized = {}
        for key, value in stored.items():
            key = str(key)
            if key not in cfg: continue
            if isinstance(value, list):
                try: level = max(1, int(value[0]))
                except (IndexError, TypeError, ValueError): level = 1
                aid = value[1] if len(value) > 1 and isinstance(value[1], str) and value[1] in profile.get("avatars", {}) else None
                normalized[key] = [level, aid]
            elif isinstance(value, dict) and value.get("unlocked"):
                try: level = max(1, int(value.get("lv", 1)))
                except (TypeError, ValueError): level = 1
                aid = value.get("aid") if isinstance(value.get("aid"), str) and value.get("aid") in profile.get("avatars", {}) else None
                normalized[key] = [level, aid]
        attrs["dn"] = normalized
        return normalized

    def _dn_config_row(self, key):
        rows = self.simple.get("dn", {}) if isinstance(self.simple, dict) else {}
        row = rows.get(str(key)) if isinstance(rows, dict) else None
        if not isinstance(row, list) or len(row) < 8:
            self._fail("InvalidConfig", f"Missing DN config row: {key}")
        return row

    def _team_response(self, p):
        groups = p.setdefault("as_equips", [[] for _ in range(6)])
        while len(groups) < 6: groups.append([])
        for i in range(6):
            if not isinstance(groups[i], list): groups[i] = []
            groups[i] = (groups[i] + [None] * 6)[:6]
        teams = p.setdefault("team", [[], [], []])
        if not isinstance(teams, list): teams = []
        normalized = []
        for i in range(3):
            row = teams[i] if i < len(teams) and isinstance(teams[i], list) else []
            row = [None if member in (None, "") else member for member in row[:6]]
            normalized.append(row + [None] * (6 - len(row)))
        p["team"] = normalized
        return p

    def _validate_dn_assignment(self, p, submitted, main_team):
        """Validate the native ``fix_team`` destiny snapshot without trusting it.

        The client sends the complete unlocked-node map alongside team changes.
        Node levels are server-owned; this endpoint may only change each node's
        optional hero binding.  A missing ``dn`` field remains compatible with
        older callers and preserves the stored bindings.
        """
        current = self._normalize_dn(p)
        if submitted is None:
            candidate = copy.deepcopy(current)
        else:
            if not isinstance(submitted, dict):
                self._fail("InvalidDN", "Destiny formation must be an object")
            if set(map(str, submitted.keys())) != set(current.keys()):
                self._fail("InvalidDN", "Destiny formation contains locked or missing nodes")
            candidate = {}
            bound = set()
            for raw_key, raw_node in submitted.items():
                key = str(raw_key)
                old_node = current.get(key)
                if not isinstance(raw_node, list) or len(raw_node) < 2:
                    self._fail("InvalidDN", "Destiny node must contain level and hero")
                level = self._num(raw_node[0], "destiny node level", 1, int(self.simple.get("dn_lv", 50)))
                if not isinstance(old_node, list) or level != int(old_node[0]):
                    self._fail("InvalidDN", "Destiny node level cannot be changed in formation")
                raw_aid = raw_node[1]
                aid = None
                if raw_aid not in (None, ""):
                    bound_hero = p.get("avatars", {}).get(raw_aid) if isinstance(raw_aid, str) else None
                    retained_missing = (raw_aid == old_node[1] and isinstance(bound_hero, dict)
                                        and mod_runtime(self.full_config)
                                        and not channel_enabled(self.full_config, bound_hero.get("aid", raw_aid), "usage.auxiliary_formation"))
                    if retained_missing:
                        aid = raw_aid
                    else:
                        aid, bound_hero = self._hero(p, raw_aid)
                        ensure_channel(self.full_config, bound_hero.get("aid", aid), "usage.auxiliary_formation")
                    if aid in bound:
                        self._fail("InvalidDN", "A hero cannot occupy multiple destiny nodes")
                    bound.add(aid)
                candidate[key] = [level, aid]

        bound = {node[1] for node in candidate.values()
                 if isinstance(node, list) and len(node) > 1 and node[1] is not None}
        if any(hero_id in bound for hero_id in main_team if hero_id is not None):
            self._fail("InvalidDN", "A destiny hero cannot also occupy the main squad")
        p.setdefault("attrs", {})["dn"] = candidate
        return candidate

    def dispatch(self, uid, method, params):
        if method not in self.HERO_METHODS: self._fail("NotImplemented", f"Method not reconstructed: {method}")
        if not isinstance(params, dict): self._fail("InvalidParameter", "Expected an object")
        if method == "user.morph": self._fail("MorphNotOpen", "转化功能尚未开放")
        if method == "user.get_avatar_talent": return self._get_avatar_talent(uid, method, params)
        if method == "user.get_newzone_ranks": return self._get_newzone_ranks(uid)
        raw_methods = {
            "user.sell_avatars", "user.swallow_avatar", "user.swallow_skillbook",
            "user.star_up", "user.phase_up", "user.morph", "user.equip_rise",
            "user.equip_wash", "user.add_magic", "user.equip_rune_up", "user.equip_sell",
            "user.equip_alchemy", "user.wager_avatar",
        }
        if method in raw_methods:
            change = (lambda p: self._sell_avatars(p, params)) if method == "user.sell_avatars" else (lambda p: self._mutate(p, method, params))
            return self._write_raw(uid, method, params, change)
        if method in ("user.equip_wash_cancel", "user.avatar_culture_cancel", "user.save_talent", "user.equip_wash_save", "user.avatar_culture_save"):
            if method in ("user.equip_wash_save", "user.avatar_culture_save", "user.save_talent"):
                return self._write_raw(uid, method, params, lambda p: self._staged(p, method, params))
            return self._write(uid, method, params, lambda p: self._staged(p, method, params))
        return self._write(uid, method, params, lambda p: self._mutate(p, method, params))

    def _staged(self, p, method, params):
        attrs = p.setdefault("attrs", {})
        if method == "user.equip_wash_cancel":
            pending = attrs.pop("equip_wash", None)
            if isinstance(pending, dict) and pending.get("eqid") in p.get("my_equips", {}):
                item = p["my_equips"][pending["eqid"]]
                definition = self.equipment.get(item.get("eid"), {})
                pl = definition.get("pl", []) if isinstance(definition, dict) else []
                pair = tuple(v for v in pl[6:8] if v in ("hit", "tough", "crit", "flee")) if len(pl) >= 8 else ()
                if len(pair) == 2:
                    migrate_item_wash(item, pair)
            # The client charges the roll when it is made; cancel discards the
            # proposed bonuses but retains the already-earned halo experience.
            return {"attrs": attrs}
        if method == "user.equip_wash_save":
            pending = attrs.get("equip_wash")
            if not pending: self._fail("NoPendingWash", "No equipment wash is awaiting confirmation")
            eqid, item = self._equip(p, pending["eqid"])
            item = p["my_equips"][eqid]
            definition = self.equipment.get(item.get("eid"), {})
            pl = definition.get("pl", []) if isinstance(definition, dict) else []
            pair = tuple(v for v in pl[6:8] if v in ("hit", "tough", "crit", "flee")) if len(pl) >= 8 else ()
            if len(pair) != 2:
                self._fail("InvalidConfig", "Equipment wash pair is invalid")
            try:
                needs_wash_migration = int(item.get("wash_schema_version", 0) or 0) < 1
            except (TypeError, ValueError, OverflowError):
                needs_wash_migration = True
            if needs_wash_migration:
                migrate_pending_save(item, pending, pair)
            else:
                values = self._normalize_equip_attrs(item)
                cfg = self.simple.get("equip_config", [])
                cap = max(0, int(cfg[3]) * self._equip_star(item) * max(1, int(item.get("lv", 1))))
                gain = bounded_wash_values(pending.get("rolled", {}), pair,
                                           max(0, cap - sum(values.values())))
                for key in pair:
                    values[key] += gain[key]
                item["new_4attrs"] = values
            cfg = self.simple.get("equip_config", [])
            cap = max(0, int(cfg[3]) * self._equip_star(item) * max(1, int(item.get("lv", 1))))
            bounded = bounded_wash_values(item["new_4attrs"], pair, cap)
            if bounded != item["new_4attrs"]:
                item.setdefault("wash_repair_original_v1", copy.deepcopy(item["new_4attrs"]))
                item["new_4attrs"] = bounded
            attrs.pop("equip_wash", None)
            halo = item.get("halo") if isinstance(item.get("halo"), dict) else None
            if halo:
                # Equip.init consumes the nested `halo` object on the native
                # callback/login path. Keep that canonical value and mirror
                # its scalar fields for older server helpers that still read
                # haloLv/haloExp.
                item["haloLv"], item["haloExp"] = halo["lv"], halo["exp"]
            return copy.deepcopy(item)
        if method == "user.avatar_culture_cancel":
            pending = attrs.pop("avatar_culture", None)
            # Cultivation attempts consume their price when rolled. Cancel only
            # discards the pending stat gains, matching the original panel.
            return {"attrs": attrs}
        if method == "user.avatar_culture_save":
            pending = attrs.pop("avatar_culture", None)
            if not pending: self._fail("NoPendingCulture", "No cultivation is awaiting confirmation")
            _, hero = self._hero(p, pending.get("aid", pending.get("eqid")))
            rolled = pending.get("rolled", pending.get("save_status", {}))
            # Historical pending rolls were not capped. Apply only their
            # already-paid incremental stat gain once, even if the new cap is
            # below the migrated old balance. New rolls obey remaining room.
            if (weighted_culture_active(self.simple, hero)
                    and pending.get("schema") == WEIGHTED_CULTURE_SCHEMA
                    and isinstance(pending.get("legacy_rolled_raw"), dict)):
                accepted = {key: max(0, int(rolled.get(key, 0) or 0))
                            for key in ("hp", "ap", "de_ph", "de_ma")}
            else:
                accepted = self._clamp_culture_roll(hero, rolled if isinstance(rolled, dict) else {})
            for key, amount in accepted.items():
                hero[key] = max(0, int(hero.get(key, 0) or 0)) + amount
            if (weighted_culture_active(self.simple, hero)
                    and pending.get("schema") == WEIGHTED_CULTURE_SCHEMA
                    and isinstance(pending.get("rolled_raw"), dict)):
                progress = hero.get("culture_roll_raw")
                if not isinstance(progress, dict):
                    progress = {key: 0 for key in ("hp", "ap", "de_ph", "de_ma")}
                hero["culture_roll_raw"] = {
                    key: max(0, int(progress.get(key, 0) or 0))
                         + max(0, int(pending["rolled_raw"].get(key, 0) or 0))
                    for key in ("hp", "ap", "de_ph", "de_ma")
                }
            # Native callback iterates param.data and merges these stat keys into the hero.
            return {"hp": hero.get("hp", 0), "ap": hero.get("ap", 0),
                    "de_ph": hero.get("de_ph", 0), "de_ma": hero.get("de_ma", 0)}
        # save_talent is a two-phase panel API: is_save=true commits; otherwise cancel.
        talent = attrs.pop("pending_talent", None) or attrs.pop("avatar_talent", None)
        attrs.pop("avatar_talent", None)
        if params.get("is_save") is True:
            if (not isinstance(talent, dict)
                    or not isinstance(talent.get("aid"), str) or not talent.get("aid")
                    or not isinstance(talent.get("id"), str) or not talent.get("id")):
                self._fail("NoPendingTalent", "没有待确认的天赋选择")
            _, hero = self._hero(p, talent["aid"])
            hero["talent"] = talent["id"]
            return {"avatar": {"talent": hero["talent"]}}
        # The client spends this point when opening the chooser, so cancel keeps that cost.
        if talent: pass
        return {"avatars": p.get("avatars", {}), "attrs": attrs}

    def _get_newzone_ranks(self, uid):
        """Return local NPC leaderboards in PanelActivityRankList's [uid,name,vip,score] schema."""
        from gameplay_competition import GameplayCompetition
        from bot_names import bot_name_for_uid

        profile = self._profile(uid)
        competition_path = __import__("pathlib").Path(__file__).resolve().parents[1] / "config/reconstruction/competition-config.json"
        competition = json.loads(competition_path.read_text(encoding="utf-8")) if competition_path.exists() else {}
        bots = competition.get("pvp_bots", [])
        name = str(profile.get("name") or "测试玩家")
        player_uid = str(profile.get("uid", uid))
        attrs = profile.get("attrs", {})
        records = profile.get("records", {})
        competition_power = GameplayCompetition(self.store, self.full_config)
        bot_powers = {}

        def player_power():
            team = profile.get("team", [])
            selected = team[0] if isinstance(team, list) and team and isinstance(team[0], list) else []
            if not selected:
                return 0
            # Rank-list power must use the same owned lineup and native power
            # calculation as arena previews, including gear, DN, skills and
            # captain/talent multipliers. Keep original slots: only slot zero
            # receives the leader skill in Avatar.getTeamPower.
            from battle_engine import serialize_player_team
            submitted = [[iid, slot % 3, 0.2] if isinstance(iid, str) and iid else None
                         for slot, iid in enumerate(selected[:6])]
            try:
                units = serialize_player_team(self.full_config.get("cfg", self.full_config),
                                              profile, 0, submitted, self.battle_attributes)
            except (GameplayFault, TypeError, ValueError):
                return 0
            return competition_power._team_power(units)

        def bot_power(bot):
            bot_uid = str(bot.get("uid", ""))
            if bot_uid not in bot_powers:
                # Arena previews and fights apply authored gear, advancement
                # and stable NPC progression before evaluating native power.
                bot_powers[bot_uid] = competition_power._team_power(competition_power._bot_units(bot))
            return bot_powers[bot_uid]

        def score_for(kind, level, rank=0, bot=None):
            key = str(kind).lower()
            if "pay" in key or "consume" in key or "spend" in key:
                return int((bot or {}).get("spend_total", 1000 // max(1, rank))) if bot else int(attrs.get("spend_total", attrs.get("pay_total", 0)))
            if "fight" in key or "combat" in key or "pvp" in key:
                if bot:
                    return int(bot.get("pvp_count", max(0, 20 - rank))) * 100 + max(0, 10000 - int(bot.get("pvp_rank", rank * 100)))
                return int(attrs.get("pvp_count", 0)) * 100 + max(0, 10000 - int(attrs.get("pvp_rank", 99999)))
            if "level" in key or key in ("lv", "growth"):
                return int(level)
            if "power" in key:
                return bot_power(bot) if bot else player_power()
            return int(level) * 1000 + max(0, 1000 - int(rank))

        rank_ids = {"level", "power", "consume", "spend", "pvp"}
        gift_rows = self.rank_config.get("gift", {}) if isinstance(self.rank_config, dict) else {}
        if isinstance(gift_rows, dict):
            rank_ids.update(str(k) for k in gift_rows if k != "rank_sort")
            rank_ids.update(str(k) for k in gift_rows.get("rank_sort", []) if isinstance(gift_rows.get("rank_sort"), list))
        result = {}
        for rank_id in sorted(rank_ids):
            entries = []
            for idx, bot in enumerate(bots):
                level = int(bot.get("lv", 1))
                bot_uid = str(bot.get("uid", f"localrank_{idx+1:03d}"))
                entries.append([bot_uid, bot_name_for_uid(bot_uid), int(bot.get("vip_lv", 0)), score_for(rank_id, level, int(bot.get("rank", idx+1)), bot)])
            level = int(profile.get("lv", 1))
            entries.append([player_uid, name, int(profile.get("vip_lv", 0)), score_for(rank_id, level)])
            entries.sort(key=lambda row: (-int(row[3]), str(row[0])))
            result[rank_id] = entries[:100]
        return result

    def _get_avatar_talent(self, uid, method, params):
        # The six native radio options map directly to attrs.sp[0..5] and
        # talent ranks 2..7. talent_config is the authoritative per-color cost.
        aid, sp_index = self._id(params.get("aid"), "aid"), self._num(params.get("sp_index"), "sp_index", 0, 5)
        def change(p):
            hero_id, hero = self._hero(p, aid)
            attrs = p.setdefault("attrs", {})
            vector = attrs.get("sp")
            if not isinstance(vector, list):
                vector = []
                attrs["sp"] = vector
            if len(vector) < 6:
                vector.extend([0] * (6 - len(vector)))
            costs = self.simple.get("talent_config", [])
            if not isinstance(costs, list) or len(costs) < 6:
                self._fail("InvalidConfig", "talent_config must define all six SP costs")
            cost = self._num(costs[sp_index], "talent_cost", 1, 10_000_000)
            if attrs.get("pending_talent"):
                self._fail("PendingOperation", "Finish the current talent choice first")
            if self._num(vector[sp_index], "sp", 0, 10_000_000) < cost:
                self._fail("InsufficientResource", "Not enough talent stones")
            rank = sp_index + 2
            offered = [row for row in self.talents.values()
                       if int(row.get("rank", -1)) == rank and isinstance(row.get("id"), str)]
            offered.sort(key=lambda row: (int(row.get("branch", 0)), row["id"]))
            if not offered:
                self._fail("InvalidConfig", f"No talent candidates for rank {rank}")
            chosen = offered[self.rng.randrange(len(offered))]
            vector[sp_index] -= cost
            spent = [0] * 6
            spent[sp_index] = cost
            pending = {"aid": hero_id, "id": chosen["id"], "spent": {"sp": spent}, "sp_index": sp_index, "cost": cost}
            # Native PanelAvatarTalentAvatar and ItemAvatarTalentSelect parse
            # this as "instance-id`candidate-talent-id". Keep structured data
            # in pending_talent for the server transaction, but expose the
            # exact client string contract in attrs and the RPC response.
            client_pending = f"{hero_id}`{chosen['id']}"
            p["attrs"]["avatar_talent"] = client_pending
            p["attrs"]["pending_talent"] = pending
            return {"avatar_talent": client_pending, "sp": vector, "talent": chosen}
        def mutate(profile):
            result = change(profile)
            return profile, {**profile, **result}
        answer, replayed = self.store.atomic_update(uid, mutate)
        return {**answer, "replayed": bool(replayed)}

    def _sell_avatars(self, p, x):
        aids = x.get("aids", x.get("ids", []))
        if not isinstance(aids, list) or not 1 <= len(aids) <= 100:
            self._fail("InvalidSelection", "Select between one and 100 heroes")
        keys = []
        for aid in aids:
            hid, hero = self._hero(p, aid)
            self._check_not_pending_culture(p, hid)
            if hid in keys: self._fail("InvalidSelection", "Duplicate hero selection")
            if hero.get("lock"):
                self._fail("HeroLocked", "Unlock the hero before selling")
            self._check_not_team(p, hid)
            self._check_not_dn(p, hid)
            keys.append(hid)
        gain = 0
        for hid in keys:
            hero = p["avatars"].pop(hid)
            base = hero.get("aid", hid).split("|")[0]
            cfg = self.heroes.get(base, {})
            gain += max(0, int((cfg.get("tl") or [0] * 8)[7]))
            souls = p.setdefault("avatar_soul", {})
            souls[base] = souls.get(base, 0) + 1
        p["gold"] = p.get("gold", 0) + gain
        # The native response data itself is the new gold balance.
        return p["gold"]

    def _mutate(self, p, m, x):
        if m == 'user.inventory_lock':
            kind, locked = x.get('kind'), x.get('locked')
            if kind not in ('hero', 'equipment') or type(locked) is not bool:
                self._fail('InvalidSelection', 'Lock kind and boolean state are required')
            key = self._id(x.get('id'), 'id')
            field = 'avatars' if kind == 'hero' else 'my_equips'
            if key not in p.get(field, {}):
                self._fail('UnknownHero' if kind == 'hero' else 'UnknownEquipment', 'Inventory instance does not belong to this account')
            key, item = self._hero(p, key) if kind == 'hero' else self._equip(p, key)
            item['lock'] = 1 if locked else 0
            if 'locked' in item:
                item['locked'] = bool(locked)
            return {'id': key, 'kind': kind, 'locked': locked}
        if m in ('user.team_preset_save', 'user.team_preset_load', 'user.team_preset_delete'):
            from team_presets import mutate
            return mutate(self, p, m, x)
        if m == "user.avatar_limit_break":
            pending = p.get("pending_limit_break")
            if not isinstance(pending, dict) or not isinstance(pending.get("candidate_ids"), list):
                self._fail("NoLimitBreakEncounter", "No breakthrough encounter is available")
            requested = self._id(x.get("aid"), "aid")
            candidates = pending["candidate_ids"]
            if requested not in candidates:
                self._fail("InvalidLimitBreakCandidate", "Hero was not offered in this encounter")
            owned = p.get("avatars", {})
            valid = []
            for candidate_id in candidates:
                hero = owned.get(candidate_id) if isinstance(owned, dict) else None
                aid = str(hero.get("aid", candidate_id)).split("|")[0] if isinstance(hero, dict) else ""
                if (isinstance(hero, dict) and aid.startswith("A_1")
                        and aid.rsplit("_", 1)[-1] in ("5", "6")
                        and int(hero.get("lv", 1)) >= 99
                        and not int(hero.get("limit_break", 0) or 0)):
                    valid.append(candidate_id)
            if not valid:
                p.pop("pending_limit_break", None)
                return {"ok": False, "reason": "NoEligibleHero", "pending_limit_break": None}
            if requested not in valid:
                self._fail("InvalidLimitBreakCandidate", "Selected hero is no longer eligible")
            self._hero(p, requested)
            hero = owned[requested]
            hero["limit_break"] = 1
            p.pop("pending_limit_break", None)
            return {"ok": True, "aid": requested, "limit_break_hero": requested,
                    "pending_limit_break": None}
        if m == "user.set_defensive_squad":
            teams = x.get("teams")
            if not isinstance(teams, list) or len(teams) != 3 or any(not isinstance(team, list) or len(team) != 5 for team in teams):
                self._fail("InvalidTeam", "Defense teams must contain three squads of five slots")
            saved = []
            for team in teams:
                row = []
                for member in team:
                    if member in (None, ""):
                        row.append("")
                        continue
                    if not isinstance(member, (list, tuple)) or len(member) < 3:
                        self._fail("InvalidTeam", "Each defense slot must be empty or [hero_id,line,position]")
                    hero_id, _ = self._hero(p, member[0])
                    line = self._num(member[1], "line", 0, 2)
                    position = member[2]
                    if type(position) not in (int, float) or not math.isfinite(position) or position < 0 or position > 1:
                        self._fail("InvalidTeam", "Invalid formation position")
                    row.append([hero_id, line, float(position)])
                saved.append(row)
            attrs = p.setdefault("attrs", {})
            attrs["defensive_squad"] = saved
            records = p.setdefault("records", {})
            return {"attrs": attrs, "server_pvp_num": records.get("server_pvp_num", 0)}
        if m == "user.fix_team":
            team, index = x.get("team"), self._num(x.get("team_num", 0), "team_num", 0, 2)
            if not isinstance(team, list) or len(team) != 3 or any(not isinstance(t, list) or len(t) > 6 for t in team): self._fail("InvalidTeam", "Team must contain three squads of at most six heroes")
            owned = p.get("avatars", {})
            norm = []
            old_teams = p.get("team", [])
            for squad_index, squad in enumerate(team):
                row = []
                for slot_index, hid in enumerate(squad):
                    if hid in (None, ""):
                        row.append(None)
                        continue
                    old = old_teams[squad_index] if squad_index < len(old_teams) and isinstance(old_teams[squad_index], list) else []
                    owned_hero = owned.get(hid) if isinstance(hid, str) else None
                    if (mod_runtime(self.full_config) and slot_index < len(old) and old[slot_index] == hid
                            and isinstance(owned_hero, dict) and not hero_available(self.full_config, owned_hero.get("aid", hid))):
                        row.append(hid)
                    else:
                        key, _ = self._hero(p, hid); row.append(key)
                nonempty = [v for v in row if v is not None]
                if len(set(nonempty)) != len(nonempty): self._fail("DuplicateHero", "A hero cannot occupy two slots in one squad")
                row += [None] * (6 - len(row)); norm.append(row[:6])
            self._team_response(p); p["team"] = norm; p["attrs"]["team_num"] = index
            dn = self._validate_dn_assignment(p, x.get("dn"), norm[0])
            return {"team": norm, "attrs": p["attrs"], "dn": dn}
        if m == "user.equip_dress":
            data = x.get("data")
            if not isinstance(data, list) or len(data) != 6 or any(not isinstance(row, list) or len(row) != 6 for row in data): self._fail("InvalidEquipmentGroup", "Expected six squads with six equipment slots")
            seen = set()
            for si, row in enumerate(data):
                for slot, eqid in enumerate(row):
                    if eqid in (None, ""): continue
                    eqid = self._id(eqid, "equipment instance")
                    eq, item = self._equip(p, eqid)
                    if eq in seen: self._fail("EquipmentInUse", "An item cannot be equipped in two slots")
                    seen.add(eq)
                    eid = item.get("eid")
                    cfg = self.equipment.get(eid, {})
                    gear_type = int(cfg.get("type", 0)) if cfg else 0
                    valid_slots = (0, 1) if gear_type == 1 else (gear_type - 1,)
                    if cfg and slot not in valid_slots: self._fail("WrongEquipmentSlot", "Equipment does not fit this slot")
            self._team_response(p); p["as_equips"] = copy.deepcopy(data)
            return {"as_equips": p["as_equips"], "my_equips": p["my_equips"]}
        if m == "user.equip_rune_up":
            eqid, item = self._equip(p, self._id(x.get("eqid"), "eqid"))
            color = item.get("symp", -1)
            if type(color) is not int or not 0 <= color < 4:
                self._fail("RuneLocked", "Reveal this equipment's elemental rune by enchanting first")
            try:
                level = int(item.get("rune_lv", 0) or 0)
            except (TypeError, ValueError, OverflowError):
                self._fail("InvalidEquipment", "Equipment rune level is invalid")
            max_level = int(self.simple.get("equipment_magic", {}).get("rune_max", 10))
            if level < 0 or max_level < 1 or max_level > 100:
                self._fail("InvalidConfig", "Equipment rune level configuration is invalid")
            if level >= max_level:
                self._fail("RuneAtMaximum", "Equipment rune is already at maximum level")
            dust_cost, mark_cost = equipment_rune_upgrade_cost(self.simple, color, level)
            attrs = p.setdefault("attrs", {})
            dust = attrs.setdefault("dust", [0, 0, 0, 0])
            if not isinstance(dust, list):
                dust = [int(dust), 0, 0, 0]
                attrs["dust"] = dust
            while len(dust) < 4: dust.append(0)
            if int(dust[color]) < dust_cost:
                self._fail("InsufficientResource", "Not enough matching elemental dust")
            self._cost(p, {"mark": mark_cost})
            dust[color] = int(dust[color]) - dust_cost
            item["rune_lv"] = level + 1
            return copy.deepcopy(item)
        if m == "user.add_magic":
            eqid, item = self._equip(p, self._id(x.get("eqid"), "eqid"))
            color = self._num(x.get("color"), "color", 0, 4)
            times = x.get('times', 1)
            if type(times) is not int or times not in (1, 10) or color == 4 and times != 1:
                self._fail('InvalidSelection', 'Elemental magic supports one or ten upgrades')
            dust_cfg = self.simple.get("dust", {})
            costs = ((dust_cfg.get("add_magic") or [[1, 1, 1, 1]])[0])
            caps = dust_cfg.get("max", [100, 100, 100, 100])
            magic = list(item.get("magic") or [0, 0, 0, 0])
            magic = (magic + [0, 0, 0, 0])[:4]
            dust = p.setdefault("attrs", {}).setdefault("dust", [0, 0, 0, 0])
            if not isinstance(dust, list): dust = [int(dust), 0, 0, 0]; p["attrs"]["dust"] = dust
            while len(dust) < 4: dust.append(0)
            if color == 4:
                if any(int(level) <= 0 for level in magic):
                    self._fail("MagicLocked", "Unlock all four elemental stages first")
                if item.get("magic_stage5") == 1:
                    self._fail("MagicAtMaximum", "The fifth enchantment stage is already unlocked")
                stage_cost = self.simple.get("equipment_magic", {}).get("stage5_cost")
                if not isinstance(stage_cost, list) or len(stage_cost) != 4 or any(type(v) is not int or v <= 0 for v in stage_cost):
                    self._fail("InvalidConfig", "Fifth-stage enchantment cost is invalid")
                if any(int(dust[i]) < stage_cost[i] for i in range(4)):
                    self._fail("InsufficientResource", "Not enough elemental dust")
                for i in range(4): dust[i] = int(dust[i]) - stage_cost[i]
                item["magic_stage5"] = 1
                item["symp"] = random.randrange(4)
                return copy.deepcopy(item)
            if color >= len(costs) or color >= len(caps): self._fail("InvalidConfig", "Equipment magic config is incomplete")
            if int(magic[color]) >= int(caps[color]): self._fail("MagicAtMaximum", "This equipment magic stat is already at maximum")
            if color > 0 and int(magic[color - 1]) <= 0:
                self._fail("MagicLocked", "Upgrade the preceding enchantment tier first")
            previous_level, spent, completed = int(magic[color]), 0, 0
            stop_reason = 'completed'
            for _ in range(times):
                if int(magic[color]) >= int(caps[color]):
                    stop_reason = 'maximum'
                    break
                cost = magic_upgrade_cost(self.simple, color, int(magic[color]))
                if int(dust[color]) < cost:
                    if completed == 0:
                        self._fail('InsufficientResource', 'Not enough dust')
                    stop_reason = 'insufficient_dust'
                    break
                dust[color] = int(dust[color]) - cost
                magic[color] = int(magic[color]) + 1
                spent += cost
                completed += 1
                item['symp'] = random.randrange(4)
            item["magic"] = magic
            # Each successful elemental enchantment draws a new rune type.
            # An idempotent replay returns the stored result without drawing.
            answer = copy.deepcopy(item)
            if times == 10:
                answer['magic_batch'] = {'requested': times, 'completed': completed,
                                         'color': color, 'dust_spent': spent,
                                         'before': previous_level, 'after': int(magic[color]),
                                         'stop_reason': stop_reason}
            return answer
        if m == "user.wager_avatar":
            kind, times = x.get("wager_type", "coin"), self._num(x.get("times", 1), "times", 1, 10)
            if kind not in ("coin", "score"): self._fail("InvalidWager", "Unsupported wager type")
            free = self._num(x.get("free", 0), "free", 0, 1) == 1
            if times not in (1, 10) or (free and times != 1): self._fail("InvalidWager", "Free draws are single draws")
            wager_cfg = self.simple.get("wager_avatar", [1] * 16)
            free_cfg = self.simple.get("wager_free", [1440, 1440])
            if not isinstance(wager_cfg, list) or len(wager_cfg) < 16: wager_cfg = [1] * 16
            if not isinstance(free_cfg, list) or len(free_cfg) < 2: free_cfg = [1440, 1440]
            # PanelCasinoA/B send avatar_len as the current hero count
            # (GlobalData.$userData_avatarNum), not capacity. Use profile state.
            attrs = p.setdefault("attrs", {})
            cap = self._num(attrs.get("avatar_len", 1000), "avatar_len", 1, 10_000_000)
            if len(p.get("avatars", {})) + times > cap: self._fail("RosterFull", "Hero roster is full")
            if self.summon_pools is None:
                categories = self.draw_pools.get(kind, []) if isinstance(self.draw_pools, dict) else []
                if mod_runtime(self.full_config):
                    active = draw_categories(self.full_config, categories, kind)
                else:
                    active = [row for row in categories if isinstance(row, dict) and row.get("ids")
                              and int(row.get("weight", 0)) > 0
                              and all(aid in self.heroes for aid in row["ids"])]
                if not active:
                    self._fail("InvalidConfig", f"No valid {kind} draw pool")
                if kind == "coin" and not any(row.get("category") == "purple_hero" for row in active):
                    self._fail("InvalidConfig", "Coin draw pity has no purple hero pool")
            price_index = (0 if times == 1 else 1) if kind == "coin" else (2 if times == 1 else 3)
            price = 0 if free else max(0, int(wager_cfg[price_index]))
            if p.get(kind, 0) < price: self._fail("InsufficientResource", f"Not enough {kind}")
            now = self.store.clock.now()
            if free:
                attrs = p.setdefault("attrs", {})
                records = p.setdefault("records", {})
                date_key = "wager_free_coin" if kind == "coin" else "wager_free_score"
                raw_date = attrs.get(date_key, {"$date": now})
                if isinstance(raw_date, dict): last_free = int(raw_date.get("$date", now))
                elif isinstance(raw_date, (int, float)): last_free = int(raw_date)
                else: last_free = now
                cooldown = max(0, int(free_cfg[1 if kind == "coin" else 0])) * 60
                if now < last_free + cooldown: self._fail("WagerCooldown", "Free draw is not ready yet")
                if kind == "score":
                    free_cap = max(0, int(wager_cfg[15]))
                    if int(records.get("free_wager_count", 0)) >= free_cap: self._fail("FreeWagerLimit", "The free score draw limit has been reached")
                    records["free_wager_count"] = int(records.get("free_wager_count", 0)) + 1
                attrs[date_key] = {"$date": now}
            else:
                p[kind] -= price
            medal_index = 11 if free else (12 if times == 1 else 13)
            if kind == "coin": p["medal"] = p.get("medal", 0) + max(0, int(wager_cfg[medal_index]))
            if self.summon_pools is not None:
                pool = "advanced" if kind == "coin" else "normal"
                new = [self._new_hero(p, self.summon_pools.draw(pool, self.rng))
                       for _ in range(times)]
                # The calibrated quality distribution replaces the old forced-purple pity.
                if kind == "coin":
                    attrs["wager_coin_1_count"] = 0
            else:
                categories = self.draw_pools.get(kind, []) if isinstance(self.draw_pools, dict) else []
                if mod_runtime(self.full_config):
                    active = draw_categories(self.full_config, categories, kind)
                else:
                    active = [row for row in categories if isinstance(row, dict) and row.get("ids")
                              and int(row.get("weight", 0)) > 0
                              and all(aid in self.heroes for aid in row["ids"])]
                if not active:
                    self._fail("InvalidConfig", f"No valid {kind} draw pool")
                new = []
                total_weight = sum(int(row["weight"]) for row in active)
                pity_period = max(1, int(wager_cfg[14]) + 1)
                pity_count = max(0, int(attrs.get("wager_coin_1_count", 0)))
                purple_rows = [row for row in active if row.get("category") == "purple_hero"]
                for _ in range(times):
                    force_purple = kind == "coin" and pity_count >= pity_period - 1
                    if force_purple:
                        if not purple_rows:
                            self._fail("InvalidConfig", "Coin draw pity has no purple hero pool")
                        selected = purple_rows[0]
                    else:
                        ticket = self.rng.randrange(total_weight)
                        selected = active[-1]
                        for row in active:
                            ticket -= int(row["weight"])
                            if ticket < 0:
                                selected = row
                                break
                    aid = selected["ids"][self.rng.randrange(len(selected["ids"]))]
                    inst = self._new_hero(p, aid); new.append(inst)
                    if kind == "coin":
                        pity_count = 0 if selected.get("category") == "purple_hero" else pity_count + 1
                if kind == "coin":
                    attrs["wager_coin_1_count"] = pity_count
            self.store.adventure.record_draw(p)
            new_map = {obj["id"]: obj for obj in new}
            return {"attrs": p["attrs"], "records": p.get("records", {}),
                    "new_avatars": new_map, "score": p.get("score", 0)}
        if m in ("user.swallow_avatar", "user.swallow_skillbook"):
            target_id = self._id(x.get("aid", x.get("eqid")), "target")
            consumed = x.get("aids", x.get("eqids"))
            if not isinstance(consumed, list) or not consumed: self._fail("InvalidMaterials", "Select at least one material")
            if m == "user.swallow_avatar":
                tid, target = self._hero(p, target_id)
                self._check_not_pending_culture(p, tid)
                ids = []
                materials = []
                for v in consumed:
                    hid, material = self._hero(p, v)
                    self._check_not_pending_culture(p, hid)
                    if hid == tid or hid in ids: self._fail("InvalidMaterials", "Target and duplicate heroes cannot be consumed")
                    if material.get('lock') or material.get('locked'):
                        self._fail('HeroLocked', 'Unlock material heroes before upgrading')
                    self._check_not_team(p, hid); self._check_not_dn(p, hid); ids.append(hid); materials.append(material)
                target_aid = target.get("aid", tid).split("|")[0]
                level_cap = self._hero_level_cap(target_aid, target)
                at_level_cap = int(target.get("lv", 1)) >= level_cap
                award_exp = sum(self._hero_offer_exp(p["avatars"][i]) for i in ids)
                # The submitted gold field is only a preview. Price feeding
                # from the server-computed XP at one L coin per ten XP,
                # rounding up so a positive amount of XP is never free.
                target_row = self.heroes.get(target_aid, {})
                target_tl = target_row.get("tl", [0] * 8)
                exp_rate = float(target_tl[5]) if len(target_tl) > 5 else 1.0
                current = self._hero_all_exp(target, target_aid)
                old_level, old_exp = int(target.get("lv", 1)), int(target.get("exp", 0))
                gained_level = (not at_level_cap and award_exp > 0 and
                                self._level_from_exp(current + award_exp, level_cap, target_aid, exp_rate)
                                != (old_level, old_exp))
                skill_probability = self._native_skill_upgrade_probability(target_aid, target, materials)
                skill_cap = self._native_skill_level_cap()
                current_skill_level = max(1, int(target.get("slv", 1)))
                skill_can_advance = current_skill_level < skill_cap and skill_probability > 0

                # Probe the existing native two-pass cultivation allocation
                # before charging. A capped hero may still consume materials
                # when they can raise its ordinary skill or cultivation; a
                # completely capped target must not lose materials for no
                # possible growth.
                cultivation_probe = copy.deepcopy(target)
                before_cultivation = tuple(int(cultivation_probe.get(k, 0) or 0)
                                           for k in ("hp", "ap", "de_ph", "de_ma"))
                before_pith_max = int(cultivation_probe.get("pith_max", 0) or 0)
                self._feed_cultivation(cultivation_probe, materials)
                cultivation_can_advance = (
                    tuple(int(cultivation_probe.get(k, 0) or 0)
                          for k in ("hp", "ap", "de_ph", "de_ma")) != before_cultivation
                    or int(cultivation_probe.get("pith_max", 0) or 0) > before_pith_max
                )
                if not (gained_level or skill_can_advance or cultivation_can_advance):
                    self._fail("MaxGrowth", "Selected materials cannot improve this hero")

                self._cost(p, {"gold": (award_exp + 9) // 10})
                if not at_level_cap:
                    target["lv"], target["exp"] = self._level_from_exp(
                        current + award_exp, level_cap, target_aid, exp_rate
                    )
                if current_skill_level < skill_cap and skill_probability > 0:
                    if self.rng.randrange(100) < skill_probability:
                        target["slv"] = current_skill_level + 1
                self._feed_cultivation(target, materials)
                for i in ids: del p["avatars"][i]
                for squad in p.get("team", []):
                    for j, h in enumerate(squad):
                        if h in ids: squad[j] = None
                return {"avatars": p["avatars"], "avatar": copy.deepcopy(target),
                        "team": p.get("team"), "gold": p["gold"]}
            tid, target = self._equip(p, target_id)
            target_definition = self.equipment.get(target.get("eid"), {})
            if target_definition.get("type") != 6:
                self._fail("InvalidTarget", "Select a skill book to upgrade")
            current_level = max(1, int(target.get("slv", 0)))
            book_cfg = self.simple.get("skill_book_exp", [])
            if not isinstance(book_cfg, list) or len(book_cfg) <= 5:
                self._fail("InvalidConfig", "Skill-book upgrade costs are missing")
            cap = min(10, max(1, int(book_cfg[3])))
            if current_level >= cap:
                self._fail("MaxGrowth", "This skill book is already at maximum level")
            if len(consumed) > 5:
                self._fail("InvalidMaterials", "Select at most five material books")
            ids, definitions = [], []
            pending = p.get("attrs", {}).get("equip_wash", {})
            for value in consumed:
                eid, material = self._equip(p, value)
                if eid == tid or eid in ids:
                    self._fail("InvalidMaterials", "Target and duplicate books cannot be consumed")
                if any(eid in squad for squad in p.get("as_equips", [])):
                    self._fail("EquipmentInUse", "Unequip material first")
                if material.get("lock") or material.get("locked"):
                    self._fail("EquipmentLocked", "Unlock material books before upgrading")
                if isinstance(pending, dict) and pending.get("eqid") == eid:
                    self._fail("PendingOperation", "Finish the pending material operation first")
                definition = self.equipment.get(material.get("eid"), {})
                if definition.get("type") != 6:
                    self._fail("InvalidMaterials", "Only skill books can be consumed here")
                ids.append(eid)
                definitions.append(definition)
            from skill_books import upgrade_probability
            probability = upgrade_probability(self.simple, current_level, definitions)
            if probability <= 0:
                self._fail("InvalidMaterials", "These materials have no chance to improve the book")
            book_rank = int(target_definition["quality"])
            price = current_level * book_rank * max(0, int(book_cfg[5]))
            self._cost(p, {"gold": price})
            succeeded = self.rng.randrange(100) < int(round(probability * 100))
            target["slv"] = current_level + int(succeeded)
            for eid in ids:
                del p["my_equips"][eid]
            return {"equip": copy.deepcopy(target), "gold": p.get("gold", 0),
                    "success": succeeded, "probability": probability,
                    "consumed_eqids": ids}
        if m in ("user.star_up", "user.phase_up"):
            target_id = self._id(x.get("aid"), "aid"); consumed = x.get("aids", [])
            if not isinstance(consumed, list):
                self._fail("InvalidMaterials", "Materials must be a list")
            if m == "user.star_up" and consumed:
                self._fail("InvalidMaterials", "Star promotion does not use hero materials")
            if m == "user.phase_up" and not consumed:
                self._fail("InvalidMaterials", "Select required hero material")
            tid, target = self._hero(p, target_id)
            self._check_not_pending_culture(p, tid)
            ids = []
            for v in consumed:
                hid, mat = self._hero(p, v)
                if hid == tid or hid in ids: self._fail("InvalidMaterials", "Target and duplicate heroes cannot be consumed")
                if mat.get('lock') or mat.get('locked'):
                    self._fail('HeroLocked', 'Unlock material heroes before ascension')
                self._check_not_team(p, hid)
                self._check_not_dn(p, hid)
                if m == "user.phase_up":
                    if (mat.get("aid", hid).split("|")[0] != target.get("aid", tid).split("|")[0]
                            or int(mat.get("morph", 0)) != 0 or int(mat.get("phase", 0)) != 0):
                        self._fail("IncompatibleMaterial", "Phase ascension requires an unadvanced copy of the same hero and quality")
                ids.append(hid)
            base = target.get("aid", tid).split("|")[0]
            row = self.heroes.get(base)
            if not row: self._fail("UnknownHero", "No growth data for this hero")
            star = int(base.rsplit("_", 1)[1])
            next_aid = "_".join(base.split("_")[:2] + [str(star + 1)])
            if m == "user.star_up":
                metadata = hero_metadata(self.full_config, base)
                if metadata.get("kind") == "new":
                    declared = metadata.get("progression", {}).get("starUp")
                    if not declared:
                        self._fail("MaxGrowth", "此 Mod 英雄未声明升星目标")
                    if declared != next_aid:
                        self._fail("InvalidConfig", "Mod 升星链不符合已注册的英雄家族")
                if next_aid not in self.heroes: self._fail("MaxGrowth", "This hero has reached its configured maximum star")
                # Existing skin owners may continue growing that same family;
                # a non-skin family cannot promote into a restricted skin ID.
                ensure_hero_acquirable(
                    next_aid, self.full_config,
                    allow_skin=base in skin_acquisition_blocked_ids(self.full_config),
                )
                # Promotion only requires the current level cap. Purple to
                # orange also requires two completed phase ascensions.
                level_cap = self._hero_level_cap(base, target)
                if int(target.get("lv", 1)) < level_cap:
                    self._fail("MaxLevel", "Hero must reach its level cap before star-up")
                if star == 5 and int(target.get("phase", 0)) < 2:
                    self._fail("PhaseRequired", "紫卡需达到二阶才能升橙")
            else:
                phase_cfg = self.simple.get("phase_config", [])
                type_index = 0 if base.startswith("A_1") else 1
                phase_table = phase_cfg[type_index] if isinstance(phase_cfg, list) and len(phase_cfg) > type_index else {}
                phase_row = phase_table.get(str(star)) if isinstance(phase_table, dict) else None
                if not isinstance(phase_row, list) or len(phase_row) < 2:
                    self._fail("InvalidConfig", "Missing phase configuration for this hero")
                if int(target.get("phase", 0)) >= int(phase_row[1]):
                    self._fail("MaxGrowth", "This hero has reached its phase limit")
                required = self._num(int(target.get("phase", 0)) + 1, "phase material count", 1, 5)
                if len(ids) != required:
                    self._fail("InsufficientMaterials", "Select exactly the configured phase-up materials")
            if m == "user.phase_up":
                if int(target.get("phase", 0)) >= int(phase_row[1]):
                    self._fail("MaxGrowth", "This hero has reached its phase limit")
                target["phase"] = int(target.get("phase", 0)) + 1
                for hid in ids: del p["avatars"][hid]
                return copy.deepcopy(target)
            # Normalize before removing the old instance: the native DN schema
            # validates a node's bound avatar against the current avatar map.
            dn = self._normalize_dn(p)
            instance_suffix = tid.rsplit("|", 1)[-1]
            promoted_id = f"{next_aid}|{instance_suffix}"
            replacement = copy.deepcopy(target)
            promoted_row = self.heroes[next_aid]
            # Keep the displayed level and progress within it. Reinterpreting
            # total XP against the new star's curve can reduce the level.
            # The new star begins its own phase ascension from zero.
            current_level = max(1, int(replacement.get("lv", 1)))
            new_cap = self._hero_level_cap(next_aid, replacement)
            if current_level < new_cap:
                next_step = (self._exp_requirement(next_aid, current_level + 1)
                             - self._exp_requirement(next_aid, current_level))
                if next_step > 0:
                    replacement["exp"] = min(max(0, int(replacement.get("exp", 0))), next_step - 1)
            replacement.update({"id": promoted_id, "aid": promoted_id, "phase": 0})
            # A 4->5 promotion crosses into weighted cultivation. Convert its
            # carried raw points using the promoted template once; an already
            # weighted 5->6 hero keeps its actual gains unchanged.
            migrate_weighted_culture_hero(replacement, promoted_row, self.simple)
            p["avatars"][promoted_id] = replacement
            del p["avatars"][tid]
            for squad in p.get("team", []):
                for j, hid in enumerate(squad):
                    if hid == tid: squad[j] = replacement["id"]
            # PanelStarUpStart.re_star_up calls
            # GlobalFunction.changeStarUpDnTeam(oldId, promotedId). DN rows
            # retain an optional bound avatar id in slot 1; migrate the first
            # matching row so the persistent formation keeps the same binding
            # after the old instance key is removed.
            for node in dn.values():
                if isinstance(node, list) and len(node) > 1 and node[1] == tid:
                    node[1] = promoted_id
                    break
            return copy.deepcopy(replacement)
        if m == "user.sell_avatars":
            aids = x.get("aids", x.get("ids", []))
            if not isinstance(aids, list) or not 1 <= len(aids) <= 100:
                self._fail("InvalidSelection", "Select between one and 100 heroes")
            keys = []
            for aid in aids:
                hid, hero = self._hero(p, aid)
                self._check_not_pending_culture(p, hid)
                if hid in keys: self._fail("InvalidSelection", "Duplicate hero selection")
                if hero.get("lock"):
                    self._fail("HeroLocked", "Unlock the hero before selling")
                self._check_not_team(p, hid); self._check_not_dn(p, hid); keys.append(hid)
            gain = 0
            for hid in keys:
                hero = p["avatars"].pop(hid); base = hero.get("aid", hid).split("|")[0]
                cfg = self.heroes.get(base, {}); gain += max(0, int((cfg.get("tl") or [0]*8)[7]))
                p.setdefault("avatar_soul", {})[base] = p.setdefault("avatar_soul", {}).get(base, 0) + 1
            p["gold"] = p.get("gold", 0) + gain
            return {"avatars": p["avatars"], "avatar_soul": p["avatar_soul"], "gold": p["gold"]}
        if m == "user.avatar_culture":
            aid = self._id(x.get("aid"), "aid")
            raw_num = x.get("num", 1)
            # PanelAvatarFoster serializes its radio choice as exactly "1" or "10".
            # Accept those native strings here without weakening _num for other RPCs.
            if isinstance(raw_num, str) and raw_num in ("1", "10"):
                n = int(raw_num)
            else:
                n = self._num(raw_num, "num", 1, 10)
                if n not in (1, 10): self._fail("InvalidParameter", "Invalid num")
            kind = x.get("type", "coin")
            if kind not in ("coin", "culture_book"): self._fail("InvalidParameter", "Invalid cultivation type")
            tid, hero = self._hero(p, aid); attrs = p.setdefault("attrs", {})
            if attrs.get("avatar_culture"): self._fail("PendingOperation", "Save or cancel current cultivation first")
            price_table = (self.simple.get("culture", {}).get("price", {})
                           if isinstance(self.simple, dict) else {})
            prices = price_table.get(kind, {}) if isinstance(price_table, dict) else {}
            if not isinstance(prices, dict) or str(n) not in prices:
                self._fail("InvalidConfig", f"Missing cultivation price for {kind}/{n}")
            remaining = max(0, self._culture_cap(hero) - self._culture_pith(hero))
            if remaining <= 0:
                self._fail("MaxCulture", "Hero cultivation points are already at the configured maximum")
            spent = {kind: self._num(prices[str(n)], "culture price", 0, 10_000_000)}
            self._cost(p, spent)
            if weighted_culture_active(self.simple, hero):
                hero_aid = str(hero.get("aid", tid)).split("|", 1)[0]
                hero_row = self.heroes.get(hero_aid)
                if not isinstance(hero_row, dict):
                    self._fail("InvalidTarget", "Cultivation target has no avatar configuration")
                rolled, rolled_raw = roll_weighted_culture(
                    hero, n, self.simple, self.rng, hero_row
                )
            else:
                raw_roll = {key: 0 for key in ("hp", "ap", "de_ph", "de_ma")}
                for _ in range(n):
                    key = self.rng.choice(tuple(raw_roll))
                    raw_roll[key] += self.rng.randint(1, 3)
                # Legacy-quality cards keep their native raw-stat model and
                # small existing cap. The 1–3 roll chooses proportions; one
                # attempt has 500 points of capacity, limited by that cap.
                rolled = allocate_culture_budget(
                    raw_roll, min(remaining, 500 * n), {key: 1 for key in raw_roll}
                )
            attrs["avatar_culture"] = {
                "eqid": tid, "aid": tid, "num": n, "type": kind,
                "save_status": rolled, "rolled": rolled, "spent": spent,
            }
            if weighted_culture_active(self.simple, hero):
                attrs["avatar_culture"]["schema"] = WEIGHTED_CULTURE_SCHEMA
                attrs["avatar_culture"]["rolled_raw"] = rolled_raw
            culture_view = {"aid": tid, "save_status": rolled}
            if weighted_culture_active(self.simple, hero):
                culture_view["schema"] = WEIGHTED_CULTURE_SCHEMA
            return {
                "avatar_culture": culture_view, "coin": p.get("coin", 0),
                "culture_book": attrs.get("culture_book", 0),
                "vip_exp": p.get("vip_exp", 0), "vip_lv": p.get("vip_lv", 0),
                "attrs": attrs, "avatars": p["avatars"],
            }
        if m == "user.get_avatar_talent": self._fail("Internal", "Talent handler routing failure")
        if m == "user.dn_unlock":
            key = self._id(x.get("key"), "key")
            row = self._dn_config_row(key); attrs = p.setdefault("attrs", {}); dn = self._normalize_dn(p)
            if key in dn: self._fail("AlreadyUnlocked", "This destiny node is already unlocked")
            parent = str(row[1])
            if parent != "0" and parent not in dn: self._fail("LockedNode", "Unlock the previous destiny node first")
            if int(p.get("lv", 1)) < int(row[2]): self._fail("InsufficientLevel", "Player level is too low for this destiny node")
            cost = max(0, int(row[3]))
            self._cost(p, {"dn_stone": cost})
            dn[key] = [1, None]
            return {"dn": dn, "dn_stone": attrs.get("dn_stone", 0), "attrs": attrs}
        if m == "user.dn_lvup":
            key, level = self._id(x.get("key"), "key"), self._num(x.get("lv"), "lv", 1, 99)
            row = self._dn_config_row(key); attrs = p.setdefault("attrs", {}); dn = self._normalize_dn(p); node = dn.get(key)
            if not isinstance(node, list): self._fail("LockedNode", "Unlock this destiny node first")
            old = max(1, int(node[0]))
            max_level = int(self.simple.get("dn_lv", 50))
            if old >= max_level: self._fail("MaxLevel", "Destiny node is already at maximum level")
            if level != old: self._fail("InvalidLevel", "Request level must match current destiny level")
            next_level = old + 1
            cost = max(0, int(level * level * float(row[4])))
            self._cost(p, {"dn_stone": cost})
            node[0] = next_level
            return {"dn": dn, "dn_stone": attrs.get("dn_stone", 0), "attrs": attrs}
        if m == "user.morph":
            hid, hero = self._hero(p, x.get("aid"))
            morph_aid = hero.get("aid", hid).split("|")[0]
            if int(hero.get("morph", 0)):
                self._fail("AlreadyMorphed", "Hero already has this form")
            try:
                unit_type = int(morph_aid.split("_")[1][:1])
                star = int(morph_aid.rsplit("_", 1)[1])
            except (IndexError, TypeError, ValueError):
                self._fail("MorphRequirements", "This unit cannot be transformed")
            morph_cfg = self.ploy_simple.get("morph", {}) if isinstance(self.ploy_simple, dict) else {}
            morph_attr = morph_cfg.get("attr", self.rules.get("morph_attr", [0, 0, 5, 0])) if isinstance(morph_cfg, dict) else self.rules.get("morph_attr", [0, 0, 5, 0])
            if not isinstance(morph_attr, list):
                morph_attr = self.rules.get("morph_attr", [0, 1, 5, 0])
            min_star = int(morph_attr[2]) if len(morph_attr) > 2 else 5
            if unit_type != 1 or star < min_star:
                self._fail("MorphRequirements", "This hero does not meet the transformation requirements")
            level_cap = self._hero_level_cap(morph_aid, hero)
            if int(hero.get("lv", 1)) < level_cap:
                self._fail("MorphRequirements", "Hero must reach its level limit before transformation")

            attrs = p.setdefault("attrs", {})
            attrs_morph = attrs.setdefault("morph", {"chance": 0})
            if not isinstance(attrs_morph, dict):
                attrs_morph = {"chance": 0}
                attrs["morph"] = attrs_morph
            chance = attrs_morph.get("chance") if isinstance(attrs_morph, dict) else None
            if isinstance(chance, dict) and set(chance) == {"$date"}:
                chance = chance.get("$date")
            elif hasattr(chance, "timestamp"):
                chance = chance.timestamp()
            if type(chance) not in (int, float) or chance <= 0:
                self._fail("MorphUnavailable", "No active transformation opportunity")
            params_cfg = morph_cfg.get("params", []) if isinstance(morph_cfg, dict) else []
            window_minutes = (params_cfg[4] if isinstance(params_cfg, list) and len(params_cfg) > 4
                              else self.rules.get("morph_window_minutes", 10080))
            try:
                window_minutes = float(window_minutes)
            except (TypeError, ValueError):
                window_minutes = 10080
            if window_minutes <= 0 or self.store.clock.now() > float(chance) + window_minutes * 60:
                self._fail("MorphUnavailable", "Transformation opportunity has expired")

            culture_cfg = self.simple.get("culture", {}) if isinstance(self.simple, dict) else {}
            if weighted_culture_active(self.simple, hero):
                # Morph keeps its small AP reward but never raises the new
                # phase-only capacity through the obsolete pith_max field.
                requested = max(0, int(self.rules.get("morph_pith_bonus", 2)))
                gained = clamp_weighted_culture_gain(hero, {"ap": requested}, self.simple)["ap"]
                if gained <= 0:
                    self._fail("MaxCulture", "Cultivation is already at the maximum")
                self._cost(p, self.rules.get("morph_cost", {}))
                hero["morph"] = 1
                hero["ap"] = max(0, int(hero.get("ap", 0) or 0)) + gained
                attrs_morph["chance"] = 0
                return {"avatar": copy.deepcopy(hero), "attr_morph": copy.deepcopy(attrs_morph),
                        "coin": p.get("coin", 0), "dust": copy.deepcopy(attrs.get("dust", [0, 0, 0, 0]))}
            absolute_pith = max(0, int(culture_cfg.get("max_pith", 30))) if isinstance(culture_cfg, dict) else 30
            base_pith = max(0, int(culture_cfg.get("max_pith_base", 10))) if isinstance(culture_cfg, dict) else 10
            old_pith_bonus = max(0, int(hero.get("pith_max", 0) or 0))
            current_pith_cap = base_pith + old_pith_bonus
            current_pith = sum(max(0, int(hero.get(field, 0) or 0)) for field in ("hp", "ap", "de_ph", "de_ma"))
            if current_pith_cap > absolute_pith or current_pith > current_pith_cap or current_pith > absolute_pith:
                self._fail("MaxCulture", "This hero is already above the cultivation limit")
            configured_bonus = max(0, int(self.rules.get("morph_pith_bonus", 2)))
            pith_bonus = min(configured_bonus, absolute_pith - current_pith_cap, absolute_pith - current_pith)
            if pith_bonus <= 0:
                self._fail("MaxCulture", "Cultivation is already at the maximum")

            # Preserve the hero's existing level/XP (including historical
            # over-cap values) and give it a small permanent, visible pith gain.
            # pith_max and ap are native Avatar fields; the bonus is bounded by
            # both the per-hero cap and absolute culture limit.
            self._cost(p, self.rules.get("morph_cost", {}))
            hero["morph"] = 1
            hero["pith_max"] = old_pith_bonus + pith_bonus
            hero["ap"] = max(0, int(hero.get("ap", 0) or 0)) + pith_bonus
            attrs_morph["chance"] = 0
            return {"avatar": copy.deepcopy(hero), "attr_morph": copy.deepcopy(attrs_morph),
                    "coin": p.get("coin", 0), "dust": copy.deepcopy(attrs.get("dust", [0, 0, 0, 0]))}
        if m == "user.soul_exchange_avatar":
            aid = self._id(x.get("aid", x.get("id")), "aid")
            if mod_runtime(self.full_config):
                ensure_available(self.full_config, aid)
            count = self._num(x.get("num", 1), "num", 1, 99)
            # PanelCenterSoul passes the exact soul-row ID (ItemAvatarSoul
            # sends data.id). Resolve the configured avatar and its native
            # type/star before reading balances or mutating the profile.
            definition = self.heroes.get(aid)
            parts = aid.split("_")
            if (not isinstance(definition, dict) or len(parts) != 3 or parts[0] != "A"
                    or not parts[1].isdigit() or not parts[2].isdigit()
                    or aid[2:3] != "1"):
                self._fail("UnknownHero", "Hero is unavailable")
            star = int(parts[2])
            if str(definition.get("id", aid)) != aid:
                self._fail("UnknownHero", "Hero is unavailable")
            exchange = self.simple.get("soul_exchange", {}) if isinstance(self.simple, dict) else {}
            avatar_costs = exchange.get("avatar", {}) if isinstance(exchange, dict) else {}
            configured_need = avatar_costs.get(str(star)) if isinstance(avatar_costs, dict) else None
            if type(configured_need) not in (int, float) or not math.isfinite(configured_need) or configured_need <= 0 or int(configured_need) != configured_need:
                self._fail("InvalidConfig", "Missing hero soul exchange threshold")
            need = int(configured_need) * count

            souls = p.get("avatar_soul", {})
            if not isinstance(souls, dict):
                self._fail("InvalidProfile", "Hero soul inventory is invalid")
            current_souls = self._num(souls.get(aid, 0), "avatar_soul", 0, 10_000_000)
            if current_souls < need:
                self._fail("InsufficientSoul", "Not enough hero souls")
            avatars = p.get("avatars", {})
            if not isinstance(avatars, dict):
                self._fail("InvalidProfile", "Hero roster is invalid")
            attrs = p.get("attrs", {})
            cap = self._num(attrs.get("avatar_len", 1000) if isinstance(attrs, dict) else 1000,
                            "avatar_len", 1, 10_000_000)
            if len(avatars) + count > cap:
                self._fail("RosterFull", "Hero roster is full")

            restricted_skin = aid in skin_acquisition_blocked_ids(self.full_config)
            credits = attrs.get("tower_skin_soul_credit", {}) if isinstance(attrs, dict) else {}
            if restricted_skin:
                if not isinstance(credits, dict) or type(credits.get(aid)) is not int or credits[aid] < need:
                    self._fail("SkinAcquisitionRestricted", "Earn this skin's souls in the tower before exchanging it")
            # Wallet, roster capacity, and tower provenance are all validated
            # before either currency or the tower's skin entitlement is spent.
            p["avatar_soul"] = souls
            souls[aid] = current_souls - need
            if restricted_skin:
                credits[aid] -= need
            made = [self._new_hero(p, aid, allow_skin=restricted_skin) for _ in range(count)]
            return {"avatars": p["avatars"], "avatar_soul": souls, "new_avatars": made}
        if m == "user.soul_exchange_equip":
            eid = self._id(x.get("eid"), "eid")
            count = self._num(x.get("num", 1), "num", 1, 99)
            definition = self.equipment.get(eid)
            parts = eid.split("_")
            if (not isinstance(definition, dict) or len(parts) != 3 or parts[0] != "E"
                    or not parts[1].isdigit() or not parts[2].isdigit()
                    or str(definition.get("id", eid)) != eid):
                self._fail("UnknownEquipment", "Equipment is unavailable")
            if eid in equipment_exclusive_ids(self.full_config):
                self._fail("ExclusiveEquipmentRestricted", "This equipment is available only through authorized mail")
            star = int(parts[2])
            exchange = self.simple.get("soul_exchange", {}) if isinstance(self.simple, dict) else {}
            equip_costs = exchange.get("equip", {}) if isinstance(exchange, dict) else {}
            configured_need = equip_costs.get(str(star)) if isinstance(equip_costs, dict) else None
            if type(configured_need) not in (int, float) or not math.isfinite(configured_need) or configured_need <= 0 or int(configured_need) != configured_need:
                self._fail("InvalidConfig", "Missing equipment soul exchange threshold")
            need = int(configured_need) * count
            souls = p.get("equip_soul", {})
            if not isinstance(souls, dict):
                self._fail("InvalidProfile", "Equipment soul inventory is invalid")
            current_souls = self._num(souls.get(eid, 0), "equip_soul", 0, 10_000_000)
            if current_souls < need:
                self._fail("InsufficientSoul", "Not enough equipment souls")

            # ItemEquipSoul normally checks equip_config[0] before sending the
            # RPC, but the inventory cap is authoritative on the server too.
            # Validate both the persisted shape and the entire batch before
            # spending souls or creating any equipment instances.
            equip_cfg = self.simple.get("equip_config", []) if isinstance(self.simple, dict) else []
            capacity = self._num(equip_cfg[0] if isinstance(equip_cfg, list) and equip_cfg else 100,
                                 "equipment_capacity", 1, 10_000_000)
            owned = p.get("my_equips", {})
            if not isinstance(owned, dict):
                self._fail("InvalidProfile", "Equipment inventory is invalid")
            if len(owned) + count > capacity:
                self._fail("EquipCapacity", "Equipment inventory is full")

            p["equip_soul"] = souls
            souls[eid] = current_souls - need
            made = [self._new_equip(p, eid) for _ in range(count)]
            return {"my_equips": p["my_equips"], "equip_soul": souls, "new_equips": made}
        if m == "user.compose_fragment":
            eid = self._id(x.get("eid"), "eid")
            amount = self._num(x.get("num", 1), "num", 1, 1)
            if eid in equipment_exclusive_ids(self.full_config):
                self._fail("ExclusiveEquipmentRestricted", "This equipment is available only through authorized mail")
            fragments = p.setdefault("fragment", {}).setdefault("equips", {})
            pieces = fragments.get(eid)
            if not isinstance(pieces, list) or not pieces or any(int(v) <= 0 for v in pieces):
                self._fail("InsufficientFragments", "Every fragment slot must be collected first")
            if eid in self.heroes:
                made = [self._new_hero(p, eid) for _ in range(amount)]
                result = {"avatars": p["avatars"], "new_avatars": made}
            elif eid in self.equipment:
                equip_cfg = self.simple.get("equip_config", []) if isinstance(self.simple, dict) else []
                capacity = self._num(equip_cfg[0] if isinstance(equip_cfg, list) and equip_cfg else 100,
                                     "equipment_capacity", 1, 10_000_000)
                owned = p.setdefault("my_equips", {})
                if len(owned) + amount > capacity:
                    self._fail("EquipCapacity", "Equipment inventory is full")
                made = [self._new_equip(p, eid) for _ in range(amount)]
                # ItemFragment.reService iterates response.data.get_equips and
                # merges each generated instance into the local inventory.
                result = {"get_equips": {key: copy.deepcopy(p["my_equips"][key]) for key in made},
                          "new_equips": made}
            else: self._fail("UnknownRecipe", "No fragment recipe for this item")
            fragments[eid] = [0 for _ in pieces]
            return {**result, "fragment": p["fragment"], "attrs": p["attrs"]}
        if m == "user.equip_rise":
            eqid, target = self._equip(p, x.get("eqid"))
            requested_lv = self._num(x.get("lv"), "lv", 1, 10_000)
            old = int(target.get("lv", 1)); cfg = self.equipment.get(target.get("eid"), {})
            # PanelEquipRise.send_rise_fun sends mCurr_lv (the current level),
            # and re_equip_rise expects the server's array[0] to be the new
            # level. The old handler interpreted the request as the target,
            # so a native level-1 request returned 1 and never advanced.
            if requested_lv != old: self._fail("InvalidLevel", "Equipment level changed; refresh before upgrading")
            vip_level = max(0, int(p.get("vip_lv", 0)))
            cap = equipment_effective_cap(p.get("lv", 1), vip_level * 3)
            if old >= cap: self._fail("MaxLevel", "Equipment has reached the player-level upgrade limit")
            self._cost(p, {"gold": self._equip_rise_price(target, cfg, old)})
            new_level = equipment_upgrade_result(old, MAX_EQUIPMENT_LEVEL, vip_level, self.rng)
            target["lv"] = new_level
            return [new_level, p.get("gold", 0)]
        if m == "user.equip_wash":
            eqid, item = self._equip(p, x.get("eqid")); attrs = p.setdefault("attrs", {})
            if attrs.get("equip_wash"): self._fail("PendingOperation", "Save or cancel current wash first")
            n = self._num(x.get("num", 1), "num", 1, 10); kind = x.get("ttype", "coin")
            if kind not in ("coin", "mark"): self._fail("InvalidWashType", "Unsupported equipment wash currency")
            equip_cfg = self.simple.get("equip_config", [])
            if not isinstance(equip_cfg, list) or len(equip_cfg) <= 9:
                self._fail("InvalidConfig", "Equipment wash price configuration is incomplete")
            star = self._equip_star(item)
            price = (int(self.simple.get("equip_wash_mark_cost", 1000)) if kind == "mark"
                     else int(equip_cfg[8]) + int(equip_cfg[9]) * star) * n
            spent = {kind: price}
            self._cost(p, spent)
            old = self._normalize_equip_attrs(item)
            # Native Equip.getPoteNow() computes the remaining wash points as
            # equip_config[3] * star * level minus existing new_4attrs. The
            # previous independent 1..n*5 rolls could exceed that budget and
            # show a negative remaining-potential preview.
            if len(equip_cfg) <= 3:
                self._fail("InvalidConfig", "Equipment wash potential configuration is incomplete")
            level = max(1, int(item.get("lv", 1)))
            point_cap = max(0, int(equip_cfg[3]) * star * level)
            remaining = max(0, point_cap - sum(old.values()))
            halo_cap = int(self.simple["equipwash"][5])
            if remaining <= 0 and self._equip_wash_halo(item, 0, kind)["lv"] >= halo_cap:
                self._fail("WashPotentialFull", "Equipment wash potential is already full")
            definition = self.equipment.get(item.get("eid"), {})
            pl = definition.get("pl", []) if isinstance(definition, dict) else []
            pair = tuple(v for v in pl[6:8] if v in ("hit", "tough", "crit", "flee")) if len(pl) >= 8 else ()
            if len(pair) != 2:
                self._fail("InvalidConfig", "Equipment wash pair is invalid")
            rolled = equipment_wash_roll(old, pair, point_cap, n, self.rng, star=star, level=level)
            attrs["equip_wash"] = {"eqid": eqid, "rolled": rolled, "old": old, "spent": spent, "ttype": kind, "num": n}
            item["halo"] = self._equip_wash_halo(item, n, kind)
            if kind == "coin": p.setdefault("records", {})["coin_wash_count"] = int(p.get("records", {}).get("coin_wash_count", 0)) + n
            balance = p.get(kind, 0)
            return [balance, rolled]
        if m == "user.equip_sell":
            ids = x.get("eqids")
            if not isinstance(ids, list) or not ids: self._fail("InvalidSelection", "Select equipment to sell")
            unique = set(); gold_gain = 0; mark_gain = 0; dust_gain = [0, 0, 0, 0]
            pending_wash = p.get("attrs", {}).get("equip_wash")
            for v in ids:
                eqid, item = self._equip(p, v)
                if eqid in unique: self._fail("InvalidSelection", "Duplicate equipment")
                unique.add(eqid)
                if any(eqid in squad for squad in p.get("as_equips", [])): self._fail("EquipmentInUse", "Unequip an item before selling")
                if item.get("lock"):
                    self._fail("EquipmentLocked", "Unlock an item before selling")
                if isinstance(pending_wash, dict) and pending_wash.get("eqid") == eqid:
                    self._fail("PendingOperation", "Save or cancel the equipment wash before selling")
                gold, mark, dust = self._equip_sell_rewards(item)
                gold_gain += gold
                mark_gain += mark
                dust_gain = [a + b for a, b in zip(dust_gain, dust)]
            for eqid in unique: del p["my_equips"][eqid]
            p["gold"] = p.get("gold", 0) + gold_gain
            p["mark"] = p.get("mark", 0) + mark_gain
            dust = p.setdefault("attrs", {}).setdefault("dust", [0, 0, 0, 0])
            if not isinstance(dust, list): dust = [dust, 0, 0, 0]
            while len(dust) < 4: dust.append(0)
            for i, n in enumerate(dust_gain): dust[i] += n
            p["attrs"]["dust"] = dust
            return [p["mark"], p["gold"], p["attrs"]["dust"]]
        if m == "user.equip_alchemy":
            ids = x.get("eqids")
            if not isinstance(ids, list) or len(ids) != 2 or ids[0] == ids[1]: self._fail("InvalidSelection", "Select two different equipment")
            target_id, target = self._equip(p, ids[0]); mat_id, mat = self._equip(p, ids[1])
            pending_wash = p.get("attrs", {}).get("equip_wash")
            if isinstance(pending_wash, dict) and pending_wash.get("eqid") in (target_id, mat_id):
                self._fail("PendingOperation", "Save or cancel the equipment wash before alchemy")
            max_star = int(self.simple.get("equip_alchemy", {}).get("star_lv", 7))
            if self._equip_star(target) >= max_star:
                self._fail("MaxGrowth", "Equipment has reached its alchemy limit")
            if any(mat_id in squad for squad in p.get("as_equips", [])): self._fail("EquipmentInUse", "Unequip material first")
            if mat.get("lock"):
                self._fail("EquipmentLocked", "Unlock material equipment before alchemy")
            if target.get("eid") != mat.get("eid"): self._fail("IncompatibleEquipment", "Only matching equipment can be combined")
            min_star = int(self.simple.get("equip_alchemy", {}).get("equip_al", 0))
            if self._equip_star(target) < min_star or self._equip_star(mat) != self._equip_star(target):
                self._fail("IncompatibleEquipment", "Alchemy requires matching equipment at the same star")
            # The alchemy panel explicitly previews the sacrifice's ordinary
            # sale proceeds (gold, marks, and dust). It is a refund, not a
            # gold fee; return those exact amounts in the normal profile-data
            # envelope consumed by GlobalFunction.update_UserData.
            gold_gain, mark_gain, dust_gain = self._equip_sell_rewards(mat)
            alchemy = target.get("alchemy", [0, 0])
            if not isinstance(alchemy, list) or len(alchemy) != 2:
                self._fail("InvalidEquipment", "Equipment alchemy state is invalid")
            phase, extra = [int(v) for v in alchemy]
            if phase not in (0, 1, 2) or extra < 0:
                self._fail("InvalidEquipment", "Equipment alchemy state is invalid")
            base_star = int(str(target["eid"]).rsplit("_", 1)[-1])
            steps = equipment_alchemy_upgrade_steps(int(p.get("vip_lv", 0)), self.rng)
            max_steps = 3 * (max_star - base_star)
            old_steps = 3 * extra + phase
            final_steps = min(max_steps, old_steps + steps)
            bonus_applied = max(0, final_steps - min(max_steps, old_steps + 1))
            next_extra, next_phase = divmod(final_steps, 3)
            target["alchemy"] = [next_phase, next_extra]
            del p["my_equips"][mat_id]
            p["gold"] = int(p.get("gold", 0)) + gold_gain
            p["mark"] = int(p.get("mark", 0)) + mark_gain
            dust = p.setdefault("attrs", {}).setdefault("dust", [0, 0, 0, 0])
            if not isinstance(dust, list): dust = [dust, 0, 0, 0]
            while len(dust) < 4: dust.append(0)
            dust = [int(a) + int(b) for a, b in zip(dust, dust_gain)]
            p["attrs"]["dust"] = dust
            return {"my_equips": p["my_equips"], "gold": p["gold"], "mark": p["mark"],
                    "attrs": p["attrs"], "alchemy_bonus_step": bonus_applied}
        self._fail("NotImplemented", f"Method not reconstructed: {m}")

    def _new_hero(self, p, aid, retain=None, *, allow_skin=False):
        if aid not in self.heroes: self._fail("UnknownHero", "Hero does not exist in roster config")
        ensure_hero_acquirable(aid, self.full_config, allow_skin=allow_skin)
        cap = self._num(p.setdefault("attrs", {}).get("avatar_len", 1000), "avatar_len", 1, 10_000_000)
        if len(p.setdefault("avatars", {})) >= cap: self._fail("RosterFull", "Hero roster is full")
        iid = next_hero_instance_id(p, aid, self.full_config)
        obj = copy.deepcopy(retain) if retain else {"lv": 1, "slv": 1, "exp": 0, "hp": 0, "ap": 0, "de_ph": 0, "de_ma": 0, "phase": 0, "morph": 0, "limit_break": 0, "love_exp": 0, "equips": []}
        obj.update({"id": iid, "aid": iid})
        p["avatars"][iid] = obj
        return obj

    def _new_equip(self, p, eid):
        if eid not in self.equipment: self._fail("UnknownEquipment", "Equipment does not exist in roster config")
        eqs = p.setdefault("my_equips", {}); n = 0
        while f"eq{n}" in eqs: n += 1
        key = f"eq{n}"
        definition = self.equipment[eid]
        is_book = int(definition.get("type", 0)) == 6
        roll_policy = self.simple.get("equipment_roll_policy", {})
        exclusive_ids = roll_policy.get("exclusive_ids", []) if isinstance(roll_policy, dict) else []
        eqs[key] = {
            "eid": eid,
            "lv": 1,
            "slv": 0,
            "sexp": 0,
            "new_4attrs": {"hit": 0, "flee": 0, "crit": 0, "tough": 0},
            # The native Equip.init reads halo.lv/halo.exp; keep scalar aliases
            # for server-side helpers and legacy profile consumers.
            "halo": {"lv": 0, "exp": 0},
            "haloLv": 0,
            "haloExp": 0,
            "alchemy": [0, 0],
            "rune_lv": 0,
            "magic_stage5": 0,
            "stat_roll_ppm": 1_000_000 if is_book else roll_for_new_item(self.rng, eid in exclusive_ids),
            "equipment_v2_version": 1,
            "wash_schema_version": 1,
        }
        return key

    def _hero_level_cap(self, aid, hero=None):
        try:
            star = int(str(aid).rsplit("_", 1)[-1])
            unit_type = int(str(aid).split("_")[1][:1])
        except (IndexError, TypeError, ValueError):
            star = 6
            unit_type = 1
        tier_cap = ({2: 20, 3: 30, 4: 60, 5: 99}.get(star, 99)
                    if unit_type == 1 else 1)
        if unit_type == 1 and star in (5, 6) and isinstance(hero, dict):
            try:
                if int(hero.get("limit_break", 0) or 0) == 1:
                    return 125
            except (TypeError, ValueError, OverflowError):
                pass
        tl = self.heroes.get(aid, {}).get("tl", [])
        configured_cap = int(tl[4]) if isinstance(tl, list) and len(tl) > 4 else tier_cap
        return min(99, tier_cap, max(1, configured_cap))

    def _migrate_hero_level_caps(self, profile):
        attrs = profile.setdefault("attrs", {})
        self._migrate_hero_experience(profile)
        curve = self.simple.get("avatar_exp_curve")
        curve_active = isinstance(curve, list) and len(curve) >= 2
        caps_done = int(attrs.get("roster_caps_version", 0) or 0) >= 1
        exp_done = int(attrs.get("avatar_exp_curve_version", 0) or 0) >= 1 or not curve_active
        if caps_done and exp_done:
            return
        for hero in profile.setdefault("avatars", {}).values():
            aid = str(hero.get("aid", hero.get("id", ""))).split("|")[0]
            if mod_runtime(self.full_config) and not hero_available(self.full_config, aid):
                continue
            cap = self._hero_level_cap(aid, hero)
            level = max(1, int(hero.get("lv", 1)))
            row = self.heroes.get(aid, {})
            tl = row.get("tl", [])
            rate = float(tl[5]) if len(tl) > 5 else 1.0
            old_total = None
            if not exp_done and 1 <= level <= len(self.simple.get("avatar_exp_curve", [])):
                # Preserve accrued XP using the previously shipped polynomial
                # before interpreting it against the new threshold table.
                old_total = self._legacy_exp_requirement(aid, level, rate) + max(0, int(hero.get("exp", 0)))
                if level <= cap:
                    hero["lv"], hero["exp"] = self._level_from_exp(old_total, cap, aid, rate)
                    level = max(1, int(hero.get("lv", 1)))
                else:
                    # Preserve a historically over-cap level as-is, while
                    # rebasing its residual so the visible cumulative XP is
                    # unchanged under the new curve. Existing cap migration,
                    # when still pending for this profile, may subsequently
                    # clamp it to cap and carry the same overflow.
                    hero["exp"] = old_total - self._exp_requirement(aid, level, rate)
            if not caps_done and level > cap:
                # Existing non-hero monster levels are retained as historical
                # inventory. The new cap blocks further feeding without
                # silently lowering progress or rewriting the owned card.
                try: unit_type = int(aid.split("_")[1][:1])
                except (IndexError, ValueError): unit_type = 1
                if unit_type != 1:
                    continue
                total = old_total if old_total is not None else self._hero_all_exp(hero, aid)
                hero["lv"], hero["exp"] = self._level_from_exp(total, cap, aid, rate)
        if not caps_done:
            attrs["roster_caps_version"] = 1
        if not exp_done and curve_active:
            attrs["avatar_exp_curve_version"] = 1

    def migrate_profile_for_login(self, profile):
        """Apply configured roster/XP migrations inside PlayerStore's login transaction."""
        curve = self.simple.get("avatar_exp_curve")
        curve_active = isinstance(curve, list) and len(curve) >= 2
        before = (
            profile.get("attrs", {}).get("avatar_exp_curve_version"),
            profile.get("attrs", {}).get("roster_caps_version"),
        )
        if curve_active:
            self._migrate_hero_level_caps(profile)
        culture_changed = self._normalize_available_culture(profile)
        equipment_changed = self._normalize_profile_equips(profile)
        from inventory_locks import migrate_preset_locks
        locks_changed = migrate_preset_locks(profile)
        after = (
            profile.get("attrs", {}).get("avatar_exp_curve_version"),
            profile.get("attrs", {}).get("roster_caps_version"),
        )
        return before != after or culture_changed or equipment_changed or locks_changed

    def _legacy_exp_requirement(self, aid, level, exp_rate=None):
        """Old native polynomial cumulative XP, used for migration/fallback."""
        coefficients = self.simple.get("avatar_exp", [0, 972, 2916])
        if not isinstance(coefficients, list) or len(coefficients) < 3:
            self._fail("InvalidConfig", "avatar_exp must have three legacy coefficients")
        row = self.heroes.get(aid, {})
        tl = row.get("tl", [])
        rate = float(tl[5]) if exp_rate is None and len(tl) > 5 else (1.0 if exp_rate is None else float(exp_rate))
        a, b, c = (float(coefficients[i]) for i in range(3))
        cumulative = (a / 3 * level ** 3 + (b - a) / 2 * level ** 2
                      + (a / 6 - b / 2 + c) * level - c)
        return int(cumulative * rate)

    def _exp_requirement(self, aid, level, exp_rate=None):
        coefficients = self.simple.get("avatar_exp", [0, 25, 75])
        if not isinstance(coefficients, list) or len(coefficients) < 3:
            self._fail("InvalidConfig", "avatar_exp must have three native coefficients")
        row = self.heroes.get(aid, {})
        tl = row.get("tl", [])
        rate = float(tl[5]) if exp_rate is None and len(tl) > 5 else (1.0 if exp_rate is None else float(exp_rate))
        curve = self._experience_curve(aid)
        if isinstance(curve, list) and 0 <= level - 1 < len(curve):
            return int(int(curve[level - 1]) * rate)
        a, b, c = (float(coefficients[i]) for i in range(3))
        required = (a / 3 * level ** 3 + (b - a) / 2 * level ** 2 + (a / 6 - b / 2 + c) * level - c) * rate
        return int(required)

    def _experience_curve(self, aid):
        curves = self.simple.get("avatar_exp_curves", {})
        quality = str(aid).split("|")[0].rsplit("_", 1)[-1]
        if isinstance(curves, dict) and isinstance(curves.get(quality), list):
            return curves[quality]
        return self.simple.get("avatar_exp_curve")

    def _migrate_hero_experience(self, profile):
        attrs = profile.setdefault("attrs", {})
        if not self.simple.get("avatar_exp_curves") or int(attrs.get("avatar_exp_curve_version", 0) or 0) >= 2:
            return
        old_curve = self.simple.get("avatar_exp_curve", [])
        old_version = int(attrs.get("avatar_exp_curve_version", 0) or 0)
        for hero in profile.get("avatars", {}).values():
            aid = str(hero.get("aid", hero.get("id", ""))).split("|")[0]
            if mod_runtime(self.full_config) and not hero_available(self.full_config, aid):
                continue
            quality = aid.rsplit("_", 1)[-1]
            if not aid.startswith("A_1") or quality not in self.simple["avatar_exp_curves"]:
                continue
            level = max(1, int(hero.get("lv", 1)))
            rate = float(self.heroes.get(aid, {}).get("tl", [0] * 6)[5])
            if old_version >= 1 and 1 <= level < len(old_curve):
                old_step = int(old_curve[level] * rate) - int(old_curve[level - 1] * rate)
            else:
                old_step = self._legacy_exp_requirement(aid, level + 1, rate) - self._legacy_exp_requirement(aid, level, rate)
            new_step = self._exp_requirement(aid, level + 1, rate) - self._exp_requirement(aid, level, rate)
            if old_step > 0 and new_step > 0:
                hero["exp"] = max(0, int(hero.get("exp", 0))) * new_step // old_step
        attrs["avatar_exp_curve_version"] = 2

    def _hero_all_exp(self, hero, aid=None):
        aid = (aid or hero.get("aid", "")).split("|")[0]
        level = max(1, int(hero.get("lv", 1)))
        return self._exp_requirement(aid, level) + max(0, int(hero.get("exp", 0)))

    def _hero_offer_exp(self, hero):
        aid = hero.get("aid", "").split("|")[0]
        row = self.heroes.get(aid, {})
        star = int(aid.rsplit("_", 1)[-1])
        multipliers = self.simple.get("provide_exp", [1] * 6)
        if not isinstance(multipliers, list) or len(multipliers) < star:
            self._fail("InvalidConfig", "provide_exp does not cover hero star tier")
        offer_exp = int(row.get("tl", [0] * 7)[6]) if len(row.get("tl", [])) > 6 else 0
        return int(self._hero_all_exp(hero, aid) * float(multipliers[star - 1]) + offer_exp)

    def _level_from_exp(self, total, cap, aid=None, exp_rate=None):
        level = 1
        amount = max(0, int(total))
        while level < cap and amount >= self._exp_requirement(aid, level + 1, exp_rate):
            level += 1
        return level, amount - self._exp_requirement(aid, level, exp_rate)

    def _apply_owned_guild_research(self, profile, stats):
        """Match Avatar's per-stat guild research after other flat bonuses."""
        guild_table = (self.full_config.get("cfg", {}).get("association_simple", {})
                       .get("guild_graduate", {}).get("guild_graduate_skill", {}))
        learned = profile.get("attrs", {}).get("guild_graduate_skill", {})
        if not isinstance(guild_table, dict) or not isinstance(learned, dict):
            return
        for skill_id, raw_level in learned.items():
            definition = guild_table.get(str(skill_id))
            if not isinstance(definition, dict):
                continue
            try:
                level = max(0, int(raw_level))
            except (TypeError, ValueError):
                continue
            level_row = definition.get("level", {}).get(str(level)) if level > 0 else None
            if not isinstance(level_row, dict):
                continue
            try:
                percent = max(0.0, min(100.0, float(level_row.get("value", 0))))
            except (TypeError, ValueError):
                continue
            targets = definition.get("effect_attributes", [])
            if isinstance(targets, str):
                targets = [targets]
            if not isinstance(targets, list):
                continue
            for target_stat in targets:
                if target_stat in ("hp", "ap", "de_ph", "de_ma"):
                    stats[target_stat] = self._native_tools_to_int(stats[target_stat] * (1 + percent / 100.0))

    def _destiny_team_bonuses(self, profile):
        """Resolve the native DN tree's flat team-wide stat bonuses.

        Avatar.setDestinyAndDN calls PanelDetailDN.getDNAttrsAllValue once for
        the player's complete DN layout.  Each assigned node contributes a
        flat value based on the bound hero's un-equipped stat, and that same
        aggregate is then applied to every combat Avatar.
        """
        dn = profile.get("attrs", {}).get("dn", {})
        dn_cfg = self.simple.get("dn", {}) if isinstance(self.simple, dict) else {}
        phase_cfg = self.simple.get("phase_config", []) if isinstance(self.simple, dict) else []
        culture_cfg = self.simple.get("culture", {}) if isinstance(self.simple, dict) else {}
        growth_rate = culture_cfg.get("pith_growth_rate", 0.1) if isinstance(culture_cfg, dict) else 0.1
        try:
            growth_rate = float(growth_rate)
        except (TypeError, ValueError):
            growth_rate = 0.1
        if growth_rate <= 0:
            growth_rate = 0.1

        result = {"hp": 0, "ap": 0, "de_ph": 0, "de_ma": 0}
        if not isinstance(dn, dict) or not isinstance(dn_cfg, dict):
            return result

        for node_id, node in dn.items():
            if not isinstance(node, (list, tuple)) or len(node) < 2 or not node[1]:
                continue
            try:
                node_num = int(node_id)
                level = max(0, int(node[0]))
            except (TypeError, ValueError):
                continue
            if node_num <= 0 or level <= 0:
                continue
            config = dn_cfg.get(str(node_id))
            if not isinstance(config, (list, tuple)) or len(config) < 8:
                continue
            try:
                rate = max(0.0, float(config[6]) + max(0, level - 1) * float(config[7]))
            except (TypeError, ValueError):
                continue

            try:
                _, bound = self._hero(profile, str(node[1]))
            except GameplayFault:
                # Native lookup produces no assigned hero for stale bindings.
                continue
            bound = copy.deepcopy(bound)
            # Owned bindings always read current growth. Legacy node[2]
            # snapshots can otherwise hide later levels, phases and talents.
            aid = str(bound.get("aid", node[1])).split("|")[0]
            if not channel_enabled(self.full_config, aid, "usage.auxiliary_formation"):
                continue
            hero_row = self.heroes.get(aid, {})
            pl = hero_row.get("pl", [])
            if len(pl) < 8:
                continue
            try:
                hero_lv = max(1, int(bound.get("lv", 1)))
                phase = max(0, int(bound.get("phase", 0)))
            except (TypeError, ValueError):
                continue
            hero_type = int(aid[2]) if len(aid) > 2 and aid[2].isdigit() else 1
            phase_table = phase_cfg[0 if hero_type == 1 else 1] if isinstance(phase_cfg, list) and len(phase_cfg) > (0 if hero_type == 1 else 1) else {}
            star = aid.rsplit("_", 1)[-1]
            phase_row = phase_table.get(str(int(star))) if isinstance(phase_table, dict) and star.isdigit() else None
            phase_lv = int(phase_row[2]) * phase if isinstance(phase_row, list) and len(phase_row) > 2 else 0
            is_six_star = star == "6"
            effective_lv = hero_lv if is_six_star else hero_lv + phase_lv
            phase_rate = 1.12 ** phase if is_six_star else 1.0
            try:
                hp_base = float(pl[0]) + float(pl[1]) * (effective_lv - 1)
                ap_base = float(pl[2]) + float(pl[3]) * (effective_lv - 1)
                de_ph_base = float(pl[4]) + float(pl[5]) * (effective_lv - 1)
                de_ma_base = float(pl[6]) + float(pl[7]) * (effective_lv - 1)
                if is_six_star:
                    # Native getters return integer base stats before adding
                    # cultivation, destiny, gear, or guild bonuses.
                    hp_base = int(hp_base * phase_rate)
                    ap_base = int(ap_base * phase_rate)
                    de_ph_base = int(de_ph_base * phase_rate)
                    de_ma_base = int(de_ma_base * phase_rate)
                weighted_bound = (weighted_culture_active(self.simple, bound)
                                  and bound.get("culture_schema") == WEIGHTED_CULTURE_SCHEMA)
                base_stats = {}
                for field, base_value, slope in (("hp", hp_base, pl[1]), ("ap", ap_base, pl[3]),
                                                  ("de_ph", de_ph_base, pl[5]), ("de_ma", de_ma_base, pl[7])):
                    raw = int(bound.get(field, 0) or 0)
                    gain = raw if weighted_bound else int(raw * float(slope) * growth_rate)
                    base_stats[field] = int(base_value) + gain
            except (TypeError, ValueError):
                continue

            # PanelDetailDN constructs an owned Avatar for the bound node.
            # Its bare getters apply that hero's guild research before the
            # node percentage is floored. The receiving team applies research
            # again after all DN flat values have been added.
            self._apply_owned_guild_research(profile, base_stats)
            bound_talent = bound.get("talent")
            bound_talent = bound_talent.get("id") if isinstance(bound_talent, dict) else bound_talent
            talent_row = self.talents.get(bound_talent, {})
            from talent_stats_103 import apply_stat_talent
            apply_stat_talent(base_stats, talent_row)
            attribute = str(config[5])
            targets = base_stats.keys() if attribute == "all" else (attribute,)
            for stat in targets:
                if stat in result:
                    result[stat] += math.floor(base_stats[stat] * rate)
        return result

    def battle_attributes(self, profile, hero_instance_id, *, hero_only=False, scope="owned"):
        """Serialize owned stats, excluding equipment and global bonuses in exploration."""
        key, hero = self._hero(profile, hero_instance_id)
        base_id = hero.get("aid", key).split("|")[0]
        aid = definition_id(self.full_config, base_id, scope) if mod_runtime(self.full_config) else base_id
        row = self.heroes.get(aid)
        if not row: self._fail("UnknownHero", f"No combat config for {aid}")
        tl, pl = row.get("tl", []), row.get("pl", [])
        if len(pl) < 13: self._fail("InvalidConfig", f"Hero {aid} has incomplete attributes")
        lv = max(1, int(hero.get("lv", 1))); lv = min(lv, self._hero_level_cap(aid, hero))
        phase = max(0, int(hero.get("phase", 0)))
        phase_rows = self.simple.get("phase_config", [])
        hero_type = int(aid[2]) if len(aid) > 2 and aid[2].isdigit() else 1
        phase_table = phase_rows[0 if hero_type == 1 else 1] if isinstance(phase_rows, list) and len(phase_rows) > (0 if hero_type == 1 else 1) else {}
        star = aid.rsplit("_", 1)[-1]
        phase_row = phase_table.get(str(int(star))) if isinstance(phase_table, dict) and star.isdigit() else None
        phase_lv = int(phase_row[2]) * phase if isinstance(phase_row, list) and len(phase_row) > 2 else 0
        is_six_star = star == "6"
        effective_lv = lv if is_six_star else lv + phase_lv
        phase_rate = 1.12 ** phase if is_six_star else 1.0
        base_stats = {
            "hp": (float(pl[0]) + float(pl[1]) * (effective_lv - 1)) * phase_rate,
            "ap": (float(pl[2]) + float(pl[3]) * (effective_lv - 1)) * phase_rate,
            "de_ph": (float(pl[4]) + float(pl[5]) * (effective_lv - 1)) * phase_rate,
            "de_ma": (float(pl[6]) + float(pl[7]) * (effective_lv - 1)) * phase_rate,
        }
        # Each native getter casts its level/phase base to int before adding
        # cultivation or gear. Keep that truncation for every star quality;
        # later five-decimal rounding would otherwise turn values such as
        # 62594.99999999999 into 62595.
        base_stats = {key: int(value) for key, value in base_stats.items()}
        stats = {**base_stats, "speed": int(pl[8]), "range": int(pl[9]), "hit": max(0, int(hero.get("hit", 0))), "flee": max(0, int(hero.get("flee", 0))), "crit": max(0, int(hero.get("crit", 0))), "tough": max(0, int(hero.get("tough", 0)))}
        # Avatar stores cultivation as raw point counts. `culture_pith` is the
        # native UI progress scale; combat growth uses the local per-point rate
        # and each hero's matching level-growth slope, as Avatar now does.
        culture_cfg = self.simple.get("culture", {}) if isinstance(self.simple, dict) else {}
        growth_rate = culture_cfg.get("pith_growth_rate", 0.1) if isinstance(culture_cfg, dict) else 0.1
        try:
            growth_rate = float(growth_rate)
        except (TypeError, ValueError):
            growth_rate = 0.1
        if growth_rate <= 0:
            growth_rate = 0.1
        weighted_hero = (weighted_culture_active(self.simple, hero)
                         and hero.get("culture_schema") == WEIGHTED_CULTURE_SCHEMA)
        for stat_key, slope_index in (("hp", 1), ("ap", 3), ("de_ph", 5), ("de_ma", 7)):
            raw_points = max(0, int(hero.get(stat_key, 0) or 0))
            stats[stat_key] += (raw_points if weighted_hero
                                else int(float(pl[slope_index]) * raw_points * growth_rate))
        # Native Avatar.initFightAttr builds ap/hp/defense from its level,
        # cultivation, equipment, destiny and DN getters. Talent effects are
        # percentage modifiers applied by Avatar.checkTalent during combat,
        # not flat additions to these serialized base attributes. Saved
        # profiles use a talent ID string; accept the native object form too
        # because Avatar.initHalo supports both when reloading older data.
        raw_talent = hero.get("talent")
        if isinstance(raw_talent, dict):
            talent_id = raw_talent.get("id")
        else:
            talent_id = raw_talent
        if not isinstance(talent_id, str) or not talent_id:
            talent_id = None
        equips = profile.get("my_equips", {}); groups = profile.get("as_equips", [])
        equip_simple = self.simple
        equip_cfg = equip_simple.get("equip_config", [])
        equip_wash = equip_simple.get("equipwash", [])
        from equipment_bonds_104 import equipment_slot
        slot = None if hero_only else equipment_slot(profile, key)
        book_skill = None
        symp_counts = [0, 0, 0, 0]
        if slot is not None and slot < len(groups):
            for eqid in groups[slot] or []:
                if not eqid or eqid not in equips: continue
                inst = equips[eqid]; ecfg = self.equipment.get(inst.get("eid"), {})
                symp = inst.get("symp", -1)
                if type(symp) is int and 0 <= symp < 4:
                    symp_counts[symp] += 1
                vals = ecfg.get("pl", [])
                equipment_level = max(1, int(inst.get("lv", 1)))
                halo = inst.get("halo", {}) if isinstance(inst.get("halo"), dict) else {}
                halo_lv = max(0, int(halo.get("lv", inst.get("haloLv", 0))))
                halo_rate = 1 + (float(equip_wash[4]) if isinstance(equip_wash, list) and len(equip_wash) > 4 else 0) * halo_lv
                alchemy_rate = self._equip_alchemy_rate(inst, 0) if "alchemy" in inst else 1.0
                rune_stats = equipment_rune_bonus(self.simple, inst)
                for stat_key, value_index in (('speed', 4), ('range', 5)):
                    if len(vals) > value_index:
                        stats[stat_key] += self._native_tools_to_int(float(vals[value_index]) * halo_rate)
                for k, idx in (("hp", 0), ("ap", 1), ("de_ph", 2), ("de_ma", 3)):
                    if len(vals) > idx:
                        base = equipment_main_stat(float(vals[idx]), equipment_level, equip_simple, inst,
                                                   halo_rate=halo_rate, alchemy_rate=alchemy_rate,
                                                   magic_rate=magic_main_stat_multiplier(self.simple, inst))
                        if idx in (0, 1):
                            magic = inst.get("magic", [0, 0, 0, 0])
                            if isinstance(magic, list) and len(magic) >= 4:
                                base += magic_stat_bonus(self.simple, magic)[k]
                        base += rune_stats[k]
                        stats[k] += base
                wash = equipment_wash_stats(inst, ecfg, equip_simple)
                for stat_key in ("hit", "flee", "crit", "tough"):
                    stats[stat_key] = int(stats.get(stat_key, 0)) + int(wash[stat_key])
                skill_id = (vals[8] if len(vals) > 8 else "") or ecfg.get("skill", "")
                if skill_id and self.skills.get(skill_id):
                    book_slv = max(1, int(inst.get("slv", 1)))
                    book_skill = self._skill(skill_id, book_slv)
                    book_skill["slv"] = book_slv
        if not hero_only:
            for stat_key, amount in magic_symp_bonuses(self.simple, symp_counts).items():
                stats[stat_key] += amount
        for k in ("hp", "ap", "de_ph", "de_ma"): stats[k] = max(0, self._equip_to_int(stats[k]))
        if not hero_only:
            dn_bonus = self._destiny_team_bonuses(profile)
            for k in ("hp", "ap", "de_ph", "de_ma"):
                stats[k] = max(0, int(stats[k]) + int(dn_bonus.get(k, 0)))
        # The native research panels render level.value through the literal
        # `@0%` template. The recovered production effect code is absent, so
        # the local guild table records percentage points and this adapter
        # applies the same value as a bounded percentage to battle stats.
        if not hero_only:
            self._apply_owned_guild_research(profile, stats)
        talent_row = self.talents.get(talent_id, {})
        if book_skill and not book_skill.get("pl"):
            for action in book_skill.get("skills", []):
                if isinstance(action, list) and len(action) > 2 and action[0] == "book_passive" and action[2] in stats:
                    stats[action[2]] = self._equip_to_int(stats[action[2]] * (1 + float(action[1])))
        from talent_stats_103 import apply_stat_talent
        apply_stat_talent(stats, talent_row)
        from bonds_104 import profile_bonds, apply_stats, skill_ids
        bond_config = self.full_config.get('cfg', self.full_config)
        bonds = profile_bonds(bond_config, profile, key, hero_only=hero_only)
        apply_stats(stats, aid, bonds)
        bond_skills = skill_ids(bond_config, aid, bonds)
        skill0 = self._skill(pl[10], max(1, int(hero.get("slv", 1))))
        skill1 = self._skill(pl[11]); skillb = self._skill(pl[13]) if len(pl) > 13 else None
        if bond_skills.get('skill'):
            skill0 = self._skill(bond_skills['skill'], max(1, int(hero.get('slv', 1))))
        if bond_skills.get('leader_skill'):
            skill1 = self._skill(bond_skills['leader_skill'])
        stats['bonds_104'] = [bond['id'] for bond in bonds]
        from equipment_bonds_104 import profile_equipment_bonds, skill_id as equipment_skill_id
        equipment_bonds=profile_equipment_bonds(bond_config,profile,key,hero_only)
        stats['equipment_bonds_104']=[r['equipment'] for r in equipment_bonds]
        def equipment_skill(snapshot,level=1):
            if not snapshot:return snapshot
            sid=equipment_skill_id(bond_config,aid,snapshot['skid'],equipment_bonds)
            return self._skill(sid,level) if sid!=snapshot['skid'] else snapshot
        skill0=equipment_skill(skill0,max(1,int(hero.get('slv',1))))
        skill1=equipment_skill(skill1)
        skillb=equipment_skill(skillb)
        return {"aid": aid, **stats, "growth_stats_applied": True, "hp_max": stats["hp"], "sign_type": int(tl[0]), "action_type": int(tl[1]), "damage_type": int(tl[2]), "skill": skill0, "leader_skill": skill1, "book_skill": book_skill, "skillB": skillb, "talent": talent_id, "phase": phase, "morph": int(hero.get("morph", 0)), "lv": lv, "slv": int(hero.get("slv", 1)), "culture_schema": hero.get("culture_schema") if weighted_hero else None, "tpl": [int(tl[i]) for i in (0, 1, 2)] + [stats["speed"], stats["range"]]}

    def _skill(self, skill_id, level=1):
        # One serializer keeps player/NPC growth and Mod mechanism fields equal.
        from battle_engine import _native_skill_snapshot
        return _native_skill_snapshot({"skill":self.skills},skill_id,max(1,int(level)))

    def _native_skill_level_cap(self):
        config = self.simple.get("slv_config", [])
        if not isinstance(config, list) or not config:
            self._fail("InvalidConfig", "slv_config must define the ordinary skill level cap")
        cap = self._num(config[0], "skill level cap", 1, 100)
        return cap

    def _native_skill_upgrade_probability(self, target_aid, target, materials):
        """Only configured skill biscuits raise an ordinary skill level."""
        target_row = self.heroes.get(target_aid, {})
        target_pl = target_row.get("pl", []) if isinstance(target_row, dict) else []
        target_skill_id = target_pl[10] if isinstance(target_pl, list) and len(target_pl) > 10 else ""
        if not target_skill_id:
            return 0
        configured = self.simple.get("skill_biscuit_ids", [])
        biscuit_ids = set(self.SKILL_BISCUIT_IDS)
        if isinstance(configured, list):
            biscuit_ids.update(aid for aid in configured if isinstance(aid, str))
        single = self.simple.get("skill_biscuit_avatar_id")
        if isinstance(single, str) and single:
            biscuit_ids.add(single)
        biscuit_count = 0
        for material in materials:
            material_aid = str(material.get("aid", material.get("id", ""))).split("|")[0]
            if material_aid in biscuit_ids:
                biscuit_count += 1
        return min(100, 20 * biscuit_count)
