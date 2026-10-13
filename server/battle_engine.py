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
              limit_break=False, npc_limit_break=False):
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
    result = {"aid":str(aid),"ap":stats["attack"],"morph":0,"buffs":{},"de_ma":stats["magic_defense"],"de_ph":stats["physical_defense"],"hp":stats["health"],"hp_max":stats["health"],"isme":team==1,"leader":1 if leader else 0,"line":int(line),"lv":level,"new_4attrs":{"hit":0,"flee":0,"crit":0,"tough":0},"pos":native_pos,"slv":int(slv),"tpl":[int(tl[i]) if len(tl)>i else 0 for i in range(3)]+[int(pl[8]) if len(pl)>8 else 0,int(pl[9]) if len(pl)>9 else 0],"talent":None,"skill":skill,"leader_skill":leader_skill,"book_skill":None,"skillB":skill_b}
    if instance_id: result["instance_id"] = instance_id
    # Avatar.toDataObj includes advancement even when it is zero. Player
    # attributes already contain its stat bonus; the snapshot must also carry
    # the stored phase so origin checks compare the same progression state.
    result["phase"] = 0
    if limit_break or npc_limit_break: result["limit_break"] = 1
    if overrides:
        for key in ("hp","hp_max","ap","de_ma","de_ph","line","pos","new_4attrs","tpl","talent","skill","leader_skill","book_skill","skillB","morph","phase"):
            if key in overrides: result[key] = overrides[key]
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
    if not result: raise ValueError("battle requires at least one saved formation avatar")
    return result


