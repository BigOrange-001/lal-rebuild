"""Persistent friend and local-assist flows backed exclusively by reconstruction bots."""
from __future__ import annotations
import copy, hashlib, json, random, time
from collections import OrderedDict
from pathlib import Path
from game_calendar import game_day_number
from bot_names import bot_name_for_uid
from player_store import GameplayFault, native_dates
from gameplay_roster import GameplayRosterEquipment
from guild_companions import GuildCompanions
from mod_policy import (runtime as mod_runtime, candidate_ids, channel_enabled,
                        ensure_channel, hero_available, base_aid)

BOT_UID_START = 92000000
FRIEND_ROSTER_SCHEMA = "friend-npc-cultivation-v1"
# Friend NPCs send requests on their own: one chance per window, a few
# pending at most, and a dismissed NPC waits a day before asking again.
REQUEST_WINDOW_SECONDS = 4 * 3600
REQUEST_CHANCE = .6
MAX_PENDING_REQUESTS = 3
IGNORE_COOLDOWN_WINDOWS = 6
# Built NPC profiles are deterministic for one recipe; keep a small cache so
# preview, assist and friend cards do not rebuild them on every request.
_BUILT = OrderedDict()
_BUILT_LIMIT = 256
# Unsaved rosters (read-only lookups before the first social request of the
# day) are cached per player and day so they are computed once.
_ROSTERS = {}

