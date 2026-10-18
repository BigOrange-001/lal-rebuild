"""Owner-scoped guild applicants whose native helper stats follow the player's team."""
from __future__ import annotations

import hashlib
import random
import copy

from bot_names import bot_name_for_uid
from mod_policy import (runtime as mod_runtime, candidate_ids, policy_signature,
                        hero_available, channel_enabled)


COMPANION_COUNT = 10


class GuildCompanions:
    def __init__(self, store, config):
        self.store = store
        self.config = config if isinstance(config, dict) else {}
        self.cfg = self.config.get("cfg", self.config)
        self.heroes = self.cfg.get("avatar", {})
        blocked = self.cfg.get("system_simple", {}).get("skin_acquisition_blocked_heroes", [])
        self.skins = sorted(aid for aid in blocked if aid in self.heroes and aid.startswith("A_1") and aid.endswith("_6"))
        self.orange = sorted(aid for aid in self.heroes if aid.startswith("A_1") and aid.endswith("_6"))
        if mod_runtime(self.config):
            self.skins = candidate_ids(self.config, self.skins, "appearance.assist_bot", quality=6)
            self.orange = candidate_ids(self.config, self.orange, "appearance.assist_bot", include_new=True, quality=6)

    def _competition(self):
        from gameplay_competition import GameplayCompetition

        for handler in self.store.gameplay_handlers:
            if isinstance(handler, GameplayCompetition):
                return handler
        return GameplayCompetition(self.store, self.config)

    @staticmethod
    def _owner_uid(profile):
        owner = str(profile.get("uid", ""))
        if owner.isdecimal() and len(owner) <= 8:
            return int(owner)
        return int.from_bytes(hashlib.sha256(owner.encode()).digest()[:4], "big")

    def uid(self, profile, index):
        return str(930000000000 + self._owner_uid(profile) * 100 + index + 1)

    def _player_power(self, profile, competition):
        teams = profile.get("team", [])
        if not isinstance(teams, list) or not teams:
            return 0
        team_index = max(0, min(int(profile.get("attrs", {}).get("team_num", 0)), len(teams) - 1))
        saved = teams[team_index]
        rows = [[iid, slot % 3, slot / 6] for slot, iid in enumerate(saved[:6])
                if iid and iid in profile.get("avatars", {}) and hero_available(
                    self.config, profile["avatars"][iid].get("aid", iid))]
        if not rows:
            return 0
        measured = profile
        if mod_runtime(self.config):
            measured = copy.deepcopy(profile)
            measured["team"][team_index] = [row[0] for row in rows]
        return competition._team_power(competition._own_team(measured, {"team_num": team_index, "team": rows}))

    def _hero(self, owner, uid, hour, index, target_power, competition):
        seed = int.from_bytes(hashlib.sha256(f"{owner}:{uid}:{hour}".encode()).digest()[:8], "big")
        rng = random.Random(seed)
        # Include the skin pool in ordinary draws and guarantee one skin among
        # the ten candidates when the configured skin prototypes are present.
        pool = self.skins if index == 0 and self.skins else self.orange
        aid = rng.choice(pool)
        instance = f"{aid}|{uid}"
        hero = {"id": instance, "aid": instance, "tpl": aid, "lv": 125, "slv": 1,
                "hp": 0, "ap": 0, "de_ph": 0, "de_ma": 0, "phase": 0,
                "morph": 0, "limit_break": 1, "equips": [], "line": 0, "pos": 0.2}
        bot = {"uid": uid, "name": bot_name_for_uid(uid), "zone": "local",
               "lv": 125, "vip_lv": 0, "login_time": {"$date": hour * 3600},
               "current_rank": index + 1, "team": [[instance, None, None, None, None, None]],
               "my_equips": {}, "as_equips": [[] for _ in range(6)],
               "attrs": {"team_num": 0, "friend_len": 30},
               "records": {"help_suids": {}, "help_fuids": {}}, "avatars": {instance: hero}}
        from gameplay_roster import GameplayRosterEquipment

        base = GameplayRosterEquipment(self.store, self.config).battle_attributes(bot, instance, scope="assist")
        card = {**base, "aid": aid, "leader": 1, "isme": False, "buffs": {},
                "line": 0, "pos": 0.2,
                "new_4attrs": {key: int(base.get(key, 0)) for key in ("hit", "flee", "crit", "tough")}}
        keys = ("hp", "ap", "de_ph", "de_ma")
        baseline = [max(1, int(base[key])) for key in keys]

        def measured(scale):
            stats = {key: max(1, int(value * scale)) for key, value in zip(keys, baseline)}
            candidate = {**card, **stats, "hp_max": stats["hp"]}
            return competition._team_power([candidate]), stats

        # Native power is quadratic in the four primary battle attributes.
        # Solve against the actual serialized card instead of changing a display
        # field. This also allows a level-125 NPC to assist a new player fairly.
        target = max(0, int(round(target_power)))
        low, high = 0.0, 1.0
        while measured(high)[0] < target and high < 1024:
            high *= 2
        best = None
        for _ in range(36):
            middle = (low + high) / 2
            power, stats = measured(middle)
            if best is None or abs(power - target) < abs(best[0] - target):
                best = (power, stats)
            if power < target:
                low = middle
            else:
                high = middle
        for scale in (low, high):
            power, stats = measured(scale)
            if abs(power - target) < abs(best[0] - target):
                best = (power, stats)
        power, stats = best
        bot["battle_stats"] = {**stats, "hp_max": stats["hp"]}
        bot["power"] = power
        return bot

    def refresh(self, profile):
        """Persist one generation per clock hour and keep accepted rows current."""
        guild = profile.get("association")
        guild = guild if isinstance(guild, dict) and guild.get("id") else {}
        members = guild.get("members", [])
        owner = str(profile.get("uid", ""))
        is_chairman = any(str(row.get("uid")) == owner and int(row.get("association_lv", 3)) == 0
                          for row in members if isinstance(row, dict))
        if not is_chairman and not isinstance(profile.get("guild_companions"), dict):
            return []
        state = profile.setdefault("guild_companions", {})
        hour = int(self.store.clock.now()) // 3600
        digest = policy_signature(self.config)
        if state.get("hour") != hour or not isinstance(state.get("bots"), list) or state.get("mod_digest", "") != digest:
            competition = self._competition()
            target = self._player_power(profile, competition) * 0.30
            state["bots"] = [self._hero(owner, self.uid(profile, i), hour, i, target, competition)
                             for i in range(COMPANION_COUNT)] if self.orange else []
            state["hour"] = hour
            state["mod_digest"] = digest
        bots = state["bots"]
        accepted = {str(member.get("uid")) for member in members if isinstance(member, dict)}
        for member in members:
            if not isinstance(member, dict):
                continue
            bot = next((row for row in bots if row["uid"] == str(member.get("uid"))), None)
            if bot:
                member.update({"name": bot["name"], "lv": bot["lv"], "power": bot["power"]})
        # Older accepted companions may predate the friend invitation. Record
        # delivery so dismissing a request does not cause it to reappear.
        sent = state.setdefault("friend_invites_sent", {})
        social = profile.setdefault("social", {})
        incoming = social.setdefault("incoming", [])
        friends = social.setdefault("friends", [])
        for bot in bots:
            uid = bot["uid"]
            if uid not in accepted or sent.get(uid):
                continue
            if uid not in friends and uid not in incoming:
                incoming.append(uid)
            sent[uid] = True
        if not is_chairman:
            return bots
        applications = guild.setdefault("applications", [])
        if not isinstance(applications, list):
            applications = []
            guild["applications"] = applications
        pending = {str(row.get("uid")) for row in applications if isinstance(row, dict)}
        for row in applications:
            if not isinstance(row, dict) or not row.get("guild_companion"):
                continue
            bot = next((item for item in bots if item["uid"] == str(row.get("uid"))), None)
            if bot:
                row.update({"name": bot["name"], "lv": bot["lv"], "power": bot["power"]})
        rejected = state.setdefault("rejected", {})
        for bot in bots:
            if bot["uid"] in accepted or bot["uid"] in pending or rejected.get(bot["uid"]) == hour:
                continue
            applications.append(self.application(bot, int(self.store.clock.now())))
        return bots

    @staticmethod
    def application(bot, now):
        return {"uid": bot["uid"], "zone": bot["zone"], "name": bot["name"],
                "lv": bot["lv"], "vip_lv": bot["vip_lv"], "power": bot["power"],
                "association_lv": 3, "apply_time": {"$date": now}, "guild_companion": True}

    @staticmethod
    def member(bot, now, day):
        return {**GuildCompanions.application(bot, now), "status": 1, "contribute": 0,
                "worship_info": {"member_worship_count": 0,
                                 "member_worship_user_list": [], "member_worship_day": day}}

    @staticmethod
    def find(profile, uid):
        state = profile.get("guild_companions", {})
        bots = state.get("bots", []) if isinstance(state, dict) else []
        return next((bot for bot in bots if isinstance(bot, dict) and bot.get("uid") == str(uid)), None)
