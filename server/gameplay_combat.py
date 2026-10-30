"""Original-client-compatible battle setup and single-player progression RPCs."""
from __future__ import annotations
from ancient_trial_drop import roll_ancient_trial_drop,roll_ancient_exclusive_drop

import copy, datetime, hashlib, math, random, secrets, time
from player_store import GameplayFault
from gameplay_common import grant_reward, game_day
from battle_engine import base_unit, serialize_player_team, serialize_stage_team, validate_team_lane_coverage
from battle_intents import create_intent, consume_intent
from pve_modes import exploration_stages, expedition_reward_per_hero
from solo_progression import expedition_stones, exploration_encounter, exploration_difficulty, _native_team_power
from gameplay_energy import energy_state, write_energy_after_spend
from equipment_elite_drop import roll_elite_drop
from hero_drop import roll_campaign_hero_drop
from mod_policy import (runtime as mod_runtime, effective_digest, validate_battle_config,
                        candidate_ids, ensure_reward, ensure_available, base_aid,
                        hero_available, band_candidates, retain_frozen_intent)
from tower_rewards_103 import roll_tower_reward, roll_tower_encounter, validate_tower_reward, SCHEMA as TOWER_REWARD_SCHEMA
from material_attempts_103 import remaining as material_remaining, consume_win as consume_material_win, daily_state as material_daily, BUY_COST


