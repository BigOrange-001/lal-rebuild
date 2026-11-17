"""Top-ten arena raids: NPCs ranked below the player come to take their place.

While the player holds a top-ten rank, an NPC from the current opponent list
may prepare an attack every few hours. The attack is queued, not resolved:
the player fights it on the client as an ordinary arena battle (the AIR
client result is authoritative), defending with any lineup they choose.

* Defended: the player keeps the rank. The NPC may come back once more with
  rearranged lanes, or another NPC tries later.
* Lost: the player and the attacker swap ranks.
* Not answered within a day: the NPC gives up; nothing changes.

Attackers are rebuilt from their real-cultivation recipe and prepare to
roughly the player's strength, keeping their bond lineup.
"""
from __future__ import annotations

import copy
import random
import secrets

from arena_opponents import bot_lines, fit_bot
from npc_cultivation import stable_seed
from player_store import GameplayFault

RAID_TOP_RANK = 10
RAID_WINDOW_SECONDS = 3 * 3600
RAID_CHANCE = .55
MAX_QUEUED_RAIDS = 2
RAID_TTL_SECONDS = 24 * 3600
RETRY_DELAY_SECONDS = 3600
MAX_RETRIES = 2
RETRY_SAME_ATTACKER = .6
PREPARED_POWER = (.9, 1.15)
LOG_LIMIT = 20
METHODS = {"user.get_arena_raids", "user.pk_combat_raid"}


