"""Daily adventure and lifetime nominal-payment rewards."""
from __future__ import annotations

import copy
import secrets
from collections import Counter

from gameplay_common import game_day, grant_reward, equipment_exclusive_ids
from player_store import GameplayFault
from recruit_exchange import daily_orange_pool


DAILY = (
    ("login", "每日登录", 1, {"coin": 2000, "culture_book": 300}),
    ("draw", "每日抽奖", 1, {"coin": 1500, "attrs": {"dust": [100, 100, 100, 100]}}),
    ("normal_wins", "普通副本胜利5次", 5, {"coin": 3000, "culture_book": 1000}),
    ("hard_wins", "精英副本胜利5次", 5, {"coin": 5000, "dn_stone": 300}),
)

MILESTONES = (
    (6, "随机普通橙英雄", "hero", None),
    (30, "随机普通橙装备", "equipment", None),
    (100, "随机普通橙装备", "equipment", None),
    (300, "培养材料", "fixed", {"coin": 5000, "culture_book": 3000}),
    (500, "随机普通橙装备", "equipment", None),
    (648, "随机普通橙装备", "equipment", None),
    (1000, "培养材料", "fixed", {"coin": 10000, "dn_stone": 1000}),
    (1888, "随机普通橙装备", "equipment", None),
    (3000, "培养材料", "fixed", {"coin": 20000, "culture_book": 10000,
                             "attrs": {"dust": [1500, 1500, 1500, 1500]}}),
    (5000, "钢铁侠提莫", "hero", "A_1310_6"),
    (8000, "培养材料", "fixed", {"coin": 30000, "dn_stone": 3000}),
    (10000, "二郎真君赵信", "hero", "A_1226_6"),
)


