"""Assist/friend cards for the persistent guild AI players.

The AI players themselves (identity, personality, growth, membership) live in
``guild_world``. This module keeps the card cache in
``profile['guild_companions']['bots']`` that the friend and assist flows in
``gameplay_social`` read through ``find``, and builds those cards with real
battle attributes solved to the agent's target power.
"""
from __future__ import annotations

import hashlib
import copy

from mod_policy import (runtime as mod_runtime, candidate_ids, hero_available)


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

    def _build(self, uid, name, aids, lv, target_power, competition):
        """Serialize a helper whose captain card is solved to ``target_power``."""
        heroes = {}
        team = []
        for slot, aid in enumerate(aids[:6]):
            instance = f"{aid}|{uid}"
            heroes[instance] = {"id": instance, "aid": instance, "tpl": aid, "lv": lv, "slv": 1,
                                "hp": 0, "ap": 0, "de_ph": 0, "de_ma": 0, "phase": 0,
                                "morph": 0, "limit_break": 1, "equips": [], "line": slot % 3,
                                "pos": 0.2 + slot * 0.12}
            team.append(instance)
        captain = team[0]
        bot = {"uid": uid, "name": name, "zone": "local",
               "lv": lv, "vip_lv": 0, "login_time": {"$date": int(self.store.clock.now())},
               "current_rank": 1, "team": [team + [None] * (6 - len(team))],
               "my_equips": {}, "as_equips": [[] for _ in range(6)],
               "attrs": {"team_num": 0, "friend_len": 30},
               "records": {"help_suids": {}, "help_fuids": {}}, "avatars": heroes}
        from gameplay_roster import GameplayRosterEquipment

        base = GameplayRosterEquipment(self.store, self.config).battle_attributes(bot, captain, scope="assist")
        card = {**base, "aid": aids[0], "leader": 1, "isme": False, "buffs": {},
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
        # field, so the shown power is what the assist actually brings.
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

    def agent_bot(self, agent, competition):
        owned = [aid for aid in agent["pool"][:max(1, int(agent.get("owned", 3)))] if aid in self.heroes]
        if not owned:
            owned = list(self.orange[:1])
        return self._build(agent["uid"], agent["name"], owned, max(1, int(agent["lv"])),
                           agent["power"], competition)

    def refresh(self, profile):
        """Deliver one friend invitation per companion the player approved.

        Membership and growth are advanced by ``guild_world`` on guild RPCs;
        this only backfills invitations for saves that predate them.
        """
        state = profile.get("guild_companions")
        if not isinstance(state, dict):
            return []
        bots = state.get("bots", []) if isinstance(state.get("bots"), list) else []
        guild = profile.get("association")
        members = guild.get("members", []) if isinstance(guild, dict) and guild.get("id") else []
        accepted = {str(member.get("uid")) for member in members if isinstance(member, dict)}
        sent = state.setdefault("friend_invites_sent", {})
        social = profile.setdefault("social", {})
        incoming = social.setdefault("incoming", [])
        friends = social.setdefault("friends", [])
        for bot in bots:
            uid = bot.get("uid")
            if uid not in accepted or sent.get(uid):
                continue
            if uid not in friends and uid not in incoming:
                incoming.append(uid)
            sent[uid] = True
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
