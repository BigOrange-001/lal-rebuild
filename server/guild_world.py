"""Persistent local AI players and guilds that grow alongside one save.

State lives in ``profile['guild_world']``. Like ``guild_companions`` it is not
part of the client state_sync projection. The player's own guild stays in the
native ``profile['association']`` record; ``guild_world.guilds`` only holds AI
guilds the player is not in, so every guild has exactly one source of truth.

AI players act through structured plans covering one window of game hours.
A plan comes from the deterministic rule planner or, when the player has
configured a model, from an LLM plan fetched ahead of time (``guild_llm``).
Both produce the same event list and run through one executor that checks
every action against the native guild rules: a plan may choose what an AI
does, never bypass daily limits, membership, capacity or costs.
"""
from __future__ import annotations

import copy
import hashlib
import random

import guild_chat
from bot_names import BOT_NAMES, bot_name_for_uid
from game_calendar import game_day, game_day_number, local_datetime

WORLD_VERSION = 1

DEFAULTS = {
    "agent_count": 36,
    "max_guilds": 8,
    "catchup_hours": 48,
    "plan_hours": 6,
    "apply_ttl_hours": 24,
    "reject_cooldown_hours": 72,
    "kick_cooldown_hours": 168,
    "max_daily_applications": 4,
    "ai_flourishing_daily_cap": 6,
    "ai_boss_hp_floor": 0.30,
    "worship_gold_per_ai": 50,
    "worship_gold_daily_ai_limit": 5,
    "chat_in_log": True,
}

# Legacy suggestion cards: IDs, names and join types (1 apply, 2 open, 0 closed)
# are kept so pending player applications in old saves stay valid.
LEGACY_GUILDS = (("10001", "晨星盟", 1), ("10002", "远征者", 2), ("10003", "青铜守卫", 0))
AI_GUILD_ID_START = 90001

ARCHETYPES = {
    #           label     activity   generosity  loyalty    ambition   chattiness
    "hot":     ("热血冲榜", (70, 95), (50, 85), (40, 75), (65, 95), (45, 80)),
    "chill":   ("佛系养老", (30, 60), (30, 70), (60, 95), (5, 35), (30, 60)),
    "chatty":  ("话痨", (55, 85), (35, 70), (45, 80), (20, 60), (75, 98)),
    "veteran": ("老练军师", (60, 85), (60, 90), (65, 95), (40, 75), (35, 65)),
    "lone":    ("冷淡独狼", (45, 80), (15, 45), (20, 50), (40, 80), (5, 20)),
    "rookie":  ("新手萌新", (50, 90), (40, 75), (50, 85), (10, 40), (50, 85)),
}
GUILD_PREFIXES = ("暗夜", "星辰", "烈焰", "苍穹", "霜狼", "龙魂", "风暴", "晨曦", "破晓", "永恒", "天启", "幻影")
GUILD_SUFFIXES = ("之刃", "联盟", "军团", "守卫", "骑士团", "殿堂", "部落", "之心")
ACTIONS = ("chat", "donate", "worship_guild", "worship_member", "boss", "apply", "leave", "found")


def _seed(*parts):
    return int.from_bytes(hashlib.sha256(":".join(map(str, parts)).encode()).digest()[:8], "big")


def _rng(*parts):
    return random.Random(_seed(*parts))


