"""NPC rosters whose combat stats come from real cultivation.

An NPC is an ordinary player profile: heroes with level, skill level, phase,
culture points and a talent; equipment with its level, halo, runes, magic and
wash points; DN nodes and guild research. Combat stats are then produced by
``GameplayRosterEquipment.battle_attributes`` exactly as for the player, so
bonds, equipment bonds, talents and every other rule apply unchanged.

Strength is controlled through one ``progress`` value that moves every
cultivation knob together: below 1 it scales the reference cultivation down,
above 1 it moves each knob towards its configured cap. The reference is a
cultivation template taken from the player's own arena team, so NPCs grow
with the player instead of being fixed numbers.
"""
from __future__ import annotations

import copy
import hashlib
import json
import random
import re

from battle_engine import serialize_player_team
from cultivation_rules import active as weighted_active, cap as weighted_cap, rules as weighted_rules
from equipment_bonds_104 import equipment_slot
from equipment_upgrade_cost import MAX_EQUIPMENT_LEVEL
from mod_policy import runtime as mod_runtime, candidate_ids

STAT_KEYS = ("hp", "ap", "de_ph", "de_ma")
WASH_KEYS = ("hit", "flee", "crit", "tough")
TEMPLATE_SCHEMA = "npc-cultivation-template-v1"
MAX_PROGRESS = 2.0
EQUIP_FIELDS = ("eid", "lv", "slv", "new_4attrs", "halo", "haloLv", "alchemy", "rune_lv",
                "magic", "magic_stage5", "symp", "stat_roll_ppm", "wash_schema_version",
                "equipment_v2_version")


def stable_seed(*parts) -> int:
    text = ":".join(str(part) for part in parts)
    return int.from_bytes(hashlib.sha256(text.encode("utf-8")).digest()[:8], "big")


def _scaled(value, cap, progress, floor=0):
    """Scale one knob: proportional below 1, towards ``cap`` above 1."""
    value = max(floor, int(value))
    cap = max(value, int(cap))
    if progress <= 1:
        return max(floor, int(round(value * progress)))
    return min(cap, int(round(value + (cap - value) * (progress - 1) / (MAX_PROGRESS - 1))))


