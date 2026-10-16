"""Combat serialization and deterministic offline balance simulator.

The Android client retains its recovered turn/skill/RNG implementation; this
module produces its combat snapshots and offers an approximate simulator for
offline tuning. It does not claim bit-for-bit ActionScript parity.
"""
import copy
import math
from combat_math import level_stats
from combat_rng import CombatRandom


def _native_skill_snapshot(config, skill_id, level=1):
    """Serialize a configured SkillSet the way Avatar.toDataObj() exposes it."""
    if not skill_id:
        return None
    row = config.get("skill", {}).get(str(skill_id))
    if not isinstance(row, dict):
        return None
    pl = row.get("pl", [])
    actions = copy.deepcopy(row.get("skill", []))
    skill_up = row.get("skillUp")
    if isinstance(skill_up, list) and skill_up and isinstance(skill_up[0], list) and int(level) > 1:
        upgrades = []
        valid = True
        for entry in skill_up:
            if (not isinstance(entry, list) or len(entry) != 3
                    or not isinstance(entry[0], (int, float))
                    or not isinstance(entry[1], (int, float))
                    or not isinstance(entry[2], (int, float))):
                valid = False
                break
            action_index, value_index, step = int(entry[0]), int(entry[1]), float(entry[2])
            if (action_index != entry[0] or value_index != entry[1] or not math.isfinite(step)
                    or action_index < 0 or action_index >= len(actions)
                    or not isinstance(actions[action_index], list)
                    or value_index < 0 or value_index >= len(actions[action_index])
                    or not isinstance(actions[action_index][value_index], (int, float))):
                valid = False
                break
            upgrades.append((action_index, value_index, step))
        if valid:
            for action_index, value_index, step in upgrades:
                actions[action_index][value_index] += step * (int(level) - 1)
    elif (isinstance(skill_up, list) and len(skill_up) >= 2 and int(level) > 1
            and isinstance(skill_up[0], (int, float))
            and isinstance(skill_up[1], (int, float))):
        action_index = int(skill_up[0])
        if (0 <= action_index < len(actions) and isinstance(actions[action_index], list)
                and len(actions[action_index]) > 1):
            actions[action_index][1] += float(skill_up[1]) * (int(level) - 1)
    for entry in row.get("skillUpPaths", []) or []:
        if not isinstance(entry, list) or len(entry) != 3 or not isinstance(entry[1], list) or not entry[1]:
            continue
        action_index, path, step = entry
        if type(action_index) is not int or not 0 <= action_index < len(actions) or not isinstance(step, (int, float)) or not math.isfinite(step):
            continue
        target = actions[action_index]
        valid = True
        for index in path[:-1]:
            if type(index) is not int or not isinstance(target, list) or not 0 <= index < len(target):
                valid = False
                break
            target = target[index]
        leaf = path[-1]
        if valid and isinstance(target, list) and type(leaf) is int and 0 <= leaf < len(target) and isinstance(target[leaf], (int, float)):
            target[leaf] += step * (max(1, min(10, int(level))) - 1)
    return {
        "cd": int(pl[0]) if isinstance(pl, list) and pl and pl[0] is not None else 0,
        "pl": copy.deepcopy(pl),
        "skid": str(skill_id),
        "skills": actions,
        "actionTargetPolicies": copy.deepcopy(row.get("actionTargetPolicies") or []),
        "actionTargetPolicyArgs": copy.deepcopy(row.get("actionTargetPolicyArgs") or []),
        "actionTargetMaxTargets": copy.deepcopy(row.get("actionTargetMaxTargets") or []),
        "actionTargetGroups": copy.deepcopy(row.get("actionTargetGroups") or []),
    }


def validate_team_lane_coverage(team, lane_count, side="team"):
    """Require one live unit on every lane declared by native GameMapData.line[0]."""
    if type(lane_count) is not int or lane_count < 1:
        raise ValueError(f"invalid native lane count: {lane_count!r}")
    if not isinstance(team, list) or not team:
        raise ValueError(f"{side} has no combat units")
    if lane_count > len(team):
        raise ValueError(f"{side} cannot cover {lane_count} native lanes with {len(team)} units")
    present = set()
    for unit in team:
        if not isinstance(unit, dict):
            raise ValueError(f"{side} has a malformed combat unit")
        line = unit.get("line")
        if type(line) is not int or line < 0 or line >= lane_count:
            raise ValueError(f"{side} has a unit outside native lanes 0..{lane_count - 1}")
        if int(unit.get("hp", 1)) > 0:
            present.add(line)
    missing = sorted(set(range(lane_count)) - present)
    if missing:
        raise ValueError(f"{side} does not cover native lane(s): {', '.join(map(str, missing))}")
    return True


def base_unit(config, aid, level=1, slv=1, line=0, pos=0.2, leader=False, team=1,
              instance_id=None, overrides=None, *, enforce_avatar_level_cap=True,
              limit_break=False, npc_limit_break=False, summoned=False):
    avatar = config.get("avatar", {}).get(str(aid))
    if not avatar:
        raise ValueError(f"unknown combat avatar id: {aid}")
    tl = avatar.get("tl", [])
    level = int(level)
    if level < 1:
        raise ValueError("combatant level must be positive")
    limit_break = bool(limit_break and int(team) == 1 and instance_id
                       and str(aid).rsplit("_", 1)[-1] in ("5", "6"))
    npc_limit_break = bool(npc_limit_break and int(team) == 2 and not instance_id
                           and str(aid).rsplit("_", 1)[-1] == "6")
    if npc_limit_break and (enforce_avatar_level_cap or not 100 <= level <= 125):
        raise ValueError("limit-broken NPC requires an authored level 100..125 stage row")
    if limit_break and level > 125:
        raise ValueError("limit-broken player level exceeds 125")
    if enforce_avatar_level_cap and not limit_break:
        # tl[4] limits levels players may train this avatar to. Stage and NPC
        # tuples carry their own battle level and native Avatar.init accepts
        # that explicit value even when it exceeds the avatar progression cap.
        level = min(level, int(tl[4] if len(tl) > 4 else 99))
    elif summoned:
        # Native summon constructors accept the owner's explicit level, even
        # for templates whose trainable level cap is 1.
        if level > 125:
            raise ValueError("summoned level exceeds the owner level bound")
    elif not limit_break and not npc_limit_break and level > 99:
        # All reconstructed stage/activity/arena/fragment NPC rows are authored
        # at level 60 or below. Reject accidental/unbounded NPC data without
        # imposing this bound on player-owned levels or changing their cap.
        raise ValueError("configured NPC level exceeds the local stage bound")
    stats = level_stats(avatar, level, enforce_cap=enforce_avatar_level_cap and not limit_break)
    pl = avatar.get("pl", [])
    simple = config.get("system_simple", {})
    battle = simple.get("battle", []) if isinstance(simple, dict) else []
    line_pos = int(battle[1]) if isinstance(battle, list) and len(battle) > 1 else 3000
    # Formation params use a 0..1 screen proportion, while Avatar.toDataObj()
    # sends its internal 0..LINE_POS coordinate. Team 1 is measured from the
    # opposite side, exactly as Avatar.goFight(team, ..., posPer) does.
    pos_per = max(0.0, min(1.0, float(pos)))
    native_pos = round(line_pos * (1 - pos_per if int(team) == 1 else pos_per))
    skill = _native_skill_snapshot(config, pl[10] if len(pl) > 10 else None, slv)
    leader_skill = _native_skill_snapshot(config, pl[11] if len(pl) > 11 else None) if leader else None
    skill_b = _native_skill_snapshot(config, pl[13] if len(pl) > 13 else None)
    result = {"aid":str(aid),"ap":stats["attack"],"morph":0,"buffs":{},"de_ma":stats["magic_defense"],"de_ph":stats["physical_defense"],"hp":stats["health"],"hp_max":stats["health"],"isme":team==1,"leader":1 if leader else 0,"line":int(line),"lv":level,"new_4attrs":{"hit":0,"flee":0,"crit":0,"tough":0},"pos":native_pos,"slv":int(slv),"tpl":[int(tl[i]) if len(tl)>i else 0 for i in range(3)]+[int(pl[8]) if len(pl)>8 else 0,int(pl[9]) if len(pl)>9 else 0],"talent":None,"skill":skill,"leader_skill":leader_skill,"book_skill":None,"skillB":skill_b,"skill_diff":_to_int(avatar.get("skill_diff", 0))}
    if instance_id: result["instance_id"] = instance_id
    # Avatar.toDataObj includes advancement even when it is zero. Player
    # attributes already contain its stat bonus; the snapshot must also carry
    # the stored phase so origin checks compare the same progression state.
    result["phase"] = 0
    result["culture_schema"] = ""
    if limit_break or npc_limit_break: result["limit_break"] = 1
    if overrides:
        for key in ("hp","hp_max","ap","de_ma","de_ph","line","pos","new_4attrs","tpl","talent","skill","leader_skill","book_skill","skillB","morph","phase","culture_schema"):
            if key in overrides: result[key] = overrides[key]
    result["culture_schema"] = str(result.get("culture_schema") or "")
    return result


def serialize_stage_team(config, entries, team=2):
    result=[]
    for i,entry in enumerate(entries or []):
        if not isinstance(entry,(list,tuple)) or not entry: continue
        # Indexes 13/14 are trusted stage-only NPC advancement markers. They
        # are never read from submitted player formations.
        tower_break = len(entry) > 13 and entry[13] == 1
        if tower_break:
            star = str(entry[0]).rsplit("_", 1)[-1]
            if star != "6":
                raise ValueError("limit-broken NPC must be an orange hero")
            phase_rows = config.get("system_simple", {}).get("phase_config", [])
            try:
                phase_cap = int(phase_rows[0][star][1])
            except (IndexError, KeyError, TypeError, ValueError) as exc:
                raise ValueError("missing authored NPC phase cap") from exc
            if len(entry) < 15 or type(entry[14]) is not int or not 0 <= entry[14] <= phase_cap:
                raise ValueError("invalid authored NPC phase")
        unit=base_unit(config,str(entry[0]),int(entry[1]) if len(entry)>1 else 1,int(entry[2]) if len(entry)>2 else 1,int(entry[3]) if len(entry)>3 else i%3,float(entry[4]) if len(entry)>4 else .2+.16*i,bool(int(entry[5])) if len(entry)>5 else i==0,team,
                       enforce_avatar_level_cap=False,npc_limit_break=tower_break)
        if tower_break:
            unit["phase"] = entry[14]
        # Campaign workbook extensions follow the native tuple's equipment
        # fields at indexes 9/10. Side offset is a fraction of sideOffset.
        if len(entry)>11 and entry[11] is not None:
            side=float(entry[11])
            if not math.isfinite(side) or abs(side)>0.5:
                raise ValueError("stage side offset is outside native lane bounds")
            unit["side_offset"]=side
        if len(entry)>12 and entry[12] is not None:
            reach=int(entry[12])
            if reach<1 or reach>3000:
                raise ValueError("stage attack range is outside native bounds")
            unit["tpl"][4]=reach
            unit["manual_attack_range"]=reach
        result.append(unit)
    return result


def serialize_player_team(config, profile, team_num, submitted_team, attributes_fn=None):
    teams=profile.get("team") or []; index=max(0,min(int(team_num or 0),max(0,len(teams)-1)))
    saved=set(x for x in (teams[index] if teams else []) if x); roster=profile.get("avatars") or {}; result=[]
    for slot,row in enumerate((submitted_team if isinstance(submitted_team,list) else [])[:6]):
        if not row or not isinstance(row,(list,tuple)) or len(row)<3: continue
        iid=str(row[0])
        if iid not in saved or iid not in roster: continue
        instance=roster[iid]; aid=str(instance.get("aid",iid.split("|")[0]).split("|")[0])
        if len(row) >= 12:
            raw_line, pos = row[8], float(row[9])
        else:
            raw_line, pos = row[1], float(row[2])
        if type(raw_line) not in (int, float) or isinstance(raw_line, bool) or not math.isfinite(float(raw_line)) or float(raw_line) != int(raw_line):
            raise ValueError("formation lane must be an integer native line index")
        line = int(raw_line)
        raw = attributes_fn(profile,iid) if attributes_fn else {}
        overrides={"hp":raw.get("hp"),"hp_max":raw.get("hp_max",raw.get("hp")),"ap":raw.get("ap"),"de_ph":raw.get("de_ph"),"de_ma":raw.get("de_ma"),"tpl":raw.get("tpl"),"talent":raw.get("talent"),"morph":raw.get("morph"),"skill":raw.get("skill"),"leader_skill":raw.get("leader_skill") if slot == 0 else None,"book_skill":raw.get("book_skill"),"skillB":raw.get("skillB"),"new_4attrs":{"hit":raw.get("hit",0),"flee":raw.get("flee",0),"crit":raw.get("crit",0),"tough":raw.get("tough",0)}} if attributes_fn else None
        result.append(base_unit(config,aid,int(instance.get("lv",1)),int(instance.get("slv",1)),line,max(0.0,min(1.0,pos)),slot==0,1,iid,overrides,
                                limit_break=instance.get("limit_break") == 1))
        # Read progression from the owned roster, never from submitted tuples.
        result[-1]["phase"] = max(0, int(instance.get("phase", 0)))
        result[-1]["culture_schema"] = str(raw.get("culture_schema", instance.get("culture_schema", "")) or "")
    if not result: raise ValueError("battle requires at least one saved formation avatar")
    return result


# Original Avatar constants (137_Avatar.as:832/834/836).
_MIN_DAMAGE_RATE = 0.1
_REAL_DAMAGE_RATE = 0.3

# Buff.LIST_BUFF / Buff.LIST_DEBUFF (140_Buff.as:57/59).
_GOOD_BUFFS = frozenset(["shield", "strong", "taunt", "bless", "steel", "armor",
                         "hitup", "fleeup", "critup", "toughup", "purify"])
_DEBUFFS = frozenset(["root", "stun", "silence", "weak", "sunder", "poison", "burn", "evil", "curse"])

# checkBuffOfSkillB's literal OR list (079_Avatar.as:3547-3552). This is the
# exact string set the client compares against, so it is NOT _GOOD_BUFFS:
# "armor" is absent here and "root" is not consulted, while the check runs over
# the whole buff table rather than only the good/bad partitions.
_SKILL_B_GUARD_BUFFS = frozenset(["evil", "silence", "stun", "burn", "sunder", "poison",
                                  "weak", "shield", "purify", "strong", "hitup", "fleeup",
                                  "critup", "toughup", "bless", "steel", "taunt"])
# skill_diff 19's own gate (079_Avatar.as:3553): fire while any debuff is held.
_SKILL_B_DEBUFF_TRIGGERS = frozenset(["root", "evil", "silence", "stun", "burn",
                                     "sunder", "poison", "weak", "curse"])
# skill_diff -> the single buff name that arms the passive (079_Avatar.as:3503-3545).
_SKILL_B_BUFF_TRIGGERS = {4: "evil", 5: "silence", 6: "stun", 7: "burn", 8: "sunder",
                          9: "poison", 10: "weak", 11: "shield", 12: "purify", 13: "strong",
                          15: "bless", 16: "steel", 17: "taunt"}

# hasBoundedSummonPolicy (139_SkillSet.as:3067). The id-shape gate admits every
# S_<family>_<2..6>; the shape alone is far too broad, so the authored
# per-family arms decide. Families that are bounded only at some star levels.
_BOUNDED_SUMMON_STARS = {"2061205": ("5", "6"), "32551036": ("4", "5", "6"),
                         "32551103": ("4", "5", "6")}
# Families bounded at every star level the shape gate admits.
_BOUNDED_SUMMON_FAMILIES = frozenset(["621014", "631014", "303014", "203014", "303029",
                                      "303040", "303124", "305082", "305128", "301209", "301221",
                                      "301310"])

# Kinds whose resolved target is published to actionTargets[actionIndex] for a
# later action in the same skill to consume.
_PUBLISH_TARGET = frozenset([
    "damage", "true_damage", "suck", "combo", "stun", "stun_by_condition", "silence",
    "weak", "weak_percent", "sunder", "sunder_percent", "poison", "burn",
    "conditional_damage", "locked_sequence", "locked_sequence_area", "locked_combo_weak",
    "shield_followup", "dispel_good", "lethal_floor_group", "heal_missing_hp_per_hero",
])


def _to_int(value):
    """ActionScript's Tools.toInt: truncation toward zero, NaN -> 0."""
    try:
        number = float(value)
    except (TypeError, ValueError):
        return 0
    if not math.isfinite(number):
        return 0
    return int(number)


def _percent_debuff_value(raw):
    """139_SkillSet.as:2518 getPercentDebuffValue -> internal multiplier scale."""
    if not isinstance(raw, (int, float)) or isinstance(raw, bool):
        return -1
    value = float(raw)
    if not math.isfinite(value) or value < 0 or value > 0.95:
        return -1
    if value == 0:
        return 0
    return value / (1 - value)


class _Buff:
    """Mirror of Buff(type, round, value) from 140_Buff.as."""
    __slots__ = ("type", "round", "value")

    def __init__(self, kind, rounds, value=0):
        self.type = str(kind)
        self.round = _to_int(rounds)
        self.value = value