class GuildWorld:
    def __init__(self, store, config, handler, companions, llm=None):
        self.store = store
        self.full = config if isinstance(config, dict) else {}
        self.cfg = self.full.get("cfg", self.full)
        self.simple = self.cfg.get("association_simple", {})
        self.rules = self.full.get("guild_boss_reconstruction", {})
        self.handler = handler
        self.companions = companions
        self.llm = llm
        overrides = self.full.get("guild_ai", {})
        self.settings = {**DEFAULTS, **(overrides if isinstance(overrides, dict) else {})}

    # ------------------------------------------------------------------ basics
    def now(self):
        return int(self.store.clock.now())

    def _owner(self, profile):
        return str(profile.get("uid", ""))

    def _player_guild(self, profile):
        guild = profile.get("association")
        return guild if isinstance(guild, dict) and guild.get("id") else None

    def _capacity(self, level):
        row = self.simple.get("guild_level", {}).get(f"level_{int(level)}", {})
        return int(row.get("max_member_length", 22 + 2 * (int(level) - 1)))

    def _level_for(self, total_alive):
        rows = self.simple.get("guild_level", {})
        level = 1
        for i in range(1, 11):
            if int(total_alive) >= int(rows.get(f"level_{i}", {}).get("flourishing", 10 ** 18)):
                level = i
        return level

    def state(self, profile):
        world = profile.get("guild_world")
        if not isinstance(world, dict) or world.get("version") != WORLD_VERSION:
            world = self._create(profile)
        return world

    # -------------------------------------------------------------- creation
    def _new_agent(self, profile, uid, index, world, name=None, power=None, lv=None):
        owner = self._owner(profile)
        rng = _rng(owner, "agent", uid)
        arch = list(ARCHETYPES)[index % len(ARCHETYPES)] if index < len(ARCHETYPES) else rng.choice(list(ARCHETYPES))
        spec = ARCHETYPES[arch]
        pool = list(self.companions.orange)
        rng.shuffle(pool)
        pool = pool[:rng.randint(8, 12)]
        skins = list(self.companions.skins)
        if skins and pool and rng.random() < 0.25:
            pool[rng.randrange(len(pool))] = rng.choice(skins)
        talent = rng.randint(1, 100)
        player_lv = int(profile.get("lv", 1))
        lv0 = max(1, min(125, int(lv) if lv else player_lv + rng.randint(-10, 5)))
        hour = self.now() // 3600
        agent = {
            "uid": uid, "name": name or bot_name_for_uid(uid), "arch": arch,
            "act": rng.randint(*spec[1]), "gen": rng.randint(*spec[2]), "loy": rng.randint(*spec[3]),
            "amb": rng.randint(*spec[4]), "chat": rng.randint(*spec[5]),
            "talent": talent, "r0": round(0.2 + 0.3 * rng.random(), 3),
            "rcap": round(0.6 + 0.7 * talent / 100, 3),
            "pool": pool, "lv0": lv0, "lv": lv0, "power": int(power or 0), "days": 0,
            "created_day": game_day_number(hour * 3600), "guild": None, "rank": 3,
            "contribute": 0, "mood": 60, "memory": [], "cool": {}, "daily": {},
            "free_since": game_day_number(hour * 3600),
        }
        self._grow(agent, world, profile, active=False)
        return agent

    def _unique_names(self, agents):
        seen = set()
        for agent in agents.values():
            if agent["name"] in seen:
                rng = _rng(agent["uid"], "rename")
                for _ in range(len(BOT_NAMES)):
                    name = rng.choice(BOT_NAMES)
                    if name not in seen:
                        agent["name"] = name
                        break
            seen.add(agent["name"])

    def _create(self, profile):
        """Build version 1 from any older profile, keeping accepted companions."""
        hour = self.now() // 3600
        competition = self.companions._competition()
        power_now = self.companions._player_power(profile, competition)
        world = {"version": WORLD_VERSION, "created_hour": hour, "last_hour": hour,
                 "last_day": game_day_number(hour * 3600), "player_ref": power_now,
                 "player_peak": power_now, "time_base": int(max(5000, power_now) * 0.4),
                 "agents": {}, "guilds": {}, "plan": {}, "counters": {}}
        profile["guild_world"] = world
        agents = world["agents"]
        guild = self._player_guild(profile)
        old_bots = {}
        legacy = profile.get("guild_companions")
        if isinstance(legacy, dict):
            old_bots = {str(bot.get("uid")): bot for bot in legacy.get("bots", []) if isinstance(bot, dict)}
        removed_static = 0
        if guild:
            kept = []
            for row in guild.get("members", []):
                if not isinstance(row, dict):
                    continue
                uid = str(row.get("uid", ""))
                if uid.startswith("npc-"):
                    removed_static += 1
                    continue
                if row.get("guild_companion"):
                    bot = old_bots.get(uid, {})
                    agent = self._new_agent(profile, uid, len(agents), world,
                                            name=bot.get("name") or row.get("name"),
                                            power=bot.get("power") or row.get("power"),
                                            lv=bot.get("lv") or row.get("lv"))
                    agent["guild"] = guild["id"]
                    agent["rank"] = int(row.get("association_lv", 3))
                    agent["contribute"] = int(row.get("contribute", 0) or 0)
                    agents[uid] = agent
                kept.append(row)
            guild["members"] = kept
            # Old hourly applicants are regenerated by the new world.
            guild["applications"] = [row for row in guild.get("applications", []) or []
                                     if isinstance(row, dict) and not row.get("guild_companion")]
        index = 10
        while len(agents) < int(self.settings["agent_count"]):
            uid = self.companions.uid(profile, index)
            index += 1
            if uid not in agents:
                agents[uid] = self._new_agent(profile, uid, len(agents), world)
        self._unique_names(agents)
        self._seed_guilds(profile, world)
        if guild and removed_static:
            self._log(guild, f"公会原有的{removed_static}名固定成员已离开，新的成员将陆续加入")
            if self._player_rank(profile) == 0:
                self._recruit_founders(profile, world, min(removed_static, 3))
        if isinstance(legacy, dict):
            legacy["friend_invites_sent"] = {**legacy.get("friend_invites_sent", {}),
                                             **{uid: True for uid in agents if agents[uid]["guild"]}}
        return world

    def _seed_guilds(self, profile, world):
        agents = world["agents"]
        free = [a for a in sorted(agents.values(), key=lambda a: -a["amb"]) if not a["guild"]]
        player = self._player_guild(profile)
        taken = {str(player["id"])} if player else set()
        rng = _rng(self._owner(profile), "seed-guilds")
        next_id = AI_GUILD_ID_START
        for i, (gid, name, join_type) in enumerate(LEGACY_GUILDS):
            if gid in taken:
                gid = str(next_id)
                next_id += 1
            if not free:
                break
            leader = free.pop(0)
            record = self._guild_record(gid, name, i, leader, join_type)
            record["total_alive"] = 10 * (i + 1)
            record["level"] = self._level_for(record["total_alive"])
            world["guilds"][gid] = record
            self._join_ai(world, leader, gid, rank=0)
            for _ in range(5 + i):
                if not free:
                    break
                self._join_ai(world, free.pop(rng.randrange(len(free))), gid)

    def _guild_record(self, gid, name, icon, leader, join_type):
        return {"id": gid, "name": name, "icon": int(icon) % 10, "leader": leader["uid"], "level": 1,
                "total_alive": 0, "join_type": join_type, "created": self.now(),
                "notice": f"{name}欢迎志同道合的伙伴", "weak_days": 0,
                "target_size": 8 + _seed(gid, name) % 7}

    # ---------------------------------------------------------------- growth
    def _grow(self, agent, world, profile, active=True):
        """Steady time growth blended with the player's progress; never decreases."""
        today = game_day_number(self.now())
        if active:
            agent["days"] += 1
        age = max(0, today - int(agent["created_day"]))
        talent = int(agent["talent"])
        ratio = min(float(agent["rcap"]), float(agent["r0"]) + 0.015 * agent["days"] * talent / 50)
        growth = 0.01 + 0.02 * talent / 100
        time_power = int(world.get("time_base", 2000)) * min(50.0, (1 + growth) ** age)
        player_part = int(world.get("player_ref", 0)) * ratio
        agent["power"] = max(int(agent.get("power", 0)), int(0.5 * player_part + 0.5 * time_power))
        cap = max(int(agent["lv0"]), min(125, int(profile.get("lv", 1)) + 5))
        agent["lv"] = max(int(agent["lv"]), min(cap, int(agent["lv0"]) + age))
        agent["owned"] = min(len(agent["pool"]), 3 + agent["days"] // 3)

    def _daily(self, profile, world, day):
        rng_owner = self._owner(profile)
        for agent in world["agents"].values():
            active = _rng(rng_owner, agent["uid"], "day", day).random() < agent["act"] / 100
            self._grow(agent, world, profile, active=active)
            if agent["guild"]:
                gained = world["counters"].get(f"alive:{agent['guild']}:{day - 1}", 0)
                agent["mood"] = max(0, min(100, agent["mood"] + (3 if gained else -4)))
            else:
                agent["mood"] = 60
        for gid in list(world["guilds"]):
            record = world["guilds"][gid]
            members = [a for a in world["agents"].values() if a["guild"] == gid]
            record["weak_days"] = record.get("weak_days", 0) + 1 if len(members) < 3 else 0
            if record["weak_days"] >= 3:
                for agent in members:
                    self._free(agent, "所在公会解散了")
                del world["guilds"][gid]
                continue
            if day % 7 == 0 and members and not any(a["rank"] == 1 for a in members):
                best = max((a for a in members if a["rank"] != 0), key=lambda a: a["contribute"], default=None)
                if best:
                    best["rank"] = 1
        world["counters"] = {k: v for k, v in world["counters"].items()
                             if not k.startswith(("alive:", "pw:", "apps:")) or k.endswith(f":{day}") or k.endswith(f":{day - 1}")}

    def _update_player_ref(self, profile, world):
        competition = self.companions._competition()
        power = self.companions._player_power(profile, competition)
        world["player_peak"] = max(int(world.get("player_peak", 0)), power)
        world["player_ref"] = int(max(world.get("player_ref", power) * 0.8 + power * 0.2,
                                      world["player_peak"] * 0.6))

    # ------------------------------------------------------------- membership
    def _join_ai(self, world, agent, gid, rank=3):
        agent.update({"guild": gid, "rank": rank, "contribute": 0, "mood": 70})

    def _free(self, agent, memory=None):
        agent.update({"guild": None, "rank": 3, "free_since": game_day_number(self.now())})
        if memory:
            self._remember(agent, memory)

    @staticmethod
    def _remember(agent, text):
        agent["memory"] = ([text] + [m for m in agent.get("memory", []) if m != text])[:6]

    def _player_rank(self, profile):
        guild = self._player_guild(profile)
        if not guild:
            return None
        me = str(profile.get("uid", ""))
        row = next((r for r in guild.get("members", []) if isinstance(r, dict) and str(r.get("uid")) == me), None)
        return int(row.get("association_lv", 3)) if row else None

    def _agent_row(self, agent, now):
        return {"uid": agent["uid"], "zone": "local", "name": agent["name"], "lv": agent["lv"],
                "vip_lv": 0, "power": agent["power"], "association_lv": agent["rank"],
                "apply_time": {"$date": now}, "guild_companion": True, "status": 1,
                "contribute": agent["contribute"],
                "worship_info": {"member_worship_count": 0, "member_worship_user_list": [],
                                 "member_worship_day": game_day(now)}}

    def _add_to_player_guild(self, profile, agent, rank=3, invite=False):
        guild = self._player_guild(profile)
        agent["guild"], agent["rank"], agent["contribute"], agent["mood"] = guild["id"], rank, 0, 70
        guild.setdefault("members", []).append(self._agent_row(agent, self.now()))
        sent = profile.setdefault("guild_companions", {}).setdefault("friend_invites_sent", {})
        if not invite:
            sent[agent["uid"]] = True

    def _recruit_founders(self, profile, world, count):
        guild = self._player_guild(profile)
        free = sorted((a for a in world["agents"].values() if not a["guild"]), key=lambda a: (a["amb"], a["uid"]))
        for agent in free[:count]:
            self._add_to_player_guild(profile, agent)
            self._log(guild, f"{agent['name']}作为元老加入公会")

    def on_player_guild_created(self, profile):
        world = self.state(profile)
        self._recruit_founders(profile, world, 3)
        self.sync_bots(profile)

    def on_rejected(self, profile, uid):
        world = self.state(profile)
        agent = world["agents"].get(str(uid))
        guild = self._player_guild(profile)
        if agent and guild:
            agent["cool"][str(guild["id"])] = self.now() // 3600 + int(self.settings["reject_cooldown_hours"])
            self._remember(agent, f"申请{guild['name']}被拒绝")

    def free_player_guild_id(self, profile, gid):
        world = self.state(profile)
        candidate = int(gid)
        while str(candidate) in world["guilds"] or str(candidate) in {g for g, _, _ in LEGACY_GUILDS}:
            candidate = 10000 + (candidate - 10000 + 1) % 80000
        return str(candidate)

    def join_player(self, profile, gid):
        """Move an AI guild into profile['association'] with the player as a member."""
        world = self.state(profile)
        record = world["guilds"].pop(gid)
        now = self.now()
        me = self.handler._me(profile)
        attrs = profile.setdefault("attrs", {})
        rows = [self._agent_row(a, now) for a in world["agents"].values() if a["guild"] == gid]
        rows.sort(key=lambda r: (r["association_lv"] != 0, -r["contribute"]))
        rows.append({**me, "association_lv": 3, "contribute": int(attrs.get("guild_contribute", 0)), "status": 1,
                     "worship_info": {"member_worship_count": 0, "member_worship_user_list": [],
                                      "member_worship_day": game_day(now)}})
        profile["association"] = {
            "id": gid, "name": record["name"], "icon": record["icon"], "level": record["level"], "exp": 0,
            "total_alive": record["total_alive"], "notice": record["notice"], "created": record["created"],
            "members": rows, "guild_graduate_skill_list": list(record.get("skills", [])), "boss": {},
            "logs": [], "shop": {}, "fund": 0, "applications": [], "join_type": record["join_type"],
        }
        sent = profile.setdefault("guild_companions", {}).setdefault("friend_invites_sent", {})
        for row in rows[:-1]:
            sent[row["uid"]] = True
        attrs.update({"association_id": gid, "association_lv": 3})
        profile.setdefault("records", {}).pop("guild_applications", None)
        guild = profile["association"]
        self._log(guild, f"{me['name']}加入公会")
        greeters = [a for a in world["agents"].values() if a["guild"] == gid]
        rng = _rng(self._owner(profile), "welcome", now)
        for agent in rng.sample(greeters, min(2, len(greeters))):
            self._say(profile, agent, guild_chat.template_line("welcome", agent["arch"], rng, other=me["name"]), "template")
        self.sync_bots(profile)

    def on_player_exit(self, profile, disband=False):
        """Return the player's guild to the AI world, or free its members on disband."""
        world = self.state(profile)
        guild = self._player_guild(profile)
        if not guild:
            return
        gid = str(guild["id"])
        self.reconcile(profile, world)
        members = [a for a in world["agents"].values() if a["guild"] == gid]
        if disband or not members:
            for agent in members:
                self._free(agent, f"{guild['name']}解散了")
            return
        if not any(a["rank"] == 0 for a in members):
            leader = max(members, key=lambda a: (a["contribute"], a["power"]))
            leader["rank"] = 0
        leader = next(a for a in members if a["rank"] == 0)
        world["guilds"][gid] = {
            "id": gid, "name": guild.get("name", ""), "icon": int(guild.get("icon", 0)), "leader": leader["uid"],
            "level": int(guild.get("level", 1)), "total_alive": int(guild.get("total_alive", 0)),
            "join_type": int(guild.get("join_type", 1)), "created": int(guild.get("created", self.now())),
            "notice": str(guild.get("notice", "")), "weak_days": 0,
            "skills": list(guild.get("guild_graduate_skill_list", [])),
        }

    # -------------------------------------------------------------- reconcile
    def reconcile(self, profile, world):
        guild = self._player_guild(profile)
        gid = str(guild["id"]) if guild else None
        agents = world["agents"]
        rows = {}
        if guild:
            for row in guild.get("members", []):
                if isinstance(row, dict) and str(row.get("uid")) in agents:
                    rows[str(row["uid"])] = row
        hour = self.now() // 3600
        for agent in agents.values():
            row = rows.get(agent["uid"])
            if row is not None:
                agent["guild"] = gid
                agent["rank"] = int(row.get("association_lv", 3))
                row.update({"name": agent["name"], "lv": agent["lv"], "power": agent["power"],
                            "contribute": agent["contribute"]})
            elif agent["guild"] and agent["guild"] == gid:
                self._free(agent, f"被移出{guild['name']}")
                agent["cool"][gid] = hour + int(self.settings["kick_cooldown_hours"])
            elif agent["guild"] and agent["guild"] not in world["guilds"]:
                self._free(agent, "所在公会解散了")
        if guild:
            apps = guild.get("applications", [])
            if not isinstance(apps, list):
                apps = []
            ttl = int(self.settings["apply_ttl_hours"]) * 3600
            kept = []
            for app in apps:
                if not isinstance(app, dict):
                    continue
                if app.get("guild_companion"):
                    agent = agents.get(str(app.get("uid")))
                    stamp = app.get("apply_time", {})
                    stamp = int(stamp.get("$date", 0)) if isinstance(stamp, dict) else 0
                    if not agent or agent["guild"] or self.now() - stamp > ttl:
                        continue
                    app.update({"name": agent["name"], "lv": agent["lv"], "power": agent["power"]})
                kept.append(app)
            guild["applications"] = kept

    def sync_bots(self, profile):
        """Keep assist/friend cards for every agent the player can see."""
        world = self.state(profile)
        companions = profile.setdefault("guild_companions", {})
        guild = self._player_guild(profile)
        visible = set()
        if guild:
            visible |= {str(r.get("uid")) for r in guild.get("members", []) if isinstance(r, dict)}
            visible |= {str(r.get("uid")) for r in guild.get("applications", []) if isinstance(r, dict)}
        social = profile.get("social") if isinstance(profile.get("social"), dict) else {}
        for key in ("friends", "incoming", "outgoing"):
            visible |= {str(uid) for uid in social.get(key, []) if isinstance(social.get(key), list)}
        cache = {str(b.get("uid")): b for b in companions.get("bots", []) if isinstance(b, dict)}
        bots = []
        competition = None
        for uid in sorted(visible & set(world["agents"])):
            agent = world["agents"][uid]
            key = [agent["lv"], agent["owned"], agent["pool"][0] if agent["pool"] else ""]
            old = cache.get(uid)
            if old and old.get("agent_key") == key and old.get("power") and \
                    abs(int(old["power"]) - agent["power"]) <= 0.05 * agent["power"]:
                old["name"] = agent["name"]
                bots.append(old)
                continue
            if not agent["pool"]:
                continue
            competition = competition or self.companions._competition()
            bot = self.companions.agent_bot(agent, competition)
            bot["agent_key"] = key
            bots.append(bot)
        companions["bots"] = bots
        companions.pop("hour", None)
        return bots

    # ---------------------------------------------------------------- advance
    def advance(self, profile):
        world = self.state(profile)
        self.reconcile(profile, world)
        now = self.now()
        hour = now // 3600
        last = int(world.get("last_hour", hour))
        today = game_day_number(now)
        if today != int(world.get("last_day", today)):
            self._update_player_ref(profile, world)
            for day in range(int(world["last_day"]) + 1, today + 1)[-3650:]:
                self._daily(profile, world, day)
            world["last_day"] = today
        if hour > last:
            start = max(last + 1, hour - int(self.settings["catchup_hours"]) + 1)
            for tick in range(start, hour + 1):
                self._tick(profile, world, tick, live=(hour - tick) < int(self.settings["plan_hours"]))
            world["last_hour"] = hour
        self._apply_replies(profile, world)
        self.reconcile(profile, world)
        self.sync_bots(profile)
        return world

    def _tick(self, profile, world, hour, live):
        size = int(self.settings["plan_hours"])
        window = hour // size
        plan = world.get("plan") or {}
        if plan.get("w") != window:
            events, source = None, "rule"
            if self.llm is not None and self.llm.enabled():
                events = self.llm.take_plan(self.store.db, self._owner(profile), window)
                if events is not None:
                    source = "llm"
                if live:
                    self.llm.request_plan(self._owner(profile), window + 1, self.snapshot(profile, window + 1))
            if events is None:
                events = self.rule_plan(profile, world, window)
            plan = {"w": window, "source": source, "events": events}
            world["plan"] = plan
        offset = hour - window * size
        for event in plan["events"]:
            if isinstance(event, dict) and event.get("h") == offset:
                self.execute(profile, world, event, hour, plan["source"])
        self._decide_player_applications(profile, world, hour)

    # ------------------------------------------------------------ rule planner
    def _boss_open(self, hour):
        return self.handler._boss_window_open("guild_boss", now=hour * 3600 + 300)

    def rule_plan(self, profile, world, window):
        size = int(self.settings["plan_hours"])
        rng = _rng(self._owner(profile), "plan", window)
        hours = [window * size + k for k in range(size)]
        weights = []
        for h in hours:
            local = local_datetime(h * 3600).hour
            weights.append(0.15 if 1 <= local <= 7 else (0.5 if local == 0 else 1.0))
        events = []
        today = game_day_number(self.now())
        for uid in sorted(world["agents"]):
            agent = world["agents"][uid]
            online = [k for k, w in enumerate(weights) if rng.random() < agent["act"] / 100 * w * 0.35]
            if not online:
                continue
            first = online[0]
            if agent["guild"]:
                if rng.random() < agent["gen"] / 100:
                    events.append({"h": first, "uid": uid, "act": "donate",
                                   "tier": 1 if agent["gen"] > 75 and rng.random() < 0.35 else 0})
                if rng.random() < 0.4 + agent["gen"] / 200:
                    events.append({"h": first, "uid": uid, "act": "worship_guild",
                                   "tier": 1 if agent["gen"] > 85 and rng.random() < 0.2 else 0})
                if rng.random() < 0.5:
                    events.append({"h": rng.choice(online), "uid": uid, "act": "worship_member"})
                if rng.random() < agent["chat"] / 200:
                    events.append({"h": first, "uid": uid, "act": "chat", "topic": "greet"})
                if rng.random() < agent["chat"] / 400:
                    events.append({"h": rng.choice(online), "uid": uid, "act": "chat", "topic": "idle"})
                for k in online:
                    if self._boss_open(hours[k]):
                        events.append({"h": k, "uid": uid, "act": "boss"})
                if agent["mood"] < 30 and agent["loy"] < 50 and agent["rank"] != 0 and rng.random() < 0.15:
                    events.append({"h": online[-1], "uid": uid, "act": "leave"})
            else:
                if agent["amb"] >= 70 and agent["lv"] >= 30 and today - agent.get("free_since", today) >= 3 \
                        and rng.random() < 0.1:
                    events.append({"h": first, "uid": uid, "act": "found"})
                elif rng.random() < 0.35:
                    events.append({"h": first, "uid": uid, "act": "apply"})
        events.sort(key=lambda e: (e["h"], e["uid"]))
        return events

    # --------------------------------------------------------------- executor
    def _daily_flags(self, agent, day):
        flags = agent.get("daily")
        if not isinstance(flags, dict) or flags.get("day") != day:
            flags = {"day": day}
            agent["daily"] = flags
        return flags

    def _guild_of(self, profile, world, gid):
        player = self._player_guild(profile)
        if player and str(player["id"]) == gid:
            return player, True
        return world["guilds"].get(gid), False

    def execute(self, profile, world, event, hour, source):
        uid = str(event.get("uid", ""))
        agent = world["agents"].get(uid)
        act = event.get("act")
        if agent is None or act not in ACTIONS:
            return False
        day = game_day_number(hour * 3600)
        flags = self._daily_flags(agent, day)
        ts = hour * 3600 + 60 * (_seed(uid, hour) % 50)
        handler = getattr(self, "_act_" + act)
        try:
            return bool(handler(profile, world, agent, event, hour, day, flags, ts, source))
        except (TypeError, ValueError, KeyError):
            return False

    def _act_chat(self, profile, world, agent, event, hour, day, flags, ts, source):
        if int(flags.get("chat", 0)) >= 6 or not self._in_player_guild(profile, agent):
            return False
        text = guild_chat.clean_text(event.get("text")) if event.get("text") else ""
        if not text:
            topic = event.get("topic") if event.get("topic") in guild_chat.TEMPLATES else "idle"
            text = guild_chat.template_line(topic, agent["arch"], _rng(agent["uid"], hour, "chat"),
                                            name=agent["name"], guild=self._player_guild(profile)["name"])
            source = "template"
        if not text:
            return False
        flags["chat"] = int(flags.get("chat", 0)) + 1
        self._say(profile, agent, text, source, ts)
        return True

    def _act_donate(self, profile, world, agent, event, hour, day, flags, ts, source):
        if not agent["guild"] or flags.get("donate"):
            return False
        rows = self.simple.get("guild_contribute_info", {}).get("exchange_cost_info", {})
        row = rows.get("4" if int(event.get("tier", 0)) == 1 else "1") or {"contribute": 100}
        amount = int(row.get("contribute", 100))
        flags["donate"] = True
        agent["contribute"] += amount
        guild, is_player = self._guild_of(profile, world, agent["guild"])
        if is_player:
            self._log(guild, f"{agent['name']}兑换公会贡献{amount}", ts)
            self._maybe_say(profile, agent, "donate", hour, ts)
        return True

    def _act_worship_guild(self, profile, world, agent, event, hour, day, flags, ts, source):
        if not agent["guild"] or flags.get("worship"):
            return False
        options = self.simple.get("guild_worship", [[0, 5, "free"], [10, 10, "coin"], [100, 20, "coin"]])
        tier = max(0, min(len(options) - 1, int(event.get("tier", 0))))
        amount = int(options[tier][1])
        key = f"alive:{agent['guild']}:{day}"
        cap = int(self.settings["ai_flourishing_daily_cap"])
        amount = max(0, min(amount, cap - int(world["counters"].get(key, 0))))
        flags["worship"] = True
        guild, is_player = self._guild_of(profile, world, agent["guild"])
        if guild is None:
            return False
        if amount:
            world["counters"][key] = int(world["counters"].get(key, 0)) + amount
            guild["total_alive"] = int(guild.get("total_alive", 0)) + amount
            guild["level"] = max(int(guild.get("level", 1)), self._level_for(guild["total_alive"]))
        if is_player:
            self._log(guild, f"{agent['name']}完成公会供奉" + (f"，增加活跃{amount}" if amount else ""), ts)
            self._maybe_say(profile, agent, "worship", hour, ts)
        return True

    def _act_worship_member(self, profile, world, agent, event, hour, day, flags, ts, source):
        if int(flags.get("mw", 0)) >= 2 or not self._in_player_guild(profile, agent):
            return False
        guild = self._player_guild(profile)
        me = str(profile.get("uid", ""))
        rows = [r for r in guild.get("members", []) if isinstance(r, dict) and str(r.get("uid")) != agent["uid"]]
        target = next((r for r in rows if str(r.get("uid")) == str(event.get("target", ""))), None)
        if target is None:
            rng = _rng(agent["uid"], hour, "mw")
            player_row = next((r for r in rows if str(r.get("uid")) == me), None)
            if player_row and rng.random() < 0.5:
                target = player_row
            elif rows:
                target = max(rows, key=lambda r: (int(r.get("association_lv", 3)) == 0, int(r.get("power", 0) or 0)))
        if target is None:
            return False
        today = game_day(hour * 3600)
        info = target.get("worship_info") if isinstance(target.get("worship_info"), dict) else {}
        if info.get("member_worship_day") != today:
            info = {"member_worship_day": today, "member_worship_count": 0, "member_worship_user_list": []}
        users = info.get("member_worship_user_list") if isinstance(info.get("member_worship_user_list"), list) else []
        if agent["uid"] in users:
            return False
        if str(target.get("uid")) == me:
            key = f"pw:{day}"
            if int(world["counters"].get(key, 0)) >= int(self.settings["worship_gold_daily_ai_limit"]):
                return False
            world["counters"][key] = int(world["counters"].get(key, 0)) + 1
            attrs = profile.setdefault("attrs", {})
            attrs["association_worship_gold"] = int(attrs.get("association_worship_gold", 0)) + \
                int(self.settings["worship_gold_per_ai"])
        users.append(agent["uid"])
        info.update({"member_worship_count": len(users), "member_worship_user_list": users})
        target["worship_info"] = info
        flags["mw"] = int(flags.get("mw", 0)) + 1
        self._log(guild, f"{agent['name']}膜拜了{target.get('name', '')}", ts)
        if _rng(agent["uid"], hour, "mw-say").random() < agent["chat"] / 300:
            self._say(profile, agent, guild_chat.template_line(
                "worship_member", agent["arch"], _rng(agent["uid"], hour), other=target.get("name", "")), "template", ts)
        return True

    def _act_boss(self, profile, world, agent, event, hour, day, flags, ts, source):
        if not self._in_player_guild(profile, agent) or day != game_day_number(self.now()):
            return False
        if not self._boss_open(hour):
            return False
        rules = self.rules.get("guild_boss", {}).get("attack", {})
        if int(flags.get("boss", 0)) >= int(rules.get("free_per_day", 3)):
            return False
        state = self.handler._boss_state(profile, "guild_boss")
        boss = state["boss"]
        max_hp = int(boss.get("max_hp", 0))
        floor = int(max_hp * float(self.settings["ai_boss_hp_floor"]) + 0.999)
        room = int(boss.get("current_hp", 0)) - floor
        if boss.get("is_end") or room <= 0:
            return False
        raw = int(rules.get("base_damage", 1200) + agent["power"] * rules.get("damage_per_power", .35))
        damage = max(1, min(room, int(rules.get("damage_cap", 250000)), raw))
        boss["current_hp"] = int(boss["current_hp"]) - damage
        flags["boss"] = int(flags.get("boss", 0)) + 1
        ranks = state.setdefault("ai_ranks", {})
        row = ranks.setdefault(agent["uid"], {"uid": agent["uid"], "name": agent["name"], "damage": 0})
        row["damage"] = int(row["damage"]) + damage
        state["report_list"].insert(0, {"type": "zb_attack", "data": {"uid": agent["uid"], "attack_hp": damage,
                                                                      "name": agent["name"]}})
        state["report_list"] = state["report_list"][:10]
        self.handler._rebuild_boss_ranks(profile, state)
        self._log(self._player_guild(profile), f"{agent['name']}挑战公会Boss，造成{damage}点伤害", ts)
        if flags["boss"] == 1:
            self._maybe_say(profile, agent, "boss", hour, ts, damage=damage)
        return True

    def _guild_cards_for_apply(self, profile, world, agent, hour):
        options = []
        for gid, record in world["guilds"].items():
            if record["join_type"] == 0 or agent["cool"].get(gid, 0) > hour:
                continue
            members = sum(1 for a in world["agents"].values() if a["guild"] == gid)
            # AI guilds stop recruiting at a modest size so free players keep
            # applying to the player's guild instead of one open AI guild.
            if members >= min(self._capacity(record["level"]), int(record.get("target_size", 12))):
                continue
            options.append((gid, record["level"] * 10 + members * 2))
        player = self._player_guild(profile)
        if player and agent["cool"].get(str(player["id"]), 0) <= hour:
            members = len(player.get("members", []))
            if members < self._capacity(player.get("level", 1)):
                bonus = 40 if agent["arch"] in ("hot", "veteran") else 30
                options.append((str(player["id"]), int(player.get("level", 1)) * 10 + members * 2 + bonus))
        return options

    def _act_apply(self, profile, world, agent, event, hour, day, flags, ts, source):
        if agent["guild"] or flags.get("apply"):
            return False
        options = self._guild_cards_for_apply(profile, world, agent, hour)
        target = str(event.get("target", "") or "")
        if target:
            options = [o for o in options if o[0] == target]
        if not options:
            return False
        rng = _rng(agent["uid"], hour, "apply")
        gid = max(options, key=lambda o: o[1] + rng.random() * 20)[0]
        flags["apply"] = True
        guild, is_player = self._guild_of(profile, world, gid)
        if is_player:
            if self._player_rank(profile) in (0, 1):
                key = f"apps:{day}"
                if int(world["counters"].get(key, 0)) >= int(self.settings["max_daily_applications"]):
                    return False
                apps = guild.setdefault("applications", [])
                if any(str(a.get("uid")) == agent["uid"] for a in apps if isinstance(a, dict)):
                    return False
                world["counters"][key] = int(world["counters"].get(key, 0)) + 1
                apps.append({"uid": agent["uid"], "zone": "local", "name": agent["name"], "lv": agent["lv"],
                             "vip_lv": 0, "power": agent["power"], "association_lv": 3,
                             "apply_time": {"$date": ts}, "guild_companion": True})
                return True
            # An AI leader runs the player's current guild: decide now.
            self._add_to_player_guild(profile, agent)
            self._log(guild, f"{agent['name']}加入公会", ts)
            self._maybe_say(profile, agent, "join", hour, ts, force=True)
            return True
        members = [a for a in world["agents"].values() if a["guild"] == gid]
        average = sum(a["power"] for a in members) / max(1, len(members))
        if guild["join_type"] == 2 or agent["power"] >= 0.3 * average:
            self._join_ai(world, agent, gid)
        else:
            agent["cool"][gid] = hour + int(self.settings["reject_cooldown_hours"])
        return True

    def _act_leave(self, profile, world, agent, event, hour, day, flags, ts, source):
        if not agent["guild"] or agent["rank"] == 0 or agent["mood"] >= 40:
            return False
        gid = agent["guild"]
        guild, is_player = self._guild_of(profile, world, gid)
        if is_player:
            self._maybe_say(profile, agent, "leave", hour, ts, force=True)
            guild["members"] = [r for r in guild.get("members", [])
                                if not (isinstance(r, dict) and str(r.get("uid")) == agent["uid"])]
            self._log(guild, f"{agent['name']}离开了公会", ts)
        agent["cool"][gid] = hour + int(self.settings["reject_cooldown_hours"])
        self._free(agent, f"离开了{guild['name'] if guild else '公会'}")
        return True

    def _act_found(self, profile, world, agent, event, hour, day, flags, ts, source):
        if agent["guild"] or agent["amb"] < 70 or agent["lv"] < 30:
            return False
        total = len(world["guilds"]) + (1 if self._player_guild(profile) else 0)
        if total >= int(self.settings["max_guilds"]):
            return False
        names = {g["name"] for g in world["guilds"].values()}
        player = self._player_guild(profile)
        if player:
            names.add(player.get("name"))
        name = guild_chat.clean_text(event.get("name"), 8) if event.get("name") else ""
        rng = _rng(agent["uid"], hour, "found")
        for _ in range(40):
            if 2 <= len(name) <= 8 and name not in names and not any(c in name for c in "*\\/"):
                break
            name = rng.choice(GUILD_PREFIXES) + rng.choice(GUILD_SUFFIXES)
        else:
            return False
        used = set(world["guilds"]) | ({str(player["id"])} if player else set())
        gid = AI_GUILD_ID_START
        while str(gid) in used:
            gid += 1
        world["guilds"][str(gid)] = self._guild_record(str(gid), name, rng.randrange(10), agent, rng.choice((1, 2)))
        self._join_ai(world, agent, str(gid), rank=0)
        self._remember(agent, f"创建了公会{name}")
        return True

    def _decide_player_applications(self, profile, world, hour):
        records = profile.setdefault("records", {})
        apps = records.get("guild_applications")
        if not isinstance(apps, dict) or not apps:
            return
        for gid in sorted(apps):
            app = apps.get(gid)
            if not isinstance(app, dict) or app.get("status") != "pending":
                continue
            submitted = int(app.get("submitted_hour", hour - 1))
            if submitted >= hour:
                continue
            record = world["guilds"].get(gid)
            if self._player_guild(profile) or record is None:
                apps.pop(gid, None)
                continue
            members = [a for a in world["agents"].values() if a["guild"] == gid]
            average = sum(a["power"] for a in members) / max(1, len(members))
            if len(members) + 1 <= self._capacity(record["level"]) and \
                    int(world.get("player_ref", 0)) >= 0.2 * average and record["join_type"] != 0:
                self.join_player(profile, gid)
                return
            apps.pop(gid, None)
        if not apps:
            records.pop("guild_applications", None)

    # ------------------------------------------------------------------ chat
    def _in_player_guild(self, profile, agent):
        guild = self._player_guild(profile)
        return bool(guild and agent["guild"] == str(guild["id"]))

    def _maybe_say(self, profile, agent, topic, hour, ts, force=False, **values):
        rng = _rng(agent["uid"], hour, topic)
        if not force and rng.random() >= agent["chat"] / 250:
            return
        guild = self._player_guild(profile)
        text = guild_chat.template_line(topic, agent["arch"], rng, name=agent["name"],
                                        guild=guild["name"] if guild else "", **values)
        self._say(profile, agent, text, "template", ts)

    def _say(self, profile, agent, text, source, ts=None):
        guild = self._player_guild(profile)
        if not guild or not text:
            return
        ts = self.now() if ts is None else int(ts)
        guild_chat.ensure_table(self.store.db)
        guild_chat.append(self.store.db, self._owner(profile), guild["id"], ts, agent["uid"],
                          agent["name"], text, source)
        if self.settings.get("chat_in_log"):
            self._log(guild, f"【聊天】{agent['name']}：{text}", ts)

    def player_said(self, profile, text):
        """Store the player's own guild message and ask the model for replies."""
        guild = self._player_guild(profile)
        me = self.handler._me(profile)
        guild_chat.ensure_table(self.store.db)
        guild_chat.append(self.store.db, me["uid"], guild["id"], self.now(), me["uid"], me["name"], text, "player")
        world = self.state(profile)
        if self.llm is not None and self.llm.enabled() and self.llm.allows_player_text():
            last = int(world["counters"].get("reply_request", 0))
            if self.now() - last >= int(self.llm.settings.get("reply_cooldown_seconds", 600)):
                world["counters"]["reply_request"] = self.now()
                self.llm.request_reply(me["uid"], self.snapshot(profile, None, player_text=text))

    def _apply_replies(self, profile, world):
        if self.llm is None or not self.llm.enabled():
            return
        hour = self.now() // 3600
        for events in self.llm.take_replies(self.store.db, self._owner(profile)):
            for event in events[:4]:
                if isinstance(event, dict) and event.get("act") == "chat":
                    self.execute(profile, world, {**event, "h": 0}, hour, "llm")

    def _log(self, guild, text, ts=None):
        if not guild:
            return
        logs = guild.get("logs")
        if not isinstance(logs, list):
            logs = []
            guild["logs"] = logs
        stamp = int(ts) if ts is not None else self.now()
        logs.insert(0, [{"$date": stamp}, str(text)[:240]])
        del logs[100:]

    # ----------------------------------------------------------------- views
    def guild_cards(self, profile, include_player=False):
        world = self.state(profile)
        applications = profile.get("records", {}).get("guild_applications", {})
        if not isinstance(applications, dict):
            applications = {}
        cards = []
        for gid, record in world["guilds"].items():
            members = [a for a in world["agents"].values() if a["guild"] == gid]
            capacity = self._capacity(record["level"])
            leader = world["agents"].get(record["leader"], {})
            app = applications.get(gid)
            cards.append({
                "id": gid, "name": record["name"], "icon": record["icon"], "level": record["level"],
                "member_count": len(members), "member_num": len(members), "max_member": capacity,
                "max_num": capacity, "total_alive": record["total_alive"], "content": record["notice"],
                "notice": record["notice"], "join_level_limit": 1, "join_type": record["join_type"],
                "flag": int(isinstance(app, dict) and app.get("status") == "pending"),
                "power": sum(a["power"] for a in members), "leader_name": leader.get("name", ""),
            })
        player = self._player_guild(profile)
        if include_player and player:
            rows = [r for r in player.get("members", []) if isinstance(r, dict)]
            capacity = self._capacity(player.get("level", 1))
            cards.append({
                "id": str(player["id"]), "name": player.get("name", ""), "icon": player.get("icon", 0),
                "level": player.get("level", 1), "member_count": len(rows), "member_num": len(rows),
                "max_member": capacity, "max_num": capacity, "total_alive": player.get("total_alive", 0),
                "content": player.get("notice", ""), "notice": player.get("notice", ""), "join_level_limit": 1,
                "join_type": int(player.get("join_type", 1)), "flag": 0,
                "power": sum(int(r.get("power", 0) or 0) for r in rows),
            })
        cards.sort(key=lambda c: (-int(c["total_alive"]), -int(c["power"]), c["id"]))
        return cards

    def snapshot(self, profile, window, player_text=None):
        """Compact, personal-data-free context for one planning request."""
        world = self.state(profile)
        guild = self._player_guild(profile)
        size = int(self.settings["plan_hours"])
        hours = []
        if window is not None:
            for k in range(size):
                h = window * size + k
                hours.append({"h": k, "local_hour": local_datetime(h * 3600).hour, "boss_open": self._boss_open(h)})
        agents = []
        for agent in sorted(world["agents"].values(), key=lambda a: a["uid"]):
            agents.append({"uid": agent["uid"], "name": agent["name"],
                           "persona": ARCHETYPES[agent["arch"]][0], "activity": agent["act"],
                           "generosity": agent["gen"], "loyalty": agent["loy"], "ambition": agent["amb"],
                           "chattiness": agent["chat"], "lv": agent["lv"], "power": agent["power"],
                           "guild": agent["guild"], "rank": agent["rank"], "mood": agent["mood"],
                           "memory": agent["memory"][:3]})
        guilds = [{"id": c["id"], "name": c["name"], "level": c["level"], "members": c["member_count"],
                   "join_type": c["join_type"]} for c in self.guild_cards(profile, include_player=True)]
        chat = []
        if guild:
            guild_chat.ensure_table(self.store.db)
            chat = [{"name": row["name"], "text": row["text"]}
                    for row in guild_chat.recent(self.store.db, self._owner(profile), guild["id"], 8)]
        me = self.handler._me(profile)
        return {"window": window, "hours": hours, "player": {
                    "name": me["name"], "lv": me["lv"], "power": int(world.get("player_ref", 0)),
                    "guild": str(guild["id"]) if guild else None, "rank": self._player_rank(profile)},
                "player_guild_name": guild.get("name") if guild else None,
                "guilds": guilds, "agents": agents, "recent_chat": chat,
                "player_message": player_text}