class GameplayCombat:
    def __init__(self, store, config):
        self.store = store
        self.full_config = config if isinstance(config, dict) else {}
        self.config = self.full_config.get("cfg", self.full_config)
        self.pve = config.get("pve", {}) if isinstance(config, dict) else {}
        self.tables = self.full_config

    def dispatch(self, uid, method, params):
        if not isinstance(params, dict):
            raise GameplayFault("InvalidRequest", "Combat params must be an object")
        if method == "user.pk_combat":
            return self._start_main(uid, params)
        if method == 'user.material_buy_attempt':
            return self._buy_material_attempt(uid,params)
        if method == "user.pve_finish":
            return self._finish(uid, params)
        if method == "user.battle_finish" and params.get("fight_kind") == "exploration":
            return self._finish_exploration(uid, params)
        if method == "user.battle_finish" and params.get("fight_kind") == "activity":
            # GameMap routes only main/main_hard to pve_finish; daily activities
            # use battle_finish and share the same one-shot PvE intent settlement.
            return self._finish(uid, params)
        if method in {"user.expedition", "user.exploration_start", "user.exploration_combat", "user.exploration_get_reward", "user.exploration_refresh", "user.exploration_opponent", "user.exploration_make_army", "user.exploration_relive", "user.exploration_buy_mode"}:
            return self._dispatch_mode(uid, method, params)
        raise GameplayFault("NotImplemented", "Method not reconstructed: " + method)

    def _cfg(self, table):
        return self.tables.get(table, self.config.get(table, {}))

    @staticmethod
    def _operation_key(method, params):
        action = params.get("actionID")
        return f"{method}:{action}" if isinstance(action, str) and action else None

    @staticmethod
    def _chapter_id(cid):
        bits = str(cid).split("_")
        if len(bits) != 3 or bits[0] != "M":
            raise GameplayFault("UnknownStage", "Main stage id is invalid")
        try:
            return int(bits[1]), int(bits[2])
        except ValueError as exc:
            raise GameplayFault("UnknownStage", "Main stage id is invalid") from exc

    def _stage(self, cid, diff, check_activity_window=True):
        activity_stage = self._cfg("combat_ploy").get(str(cid)) if int(diff) == 0 else None
        if activity_stage:
            chapter_key = str(cid).rsplit("_", 1)[0]
            chapter = self._cfg("battle_ploy").get(chapter_key)
            stage = activity_stage
            if not chapter or int(str(cid).rsplit("_", 1)[-1]) > int(chapter.get("combat", 0)):
                raise GameplayFault("UnknownStage", "Configured activity stage does not exist")
            if check_activity_window and not self._activity_is_open(chapter):
                raise GameplayFault("ActivityClosed", "This activity is outside its configured open period")
        else:
            chapters = self._cfg("battle_main")
            stages = self._cfg("combat_main")
            chapter_id, combat_no = self._chapter_id(cid)
            chapter_key = f"M_{chapter_id:03d}"
            chapter = chapters.get(chapter_key)
            stage = stages.get(str(cid))
            if not chapter or not stage or combat_no > int(chapter.get("combat", 0)):
                raise GameplayFault("UnknownStage", "Configured stage does not exist")
        if int(diff) not in (0, 1):
            raise GameplayFault("InvalidDifficulty", "Difficulty must be normal or hard")
        if int(diff) == 1 and not self.tables.get("hard_enabled", True):
            raise GameplayFault("UnavailableDifficulty", "Hard mode is not configured")
        return chapter, stage

    @staticmethod
    def _config_epoch(value, default):
        if isinstance(value, dict): value=value.get("$date", default)
        if type(value) not in (int,float): return default
        return int(value)

    def _activity_is_open(self, chapter, now=None):
        now=int(self.store.clock.now() if now is None else now)
        start=self._config_epoch(chapter.get("start_time"),0)
        end=self._config_epoch(chapter.get("end_time"),2**31-1)
        if now < start or now >= end: return False
        cycle=max(1,int(chapter.get("cycle",1440))*60)
        duration=max(0,int(chapter.get("duration",cycle//60))*60)
        return (now-start)%cycle < duration

    def _start_main(self, uid, params):
        cid = str(params.get("cid", "")); diff = int(params.get("diff", 0)); chapter, stage = self._stage(cid, diff)
        is_activity = cid in self._cfg("combat_ploy") and diff == 0
        activity_kind = stage.get("activity_kind") if is_activity else None
        seed = secrets.randbelow(2**31-1)+1
        fight_id = secrets.token_urlsafe(18)
        if is_activity and activity_kind == 'tower' and stage.get('tower_enemy_rule'):
            stage=roll_tower_encounter(self.config,stage,random.Random(seed))
        try:
            attr_fn = None
            try:
                from gameplay_roster import GameplayRosterEquipment
                attr_fn = GameplayRosterEquipment(self.store, self.full_config).battle_attributes
            except ImportError:
                pass
            def mutate(profile):
                profile.setdefault("cid", "M_001_1"); profile.setdefault("hid", "M_001_1")
                progress = profile["hid"] if diff else profile["cid"]
                if activity_kind == "tower":
                    floor = int(stage.get("tower_floor", 0))
                    frontier = max(1, int(profile.setdefault("records", {}).get("tower_floor", 1)))
                    if floor < 1 or floor > int(chapter['combat']) or floor > frontier:
                        raise GameplayFault("TowerFloorLocked", "Complete the preceding tower floor first")
                elif activity_kind == "material":
                    if material_remaining(profile,cid.rsplit('_',1)[0],self.store.clock.now())<=0:
                        raise GameplayFault("ActivityAttemptsExhausted", "This material activity has no shared attempts remaining today")
                if not is_activity and int(profile.get("lv", 1)) < int(chapter.get("ulv", 1)):
                    raise GameplayFault("StageLocked", "Player level is below this chapter's unlock requirement")
                if not is_activity and not self._is_unlocked(cid, progress):
                    raise GameplayFault("StageLocked", "Complete the previous stage first")
                limit_value = stage.get("limit", [99, 99, 99])
                limit = int(limit_value[diff] if isinstance(limit_value, list) and len(limit_value) > diff
                            else limit_value if type(limit_value) is int else 99)
                attempt_bucket = "combat_ploy" if is_activity else "combat_main_hard" if diff else "combat_main"
                attempts = int(profile.get("records", {}).get('daily_stage_attempts',{}).get(attempt_bucket, {}).get(cid, 0))
                if attempts >= limit and activity_kind != 'material' and not stage.get("unlimited_attempts"):
                    raise GameplayFault("ActivityAttemptsExhausted" if is_activity else "StageAttemptsExhausted",
                                        "This stage has no attempts remaining")
                own = serialize_player_team(self.config, profile, params.get("team_num", 0), params.get("team", []), attr_fn)
                assist = self._resolve_assist(profile, params)
                client_team_a = copy.deepcopy(own)
                if assist:
                    # The client includes the selected helper in team1List and
                    # checks every unit against orgin_team_a. It is not owned
                    # in profile.avatars, so serialize its validated battle
                    # snapshot separately as the sixth member.
                    client_team_a.append(copy.deepcopy(assist["battle_snapshot"]))
                map_team_a = serialize_stage_team(self.config, stage.get("team1", []), team=1)
                # Mainline difficulty may have a separately authored formation.
                # Activity stages continue to use their original team2 roster.
                enemy_entries = stage.get("team2", [])
                if not is_activity:
                    by_diff = stage.get("team2_by_diff", {})
                    if isinstance(by_diff, dict):
                        enemy_entries = by_diff.get(str(diff), enemy_entries)
                enemy = serialize_stage_team(self.config, enemy_entries, team=2)

                # Native GameMapRuntime applies difficulty only to configured
                # map units (GameMapData.team1List/team2List), after applying
                # each map's shared new_4attrs. Player and helper avatars are
                # initialized through separate paths and must stay unscaled.
                diff_rows = self.config.get("system_simple", {}).get("combat_diff", [])
                factors = None
                if diff:
                    if (not isinstance(diff_rows, list) or diff >= len(diff_rows)
                            or not isinstance(diff_rows[diff], list) or len(diff_rows[diff]) < 2):
                        raise GameplayFault("InvalidCombatConfig", "Difficulty scaling is not configured")
                    factors = diff_rows[diff]
                stage_attrs = stage.get("new_4attrs")
                for unit in map_team_a + enemy:
                    if isinstance(stage_attrs, list) and len(stage_attrs) >= 4:
                        unit["new_4attrs"] = dict(zip(("hit", "flee", "crit", "tough"),
                                                       (int(value) for value in stage_attrs[:4])))
                    if factors is not None:
                        for key in ("hp", "hp_max", "ap", "de_ph", "de_ma"):
                            unit[key] = int(unit[key] * factors[0])
                        for key in ("hit", "flee", "crit", "tough"):
                            unit["new_4attrs"][key] = int(unit["new_4attrs"][key] * factors[1])
                # Difficulty anchors are per team2 entry, so repeated units
                # retain their own positional budget. The same final values
                # are sent in orgin_team_b below. Other modes keep their
                # native combat_diff path.
                scale_rows = (stage.get("enemy_unit_stats_by_diff", {})
                              if is_activity or cid.startswith("M_") else {})
                if isinstance(scale_rows, dict) and str(diff) in scale_rows:
                    overrides = scale_rows[str(diff)]
                    if not isinstance(overrides, list) or len(overrides) != len(enemy):
                        raise GameplayFault("InvalidStage", "Enemy difficulty snapshot has the wrong team2 length")
                    for index, override in enumerate(overrides):
                        if override is None:
                            continue
                        unit = enemy[index]
                        if (not isinstance(override, dict) or override.get("index") != index
                                or override.get("aid") != base_aid(self.config, unit.get("aid"))):
                            raise GameplayFault("InvalidStage", "Enemy difficulty snapshot does not match team2 order")
                        try:
                            hp = max(0, int(override["hp"]))
                            for key in ("ap", "de_ph", "de_ma"):
                                unit[key] = max(0, int(override[key]))
                            affixes = {key: max(0, int(override[key]))
                                       for key in ("hit", "flee", "crit", "tough")}
                        except (KeyError, TypeError, ValueError, OverflowError) as exc:
                            raise GameplayFault("InvalidStage", "Enemy difficulty snapshot has invalid stats") from exc
                        unit["hp"] = hp
                        unit["hp_max"] = hp
                        unit["new_4attrs"] = affixes
                client_team_a.extend(map_team_a)

                if not enemy:
                    raise GameplayFault("InvalidStage", "Stage has no enemy formation")
                map_line = stage.get("line", [3, ["mg001", "mg002", "mg003"]])
                if not isinstance(map_line, list) or not map_line or type(map_line[0]) is not int:
                    raise GameplayFault("InvalidStage", "Stage has an invalid native lane layout")
                lane_count = map_line[0]
                try:
                    validate_team_lane_coverage(client_team_a, lane_count, "player formation")
                except ValueError as exc:
                    raise GameplayFault("InvalidFormation", f"Every route needs a hero; this map requires at least {lane_count} heroes") from exc
                try:
                    validate_team_lane_coverage(enemy, lane_count, "stage enemy formation")
                except ValueError as exc:
                    raise GameplayFault("InvalidStage", "Stage enemies must cover every native route") from exc
                energy_cost=max(0,int(stage.get('energy',0)))
                if mod_runtime(self.config):
                    channel = "acquisition.drop.activity" if is_activity else "acquisition.drop.campaign"
                    ensure_reward(self.config, stage.get("reward", {}), channel)
                    ensure_reward(self.config, stage.get("reward", {}).get("first_clear", {}), channel)
                    if not is_activity:
                        groups = {}
                        for row in stage.get("hero_drop_candidates_by_diff", {}).get(str(diff), []):
                            if isinstance(row, dict):
                                groups.setdefault(row.get("star"), []).append(row.get("aid"))
                        for quality, ids in groups.items():
                            if not candidate_ids(self.config, ids, "acquisition.drop.campaign", include_new=True, quality=quality):
                                raise GameplayFault("ModPoolEmpty", "主线英雄掉落的某个品阶池为空")
                    if is_activity and stage.get("activity_kind") == "tower":
                        if stage.get('tower_reward_rule',{}).get('schema') == TOWER_REWARD_SCHEMA:
                            validate_tower_reward(self.full_config,stage)
                        else:
                            soul_pool = band_candidates(self.config, stage.get("soul_candidates", []), "acquisition.drop.tower_soul")
                            if not soul_pool:
                                raise GameplayFault("ModPoolEmpty", "爬塔英雄碎片池为空")
                            if int(stage.get("tower_floor", 0)) > 100 and not candidate_ids(self.config, stage.get("tower_hero_candidates", []), "acquisition.drop.tower_hero", include_new=True, quality=6):
                                raise GameplayFault("ModPoolEmpty", "爬塔整卡池为空")
                energy_state=self._spend_energy(profile,energy_cost)
                stage_copy = copy.deepcopy(stage)
                stage_copy["line"] = map_line
                stage_copy["id"] = cid
                stage_copy["team2"] = copy.deepcopy(enemy_entries)
                pending = {"fight_id": fight_id, "cid": cid, "diff": diff, "seed": seed,
                           # Private settlement entropy is persisted with the
                           # intent. A capacity failure rolls the transaction
                           # back, so retries must reproduce this fight's
                           # optional drops instead of rerolling them.
                           "reward_seed": secrets.token_hex(32),
                           "kind":"activity" if is_activity else "main","stage": stage_copy, "created": int(self.store.clock.now()), "expires": int(self.store.clock.now())+3600,
                           "team_a": client_team_a, "team_b": enemy, "assist": copy.deepcopy(assist), "settled": False}
                if effective_digest(self.config):
                    pending["mod_digest"] = effective_digest(self.config)
                profile.setdefault("pending_pve", {})[fight_id] = pending
                profile["pending_pve"] = {k:v for k,v in profile["pending_pve"].items()
                                          if int(v.get("expires", 0)) > int(self.store.clock.now())
                                          or retain_frozen_intent(self.config, v)}
                data = {"fight_id": fight_id, "fight_kind": "activity" if is_activity else "main_hard" if diff else "main", "metadata": {"cid": cid, "diff": diff}, "seed": seed, "poke_data": {}, "cid": cid, "diff": diff,
                        "line": stage_copy["line"], "team1": stage_copy.get("team1", []), "team2": stage_copy["team2"],
                        # Native GameMap.checkOrginTeam compares its locally
                        # initialized units against these original snapshots;
                        # initByOrgin also needs them for replay/auto-load.
                        # Keep the exact spelling used by the original client.
                        "orgin_team_a": copy.deepcopy(client_team_a), "orgin_team_b": copy.deepcopy(enemy),
                        "win": stage_copy.get("win", [-1]),
                        "next_cid": progress, "sign": 0, "gold": profile.get("gold", 0),
                        "coin": profile.get("coin", 0), "score": profile.get("score", 0),
                        "medal": profile.get("medal", 0), "mark": profile.get("mark", 0),
                        "exp": profile.get("exp", 0), "lv": profile.get("lv", 1),
                        "combat_score": profile.get("combat_score", {"normal":{},"hard":{},"ploy":{}}),
                        "energy": profile.get("energy", {"$date":int(self.store.clock.now())}),
                        "attr_energy_extra": profile.get("attrs", {}).get("energy_extra", 0),"energy_cost":energy_cost,"energy_now":energy_state}
                if assist:
                    data["friend_avatar"] = copy.deepcopy(assist["friend_avatar"])
                return profile, data
            data, _ = self.store.atomic_update(uid, mutate, self._operation_key("user.pk_combat", params), params)
            return data
        except GameplayFault:
            raise
        except (ValueError, TypeError, KeyError) as exc:
            raise GameplayFault("InvalidFormation", str(exc)) from exc

    def _buy_material_attempt(self,uid,params):
        chapter=str(params.get('bid',''))
        definition=self._cfg('battle_ploy').get(chapter)
        stages=[s for key,s in self._cfg('combat_ploy').items() if key.startswith(chapter+'_')]
        if (not isinstance(definition,dict) or not stages
                or any(s.get('activity_kind')!='material' for s in stages)):
            raise GameplayFault('InvalidStage','只能为资源副本购买挑战次数。')
        if not self._activity_is_open(definition):
            raise GameplayFault('ActivityClosed','This resource activity is closed')
        if not self._operation_key('user.material_buy_attempt',params):
            raise GameplayFault('InvalidRequest','Resource purchases require an actionID')
        def mutate(profile):
            daily=material_daily(profile,self.store.clock.now())
            bought=daily['buys'].get(chapter,0)
            limit=max(0,int(profile.get('vip_lv',0)))+2
            if bought>=limit:raise GameplayFault('DailyLimit','今日该资源副本购买次数已用完。')
            if int(profile.get('coin',0))<BUY_COST:
                raise GameplayFault('InsufficientCoin','金砖不足，购买一次需要50金砖。')
            profile['coin']-=BUY_COST
            daily['buys'][chapter]=bought+1
            return profile,{'coin':profile['coin'],'records':copy.deepcopy(profile['records']),
                            'material_challenge':{'bid':chapter,'remaining':material_remaining(profile,chapter,self.store.clock.now()),
                                                  'buys':bought+1,'buy_limit':limit,'cost':BUY_COST}}
        result,replayed=self.store.atomic_update(uid,mutate,self._operation_key('user.material_buy_attempt',params),{'bid':chapter})
        result['replayed']=replayed
        return result

    def _resolve_assist(self, profile, params):
        """Bind the optional sixth PvE formation row to a locally available helper."""
        team = params.get("team", [])
        if not isinstance(team, list) or len(team) < 6:
            return None
        row = team[5]
        if not isinstance(row, (list, tuple)) or len(row) < 5:
            return None
        uid = str(row[-2])
        is_friend = row[-1] in (1, True, "1")
        if row[-1] not in (0, 1, False, True, "0", "1"):
            return None
        from gameplay_social import GameplaySocial
        social = GameplaySocial(self.store, self.full_config)
        helper = social.lookup_assist(uid, profile)
        # Native Avatar.init synthesizes ``<aid>-<counter>`` when the selected
        # friend-card object has no id field. Other renderer paths retain the
        # base aid or the helper roster id (``aid|sequence``). Accept only
        # these exact identities after resolving the selected local UID.
        row_id = str(row[0])
        avatar = helper.get("avatar") or {}
        expected_aid = str(avatar.get("aid", "")).split("|", 1)[0]
        original_aid = base_aid(self.config, expected_aid)
        helper_avatar_id = str(helper.get("avatar_id", ""))
        valid_helper_ids = {expected_aid, original_aid, helper_avatar_id}
        if row_id not in valid_helper_ids:
            prefix = expected_aid + "-"
            suffix = row_id[len(prefix):] if row_id.startswith(prefix) else ""
            if suffix.isdigit():
                valid_helper_ids.add(row_id)
        if row_id not in valid_helper_ids:
            raise GameplayFault("InvalidAssist", "Selected helper does not match the local friend card")
        profile_friends = profile.get("social", {}).get("friends", [])
        if isinstance(profile_friends, dict):
            friend_ids = {str(key) for key, enabled in profile_friends.items() if enabled}
        elif isinstance(profile_friends, (list, tuple, set)):
            friend_ids = {str(friend_id) for friend_id in profile_friends}
        else:
            friend_ids = set()
        if is_friend and uid not in friend_ids:
            raise GameplayFault("InvalidAssist", "Selected helper is not in the player's friend list")
        now = int(self.store.clock.now())
        simple = self.config.get("system_simple", {})
        friend_cd = simple.get("friend_cd", [0, 0, 60, 5])
        cd_seconds = max(0, int(friend_cd[2] if isinstance(friend_cd, list) and len(friend_cd) > 2 else 60)) * 60
        cd_time = {"$date": now + cd_seconds} if is_friend and not social.is_bot_uid(uid, profile) else {"$date": 0}
        avatar = copy.deepcopy(helper["avatar"])
        # GameMap.reSend() passes this object to Avatar.reInit(). That native
        # path requires aid to be the roster instance form ``base|sequence``:
        # it slices the base before the pipe and resolves the embedded avatar
        # resource before applying the supplied battle stats. The friend-list
        # card intentionally exposes the base aid, so give only the battle
        # snapshot the helper's validated instance id.
        if "|" not in helper_avatar_id or helper_avatar_id.split("|", 1)[0] != original_aid:
            raise GameplayFault("InvalidAssist", "Selected helper has an invalid avatar instance")
        avatar["aid"] = expected_aid + "|" + helper_avatar_id.split("|", 1)[1]
        avatar["is_friend"] = bool(is_friend)
        avatar["cd_time"] = cd_time
        # Construct the exact native combatant snapshot alongside the
        # reInit payload. The displayed helper card keeps its base aid, while
        # this snapshot must use Avatar.toDataObj's base id and battle slot.
        try:
            line = max(0, min(2, int(row[1]))) if len(row) > 2 else 0
            pos = max(0.0, min(1.0, float(row[2]))) if len(row) > 2 else 0.5
            overrides = {key: avatar.get(key) for key in (
                "hp", "hp_max", "ap", "de_ph", "de_ma", "tpl", "talent", "morph", "phase", "culture_schema",
                "skill", "leader_skill", "book_skill", "skillB", "bonds_104", "equipment_bonds_104", "growth_stats_applied")}
            overrides["leader_skill"] = avatar.get("leader_skill") if is_friend else None
            overrides["new_4attrs"] = {
                key: (avatar.get("new_4attrs") or {}).get(key, 0)
                for key in ("hit", "flee", "crit", "tough")}
            battle_snapshot = base_unit(
                self.config, expected_aid, int(avatar.get("lv", 1)),
                int(avatar.get("slv", 1)), line, pos, is_friend, 1,
                helper_avatar_id, overrides, limit_break=avatar.get("limit_break") == 1, scope="assist")
        except (ValueError, TypeError, KeyError) as exc:
            raise GameplayFault("InvalidAssist", "Selected helper has invalid battle data") from exc
        return {"uid": uid, "is_friend": is_friend, "is_bot": True, "score_kind": "friend" if is_friend else "online",
                "score_gain": None, "cd_time": cd_time, "friend_avatar": avatar,
                "battle_snapshot": battle_snapshot}

    def _spend_energy(self,profile,cost):
        now=int(self.store.clock.now())
        state=energy_state(profile,self.full_config,now)
        current=state['current']
        if current<cost:
            raise GameplayFault('InsufficientEnergy','Not enough energy for this battle')
        remaining=current-cost
        write_energy_after_spend(profile,remaining,state,now)
        return remaining

    def _is_unlocked(self, cid, progress):
        try:
            cn, sn = self._chapter_id(cid); pn, ps = self._chapter_id(progress)
        except (GameplayFault, TypeError):
            return cid == "M_001_1"
        return (cn, sn) <= (pn, ps)

    def _finish(self, uid, params):
        fight_id = params.get("fight_id")
        if not isinstance(fight_id, str) or not fight_id:
            raise GameplayFault("MissingFight", "A valid fight_id is required")
        sign = params.get("sign")
        if type(sign) is not int or sign not in (1, 2):
            raise GameplayFault("InvalidResult", "Client result must be a valid winner side")
        cid = str(params.get("cid", "")); diff = int(params.get("diff", 0))
        # The fight may legitimately finish after a time-limited activity
        # window closes. Starting is gated by the schedule; settlement must
        # use the already-issued pending intent and its copied stage instead.
        self._stage(cid, diff, check_activity_window=False)
        snapshots = params.get("teams", {})
        if not isinstance(snapshots, dict):
            raise GameplayFault("InvalidResult", "Team snapshots must be an object")
        score = max(0, min(3, int(params.get("combat_star", 3 if sign == 1 else 0)))) if sign == 1 else 0
        def mutate(profile):
            first_clear = False
            encounter = None
            pending_map = profile.setdefault("pending_pve", {})
            pending = pending_map.get(fight_id)
            if not pending or pending.get("cid") != cid or int(pending.get("diff", -1)) != diff or int(pending.get("expires", 0)) < int(self.store.clock.now()):
                raise GameplayFault("UnknownFight", "Battle is expired or does not belong to this player")
            stage = pending["stage"]
            if pending.get("settled"):
                raise GameplayFault("FightAlreadySettled", "Battle has already been settled")
            validate_battle_config(self.config, pending)
            # Snapshots are bounded and validated for consistency, but never treated as server proof.
            self._validate_snapshots(snapshots, pending)
            profile.setdefault("combat_score", {"normal":{},"hard":{},"ploy":{}})
            is_activity = pending.get("kind") == "activity"
            score_key = "ploy" if is_activity else "hard" if diff else "normal"
            scores = profile["combat_score"].setdefault(score_key, {})
            chapter_key = cid.rsplit("_", 1)[0]
            if sign==1 and is_activity and stage.get('activity_kind')=='material':
                consume_material_win(profile,chapter_key,self.store.clock.now())
            try:
                stage_index = int(cid.rsplit("_", 1)[1]) - 1
            except (ValueError, IndexError):
                raise GameplayFault("UnknownStage", "Stage id has no numeric index")
            chapter_cfg = self._cfg("battle_ploy" if is_activity else "battle_main").get(chapter_key, {})
            stage_count = int(chapter_cfg.get("combat", stage_index + 1))
            score_entry = scores.get(chapter_key)
            if isinstance(score_entry, list) and len(score_entry) > 1 and isinstance(score_entry[1], list):
                stars = list(score_entry[1])
            else:
                stars = []
                # Migrate old reconstructed saves that stored scalar stars per cid.
                for index in range(stage_count):
                    legacy = scores.get(f"{chapter_key}_{index + 1}", 0)
                    stars.append(max(0, min(3, int(legacy) if type(legacy) in (int, float) else 0)))
            if len(stars) < stage_count:
                stars.extend([0] * (stage_count - len(stars)))
            previous = max(0, min(3, int(stars[stage_index]))) if 0 <= stage_index < len(stars) else 0
            if sign == 1:
                if is_activity:
                    activity_key=cid.rsplit("_",1)[0]
                    ploy_cids=profile.setdefault("ploy_cids",{}).setdefault(activity_key,[])
                    first_clear=cid not in ploy_cids
                    if first_clear: ploy_cids.append(cid)
                    next_cid=cid
                    counter_key="combat_ploy"
                else:
                    first_clear = previous == 0
                    progress_key = "hid" if diff else "cid"
                    next_cid = self._next_stage(cid)
                    profile[progress_key] = self._furthest(profile.get(progress_key, "M_001_1"), next_cid)
                    counter_key = "combat_main_hard" if diff else "combat_main"
                stars[stage_index] = max(previous, score)
                claim_mode = "-1" if is_activity else str(diff)
                previous_chapter = scores.get(chapter_key, [])
                claimed = (chapter_key in profile.get("records", {}).get("pass_battle_gift", {}).get(claim_mode, [])
                           or isinstance(previous_chapter, list) and previous_chapter and str(previous_chapter[0]) == "1")
                scores[chapter_key] = ["1" if claimed else "0", stars]
                for index in range(stage_count):
                    scores.pop(f"{chapter_key}_{index + 1}", None)
                record_bucket = profile.setdefault("records", {}).setdefault(counter_key, {})
                previous_wins = int(record_bucket.get(cid, 0))
                record_bucket[cid] = previous_wins + 1
                daily_bucket=profile['records'].setdefault('daily_stage_attempts',{}).setdefault(counter_key,{})
                daily_bucket[cid]=int(daily_bucket.get(cid,0))+1
                # Stars and win records are settlement authority. Return the
                # decision with the actual rewards so a stale client frontier
                # cannot apply a second first-clear multiplier locally.
                first_clear = first_clear and previous_wins == 0
                diff_rows = self.config.get("system_simple", {}).get("combat_diff", [[1, 1, 1, 1, 1]])
                factors = diff_rows[diff] if isinstance(diff_rows, list) and len(diff_rows) > diff else [1, 1, 1, 1, 1]
                first_rate = 2 if first_clear else 1
                gold_factor = float(factors[3]) if isinstance(factors, list) and len(factors) > 3 else 1.0
                exp_factor = float(factors[2]) if isinstance(factors, list) and len(factors) > 2 else 1.0
                amount_gold = max(0, int(int(stage.get("gold", 0)) * first_rate * gold_factor))
                exp_gain = max(0, int(int(stage.get("exp", 0)) * first_rate * exp_factor))
                authored_reward = stage.get("reward", {})
                reward = copy.deepcopy({k:v for k,v in authored_reward.items() if k in {"gold","coin","score","medal","mark","attrs","avatar_exp","items","heroes"}})
                reward["gold"] = amount_gold
                reward["exp"] = exp_gain
                if is_activity and stage.get("activity_kind") == "material" and stage.get("activity_avatar_exp"):
                    leader = next((unit.get("instance_id") for unit in pending.get("team_a", [])
                                   if isinstance(unit, dict) and unit.get("instance_id") in profile.get("avatars", {})), None)
                    if not leader:
                        raise GameplayFault("InvalidTeam", "Material hero experience has no owned battle leader")
                    reward["avatar_exp"] = {"hero_id": leader, "amount": int(stage["activity_avatar_exp"])}
                tower_soul = None
                tower_hero = None
                tower_drop = None
                if (is_activity and stage.get("activity_kind") == "tower"
                        and stage.get('tower_reward_rule',{}).get('schema') == TOWER_REWARD_SCHEMA):
                    tower_drop = roll_tower_reward(self.full_config,stage,self._reward_rng(uid,fight_id,pending,'tower-103'))
                    reward.update(tower_drop)
                elif is_activity and stage.get("activity_kind") == "tower":
                    candidates = stage.get("soul_candidates", [])
                    if mod_runtime(self.config):
                        candidates = band_candidates(self.config, candidates, "acquisition.drop.tower_soul")
                    if not isinstance(candidates, list) or not candidates or any(aid not in self.config.get("avatar", {}) for aid in candidates):
                        raise GameplayFault("InvalidStage", "Tower soul pool is invalid")
                    tower_soul = self._reward_rng(uid, fight_id, pending, "tower-soul").choice(candidates)
                    reward["avatar_soul"] = {tower_soul: int(stage.get("soul_amount", 120))}
                    if int(stage.get("tower_floor", 0)) > 100:
                        heroes = stage.get("tower_hero_candidates", [])
                        if mod_runtime(self.config):
                            heroes = candidate_ids(self.config, heroes, "acquisition.drop.tower_hero", include_new=True, quality=6)
                        if (not isinstance(heroes, list) or not heroes
                                or any(aid not in self.config.get("avatar", {})
                                       or not aid.startswith("A_1") or not aid.endswith("_6") for aid in heroes)):
                            raise GameplayFault("InvalidStage", "Tower hero pool is invalid")
                        tower_hero = self._reward_rng(uid, fight_id, pending, "tower-hero").choice(heroes)
                # The config-gated elite gear rule rolls only on successful
                # hard-mode mainline wins. It appends into
                # this same reward object before the atomic grant_reward call,
                # so inventory capacity failure rolls back the whole settlement.
                if not is_activity and diff == 1 and sign == 1:
                    elite_eid = roll_elite_drop(
                        self.full_config, cid, diff, True,
                        self._reward_rng(uid, fight_id, pending, "elite-equipment"),
                    )
                    if elite_eid is not None:
                        reward.setdefault("items", []).append({"eid": elite_eid, "num": 1})
                if not is_activity and cid.startswith("M_") and sign == 1:
                    hero_aid = roll_campaign_hero_drop(
                        self.full_config, stage, cid, diff, True,
                        self._reward_rng(uid, fight_id, pending, "campaign-hero"),
                    )
                    if hero_aid is not None:
                        reward.setdefault("heroes", []).append({"aid": hero_aid, "num": 1})
                first = copy.deepcopy(authored_reward.get("first_clear", {}))
                if isinstance(first, dict):
                    first_attrs = first.get("attrs", {})
                    if isinstance(first_attrs, dict):
                        # Talent SP tutorial rewards are unique per stage across
                        # normal and hard mode. Keep other first-clear rewards
                        # under their existing per-difficulty semantics.
                        sp_reward = first_attrs.pop("sp", None)
                        if sp_reward is not None:
                            records = profile.setdefault("records", {})
                            claimed = records.setdefault("talent_sp_first_clear", [])
                            if not isinstance(claimed, list):
                                raise GameplayFault("InvalidProfile", "Talent first-clear record is malformed")
                            if cid not in claimed:
                                reward.setdefault("attrs", {})["sp"] = sp_reward
                                claimed.append(cid)
                    if first_clear:
                        for key in ("gold","coin","score","medal","mark"): reward[key] = int(reward.get(key,0)) + int(first.get(key,0))
                        if isinstance(first_attrs, dict) and first_attrs:
                            reward.setdefault("attrs", {}).update(first_attrs)
                        for key in ("items", "heroes"):
                            if isinstance(first.get(key), list): reward.setdefault(key, []).extend(first[key])
                exclusive_eid=None
                if is_activity and cid.startswith("P_001_") and sign == 1:
                    dropped_eid = roll_ancient_trial_drop(
                        self.full_config, stage, cid, True,
                        self._reward_rng(uid, fight_id, pending, "ancient-trial-equipment"))
                    if dropped_eid is not None:
                        reward.setdefault("items", []).append({"eid": dropped_eid, "num": 1})
                    exclusive_eid=roll_ancient_exclusive_drop(self.full_config,stage,cid,True,
                        self._reward_rng(uid,fight_id,pending,'ancient-trial-exclusive'))
                before_avatars=set(profile.get("avatars",{})); before_equips=set(profile.get("my_equips",{}))
                grant_reward(profile, reward, self.full_config, allow_skin=tower_drop is not None)
                if exclusive_eid is not None:
                    exclusive_reward={'items':[{'eid':exclusive_eid,'num':1}]}
                    grant_reward(profile,exclusive_reward,self.full_config,allow_equipment_exclusive=True)
                    reward.setdefault('items',[]).extend(exclusive_reward['items'])
                if tower_hero is not None:
                    grant_reward(profile, {"heroes": [{"aid": tower_hero, "num": 1}]}, self.full_config, allow_skin=True)
                    reward.setdefault("heroes", []).append({"aid": tower_hero, "num": 1})
                if reward.get("avatar_exp"):
                    from gameplay_roster import GameplayRosterEquipment
                    roster_rules = GameplayRosterEquipment(self.store, self.full_config)
                    hero_id = reward["avatar_exp"]["hero_id"]
                    hero = profile["avatars"][hero_id]
                    hero_aid = str(hero.get("aid", hero_id)).split("|")[0]
                    total_exp = roster_rules._hero_all_exp(hero, hero_aid)
                    cap = roster_rules._hero_level_cap(hero_aid, hero)
                    hero["lv"], hero["exp"] = roster_rules._level_from_exp(total_exp, cap, hero_aid)
                if tower_soul is not None or tower_drop is not None:
                    # Only tower-issued restricted souls authorize the later
                    # exchange. A transaction replay cannot reach this block.
                    from gameplay_common import skin_acquisition_blocked_ids
                    souls = tower_drop.get('avatar_soul',{}) if tower_drop is not None else {tower_soul:int(stage.get('soul_amount',120))}
                    for aid,amount in souls.items():
                        if aid in skin_acquisition_blocked_ids(self.full_config):
                            credit = profile.setdefault("attrs", {}).setdefault("tower_skin_soul_credit", {})
                            credit[aid] = int(credit.get(aid, 0)) + amount
                    floor = int(stage["tower_floor"])
                    records = profile.setdefault("records", {})
                    tower_count=int(self._cfg('battle_ploy')['P_200']['combat'])
                    records["tower_floor"] = max(1, int(records.get("tower_floor", 1)), min(tower_count+1, floor+1))
                encounter = profile.get("pending_limit_break")
                if not isinstance(encounter, dict):
                    encounter = None
                if encounter is not None:
                    still_valid = self._limit_break_candidates(profile, encounter.get("candidate_ids", []))
                    if still_valid:
                        encounter["candidate_ids"] = still_valid
                    else:
                        profile.pop("pending_limit_break", None)
                        encounter = None
                if encounter is None:
                    ids = [unit.get("instance_id") for unit in pending.get("team_a", [])
                           if isinstance(unit, dict)]
                    candidates = self._limit_break_candidates(profile, ids)
                    if (candidates and self._reward_rng(uid, fight_id, pending, "limit-break").random() < 0.05):
                        encounter = {"fight_id": fight_id, "candidate_ids": candidates, "created": int(self.store.clock.now())}
                        profile["pending_limit_break"] = encounter
                # A mainline chapter-finale win grants one native-shaped,
                # time-limited morph chance per chapter across normal/hard.
                # Preserve a still-live chance instead of shortening its
                # window; recording the chapter prevents replay refreshes.
                # Chapter-finale rewards follow the authored chapter length;
                # newer chapters may use a different number of encounters.
                chapter_final = not is_activity and stage_index == stage_count - 1
                if chapter_final:
                    records = profile.setdefault("records", {})
                    chapter_morph = copy.deepcopy(profile.get("attrs", {}).get("morph", {}))
                    claimed = records.setdefault("morph_chance_first_clear", [])
                    if not isinstance(claimed, list):
                        claimed = list(claimed) if isinstance(claimed, (tuple, set)) else []
                        records["morph_chance_first_clear"] = claimed
                    if chapter_key not in claimed:
                        attrs = profile.setdefault("attrs", {})
                        morph = attrs.setdefault("morph", {})
                        if not isinstance(morph, dict):
                            morph = {}
                            attrs["morph"] = morph
                        chance = morph.get("chance", 0)
                        chance_time = chance.get("$date") if isinstance(chance, dict) else chance
                        try:
                            chance_time = int(chance_time or 0)
                        except (TypeError, ValueError, OverflowError):
                            chance_time = 0
                        morph_cfg = self.config.get("ploy_system_simple", {}).get("morph", {})
                        morph_params = morph_cfg.get("params", []) if isinstance(morph_cfg, dict) else []
                        try:
                            window_seconds = max(0, int(morph_params[4]) * 60)
                        except (TypeError, ValueError, IndexError, OverflowError):
                            # Keep compatibility with a partial legacy config;
                            # the configured duration is seven days.
                            window_seconds = 7 * 24 * 60 * 60
                        now = int(self.store.clock.now())
                        chance_is_live = chance_time > 0 and now - chance_time <= window_seconds
                        if not chance_is_live:
                            morph["chance"] = {"$date": now}
                        claimed.append(chapter_key)
                    # PanelGameEndAward consumes this native field and merges
                    # it into the current client attrs without replacing the
                    # other morph settings.
                    chapter_morph = copy.deepcopy(profile.get("attrs", {}).get("morph", {}))
                assist = pending.get("assist")
                if assist:
                    score_cfg = self.config.get("system_simple", {}).get("score_config", [100, 1])
                    score_index = 0 if assist.get("is_friend") else 1
                    score_gain = max(0, int(score_cfg[score_index] if isinstance(score_cfg, list) and len(score_cfg) > score_index else (100 if score_index == 0 else 1)))
                    profile["score"] = int(profile.get("score", 0)) + score_gain
                    assist["score_gain"] = score_gain
                    if not assist.get("is_bot"):
                        records = profile.setdefault("records", {})
                        key = "help_fuids" if assist.get("is_friend") else "help_suids"
                        records.setdefault(key, {})[assist["uid"]] = copy.deepcopy(assist["cd_time"])
                granted_avatars={key:value for key,value in profile.get("avatars",{}).items() if key not in before_avatars}
                granted_equips={key:value for key,value in profile.get("my_equips",{}).items() if key not in before_equips}
            else:
                granted_avatars={}; granted_equips={}
                next_cid = profile.get("hid" if diff else "cid", "M_001_1")
                amount_gold = 0; exp_gain = 0
            pending["settled"] = True
            pending["result"] = sign
            pending["finished"] = int(self.store.clock.now())
            profile["pending_pve"].pop(fight_id, None)
            if sign == 1 and not is_activity:
                self.store.adventure.record_pve_win(profile, diff)
            if sign == 1:
                cfg_scores = profile["combat_score"]
                # The existing panel calculates chapter/encounter progression from these fields.
                return_data = {"sign":1,"combat_star":score,"next_cid":next_cid,"gold":profile.get("gold",0),
                    "coin":profile.get("coin",0),"score":profile.get("score",0),"medal":profile.get("medal",0),"mark":profile.get("mark",0),
                    "combat_score":cfg_scores,"ploy_cids":profile.get("ploy_cids",{}),"exp":profile.get("exp",0),"lv":profile.get("lv",1),
                    "energy":profile.get("energy",{"$date":int(self.store.clock.now())}),"attr_energy_extra":profile.get("attrs",{}).get("energy_extra",0),
                    "attrs":profile.get("attrs",{}),"sp":profile.get("attrs",{}).get("sp",[0,0,0,0]),"records":profile.get("records",{}),"gold_reward":amount_gold,"exp_reward":exp_gain,
                    "get_avatars":granted_avatars,"get_equips":granted_equips,"culture_book":profile.get("attrs",{}).get("culture_book",0),"box_key":profile.get("attrs",{}).get("box_key",0),"dust":profile.get("attrs",{}).get("dust",[0,0,0,0]),"dn_stone":profile.get("attrs",{}).get("dn_stone",0),
                    "battle_teams":snapshots,"first_clear":first_clear}
            else:
                return_data = {"sign":2,"combat_star":0,"next_cid":profile.get("hid" if diff else "cid","M_001_1"),
                    "gold":profile.get("gold",0),"coin":profile.get("coin",0),"score":profile.get("score",0),
                    "combat_score":profile.get("combat_score",{}),"ploy_cids":profile.get("ploy_cids",{}),"exp":profile.get("exp",0),"lv":profile.get("lv",1),
                    "energy":profile.get("energy",{"$date":int(self.store.clock.now())}),"attr_energy_extra":profile.get("attrs",{}).get("energy_extra",0),
                    "attrs":profile.get("attrs",{}),"sp":profile.get("attrs",{}).get("sp",[0,0,0,0]),"records":profile.get("records",{}),"get_avatars":{},"get_equips":{},"culture_book":profile.get("attrs",{}).get("culture_book",0),"box_key":profile.get("attrs",{}).get("box_key",0),"dust":profile.get("attrs",{}).get("dust",[0,0,0,0]),"dn_stone":profile.get("attrs",{}).get("dn_stone",0),"battle_teams":snapshots,"first_clear":False}
            if pending.get("assist"):
                return_data["friend_avatar"] = copy.deepcopy(pending["assist"]["friend_avatar"])
                return_data["score"] = profile.get("score", 0)
            if sign == 1 and chapter_final:
                return_data["attr_morph"] = chapter_morph
            if sign == 1 and encounter is not None:
                return_data["limit_break_encounter"] = copy.deepcopy(encounter)
            if sign == 1 and is_activity and stage.get("activity_kind") == "tower":
                return_data["tower_soul_reward"] = copy.deepcopy(reward.get('avatar_soul',{}))
                return_data["new_avatar_soul"] = copy.deepcopy(reward.get('avatar_soul',{}))
                return_data["get_avatar_soul"] = copy.deepcopy(profile.get('avatar_soul',{}))
                return_data["avatar_soul"] = copy.deepcopy(profile.get("avatar_soul", {}))
                return_data["tower_floor"] = profile.get("records", {}).get("tower_floor", 1)
            return profile, return_data
        data, replayed = self.store.atomic_update(uid, mutate, self._operation_key("user.pve_finish", params), params)
        data["fight_id"] = fight_id; data["replayed"] = replayed
        return data

    @staticmethod
    def _limit_break_candidates(profile, ids):
        avatars = profile.get("avatars", {})
        candidates = []
        if not isinstance(ids, list) or not isinstance(avatars, dict):
            return candidates
        for iid in ids:
            if not isinstance(iid, str) or iid in candidates:
                continue
            hero = avatars.get(iid)
            if not isinstance(hero, dict):
                continue
            aid = str(hero.get("aid", iid)).split("|")[0]
            if (aid.startswith("A_1") and aid.rsplit("_", 1)[-1] in {"5", "6"}
                    and int(hero.get("lv", 1)) >= 99
                    and int(hero.get("limit_break", 0) or 0) == 0):
                candidates.append(iid)
        return candidates

    @staticmethod
    def _reward_rng(uid, fight_id, pending, domain):
        """A retry-stable random stream scoped to a server-issued battle intent.

        New intents persist an unexposed random seed. For already-pending legacy
        intents that predate this field, derive a deterministic compatibility
        seed so a failed transaction still cannot reroll on retry.
        """
        stored = pending.get("reward_seed")
        if not isinstance(stored, str) or not stored:
            stored = f"legacy:{uid}:{fight_id}:{pending.get('cid', '')}:{pending.get('diff', '')}"
        material = f"{stored}:{domain}".encode("utf-8")
        seed = int.from_bytes(hashlib.sha256(material).digest(), "big")
        return random.Random(seed)

    @staticmethod
    def _validate_snapshots(snapshots, pending):
        for name, expected in (("team_a", pending["team_a"]), ("team_b", pending["team_b"])):
            values = snapshots.get(name, [])
            if not isinstance(values, list) or len(values) > 30:
                raise GameplayFault("InvalidResult", "Invalid result team snapshot")
            for unit in values:
                if not isinstance(unit, dict) or not isinstance(unit.get("aid"), str):
                    raise GameplayFault("InvalidResult", "Invalid combatant snapshot")
                hp = unit.get("hp"); maximum = unit.get("hp_max")
                # Avatar.injured subtracts the full lethal hit and does not clamp
                # its stored hp; native toDataObj() can therefore report a
                # negative post-mortem value. Snapshots are diagnostics only.
                if (type(hp) not in (int, float) or type(maximum) not in (int, float)
                        or not math.isfinite(hp) or not math.isfinite(maximum)
                        or abs(hp) > 1_000_000_000 or maximum <= 0 or maximum > 1_000_000_000
                        or hp > maximum):
                    raise GameplayFault("InvalidResult", "Invalid combatant health")

    def _next_stage(self, cid):
        chapters=self._cfg("battle_main"); n, s=self._chapter_id(cid); current=chapters.get(f"M_{n:03d}",{}).get("combat",0)
        if s < int(current): return f"M_{n:03d}_{s+1}"
        next_chapter=n+1
        # Return the next chapter pointer even after the final authored chapter.
        # PanelGameEndAward uses next_cid != current cid to identify a first clear;
        # returning cid at M_010_6 made the terminal stage's displayed first-clear
        # multiplier disagree with the already-correct one-time server reward.
        return f"M_{next_chapter:03d}_1"

    def _furthest(self, first, second):
        try: return second if self._chapter_id(second) > self._chapter_id(first) else first
        except Exception: return second

    def _dispatch_mode(self, uid, method, params):
        if method == "user.expedition":
            return self._dispatch_expedition(uid, params)
        if method.startswith("user.exploration_"):
            return self._dispatch_exploration(uid, method, params)
        raise GameplayFault("NotImplemented", "Single-player mode RPC is not reconstructed yet: " + method)

    def _dispatch_expedition(self, uid, params):
        aids = params.get("aids", [])
        if not isinstance(aids, list) or not aids or len(aids) > 5 or len(set(aids)) != len(aids):
            raise GameplayFault("InvalidTeam", "Choose one to five unique heroes")
        def mutate(profile):
            roster = profile.setdefault("avatars", {})
            if any(not isinstance(a, str) or a not in roster for a in aids):
                raise GameplayFault("InvalidTeam", "Expedition heroes must be owned")
            from gameplay_roster import GameplayRosterEquipment
            roster_rules=GameplayRosterEquipment(self.store,self.full_config)
            for aid in aids:
                roster_rules._hero(profile, aid)
                roster_rules._check_not_dn(profile,aid)
                # Keep the native, localized error used for heroes in an
                # unfinished mainline battle while sharing the exact live,
                # expiry-aware predicate with every roster consumption path.
                if roster_rules._hero_is_in_active_pve(profile, aid):
                    raise GameplayFault("HeroInBattle", "A hero in an unfinished battle cannot be sacrificed")
                # ItemActivityExpeditionSelect inherits ItemAvatarSell. Its
                # native lock check blocks any hero still assigned to a saved
                # team, defense squad, exploration army, or active battle.
                # Enforce the same rule server-side so forged/stale selection
                # requests cannot leave dangling references after consumption.
                roster_rules._check_not_team(profile,aid)
            talent = profile.get("attrs", {}).get("avatar_talent")
            if isinstance(talent, str) and talent.split("`", 1)[0] in aids:
                raise GameplayFault("InvalidTeam", "The active talent hero cannot be sacrificed")
            gained = sum(expedition_stones(roster[aid]) for aid in aids)
            for aid in aids:
                roster.pop(aid)
            attrs = profile.setdefault("attrs", {})
            expedition = attrs.setdefault("expedition", {})
            attrs["dn_stone"] = int(attrs.get("dn_stone", 0)) + gained
            day = game_day(self.store.clock.now())
            expedition.update({"day": day, "sent": list(aids), "reward_claimed": True})
            result = {"dn_stone": attrs["dn_stone"], "gained_dn_stone": gained, "get_avatars": {}, "attrs": copy.deepcopy(attrs),
                "gold": profile.get("gold",0), "coin": profile.get("coin",0),
                "avatar_len": attrs.get("avatar_len",100), "attr_expedition": copy.deepcopy(expedition),
                "team": copy.deepcopy(profile.get("team", [])),
                "as_equips": copy.deepcopy(profile.get("as_equips", []))}
            return profile, result
        data, _ = self.store.atomic_update(uid, mutate, self._operation_key("user.expedition", params), params)
        return data

    def _exploration_defaults(self, profile):
        state = profile.setdefault("exploration", {})
        state.setdefault("stage", 1)
        state.setdefault("stage_mode", ["ap", "all", 1.05, 1])
        state.setdefault("current_stage_finish", 0); state.setdefault("army", {})
        state.setdefault("combat_army", [])
        times = profile.setdefault("records", {}).setdefault("exploration_times", {})
        today = game_day(self.store.clock.now())
        if times.get("day") != today:
            times.update({"day": today, "refresh_count": 3, "refresh_buy": 0, "relive_buy": 0, "mode_buy": 0, "vip_relive": 1})
        else:
            for key, value in (("refresh_count", 3), ("refresh_buy", 0), ("relive_buy", 0), ("mode_buy", 0), ("vip_relive", 1)):
                times.setdefault(key, value)
        if state.get("attribute_schema") != "hero-only-v1":
            # Older maps recorded geared maxima and a geared difficulty
            # anchor. Keep each surviving hero's HP percentage while moving
            # both snapshots to exploration's native bare-Avatar rules.
            from gameplay_roster import GameplayRosterEquipment
            attributes = GameplayRosterEquipment(self.store, self.full_config).battle_attributes
            ledger = state.setdefault("health_ledger", {})
            for iid, hero in state.get("army", {}).items():
                if not isinstance(hero, dict) or iid not in profile.get("avatars", {}):
                    continue
                if mod_runtime(self.config) and not hero_available(self.config, profile["avatars"][iid].get("aid", iid)):
                    continue
                old = hero if hero.get("max_hp") else ledger.get(iid, {})
                old_max = max(1, int(old.get("max_hp", 1)))
                old_hp = max(0, min(old_max, int(old.get("current_hp", old_max))))
                new_max = max(1, int(attributes(profile, iid, hero_only=True)["hp_max"]))
                hero["max_hp"] = new_max
                hero["current_hp"] = max(0, min(new_max, int(new_max * old_hp / old_max)))
                ledger[iid] = {"current_hp": hero["current_hp"], "max_hp": new_max}
            if isinstance(state.get("difficulty"), dict) and state["difficulty"].get("stat_schema") != "hero-only-v1":
                state.pop("difficulty", None)
            state["attribute_schema"] = "hero-only-v1"
        army = state.get("army", {})
        if isinstance(army, dict):
            for hero in army.values():
                if isinstance(hero, dict):
                    hero["exploration_hero_only"] = True
        return state, times

    def _exploration_response(self, profile):
        state, times = self._exploration_defaults(profile)
        return {"stage": state["stage"], "stage_mode": state["stage_mode"],
                "current_stage_finish": state["current_stage_finish"], "army": copy.deepcopy(state["army"]),
                "combat_army": copy.deepcopy(state["combat_army"]), "refresh_count": times["refresh_count"],
                "refresh_buy": times["refresh_buy"], "relive_buy": times["relive_buy"],
                "mode_buy": times["mode_buy"], "vip_relive": times["vip_relive"]}

    def _exploration_enemy_team(self, stage_cfg):
        enemy = serialize_stage_team(self.config, stage_cfg.get("team2", []), team=2)
        stat_rows = stage_cfg.get("enemy_unit_stats_by_diff", {})
        if isinstance(stat_rows, dict) and "0" in stat_rows:
            overrides = stat_rows["0"]
            if not isinstance(overrides, list) or len(overrides) != len(enemy):
                raise GameplayFault("InvalidStage", "Exploration enemy snapshot has the wrong team2 length")
            for index, override in enumerate(overrides):
                if override is None:
                    continue
                unit = enemy[index]
                if (not isinstance(override, dict) or override.get("index") != index
                        or override.get("aid") != base_aid(self.config, unit.get("aid"))):
                    raise GameplayFault("InvalidStage", "Exploration enemy snapshot does not match team2 order")
                try:
                    hp = max(0, int(override["hp"]))
                    for key in ("ap", "de_ph", "de_ma"):
                        unit[key] = max(0, int(override[key]))
                    affixes = {key: max(0, int(override[key]))
                               for key in ("hit", "flee", "crit", "tough")}
                except (KeyError, TypeError, ValueError, OverflowError) as exc:
                    raise GameplayFault("InvalidStage", "Exploration enemy snapshot has invalid stats") from exc
                unit["hp"] = hp
                unit["hp_max"] = hp
                unit["new_4attrs"] = affixes
        # Exploration uses a single-lane GameMapData. Normalize
        # generated opponents to that lane before serializing native
        # Avatar.toDataObj snapshots.
        for unit in enemy:
            unit["line"] = 0
        return enemy

    def _dispatch_exploration(self, uid, method, params):
        stages = exploration_stages(self.full_config)
        def mutate(profile):
            state, times = self._exploration_defaults(profile)
            raw_stage = max(1, int(state["stage"]))
            if raw_stage > len(stages) and method in {"user.exploration_opponent", "user.exploration_combat", "user.exploration_get_reward"}:
                raise GameplayFault("ExplorationComplete", "All configured exploration stages are complete")
            stage_no = max(1, min(raw_stage, len(stages) or 1))
            stage_cfg = stages[stage_no - 1] if stages else {}
            stage_cfg = exploration_encounter(self.full_config, profile, state, stage_no, stage_cfg)
            if method in {"user.exploration_make_army", "user.exploration_buy_mode", "user.exploration_relive"}:
                now = int(self.store.clock.now())
                active = profile.get("pending_battles", {}).get("exploration", {})
                if any(isinstance(battle, dict) and (int(battle.get("expires", 0)) > now
                       or retain_frozen_intent(self.config, battle)) for battle in active.values()):
                    raise GameplayFault("ExplorationBattlePending", "请先完成当前探险战斗，再更换名单、复活或刷新加成")
            if method == "user.exploration_start":
                for intent in profile.get("pending_battles", {}).get("exploration", {}).values():
                    if retain_frozen_intent(self.config, intent):
                        validate_battle_config(self.config, intent)
                # The original client does not serialize/reopen an in-progress
                # GameMap fight after an app restart. Entering exploration
                # again abandons an unreported battle instead of leaving a stale
                # intent that could settle after a later encounter.
                profile.setdefault("pending_battles", {}).pop("exploration", None)
                if raw_stage > len(stages) and int(state.get("current_stage_finish", 0)) == 0 and stages:
                    # A completed map stores map_max+1 as a sentinel. Starting
                    # a new outing must create a fresh map before hero choice;
                    # the native map paints every chest as opened otherwise.
                    state["stage"] = 1
                    state["map_revision"] = int(state.get("map_revision", 0)) + 1
                    state.pop("difficulty", None)
                    state["health_ledger"] = {}
                    state["combat_army"] = []
                return profile, self._exploration_response(profile)
            if method == "user.exploration_make_army":
                aids = params.get("aids", [])
                roster = profile.get("avatars", {})
                explore_cfg = self.config.get("system_simple", {}).get("explore", {})
                army_max = min(15, max(1, int(explore_cfg.get("army_max", 15))))
                if (not isinstance(aids, list) or not 1 <= len(aids) <= army_max
                        or any(not isinstance(a, str) or not a for a in aids)
                        or len(set(aids)) != len(aids) or any(a not in roster for a in aids)):
                    raise GameplayFault("InvalidTeam", f"Select one to {army_max} unique owned heroes")
                from gameplay_roster import GameplayRosterEquipment
                attributes = GameplayRosterEquipment(self.store, self.full_config).battle_attributes
                previous_army = state.get("army", {}) if isinstance(state.get("army"), dict) else {}
                health_ledger = state.setdefault("health_ledger", {})
                selected = {}
                for aid in aids:
                    hero = copy.deepcopy(roster[aid])
                    hero["exploration_hero_only"] = True
                    maximum = max(1, int(attributes(profile, aid, hero_only=True).get("hp_max", 1)))
                    prior = previous_army.get(aid, health_ledger.get(aid, {}))
                    prior_max = max(1, int(prior.get("max_hp", maximum))) if isinstance(prior, dict) else maximum
                    current = int(prior.get("current_hp", prior_max)) if isinstance(prior, dict) else maximum
                    hero["current_hp"] = max(0, min(maximum, int(maximum * current / prior_max)))
                    hero["max_hp"] = maximum
                    selected[aid] = hero
                    health_ledger[aid] = {"current_hp": hero["current_hp"], "max_hp": maximum}
                state["army"] = selected
                if not state.get("difficulty"):
                    state["difficulty"] = exploration_difficulty(profile, aids, self.full_config)
                return profile, self._exploration_response(profile)
            if method == "user.exploration_opponent":
                enemy = self._exploration_enemy_team(stage_cfg)
                # AvatarImg's legacy NPC preview expects HP at offsets 6/7,
                # not the cultivation/phase columns in authored combat tuples.
                line_pos = max(1, int(self.config.get("system_simple", {}).get("battle", [0, 3000])[1]))
                army = [[u["aid"], u["lv"], u["slv"], u["line"], u["pos"] / line_pos,
                         u["leader"], u["hp"], u["hp_max"]] for u in enemy]
                return profile, {"name": "迷雾守军", "power": _native_team_power(self.full_config, enemy),
                    "army": army, "units": copy.deepcopy(enemy), "is_npc": True, "stage": stage_no}
            if method == "user.exploration_combat":
                if int(state.get("current_stage_finish", 0)) == 1:
                    raise GameplayFault("ExplorationRewardPending", "Claim the completed stage before fighting again")
                pending = profile.setdefault("pending_battles", {}).setdefault("exploration", {})
                now = int(self.store.clock.now())
                pending = {key: value for key, value in pending.items()
                           if isinstance(value, dict) and (int(value.get("expires", 0)) > now
                           or retain_frozen_intent(self.config, value))}
                if pending:
                    profile["pending_battles"]["exploration"] = pending
                    raise GameplayFault("ExplorationBattlePending", "Return to the exploration map before starting another battle")
                army = state.get("army", {})
                submitted = params.get("team", [])
                if not isinstance(submitted, list) or len(submitted) > 6:
                    raise GameplayFault("InvalidTeam", "请选择一至三名探险英雄")
                rows = [row for row in submitted if row not in (None, "")]
                if (not 1 <= len(rows) <= 3 or any(not isinstance(row, (list, tuple)) or len(row) != 3
                        or not isinstance(row[0], str) or row[0] not in army for row in rows)):
                    raise GameplayFault("InvalidTeam", "出战英雄必须来自当前探险名单")
                ids = [row[0] for row in rows]
                if len(set(ids)) != len(ids):
                    raise GameplayFault("InvalidTeam", "探险出战英雄不能重复")
                if any(type(row[1]) not in (int, float) or not math.isfinite(row[1])
                       or type(row[2]) not in (int, float) or not math.isfinite(row[2])
                       or not 0 <= row[2] <= 1 for row in rows):
                    raise GameplayFault("InvalidFormation", "探险阵型坐标无效")
                from gameplay_roster import GameplayRosterEquipment
                attributes = GameplayRosterEquipment(self.store, self.full_config).battle_attributes
                own = []
                for i, iid in enumerate(ids):
                    hero = profile.get("avatars", {}).get(iid)
                    if not hero: raise GameplayFault("InvalidTeam", "Exploration hero is no longer owned")
                    raw = attributes(profile, iid, hero_only=True)
                    exploration_hero = army.get(iid, {})
                    maximum = max(1, int(raw.get("hp_max", 1)))
                    old_maximum = max(1, int(exploration_hero.get("max_hp", maximum)))
                    old_hp = max(0, min(old_maximum, int(exploration_hero.get("current_hp", old_maximum))))
                    current_hp = maximum * old_hp // old_maximum
                    exploration_hero.update(max_hp=maximum, current_hp=current_hp)
                    state.setdefault("health_ledger", {})[iid] = {"current_hp": current_hp, "max_hp": maximum}
                    if current_hp <= 0:
                        raise GameplayFault("ExplorationHeroDefeated", "Revive defeated exploration heroes before using them")
                    row = next((r for r in submitted if isinstance(r, (list, tuple)) and r and r[0] == iid), [])
                    # Exploration's native GameMapData is one lane wide. The
                    # roster formation positions are visual selectors and can
                    # retain stale multi-lane indices from another mode.
                    _, pos = (int(row[1]), float(row[2])) if len(row) >= 3 else (0, .2 + .24 * i)
                    line = 0
                    overrides = {k: raw.get(k) for k in ("hp", "hp_max", "ap", "de_ph", "de_ma", "tpl", "talent", "morph", "phase", "culture_schema", "skill", "leader_skill", "book_skill", "skillB", "growth_stats_applied", "bonds_104", "equipment_bonds_104")}
                    # Native exploration marks every selected hero as captain.
                    overrides["leader_skill"] = raw.get("leader_skill")
                    overrides["hp"] = current_hp
                    overrides["new_4attrs"] = {k: raw.get(k, 0) for k in ("hit", "flee", "crit", "tough")}
                    own.append(base_unit(self.config, hero.get("aid", iid).split("|")[0], hero.get("lv", 1), hero.get("slv", 1), max(0,min(2,line)), max(0,min(1,pos)), True, 1, iid, overrides,
                                         limit_break=hero.get("limit_break") == 1))
                mode = state.get("stage_mode", [])
                if isinstance(mode, list) and len(mode) == 4:
                    stat, _, amount, percentage = mode
                    for unit in own:
                        if stat in ("hp", "ap", "de_ph", "de_ma") and percentage == 1:
                            if stat == "hp":
                                unit["hp_max"] = max(1, int(unit["hp_max"] * amount))
                                unit["hp"] = max(1, int(unit["hp"] * amount))
                            else:
                                unit[stat] = max(1, int(unit[stat] * amount))
                        elif stat in ("hit", "flee", "crit", "tough") and percentage == 0:
                            unit["new_4attrs"][stat] += int(amount)
                enemy = self._exploration_enemy_team(stage_cfg)
                lane_count = 1  # GameMapManager.getExplorationData constructs [1, [background]].
                try:
                    validate_team_lane_coverage(own, lane_count, "exploration player formation")
                    validate_team_lane_coverage(enemy, lane_count, "exploration enemy formation")
                except ValueError as exc:
                    raise GameplayFault("InvalidFormation", "Every exploration route needs at least one hero or enemy") from exc
                # DoorLayer requires both powers from the final combat snapshots.
                my_pr_power = _native_team_power(self.full_config, own)
                pr_power = _native_team_power(self.full_config, enemy)
                metadata = {"stage": stage_no}
                intent = create_intent(profile, "exploration", metadata, own, enemy, now=self.store.clock.now(), config=self.config)
                if effective_digest(self.config):
                    profile["pending_battles"]["exploration"][intent["fight_id"]]["reward_snapshot"] = copy.deepcopy(stage_cfg.get("reward", {}))
                state["combat_army"] = ids
                return profile, {**self._exploration_response(profile), **intent, "fight_kind": "exploration",
                    "metadata": metadata, "seed": intent["seed"], "poke_data": {}, "cid": f"E_{stage_no:03d}_1",
                    "diff": 0, "line": [lane_count, (stage_cfg.get("line", [1,["m002"]])[1] or ["m002"])[:1]],
                    # In exploration $isPVE is false, so GameMap.reSend enters
                    # initByOrgin and requires both arrays. Without them the
                    # curtain opens, but native setup returns before creating
                    # units or starting the turn loop.
                    "orgin_team_a": copy.deepcopy(own), "orgin_team_b": copy.deepcopy(enemy),
                    "team1": submitted, "team2": stage_cfg.get("team2", []), "win": [-1],
                    "my_pr_power": my_pr_power, "pr_power": pr_power, "def_th": 1}
            if method == "user.exploration_get_reward":
                if int(state.get("current_stage_finish", 0)) != 1:
                    raise GameplayFault("NoExplorationReward", "Complete the current stage first")
                frozen = state.get("mod_pending_reward")
                if isinstance(frozen, dict):
                    validate_battle_config(self.config, frozen)
                    if int(frozen.get("stage", -1)) != stage_no:
                        raise GameplayFault("InvalidBattle", "探索奖励与已完成关卡不匹配，原记录已保留")
                    reward = copy.deepcopy(frozen.get("reward", {}))
                else:
                    reward = copy.deepcopy(stage_cfg.get("reward", {}))
                reward.pop("first_clear", None)
                grant_reward(profile, reward, self.full_config)
                # Advance to map_max + 1 as a completion sentinel; clamping
                # kept the final encounter selectable and repeatable forever.
                state["stage"] = stage_no + 1
                state["current_stage_finish"] = 0; state["combat_army"] = []
                state.pop("mod_pending_reward", None)
                if stage_no >= len(stages):
                    # The completion sentinel has no more combat/reward path.
                    # Release the old lineup so these heroes can be used for
                    # roster growth; the response carries the empty army too.
                    state["army"] = {}
                gifts = [{key: value} for key, value in reward.items() if key not in {"attrs", "heroes", "items"}]
                gifts.extend({row["aid"]: row.get("num", 1)} for row in reward.get("heroes", []))
                gifts.extend({row["eid"]: row.get("num", 1)} for row in reward.get("items", []))
                if isinstance(reward.get("attrs"), dict):
                    gifts.extend({key: value} for key, value in reward["attrs"].items())
                return profile, {**self._exploration_response(profile), "gifts": gifts,
                    "gold": profile.get("gold",0), "coin": profile.get("coin",0),
                    "score": profile.get("score",0), "medal": profile.get("medal",0), "mark": profile.get("mark",0),
                    "exp": profile.get("exp",0), "lv": profile.get("lv",1), "attrs": profile.get("attrs",{})}
            if method == "user.exploration_refresh":
                for intent in profile.get("pending_battles", {}).get("exploration", {}).values():
                    if retain_frozen_intent(self.config, intent):
                        validate_battle_config(self.config, intent)
                # A completed encounter is an unclaimed asset. Refuse before
                # charging or changing any state so refresh cannot erase it.
                if int(state.get("current_stage_finish", 0)) == 1:
                    raise GameplayFault("ExplorationRewardPending", "Claim the completed stage before refreshing the map")
                if int(times.get("refresh_count", 0)) > 0:
                    times["refresh_count"] -= 1
                else:
                    explore_cfg = self.config.get("system_simple", {}).get("explore", {})
                    max_paid = max(0, int(explore_cfg.get("refresh_num", 3)))
                    if int(times.get("refresh_buy", 0)) >= max_paid:
                        raise GameplayFault("NoRefreshes", "No exploration refreshes remain today")
                    cost = max(0, int(explore_cfg.get("refresh_price", 10)))
                    if int(profile.get("coin", 0)) < cost:
                        raise GameplayFault("InsufficientCoin", "Not enough coins for exploration refresh")
                    profile["coin"] = int(profile.get("coin", 0)) - cost
                    times["refresh_buy"] = int(times.get("refresh_buy", 0)) + 1
                state["stage"] = 1
                state["map_revision"] = int(state.get("map_revision", 0)) + 1
                state.pop("difficulty", None)
                state["health_ledger"] = {}
                state["current_stage_finish"] = 0; state["combat_army"] = []
                # A confirmed map reset abandons only an in-flight battle
                # intent. It keeps the selected exploration roster and its
                # current health, then restores those heroes below.
                pending = profile.get("pending_battles")
                if isinstance(pending, dict):
                    pending.pop("exploration", None)
                for hero in state.get("army", {}).values():
                    if isinstance(hero, dict) and hero.get("max_hp"):
                        hero["current_hp"] = hero["max_hp"]
                if state.get("army"):
                    state["difficulty"] = exploration_difficulty(profile, list(state["army"]), self.full_config)
                return profile, {**self._exploration_response(profile), "coin": profile.get("coin",0), "gold": profile.get("gold",0), "attrs": profile.get("attrs",{})}
            if method == "user.exploration_relive":
                aid = str(params.get("aid", "")); hero = state.get("army", {}).get(aid)
                if not isinstance(hero, dict) or int(hero.get("current_hp", 1)) > 0:
                    raise GameplayFault("NoFallenHero", "Only a defeated exploration hero can be revived")
                if int(profile.get("vip_lv", 0)) < int(self.config.get("system_simple", {}).get("explore", {}).get("relive_vip", 0)):
                    raise GameplayFault("VipRequired", "This account cannot revive exploration heroes")
                if int(times.get("vip_relive", 0)) <= 0:
                    raise GameplayFault("NoRevives", "No exploration revives remain today")
                relive = self.config.get("system_simple", {}).get("explore", {}).get("relive", [5, 5])
                cost = max(0, int(relive[0]) * int(times.get("relive_buy", 0)) + int(relive[1])) if isinstance(relive, list) and len(relive) > 1 else 5
                if int(profile.get("coin", 0)) < cost:
                    raise GameplayFault("InsufficientCoin", "Not enough coins to revive this hero")
                profile["coin"] = int(profile.get("coin", 0)) - cost
                times["relive_buy"] = int(times.get("relive_buy", 0)) + 1
                times["vip_relive"] = int(times.get("vip_relive", 0)) - 1
                hero["current_hp"] = max(1, int(hero.get("max_hp", 1)))
                state.setdefault("health_ledger", {})[aid] = {"current_hp": hero["current_hp"], "max_hp": hero["max_hp"]}
                return profile, {**self._exploration_response(profile), "aid": aid, "info": copy.deepcopy(hero), "coin": profile.get("coin",0), "vip_relive": times["vip_relive"], "relive_buy": times["relive_buy"], "attrs": profile.get("attrs",{})}
            if method == "user.exploration_buy_mode":
                explore_cfg = self.config.get("system_simple", {}).get("explore", {})
                free_times = max(0, int(explore_cfg.get("free_times", 1)))
                price = explore_cfg.get("refresh_mode_price", [10, 5])
                cost = 0 if int(times.get("mode_buy", 0)) < free_times else max(0, int(price[0]) * int(times.get("mode_buy", 0)) + int(price[1]))
                if int(profile.get("coin", 0)) < cost:
                    raise GameplayFault("InsufficientCoin", "Not enough coins to change exploration mode")
                profile["coin"] = int(profile.get("coin", 0)) - cost
                modes = [["ap", "all", 1.05, 1], ["hp", "all", 1.05, 1], ["de_ph", "all", 1.05, 1], ["de_ma", "all", 1.05, 1], ["hit", "all", 5, 0], ["flee", "all", 5, 0], ["crit", "all", 5, 0], ["tough", "all", 5, 0]]
                state["stage_mode"] = copy.deepcopy(modes[(int(times.get("mode_buy", 0)) + 1) % len(modes)])
                times["mode_buy"] = int(times.get("mode_buy", 0)) + 1
                return profile, {**self._exploration_response(profile), "coin": profile.get("coin",0), "attrs": profile.get("attrs",{})}
            raise GameplayFault("NotImplemented", "Unsupported exploration request")
        data, _ = self.store.atomic_update(uid, mutate, self._operation_key(method, params), params)
        return data

    def _finish_exploration(self, uid, params):
        def mutate(profile):
            intent = consume_intent(profile, "exploration", params, metadata_keys=("stage",), now=self.store.clock.now(), config=self.config)
            state, _ = self._exploration_defaults(profile)
            if int(intent.get("metadata", {}).get("stage", -1)) != int(state.get("stage", 1)):
                raise GameplayFault("InvalidBattle", "Exploration stage changed during battle")
            sign = intent["sign"]
            if sign == 1:
                state["current_stage_finish"] = 1
                if intent.get("mod_digest"):
                    state["mod_pending_reward"] = {"stage": state["stage"],
                        "reward": copy.deepcopy(intent.get("reward_snapshot", {})),
                        "mod_digest": intent["mod_digest"], "team_a": copy.deepcopy(intent["team_a"]),
                        "team_b": copy.deepcopy(intent["team_b"])}
            else:
                state["current_stage_finish"] = 0
                state.pop("mod_pending_reward", None)
            snapshot = intent.get("snapshots", {}).get("team_a", [])
            by_instance = {}
            for row in snapshot:
                iid = row.get("instance_id") or (row.get("aid") if row.get("aid") in state.get("army", {}) else None)
                if iid:
                    if iid in by_instance:
                        raise GameplayFault("InvalidResult", "探险结算包含重复的英雄记录")
                    by_instance[iid] = row
            for index, original in enumerate(intent.get("team_a", [])):
                iid = original.get("instance_id")
                if not iid:
                    raise GameplayFault("InvalidBattle", "探险战斗缺少英雄编号，请重新进入地图")
                hero = state.get("army", {}).get(iid)
                final = by_instance.get(iid)
                # Older native clients only sent base aid, in original order.
                if final is None and index < len(snapshot) and not snapshot[index].get("instance_id") and snapshot[index].get("aid") == original.get("aid"):
                    final = snapshot[index]
                if final is None:
                    raise GameplayFault("InvalidResult", "探险结算缺少英雄生命记录，请重试结算")
                if isinstance(hero, dict):
                    hero["current_hp"] = max(0, int(final.get("hp", 0)))
                    hero["max_hp"] = max(1, int(final.get("hp_max", hero.get("max_hp", 1))))
                    # Store the unmodified health scale used by roster selection.
                    base_maximum = int(state.get("health_ledger", {}).get(iid, {}).get("max_hp", hero["max_hp"]))
                    fraction = hero["current_hp"] / max(1, hero["max_hp"])
                    hero["max_hp"] = base_maximum
                    hero["current_hp"] = int(base_maximum * fraction)
                    state.setdefault("health_ledger", {})[iid] = {"current_hp": hero["current_hp"], "max_hp": base_maximum}
            return profile, {"sign": sign, "combat_star": max(0,min(3,int(params.get("combat_star", 3)))) if sign == 1 else 0,
                "fight_id": intent["fight_id"], "fight_kind": "exploration", "metadata": intent["metadata"],
                **self._exploration_response(profile), "attrs": profile.get("attrs",{})}
        data, replayed = self.store.atomic_update(uid, mutate, self._operation_key("user.battle_finish", params), params)
        data["replayed"] = replayed
        return data