class GameplaySocial:
    METHODS = {"user.get", "user.get_friends", "user.apply_friend", "user.add_friend",
               "user.del_friend", "user.unapply_friend", "user.online_user",
               "user.get_radio", "user.send_bugle_radio"}

    def __init__(self, store, full_config):
        self.store = store
        self.config = full_config if isinstance(full_config, dict) else {}
        self.cfg = self.config.get("cfg", self.config)
        root = Path(__file__).resolve().parents[1] / "config" / "reconstruction"
        comp = json.loads((root / "competition-config.json").read_text(encoding="utf-8"))
        roster_path = root / "roster-config.json"
        roster = json.loads(roster_path.read_text(encoding="utf-8")) if roster_path.exists() else {}
        self.avatars = self.cfg.get("avatar") or roster.get("heroes", {})
        self.simple = self.cfg.get("system_simple", {})
        self.roster = GameplayRosterEquipment(store, self.config)
        self.companions = GuildCompanions(store, self.config)
        candidates = list(comp.get("fragment_bots", [])) + list(comp.get("pvp_bots", []))
        self.bots = [self._make_bot(row, index) for index, row in enumerate(candidates[:12])]
        if mod_runtime(self.config):
            self.bots = [bot for bot in self.bots if bot.get("avatars")]
        # Added heroes receive dedicated helpers instead of replacing the
        # captains of half the original roster. One hero must not become six
        # high-power copies that fill the client's sorted first screen.
        self.mod_bots = []
        for offset, aid in enumerate(candidate_ids(self.config, [], "appearance.assist_bot", include_new=True)):
            source = candidates[offset % len(candidates)] if candidates else {"lv": 1}
            row = {**source, "team": [[aid, int(source.get("lv", 1)), 1]]}
            self.mod_bots.append(self._make_bot(row, 1000 + offset))
        self.by_uid = {bot["uid"]: bot for bot in self.bots + self.mod_bots}
        self.capacity = int(self.simple.get("friend_len", [0, 0, 30])[2]) if isinstance(self.simple.get("friend_len"), list) and len(self.simple["friend_len"]) > 2 else 30

    @staticmethod
    def _fail(code, message):
        raise GameplayFault(code, message)

    def _make_bot(self, source, index):
        uid = str(BOT_UID_START + index + 1)
        name = bot_name_for_uid(uid)
        level = max(1, int(source.get("lv", 1)))
        raw_team = source.get("team", [])
        if mod_runtime(self.config):
            raw_team = [list(copy.deepcopy(row)) for row in raw_team if isinstance(row, (list, tuple)) and row
                        and channel_enabled(self.config, row[0], "appearance.assist_bot")]
        units = []
        for slot, row in enumerate(raw_team[:6]):
            if not isinstance(row, (list, tuple)) or not row:
                continue
            aid = str(row[0]).split("|")[0]
            # Avatar instance hp/ap/de_ph/de_ma are cultivation point inputs,
            # not the derived combat stats. `battle_attributes` applies the
            # hero's level growth and then multiplies these point inputs by
            # culture_pith. Precomputing level-grown stats here would therefore
            # add them a second time as cultivation, inflating helper power.
            units.append({"id": f"{aid}|{index*6+slot}", "aid": f"{aid}|{index*6+slot}",
                          "tpl": aid, "lv": level, "slv": max(1, int(row[2]) if len(row)>2 and isinstance(row[2],(int,float)) else 1),
                          "hp": 0, "ap": 0, "de_ph": 0, "de_ma": 0,
                          "phase": int(row[3]) if len(row)>3 and isinstance(row[3],(int,float)) else 0,
                          "line": int(row[4]) if len(row)>4 and isinstance(row[4],(int,float)) else 0,
                          "pos": float(row[4]) if len(row)>4 and isinstance(row[4],(int,float)) else 0,
                          "morph": 0, "equips": []})
        if not units:
            fallback = list(self.avatars)
            if mod_runtime(self.config):
                fallback = candidate_ids(self.config, fallback, "appearance.assist_bot")
                fallback = [aid for aid in fallback if not self.avatars[aid].get("mod_variant")]
            for slot, aid in enumerate(fallback[:5]):
                units.append({"id":f"{aid}|{index*6+slot}","aid":f"{aid}|{index*6+slot}","tpl":aid,
                              "lv":level,"slv":1,"hp":0,"ap":0,
                              "de_ph":0,"de_ma":0,"phase":0,"morph":0,"equips":[]})
        team_ids = [u["id"] for u in units] + [None] * max(0, 6-len(units))
        return {"uid":uid,"name":name,"lv":level,"vip_lv":int(source.get("vip_lv",0)),
                "login_time":{"$date":int(self.store.clock.now())},"current_rank":int(source.get("rank",index+1)),
                "team":[team_ids], "my_equips":{}, "as_equips":[[] for _ in team_ids],
                "attrs":{"team_num":0,"friend_len":30},"records":{"current_rank":int(source.get("rank",index+1)),"help_suids":{},"help_fuids":{}},
                "avatars":{u["id"]:copy.deepcopy(u) for u in units}}

    @property
    def cultivator(self):
        if getattr(self, "_cultivator", None) is None:
            from npc_cultivation import NpcCultivator
            self._cultivator = NpcCultivator(self.store, self.config)
        return self._cultivator

    @staticmethod
    def _owner(profile):
        return str(profile.get("uid", "local")) if isinstance(profile, dict) else "local"

    def _roster(self, profile, *, persist):
        """Today's cultivated friend NPCs, rebuilt from the player's own growth.

        Each NPC keeps a stable main lineup built around bonds and a personal
        strength ratio; its cultivation follows the player's arena team, so
        friends level, gear and enchant alongside the player.
        """
        from mod_policy import policy_signature
        from npc_cultivation import stable_seed, template_stars
        from arena_opponents import bot_lines
        social = profile.get("social") if isinstance(profile.get("social"), dict) else {}
        day = game_day_number(self.store.clock.now())
        digest = policy_signature(self.config)
        state = social.get("npc_roster")
        if (isinstance(state, dict) and state.get("schema") == FRIEND_ROSTER_SCHEMA
                and state.get("day") == day and state.get("mod_digest") == digest
                and isinstance(state.get("bots"), dict)):
            return state
        cache_key = (self._owner(profile), day, digest, FRIEND_ROSTER_SCHEMA)
        cached = _ROSTERS.get(cache_key)
        if cached is not None and cached[0] == self.cultivator.template_digest(self.cultivator.template(profile)):
            state = copy.deepcopy(cached[1])
            if persist:
                profile.setdefault("social", {})["npc_roster"] = state
            return state
        competition = self.companions._competition()
        try:
            own_power = competition._team_power(competition._current_arena_team(profile))
        except GameplayFault:
            return None
        if own_power < 1:
            return None
        cultivator = self.cultivator
        template = cultivator.template(profile)
        stars = template_stars(template)
        forms = cultivator.family_forms("appearance.assist_bot")
        owner = self._owner(profile)
        bots = {}
        for bot in self.bots:
            uid = bot["uid"]
            rng = random.Random(stable_seed(owner, uid, "lineup", *stars))
            aids, bonds = cultivator.pick_team(rng, forms, stars)
            lines = bot_lines(rng, len(aids))
            ratio = .6 + .55 * (stable_seed(owner, uid, "ratio") % 1000) / 999
            seed = stable_seed(owner, uid, day)
            fitted = cultivator.fit(aids, template, own_power * ratio, competition._team_power, seed,
                                    uid=uid, name=bot["name"], scope="assist",
                                    lines=lines + [0] * (6 - len(lines)))
            bots[uid] = {"aids": aids, "lines": lines, "progress": fitted["progress"], "seed": seed,
                         "power": fitted["power"], "bonds": bonds}
        state = {"schema": FRIEND_ROSTER_SCHEMA, "day": day, "mod_digest": digest,
                 "template": template, "bots": bots}
        _ROSTERS[cache_key] = (cultivator.template_digest(template), copy.deepcopy(state))
        while len(_ROSTERS) > 32:
            _ROSTERS.pop(next(iter(_ROSTERS)))
        if persist:
            profile.setdefault("social", {})["npc_roster"] = state
        return state

    def _cultivated(self, bot, profile):
        """The static friend NPC with today's real cultivation, when available."""
        if not isinstance(profile, dict) or bot not in self.bots:
            return bot
        state = self._roster(profile, persist=False)
        recipe = state.get("bots", {}).get(bot["uid"]) if state else None
        if not recipe:
            return bot
        key = hashlib.sha256(json.dumps([self._owner(profile), bot["uid"], recipe, state["template"]],
                                        sort_keys=True, ensure_ascii=False).encode("utf-8")).hexdigest()
        built = _BUILT.get(key)
        if built is None:
            lines = recipe["lines"] + [0] * (6 - len(recipe["lines"]))
            built = self.cultivator.build(recipe["aids"], state["template"], recipe["progress"],
                                          recipe["seed"], uid=bot["uid"], name=bot["name"], lines=lines)
            _BUILT[key] = built
            while len(_BUILT) > _BUILT_LIMIT:
                _BUILT.popitem(last=False)
        else:
            _BUILT.move_to_end(key)
        result = copy.deepcopy(built)
        result.update({field: copy.deepcopy(bot[field]) for field in
                       ("uid", "name", "vip_lv", "login_time", "current_rank", "records") if field in bot})
        result["lv"] = max(1, int(state["template"].get("account_lv", bot.get("lv", 1))))
        result["power"] = recipe["power"]
        result["bonds_104"] = list(recipe.get("bonds", []))
        return result

    def _tick_requests(self, profile):
        """Let friend NPCs ask to be friends from time to time."""
        from npc_cultivation import stable_seed
        social = self._state(profile)
        window = int(self.store.clock.now()) // REQUEST_WINDOW_SECONDS
        last = social.get("request_window")
        social["request_window"] = window
        if type(last) is not int or last >= window:
            return
        ignored = social.setdefault("ignored", {})
        capacity = int(profile.get("attrs", {}).get("friend_len", self.capacity))
        owner = self._owner(profile)
        # Only the latest few windows count, so a long absence does not
        # flood the request list.
        for current in range(max(last + 1, window - 2), window + 1):
            pending = [uid for uid in social["incoming"] if uid in self.by_uid]
            if len(pending) >= MAX_PENDING_REQUESTS or len(social["friends"]) >= capacity:
                break
            rng = random.Random(stable_seed(owner, "friend-request", current))
            if rng.random() >= REQUEST_CHANCE:
                continue
            known = set(social["friends"]) | set(social["incoming"]) | set(social["outgoing"])
            choices = [bot["uid"] for bot in self.bots if bot["uid"] not in known
                       and current - int(ignored.get(bot["uid"], -10**9)) > IGNORE_COOLDOWN_WINDOWS]
            if choices:
                social["incoming"].append(rng.choice(choices))

    def _avatar_card(self, bot, instance_id):
        """Serialize the same combat fields as Avatar.toDataObj for panel preview."""
        avatar = self.roster.battle_attributes(bot, instance_id, scope="assist")
        if isinstance(bot.get("battle_stats"), dict):
            avatar.update(copy.deepcopy(bot["battle_stats"]))
        slot = next((i for i, hero_id in enumerate(bot.get("team", [[]])[0]) if hero_id == instance_id), 0)
        hero = bot.get("avatars", {}).get(instance_id, {})
        avatar.update({
            "aid": avatar.get("aid", str(hero.get("aid", instance_id)).split("|")[0]),
            "buffs": {}, "isme": False, "leader": 1 if slot == 0 else 0,
            "line": int(hero.get("line", 0)), "pos": float(hero.get("pos", slot)),
            "new_4attrs": {key: int(avatar.get(key, 0)) for key in ("hit", "flee", "crit", "tough")},
        })
        if int(hero.get("limit_break", 0) or 0) == 1:
            avatar["limit_break"] = 1
        if slot != 0:
            avatar["leader_skill"] = None
        return avatar

    def lookup_assist(self, uid, profile=None):
        """Return a validated local helper and its captain instance for PvE wiring."""
        bot = self._bot_or_fail(uid, profile)
        lead_id = next((item for item in bot.get("team", [[]])[0] if item), None)
        avatar = self._avatar_card(bot, lead_id)
        ensure_channel(self.config, avatar.get("aid", ""), "usage.friend_assist")
        return {"uid": bot["uid"], "name": bot["name"], "avatar_id": lead_id,
                "avatar": avatar, "cd_time": 0}

    def is_bot_uid(self, uid, profile=None):
        bot = self.by_uid.get(str(uid)) or self._dynamic_bot(uid, profile)
        if not isinstance(bot, dict):
            return False
        return any(hero_available(self.config, hero.get("aid", key))
                   and channel_enabled(self.config, hero.get("aid", key), "appearance.assist_bot")
                   for key, hero in bot.get("avatars", {}).items())

    def _dynamic_bot(self, uid, profile):
        if not isinstance(profile, dict):
            return None
        bot = self.companions.find(profile, uid)
        guild = profile.get("association")
        members = guild.get("members", []) if isinstance(guild, dict) else []
        social = profile.get("social")
        social = social if isinstance(social, dict) else {}
        known = any(str(uid) in social.get(key, []) for key in ("friends", "incoming", "outgoing"))
        if bot and (known or any(str(row.get("uid")) == str(uid) for row in members if isinstance(row, dict))):
            return bot
        return None

    def _bot_or_fail(self, uid, profile=None):
        bot = self.by_uid.get(str(uid))
        if bot is not None:
            return self._cultivated(bot, profile)
        bot = self._dynamic_bot(uid, profile)
        if bot is None:
            self._fail("LocalPlayerUnavailable", "Only local reconstruction bots can be selected here")
        return bot

    def _friend_card(self, uid, profile=None):
        bot = self._bot_or_fail(uid, profile)
        lead_id = next((x for x in bot["team"][0] if x), None)
        avatar = self._avatar_card(bot, lead_id)
        return {"uid":bot["uid"],"name":bot["name"],"lv":bot["lv"],"vip_lv":bot["vip_lv"],
                "avatar":avatar,"login_time":copy.deepcopy(bot["login_time"]),"current_rank":bot["current_rank"]}

    def _state(self, profile):
        social = profile.setdefault("social", {})
        social.setdefault("friends", [])
        social.setdefault("incoming", [])
        social.setdefault("outgoing", [])
        social.setdefault("friendship", 0)
        if not social.get("bootstrapped"):
            # Seed a few local request cards so the original request panel has something useful to do.
            social["incoming"].extend(b["uid"] for b in self.bots[3:5]
                                      if b["uid"] not in social["incoming"])
            social["bootstrapped"] = True
        return social

    def _write(self, uid, method, params, mutator):
        action = params.get("actionID")
        key = f"{method}:{action}" if isinstance(action,(str,int)) else None
        def refresh_then_mutate(profile):
            self.companions.refresh(profile)
            self._roster(profile, persist=True)
            self._tick_requests(profile)
            return mutator(profile)
        result, replayed = self.store.atomic_update(uid, refresh_then_mutate, idempotency_key=key,
                                                    request_payload=params if key else None)
        if isinstance(result, dict): result.setdefault("replayed", bool(replayed))
        return result

    def dispatch(self, uid, method, params):
        if method not in self.METHODS:
            self._fail("NotImplemented", f"Social method not reconstructed: {method}")
        if not isinstance(params, dict):
            self._fail("InvalidParameter", "Expected an object")
        if method == "user.get":
            target = str(params.get("uid", ""))
            return self._write(uid, method, params,
                               lambda profile: (profile, copy.deepcopy(self._bot_or_fail(target, profile))))
        if method == "user.get_friends": return self._get_friends(uid)
        if method == "user.online_user": return self._online_users(uid)
        if method == "user.apply_friend": return self._apply(uid, params)
        if method == "user.add_friend": return self._accept(uid, params)
        if method == "user.del_friend": return self._delete(uid, params)
        if method == "user.unapply_friend": return self._ignore(uid, params)
        if method == "user.get_radio":
            return native_dates({"self":[],"bugle":[],"sys":[{"rtype":"95018","time":{"$date":int(self.store.clock.now())}}]})
        if method == "user.send_bugle_radio":
            self._fail("LocalModeUnavailable", "本地重构模式不提供向其他玩家广播的功能")
        self._fail("NotImplemented", method)

    def _get_friends(self, uid):
        def mutate(profile):
            social=self._state(profile)
            friends=[self._friend_card(fid, profile) for fid in social["friends"] if self.is_bot_uid(fid, profile)]
            incoming=[self._friend_card(fid, profile) for fid in social["incoming"] if self.is_bot_uid(fid, profile)]
            # Local bots accept requests on the next refresh, retaining an auditable outgoing request first.
            accepted=[]
            for fid in social["outgoing"]:
                if self.is_bot_uid(fid, profile) and fid not in social["friends"] and len(social["friends"]) < int(profile.get("attrs",{}).get("friend_len",self.capacity)):
                    social["friends"].append(fid); accepted.append(fid)
            if accepted:
                social["outgoing"]=[fid for fid in social["outgoing"] if fid not in accepted]
                friends=[self._friend_card(fid, profile) for fid in social["friends"] if self.is_bot_uid(fid, profile)]
            return profile,{"friends_list":friends,"apply_list":incoming}
        return self._write(uid,"user.get_friends",{},mutate)

    def _online_users(self, uid):
        def mutate(profile):
            social=self._state(profile)
            friends=[self._friend_card(fid, profile) for fid in social["friends"] if self.is_bot_uid(fid, profile)]
            # Only admitted guild companions can appear in the helper list.
            guild_ids={str(row.get("uid")) for row in profile.get("association",{}).get("members",[])
                       if isinstance(row,dict)}
            companions=[bot for bot in profile.get("guild_companions",{}).get("bots",[])
                        if bot["uid"] in guild_ids]
            # Keep responses bounded; rotate additional hero candidates daily.
            offset = game_day_number(self.store.clock.now()) % max(1, len(self.mod_bots))
            extra = (self.mod_bots[offset:] + self.mod_bots[:offset])[:6]
            cards=[self._friend_card(bot["uid"], profile) for bot in self.bots+extra+companions
                   if self.is_bot_uid(bot["uid"], profile)]
            seen=set()
            return profile,[card for card in cards+friends
                            if not (card["uid"] in seen or seen.add(card["uid"]))]
        return self._write(uid,"user.online_user",{},mutate)

    def _apply(self, uid, params):
        fid=str(params.get("fid", ""))
        def mutate(profile):
            self._bot_or_fail(fid, profile)
            social=self._state(profile); friend_len=int(profile.get("attrs",{}).get("friend_len",self.capacity))
            if fid in social["friends"]: self._fail("AlreadyFriend", "This bot is already your friend")
            if len(social["friends"])>=friend_len: self._fail("FriendListFull", "Friend list is full")
            if fid not in social["outgoing"]: social["outgoing"].append(fid)
            return profile,{"ok":True,"fid":fid,"pending":True}
        return self._write(uid,"user.apply_friend",params,mutate)

    def _accept(self, uid, params):
        fid=str(params.get("fid", ""))
        def mutate(profile):
            self._bot_or_fail(fid, profile)
            social=self._state(profile)
            if fid not in social["incoming"]: self._fail("UnknownFriendRequest", "No local friend request from this bot")
            if fid in social["friends"]: self._fail("AlreadyFriend", "This bot is already your friend")
            cap=int(profile.get("attrs",{}).get("friend_len",self.capacity))
            if len(social["friends"])>=cap: self._fail("FriendListFull", "Friend list is full")
            social["incoming"].remove(fid); social["friends"].append(fid)
            return profile,{"ok":True,"friend":self._friend_card(fid, profile)}
        return self._write(uid,"user.add_friend",params,mutate)

    def _delete(self, uid, params):
        fid=str(params.get("fid", ""))
        def mutate(profile):
            self._bot_or_fail(fid, profile)
            social=self._state(profile)
            if fid not in social["friends"]: self._fail("NotFriend", "This bot is not in your friend list")
            social["friends"].remove(fid)
            return profile,{"ok":True,"fid":fid}
        return self._write(uid,"user.del_friend",params,mutate)

    def _ignore(self, uid, params):
        fid=str(params.get("fid", ""))
        def mutate(profile):
            self._bot_or_fail(fid, profile)
            social=self._state(profile)
            if fid in social["incoming"]: social["incoming"].remove(fid)
            social.setdefault("ignored",{})[fid]=int(self.store.clock.now())//REQUEST_WINDOW_SECONDS
            return profile,{"ok":True,"fid":fid}
        return self._write(uid,"user.unapply_friend",params,mutate)