class ArenaRaids:
    def __init__(self, competition):
        self.comp = competition

    # ---------------------------------------------------------------- state
    @staticmethod
    def state(profile):
        records = profile.setdefault("records", {})
        state = records.get("arena_raids")
        if not isinstance(state, dict):
            state = {}
            records["arena_raids"] = state
        state.setdefault("queue", [])
        state.setdefault("log", [])
        state.setdefault("retries", [])
        return state

    def _now(self):
        return int(self.comp.store.clock.now())

    def _prepare(self, profile, uid, bot, batch, attempt, *, lines=None):
        """Rebuild the attacker from its recipe at a prepared strength."""
        recipe = bot.get("recipe") or {}
        if not recipe.get("aids"):
            return None
        own_power = self.comp._team_power(self.comp._current_arena_team(profile))
        seed = stable_seed(uid, bot["uid"], "raid", attempt, self._now() // RAID_WINDOW_SECONDS)
        rng = random.Random(seed)
        target = round(own_power * rng.uniform(*PREPARED_POWER))
        lanes = lines or recipe.get("lines")
        built = fit_bot(self.comp.cultivator, batch["template"], {}, rng, target, self.comp._team_power,
                        uid=bot["uid"], name=bot["name"], seed=seed, aids=list(recipe["aids"]),
                        lines=list(lanes))
        return {"id": "raid_" + secrets.token_hex(8), "attacker_uid": bot["uid"], "name": bot["name"],
                "rank": int(bot["rank"]), "lv": int(bot.get("lv", 1)), "units": built["units"],
                "power": built["power"], "bonds": list(bot.get("bonds", [])), "attempt": attempt,
                "lines": list(lanes), "created": self._now(), "expires": self._now() + RAID_TTL_SECONDS}

    def tick(self, profile, uid):
        """Queue new attacks for elapsed windows; drop stale ones."""
        state = self.state(profile)
        now = self._now()
        rank = self.comp._rank(profile)
        window = now // RAID_WINDOW_SECONDS
        last = state.get("window")
        state["window"] = window
        batch = profile.get("records", {}).get("pvp_opponents")
        bots = batch.get("bots", []) if isinstance(batch, dict) else []
        current = {bot["uid"]: bot for bot in bots if isinstance(bot, dict)}
        # Raids only target a top-ten holder, from NPCs still listed below.
        state["queue"] = [raid for raid in state["queue"] if isinstance(raid, dict)
                          and raid.get("expires", 0) > now and rank <= RAID_TOP_RANK
                          and raid.get("attacker_uid") in current
                          and int(current[raid["attacker_uid"]]["rank"]) > rank]
        if rank > RAID_TOP_RANK or not isinstance(batch, dict) or not batch.get("template"):
            state["retries"] = []
            return state
        below = [bot for bot in bots if int(bot.get("rank", 0)) > rank and bot.get("recipe")]
        # Retries from defended raids come back first, once they are ready.
        ready = [row for row in state["retries"] if row.get("ready_at", 0) <= now]
        state["retries"] = [row for row in state["retries"] if row.get("ready_at", 0) > now]
        for row in ready:
            if len(state["queue"]) >= MAX_QUEUED_RAIDS:
                state["retries"].append(row)
                continue
            bot = current.get(row.get("attacker_uid"))
            if bot and int(bot["rank"]) > rank:
                raid = self._prepare(profile, uid, bot, batch, int(row.get("attempt", 1)),
                                     lines=row.get("lines"))
                if raid:
                    state["queue"].append(raid)
        if type(last) is not int or last >= window:
            return state
        for current_window in range(max(last + 1, window - 2), window + 1):
            if len(state["queue"]) >= MAX_QUEUED_RAIDS or not below:
                break
            rng = random.Random(stable_seed(uid, "arena-raid", current_window))
            if rng.random() >= RAID_CHANCE:
                continue
            queued = {raid["attacker_uid"] for raid in state["queue"]}
            choices = [bot for bot in below if bot["uid"] not in queued]
            if not choices:
                break
            # Closer ranks are hungrier for the spot.
            weights = [1 / max(1, int(bot["rank"]) - rank) for bot in choices]
            bot = rng.choices(choices, weights)[0]
            raid = self._prepare(profile, uid, bot, batch, 0)
            if raid:
                state["queue"].append(raid)
        return state

    # ------------------------------------------------------------------ RPC
    @staticmethod
    def _public(raid):
        return {"raid_id": raid["id"], "uid": raid["attacker_uid"], "name": raid["name"],
                "rank": raid["rank"], "lv": raid["lv"], "power": raid["power"],
                "attempt": raid["attempt"], "bonds": raid.get("bonds", []),
                "data_base": None, "expires": {"$date": raid["expires"]}}

    def list(self, uid):
        def change(profile):
            self.comp._ensure_opponents(profile, uid)
            state = self.tick(profile, uid)
            rows = []
            for raid in state["queue"]:
                row = self._public(raid)
                row["data_base"] = self.comp._compact(raid["units"])
                rows.append(row)
            return profile, {"raids": rows, "log": copy.deepcopy(state["log"][:LOG_LIMIT]),
                             "rank": self.comp._rank(profile), "top_rank": RAID_TOP_RANK}
        return self.comp.store.atomic_update(uid, change)[0]

    def start(self, uid, params):
        """Start the defense battle as an ordinary arena intent."""
        raid_id = str(params.get("raid_id", ""))
        comp = self.comp

        def mutate(profile):
            state = self.tick(profile, uid)
            raid = next((row for row in state["queue"] if row.get("id") == raid_id), None)
            if raid is None:
                raise GameplayFault("UnknownRaid", "This arena raid is no longer pending")
            own = comp._own_team(profile, params)
            enemy = copy.deepcopy(raid["units"])
            from battle_intents import create_intent
            metadata = {"uid": raid["attacker_uid"], "target_uid": raid["attacker_uid"],
                        "rank": raid["rank"], "raid_id": raid_id,
                        "team_num": comp._num(params.get("team_num", 0), "team_num", 0, 2),
                        "opponent_name": raid["name"], "opponent_lv": raid["lv"]}
            my_power = comp._team_power(own)
            enemy_power = comp._team_power(enemy)
            def_th = comp._pvp_def_th(my_power, enemy_power)
            token = create_intent(profile, "pvp", metadata, own, enemy,
                                  int(comp.rules.get("intent_ttl", 3600)), now=self._now(), config=comp.cfg)
            intent = profile["pending_battles"]["pvp"][token["fight_id"]]
            intent.update(arena_my_pr_power=my_power, arena_pr_power=enemy_power, arena_def_th=def_th)
            poke = {"gift_list": [{"gold": 0}] * 3, "poke_gift_index": 0, "user_gift": {"gold": 0}}
            return profile, {"fight_kind": "pvp", "fight_id": token["fight_id"], "seed": token["seed"],
                             "metadata": metadata, "cid": "V_000_0", "def_th": def_th,
                             "orgin_team_a": own, "orgin_team_b": enemy, "team1": [], "team2": [],
                             "poke_data": poke, "sign": 0, "my_pr_power": my_power, "pr_power": enemy_power,
                             "arena_raid": True}
        return comp.store.atomic_update(uid, mutate, idempotency_key=comp._key("user.pk_combat_raid", params),
                                        request_payload=params if params.get("actionID") else None)[0]

    # ---------------------------------------------------------- settlement
    def _swap(self, profile, raid):
        attrs = profile.setdefault("attrs", {})
        records = profile.setdefault("records", {})
        new_rank = max(self.comp._rank(profile), int(raid["rank"]))
        attrs["pvp_rank"] = new_rank
        records["current_rank"] = new_rank

    @staticmethod
    def _log(state, raid, result, old_rank, new_rank):
        entry = {"name": raid["name"], "rank": raid["rank"], "result": result, "attempt": raid["attempt"],
                 "old_rank": old_rank, "new_rank": new_rank, "power": raid["power"]}
        state["log"] = [entry] + list(state.get("log", []))[:LOG_LIMIT - 1]

    def finish(self, profile, uid, intent, sign, metadata, now):
        """Settle a defense battle; returns the new rank."""
        state = self.state(profile)
        raid = next((row for row in state["queue"] if row.get("id") == metadata.get("raid_id")), None)
        if raid is None:
            # The raid expired while the battle was running: no rank change.
            return self.comp._rank(profile), None
        state["queue"].remove(raid)
        old = self.comp._rank(profile)
        if sign == 1:
            self._log(state, raid, "defended", old, old)
            attempt = int(raid["attempt"]) + 1
            rng = random.Random(stable_seed(uid, raid["id"], "retry"))
            if attempt <= MAX_RETRIES and rng.random() < RETRY_SAME_ATTACKER:
                # Same NPC, new lanes: it studied the loss.
                lines = bot_lines(rng, len(raid["lines"]))
                while lines == raid["lines"]:
                    lines = bot_lines(rng, len(raid["lines"]))
                state["retries"].append({"attacker_uid": raid["attacker_uid"], "attempt": attempt,
                                         "lines": lines, "ready_at": now + RETRY_DELAY_SECONDS})
            return old, "defended"
        self._swap(profile, raid)
        self._log(state, raid, "lost", old, self.comp._rank(profile))
        return self.comp._rank(profile), "lost"