class ReferenceBattle:
    """Approximate deterministic tuner; client results remain authoritative."""
    _LINE_POS = 3000
    _MIN_SPACE_POS = 200

    def __init__(self, team_a, team_b, seed=82684, max_rounds=30):
        self.a, self.b = [dict(x) for x in team_a], [dict(x) for x in team_b]
        self.rng = CombatRandom(int(seed))
        self.max_rounds = max(1, int(max_rounds))

    @staticmethod
    def _skill_targets(attacker, candidates, pl):
        alive = [u for u in candidates if int(u.get("hp", 0)) > 0]
        if not alive:
            return []
        reach = abs(int(pl[2])) if len(pl) > 2 else 0
        if reach <= 0:
            return []
        if reach <= 100:
            alive = [u for u in alive if u.get("line") == attacker.get("line")]
        alive = [u for u in alive if abs(float(u.get("pos", 0)) - float(attacker.get("pos", 0))) <= reach]
        alive.sort(key=lambda u: (u.get("line") != attacker.get("line"), abs(float(u.get("pos", 0)) - float(attacker.get("pos", 0))), int(u.get("hp", 0))))
        return alive[:max(1, int(pl[4]) + 1)]

    @staticmethod
    def _native_damage(attacker, target, multiplier, damage_type):
        base = max(1, int(int(attacker.get("ap", 1)) * float(multiplier)))
        damage_type = int(damage_type)
        if damage_type == 3:
            dealt = int(base * 0.3)  # Original Avatar.REAL_DAMAGE_RATE.
        else:
            defense = "de_ph" if damage_type == 1 else "de_ma"
            dealt = max(int(base * 0.1), base - max(0, int(target.get(defense, 0))))
        absorbed = min(max(0, int(target.get("_shield", 0))), dealt)
        target["_shield"] = max(0, int(target.get("_shield", 0)) - absorbed)
        dealt -= absorbed
        target["hp"] = max(0, int(target.get("hp", 0)) - dealt)
        return dealt

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

    @classmethod
    def _apply_native_skill(cls, attacker, enemies):
        """Execute this reconstruction's native action subset; reject unsupported rows."""
        skill = attacker.get("skill")
        if not isinstance(skill, dict) or not isinstance(skill.get("skills"), list):
            return False
        actions = skill["skills"]
        supported = {"dash", "damage", "suck", "silence", "shield", "stun"}
        if not actions or any(not isinstance(a, list) or not a or a[0] not in supported for a in actions):
            return False
        if any(a[0] == "dash" for a in actions):
            if any(len(a) < 2 or not isinstance(a[1], (int, float)) or isinstance(a[1], bool) for a in actions if a[0] == "dash"):
                return False
            if not cls._can_apply_dash(attacker, enemies):
                return False
        for action in actions:
            kind = action[0]
            if kind == "dash":
                cls._apply_dash(attacker, enemies, action[1])
            elif kind == "shield":
                attacker["_shield"] = int(attacker.get("_shield", 0)) + max(0, int(int(attacker.get("ap", 1)) * float(action[1])))
            elif kind == "damage":
                for target in cls._skill_targets(attacker, enemies, skill.get("pl") or []):
                    cls._native_damage(attacker, target, action[1], action[2])
            elif kind == "suck":
                targets = cls._skill_targets(attacker, enemies, skill.get("pl") or [])
                total = sum(cls._native_damage(attacker, target, action[1], action[2]) for target in targets)
                attacker["hp"] = min(int(attacker.get("hp_max", attacker.get("hp", 0))), int(attacker.get("hp", 0)) + int(total * float(action[3])))
            elif kind in {"silence", "stun"}:
                for target in cls._skill_targets(attacker, enemies, skill.get("pl") or []):
                    cls._native_damage(attacker, target, action[1], action[2])
                    target["_" + kind] = max(int(target.get("_" + kind, 0)), int(action[3]))
        return True

    @staticmethod
    def _basic_attack(attacker, target):
        damage = max(1, int(attacker.get("ap", 1)) - max(0, int(target.get("de_ph", 0))))
        absorbed = min(max(0, int(target.get("_shield", 0))), damage)
        target["_shield"] = max(0, int(target.get("_shield", 0)) - absorbed)
        target["hp"] = max(0, int(target.get("hp", 0)) - (damage - absorbed))

    def run(self):
        sides = {1: self.a, 2: self.b}
        for units in sides.values():
            for unit in units:
                unit.setdefault("hp", unit.get("hp_max", 1))
                unit.setdefault("hp_max", unit["hp"])
                unit.setdefault("_skill_cd", int((unit.get("skill") or {}).get("pl", [0, 0])[0]))
        rounds = 0
        for rounds in range(1, self.max_rounds + 1):
            for side in (1, 2):
                for attacker in (x for x in sides[side] if x["hp"] > 0):
                    if attacker.get("_stun", 0) > 0:
                        attacker["_stun"] -= 1
                        continue
                    enemies = [x for x in sides[3 - side] if x["hp"] > 0]
                    if not enemies:
                        break
                    skill = attacker.get("skill")
                    if isinstance(skill, dict) and skill.get("skills"):
                        if attacker["_skill_cd"] > 0:
                            attacker["_skill_cd"] -= 1
                        elif self._apply_native_skill(attacker, enemies):
                            attacker["_skill_cd"] = max(1, int((skill.get("pl") or [0, 1])[1]))
                            continue
                    target = min(enemies, key=lambda x: (x.get("line") != attacker.get("line"), abs(float(x.get("pos", 0)) - float(attacker.get("pos", 0))), x["hp"]))
                    if self.rng.get_random(100) < 80:
                        self._basic_attack(attacker, target)
            if not any(x["hp"] > 0 for x in self.a) or not any(x["hp"] > 0 for x in self.b):
                break
        aa, bb = sum(x["hp"] > 0 for x in self.a), sum(x["hp"] > 0 for x in self.b)
        sa, sb = sum(x["hp"] for x in self.a), sum(x["hp"] for x in self.b)
        winner = 1 if aa and (not bb or sa >= sb) else 2
        return {"winner": winner, "rounds": rounds, "team_a": self.a, "team_b": self.b, "rng_calls": self.rng.calls}