class NpcCultivator:
    def __init__(self, store, config):
        from gameplay_roster import GameplayRosterEquipment

        self.config = config if isinstance(config, dict) else {}
        self.cfg = self.config.get("cfg", self.config)
        self.simple = self.cfg.get("system_simple", {})
        self.heroes = self.cfg.get("avatar", {})
        self.roster = GameplayRosterEquipment(store, self.config)
        self.talent_ranks: dict[int, list[str]] = {}
        for tid, row in sorted(self.cfg.get("talent", {}).items()):
            try:
                rank = int(row.get("rank", 0))
            except (TypeError, ValueError):
                continue
            if rank > 0 and re.fullmatch(r"T_\d{2}_\d{2}", tid):
                self.talent_ranks.setdefault(rank, []).append(tid)
        self.max_talent_rank = max(self.talent_ranks, default=0)
        wash = self.simple.get("equipwash", [])
        self.halo_cap = int(wash[5]) if isinstance(wash, list) and len(wash) > 5 else 5
        magic = self.simple.get("equipment_magic", {})
        self.rune_cap = int(magic.get("rune_max", 10)) if isinstance(magic, dict) else 10
        guild = (self.config.get("cfg", {}).get("association_simple", {})
                 .get("guild_graduate", {}).get("guild_graduate_skill", {}))
        self.guild_caps = {}
        for skill_id, row in guild.items() if isinstance(guild, dict) else ():
            levels = [int(k) for k in (row.get("level") or {}) if str(k).isdigit()]
            self.guild_caps[skill_id] = max(levels, default=0)
        self.skill_cap = self.roster._native_skill_level_cap()

    # ------------------------------------------------------------------ pools
    def family_forms(self, channel: str) -> dict[str, dict[int, str]]:
        """Every configured A_1xxx quality form, grouped by hero family."""
        candidates = [aid for aid in self.heroes if re.fullmatch(r"A_1\d{3}_[2-6]", aid)]
        if mod_runtime(self.cfg):
            candidates = candidate_ids(self.cfg, candidates, channel, include_new=True)
        forms: dict[str, dict[int, str]] = {}
        for aid in sorted(candidates):
            family, star_text = aid.rsplit("_", 1)
            forms.setdefault(family, {})[int(star_text)] = aid
        if len(forms) < 5:
            raise ValueError("NPC rosters need at least five configured hero families")
        return forms

    def pick_team(self, rng: random.Random, forms: dict[str, dict[int, str]],
                  stars: list[int]) -> tuple[list[str], list[str]]:
        """Pick one hero per slot at the slot's quality, completing bonds where possible.

        ``stars`` gives the quality wanted for each slot (the player's own
        lineup). Bonds need every member at one exact quality, so a bond is
        placed only into slots that share that quality. Returns
        ``(aids, bond_ids)``; slot 0 is the captain.
        """
        size = len(stars)
        chosen: list[str | None] = [None] * size
        used: set[str] = set()
        bond_ids: list[str] = []
        bonds = list(self.simple.get("bonds_104", []) or [])
        rng.shuffle(bonds)
        # Most NPCs build around one or two bonds; a few bring a free-form team.
        wanted = 0 if rng.random() < .1 else (2 if rng.random() < .4 else 1)
        for bond in bonds:
            if len(bond_ids) >= wanted:
                break
            families = bond.get("families", [])
            if not families or any(family in used for family in families):
                continue
            for star in sorted({*stars}, key=lambda _: rng.random()):
                open_slots = [i for i, value in enumerate(stars) if value == star and chosen[i] is None]
                if len(open_slots) < len(families) or any(star not in forms.get(f, {}) for f in families):
                    continue
                ordered = sorted(families, key=lambda f: f != bond.get("focus"))
                for slot, family in zip(open_slots, ordered):
                    chosen[slot] = forms[family][star]
                    used.add(family)
                bond_ids.append(bond["id"])
                break
        for slot, star in enumerate(stars):
            if chosen[slot] is not None:
                continue
            free = [family for family in forms if family not in used]
            # Use the slot's quality when available, otherwise the nearest one.
            for distance in range(0, 5):
                exact = [f for f in free if star - distance in forms[f] or star + distance in forms[f]]
                if exact:
                    family = rng.choice(exact)
                    options = [s for s in (star - distance, star + distance) if s in forms[family]]
                    chosen[slot] = forms[family][min(options)]
                    used.add(family)
                    break
        return [aid for aid in chosen if aid], bond_ids

    # --------------------------------------------------------------- template
    def template(self, profile: dict) -> dict:
        """Freeze the cultivation of the player's current arena team."""
        teams = profile.get("team") or []
        index = max(0, min(int(profile.get("attrs", {}).get("team_num", 0) or 0), max(0, len(teams) - 1)))
        saved = teams[index] if teams else []
        avatars = profile.get("avatars", {})
        equips = profile.get("my_equips", {})
        groups = profile.get("as_equips", [])
        slots = []
        for iid in saved[:6] if isinstance(saved, list) else []:
            if not iid or iid not in avatars:
                continue
            hero = avatars[iid]
            aid = str(hero.get("aid", iid)).split("|")[0]
            talent = hero.get("talent")
            talent = talent.get("id") if isinstance(talent, dict) else talent
            talent_rank = int(self.cfg.get("talent", {}).get(talent, {}).get("rank", 0) or 0) if talent else 0
            culture_fraction = 0.0
            culture_split = {key: 0 for key in STAT_KEYS}
            if weighted_active(self.simple, hero) and hero.get("culture_schema"):
                weights, _ = weighted_rules(self.simple, hero)
                total_cap = max(1, weighted_cap(hero, self.simple))
                weighted_values = {key: weights[key] * max(0, int(hero.get(key, 0) or 0)) for key in STAT_KEYS}
                culture_fraction = min(1.0, sum(weighted_values.values()) / total_cap)
                culture_split = weighted_values
            slot = equipment_slot(profile, iid)
            gear = []
            if slot is not None and slot < len(groups):
                for eqid in (groups[slot] or [])[:6]:
                    item = equips.get(eqid) if eqid else None
                    if isinstance(item, dict) and item.get("eid"):
                        gear.append({key: copy.deepcopy(item[key]) for key in EQUIP_FIELDS if key in item})
            slots.append({"star": aid.rsplit("_", 1)[-1], "lv": int(hero.get("lv", 1) or 1),
                          "slv": int(hero.get("slv", 1) or 1), "phase": int(hero.get("phase", 0) or 0),
                          "limit_break": int(hero.get("limit_break", 0) or 0),
                          "talent_rank": talent_rank, "culture_fraction": culture_fraction,
                          "culture_split": culture_split, "gear": gear})
        if not slots:
            slots = [{"star": "5", "lv": max(1, int(profile.get("lv", 1) or 1)), "slv": 1, "phase": 0,
                      "limit_break": 0, "talent_rank": 0, "culture_fraction": 0.0,
                      "culture_split": {key: 0 for key in STAT_KEYS}, "gear": []}]
        dn = profile.get("attrs", {}).get("dn", {})
        dn_levels = {str(node): int(value[0]) for node, value in (dn.items() if isinstance(dn, dict) else ())
                     if isinstance(value, (list, tuple)) and value and value[1:2] and value[1]
                     and str(node).isdigit() and int(value[0]) > 0}
        guild = profile.get("attrs", {}).get("guild_graduate_skill", {})
        guild = {str(k): int(v) for k, v in (guild.items() if isinstance(guild, dict) else ())
                 if str(k) in self.guild_caps and int(v) > 0}
        return {"schema": TEMPLATE_SCHEMA, "account_lv": max(1, int(profile.get("lv", 1) or 1)),
                "slots": slots, "dn": dn_levels, "guild": guild}

    @staticmethod
    def template_digest(template: dict) -> str:
        payload = json.dumps(template, sort_keys=True, ensure_ascii=False, separators=(",", ":"))
        return hashlib.sha256(payload.encode("utf-8")).hexdigest()

    # ------------------------------------------------------------------ build
    def _phase_cap(self, aid):
        star = aid.rsplit("_", 1)[-1]
        rows = self.simple.get("phase_config", [])
        table = rows[0] if isinstance(rows, list) and rows else {}
        row = table.get(str(int(star))) if isinstance(table, dict) and star.isdigit() else None
        return int(row[1]) if isinstance(row, list) and len(row) > 1 else 0

    def _talent(self, rng, rank):
        rank = max(0, min(self.max_talent_rank, int(rank)))
        options = self.talent_ranks.get(rank, [])
        return rng.choice(options) if options else None

    def _culture(self, hero, slot, progress):
        if not (weighted_active(self.simple, hero) and slot["culture_fraction"] > 0):
            return
        weights, _ = weighted_rules(self.simple, hero)
        total_cap = weighted_cap(hero, self.simple)
        fraction = (slot["culture_fraction"] * progress if progress <= 1 else
                    slot["culture_fraction"] + (1 - slot["culture_fraction"]) * (progress - 1) / (MAX_PROGRESS - 1))
        budget = int(total_cap * max(0.0, min(1.0, fraction)))
        split = slot["culture_split"]
        whole = sum(split.values()) or 1
        for key in STAT_KEYS:
            hero[key] = int(budget * split[key] / whole) // weights[key]
        hero["culture_schema"] = self.simple["culture"]["weighted"]["schema"]

    def _gear(self, item, progress, account_cap):
        result = copy.deepcopy(item)
        result["lv"] = _scaled(item.get("lv", 1), max(int(item.get("lv", 1)), account_cap), progress, 1)
        if int(item.get("slv", 0) or 0) > 0:
            result["slv"] = _scaled(item["slv"], 10, progress, 1)
        halo = item.get("halo") if isinstance(item.get("halo"), dict) else {}
        halo_lv = _scaled(halo.get("lv", item.get("haloLv", 0)), self.halo_cap, progress)
        result["halo"] = {"lv": halo_lv, "exp": 0}
        result["haloLv"] = halo_lv
        if "rune_lv" in item:
            result["rune_lv"] = _scaled(item["rune_lv"], self.rune_cap, progress)
        if isinstance(item.get("magic"), list):
            result["magic"] = [_scaled(v, max(int(v), 100), min(progress, 1.0)) for v in item["magic"]]
        wash = item.get("new_4attrs") if isinstance(item.get("new_4attrs"), dict) else {}
        result["new_4attrs"] = {key: _scaled(wash.get(key, 0), wash.get(key, 0), min(progress, 1.0))
                                for key in WASH_KEYS}
        return result

    def build(self, aids: list[str], template: dict, progress: float, seed: int, *,
              uid: str, name: str, lines=None) -> dict:
        """Return a full NPC profile. Deterministic for equal inputs."""
        rng = random.Random(seed)
        progress = max(0.0, min(MAX_PROGRESS, float(progress)))
        slots = template["slots"]
        account_cap = min(MAX_EQUIPMENT_LEVEL, max(template.get("account_lv", 1), 1) + 30)
        avatars, equips, groups, team = {}, {}, [], []
        for index, aid in enumerate(aids[:6]):
            slot = slots[index % len(slots)]
            # Native Avatar.reInit expects a numeric roster sequence after the pipe.
            iid = f"{aid}|{index + 1}"
            star = aid.rsplit("_", 1)[-1]
            limit_break = 1 if slot["limit_break"] and star in ("5", "6") else 0
            hero = {"id": iid, "aid": iid, "tpl": aid, "lv": 1, "slv": 1, "exp": 0, "phase": 0, "morph": 0,
                    "limit_break": limit_break, "equips": [], "hp": 0, "ap": 0, "de_ph": 0, "de_ma": 0,
                    "line": int(lines[index]) if lines and index < len(lines) else index % 3,
                    "pos": .2 if index < 3 else .1}
            level_cap = self.roster._hero_level_cap(aid, hero)
            hero["lv"] = _scaled(min(slot["lv"], level_cap), level_cap, progress, 1)
            hero["slv"] = _scaled(min(slot["slv"], self.skill_cap), self.skill_cap, progress, 1)
            phase_cap = self._phase_cap(aid)
            hero["phase"] = _scaled(min(slot["phase"], phase_cap), phase_cap, progress)
            hero["talent"] = self._talent(rng, _scaled(slot["talent_rank"], self.max_talent_rank, progress))
            self._culture(hero, slot, progress)
            avatars[iid] = hero
            team.append(iid)
            group = []
            for gear_index, item in enumerate(slot["gear"]):
                eqid = f"{uid}_e{index}_{gear_index}"
                equips[eqid] = self._gear(item, progress, account_cap)
                group.append(eqid)
            groups.append(group)
        while len(team) < 6:
            team.append(None)
            groups.append([])
        # DN nodes bind the NPC's own lineup; levels follow the template.
        members = [iid for iid in team if iid]
        dn = {}
        for offset, (node, level) in enumerate(sorted(template.get("dn", {}).items(), key=lambda kv: int(kv[0]))):
            dn[node] = [_scaled(level, 50, progress, 1), members[offset % len(members)]]
        guild = {key: _scaled(level, self.guild_caps.get(key, level), progress)
                 for key, level in template.get("guild", {}).items()}
        guild = {key: level for key, level in guild.items() if level > 0}
        return {"uid": uid, "name": name, "lv": template.get("account_lv", 1), "vip_lv": 0,
                "zone": "local", "avatars": avatars, "my_equips": equips, "as_equips": groups,
                "team": [team], "lines": list(lines) if lines else None,
                "attrs": {"team_num": 0, "dn": dn, "guild_graduate_skill": guild, "friend_len": 30},
                "records": {"help_suids": {}, "help_fuids": {}}}

    def units(self, profile: dict, *, scope: str, lines=None) -> list[dict]:
        """Serialize the NPC lineup through the player team path."""
        team = profile["team"][0]
        lines = lines or profile.get("lines") or [slot % 3 for slot in range(6)]
        submitted = [[iid, int(lines[slot]), .2 if slot < 3 else .1] if iid else None
                     for slot, iid in enumerate(team)]

        def attributes(owner, iid):
            return self.roster.battle_attributes(owner, iid, scope=scope)

        units = serialize_player_team(self.cfg, profile, 0, submitted, attributes)
        if scope == "arenaEnemy":
            # Keep the player's full stat calculation, then place opponents
            # on team 2 in native battlefield coordinates.
            battle = self.simple.get("battle", [])
            line_pos = int(battle[1]) if isinstance(battle, list) and len(battle) > 1 else 3000
            for unit in units:
                unit["isme"] = False
                unit["pos"] = line_pos - unit["pos"]
        return units

    def fit(self, aids, template, target_power, power_fn, seed, *, uid, name, scope, lines=None):
        """Find the cultivation progress whose real power is closest to target."""
        cache = {}

        def measure(progress):
            key = round(progress, 6)
            if key not in cache:
                profile = self.build(aids, template, progress, seed, uid=uid, name=name, lines=lines)
                units = self.units(profile, scope=scope, lines=lines)
                cache[key] = (power_fn(units), progress, profile, units)
            return cache[key]

        low, high = 0.0, MAX_PROGRESS
        if measure(high)[0] <= target_power:
            best = measure(high)
        elif measure(low)[0] >= target_power:
            best = measure(low)
        else:
            for _ in range(18):
                middle = (low + high) / 2
                if measure(middle)[0] < target_power:
                    low = middle
                else:
                    high = middle
            best = min((measure(low), measure(high)), key=lambda row: abs(row[0] - target_power))
        power, progress, profile, units = best
        return {"power": power, "progress": progress, "profile": profile, "units": units}


def template_stars(template: dict, size: int = 5) -> list[int]:
    """Quality wanted for each NPC slot, cycling the player's own lineup."""
    slots = template.get("slots") or [{"star": "5"}]
    return [int(slots[i % len(slots)]["star"]) for i in range(size)]