class ReferenceBattle:
    """Approximate deterministic tuner; client results remain authoritative."""
    _LINE_POS = 3000
    _MIN_SPACE_POS = 200
    _SUMMON_POS = 500

    def __init__(self, team_a, team_b, seed=82684, max_rounds=30, config=None):
        self.a = copy.deepcopy([dict(x) for x in team_a])
        self.b = copy.deepcopy([dict(x) for x in team_b])
        # boundedSummons belongs to each SkillSet/Avatar instance. Keep the
        # public aid for compatibility and add a private owner token so two
        # copies of the same hero do not share one bounded summon slot.
        for side, roster in ((1, self.a), (2, self.b)):
            for index, unit in enumerate(roster):
                unit.setdefault("_owner_token", unit.get("instance_id") or f"{side}:{index}")
        self.rng = CombatRandom(int(seed))
        self.max_rounds = max(1, int(max_rounds))
        # Kept for the avatar-table lookups the action handlers need (cast
        # range, ranged-caster classification). Serialized unit dicts are never
        # widened to carry it.
        self._config = config if isinstance(config, dict) else {}
        simple = self._config.get("system_simple", {}) if isinstance(self._config, dict) else {}
        attack = simple.get("attack", []) if isinstance(simple, dict) else []
        battle = simple.get("battle", []) if isinstance(simple, dict) else []
        # attack[18] is the poison hpMax-fraction term; attack[20] the bless
        # revival fraction (137_Avatar.as:2908 / 5707).
        self._poison_hp_fraction = float(attack[18]) if isinstance(attack, list) and len(attack) > 18 else 0.01
        self._bless_fraction = float(attack[20]) if isinstance(attack, list) and len(attack) > 20 else 0.5
        # Native authored bounds; keep the module constants as the default so
        # the class stays usable without a config.
        if isinstance(battle, list) and len(battle) > 2:
            self._LINE_POS = int(battle[1])
            self._MIN_SPACE_POS = int(battle[2])
        else:
            self._LINE_POS, self._MIN_SPACE_POS = 3000, 200
        self._SUMMON_POS = int(battle[3]) if isinstance(battle, list) and len(battle) > 3 else 500
        # skillAreaRadius (137_Avatar.as:461) scales authored radii by
        # GlobalData.$mConfig_simple.skill_effect_radius_scale. The reconstructed
        # config authors 1.4; a missing/non-finite/non-positive value means 1.
        raw_scale = simple.get("skill_effect_radius_scale") if isinstance(simple, dict) else None
        if isinstance(raw_scale, (int, float)) and not isinstance(raw_scale, bool) \
                and math.isfinite(float(raw_scale)) and float(raw_scale) > 0:
            self._skill_radius_scale = float(raw_scale)
        else:
            self._skill_radius_scale = 1.0
        # Manual stack / timed stack / manual-DOT side tables (137_Avatar.as
        # :2287/2304/2392). Stored per unit dict under an underscore key so the
        # serialized shape is untouched.
        self._aoe_slack = 0
        # Serial stamped onto stacked manual-DOT layers so a re-application with
        # stack=true becomes its own layer instead of merging (137:2392).
        self._manual_dot_serial = 0

    # ---------------------------------------------------------------- buffs

    @staticmethod
    def _buff(unit, kind):
        container = unit.get("_buffs")
        if not isinstance(container, dict):
            container = {}
            unit["_buffs"] = container
        return container.get(kind)

    @staticmethod
    def _buff_value(unit, kind, default=0):
        entry = ReferenceBattle._buff(unit, kind)
        return entry.value if entry is not None else default

    def _add_buff(self, unit, kind, rounds, value=0):
        """addBuff tail (137_Avatar.as:2619): merge rules differ per buff.

        Two compare arms and one merge arm; a kind in neither arm has its new
        buff silently discarded when one is already present.
        """
        kind = str(kind)
        container = unit.setdefault("_buffs", {})
        current = container.get(kind)
        incoming = _Buff(kind, rounds, value)
        # Purify has priority over every debuff, including evil and curse. It
        # must clear them before the one-shot evil/purify guards are checked.
        if kind == "purify":
            self._remove_all_debuff(unit)
            unit.pop("_curse_window_started", None)
        if container.get("purify") is not None and kind in _DEBUFFS:
            # An armed purify refuses one incoming debuff and is consumed.
            del container["purify"]
            return
        if container.get("curse") is not None and kind in _GOOD_BUFFS and kind != "purify":
            # Unlike evil's one-shot guard, curse rejects positive buffs while
            # its normal owner-turn countdown remains active.
            return
        if container.get("evil") is not None and kind in _GOOD_BUFFS:
            del container["evil"]
            return
        if current is None:
            container[kind] = incoming
            if kind == "purify":
                self._remove_all_debuff(unit)
            elif kind == "evil":
                self._remove_all_good(unit)
            return
        if kind in ("stun", "silence", "purify", "evil", "curse", "taunt", "bless"):
            # Round-compare arm: the longer duration wins outright.
            if incoming.round >= current.round:
                container[kind] = incoming
                if kind == "purify":
                    self._remove_all_debuff(unit)
                elif kind == "evil":
                    self._remove_all_good(unit)
            return
        if kind in ("poison", "burn"):
            # Remaining total damage is preserved and re-spread over the new
            # duration (137_Avatar.as:2669).
            if incoming.round != 0:
                current.value = _to_int(current.value * current.round / incoming.round
                                        + incoming.value)
            current.round = incoming.round
            return
        if kind in ("root", "weak", "sunder", "shield", "strong", "steel", "armor",
                    "hitup", "fleeup", "critup", "toughup"):
            # Value-compare arm.
            if incoming.value >= current.value:
                container[kind] = incoming
            return
        # back / summon and every other kind: the new buff is discarded.

    def _remove_buff(self, unit, kind):
        container = unit.get("_buffs")
        if isinstance(container, dict):
            container.pop(str(kind), None)

    def _remove_all_good(self, unit):
        container = unit.get("_buffs")
        if not isinstance(container, dict):
            return
        for kind in [k for k in container if k in _GOOD_BUFFS]:
            del container[kind]

    def _remove_all_debuff(self, unit):
        container = unit.get("_buffs")
        if not isinstance(container, dict):
            return
        for kind in [k for k in container if k in _DEBUFFS]:
            del container[kind]

    def _tick_buffs(self, unit):
        """checkBuff (137_Avatar.as:2857): per-owner-turn buff expiry and DOTs."""
        container = unit.get("_buffs")
        if not isinstance(container, dict) or not container:
            # Manual DOT rows live outside the buff map and still expire.
            return self._tick_manual_skill_dots(unit)
        for kind in list(container):
            entry = container.get(kind)
            if entry is None:
                continue
            # Bless stays armed until a lethal hit consumes it.
            if kind == "bless":
                continue
            entry.round -= 1
            if kind == "summon" and entry.round < 0:
                unit["hp"] = 0
                return True
            if entry.round < 0:
                del container[kind]
        poison = container.get("poison")
        if poison is not None:
            tick = _to_int(poison.value * _REAL_DAMAGE_RATE
                           + self._poison_hp_fraction * int(unit.get("hp_max", 0)))
            self._injured(unit, tick, damage_type=3)
            if int(unit.get("hp", 0)) <= 0:
                unit["hp"] = 0
                return True
            if poison.round <= 0:
                del container["poison"]
        burn = container.get("burn")
        if burn is not None:
            self._injured(unit, _to_int(burn.value * _REAL_DAMAGE_RATE), damage_type=3)
            if int(unit.get("hp", 0)) <= 0:
                unit["hp"] = 0
                return True
            if burn.round <= 0:
                del container["burn"]
        return self._tick_manual_skill_dots(unit)

    # --------------------------------------------------------------- getters

    @staticmethod
    def _talent(unit, index):
        talent = unit.get("talent")
        if isinstance(talent, (list, tuple)) and len(talent) > index:
            value = talent[index]
            if isinstance(value, (int, float)) and not isinstance(value, bool):
                return float(value)
        return 0.0

    def _get_damage(self, unit):
        """getDamage (137_Avatar.as:3222): weak/strong scale outgoing damage.

        checkTalent(1) is applied by the calling action, not inside the getter
        (see the poison/burn and heal formulas).
        """
        value = float(unit.get("ap", 1))
        weak = self._buff_value(unit, "weak")
        if weak:
            value /= 1 + float(weak)
        strong = self._buff_value(unit, "strong")
        if strong:
            value *= 1 + float(strong)
        return value

    def _ap_with_talent(self, unit):
        """The ``Tools.toInt(getDamage() * (1 + checkTalent(1)))`` call-site form."""
        return _to_int(self._get_damage(unit) * (1.0 + self._talent(unit, 1)))

    def _get_de_ph(self, unit):
        """getDePh (137_Avatar.as:3302): sunder/steel then the armor buff."""
        value = float(unit.get("de_ph", 0))
        sunder = self._buff_value(unit, "sunder")
        if sunder:
            value /= 1 + float(sunder)
        steel = self._buff_value(unit, "steel")
        if steel:
            value *= 1 + float(steel)
        value = max(_to_int(value), 0)
        armor = self._buff_value(unit, "armor")
        if armor:
            value = max(_to_int(value * (1 + float(armor))), 0)
        return value

    def _get_de_ma(self, unit):
        """getDeMa (137_Avatar.as:3381): same, but with no armor term."""
        value = float(unit.get("de_ma", 0))
        sunder = self._buff_value(unit, "sunder")
        if sunder:
            value /= 1 + float(sunder)
        steel = self._buff_value(unit, "steel")
        if steel:
            value *= 1 + float(steel)
        return max(_to_int(value), 0)

    def _raw_attr(self, unit, key):
        """The base value of one of the four secondary stats (new_4attrs)."""
        raw = unit.get("new_4attrs")
        if not isinstance(raw, dict):
            return 0.0
        value = raw.get(key, 0)
        if not isinstance(value, (int, float)) or isinstance(value, bool):
            return 0.0
        return float(value)

    def _stat_buff(self, unit, key):
        """hit/flee/crit/tough (137_Avatar.as:3520/3558/3596/3634).

        All four share one shape: the raw stat, plus the matching ``*up`` buff
        value added flat. There is no ``*down`` counterpart and no multiplier —
        attrup's value is already an absolute amount, so it is added, not
        scaled in.
        """
        return _to_int(self._raw_attr(unit, key)) + _to_int(self._buff_value(unit, key + "up"))

    def _get_hit(self, unit):
        return self._stat_buff(unit, "hit")

    def _get_flee(self, unit):
        return self._stat_buff(unit, "flee")

    def _get_crit(self, unit):
        return self._stat_buff(unit, "crit")

    def _get_tough(self, unit):
        return self._stat_buff(unit, "tough")

    # ---------------------------------------------------------------- damage

    def _injured(self, target, amount, damage_type=0):
        """injured (137_Avatar.as:5545): the shield pool absorbs before HP.

        Returns the HP actually lost. ``damage_type`` 4 heals and 5/0 applies
        nothing, matching countDamage.
        """
        amount = _to_int(amount)
        if int(damage_type) == 4:
            missing = max(0, int(target.get("hp_max", 0)) - int(target.get("hp", 0)))
            healed = max(0, min(missing, amount))
            target["hp"] = int(target.get("hp", 0)) + healed
            return -healed
        if int(damage_type) in (0, 5) or amount <= 0:
            return 0
        shield = self._buff(target, "shield")
        if shield is not None:
            absorbed = min(max(0, _to_int(shield.value)), amount)
            shield.value = _to_int(shield.value) - absorbed
            if shield.value <= 0:
                self._remove_buff(target, "shield")
            amount -= absorbed
        if amount <= 0:
            return 0
        target["hp"] = max(0, int(target.get("hp", 0)) - amount)
        self._resolve_lethal(target)
        return amount

    def _resolve_lethal(self, target):
        """Lethal guards in injured order: bless, then trynd undying."""
        if int(target.get("hp", 0)) > 0:
            return
        if self._buff(target, "bless") is not None:
            self._remove_buff(target, "bless")
            self._remove_all_debuff(target)
            target["hp"] = max(1, _to_int(int(target.get("hp_max", 0)) * self._bless_fraction))
            return
        if int(target.get("_trynd_rounds", 0)) > 0:
            target["_trynd_rounds"] = 0
            target["hp"] = 1
            return
        target["hp"] = 0

    def _injured_absolute(self, target, amount, damage_type):
        """attackAimList's damageType -1: an absolute value, no scaling stage.

        Every other channel multiplies ``getDamage()`` by a coefficient first;
        -1 is the auto-attack form (137_Avatar.as:5056), so the amount is used
        as-is and only the defence and minimum-damage floors apply.
        """
        amount = _to_int(amount)
        damage_type = _to_int(damage_type)
        if damage_type == 1:
            defense = max(0, self._get_de_ph(target))
        elif damage_type in (2, 3):
            defense = max(0, self._get_de_ma(target)) if damage_type == 2 else 0
        else:
            defense = 0
        if damage_type == 3:
            dealt = _to_int(amount * _REAL_DAMAGE_RATE)
        elif damage_type in (1, 2):
            dealt = max(_to_int(amount * _MIN_DAMAGE_RATE), amount - defense)
        else:
            dealt = amount
        return self._injured(target, dealt, damage_type)

    def _native_damage(self, attacker, target, multiplier, damage_type):
        """countDamage (137_Avatar.as:1283) plus the getters' buff multipliers."""
        damage_type = _to_int(damage_type)
        if damage_type == 1:
            base = max(1, _to_int(self._get_damage(attacker) * float(multiplier)))
            dealt = max(_to_int(base * _MIN_DAMAGE_RATE), base - max(0, self._get_de_ph(target)))
        elif damage_type == 3:
            dealt = _to_int(max(1, _to_int(self._get_damage(attacker) * float(multiplier))) * _REAL_DAMAGE_RATE)
        else:
            base = max(1, _to_int(self._get_damage(attacker) * float(multiplier)))
            dealt = max(_to_int(base * _MIN_DAMAGE_RATE), base - max(0, self._get_de_ma(target)))
        return self._injured(target, dealt, damage_type)

    # -------------------------------------------------------------- targeting

    def _skill_targets(self, attacker, candidates, pl, enemies=None, skill=None, index=None):
        """Range/line filter, then the native target count from pl[4].

        pl[4] == -1 means "every eligible target in range" (the authored
        server form). It previously collapsed to a single target because the
        Python read it as a count and applied ``max(1, -1 + 1)``.

        When ``skill`` and ``index`` are supplied the action's own
        actionTargetPolicies row is honoured (139_SkillSet.as:2380): the
        policy replaces the range/line filter rather than refining it, which
        is what getActionRange collapsing to the cast range would do. An
        unrecognized policy falls back to the geometric filter, and the
        caller keeps its taunt pull.
        """
        alive = [u for u in candidates if int(u.get("hp", 0)) > 0]
        if not alive:
            return []
        policy = None
        if isinstance(skill, dict) and index is not None:
            policies = skill.get("actionTargetPolicies")
            if isinstance(policies, list) and 0 <= index < len(policies):
                policy = policies[index]
        if policy == "enemy_global_lowest_current_hp":
            # 139_SkillSet.as:2731-2875. Only heroes are eligible
            # (_avatar.getType() != 1 is skipped), then the survivors are
            # sorted by current hp ascending.
            heroes = [u for u in alive if _to_int(self._get_type(u)) == 1]
            # This policy is explicitly hero-only.  The client does not fall
            # back to a minion or summon when the opposing side has no hero.
            if not heroes:
                return []
            pool = heroes
            pool = sorted(pool, key=lambda u: (int(u.get("hp", 0)), u.get("line", 0),
                                               float(u.get("pos", 0))))
            return pool[:max(1, self._policy_max_targets(skill, index, 1))]
        if policy == "ally_all":
            return sorted(alive, key=lambda u: (u is not attacker, u.get("line", 0),
                                                float(u.get("pos", 0))))
        if policy in ("enemy_lane_all", "enemy_lane_all_in_radius"):
            alive = [u for u in alive
                     if u.get("line") == attacker.get("line")]
            args = self._policy_args(skill, index)
            radius = args.get("radius") if isinstance(args, dict) else None
            if policy == "enemy_lane_all_in_radius" and isinstance(radius, (int, float)):
                alive = [u for u in alive
                         if abs(float(u.get("pos", 0)) - float(attacker.get("pos", 0))) <= float(radius)]
            alive.sort(key=lambda u: (abs(float(u.get("pos", 0)) - float(attacker.get("pos", 0))),
                                     int(u.get("hp", 0))))
            limit = self._policy_max_targets(skill, index, -1)
            return alive if limit < 0 else alive[:limit]
        reach = abs(int(pl[2])) if len(pl) > 2 else 0
        if reach <= 0:
            return []
        # Avatar.findAimList keeps a finite cast range on the caster's lane
        # through LINE_POS (3000); only ranges beyond the lane length may
        # select across lanes.  The previous 100-unit cutoff made long-range
        # lane-wide skills, including Steel Teemo's strike, hit every lane.
        if reach <= self._LINE_POS:
            alive = [u for u in alive if u.get("line") == attacker.get("line")]
        alive = [u for u in alive
                 if abs(float(u.get("pos", 0)) - float(attacker.get("pos", 0))) <= reach]
        alive.sort(key=lambda u: (u.get("line") != attacker.get("line"),
                                  abs(float(u.get("pos", 0)) - float(attacker.get("pos", 0))),
                                  int(u.get("hp", 0))))
        if not alive:
            return []
        # Taunt pulls targeting onto the taunting unit when one is reachable.
        for unit in alive:
            if self._buff(unit, "taunt") is not None:
                return [unit]
        count = int(pl[4]) if len(pl) > 4 else 0
        if count == -1:
            return alive
        return alive[:max(1, count + 1)]

    @staticmethod
    def _policy_max_targets(skill, index, default):
        """actionTargetMaxTargets[index]; -1 and absent both mean "unbounded"."""
        limits = skill.get("actionTargetMaxTargets") if isinstance(skill, dict) else None
        if not isinstance(limits, list) or not 0 <= index < len(limits):
            return default
        value = _to_int(limits[index])
        return value if value > 0 or value == -1 else default

    @staticmethod
    def _policy_args(skill, index):
        args = skill.get("actionTargetPolicyArgs") if isinstance(skill, dict) else None
        if not isinstance(args, list) or not 0 <= index < len(args):
            return None
        return args[index] if isinstance(args[index], dict) else None

    # ------------------------------------------------- manual side tables

    def _add_manual_skill_dot(self, target, key, kind, ap_tick, hp_max_fraction,
                              rounds, source, damage_type, stack):
        """137_Avatar.as:2392 addManualSkillDot.

        Guards: non-empty key, a known kind, finite ap>=0, finite fraction>=0,
        rounds>=1. An armed purify absorbs the application and is consumed.
        """
        if not key or kind not in ("poison", "burn", "bleed"):
            return False
        if not isinstance(ap_tick, (int, float)) or isinstance(ap_tick, bool) or not math.isfinite(float(ap_tick)) or float(ap_tick) < 0:
            return False
        if not isinstance(hp_max_fraction, (int, float)) or isinstance(hp_max_fraction, bool) or not math.isfinite(float(hp_max_fraction)) or float(hp_max_fraction) < 0:
            return False
        if _to_int(rounds) < 1:
            return False
        if self._buff(target, "purify") is not None:
            self._remove_buff(target, "purify")
            return False
        if stack:
            self._manual_dot_serial = int(getattr(self, "_manual_dot_serial", 0)) + 1
            key = "%s:layer:%d" % (key, self._manual_dot_serial)
        target.setdefault("_manual_dots", {})[key] = {
            "kind": str(kind),
            "apTick": max(0, _to_int(ap_tick)),
            "hpMaxFraction": float(hp_max_fraction),
            "damageType": _to_int(damage_type),
            "round": _to_int(rounds),
            "source": source,
        }
        # The dot also shows as a native poison/burn buff; bleed renders as
        # poison (140_Buff.as). Merged, so the visual is additive on reapply.
        visual_kind = "poison" if kind == "bleed" else str(kind)
        self._add_buff(target, visual_kind, _to_int(rounds), max(0, _to_int(ap_tick)))
        return True

    def _has_manual_dot_kind(self, unit, kind):
        """137_Avatar.as:2426 hasManualDotKind."""
        if kind in ("poison", "burn") and self._buff(unit, kind) is not None:
            return True
        for entry in (unit.get("_manual_dots") or {}).values():
            if isinstance(entry, dict) and _to_int(entry.get("round", 0)) > 0 and entry.get("kind") == kind:
                return True
        return False

    def _tick_manual_skill_dots(self, unit):
        """The per-owner-turn half of checkBuff for manual DOT rows."""
        container = unit.get("_manual_dots")
        if not isinstance(container, dict) or not container:
            return False
        for key in list(container):
            entry = container.get(key)
            if not isinstance(entry, dict):
                del container[key]
                continue
            entry["round"] = _to_int(entry.get("round", 0)) - 1
            if entry["round"] < 0:
                del container[key]
                continue
            tick = _to_int(entry.get("apTick", 0)) + _to_int(float(entry.get("hpMaxFraction", 0.0))
                                                             * int(unit.get("hp_max", 0)))
            self._injured(unit, tick, damage_type=_to_int(entry.get("damageType", 0)))
            if int(unit.get("hp", 0)) <= 0:
                unit["hp"] = 0
                return True
        return False

    def _get_manual_battle_stack(self, unit, stat):
        """137_Avatar.as:2287 getManualBattleStack."""
        stacks = unit.get("_manual_battle_stacks")
        if not isinstance(stacks, dict):
            return 0
        return max(0, _to_int(stacks.get(str(stat), 0)))

    def _add_manual_battle_stack(self, unit, stat, value, cap):
        """137_Avatar.as:2293 addManualBattleStack (attack/defense/flee only)."""
        stat = str(stat)
        if stat not in ("attack", "defense", "flee"):
            return False
        if not isinstance(value, (int, float)) or isinstance(value, bool) or not math.isfinite(float(value)) or float(value) <= 0:
            return False
        if _to_int(cap) < 1:
            return False
        stacks = unit.setdefault("_manual_battle_stacks", {})
        stacks[stat] = min(float(_to_int(cap)) * float(value),
                           float(self._get_manual_battle_stack(unit, stat)) + float(value))
        return True

    def _add_manual_timed_stack(self, unit, stat, value, max_stacks, expire_rounds):
        """137_Avatar.as:2317 addManualTimedStack."""
        if str(stat) != "attack":
            return False
        if not isinstance(value, (int, float)) or isinstance(value, bool) or not math.isfinite(float(value)) or float(value) <= 0 or float(value) > 1:
            return False
        max_stacks, expire_rounds = _to_int(max_stacks), _to_int(expire_rounds)
        if max_stacks < 1 or max_stacks > 8 or expire_rounds < 1 or expire_rounds > 20:
            return False
        serial = _to_int(unit.get("_action_serial", 0))
        entries = [e for e in (unit.get("_timed_stacks") or [])
                   if isinstance(e, dict) and _to_int(e.get("expiresAt", 0)) >= serial]
        if sum(1 for e in entries if e.get("stat") == str(stat)) >= max_stacks:
            return False
        entries.append({"stat": str(stat), "value": float(value),
                        "expiresAt": serial + expire_rounds})
        unit["_timed_stacks"] = entries
        return True

    def _get_manual_timed_stack(self, unit, stat):
        """137_Avatar.as:2304 getManualTimedStack."""
        serial = _to_int(unit.get("_action_serial", 0))
        total = sum(float(e.get("value", 0)) for e in (unit.get("_timed_stacks") or [])
                    if isinstance(e, dict) and e.get("stat") == str(stat)
                    and _to_int(e.get("expiresAt", 0)) >= serial)
        return max(0.0, total)

    # ------------------------------------------------- native action geometry

    def _skill_area_radius(self, raw):
        """139_SkillSet.as skillAreaRadius -> 137_Avatar.as:461.

        ``Math.round(value * skill_effect_radius_scale)``; a non-finite or
        non-positive authored value collapses to 1.
        """
        value = float(raw) if isinstance(raw, (int, float)) and not isinstance(raw, bool) else float("nan")
        if not math.isfinite(value) or value <= 0:
            return 1
        return _to_int(math.floor(value * self._skill_radius_scale + 0.5))

    def _avatar_definition(self, unit):
        table = self._config.get("avatar", {}) if isinstance(self._config, dict) else {}
        return table.get(str(unit.get("aid"))) if isinstance(table, dict) else None

    @staticmethod
    def _get_type(unit):
        """137_Avatar.as:4053 getType() = int(avatarData.id.slice(2,3)).

        The third character of the authored id is the native type: 1 hero,
        2 summon/creep, 3 structure. The serialized ``tpl`` array does not
        carry it, so it must be read off the id.
        """
        aid = str(unit.get("aid", ""))
        if len(aid) < 3:
            return 0
        try:
            return int(aid[2])
        except (TypeError, ValueError):
            return 0

    def _is_ranged_skill_caster(self, unit):
        """137_Avatar.as:4023 isRangedSkillCaster.

        Heroes only, and only when the avatar row marks the kit ranged
        (``ranged_skill`` boolean, else ``range >= 500``). The trailing
        jayce_n form clause (``A_1041_`` in hammer form) needs ability form
        state the snapshot does not carry, so it is treated as "not hammer".
        """
        if self._get_type(unit) != 1:
            return False
        row = self._avatar_definition(unit)
        if isinstance(row, dict):
            flag = row.get("ranged_skill")
            if isinstance(flag, bool):
                ranged = flag
            else:
                try:
                    ranged = float(row.get("range")) >= 500
                except (TypeError, ValueError):
                    ranged = False
        else:
            ranged = _to_int(unit.get("range", 0)) >= 500
        if not ranged:
            return False
        return str(unit.get("aid", "")).find("A_1041_") != 0

    def _get_range(self, unit):
        """137_Avatar.as:3497 getRange(false)."""
        override = unit.get("manual_attack_range")
        if isinstance(override, (int, float)) and not isinstance(override, bool) \
                and math.isfinite(float(override)) and float(override) > 0:
            return _to_int(override)
        # Native Avatar.init restores its cached range from snapshot.tpl[4].
        # Serialized units have hp_max but need not carry a top-level range.
        tpl = unit.get("tpl") or []
        candidates = [unit.get("range")]
        if isinstance(tpl, (list, tuple)) and len(tpl) > 4:
            candidates.append(tpl[4])
        for value in candidates:
            if isinstance(value, (int, float)) and not isinstance(value, bool) \
                    and math.isfinite(float(value)):
                return _to_int(value)
        row = self._avatar_definition(unit)
        if isinstance(row, dict):
            pl = row.get("pl") or []
            return _to_int(row.get("range", pl[9] if len(pl) > 9 else 0))
        return 0

    def _get_cast_range(self, unit, skill):
        """139_SkillSet.as:2591 getCastRange.

        The jayce_n hammer special case needs ability form state that the
        serialized snapshot does not carry, so it degrades to LINE_POS for the
        ranged branch below.
        """
        pl = skill.get("pl") if isinstance(skill, dict) else None
        if not isinstance(pl, list) or len(pl) < 3:
            return 0
        raw = pl[2]
        if not isinstance(raw, (int, float)) or isinstance(raw, bool) or not math.isfinite(float(raw)):
            return 0
        distance = _to_int(abs(float(raw)))
        if 0 < distance <= self._LINE_POS and self._is_ranged_skill_caster(unit):
            return self._LINE_POS
        return distance

    def _get_forward_pos(self, team, line):
        """014_GameMap.as:774 getForwardPos."""
        if int(team) == 1:
            listing = self.a
            frontier = int(self._LINE_POS)
        else:
            listing = self.b
            frontier = 0
        for unit in listing:
            if int(unit.get("line", -1)) != int(line) or int(unit.get("hp", 0)) <= 0:
                continue
            try:
                pos = _to_int(unit.get("pos", 0))
            except (TypeError, ValueError):
                continue
            frontier = min(frontier, pos) if int(team) == 1 else max(frontier, pos)
        if int(team) == 1:
            return min(frontier - int(self._MIN_SPACE_POS), int(self._LINE_POS))
        return max(frontier + int(self._MIN_SPACE_POS), 0)

    def _get_final_pos(self, team, line, pos):
        """014_GameMap.as:818 getFinalPos."""
        frontier = self._get_forward_pos(3 - int(team), line)
        target = _to_int(pos)
        if int(team) == 1:
            return min(int(self._LINE_POS), max(frontier, target))
        return max(0, min(frontier, target))

    @staticmethod
    def _team_number(unit):
        """Convert Avatar.toDataObj's ``isme`` flag to its native team number."""
        return 1 if bool(unit.get("isme")) else 2

    def _reline(self, unit, line, pos=None, offset=None, forced=False):
        """137_Avatar.as:4770 reline (the -2147483648 sentinels mean "default")."""
        if self._rooted(unit) and not forced:
            return False
        unit["line"] = int(line)
        if pos is None:
            unit["pos"] = int(self._LINE_POS) if int(unit.get("isme")) else 0
        else:
            unit["pos"] = self._get_final_pos(self._team_number(unit), line, pos)
        unit["offset"] = 0 if offset is None else offset
        return True

    def _check_move(self, unit, forward, distance=0, forced=False):
        """137_Avatar.as:4576 checkMove, reduced to the position update."""
        if self._rooted(unit) and not forced:
            return 0
        normal_move = not distance and not forced
        amount = abs(_to_int(distance))
        if amount == 0:
            amount = self._get_speed(unit)
        team = self._team_number(unit)
        if bool(forward):
            delta = -amount if team == 1 else amount
        else:
            delta = amount if team == 1 else -amount
        before = _to_int(unit.get("pos", 0))
        target = before + delta
        if normal_move:
            roster = self.a if team == 1 else self.b
            owner_token = unit.get("summon_owner_token")
            if unit.get("aid") in ("A_2003_2", "A_2018_2", "A_2024_6") and owner_token is not None:
                owner = next((u for u in roster if u.get("_owner_token") == owner_token
                              and u.get("hp", 0) > 0 and u.get("line") == unit.get("line")), None)
                if owner:
                    anchor = _to_int(owner.get("pos", 0))
                    target = min(target, max(before, anchor - self._MIN_SPACE_POS)) if team == 1 else max(target, min(before, anchor + self._MIN_SPACE_POS))
            if forward:
                for summon in roster:
                    if (summon.get("aid") not in ("A_2003_2", "A_2018_2", "A_2024_6")
                            or summon.get("summon_owner_token") != unit.get("_owner_token")
                            or unit.get("_owner_token") is None or summon.get("hp", 0) <= 0
                            or summon.get("line") != unit.get("line")):
                        continue
                    anchor = _to_int(summon.get("pos", 0))
                    target = max(target, min(before, anchor + self._MIN_SPACE_POS)) if team == 1 else min(target, max(before, anchor - self._MIN_SPACE_POS))
        unit["pos"] = self._get_final_pos(team, int(unit.get("line", 0)), target)
        return abs(before - _to_int(unit.get("pos", 0)))

    def _rooted(self, unit):
        """abilityState.root: set by abilityControl("root") and the root buff."""
        return bool(unit.get("_rooted")) or self._buff(unit, "root") is not None

    @staticmethod
    def _get_speed(unit):
        for key in ("speed", "spd"):
            value = unit.get(key)
            if isinstance(value, (int, float)) and not isinstance(value, bool):
                return _to_int(value)
        return 0

    def _find_aim_list(self, attacker, candidates, reach, ban_stand=False):
        """137_Avatar.as:6145 findAimList, over an already-filtered candidate set."""
        alive = [u for u in candidates if int(u.get("hp", 0)) > 0]
        reach = _to_int(reach)
        if reach == 0:
            # findAimList returns [this] only when the caster is in the pool, so
            # a zero-range enemy scan yields nothing.
            return [attacker] if any(u is attacker for u in alive) else []
        if reach < 0:
            reach = self._get_range(attacker)
        line_filter = -1 if reach > int(self._LINE_POS) else int(attacker.get("line", 0))
        apos = _to_int(attacker.get("pos", 0))
        out = []
        for unit in alive:
            if line_filter != -1 and int(unit.get("line", -1)) != line_filter:
                continue
            # Avatar.getEffectiveActionType() is serialized as tpl[1].  tpl[0]
            # is the role/action category and must not control banStand.
            if ban_stand and int(unit.get("tpl", [0, 0, 0, 0, 0])[1] if unit.get("tpl") else 0) == 3:
                continue
            if abs(_to_int(unit.get("pos", 0)) - apos) <= reach:
                out.append(unit)
        return out

    def _custom_targets(self, attacker, skill, ally=False, candidates=None, ban_stand=None):
        """139_SkillSet.as:2380 getCustomActionTargets.

        The snapshot drops actionTargetPolicyArgs/actionTargetGroups and no
        action carries a centre, so getActionRange collapses to the cast range
        and the policy surface reduces to identity.
        """
        pool = candidates
        if pool is None:
            pool = (attacker.get("_team", []) if ally
                    else [u for u in self._living_opponents(attacker)])
        pl = skill.get("pl") if isinstance(skill, dict) else []
        if ban_stand is None:
            # 086_SkillSetData.as:128-133 reads this field as
            #     banStand = (pl[5] == 0)
            # i.e. pl[5] == 1 means the skill MAY hit stand-type (tpl[0] == 3)
            # targets. An earlier revision had `bool(pl[5])` here, which is the
            # exact opposite: it made every "可命中坚守型" skill unable to hit
            # them in simulation. The authored info text and the client both
            # agree with pl[5] == 0 meaning ban, so that is the reading kept.
            ban_stand = (pl[5] == 0) if isinstance(pl, list) and len(pl) > 5 else False
        return self._find_aim_list(attacker, pool, self._get_range_for_action(attacker, skill), ban_stand)

    def _living_opponents(self, attacker):
        other = self.b if int(attacker.get("isme")) else self.a
        return [u for u in other if int(u.get("hp", 0)) > 0 and u is not attacker]

    def _get_range_for_action(self, attacker, skill):
        """getActionRange collapses to the cast range with the snapshot we hold."""
        return self._get_cast_range(attacker, skill)

    @classmethod
    def _can_apply_dash(cls, attacker, enemies):
        pos = attacker.get("pos")
        team_one = attacker.get("isme")
        if (not isinstance(pos, (int, float)) or isinstance(pos, bool)
                or not math.isfinite(float(pos)) or not isinstance(team_one, (bool, int))
                or team_one not in (False, True, 0, 1)):
            return False
        for target in enemies:
            target_pos = target.get("pos")
            if (not isinstance(target_pos, (int, float)) or isinstance(target_pos, bool)
                    or not math.isfinite(float(target_pos))):
                return False
        return True

    @classmethod
    def _apply_dash(cls, attacker, enemies, distance):
        """Apply forward native dash to serialized positions, with native lane bounds.

        The model accepts native combat coordinates only. It declines to apply
        a dash when the required position/team data is absent.
        """
        pos = float(attacker["pos"])
        enemy_positions = [float(unit["pos"]) for unit in enemies
                           if unit.get("line", 0) == attacker.get("line", 0)]
        line_end = float(cls._LINE_POS)
        min_space = float(cls._MIN_SPACE_POS)
        step = float(distance)

        if bool(attacker["isme"]):
            forward_limit = (max(enemy_positions) + min_space) if enemy_positions else min_space
            attacker["pos"] = max(forward_limit, min(line_end, pos - step))
        else:
            forward_limit = (min(enemy_positions) - min_space) if enemy_positions else line_end - min_space
            attacker["pos"] = min(forward_limit, max(0.0, pos + step))

    # ------------------------------------------------------------ skills

    @staticmethod
    def _action_vfx(action):
        """The trailing vfx/resource key, when the row carries a string."""
        if len(action) >= 2 and isinstance(action[-1], str):
            return action[-1]
        return None

    @classmethod
    def _action_name(cls, action, args):
        """``[kind, name_arg, ...]`` buff kinds carry an explicit name."""
        for index in args:
            if 0 < index < len(action) and isinstance(action[index], str):
                return action[index]
        return None

    def _supported(self, action):
        return (isinstance(action, list) and bool(action)
                and action[0] in _ACTION_HANDLERS)

    def _apply_native_skill(self, attacker, enemies, slot="skill"):
        """Execute a native action list, mirroring the client's dispatch switch.

        The client switch (139_SkillSet.as:804) has no ``default:`` clause, so an
        action whose kind it does not implement is a silent no-op and the rest of
        the skill still runs. Only a malformed row aborts the skill.
        """
        skill = attacker.get(slot)
        if not isinstance(skill, dict) or not isinstance(skill.get("skills"), list):
            return False
        actions = skill["skills"]
        if not actions:
            return False
        if any(a[0] == "dash" for a in actions):
            if any(len(a) < 2 or not isinstance(a[1], (int, float)) or isinstance(a[1], bool)
                   for a in actions if a[0] == "dash"):
                return False
            if not self._can_apply_dash(attacker, enemies):
                return False
        allies = [u for u in attacker.get("_team", []) if int(u.get("hp", 0)) > 0]
        context = {"targets": {}, "damage": {}, "kills": {}, "target_groups": {}}
        for index, action in enumerate(actions):
            if not isinstance(action, list) or not action:
                return False
            handler = _ACTION_HANDLERS.get(str(action[0]))
            if handler is None:
                # No matching case in the native switch: skip and carry on.
                continue
            try:
                handler(self, attacker, enemies, allies, skill, action, index, context)
            except (TypeError, ValueError, IndexError, KeyError):
                return False
        return True

    # --- individual action handlers -------------------------------------

    def _act_dash(self, attacker, enemies, allies, skill, action, index, context):
        self._apply_dash(attacker, enemies, action[1])

    def _act_damage(self, attacker, enemies, allies, skill, action, index, context):
        if len(action) < 3:
            raise ValueError("damage action needs a coefficient and a damage type")
        pl = skill.get("pl") or []
        targets = self._skill_targets(attacker, enemies, pl, skill=skill, index=index)
        total = 0
        first = None
        for target in targets:
            total += self._native_damage(attacker, target, action[1], action[2])
            first = first or target
        context["damage"][index] = total
        context["kills"][index] = self._kill_record(targets)
        if first is not None:
            context["targets"][index] = first

    def _act_true_damage(self, attacker, enemies, allies, skill, action, index, context):
        """true_damage (139_SkillSet.as:1406): damage with type forced to 3."""
        pl = skill.get("pl") or []
        coefficient = float(action[1]) / _REAL_DAMAGE_RATE
        targets = self._skill_targets(attacker, enemies, pl)
        total = 0
        first = None
        for target in targets:
            total += self._native_damage(attacker, target, coefficient, 3)
            first = first or target
        context["damage"][index] = total
        context["kills"][index] = self._kill_record(targets)
        if first is not None:
            context["targets"][index] = first

    def _act_suck(self, attacker, enemies, allies, skill, action, index, context):
        if len(action) < 4:
            raise ValueError("suck action needs a coefficient, a damage type and a ratio")
        pl = skill.get("pl") or []
        targets = self._skill_targets(attacker, enemies, pl)
        total = 0
        for target in targets:
            total += self._native_damage(attacker, target, action[1], action[2])
        context["damage"][index] = total
        context["kills"][index] = self._kill_record(targets)
        if targets:
            context["targets"][index] = targets[0]
        drained = _to_int(total * float(action[3]))
        if drained > 0:
            self._injured(attacker, drained, damage_type=4)

    def _act_conditional_damage(self, attacker, enemies, allies, skill, action, index, context):
        """conditional_damage (139_SkillSet.as:942): base + additive bonus."""
        if len(action) < 6:
            raise ValueError("conditional_damage needs five arguments")
        pl = skill.get("pl") or []
        base = float(action[1])
        damage_type = int(action[2])
        condition = str(action[3])
        bonus = float(action[4])
        total = 0
        for target in self._skill_targets(attacker, enemies, pl):
            coefficient = base
            if self._condition_matches(condition, target, context):
                coefficient += bonus
            if damage_type == 3:
                coefficient /= _REAL_DAMAGE_RATE
            total += self._native_damage(attacker, target, coefficient, damage_type)
        context["damage"][index] = total
        context["kills"][index] = self._kill_record(
            [u for u in enemies if int(u.get("hp", 0)) > 0])

    def _condition_matches(self, condition, target, context):
        """conditionMatches (139_SkillSet.as:2391)."""
        if condition == "target_hp_below_50":
            hp_max = int(target.get("hp_max", 0))
            return hp_max > 0 and int(target.get("hp", 0)) / hp_max < 0.5
        if condition == "target_hp_below_50_percent":
            hp_max = int(target.get("hp_max", 0))
            return hp_max > 0 and int(target.get("hp", 0)) / hp_max < 0.5
        if condition in ("primary_target", "prehit_burn", "prehit_bleed"):
            issued = [i for i in sorted(context["targets"]) if i < index]
            if not issued:
                return False
            return context["targets"].get(issued[-1]) is target
        # primary_killed is hardcoded false in the client.
        return False

    def _act_stun(self, attacker, enemies, allies, skill, action, index, context):
        if len(action) < 4:
            raise ValueError("stun action needs a coefficient, damage type and rounds")
        pl = skill.get("pl") or []
        targets = self._skill_targets(attacker, enemies, pl)
        for target in targets:
            self._native_damage(attacker, target, action[1], action[2])
            self._add_buff(target, "stun", int(action[3]), 0)
        if targets:
            context["targets"][index] = targets[0]

    def _act_stun_by_condition(self, attacker, enemies, allies, skill, action, index, context):
        if len(action) < 7:
            raise ValueError("stun_by_condition needs six arguments")
        pl = skill.get("pl") or []
        for target in self._skill_targets(attacker, enemies, pl):
            rounds = int(action[3])
            if self._condition_matches(str(action[4]), target, context):
                rounds += int(action[5])
            self._native_damage(attacker, target, action[1], action[2])
            self._add_buff(target, "stun", rounds, 0)
        context["kills"][index] = self._kill_record(
            [u for u in enemies if int(u.get("hp", 0)) > 0])

    def _act_silence(self, attacker, enemies, allies, skill, action, index, context):
        if len(action) < 4:
            raise ValueError("silence action needs a coefficient, damage type and rounds")
        pl = skill.get("pl") or []
        targets = self._skill_targets(attacker, enemies, pl)
        for target in targets:
            self._native_damage(attacker, target, action[1], action[2])
            self._add_buff(target, "silence", int(action[3]), 0)
        if targets:
            context["targets"][index] = targets[0]

    def _act_weak(self, attacker, enemies, allies, skill, action, index, context):
        """weak (139_SkillSet.as:1761): Buff value is arg[3] verbatim."""
        if len(action) < 4:
            raise ValueError("weak action needs a coefficient, damage type and value")
        pl = skill.get("pl") or []
        targets = self._skill_targets(attacker, enemies, pl)
        for target in targets:
            self._native_damage(attacker, target, action[1], action[2])
            self._add_buff(target, "weak", int(action[4]), float(action[3]))
        if targets:
            context["targets"][index] = targets[0]

    def _act_weak_percent(self, attacker, enemies, allies, skill, action, index, context):
        """weak_percent (139_SkillSet.as:1768): arg[3] is a display fraction."""
        if len(action) < 4:
            raise ValueError("weak_percent action needs a coefficient, damage type and percent")
        pl = skill.get("pl") or []
        converted = _percent_debuff_value(action[3])
        if converted < 0:
            return
        targets = self._skill_targets(attacker, enemies, pl)
        for target in targets:
            self._native_damage(attacker, target, action[1], action[2])
            self._add_buff(target, "weak", int(action[4]), converted)
        if targets:
            context["targets"][index] = targets[0]

    def _act_sunder(self, attacker, enemies, allies, skill, action, index, context):
        if len(action) < 4:
            raise ValueError("sunder action needs a coefficient, damage type and value")
        pl = skill.get("pl") or []
        targets = self._skill_targets(attacker, enemies, pl)
        for target in targets:
            self._native_damage(attacker, target, action[1], action[2])
            self._add_buff(target, "sunder", int(action[4]), float(action[3]))
        if targets:
            context["targets"][index] = targets[0]

    def _act_sunder_percent(self, attacker, enemies, allies, skill, action, index, context):
        if len(action) < 4:
            raise ValueError("sunder_percent action needs three arguments")
        pl = skill.get("pl") or []
        converted = _percent_debuff_value(action[3])
        if converted < 0:
            return
        targets = self._skill_targets(attacker, enemies, pl)
        for target in targets:
            self._native_damage(attacker, target, action[1], action[2])
            self._add_buff(target, "sunder", int(action[4]), converted)
        if targets:
            context["targets"][index] = targets[0]

    def _act_poison(self, attacker, enemies, allies, skill, action, index, context):
        """poison (139_SkillSet.as:1797): a direct hit, then an AP-scaled DOT.

        Args are ``[1]`` direct coefficient, ``[2]`` direct damage type,
        ``[3]`` DOT coefficient, ``[4]`` rounds, ``[5]`` vfx. Unlike burn,
        poison *is* a direct-damage action, so it creates a kill context.
        """
        if len(action) < 5:
            raise ValueError("poison action needs a coefficient, type, dot and rounds")
        pl = skill.get("pl") or []
        magnitude = _to_int(float(action[3]) * self._ap_with_talent(attacker))
        targets = self._skill_targets(attacker, enemies, pl)
        total = 0
        for target in targets:
            total += self._native_damage(attacker, target, action[1], action[2])
            self._add_buff(target, "poison", int(action[4]), magnitude)
        context["damage"][index] = total
        context["kills"][index] = self._kill_record(targets)
        if targets:
            context["targets"][index] = targets[0]

    def _act_burn(self, attacker, enemies, allies, skill, action, index, context):
        """burn (139_SkillSet.as:1803): pure DOT, no impact damage at all.

        Args are ``[1]`` DOT coefficient, ``[2]`` rounds — note the rounds slot
        differs from poison's ``[4]``. The client calls checkAttack with a
        literal 0 damage type and 0 coefficient, so nothing lands on the hit
        itself and no kill context is created.
        """
        if len(action) < 3:
            raise ValueError("burn action needs a dot coefficient and rounds")
        pl = skill.get("pl") or []
        magnitude = _to_int(float(action[1]) * self._ap_with_talent(attacker))
        targets = self._skill_targets(attacker, enemies, pl)
        for target in targets:
            self._add_buff(target, "burn", int(action[2]), magnitude)
        if targets:
            context["targets"][index] = targets[0]

    def _act_strong(self, attacker, enemies, allies, skill, action, index, context):
        self._self_value_buff(attacker, action, "strong")

    def _act_steel(self, attacker, enemies, allies, skill, action, index, context):
        self._self_value_buff(attacker, action, "steel")

    def _act_armor(self, attacker, enemies, allies, skill, action, index, context):
        self._self_value_buff(attacker, action, "armor")

    def _act_bless(self, attacker, enemies, allies, skill, action, index, context):
        """bless: a one-shot revival, rounds are irrelevant (checkBuff skips it).

        ``bless`` is a friendly buff, so it takes the same recipients as the
        other ally-targeted kinds rather than always landing on the caster.
        """
        rounds = action[1] if len(action) > 1 and isinstance(action[1], (int, float)) else 1
        for target in self._ally_buff_targets(attacker, allies, skill.get("pl") or [],
                                              skill=skill, index=index):
            self._add_buff(target, "bless", int(rounds), 0)

    def _act_purify(self, attacker, enemies, allies, skill, action, index, context):
        """purify (139_SkillSet.as:1974): rounds at ``[1]``, no value argument.

        Purely defensive: it arms the buff and clears the recipient's debuffs.
        It never strips anything from the opposing team.
        """
        for target in self._ally_buff_targets(attacker, allies, skill.get("pl") or [],
                                              skill=skill, index=index):
            self._add_buff(target, "purify", _to_int(action[1]), 0)

    def _act_cure(self, attacker, enemies, allies, skill, action, index, context):
        """cure (139_SkillSet.as:1938): a heal through channel 4, not a cleanse.

        ``attackAimList(targets, 4, arg[1], ...)`` — coefficient at ``[1]`` and
        no Buff object, so it applies nothing but restored HP.
        """
        if len(action) < 2:
            raise ValueError("cure needs a heal coefficient")
        amount = self._heal_channel_value(attacker, action[1])
        for target in self._ally_buff_targets(attacker, allies, skill.get("pl") or [],
                                              skill=skill, index=index):
            missing = int(target.get("hp_max", 0)) - int(target.get("hp", 0))
            if missing > 0:
                self._injured(target, min(missing, amount), damage_type=4)

    def _act_evil(self, attacker, enemies, allies, skill, action, index, context):
        """evil (139_SkillSet.as:1808): rounds at ``[1]``, zero damage.

        Stripping the good buffs happens inside _add_buff, alongside arming the
        buff that blocks the next incoming one.
        """
        pl = skill.get("pl") or []
        for target in self._skill_targets(attacker, enemies, pl):
            self._add_buff(target, "evil", _to_int(action[1]), 0)

    def _act_curse(self, attacker, enemies, allies, skill, action, index, context):
        """Block positive buffs through the target's next owner-turn window."""
        if len(action) < 2:
            raise ValueError("curse action needs a round count")
        # A zero-range curse is the one debuff action that targets its caster;
        # 139_SkillSet.as builds a singleton vector instead of scanning enemies.
        if self._get_cast_range(attacker, skill) == 0:
            targets = [attacker] if int(attacker.get("hp", 0)) > 0 else []
        else:
            # Curse uses the same action-policy/link pipeline as other
            # targeted actions.  Passing the skill/index is required for
            # authored policies such as global-lowest-HP and target caps.
            targets = self._skill_targets(
                attacker, enemies, skill.get("pl") or [], skill=skill, index=index)
        for target in targets:
            self._add_buff(target, "curse", _to_int(action[1]), 0)
        if targets:
            context["targets"][index] = targets[0]

    def _act_taunt(self, attacker, enemies, allies, skill, action, index, context):
        self._add_buff(attacker, "taunt", _to_int(action[1]), 0)

    def _act_attrup(self, attacker, enemies, allies, skill, action, index, context):
        """attrup (139_SkillSet.as:1992): value is derived, not read directly.

        Args are ``[1]`` scale, ``[2]`` stat key, ``[3]`` flat pre-addend,
        ``[4]`` rounds, ``[5]`` vfx. Value is
        ``toInt((<raw stat> + [3]) * [1])``, read off the raw public vars rather
        than the buff-aware getters.
        """
        if len(action) < 5:
            raise ValueError("attrup needs a scale, a stat, a flat add and rounds")
        key = str(action[2])
        if key not in ("hit", "flee", "crit", "tough"):
            raise ValueError("attrup stat must be hit/flee/crit/tough")
        raw = attacker.get("new_4attrs")
        base = float(raw.get(key, 0)) if isinstance(raw, dict) else 0.0
        value = _to_int((base + float(action[3])) * float(action[1]))
        for target in self._ally_buff_targets(attacker, allies, skill.get("pl") or [],
                                              skill=skill, index=index):
            self._add_buff(target, key + "up", _to_int(action[4]), value)

    def _act_stat_flat(self, attacker, enemies, allies, skill, action, index, context):
        """stat_flat (139_SkillSet.as:1204): key ``[1]``, value ``[2]``, rounds ``[3]``.

        A distinct kind from attrup with a different argument layout.
        """
        if len(action) < 5:
            raise ValueError("stat_flat needs a stat key, a value, rounds and a vfx")
        key = str(action[1])
        if key not in ("hit", "flee", "crit", "tough"):
            raise ValueError("stat_flat stat must be hit/flee/crit/tough")
        value = float(action[2])
        rounds = int(action[3])
        if not (0 < value <= 100000) or not (1 <= rounds <= 20):
            raise ValueError("stat_flat arguments are outside the authored bounds")
        for target in self._ally_buff_targets(attacker, allies, skill.get("pl") or [],
                                              skill=skill, index=index):
            self._add_buff(target, key + "up", rounds, value)

    def _hp_shield_targets(self, attacker, skill, *, per_target_base):
        """139_SkillSet.as:830 — hp_shield / caster_hp_shield / target_hp_shield.

        All three cases share one body: recipients come from
        ``getCustomActionTargets(action, actionTargets, targetGroups, true)``,
        and only the shield base differs — ``target_hp_shield`` scales off each
        recipient's own ``getHpMax()``, the other two off the caster's.
        """
        recipients = self._custom_targets(attacker, skill, ally=True,
                                          candidates=list(attacker.get("_team", [])),
                                          ban_stand=False)
        if not recipients:
            recipients = [attacker]
        return recipients, per_target_base

    def _act_hp_shield(self, attacker, enemies, allies, skill, action, index, context):
        """hp_shield (139_SkillSet.as:830): shield = ratio * caster hpMax."""
        if len(action) != 4:
            raise ValueError("hp_shield requires exactly three arguments")
        ratio = float(action[1])
        rounds = int(action[2])
        if not ratio > 0 or not rounds > 0:
            return
        recipients, _ = self._hp_shield_targets(attacker, skill, per_target_base=False)
        for ally in recipients:
            self._add_buff(ally, "shield", rounds, _to_int(int(attacker.get("hp_max", 0)) * ratio))

    def _act_caster_hp_shield(self, attacker, enemies, allies, skill, action, index, context):
        self._act_hp_shield(attacker, enemies, allies, skill, action, index, context)

    def _act_target_hp_shield(self, attacker, enemies, allies, skill, action, index, context):
        """target_hp_shield (139_SkillSet.as:837): ratio * each recipient's hpMax."""
        if len(action) != 4:
            raise ValueError("target_hp_shield requires exactly three arguments")
        ratio = float(action[1])
        rounds = int(action[2])
        if not ratio > 0 or not rounds > 0:
            return
        recipients, _ = self._hp_shield_targets(attacker, skill, per_target_base=True)
        for ally in recipients:
            self._add_buff(ally, "shield", rounds, _to_int(int(ally.get("hp_max", 0)) * ratio))

    def _act_shield(self, attacker, enemies, allies, skill, action, index, context):
        """shield (139_SkillSet.as:1920).

        The executor branches on ``_loc24_`` — the cached ``getCastRange()``.
        A zero cast range makes the pool the caster alone; otherwise it is the
        caster's own team narrowed by ``findAimList``. The value is
        ``toInt(arg[1] * (toInt(getDamage() * (1 + checkTalent(1))) +
        hpMax * .1))``, with no floor, so a zero base yields a zero shield.
        """
        if len(action) < 3:
            raise ValueError("shield needs a coefficient and a round count")
        amount = _to_int(float(action[1])
                         * (_to_int(self._get_damage(attacker) * (1.0 + self._talent(attacker, 1)))
                            + int(attacker.get("hp_max", 0)) * 0.1))
        rounds = _to_int(action[2])
        if rounds <= 0:
            return
        if self._get_cast_range(attacker, skill) == 0:
            recipients = [attacker]
        else:
            recipients = self._custom_targets(attacker, skill, ally=True,
                                             candidates=list(attacker.get("_team", [])),
                                             ban_stand=False)
        for ally in recipients:
            self._add_buff(ally, "shield", rounds, max(0, amount))

    def _act_shield_composite(self, attacker, enemies, allies, skill, action, index, context):
        """shield_composite (139_SkillSet.as:1147): AP + 10% hpMax + defences.

        ``compositeEffectiveAP = toInt(getDamage() * (1 + checkTalent(1))) +
        hpMax * .1``; the shield is ``arg[1] * that + arg[2] * (dePh + deMa)``,
        floored at 1, and applied to the caster's own team.
        """
        if len(action) < 5:
            raise ValueError("shield_composite needs an AP and a defence coefficient")
        effective_ap = (_to_int(self._get_damage(attacker) * (1.0 + self._talent(attacker, 1)))
                        + int(attacker.get("hp_max", 0)) * 0.1)
        composite = _to_int(float(action[1]) * effective_ap
                            + float(action[2]) * (self._get_de_ph(attacker) + self._get_de_ma(attacker)))
        rounds = int(action[3])
        if rounds <= 0:
            return
        recipients = self._custom_targets(attacker, skill, ally=True,
                                         candidates=list(attacker.get("_team", [])),
                                         ban_stand=False)
        for ally in recipients:
            self._add_buff(ally, "shield", rounds, max(1, composite))

    def _act_shield_followup(self, attacker, enemies, allies, skill, action, index, context):
        """shield_followup (139_SkillSet.as:1558): shield self, then strike."""
        if len(action) not in (7, 9):
            raise ValueError("shield_followup requires 7 or 9 elements")
        ratio = float(action[1])
        rounds = int(action[2])
        coefficient = float(action[3])
        source_index = int(action[4])
        damage_type = int(action[5])
        if not (0 < ratio <= 1) or rounds <= 0 or coefficient < 0:
            return
        if damage_type not in (1, 2, 3) or source_index < 0 or source_index >= index:
            return
        amount = _to_int(int(attacker.get("hp_max", 0)) * ratio)
        self._add_buff(attacker, "shield", rounds, amount)
        victim = context["targets"].get(source_index)
        if victim is None or int(victim.get("hp", 0)) <= 0:
            return
        if victim.get("line") != attacker.get("line"):
            return
        if abs(float(victim.get("pos", 0)) - float(attacker.get("pos", 0))) > 600:
            return
        self._native_damage(attacker, victim, coefficient, damage_type)
        if len(action) == 9:
            weak_percent = float(action[6])
            weak_rounds = int(action[7])
            converted = _percent_debuff_value(weak_percent)
            if converted >= 0 and weak_rounds > 0:
                self._add_buff(victim, "weak", weak_rounds, converted)
        context["targets"][index] = victim

    def _act_shield_dispel(self, attacker, enemies, allies, skill, action, index, context):
        """shield_dispel (139_SkillSet.as:1600): strip an enemy shield in radius."""
        pl = skill.get("pl") or []
        reach = abs(int(pl[2])) if len(pl) > 2 else 0
        candidates = [u for u in enemies if int(u.get("hp", 0)) > 0]
        if reach > 100:
            candidates = [u for u in candidates
                          if abs(float(u.get("pos", 0)) - float(attacker.get("pos", 0))) <= reach]
        else:
            candidates = [u for u in candidates if u.get("line") == attacker.get("line")]
        for target in candidates:
            if self._buff(target, "shield") is not None:
                self._remove_buff(target, "shield")

    def _act_dispel_good(self, attacker, enemies, allies, skill, action, index, context):
        """dispel_good (139_SkillSet.as:1578): strip every good buff."""
        for target in self._skill_targets(attacker, enemies, skill.get("pl") or []):
            self._remove_all_good(target)
        context["kills"][index] = self._kill_record(
            [u for u in enemies if int(u.get("hp", 0)) > 0])

    def _heal_ap_channel(self, attacker, coefficient):
        """attackAimList channel 4 (137_Avatar.as:5055).

        ``recoveryBase = toInt(getDamage() * (1 + checkTalent(1))) + hpMax * .1``,
        scaled by the coefficient and then by the hit-derived
        ``getActiveRecoveryMultiplier``, whose hit term is
        ``toInt(getHit() * (1 + checkTalent(4)))``.
        """
        base = _to_int(self._get_damage(attacker) * (1.0 + self._talent(attacker, 1)))
        base += int(attacker.get("hp_max", 0)) * 0.1
        amount = _to_int(base * float(coefficient))
        hit = _to_int(self._get_hit(attacker) * (1.0 + self._talent(attacker, 4)))
        if hit > 0:
            amount = _to_int(amount * (1 + 0.5 * hit / (hit + 3000)))
        return amount

    def _act_heal_ap(self, attacker, enemies, allies, skill, action, index, context):
        """heal_ap (139_SkillSet.as:1663): self only, routed through channel 4."""
        if len(action) < 2:
            raise ValueError("heal_ap needs a coefficient")
        self._injured(attacker, self._heal_ap_channel(attacker, action[1]), damage_type=4)

    def _act_heal_missing_hp(self, attacker, enemies, allies, skill, action, index, context):
        """heal_missing_hp (139_SkillSet.as:1225): fraction of each ally's own gap."""
        if len(action) < 3:
            raise ValueError("heal_missing_hp needs a fraction and a vfx")
        fraction = float(action[1])
        if not (0 < fraction <= 1):
            return
        for ally in [u for u in allies if int(u.get("hp", 0)) > 0]:
            missing = int(ally.get("hp_max", 0)) - int(ally.get("hp", 0))
            amount = max(0, min(missing, _to_int(missing * fraction)))
            if amount > 0:
                self._injured(ally, amount, damage_type=4)

    def _act_heal_damage_sum(self, attacker, enemies, allies, skill, action, index, context):
        """heal_damage_sum (139_SkillSet.as:1248): heal off earlier actions' damage."""
        if len(action) < 4 or not isinstance(action[2], list):
            raise ValueError("heal_damage_sum needs a fraction, an index array and a vfx")
        fraction = float(action[1])
        if not (0 < fraction <= 1):
            return
        total = 0
        seen = set()
        for raw in action[2]:
            if isinstance(raw, bool) or not isinstance(raw, (int, float)):
                continue
            source = int(raw)
            if source != raw or source < 0 or source >= index or source in seen:
                continue
            seen.add(source)
            total += context["damage"].get(source, 0)
        if total <= 0:
            return
        for ally in [u for u in allies if int(u.get("hp", 0)) > 0]:
            missing = int(ally.get("hp_max", 0)) - int(ally.get("hp", 0))
            amount = max(0, min(missing, _to_int(total * fraction)))
            if amount > 0:
                self._injured(ally, amount, damage_type=4)

    def _act_heal_missing_hp_per_hero(self, attacker, enemies, allies, skill, action, index, context):
        """heal_missing_hp_per_hero (139_SkillSet.as:846): cast-time snapshot."""
        if len(action) != 5:
            raise ValueError("heal_missing_hp_per_hero requires exactly four arguments")
        source = int(action[3])
        if source < 0 or source >= index:
            return
        per_hero = float(action[1])
        cap = float(action[2])
        record = context["kills"].get(source) or {}
        hero_hits = len(record.get("hit_heroes") or [])
        multiplier = min(cap, hero_hits * per_hero)
        missing_at_cast = max(0, int(attacker.get("hp_max", 0)) - int(attacker.get("hp", 0)))
        refund = missing_at_cast * multiplier
        if refund > 0:
            missing = int(attacker.get("hp_max", 0)) - int(attacker.get("hp", 0))
            self._injured(attacker, min(missing, _to_int(refund)), damage_type=4)

    def _act_locked_sequence(self, attacker, enemies, allies, skill, action, index, context):
        """locked_sequence (139_SkillSet.as:1412): N hits on one locked target."""
        count = int(action[1]) if len(action) > 1 else 0
        if count <= 0 or len(action) < 5 + count:
            raise ValueError("locked_sequence argument count does not match its hit count")
        pl = skill.get("pl") or []
        targets = self._skill_targets(attacker, enemies, pl, skill=skill, index=index)
        if not targets:
            return
        primary = targets[0]
        context["targets"][index] = primary
        damage_type = int(action[2 + count])
        lifesteal = float(action[3 + count])
        total = 0
        hit = 0
        while hit < count and int(primary.get("hp", 0)) > 0:
            total += self._native_damage(attacker, primary, action[2 + hit], damage_type)
            hit += 1
        context["damage"][index] = total
        if lifesteal > 0 and total > 0:
            self._injured(attacker, _to_int(total * lifesteal), damage_type=4)

    def _act_locked_sequence_area(self, attacker, enemies, allies, skill, action, index, context):
        """locked_sequence_area (139_SkillSet.as:1445): N hits over a radius."""
        count = int(action[1]) if len(action) > 1 else 0
        if count <= 0 or len(action) < 7 + count:
            raise ValueError("locked_sequence_area argument count does not match its hit count")
        pl = skill.get("pl") or []
        targets = self._skill_targets(attacker, enemies, pl)
        if not targets:
            return
        primary = targets[0]
        context["targets"][index] = primary
        damage_type = int(action[2 + count])
        lifesteal = float(action[3 + count])
        radius = abs(int(action[4 + count]))
        cap = int(action[5 + count])
        if cap < 1:
            raise ValueError("locked_sequence_area target cap is invalid")
        area = [u for u in enemies
                if int(u.get("hp", 0)) > 0
                and u.get("line") == primary.get("line")
                and abs(float(u.get("pos", 0)) - float(primary.get("pos", 0))) <= radius]
        area.sort(key=lambda u: (abs(float(u.get("pos", 0)) - float(primary.get("pos", 0))),
                                 int(u.get("hp", 0))))
        area = area[:cap]
        total = 0
        for target in area:
            for _ in range(count):
                if int(target.get("hp", 0)) <= 0:
                    break
                total += self._native_damage(attacker, target, action[2], damage_type)
        context["damage"][index] = total
        if lifesteal > 0 and total > 0:
            self._injured(attacker, _to_int(total * lifesteal), damage_type=4)

    def _act_locked_combo_group(self, attacker, enemies, allies, skill, action, index, context):
        """locked_combo_group (139_SkillSet.as:1632): hits per target, several targets."""
        if len(action) < 7:
            raise ValueError("locked_combo_group needs six arguments")
        pl = skill.get("pl") or []
        max_targets = int(action[1])
        hits = int(action[2])
        coefficient = float(action[3])
        damage_type = int(action[4])
        lifesteal = float(action[5])
        # S_201310 stores pl[4] == 0 for its single-action metadata, while
        # locked_combo_group itself carries the real six-target cap.  Feed the
        # action cap into the native target resolver before it applies pl[4].
        target_pl = list(pl)
        while len(target_pl) <= 4:
            target_pl.append(0)
        target_pl[4] = max(0, max_targets - 1)
        targets = self._skill_targets(attacker, enemies, target_pl)[:max(1, max_targets)]
        total = 0
        for target in targets:
            hit = 0
            while hit < hits and int(target.get("hp", 0)) > 0:
                total += self._native_damage(attacker, target, coefficient, damage_type)
                hit += 1
        context["damage"][index] = total
        if targets:
            context["targets"][index] = targets[0]
        if lifesteal > 0 and total > 0:
            self._injured(attacker, _to_int(total * lifesteal), damage_type=4)

    def _act_locked_combo_weak(self, attacker, enemies, allies, skill, action, index, context):
        """locked_combo_weak (139_SkillSet.as:1667): weak lands only if all hits do.

        Note the argument order: rounds are arg[5] and the value is arg[4], the
        reverse of ``weak``.
        """
        if len(action) < 6:
            raise ValueError("locked_combo_weak needs five arguments")
        required = int(action[3])
        pl = skill.get("pl") or []
        targets = self._skill_targets(attacker, enemies, pl)
        if not targets or required <= 0:
            return
        primary = targets[0]
        damage_type = int(action[2])
        landed = 0
        while landed < required and int(primary.get("hp", 0)) > 0:
            self._native_damage(attacker, primary, action[1], damage_type)
            landed += 1
        if landed == required and int(primary.get("hp", 0)) > 0:
            self._add_buff(primary, "weak", int(action[5]), float(action[4]))
        context["targets"][index] = primary

    def _act_combo(self, attacker, enemies, allies, skill, action, index, context):
        """combo: repeated strikes; the tail slot mirrors true damage when type 3."""
        if len(action) < 4:
            raise ValueError("combo needs a coefficient, damage type and hit count")
        pl = skill.get("pl") or []
        targets = self._skill_targets(attacker, enemies, pl)
        damage_type = int(action[2])
        coefficient = float(action[1])
        if damage_type == 3:
            coefficient /= _REAL_DAMAGE_RATE
        hits = max(1, int(action[3]))
        total = 0
        for target in targets:
            for _ in range(hits):
                if int(target.get("hp", 0)) <= 0:
                    break
                total += self._native_damage(attacker, target, coefficient, damage_type)
        context["damage"][index] = total
        context["kills"][index] = self._kill_record(targets)
        if targets:
            context["targets"][index] = targets[0]

    def _act_trynd_undying(self, attacker, enemies, allies, skill, action, index, context):
        """trynd_undying (139_SkillSet.as:1690): arms a one-shot hp = 1 revive."""
        rounds = int(action[1]) if len(action) > 1 else 0
        attacker["_trynd_rounds"] = max(0, rounds)

    def _act_lethal_floor(self, attacker, enemies, allies, skill, action, index, context):
        """lethal_floor (139_SkillSet.as:1307): hold self at a minimum HP."""
        if len(action) < 5:
            raise ValueError("lethal_floor needs four arguments")
        minimum = int(action[1])
        rounds = int(action[2])
        if minimum < 1 or rounds <= 0:
            return
        attacker["_lethal_floor"] = {"min_hp": minimum, "rounds": rounds,
                                     "expiry_heal": _to_int(float(action[3]) * self._get_damage(attacker))}

    def _act_lethal_floor_group(self, attacker, enemies, allies, skill, action, index, context):
        """lethal_floor_group (139_SkillSet.as:1314): the ally-wide form.

        Here arg[3] is an hpMax fraction, not an AP coefficient as in
        ``lethal_floor``.
        """
        if len(action) < 5:
            raise ValueError("lethal_floor_group needs four arguments")
        minimum = int(action[1])
        rounds = int(action[2])
        fraction = float(action[3])
        if minimum < 1 or rounds <= 0 or not 0 <= fraction <= 1:
            return
        for ally in [u for u in allies if int(u.get("hp", 0)) > 0]:
            ally["_lethal_floor"] = {"min_hp": minimum, "rounds": rounds,
                                     "expiry_heal": 0, "hp_fraction": fraction}
        context["kills"][index] = self._kill_record(
            [u for u in enemies if int(u.get("hp", 0)) > 0])

    def _act_back(self, attacker, enemies, allies, skill, action, index, context):
        """back (139_SkillSet.as:1185): rounds at ``[2]``, value at ``[1]``.

        The two slots are reversed relative to every other buff kind, and the
        guard requires both to be strictly positive before anything lands. It
        targets the caster's own team.
        """
        if len(action) < 4:
            return
        value = float(action[1])
        rounds = _to_int(action[2])
        if value <= 0 or rounds <= 0:
            return
        for target in self._ally_buff_targets(attacker, allies, skill.get("pl") or [],
                                              skill=skill, index=index):
            self._add_buff(target, "back", rounds, value)

    def _act_kill_buff(self, attacker, enemies, allies, skill, action, index, context):
        """kill_buff (139_SkillSet.as:855): value is arg[2] and rounds arg[3]."""
        if len(action) != 6:
            raise ValueError("kill_buff requires exactly five arguments")
        source = int(action[4])
        if source < 0 or source >= index:
            return
        record = context["kills"].get(source) or {}
        if not record.get("killed") or int(record.get("killed_type", 0)) != 1 or record.get("killed_summon"):
            return
        self._add_buff(attacker, str(action[1]), int(action[3]), float(action[2]))

    # --- small shared helpers -------------------------------------------

    def _self_value_buff(self, attacker, action, kind):
        """strong/steel/armor: value is arg[1] and rounds arg[2], applied to self."""
        if len(action) < 3:
            raise ValueError(f"{kind} needs a value and a round count")
        value = float(action[1])
        rounds = int(action[2])
        if value <= 0 or rounds <= 0:
            return
        self._add_buff(attacker, kind, rounds, value)

    @staticmethod
    def _round_arg(action):
        for index in range(1, len(action)):
            value = action[index]
            if isinstance(value, (int, float)) and not isinstance(value, bool) and float(value) == int(value):
                return max(1, int(value))
        return 1

    def _ally_buff_targets(self, attacker, allies, pl, skill=None, index=None):
        """Resolve the recipients of a friendly buff.

        The client distinguishes self from team targets with the cast range:
        ``getCastRange() == 0`` means the effect is self-only, otherwise it is
        the same range/line filter applied against the caster's own team. An
        action carrying an ally policy (``ally_all``) overrides that and
        reaches every living ally regardless of range.
        """
        if len(pl) < 3 or abs(int(pl[2])) == 0:
            return [attacker]
        return self._skill_targets(attacker, allies, pl, skill=skill, index=index) or [attacker]

    def _heal_channel_value(self, attacker, coefficient):
        """Channel 4, as ``cure`` (139_SkillSet.as:1938) calls it.

        ``cure`` reaches the same ``attackAimList(targets, 4, arg[1], ...)``
        branch as ``heal_ap``, so the hpMax term applies here too. Kept as a
        named alias because the call sites read better for it.
        """
        return self._heal_ap_channel(attacker, coefficient)

    @staticmethod
    def _kill_record(targets):
        killed = None
        for target in targets:
            if int(target.get("hp", 0)) <= 0:
                killed = target
                break
        hero_hits = [t for t in targets if t.get("tpl")]
        return {
            "hit": bool(targets),
            "hit_heroes": hero_hits,
            "killed": killed is not None,
            "killed_type": 1 if killed is not None else 0,
            "killed_summon": False,
        }

    # ------------------------------------------------- formerly unimplemented

    def _act_hitup(self, attacker, enemies, allies, skill, action, index, context):
        """hitup: no ``case`` exists in the client switch (139_SkillSet.as:804).

        The action is an explicit no-op; it exists in the config but the client
        never implemented it, so the skill continues without an effect.
        """

    def _act_fleeup(self, attacker, enemies, allies, skill, action, index, context):
        """fleeup: likewise unimplemented in the client switch — explicit no-op."""

    def _act_select_target(self, attacker, enemies, allies, skill, action, index, context):
        """select_target (139_SkillSet.as:822): publish one target, no effect."""
        candidates = self._custom_targets(attacker, skill, ally=False)
        if candidates:
            context["targets"][index] = candidates[0]

    def _act_move_self(self, attacker, enemies, allies, skill, action, index, context):
        """move_self (139_SkillSet.as:936): signed distance, negative moves forward."""
        if len(action) < 3:
            raise ValueError("move_self needs a signed distance and a vfx")
        raw = action[1]
        if not isinstance(raw, (int, float)) or isinstance(raw, bool) \
                or not math.isfinite(float(raw)) or float(raw) == 0:
            return
        self._check_move(attacker, float(raw) < 0, abs(_to_int(raw)), forced=False)

    def _act_move_to_target(self, attacker, enemies, allies, skill, action, index, context):
        """move_to_target (139_SkillSet.as:1538): close the gap, capped by arg[2]."""
        if len(action) < 3:
            raise ValueError("move_to_target needs a policy and a cap")
        candidates = self._find_aim_list(
            attacker, self._living_opponents(attacker),
            self._get_range_for_action(attacker, skill),
            bool((skill.get("pl") or [0, 0, 0, 0, 0, False])[5]) if len(skill.get("pl") or []) > 5 else False)
        if not candidates:
            return
        target = candidates[0]
        context["targets"][index] = target
        gap = abs(_to_int(target.get("pos", 0)) - _to_int(attacker.get("pos", 0)))
        cap = action[2]
        if isinstance(cap, (int, float)) and not isinstance(cap, bool) and float(cap) > 0:
            gap = min(gap, _to_int(cap))
        if gap <= 0:
            return
        forward = (target.get("pos") < attacker.get("pos")) if int(attacker.get("isme")) \
            else (target.get("pos") > attacker.get("pos"))
        self._check_move(attacker, forward, gap, forced=False)

    def _act_move_to_target_lane(self, attacker, enemies, allies, skill, action, index, context):
        """move_to_target_lane (139_SkillSet.as:1333): cross lanes to a target.

        findAimList is called with ``LINE_POS + 1`` as the reach, which clears
        the same-line filter, and the destination uses ``getFinalPos`` on the
        caster's side of the target.
        """
        if len(action) < 5:
            raise ValueError("move_to_target_lane needs a policy, offsets and a vfx")
        candidates = self._find_aim_list(attacker, self._living_opponents(attacker),
                                         int(self._LINE_POS) + 1, False)
        if not candidates:
            return
        target = candidates[0]
        context["targets"][index] = target
        friendly_offset = _to_int(action[3])
        side = self._team_number(attacker)
        requested = _to_int(target.get("pos", 0)) + (-friendly_offset if side == 1 else friendly_offset)
        destination = self._get_final_pos(side, int(target.get("line", 0)), requested)
        self._reline(attacker, int(target.get("line", 0)), destination, _to_int(action[2]), forced=False)

    def _act_move_enemy_side_target(self, attacker, enemies, allies, skill, action, index, context):
        """move_enemy_side_target (139_SkillSet.as:1350): step onto the enemy side."""
        if len(action) < 4:
            raise ValueError("move_enemy_side_target needs a policy, a step and a vfx")
        step = action[2]
        if not isinstance(step, (int, float)) or isinstance(step, bool) \
                or not math.isfinite(float(step)) or float(step) < 0:
            return
        candidates = self._find_aim_list(
            attacker, self._living_opponents(attacker),
            self._get_range_for_action(attacker, skill),
            bool((skill.get("pl") or [0, 0, 0, 0, 0, False])[5]) if len(skill.get("pl") or []) > 5 else False)
        if not candidates:
            return
        target = candidates[0]
        context["targets"][index] = target
        side = self._team_number(attacker)
        amount = _to_int(step)
        requested = _to_int(target.get("pos", 0)) + (-amount if side == 1 else amount)
        destination = self._get_final_pos(side, int(target.get("line", 0)), requested)
        self._reline(attacker, int(target.get("line", 0)), destination, 0, forced=False)

    def _act_move_to_ally(self, attacker, enemies, allies, skill, action, index, context):
        """move_to_ally (139_SkillSet.as:1369): reline onto a chosen ally."""
        if len(action) < 2:
            raise ValueError("move_to_ally needs a vfx")
        candidates = self._custom_targets(attacker, skill, ally=True, candidates=allies)
        if not candidates:
            return
        ally = candidates[0]
        if int(ally.get("hp", 0)) <= 0:
            return
        context["targets"][index] = ally
        side = self._team_number(attacker)
        destination = self._get_final_pos(side, int(ally.get("line", 0)), _to_int(ally.get("pos", 0)))
        self._reline(attacker, int(ally.get("line", 0)), destination, 0, forced=False)

    def _act_pull(self, attacker, enemies, allies, skill, action, index, context):
        """pull (139_SkillSet.as:1813): damage, then a forced forward move."""
        if len(action) < 4:
            raise ValueError("pull needs a coefficient, a type and a distance")
        targets = self._skill_targets(attacker, enemies, skill.get("pl") or [])
        if not targets:
            return
        target = targets[0]
        self._native_damage(attacker, target, action[1], action[2])
        context["kills"][index] = self._kill_record(targets)
        context["targets"][index] = target
        if int(target.get("hp", 0)) <= 0:
            return
        # 137_Avatar.as:2572 — the buff's value is the distance, and addBuff's
        # consumption calls checkMove(true, value, ..., forced = true).
        self._add_buff(target, "pull", 1, _to_int(action[3]))
        self._check_move(target, True, _to_int(action[3]), forced=True)

    def _act_pull_group(self, attacker, enemies, allies, skill, action, index, context):
        """pull_group (139_SkillSet.as:1819): pull a spread of enemies inward."""
        if len(action) < 5:
            raise ValueError("pull_group needs a coefficient, type, distance and gap")
        targets = self._skill_targets(attacker, enemies, skill.get("pl") or [])
        if not targets:
            return
        maximum = _to_int(action[3])
        keep_gap = _to_int(action[4])
        total = 0
        for target in targets:
            total += self._native_damage(attacker, target, action[1], action[2])
        context["damage"][index] = total
        context["kills"][index] = self._kill_record(targets)
        context["targets"][index] = targets[0]
        side = self._team_number(attacker)
        anchor = _to_int(attacker.get("pos", 0))
        for target in targets:
            if int(target.get("hp", 0)) <= 0:
                continue
            gap = abs(_to_int(target.get("pos", 0)) - anchor)
            travel = min(max(0, gap - keep_gap), maximum) if maximum > 0 else max(0, gap - keep_gap)
            if travel <= 0:
                continue
            self._add_buff(target, "pull", 1, travel)
            self._check_move(target, True, travel, forced=True)

    def _act_push(self, attacker, enemies, allies, skill, action, index, context):
        """push (139_SkillSet.as:1844): damage, then a forced backward move."""
        if len(action) < 4:
            raise ValueError("push needs a coefficient, a type and a distance")
        targets = self._skill_targets(attacker, enemies, skill.get("pl") or [])
        if not targets:
            return
        target = targets[0]
        self._native_damage(attacker, target, action[1], action[2])
        context["kills"][index] = self._kill_record(targets)
        context["targets"][index] = target
        if int(target.get("hp", 0)) <= 0:
            return
        self._add_buff(target, "push", 1, _to_int(action[3]))
        self._check_move(target, False, _to_int(action[3]), forced=True)

    def _act_push_aoe(self, attacker, enemies, allies, skill, action, index, context):
        """push_aoe (139_SkillSet.as:1618): shove everything inside a radius back."""
        if len(action) < 3:
            raise ValueError("push_aoe needs a search radius and a push distance")
        radius = self._skill_area_radius(action[1])
        distance = _to_int(action[2])
        for target in self._find_aim_list(attacker, self._living_opponents(attacker), radius, False):
            if int(target.get("hp", 0)) <= 0:
                continue
            self._check_move(target, False, distance, forced=True)

    def _act_manual_dot(self, attacker, enemies, allies, skill, action, index, context):
        """manual_dot (139_SkillSet.as:919): route an authored DOT onto a target."""
        if len(action) < 6:
            raise ValueError("manual_dot needs at least five arguments")
        targets = self._custom_targets(attacker, skill, ally=False)
        if not targets:
            return
        target = targets[0]
        kind = str(action[1])
        ap_tick = float(action[2]) * self._get_damage(attacker) if isinstance(action[2], (int, float)) else 0
        fraction = float(action[3]) if isinstance(action[3], (int, float)) else 0.0
        rounds = _to_int(action[4])
        if len(action) >= 8:
            damage_type = _to_int(action[5])
            refresh = str(action[6]) if str(action[6]) else str(skill.get("skid", "")) + ":" + str(index)
        elif len(action) == 7 and isinstance(action[5], str) and action[5]:
            damage_type = 0
            refresh = str(action[5])
        else:
            damage_type = 0
            refresh = str(skill.get("skid", "")) + ":" + str(index)
        stacked = len(action) >= 9 and bool(action[7])
        key = "%s:%s" % (attacker.get("aid", "?"), refresh)
        self._add_manual_skill_dot(target, key, kind, ap_tick, fraction, rounds,
                                   attacker, damage_type, stacked)
        context["targets"][index] = target

    def _act_battle_stack(self, attacker, enemies, allies, skill, action, index, context):
        """battle_stack (139_SkillSet.as:1287): permanent stack, gated on a hit.

        ``stackSource.hitHero`` is the AS3 flag; the kill record exposes it as
        the ``hit_heroes`` list. Either condition also requires a plain hit.
        """
        if len(action) < 7:
            raise ValueError("battle_stack needs seven arguments")
        source_index = _to_int(action[4])
        record = None
        if 0 <= source_index:
            record = context.get("kills", {}).get(source_index)
        condition = str(action[5])
        if not record or not record.get("hit"):
            return
        if condition == "any_hit":
            pass
        elif condition == "hero_hit" and record.get("hit_heroes"):
            pass
        else:
            return
        self._add_manual_battle_stack(attacker, action[1], action[2], action[3])

    def _act_battle_stack_unconditional(self, attacker, enemies, allies, skill, action, index, context):
        """battle_stack_unconditional (139_SkillSet.as:885): always applies."""
        if len(action) != 5:
            raise ValueError("battle_stack_unconditional requires exactly four arguments")
        self._add_manual_battle_stack(attacker, action[1], action[2], action[3])

    def _act_timed_stack(self, attacker, enemies, allies, skill, action, index, context):
        """timed_stack (139_SkillSet.as:1299): hard-gated to S_631134_5/6."""
        if len(action) < 6:
            raise ValueError("timed_stack needs six arguments")
        if str(action[1]) != "attack":
            return
        if str(skill.get("skid", "")) not in ("S_631134_5", "S_631134_6"):
            return
        self._add_manual_timed_stack(attacker, action[1], action[2], action[3], action[4])

    def _act_summon(self, attacker, enemies, allies, skill, action, index, context):
        """summon (139_SkillSet.as:1850 -> executeManualSummon).

        ``action[1]`` is a level fraction: the unit spawns at
        ``toInt(fraction * owner.lv)``, floored at 1 for the bounded-policy ids
        (139_SkillSet.as:3067 hasBoundedSummonPolicy). The native placement uses
        ``GameMapConfig.SUMMON_POS``, which is not declared anywhere in the
        reconstructed source; rather than invent a value the unit is placed on
        the caster's own line and slot and the unavailable offset is flagged.
        """
        if len(action) < 5:
            raise ValueError("summon needs a scale, an avatar id, rounds and a vfx")
        aid = str(action[2])
        if not aid:
            return
        rounds = _to_int(action[3])
        if rounds < 1:
            return
        fraction = action[1]
        if not isinstance(fraction, (int, float)) or isinstance(fraction, bool) \
                or not math.isfinite(float(fraction)):
            return
        bounded = self._has_bounded_summon_policy(str(skill.get("skid", "")))
        level = _to_int(float(fraction) * _to_int(attacker.get("lv", 1)))
        if bounded:
            level = max(1, level)
        elif level < 1:
            return
        skill_id = str(skill.get("skid", ""))
        if bounded and self._has_live_bounded_summon(attacker, skill_id):
            return
        clone = self._spawn_summon(attacker, aid, float(fraction), rounds, level=level,
                                   bounded=bounded,
                                   bounded_skill_id=skill_id,
                                   ap_factor=self._summon_ap_factor(skill_id))
        if clone is not None:
            context["targets"][index] = clone

    @staticmethod
    def _has_bounded_summon_policy(skill_id):
        """139_SkillSet.as:3067 hasBoundedSummonPolicy.

        A summon is bounded when the authored per-family table says so, not
        merely because the id has the right shape: the shape gate only admits
        the candidate, and an unlisted family such as 301226 is unbounded.
        """
        parts = str(skill_id).split("_")
        if len(parts) != 3 or parts[0] != "S":
            return False
        try:
            suffix = int(parts[2])
        except (TypeError, ValueError):
            return False
        if suffix < 2 or suffix > 6:
            return False
        family = parts[1]
        stars = _BOUNDED_SUMMON_STARS.get(family)
        if stars is not None:
            return parts[2] in stars
        return family in _BOUNDED_SUMMON_FAMILIES

    @staticmethod
    def _has_live_bounded_summon(owner, skill_id):
        """Match SkillSet.boundedSummons per owner and per skill instance."""
        roster = owner.get("_team")
        if not isinstance(roster, list):
            return False
        owner_id = owner.get("aid")
        owner_token = owner.get("_owner_token")
        for unit in roster:
            if not isinstance(unit, dict) or int(unit.get("hp", 0)) <= 0:
                continue
            if not unit.get("_bounded_summon"):
                continue
            summon_token = unit.get("summon_owner_token")
            if summon_token is not None:
                if summon_token != owner_token:
                    continue
            elif unit.get("summon_owner") != owner_id:
                # Accept old snapshots without a token through the legacy aid
                # field, while tokenized summons remain instance-specific.
                continue
            # Older serialized summons may not carry the skill marker. Treat
            # those as occupying the bounded slot rather than stacking them.
            existing_skill = unit.get("_bounded_summon_skill")
            if existing_skill is None or existing_skill == skill_id:
                return True
        return False

    @staticmethod
    def _summon_ap_factor(skill_id):
        """139_SkillSet.as:3447 getSummonCombatSnapshotApFactor.

        Only two families rescale a summoned unit's combat snapshot; every
        other summon keeps the spawned avatar's own stats.
        """
        parts = str(skill_id).split("_")
        if len(parts) != 3 or parts[0] != "S":
            return 0.0
        family, star = parts[1], parts[2]
        if family == "32551036" and star in ("4", "5", "6"):
            return 0.60
        if family == "32551103" and star in ("4", "5", "6"):
            return 0.30
        return 0.0

    def _spawn_summon(self, owner, aid, scale, rounds, level=None, bounded=False,
                      bounded_skill_id=None, ap_factor=None):
        """Build one summoned unit from the owner's live stats (executeManualSummon).

        ``ap_factor`` selects the native stat model the caller is emulating.
        ``None`` keeps the historical uniform rescale used by the turret and
        clone paths. A number applies 139_SkillSet.as:1878-1889: the rescale
        runs only when the factor is positive, in which case hpMax, ap, dePh
        and deMa come from the *owner* — and the four secondary attrs are
        copied from the owner unconditionally, outside that gate.
        """
        if level is None:
            level = max(1, _to_int(owner.get("lv", 1)))
        try:
            unit = base_unit(self._config, aid, max(1, _to_int(level)),
                             max(1, _to_int(owner.get("slv", 1))),
                             int(owner.get("line", 0)), 0.0, False,
                             self._team_number(owner),
                             enforce_avatar_level_cap=False, summoned=True)
        except (ValueError, KeyError, TypeError, IndexError):
            return None
        if ap_factor is None:
            ratio = float(scale) if isinstance(scale, (int, float)) and not isinstance(scale, bool) else 1.0
            if not math.isfinite(ratio) or ratio <= 0:
                ratio = 1.0
            owner_ap = max(1, _to_int(self._get_damage(owner)))
            owner_hp = max(1, _to_int(owner.get("hp_max", 1)))
            unit["ap"] = max(1, _to_int(owner_ap * ratio))
            unit["hp_max"] = max(1, _to_int(owner_hp * ratio))
            unit["de_ph"] = max(1, _to_int(_to_int(owner.get("de_ph", 0)) * ratio))
            unit["de_ma"] = max(1, _to_int(_to_int(owner.get("de_ma", 0)) * ratio))
            unit["hp"] = unit["hp_max"]
        else:
            factor = float(ap_factor)
            if math.isfinite(factor) and factor > 0:
                unit["hp_max"] = max(1, _to_int(_to_int(owner.get("hp_max", 1)) * 0.20))
                unit["ap"] = max(1, _to_int(self._get_damage(owner) * factor))
                unit["de_ph"] = max(1, _to_int(_to_int(owner.get("de_ph", 0)) * 0.40))
                unit["de_ma"] = max(1, _to_int(_to_int(owner.get("de_ma", 0)) * 0.40))
                unit["hp"] = unit["hp_max"]
            for key in ("hit", "flee", "crit", "tough"):
                unit["new_4attrs"][key] = max(0, _to_int(self._stat_buff(owner, key)))
        if bounded:
            unit["_bounded_summon"] = True
            if bounded_skill_id is not None:
                unit["_bounded_summon_skill"] = str(bounded_skill_id)
        # The kit is kept: the generic summon path (139:1850) never nulls it,
        # so a summoned unit acts on its own pl slots. The turret path clears
        # them itself (139:3158).
        unit["_skill_cd"] = 0
        unit["_buffs"] = {}
        unit["summon_owner"] = owner.get("aid")
        unit["summon_owner_token"] = owner.get("_owner_token")
        unit["_team"] = owner.get("_team")
        unit["line"] = int(owner.get("line", 0))
        # Match the client's authored summon offset, not minimum unit spacing.
        team = self._team_number(owner)
        raw_pos = _to_int(owner.get("pos", 0)) + (-self._SUMMON_POS if team == 1 else self._SUMMON_POS)
        unit["pos"] = self._get_final_pos(team, unit["line"], raw_pos)
        self._add_buff(unit, "summon", max(1, _to_int(rounds)), 0)
        roster = owner.get("_team")
        if isinstance(roster, list):
            roster.append(unit)
        return unit

    @staticmethod
    def _is_heimer_turret_skill(skill_id):
        """139_SkillSet.as:3100 isHeimerTurretSkill — an explicit id whitelist."""
        return str(skill_id) in (
            "S_621014_3", "S_621014_4", "S_621014_5", "S_621014_6",
            "S_631014_3", "S_631014_4", "S_631014_5", "S_631014_6",
            "S_203014_3", "S_203014_4", "S_203014_5", "S_203014_6",
            "S_303014_3", "S_303014_4", "S_303014_5", "S_303014_6",
        )

    def _act_summon_turret(self, attacker, enemies, allies, skill, action, index, context):
        """summon_turret (139_SkillSet.as:1917 -> executeHeimerTurretSummon)."""
        if len(action) < 11:
            raise ValueError("summon_turret requires the authored 11-argument row")
        skid = str(skill.get("skid", ""))
        if not self._is_heimer_turret_skill(skid) or not self._has_bounded_summon_policy(skid):
            return
        if str(action[2]) != "A_2001_4":
            return
        scale = action[1]
        if not isinstance(scale, (int, float)) or isinstance(scale, bool) \
                or not math.isfinite(float(scale)) or not 0 < float(scale) <= 1:
            return
        rounds = _to_int(action[3])
        if rounds < 1 or _to_int(action[4]) != 0 or _to_int(action[5]) != 0:
            return
        # One live turret per hero; the native `boundedSummons[0].hp > 0` check.
        for unit in (attacker.get("_team") or []):
            if int(unit.get("hp", 0)) > 0 and unit.get("_turret"):
                return
        turret = self._spawn_summon(attacker, "A_2001_4", float(scale), rounds,
                                    level=max(1, _to_int(attacker.get("lv", 1))),
                                    bounded=True, bounded_skill_id=skid)
        if turret is None:
            return
        # executeHeimerTurretSummon scales all four secondary stats too, and
        # clears skill0/skill1/skill2/skillB (139:3158) — the clearing lives
        # here, not in _spawn_summon, because the generic summon path keeps the
        # summoned unit's own kit.
        for key in ("hit", "flee", "crit", "tough"):
            turret["new_4attrs"][key] = max(0, _to_int(self._raw_attr(attacker, key) * float(scale)))
        turret["skill"] = None
        turret["leader_skill"] = None
        turret["skillB"] = None
        turret["_turret"] = True
        turret["manualActionTypeOverride"] = 1
        context["targets"][index] = turret

    def _act_clone_normal(self, attacker, enemies, allies, skill, action, index, context):
        """clone_normal (139_SkillSet.as:1914 -> executeManualNormalClone).

        The full guard set needs ``manualClonePolicy``, which the snapshot drops.
        What can be checked from the serialized row is applied; the rest is
        flagged rather than guessed.
        """
        skid = str(skill.get("skid", ""))
        if skid not in ("S_631132_5", "S_631132_6"):
            return
        owner_aid = str(attacker.get("aid", ""))
        if not owner_aid.endswith(skid.rsplit("_", 1)[-1]):
            return
        clone = self._spawn_summon(attacker, owner_aid, 1.0, 1)
        if clone is None:
            return
        clone["_clone_of"] = owner_aid
        clone["_clone_policy_unavailable"] = True
        context["targets"][index] = clone

    def _act_focus_fire(self, attacker, enemies, allies, skill, action, index, context):
        """focus_fire (139_SkillSet.as:1155): every in-range ally strikes one target."""
        if len(action) < 2:
            raise ValueError("focus_fire needs a vfx")
        candidates = self._custom_targets(attacker, skill, ally=False)
        if not candidates:
            return
        target = candidates[0]
        context["targets"][index] = target
        for ally in sorted(allies, key=lambda u: str(u.get("aid", ""))):
            if int(target.get("hp", 0)) <= 0:
                break
            if int(ally.get("hp", 0)) <= 0:
                continue
            if int(ally.get("line", -1)) != int(target.get("line", -2)):
                continue
            if abs(_to_int(ally.get("pos", 0)) - _to_int(target.get("pos", 0))) > self._get_range(ally):
                continue
            self._injured_absolute(target, self._get_damage(ally), 1)

    def _act_dash_group_strike(self, attacker, enemies, allies, skill, action, index, context):
        """dash_group_strike (139_SkillSet.as:899): reline and strike each target."""
        if len(action) < 5:
            raise ValueError("dash_group_strike needs a coefficient, type, heal and vfx")
        targets = self._custom_targets(attacker, skill, ally=False)
        total = 0
        for target in targets:
            if int(target.get("hp", 0)) <= 0:
                continue
            side = self._team_number(attacker)
            requested = _to_int(target.get("pos", 0)) + (-125 if side == 1 else 125)
            destination = self._get_final_pos(side, int(target.get("line", 0)), requested)
            self._reline(attacker, int(target.get("line", 0)), destination, 0, forced=False)
            total += self._native_damage(attacker, target, action[1], action[2])
            # 139_SkillSet.as:912 — the heal is the channel-4 base (getDamage() +
            # 10% hpMax) scaled by action[3] and the active-recovery multiplier,
            # then clamped to the caster's own missing HP.
            heal = self._heal_ap_channel(attacker, float(action[3]))
            if heal > 0:
                self._injured(attacker, heal, damage_type=4)
        context["damage"][index] = total
        context["kills"][index] = self._kill_record(targets)
        if targets:
            context["targets"][index] = targets[0]

    def _has_basic_ability(self, unit):
        """The serializable stand-in for ``avatar.skill0 != null`` (139:866).

        skill0 is the hero's basic ability. The snapshot never carries a skill
        object, but turrets and clones null it out (139:3158/3273), and those
        are exactly the units ``_get_type`` reports as non-heroes.
        """
        return self._get_type(unit) == 1

    def _act_normal_on_hero_kill(self, attacker, enemies, allies, skill, action, index, context):
        """normal_on_hero_kill (139_SkillSet.as:865): recast the basic ability."""
        if len(action) < 3 or not isinstance(action[1], list):
            return
        if not self._has_basic_ability(attacker):
            return
        if bool(attacker.get("_in_kill_recast")):
            return
        for source in action[1]:
            record = context.get("kills", {}).get(_to_int(source))
            if record and record.get("killed") and record.get("killed_type") == 1 \
                    and not record.get("killed_summon"):
                attacker["_in_kill_recast"] = True
                try:
                    self._recast_basic(attacker, enemies)
                finally:
                    attacker["_in_kill_recast"] = False
                return

    def _act_recast_on_kill(self, attacker, enemies, allies, skill, action, index, context):
        """recast_on_kill (139_SkillSet.as:1392): replay the skill, budgeted 0..2."""
        if len(action) < 5:
            raise ValueError("recast_on_kill needs a source index and a limit")
        record = context.get("kills", {}).get(_to_int(action[1]))
        limit = min(2, max(0, _to_int(action[2])))
        owns = _to_int(attacker.get("_kill_recast_remaining", -1)) < 0
        if owns:
            attacker["_kill_recast_remaining"] = limit
        if record and record.get("killed") and (_to_int(action[3]) == 0 or record.get("killed_type") == 1) \
                and (_to_int(action[4]) == 0 or not record.get("killed_summon")) \
                and _to_int(attacker.get("_kill_recast_remaining", 0)) > 0:
            attacker["_kill_recast_remaining"] = _to_int(attacker["_kill_recast_remaining"]) - 1
            self._apply_native_skill(attacker, enemies)
        if owns:
            attacker["_kill_recast_remaining"] = -1

    def _recast_basic(self, attacker, enemies):
        target = min(enemies, key=lambda x: (x.get("line") != attacker.get("line"),
                                             abs(float(x.get("pos", 0)) - float(attacker.get("pos", 0))),
                                             x["hp"]), default=None)
        if target is not None:
            self._basic_attack(attacker, target)

    def _act_ricochet_bursts(self, attacker, enemies, allies, skill, action, index, context):
        """ricochet_bursts (139_SkillSet.as:962 -> castRicochetBursts)."""
        if len(action) != 6 or not isinstance(action[2], list):
            return
        radius = self._skill_area_radius(action[3])
        damage_type = _to_int(action[4])
        coefficients = action[2]
        alive = self._living_opponents(attacker)
        if not alive:
            return
        primary = self._find_aim_list(
            attacker, alive, self._get_range_for_action(attacker, skill),
            bool((skill.get("pl") or [0, 0, 0, 0, 0, False])[5]) if len(skill.get("pl") or []) > 5 else False)
        primary = primary[0] if primary else alive[0]
        totals = {}
        plan = []
        previous = primary
        for step, coefficient in enumerate(coefficients):
            if not isinstance(coefficient, (int, float)) or isinstance(coefficient, bool):
                break
            if step == 0:
                target = primary
            else:
                hops = [u for u in alive if int(u.get("hp", 0)) > 0
                        and int(u.get("line", -1)) == int(primary.get("line", -2))
                        and abs(_to_int(u.get("pos", 0)) - _to_int(previous.get("pos", 0))) <= radius]
                hops = [u for u in hops if u is not previous]
                if not hops:
                    break
                target = min(hops, key=lambda u: (abs(_to_int(u.get("pos", 0)) - _to_int(previous.get("pos", 0))),
                                                  str(u.get("aid", ""))))
            key = id(target)
            totals[key] = totals.get(key, 0.0) + float(coefficient)
            plan.append((target, float(coefficient)))
            previous = target
        for target, coefficient in plan:
            if int(target.get("hp", 0)) <= 0:
                continue
            share = totals.get(id(target), coefficient)
            weight = coefficient / share if share else 1
            source = primary if target is primary else None
            self._native_damage(attacker, target, weight, damage_type)
        context["kills"][index] = self._kill_record([t for t, _ in plan])
        context["targets"][index] = primary

    def _act_pending_area_strike(self, attacker, enemies, allies, skill, action, index, context):
        """pending_area_strike (139_SkillSet.as:1384): queue a delayed strike."""
        if len(action) < 8:
            raise ValueError("pending_area_strike needs eight arguments")
        source = _to_int(action[1])
        origin = context.get("targets", {}).get(source)
        if origin is None or int(origin.get("hp", 0)) <= 0:
            return
        coefficient = action[2]
        radius = action[4]
        max_targets = _to_int(action[5])
        rounds = _to_int(action[6])
        if not isinstance(coefficient, (int, float)) or float(coefficient) < 0:
            return
        if not isinstance(radius, (int, float)) or float(radius) <= 0:
            return
        if max_targets <= 0 or rounds != 1:
            return
        attacker["_pending_strike"] = {
            "target": origin,
            "line": int(origin.get("line", 0)),
            "pos": _to_int(origin.get("pos", 0)),
            "coeff": float(coefficient),
            "type": _to_int(action[3]),
            "radius": self._skill_area_radius(radius),
            "maxTargets": max_targets,
            "rounds": rounds,
            "effect": str(action[7]),
        }

    def _resolve_pending_strike(self, owner):
        """139_SkillSet.as:2990 resolvePendingAreaStrike."""
        strike = owner.get("_pending_strike")
        if not isinstance(strike, dict):
            return
        origin = strike.get("target")
        if origin is None or int(origin.get("hp", 0)) <= 0:
            owner.pop("_pending_strike", None)
            return
        rounds = _to_int(strike.get("rounds", 0))
        if rounds > 1:
            strike["rounds"] = rounds - 1
            return
        owner.pop("_pending_strike", None)
        line = int(origin.get("line", 0))
        position = _to_int(origin.get("pos", 0))
        radius = _to_int(strike.get("radius", 0))
        pool = [u for u in self._living_opponents(owner)
                if int(u.get("line", -1)) == line and abs(_to_int(u.get("pos", 0)) - position) <= radius]
        pool.sort(key=lambda u: (abs(_to_int(u.get("pos", 0)) - position), str(u.get("aid", ""))))
        cap = _to_int(strike.get("maxTargets", 0))
        if cap > 0:
            pool = pool[:cap]
        coefficient = float(strike.get("coeff", 0.0))
        damage_type = _to_int(strike.get("type", 0))
        if damage_type == 3:
            coefficient /= _REAL_DAMAGE_RATE
        for target in pool:
            self._native_damage(owner, target, coefficient, damage_type)

    def _act_damage_chain(self, attacker, enemies, allies, skill, action, index, context):
        """damage_chain (139_SkillSet.as:965): hop a chain across neighbours.

        Per-target visit counts are capped by ``action[5]``; ``action[2]`` is the
        per-hop coefficient array (out-of-range or negative ends the loop). A
        failed first hop onto a dead primary adds ``action[7]`` to the second.
        """
        if len(action) < 12 or not isinstance(action[2], list):
            return
        coefficients = action[2]
        damage_type = _to_int(action[3])
        if not 0 <= damage_type <= 3:
            return
        radius = self._skill_area_radius(max(0, _to_int(action[4])))
        victim_cap = max(1, _to_int(action[5]))
        policy = str(action[6])
        primary_bonus = float(action[7]) if isinstance(action[7], (int, float)) else 0.0
        dot_condition = str(action[8])
        dot_bonus = float(action[9]) if isinstance(action[9], (int, float)) else 0.0
        repeat_primary = bool(action[10])
        candidates = self._custom_targets(attacker, skill, ally=False)
        primary = candidates[0] if candidates else None
        if primary is None or not coefficients:
            return
        reach = self._get_range_for_action(attacker, skill)
        plan, counts = [], {}
        previous = primary
        primary_killed_on_first = False
        hit_index = 0
        while hit_index < max(0, _to_int(action[1])):
            target = None
            if hit_index == 0:
                target = primary
            elif policy in ("enemy_lane_nearest_neighbor", "enemy_lane_behind_primary"):
                hops = self._find_aim_list(attacker, self._living_opponents(attacker), reach, False)
                hops = sorted(hops, key=lambda u: (abs(_to_int(u.get("pos", 0)) - _to_int(previous.get("pos", 0))),
                                                   str(u.get("aid", ""))))
                for candidate in hops:
                    visits = counts.get(id(candidate), 0)
                    if candidate is previous or int(candidate.get("hp", 0)) <= 0:
                        continue
                    if int(candidate.get("line", -1)) != int(primary.get("line", -2)):
                        continue
                    if abs(_to_int(candidate.get("pos", 0)) - _to_int(previous.get("pos", 0))) > radius:
                        continue
                    if policy == "enemy_lane_behind_primary" and not self._is_forward_of(candidate, primary, attacker):
                        continue
                    if visits >= victim_cap:
                        continue
                    target = candidate
                    break
                if target is None and repeat_primary and int(primary.get("hp", 0)) > 0 \
                        and counts.get(id(primary), 0) < victim_cap:
                    target = primary
            if target is None or int(target.get("hp", 0)) <= 0:
                break
            if hit_index >= len(coefficients):
                break
            coefficient = coefficients[hit_index]
            if not isinstance(coefficient, (int, float)) or isinstance(coefficient, bool) \
                    or not math.isfinite(float(coefficient)) or float(coefficient) < 0:
                break
            coefficient = float(coefficient)
            if hit_index == 1 and primary_killed_on_first:
                coefficient += primary_bonus
            if dot_condition == "prehit_burn" and (self._has_manual_dot_kind(target, "burn")
                                                   or self._buff(target, "burn") is not None):
                coefficient += dot_bonus
            elif dot_condition == "prehit_bleed" and self._has_manual_dot_kind(target, "bleed"):
                coefficient += dot_bonus
            before_hp = int(target.get("hp", 0))
            effective = coefficient / _REAL_DAMAGE_RATE if damage_type == 3 else coefficient
            self._native_damage(attacker, target, effective, damage_type)
            if hit_index == 0:
                primary_killed_on_first = before_hp > 0 and int(target.get("hp", 0)) <= 0
            counts[id(target)] = counts.get(id(target), 0) + 1
            plan.append(target)
            previous = target
            hit_index += 1
        context["kills"][index] = self._kill_record(plan)
        context["targets"][index] = primary

    def _is_forward_of(self, a, b, caster):
        """139_SkillSet.as:2699 isForwardOf."""
        if int(a.get("line", -1)) != int(b.get("line", -2)):
            return False
        if self._is_ranged_skill_caster(caster):
            return True
        if int(a.get("isme")):
            return _to_int(a.get("pos", 0)) <= _to_int(b.get("pos", 0))
        return _to_int(a.get("pos", 0)) >= _to_int(b.get("pos", 0))

    def _act_manual_ability(self, attacker, enemies, allies, skill, action, index, context):
        """manual_ability (139_SkillSet.as:806 -> 137_Avatar.as:543 executeAbility).

        The named bodies read ability state the serialized snapshot does not
        carry — forms, marks, guards, zones, per-ability scratch keys. Only the
        positions and totals the server model can express are reproduced, so the
        action reports no effect and the skill continues, exactly as an unknown
        kind does.
        """


    def run(self):
        sides = {1: self.a, 2: self.b}
        for units in sides.values():
            for unit in units:
                unit.setdefault("hp", unit.get("hp_max", 1))
                unit.setdefault("hp_max", unit["hp"])
                unit.setdefault("_skill_cd", int((unit.get("skill") or {}).get("pl", [0, 0])[0]))
                unit.setdefault("_skill_cd_b", int((unit.get("skillB") or {}).get("pl", [0, 0])[0]))
                unit.setdefault("_skill_cd_leader",
                                int((unit.get("leader_skill") or {}).get("pl", [0, 0])[0]))
                unit.setdefault("_buffs", {})
        rounds = 0
        for rounds in range(1, self.max_rounds + 1):
            for side in (1, 2):
                for attacker in (x for x in sides[side] if x["hp"] > 0):
                    if not self._run_unit_turn(attacker, sides, side):
                        break
            if not any(x["hp"] > 0 for x in self.a) or not any(x["hp"] > 0 for x in self.b):
                break
        aa, bb = sum(x["hp"] > 0 for x in self.a), sum(x["hp"] > 0 for x in self.b)
        sa, sb = sum(x["hp"] for x in self.a), sum(x["hp"] for x in self.b)
        winner = 1 if aa and (not bb or sa >= sb) else 2
        return {"winner": winner, "rounds": rounds, "team_a": self.a, "team_b": self.b, "rng_calls": self.rng.calls}

    def _run_unit_turn(self, attacker, sides, side):
        """Run one owner turn from its top-of-turn checks through its action."""
        attacker["_team"] = sides[side]
        # A queued area strike resolves at the top of the owner's next turn.
        self._resolve_pending_strike(attacker)
        if int(attacker.get("hp", 0)) <= 0:
            return True
        enemies = [x for x in sides[3 - side] if x["hp"] > 0]
        if not enemies:
            return False
        for cd_key in ("_skill_cd", "_skill_cd_b", "_skill_cd_leader"):
            self._tick_slot_cd(attacker, cd_key)
        # Avatar.checkSkillB() runs after cooldowns and before checkBuff(). A
        # passive such as Steel Teemo's purify therefore gets a chance to
        # remove a stun on the same owner turn.
        self._use_turn_start_passive(attacker, enemies)
        if int(attacker.get("hp", 0)) <= 0:
            return True
        if self._tick_buffs(attacker):
            return True
        if int(attacker.get("hp", 0)) <= 0:
            return True
        if self._buff(attacker, "stun") is not None:
            return True
        skill = attacker.get("skill")
        silenced = self._buff(attacker, "silence") is not None
        acted = False
        if isinstance(skill, dict) and skill.get("skills") and not silenced:
            acted = self._use_skill_slot(attacker, enemies, "skill", "_skill_cd") or acted
        # checkSkill() tries skill0 and then the leader skill independently;
        # success of the ordinary skill does not suppress the leader cast.
        if attacker.get("leader"):
            acted = self._use_skill_slot(attacker, enemies, "leader_skill", "_skill_cd_leader") or acted
        if not acted:
            target = min(enemies, key=lambda x: (x.get("line") != attacker.get("line"),
                                                  abs(float(x.get("pos", 0)) - float(attacker.get("pos", 0))),
                                                  x["hp"]))
            if self.rng.get_random(100) < 80:
                self._basic_attack(attacker, target)
        return True

    def _tick_slot_cd(self, attacker, cd_key):
        """Advance one skill slot's cooldown counter by a full owner turn.

        079_Avatar.as:3326 ticks skill0, skill1, skill2 and skillB
        unconditionally at the top of every turn, so an idle slot keeps
        cooling down while another slot is the one that fires.
        ``SkillSet.cooldown()`` (139:545) is ``max(-1, n - 1)``.
        """
        attacker[cd_key] = max(-1, int(attacker.get(cd_key, -1)) - 1)

    def _use_skill_slot(self, attacker, enemies, slot, cd_key):
        """Cast one skill slot when it is ready, then re-arm its cooldown.

        ``canEvent`` (139:551) refuses while ``m_cooldownNum >= 0``, so a slot
        is ready only once its counter has gone negative. Combined with the
        per-turn floor at -1 this gives the authored cadence: cooldown 0 fires
        every turn, cooldown 1 fires every other turn, and ``pl[0]`` is the
        opening warmup.
        """
        skill = attacker.get(slot)
        if not isinstance(skill, dict) or not skill.get("skills"):
            return False
        if int(attacker.get(cd_key, -1)) >= 0:
            return False
        if not self._apply_native_skill(attacker, enemies, slot=slot):
            return False
        attacker[cd_key] = max(0, int((skill.get("pl") or [0, 1])[1]))
        return True

    def _use_turn_start_passive(self, attacker, enemies):
        """skillB, evaluated at the top of the owner's turn (079_Avatar.as:3340)."""
        skill_b = attacker.get("skillB")
        if not isinstance(skill_b, dict) or not skill_b.get("skills"):
            return False
        if not self._check_buff_of_skill_b(attacker):
            return False
        if int(attacker.get("hp", 0)) <= 0 or not enemies:
            return False
        return self._use_skill_slot(attacker, enemies, "skillB", "_skill_cd_b")

    def _check_buff_of_skill_b(self, attacker):
        """079_Avatar.as:3468 checkBuffOfSkillB.

        Diffs 1/2/3 are armed by the attack code itself (on miss / on crit / on
        kill) and cannot be decided here, so they do not fire from this gate.
        Diff 14 fires on any of the four secondary-stat buffs. Diff 18 fires
        every turn *unless* the unit holds one of the 17 guard buffs — an early
        return inside the scan — and diff 19 while any listed debuff is held.
        """
        diff = _to_int(attacker.get("skill_diff", 0))
        if diff <= 0:
            return False
        buffs = attacker.get("_buffs")
        names = set(buffs) if isinstance(buffs, dict) else set()
        if diff == 18:
            for name in names:
                if name in _SKILL_B_GUARD_BUFFS:
                    return False
            return True
        if diff == 19:
            return bool(names & _SKILL_B_DEBUFF_TRIGGERS)
        if diff == 14:
            return bool(names & frozenset(["hitup", "fleeup", "critup", "toughup"]))
        trigger = _SKILL_B_BUFF_TRIGGERS.get(diff)
        if trigger is None:
            return False
        return trigger in names

    def _basic_attack(self, attacker, target):
        """A physical auto-attack, routed through the native damage pipeline."""
        damage = max(1, _to_int(self._get_damage(attacker)))
        dealt = max(_to_int(damage * _MIN_DAMAGE_RATE), damage - max(0, self._get_de_ph(target)))
        self._injured(target, dealt, damage_type=1)