class AdventureTasks:
    def __init__(self, store, config):
        self.store = store
        self.config = config if isinstance(config, dict) else {}
        cfg = self.config.get("cfg", self.config)
        try:
            self.heroes = daily_orange_pool(self.config)
        except ValueError:
            # Partial test configurations can construct a store without any
            # hero table; claiming will report an unavailable reward.
            self.heroes = []
        exclusive = equipment_exclusive_ids(cfg)
        self.equipment = sorted(eid for eid, row in cfg.get("equip", {}).items()
                                if eid.startswith("E_") and eid.endswith("_6")
                                and isinstance(row, dict) and int(row.get("type", 0)) in (1, 3, 4, 5)
                                and eid not in exclusive)

    def _state(self, profile):
        state = profile.setdefault("adventure_tasks", {})
        if not isinstance(state, dict):
            state = profile["adventure_tasks"] = {}
        today = game_day(self.store.clock.now())
        if state.get("day") != today:
            state["day"] = today
            state["daily_counts"] = {}
            state["daily_claimed"] = []
        if not isinstance(state.get("daily_counts"), dict):
            state["daily_counts"] = {}
        if not isinstance(state.get("daily_claimed"), list):
            state["daily_claimed"] = []
        if not isinstance(state.get("milestone_claimed"), list):
            state["milestone_claimed"] = []
        if type(state.get("repeat_claimed")) is not int or state["repeat_claimed"] < 0:
            state["repeat_claimed"] = 0
        last_login = profile.get("login_time")
        if isinstance(last_login, dict):
            last_login = last_login.get("$date")
        if type(last_login) in (int, float) and game_day(last_login) == today:
            state["daily_counts"]["login"] = 1
        return state

    @staticmethod
    def paid_yuan(profile):
        attrs = profile.get("attrs", {})
        attrs = attrs if isinstance(attrs, dict) else {}
        records = profile.get("records", {})
        pay = records.get("pay", {}) if isinstance(records, dict) else {}
        task = profile.get("task", {})
        values = [attrs.get("pay_total", 0), attrs.get("pay_money", 0),
                  task.get("pay_total", 0) if isinstance(task, dict) else 0,
                  pay.get("coin", 0) // 10 if isinstance(pay, dict)
                  and type(pay.get("coin")) is int else 0]
        return max((value for value in values if type(value) is int and value >= 0), default=0)

    def record_login(self, profile):
        state = self._state(profile)
        state["daily_counts"]["login"] = 1

    def record_draw(self, profile):
        state = self._state(profile)
        state["daily_counts"]["draw"] = int(state["daily_counts"].get("draw", 0)) + 1

    def record_pve_win(self, profile, diff):
        state = self._state(profile)
        key = "hard_wins" if int(diff) == 1 else "normal_wins"
        state["daily_counts"][key] = int(state["daily_counts"].get(key, 0)) + 1

    @staticmethod
    def _preview(kind, reward):
        if kind == "hero":
            return {"random_non_skin_orange_hero": 1} if reward is None else {"avatar": {reward: 1}}
        if kind == "equipment":
            return {"random_normal_orange_equipment": 1}
        return copy.deepcopy(reward)

    @staticmethod
    def _reward_text(kind, reward):
        if kind == "hero":
            return ("钢铁侠提莫橙卡×1" if reward == "A_1310_6" else
                    "二郎真君赵信橙卡×1" if reward == "A_1226_6" else
                    "随机非皮肤橙英雄×1")
        if kind == "equipment":
            return "随机非专属橙装备×1"
        parts = []
        for key, value in reward.items():
            if key == "attrs" and isinstance(value, dict):
                for attr, amount in value.items():
                    if attr == "dust" and isinstance(amount, list):
                        parts.append("装备粉尘各" + str(amount[0]))
                    else:
                        parts.append(str(attr) + "×" + str(amount))
            else:
                label = {"coin": "金砖", "culture_book": "培养书",
                         "dn_stone": "德诺石"}.get(key, key)
                parts.append(label + "×" + str(value))
        return "、".join(parts)

    def _public(self, profile, state):
        paid = self.paid_yuan(profile)
        counts = state["daily_counts"]
        claimed = set(state["daily_claimed"])
        daily = [{"key": key, "title": title, "count": int(counts.get(key, 0)),
                  "goal": goal, "claimed": key in claimed,
                  "claimable": int(counts.get(key, 0)) >= goal and key not in claimed,
                  "reward": copy.deepcopy(reward),
                  "reward_text": self._reward_text("fixed", reward)}
                 for key, title, goal, reward in DAILY]
        claimed_milestones = set(str(key) for key in state["milestone_claimed"])
        milestones = [{"key": str(yuan), "title": title, "required_yuan": yuan,
                       "claimed": str(yuan) in claimed_milestones,
                       "claimable": paid >= yuan and str(yuan) not in claimed_milestones,
                       "reward": self._preview(kind, reward),
                       "reward_text": self._reward_text(kind, reward)}
                      for yuan, title, kind, reward in MILESTONES]
        repeat_claimed = max(0, int(state["repeat_claimed"]))
        repeat_available = max(0, paid // 2000 - repeat_claimed)
        return {"day": state["day"], "paid_yuan": paid, "daily": daily,
                "milestones": milestones,
                "repeat": {"key": "2000", "required_per_claim_yuan": 2000,
                           "claimed_count": repeat_claimed,
                           "available_count": repeat_available,
                           "claimable": repeat_available > 0,
                           "reward": {"random_non_skin_orange_hero": 1},
                           "reward_text": "每累计充值2000元：随机非皮肤橙英雄×1"}}

    def info(self, uid):
        def mutate(profile):
            state = self._state(profile)
            return profile, self._public(profile, state)
        result, _ = self.store.atomic_update(uid, mutate)
        return result

    def _award(self, profile, kind, reward):
        if kind == "hero":
            if reward is None:
                return self._award_random_heroes(profile, 1)
            aid = reward
            grant_reward(profile, {"avatar": {aid: 1}}, self.config,
                         allow_skin=aid in {"A_1310_6", "A_1226_6"})
            return {"avatar": {aid: 1}}
        if kind == "equipment":
            if not self.equipment:
                raise GameplayFault("AdventureRewardUnavailable", "No ordinary orange equipment is configured")
            eid = secrets.choice(self.equipment)
            grant_reward(profile, {"equip": {eid: 1}}, self.config)
            return {"equip": {eid: 1}}
        grant_reward(profile, reward, self.config)
        return copy.deepcopy(reward)

    def _award_random_heroes(self, profile, count):
        if not self.heroes:
            raise GameplayFault("AdventureRewardUnavailable", "No ordinary orange heroes are configured")
        chosen = Counter(secrets.choice(self.heroes) for _ in range(count))
        rows = []
        for aid, amount in chosen.items():
            while amount:
                portion = min(100, amount)
                rows.append({"aid": aid, "num": portion})
                amount -= portion
        grant_reward(profile, {"heroes": rows}, self.config)
        return {"avatar": dict(chosen)}

    def claim(self, uid, params):
        kind, key = params.get("kind"), params.get("key")
        if type(kind) is not str or type(key) is not str:
            raise GameplayFault("InvalidAdventureTask", "Task kind and key are required")
        if kind not in {"daily", "milestone", "repeat"}:
            raise GameplayFault("InvalidAdventureTask", "Unknown task kind")
        action = params.get("actionID")
        if type(action) is not str or not action:
            raise GameplayFault("InvalidRequestKey", "A claim actionID is required")
        def mutate(profile):
            state = self._state(profile)
            if kind == "daily":
                row = next((row for row in DAILY if row[0] == key), None)
                if row is None:
                    raise GameplayFault("InvalidAdventureTask", "Unknown daily task")
                _, _, goal, reward = row
                if int(state["daily_counts"].get(key, 0)) < goal:
                    raise GameplayFault("AdventureTaskIncomplete", "Daily task is incomplete")
                if key in state["daily_claimed"]:
                    raise GameplayFault("AdventureTaskClaimed", "Daily reward was already claimed")
                awarded = self._award(profile, "fixed", reward)
                state["daily_claimed"].append(key)
            elif kind == "milestone":
                row = next((row for row in MILESTONES if str(row[0]) == key), None)
                if row is None:
                    raise GameplayFault("InvalidAdventureTask", "Unknown payment milestone")
                yuan, _, reward_kind, reward = row
                if self.paid_yuan(profile) < yuan:
                    raise GameplayFault("AdventureTaskIncomplete", "Payment milestone is incomplete")
                if key in state["milestone_claimed"]:
                    raise GameplayFault("AdventureTaskClaimed", "Payment reward was already claimed")
                awarded = self._award(profile, reward_kind, reward)
                state["milestone_claimed"].append(key)
            else:
                if key != "2000":
                    raise GameplayFault("InvalidAdventureTask", "Unknown repeat reward")
                available = self.paid_yuan(profile) // 2000 - int(state["repeat_claimed"])
                if available <= 0:
                    raise GameplayFault("AdventureTaskIncomplete", "No repeat reward is available")
                awarded = self._award_random_heroes(profile, available)
                state["repeat_claimed"] = int(state["repeat_claimed"]) + available
            response = copy.deepcopy(profile)
            response.update({"ok": True, "kind": kind, "key": key, "award": awarded,
                             "tasks": self._public(profile, state)})
            if kind == "repeat":
                response["repeat_awarded_count"] = available
            return profile, response
        scope = game_day(self.store.clock.now()) if kind == "daily" else "lifetime"
        result, replayed = self.store.atomic_update(
            uid, mutate, "user.adventure_task_claim:" + scope + ":" + action,
            {"kind": kind, "key": key})
        result["replayed"] = replayed
        return result