_ACTION_HANDLERS = {
    "dash": ReferenceBattle._act_dash,
    "damage": ReferenceBattle._act_damage,
    "true_damage": ReferenceBattle._act_true_damage,
    "suck": ReferenceBattle._act_suck,
    "conditional_damage": ReferenceBattle._act_conditional_damage,
    "stun": ReferenceBattle._act_stun,
    "stun_by_condition": ReferenceBattle._act_stun_by_condition,
    "silence": ReferenceBattle._act_silence,
    "weak": ReferenceBattle._act_weak,
    "weak_percent": ReferenceBattle._act_weak_percent,
    "sunder": ReferenceBattle._act_sunder,
    "sunder_percent": ReferenceBattle._act_sunder_percent,
    "poison": ReferenceBattle._act_poison,
    "burn": ReferenceBattle._act_burn,
    "strong": ReferenceBattle._act_strong,
    "steel": ReferenceBattle._act_steel,
    "armor": ReferenceBattle._act_armor,
    "bless": ReferenceBattle._act_bless,
    "purify": ReferenceBattle._act_purify,
    "cure": ReferenceBattle._act_cure,
    "evil": ReferenceBattle._act_evil,
    "curse": ReferenceBattle._act_curse,
    "taunt": ReferenceBattle._act_taunt,
    "attrup": ReferenceBattle._act_attrup,
    "stat_flat": ReferenceBattle._act_stat_flat,
    "hp_shield": ReferenceBattle._act_hp_shield,
    "caster_hp_shield": ReferenceBattle._act_caster_hp_shield,
    "target_hp_shield": ReferenceBattle._act_target_hp_shield,
    "shield": ReferenceBattle._act_shield,
    "shield_composite": ReferenceBattle._act_shield_composite,
    "shield_followup": ReferenceBattle._act_shield_followup,
    "shield_dispel": ReferenceBattle._act_shield_dispel,
    "dispel_good": ReferenceBattle._act_dispel_good,
    "heal_ap": ReferenceBattle._act_heal_ap,
    "heal_missing_hp": ReferenceBattle._act_heal_missing_hp,
    "heal_damage_sum": ReferenceBattle._act_heal_damage_sum,
    "heal_missing_hp_per_hero": ReferenceBattle._act_heal_missing_hp_per_hero,
    "locked_sequence": ReferenceBattle._act_locked_sequence,
    "locked_sequence_area": ReferenceBattle._act_locked_sequence_area,
    "locked_combo_group": ReferenceBattle._act_locked_combo_group,
    "locked_combo_weak": ReferenceBattle._act_locked_combo_weak,
    "combo": ReferenceBattle._act_combo,
    "trynd_undying": ReferenceBattle._act_trynd_undying,
    "lethal_floor": ReferenceBattle._act_lethal_floor,
    "lethal_floor_group": ReferenceBattle._act_lethal_floor_group,
    "back": ReferenceBattle._act_back,
    "kill_buff": ReferenceBattle._act_kill_buff,
    # Kinds the client switch does not implement: explicit no-ops.
    "hitup": ReferenceBattle._act_hitup,
    "fleeup": ReferenceBattle._act_fleeup,
    # Newly reconstructed kinds.
    "manual_ability": ReferenceBattle._act_manual_ability,
    "select_target": ReferenceBattle._act_select_target,
    "move_self": ReferenceBattle._act_move_self,
    "move_to_target": ReferenceBattle._act_move_to_target,
    "move_to_target_lane": ReferenceBattle._act_move_to_target_lane,
    "move_enemy_side_target": ReferenceBattle._act_move_enemy_side_target,
    "move_to_ally": ReferenceBattle._act_move_to_ally,
    "pull": ReferenceBattle._act_pull,
    "pull_group": ReferenceBattle._act_pull_group,
    "push": ReferenceBattle._act_push,
    "push_aoe": ReferenceBattle._act_push_aoe,
    "manual_dot": ReferenceBattle._act_manual_dot,
    "battle_stack": ReferenceBattle._act_battle_stack,
    "battle_stack_unconditional": ReferenceBattle._act_battle_stack_unconditional,
    "timed_stack": ReferenceBattle._act_timed_stack,
    "summon": ReferenceBattle._act_summon,
    "summon_turret": ReferenceBattle._act_summon_turret,
    "clone_normal": ReferenceBattle._act_clone_normal,
    "focus_fire": ReferenceBattle._act_focus_fire,
    "dash_group_strike": ReferenceBattle._act_dash_group_strike,
    "normal_on_hero_kill": ReferenceBattle._act_normal_on_hero_kill,
    "recast_on_kill": ReferenceBattle._act_recast_on_kill,
    "ricochet_bursts": ReferenceBattle._act_ricochet_bursts,
    "damage_chain": ReferenceBattle._act_damage_chain,
    "pending_area_strike": ReferenceBattle._act_pending_area_strike,
}
