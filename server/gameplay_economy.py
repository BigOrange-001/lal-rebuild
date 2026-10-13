"""Persistent local economy, payment, daily sign-in, and task handlers."""
from __future__ import annotations
import copy, datetime, hashlib, math, random
from gameplay_common import game_day, grant_reward, skin_acquisition_blocked_ids
from gameplay_energy import energy_state
from player_store import GameplayFault, native_dates

# Local test-gift denominations, in game currency (coin / 金砖).
PACKS = {f"local_{amount}": amount for amount in (60, 120, 300, 680, 980, 1280, 3280, 6480, 10000)}
MONTHLY_PACKS = {"coin98": 60, "coin99": 120, "coin100": 300}

class GameplayEconomy:
    METHODS = {
        "user.local_pay_test", "user.pay", "user.appstore_pay", "user.get_coin", "user.comment_gift", "user.get_activity_cd", "user.get_avatar_store",
        "user.check_in", "user.task_info", "user.task_done", "user.everyday_gift",
        "user.vip_gift", "user.vip_gift_buy", "user.full_energy",
        "user.full_fragment_energy", "user.expand_avatar_len", "user.expand_friend_len",
        "user.change_name", "user.sign_in", "user.sign_reward",
        "user.mystery_shop_info", "user.mystery_shop_buy", "user.mystery_shop_refresh_by_coin",
        "user.gamble", "user.get_gamble_reports", "user.fund",
        "user.get_pay_gift", "user.get_spend_fixed_gift", "user.get_pass_battle_gift", "user.get_consume_ranks",
        "user.medal_exchange", "user.get_reward_by_code", "user.exchange_key",
        "user.welfare_reward_info", "user.welfare_buy_dust", "user.welfare_get_reward",
        "user.roulette", "user.roulette_lottery", "user.get_lottery_activity", "user.exchange_activity_avatar",
        "user.get_box_key", "user.box_key_gift", "user.box_key_exchange", "user.box_gift_record",
        "user.groupon_info", "user.groupon_buy", "user.groupon_close", "user.rank_lv",
    }
    def __init__(self, store, config):
        self.store, self.config = store, (config or {}).get("cfg", config or {})

    def _op_key(self, method, params):
        action_id = params.get("actionID") or params.get("order_id") or params.get("orderID")
        return f"{method}:{action_id}" if isinstance(action_id, str) and action_id else None

    def _profile_result(self, profile, **extra):
        return {**copy.deepcopy(profile), **copy.deepcopy(extra)}

    def dispatch(self, uid, method, params):
        handlers = {
            "user.local_pay_test": self.local_pay_test,
            "user.pay": self.local_pay_test,
            "user.appstore_pay": self.local_pay_test,
            "user.get_coin": self.get_coin,
            "user.comment_gift": self.comment_gift,
            "user.get_activity_cd": self.get_activity_cd,
            "user.get_avatar_store": self.get_avatar_store,
            "user.check_in": self.check_in,
            "user.task_info": self.task_info,
            "user.task_done": self.task_done,
            "user.everyday_gift": self.everyday_gift,
            "user.vip_gift": self.vip_gift,
            "user.vip_gift_buy": self.vip_gift_buy,
            "user.full_energy": self.full_energy,
            "user.full_fragment_energy": self.full_fragment_energy,
            "user.expand_avatar_len": self.expand_avatar_len,
            "user.expand_friend_len": self.expand_friend_len,
            "user.change_name": self.change_name,
            "user.sign_in": self.sign_in,
            "user.sign_reward": self.sign_reward,
            "user.mystery_shop_info": self.mystery_shop_info,
            "user.mystery_shop_buy": self.mystery_shop_buy,
            "user.mystery_shop_refresh_by_coin": self.mystery_shop_refresh_by_coin,
            "user.gamble": self.gamble,
            "user.get_gamble_reports": self.get_gamble_reports,
            "user.fund": self.fund,
            "user.get_pay_gift": self.get_pay_gift,
            "user.get_consume_ranks": self.get_consume_ranks,
            "user.get_spend_fixed_gift": self.get_spend_fixed_gift,
            "user.get_pass_battle_gift": self.get_pass_battle_gift,
            "user.medal_exchange": self.medal_exchange,
            "user.get_reward_by_code": self.get_reward_by_code,
            "user.exchange_key": self.exchange_key,
            "user.welfare_reward_info": self.welfare_reward_info,
            "user.welfare_buy_dust": self.welfare_buy_dust,
            "user.welfare_get_reward": self.welfare_get_reward,
            "user.roulette": self.roulette,
            "user.roulette_lottery": self.roulette_lottery,
            "user.get_lottery_activity": self.get_lottery_activity,
            "user.exchange_activity_avatar": self.exchange_activity_avatar,
            "user.get_box_key": self.get_box_key,
            "user.box_key_gift": self.box_key_gift,
            "user.box_key_exchange": self.box_key_exchange,
            "user.box_gift_record": self.box_gift_record,
            "user.groupon_info": self.groupon_info,
            "user.groupon_buy": self.groupon_buy,
            "user.groupon_close": self.groupon_close,
            "user.rank_lv": self.rank_lv,
        }
        fn = handlers.get(method)
        if fn is None:
            raise GameplayFault("NotImplemented", "Economy method not reconstructed: " + method)
        return fn(str(uid), params)

    def local_pay_test(self, uid, params):
        pid = params.get("pid")
        if pid not in PACKS and pid not in MONTHLY_PACKS:
            raise GameplayFault("InvalidPayProduct", "Unknown local gift pack")
        base = PACKS.get(pid, MONTHLY_PACKS.get(pid))
        def mutate(p):
            attrs = p.setdefault("attrs", {})
            now = self._now()
            first = int(attrs.get("pay_first_gift", 0)) == 0
            granted = base * (2 if first else 1)
            p["coin"] = int(p.get("coin", 0)) + granted
            attrs.setdefault("fund", {"key":"1","money":0,"last_time":None})
            attrs["fund"]["money"] = int(attrs["fund"].get("money",0)) + base // 10
            attrs["pay_gift"] = int(attrs.get("pay_gift", 0)) + base // 10
            attrs.setdefault("pay_gift_count", 0)
            attrs["pay_first_gift"] = 2
            attrs["pay_first"] = 1
            attrs["pay_total"] = int(attrs.get("pay_total", 0)) + base // 10
            attrs["pay_money"] = int(attrs.get("pay_money", 0)) + base // 10
            attrs["pay_count"] = int(attrs.get("pay_count", 0)) + 1
            # The client stores these campaign counters in tenths of a coin:
            # its UI multiplies `money` by 10 when displaying the cumulative
            # click-to-gift amount. Credit only while the corresponding native
            # campaign window is open, in the same transaction as the gift.
            self._add_local_pay_progress(attrs, base // 10, now)
            if pid in MONTHLY_PACKS:
                card_days = 30
                card_cfg = (self.config.get("system_simple") or {}).get("mon_card", {}).get(pid, [])
                if isinstance(card_cfg, list) and len(card_cfg) > 2 and int(card_cfg[2]) > 0:
                    card_days = min(365, int(card_cfg[2]))
                cards = attrs.get("mon_card", {})
                if isinstance(cards, dict) and "$date" in cards:
                    cards = {"coin99": cards}
                elif not isinstance(cards, dict):
                    legacy = cards.get("$date", 0) if isinstance(cards, dict) else cards
                    cards = {"coin99": {"$date": int(legacy or 0)}} if legacy else {}
                attrs["mon_card"] = cards
                previous = cards.get(pid)
                if isinstance(previous, dict): previous = previous.get("$date", 0)
                try: previous = int(previous or 0)
                except (TypeError, ValueError): previous = 0
                cards[pid] = {"$date": max(now, previous) + card_days * 86400}
                attrs.setdefault("mon_card_claim_day", {})
            p["vip_exp"] = int(p.get("vip_exp", 0)) + base // 10
            vip = (self.config.get("vip") or {})
            next_lv = int(p.get("vip_lv", 0))
            while str(next_lv + 1) in vip and int(p["vip_exp"]) >= int(vip[str(next_lv + 1)].get("exp", 10**18)):
                next_lv += 1
            p["vip_lv"] = next_lv
            records = p.setdefault("records", {})
            pay = records.setdefault("pay", {})
            if not isinstance(pay, dict): pay = records["pay"] = {}
            pay["count"] = int(pay.get("count", 0)) + 1
            pay["coin"] = int(pay.get("coin", 0)) + base
            pay["last_day"] = game_day()
            p.setdefault("task", {})["pay_total"] = int(p.get("task", {}).get("pay_total", 0)) + base // 10
            return p, {"ok": True, "pid": pid, "base_coin": base, "granted_coin": granted, "first_double": first, "vip_lv": next_lv}
        key = self._op_key("user.local_pay_test", params)
        result, replayed = self.store.atomic_update(uid, mutate, key, {"pid": pid})
        return {**result, "replayed": replayed}

    def get_coin(self, uid, params):
        today = game_day()
        now = self._now()
        cards_cfg = (self.config.get("system_simple") or {}).get("mon_card", {})
        def mutate(p):
            attrs = p.setdefault("attrs", {})
            cards = attrs.get("mon_card", {})
            if isinstance(cards, dict) and "$date" in cards:
                cards = {"coin99": cards}
                attrs["mon_card"] = cards
            claims = attrs.setdefault("mon_card_claim_day", {})
            total = 0
            if isinstance(cards, dict):
                for sku, expiry in cards.items():
                    row = cards_cfg.get(sku) if isinstance(cards_cfg, dict) else None
                    if not isinstance(row, list) or len(row) < 3 or not isinstance(expiry, dict):
                        continue
                    try: expires = int(expiry.get("$date", 0))
                    except (TypeError, ValueError): continue
                    amount = int(row[1])
                    if amount > 0 and expires > now and claims.get(sku) != today:
                        total += amount
                        claims[sku] = today
            if total:
                p["coin"] = int(p.get("coin", 0)) + total
            return p, {"user": p, "gifts": []}
        result, _ = self.store.atomic_update(uid, mutate, None)
        return result

    def task_info(self, uid, params):
        p = self.store.profile(uid)
        attrs = p.setdefault("attrs", {})
        if "time_consumecoin" not in attrs: attrs["time_consumecoin"] = {"num": 0, "time": datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None)}
        return {"hero_score": int(p.get("score", 0)), "time_consumecoin": native_dates(attrs["time_consumecoin"])}

    def check_in(self, uid, params):
        key = self._op_key("user.check_in", params)
        today = game_day()
        config = self.config.get("check_in") or {}
        month = int(today[5:7])
        month_key = today[:7]
        rewards = config.get(str(month)) or config.get(month) or config.get("1") or config.get(1) or []
        if not rewards:
            raise GameplayFault("CheckInUnavailable", "This month's sign-in table is not configured")
        def mutate(p):
            attrs = p.setdefault("attrs", {})
            record = self.store._normalize_check_in_state(attrs.get("check_in"))
            attrs["check_in"] = record
            if record.get("month_key") != month_key:
                record.update(m=month, n=0, day=0, had_check=[0, 0], month_key=month_key)
            else:
                record["m"] = month
            last = record.get("last_day")
            if last != today:
                # A pending VIP second-half reward is tied to the prior sign-in
                # date. Close that row before advancing to today's row.
                if record.get("month_key") == month_key and last and record.get("had_check", [0, 0])[0]:
                    record["n"] = max(int(record.get("n", 0)), int(record.get("day", 0)))
                record["had_check"] = [0, 0]
                record["day"] = int(record.get("day", 0)) + 1
                record["last_day"] = today
            had = list(record.get("had_check", [0, 0]))
            while len(had) < 2: had.append(0)
            index = (int(record.get("day", 1)) - 1) % len(rewards)
            entry = rewards[index]
            reward = entry.get("reward", {"coin": 60 + 20 * index})
            if not isinstance(reward, dict): raise GameplayFault("InvalidReward", "Check-in reward is invalid")
            if params.get("is_vip") is True:
                vip_need = int(entry.get("vip_double", 0))
                if not had[0]:
                    raise GameplayFault("InvalidCheckInState", "Claim the regular sign-in reward before its VIP bonus")
                if had[1]:
                    raise GameplayFault("AlreadyCheckedIn", "Today's double sign-in reward has already been claimed")
                if vip_need <= 0 or int(p.get("vip_lv", 0)) < vip_need:
                    raise GameplayFault("VipLevelTooLow", "VIP level is too low for the double sign-in reward")
                # The native client makes a second user.check_in request for the
                # VIP bonus after the regular reward. Grant only that second half;
                # do not advance the day or monthly progress a second time.
                grant_reward(p, reward, {"cfg":self.config})
                had[1] = 1
                record["n"] = min(int(record.get("day", 1)), len(rewards))
            else:
                if had[0]: raise GameplayFault("AlreadyCheckedIn", "Today's sign-in reward has already been claimed")
                grant_reward(p, reward, {"cfg":self.config})
                had[0] = 1
                record["count"] = int(record.get("count", 0)) + 1
                # The native client holds the current row open while a VIP
                # second-half claim is available. Otherwise complete it now.
                if int(entry.get("vip_double", 0)) > 0:
                    record["n"] = max(0, min(int(record.get("day", 1)), len(rewards)) - 1)
                else:
                    had[1] = 1
                    record["n"] = min(int(record.get("day", 1)), len(rewards))
            record["had_check"] = had
            return p, self._profile_result(p, check_in=record)
        result, replayed = self.store.atomic_update(uid, mutate, key, {"is_vip": params.get("is_vip") is True, "day": today})
        result["check_in"] = result.get("check_in", result.get("attrs", {}).get("check_in", {}))
        result["replayed"] = replayed
        return result

    def everyday_gift(self, uid, params):
        try: index = int(params.get("gnum"))
        except (TypeError, ValueError): raise GameplayFault("InvalidTask", "Daily gift index is required")
        gifts = self.config.get("everyday_gift") or []
        if not isinstance(gifts, list) or not 0 <= index < len(gifts): raise GameplayFault("UnknownTask", "Daily gift is not configured")
        key = self._op_key("user.everyday_gift", params)
        def mutate(p):
            claimed = p.setdefault("records", {}).setdefault("everyday_gift", [])
            if index in claimed: raise GameplayFault("AlreadyClaimed", "Daily gift already claimed")
            reward = gifts[index]
            if not isinstance(reward, dict) or not reward: raise GameplayFault("InvalidReward", "Daily gift has no reward")
            gift_type = params.get("giftType")
            if gift_type and gift_type not in reward: raise GameplayFault("InvalidReward", "Requested reward does not match this daily gift")
            grant_reward(p, reward, {"cfg":self.config})
            claimed.append(index)
            return p, self._profile_result(p)
        result, replayed = self.store.atomic_update(uid, mutate, key, {"index": index, "giftType": params.get("giftType")})
        result["replayed"] = replayed
        return result

    def vip_gift(self, uid, params):
        try: index = int(params.get("gnum"))
        except (TypeError, ValueError): raise GameplayFault("InvalidGift", "VIP gift index is required")
        key = self._op_key("user.vip_gift", params)
        def mutate(p):
            level = str(int(p.get("vip_lv", 0)))
            vip = self.config.get("vip", {}).get(level, {})
            gift_list = vip.get("gift", [])
            if not isinstance(gift_list, list) or not 0 <= index < len(gift_list): raise GameplayFault("UnknownGift", "VIP reward is not configured")
            claimed = p.setdefault("records", {}).setdefault("vip_gift", [])
            if index in claimed: raise GameplayFault("AlreadyClaimed", "VIP reward already claimed")
            reward = gift_list[index]
            if not isinstance(reward, dict) or not reward: raise GameplayFault("InvalidReward", "VIP reward has no content")
            grant_reward(p, reward, {"cfg":self.config}); claimed.append(index)
            return p, self._profile_result(p)
        result, replayed = self.store.atomic_update(uid, mutate, key, {"index": index})
        result["replayed"] = replayed
        return result

    def vip_gift_buy(self, uid, params):
        try: level = int(params.get("vip_lv", params.get("gnum")))
        except (TypeError, ValueError): raise GameplayFault("InvalidGift", "VIP gift level is required")
        try: kind = int(params.get("type", 0))
        except (TypeError, ValueError): raise GameplayFault("InvalidGift", "VIP gift type is invalid")
        if kind not in (0, 1): raise GameplayFault("InvalidGift", "VIP gift type is invalid")
        key = self._op_key("user.vip_gift_buy", params)
        def mutate(p):
            current_level = int(p.get("vip_lv", 0))
            if level < 1 or level > current_level:
                raise GameplayFault("VipLevelRequired", "This VIP gift requires its VIP level")
            vip = self.config.get("vip", {}).get(str(level), {})
            try: gift_buy_limit = int(vip.get("gift_buy_limit", 1))
            except (TypeError, ValueError): raise GameplayFault("InvalidGift", "VIP gift limit is invalid")
            if gift_buy_limit != 1:
                raise GameplayFault("InvalidGift", "Only one purchase per VIP gift type is supported")
            field = "gift_buy" if kind == 0 else "gift_coin_buy"
            bundle = vip.get(field)
            if not isinstance(bundle, dict) or not isinstance(bundle.get("data"), dict) or not bundle["data"]:
                raise GameplayFault("UnknownGift", "VIP purchase is not configured")
            attr_name = "vip_gift_buy" if kind == 0 else "vip_gift_buy2"
            bought = p.setdefault("attrs", {}).setdefault(attr_name, [])
            if level in bought: raise GameplayFault("AlreadyClaimed", "VIP purchase already claimed")
            pay = bundle.get("pay") or []
            cost = int(pay[1]) if kind == 1 and isinstance(pay, list) and len(pay) > 1 else 0
            if cost < 0: raise GameplayFault("InvalidGift", "VIP gift cost is invalid")
            if int(p.get("coin", 0)) < cost: raise GameplayFault("InsufficientCoin", "Not enough coin")
            if cost:
                p["coin"] = int(p.get("coin", 0)) - cost
                self._record_coin_spend(p, cost)
            grant_reward(p, bundle["data"], self.config)
            bought.append(level)
            attrs = p.setdefault("attrs", {})
            return p, self._profile_result(p,
                vip_gift_buy=list(attrs.get("vip_gift_buy", [])),
                vip_gift_buy2=list(attrs.get("vip_gift_buy2", [])),
                attr_energy_extra=attrs.get("energy_extra", 0),
                avatars=p.get("avatars", {}), my_equips=p.get("my_equips", {}),
                avatar_soul=p.get("avatar_soul", {}), equip_soul=p.get("equip_soul", {}),
                dust=attrs.get("dust", [0,0,0,0]), dn_stone=attrs.get("dn_stone", 0),
                box_key=attrs.get("box_key", {}))
        result, replayed = self.store.atomic_update(uid, mutate, key, {"level": level, "type": kind})
        result["replayed"] = replayed
        return result

    def _simple(self, key, default):
        return (self.config.get("system_simple") or {}).get(key, default)

    def _now(self):
        return int(datetime.datetime.now(datetime.timezone.utc).timestamp())

    def _add_local_pay_progress(self, attrs, units, now):
        if type(units) is not int or units <= 0:
            return
        tasks = self.config.get("task") or {}
        for task_key in ("time_pay", "time_pay_loop"):
            definition = tasks.get(task_key) if isinstance(tasks, dict) else None
            if not isinstance(definition, dict):
                continue
            begin = self._timestamp_seconds(definition.get("begin_time"))
            end = self._timestamp_seconds(definition.get("end_time"))
            if begin is None or end is None or not begin <= now < end:
                continue
            state = attrs.get(task_key)
            if not isinstance(state, dict):
                state = {}
            marker = self._timestamp_seconds(state.get("time_key"))
            if marker != begin:
                # A new configured window starts with no carry-over. Keep the
                # durable lifetime counter for diagnostics/history only.
                lifetime = state.get("lifetime_money", 0)
                if type(lifetime) is not int or lifetime < 0:
                    lifetime = 0
                state = {"money": 0, "time_key": {"$date": begin}, "lifetime_money": lifetime, "claimed": 0}
            money = state.get("money", 0)
            if type(money) is not int or money < 0:
                money = 0
            state["money"] = money + units
            state["time_key"] = {"$date": begin}
            lifetime = state.get("lifetime_money", 0)
            if type(lifetime) is not int or lifetime < 0:
                lifetime = 0
            claimed = state.get("claimed", 0)
            if type(claimed) is not int or claimed < 0:
                claimed = 0
            state["lifetime_money"] = lifetime + units
            state["claimed"] = claimed
            attrs[task_key] = state

    @staticmethod
    def _timestamp_seconds(value):
        if isinstance(value, dict) and set(value) == {"$date"}:
            value = value["$date"]
        if isinstance(value, datetime.datetime):
            if value.tzinfo is None:
                value = value.replace(tzinfo=datetime.timezone.utc)
            return int(value.timestamp())
        if type(value) in (int, float):
            return int(value)
        return None

    @staticmethod
    def _record_coin_spend(profile, amount):
        amount=int(amount)
        if amount<=0: return
        attrs=profile.setdefault("attrs",{})
        attrs["spend_total"]=int(attrs.get("spend_total",0))+amount

    def get_activity_cd(self, uid, params):
        profile=self.store.profile(uid)
        attrs=profile.get("attrs",{})
        state=attrs.get("lottery_activity",{}) if isinstance(attrs.get("lottery_activity"),dict) else {}
        return {"time":attrs.get("activity_time",state.get("last_time"))}

    def get_avatar_store(self, uid, params):
        profile=self.store.profile(uid)
        owned={str(instance.get("aid",instance.get("id","")).split("|")[0]) for instance in profile.get("avatars",{}).values() if isinstance(instance,dict)}
        prior=profile.get("attrs",{}).get("avatar_store",{})
        table={str(aid):(int(prior.get(aid,1 if aid in owned else 0))) for aid in self.config.get("avatar",{})}
        return {"avatars":table}

    def comment_gift(self, uid, params):
        cfg=self._simple("pf_comment_lv",[1,{"coin":100}])
        reward=(cfg[1] if isinstance(cfg,list) and len(cfg)>1 and isinstance(cfg[1],dict) else {"coin":100})
        key=self._op_key("user.comment_gift",params)
        def mutate(p):
            attrs=p.setdefault("attrs",{})
            if attrs.get("comment_gift") is True:
                raise GameplayFault("AlreadyClaimed","Local comment reward was already claimed")
            grant_reward(p,reward,{"cfg":self.config})
            attrs["comment_gift"]=True
            resource=next(reversed(reward))
            target=attrs if resource in {"dust","sp","dn_stone","culture_book"} else p
            return p,int(target.get(resource,0))
        result,_=self.store.atomic_update(uid,mutate,key,{"local_comment_gift":True})
        return result

    def full_energy(self, uid, params):
        cfg = self._simple("energy_config", [100, 0, 5, 130, 1, 3, 0, 1, 0])
        key = self._op_key("user.full_energy", params)
        def mutate(p):
            attrs, records = p.setdefault("attrs", {}), p.setdefault("records", {})
            now = self._now(); state = energy_state(p, self.config, now)
            maximum, current = state["max"], state["current"]
            if current >= maximum: raise GameplayFault("EnergyFull", "Energy is already full")
            used = int(records.get("energy_times", 0)); vip = (self.config.get("vip") or {}).get(str(p.get("vip_lv", 0)), {})
            limit = int(cfg[5]) + int(vip.get("buy_energy", 0))
            if used >= limit: raise GameplayFault("EnergyPurchaseLimit", "Energy purchase limit reached")
            price = int(cfg[4]) + int(cfg[7]) * used
            if int(p.get("coin", 0)) < price: raise GameplayFault("InsufficientCoin", "Not enough coin")
            p["coin"] = int(p.get("coin", 0)) - price
            self._record_coin_spend(p,price)
            attrs["energy_extra"] = 0
            p["energy"] = {"$date": now - maximum * int(cfg[2]) * 60}
            records["energy_times"] = used + 1
            return p, {"coin": p["coin"], "attr_energy_extra": 0, "energy_times": used + 1, "energy": p["energy"]}
        result, replayed = self.store.atomic_update(uid, mutate, key, {"method": "full_energy"})
        result["replayed"] = replayed
        return result

    def full_fragment_energy(self, uid, params):
        cfg = self._simple("capacity_config", [12, 30, 1, 0, 3, 5, 100, 0])
        key = self._op_key("user.full_fragment_energy", params)
        def mutate(p):
            attrs, records = p.setdefault("attrs", {}), p.setdefault("records", {})
            now = self._now(); stamp_obj = attrs.get("fragment_energy", p.get("fragment_energy", {"$date": now}))
            stamp = stamp_obj.get("$date", now) if isinstance(stamp_obj, dict) else now
            current = min(int(cfg[0]) + int(attrs.get("fragment_energy_extra", 0)), max(0, int((now - int(stamp)) // max(1, int(cfg[1]) * 60))))
            if current >= int(cfg[0]): raise GameplayFault("FragmentEnergyFull", "Fragment energy is already full")
            used = int(records.get("fragment_energy_times", 0))
            if used >= int(cfg[4]): raise GameplayFault("FragmentEnergyPurchaseLimit", "Fragment energy purchase limit reached")
            price = int(cfg[6]) + used * int(cfg[5])
            if int(p.get("coin", 0)) < price: raise GameplayFault("InsufficientCoin", "Not enough coin")
            p["coin"] = int(p.get("coin", 0)) - price
            self._record_coin_spend(p,price)
            attrs["fragment_energy_extra"] = 0
            attrs["fragment_energy"] = {"$date": now - int(cfg[0]) * int(cfg[1]) * 60}
            records["fragment_energy_times"] = used + 1
            p["fragment_energy"] = attrs["fragment_energy"]
            return p, {"coin": p["coin"], "attr_fragment_energy_extra": 0, "fragment_energy_times": used + 1, "fragment_energy": attrs["fragment_energy"]}
        result, replayed = self.store.atomic_update(uid, mutate, key, {"method": "full_fragment_energy"})
        result["replayed"] = replayed
        return result

    def _expand_capacity(self, uid, params, kind):
        key = "avatar_len" if kind == "avatar" else "friend_len"
        config_key = key
        cfg = self._simple(config_key, [0, 20, 100, 1000 if kind == "avatar" else 100])
        method = "user.expand_avatar_len" if kind == "avatar" else "user.expand_friend_len"
        op = self._op_key(method, params)
        def mutate(p):
            attrs = p.setdefault("attrs", {})
            current = int(attrs.get(key, 0))
            supplied = params.get(key)
            if supplied is not None and int(supplied) != current: raise GameplayFault("StaleCapacity", "Capacity changed; refresh and retry")
            increment, cost, maximum = int(cfg[1]), int(cfg[2]), int(cfg[3])
            vip_level = int(p.get("vip_lv", 0))
            vip_rows = self.config.get("vip", {}) if isinstance(self.config, dict) else {}
            vip_row = vip_rows.get(str(vip_level), {}) if isinstance(vip_rows, dict) else {}
            maximum += int(vip_row.get("avatar_len_add", 0)) if kind == "avatar" and isinstance(vip_row, dict) else 0
            maximum = max(maximum, current)
            if current >= maximum: raise GameplayFault("CapacityMax", "Capacity is already at its configured maximum")
            if p.get("coin", 0) < cost: raise GameplayFault("InsufficientCoin", "Not enough coin")
            p["coin"] = int(p["coin"]) - cost
            self._record_coin_spend(p,cost)
            attrs[key] = min(maximum, current + increment)
            return p, {"attrs": attrs, "coin": p["coin"], "capacity": attrs[key]}
        result, replayed = self.store.atomic_update(uid, mutate, op, {"capacity": kind, "current": params.get(key)})
        result["replayed"] = replayed
        return result

    def expand_avatar_len(self, uid, params): return self._expand_capacity(uid, params, "avatar")
    def expand_friend_len(self, uid, params): return self._expand_capacity(uid, params, "friend")

    def change_name(self, uid, params):
        name = params.get("name")
        if not isinstance(name, str) or not name.strip() or len(name.strip()) > 18: raise GameplayFault("InvalidName", "Name must be 1 to 18 characters")
        cfg = self._simple("rename", 0)
        key = self._op_key("user.change_name", params)
        def mutate(p):
            cost = int(cfg)
            if int(p.get("coin", 0)) < cost: raise GameplayFault("InsufficientCoin", "Not enough coin")
            p["coin"] = int(p.get("coin", 0)) - cost
            self._record_coin_spend(p,cost)
            p["name"] = name.strip()
            return p, True
        result, replayed = self.store.atomic_update(uid, mutate, key, {"name": name.strip()})
        result["replayed"] = replayed
        return result

    def _activity_sign_config(self):
        configured=(self.config.get("ploy_system_simple") or {}).get("sign_in")
        avatars=self.config.get("avatar",{})
        if not isinstance(avatars,dict): avatars={}
        def has_preview_sequence(prefix, count):
            if not isinstance(prefix,str) or not prefix.startswith("A_1") or not prefix.endswith("_"): return False
            for index in range(1,count+2):
                row=avatars.get(prefix+str(index))
                if not isinstance(row,dict) or row.get("id")!=prefix+str(index): return False
                resource=row.get("res")
                if not isinstance(resource,str) or not isinstance(avatars.get(resource),dict): return False
            return True
        if configured:
            if not isinstance(configured,dict):
                raise GameplayFault("SignUnavailable","Activity sign-in configuration is invalid")
            for row in configured.values():
                if not isinstance(row,dict):
                    raise GameplayFault("SignUnavailable","Activity sign-in configuration is invalid")
                count=row.get("num",4)
                if type(count) is not int or not 1<=count<=31 or not has_preview_sequence(row.get("mcid"),count):
                    raise GameplayFault("SignUnavailable","Activity sign-in preview templates are incomplete")
            return configured
        # A fallback is safe only when the configuration already contains a
        # complete native family, including the extra preview shown after the
        # final sign-in while the player waits to claim the cycle reward.
        prefixes=sorted({key.rsplit("_",1)[0]+"_" for key in avatars if isinstance(key,str) and key.startswith("A_1") and key.rsplit("_",1)[-1].isdigit()})
        for prefix in prefixes:
            if has_preview_sequence(prefix,4):
                return {"1":{"num":4,"mcid":prefix,"gift":{"gold":100,"coin":100}}}
        raise GameplayFault("SignUnavailable","Activity sign-in preview templates are missing")

    def _sign_response(self, p, sign_in, gift_dict=None):
        attrs = p.get("attrs", {})
        result = self._profile_result(p, sign_in=copy.deepcopy(sign_in), attr_energy_extra=attrs.get("energy_extra", 0),
            dn_stone=attrs.get("dn_stone", 0), dust=attrs.get("dust", [0,0,0,0]), box_key=attrs.get("box_key", 0),
            culture_book=attrs.get("culture_book", 0), fragment_energy=attrs.get("fragment_energy", p.get("fragment_energy")),
            fragment_energy_extra=attrs.get("fragment_energy_extra", 0), energy=p.get("energy"))
        if gift_dict is not None: result["gift_dict"] = gift_dict
        return result

    def sign_in(self, uid, params):
        key = self._op_key("user.sign_in", params)
        today = game_day()
        def mutate(p):
            attrs = p.setdefault("attrs", {})
            state = attrs.setdefault("sign_in", {"k":1,"n":0,"t":None})
            levels = self._activity_sign_config()
            ordered = sorted(levels, key=lambda value: int(value))
            current_k = str(state.get("k", ordered[0]))
            if current_k not in levels: current_k = ordered[0]
            previous = state.get("last_day")
            if previous == today: raise GameplayFault("AlreadySignedIn", "Activity sign-in already used today")
            if previous:
                try:
                    old = datetime.date.fromisoformat(previous); new = datetime.date.fromisoformat(today)
                    if (new-old).days > 1: state["n"] = 0
                except ValueError: state["n"] = 0
            entry = levels[current_k]
            count = int(entry.get("num", 4))
            if int(state.get("n", 0)) >= count: raise GameplayFault("SignRewardRequired", "Claim the cycle reward before signing in again")
            state["n"] = int(state.get("n", 0)) + 1
            state["k"] = int(current_k); state["last_day"] = today; state["t"] = {"$date": self._now()}
            return p, self._sign_response(p, state)
        result, replayed = self.store.atomic_update(uid, mutate, key, {"day": today})
        result["replayed"] = replayed
        return result

    def sign_reward(self, uid, params):
        key = self._op_key("user.sign_reward", params)
        today = game_day()
        def mutate(p):
            attrs = p.setdefault("attrs", {})
            state = attrs.setdefault("sign_in", {"k":1,"n":0,"t":None})
            levels = self._activity_sign_config(); current_k = str(state.get("k", "1"))
            entry = levels.get(current_k, levels.get(str(min(levels, key=lambda x:int(x))), {"num":4}))
            if int(state.get("n", 0)) < int(entry.get("num", 4)):
                raise GameplayFault("SignCycleIncomplete", "Complete all sign-in days before claiming the cycle reward")
            reward = entry.get("gift", {"gold":100,"coin":100})
            if not isinstance(reward, dict) or not reward: raise GameplayFault("InvalidReward", "Activity sign reward is empty")
            grant_reward(p, reward, self.config)
            state["k"] = int(current_k); state["n"] = 0; state["last_reward_day"] = today
            return p, self._sign_response(p, state, copy.deepcopy(reward))
        result, replayed = self.store.atomic_update(uid, mutate, key, {"day": today})
        result["replayed"] = replayed
        return result

    def _shop_type(self, params):
        kind = params.get("s_type")
        if kind not in {"normal", "advanced", "super"}: raise GameplayFault("InvalidShop", "Unknown soul shop type")
        shops = self.config.get("mystery_shop") or {}
        if kind not in shops: raise GameplayFault("ShopUnavailable", "Soul shop table is not configured")
        return kind, shops[kind]

    def _fresh_shop_sheet(self, uid, kind, old=None):
        offers = (self.config.get("mystery_shop_offers") or {}).get(kind) or []
        if not offers: raise GameplayFault("ShopUnavailable", "Soul shop inventory is empty")
        cycle = int(old.get("refresh_seq", 0)) if isinstance(old, dict) else 0
        seed = int.from_bytes(hashlib.sha256(f"{uid}:{kind}:{cycle}".encode()).digest()[:8], "big")
        rng = random.Random(seed); indices = list(range(len(offers))); rng.shuffle(indices)
        chosen = indices[:min(6, len(indices))]
        return {"t": self._now() * 1000, "items": [copy.deepcopy(offers[i]) for i in chosen], "b": [], "refresh_seq": cycle}

    def _apply_shop_award(self, p, data):
        if not isinstance(data, dict) or len(data) != 1: raise GameplayFault("InvalidReward", "Shop item must contain exactly one reward")
        kind, amount = next(iter(data.items()))
        if kind in {"avatar_soul", "equip_soul"}:
            if not isinstance(amount, dict) or len(amount) != 1: raise GameplayFault("InvalidReward", "Soul reward must name exactly one item")
            target = p.setdefault(kind, {})
            for item_id, count in amount.items():
                if type(count) is not int or count <= 0: raise GameplayFault("InvalidReward", "Soul reward quantity must be positive")
                target[str(item_id)] = int(target.get(str(item_id), 0)) + count
        elif kind == "avatar":
            grant_reward(p, {"heroes": [{"aid": k, "num": int(v)} for k,v in amount.items()]}, {"cfg": self.config})
        elif kind == "equip":
            # Keep native eid instances; this helper also checks that the ID is configured.
            grant_reward(p, {"items": [{"eid": k, "num": int(v)} for k,v in amount.items()]}, {"cfg": self.config})
        else:
            grant_reward(p, {kind: amount}, {"cfg": self.config})

    def mystery_shop_info(self, uid, params):
        kind, cfg = self._shop_type(params)
        result, _ = self.store.atomic_update(uid, lambda p: self._shop_info_mutation(p, uid, kind, cfg))
        return result

    def _shop_info_mutation(self, p, uid, kind, cfg):
        attrs = p.setdefault("attrs", {}); shops = attrs.setdefault("mystery_shop", {})
        sheet = shops.get(kind)
        interval = max(1, int(cfg.get("refresh_interval", 120))) * 60
        if not isinstance(sheet, dict) or self._now() * 1000 - int(sheet.get("t", 0)) >= interval * 1000:
            sheet = self._fresh_shop_sheet(uid, kind, sheet); shops[kind] = sheet
        return p, {"s_type": kind, "t": sheet["t"], "items": copy.deepcopy(sheet["items"]), "b": list(sheet.get("b", []))}

    def mystery_shop_refresh_by_coin(self, uid, params):
        kind, cfg = self._shop_type(params); key = self._op_key("user.mystery_shop_refresh_by_coin", params)
        price = int(cfg.get("refresh_price", 0))
        def mutate(p):
            if price <= 0: raise GameplayFault("InvalidShop", "Shop refresh price is not configured")
            if int(p.get("coin", 0)) < price: raise GameplayFault("InsufficientCoin", "Not enough coin")
            p["coin"] = int(p.get("coin", 0)) - price
            self._record_coin_spend(p,price)
            attrs = p.setdefault("attrs", {}); shops = attrs.setdefault("mystery_shop", {})
            old = shops.get(kind, {}); old["refresh_seq"] = int(old.get("refresh_seq", 0)) + 1
            sheet = self._fresh_shop_sheet(uid, kind, old); shops[kind] = sheet
            return p, {**copy.deepcopy(p), "t":sheet["t"], "items":copy.deepcopy(sheet["items"]), "b":[]}
        result, replayed = self.store.atomic_update(uid, mutate, key, {"s_type":kind})
        result["replayed"] = replayed
        return result

    def mystery_shop_buy(self, uid, params):
        kind, cfg = self._shop_type(params); key = self._op_key("user.mystery_shop_buy", params)
        try: index = int(params.get("index")); requested_time = int(params.get("time"))
        except (TypeError, ValueError): raise GameplayFault("InvalidShopItem", "Shop item index and stock timestamp are required")
        def mutate(p):
            shops = p.setdefault("attrs", {}).setdefault("mystery_shop", {}); sheet = shops.get(kind)
            if not isinstance(sheet, dict) or int(sheet.get("t", -1)) != requested_time: raise GameplayFault("StaleShop", "Shop stock changed; refresh it")
            items = sheet.get("items", []); bought = sheet.setdefault("b", [])
            if not 0 <= index < len(items): raise GameplayFault("InvalidShopItem", "Shop item index is out of range")
            if index in bought: raise GameplayFault("AlreadyBought", "This shop item has already been purchased")
            row = items[index]
            if not isinstance(row, list) or len(row) != 2 or not isinstance(row[0], dict) or not isinstance(row[1], dict) or len(row[1]) != 1:
                raise GameplayFault("InvalidShopItem", "Shop item data is malformed")
            currency, price = next(iter(row[1].items()))
            if currency not in {"coin", "gold"} or type(price) is not int or price <= 0: raise GameplayFault("InvalidShopItem", "Shop item price is invalid")
            if int(p.get(currency, 0)) < price: raise GameplayFault("InsufficientResource", "Not enough " + currency)
            p[currency] = int(p.get(currency, 0)) - price
            if currency=="coin": self._record_coin_spend(p,price)
            self._apply_shop_award(p, row[0]); bought.append(index)
            return p, {**copy.deepcopy(p), "b":list(bought), "t":sheet["t"], "items":copy.deepcopy(items)}
        result, replayed = self.store.atomic_update(uid, mutate, key, {"s_type":kind,"index":index,"time":requested_time})
        result["replayed"] = replayed
        return result

    def gamble(self, uid, params):
        gamble = (self.config.get("ploy_system_simple") or {}).get("gamble") or {}
        tiers = gamble.get("return_coin") or []
        if not isinstance(tiers, list) or len(tiers) < 2:
            raise GameplayFault("GambleUnavailable", "Gamble schedule is not configured")
        key = self._op_key("user.gamble", params)
        def mutate(p):
            attrs = p.setdefault("attrs", {})
            state = int(attrs.get("gamble_index", 0))
            # The client increments by one after every accepted click; tier 0 is the
            # display baseline and tiers 1..N are the actual attempts.
            if state + 1 >= len(tiers):
                raise GameplayFault("GambleLimit", "All configured gamble attempts have been used")
            row = tiers[state + 1]
            if not isinstance(row, list) or len(row) < 2:
                raise GameplayFault("InvalidGamble", "Gamble tier must contain cost and payout")
            cost, payout = int(row[0]), int(row[1])
            if cost < 0 or payout < 0:
                raise GameplayFault("InvalidGamble", "Gamble cost and payout cannot be negative")
            if int(p.get("coin", 0)) < cost:
                raise GameplayFault("InsufficientCoin", "Not enough coin")
            p["coin"] = int(p.get("coin", 0)) - cost + payout
            self._record_coin_spend(p,cost)
            attrs["gamble_index"] = state + 1
            records = p.setdefault("records", {})
            reports = records.setdefault("gamble_reports", [])
            reports.append({"attempt": state + 1, "cost": cost, "payout": payout, "time": {"$date": self._now()}})
            del reports[:-20]
            return p, int(p["coin"])
        result, replayed = self.store.atomic_update(uid, mutate, key, {"method": "gamble"})
        return result

    def fund(self, uid, params):
        config = (self.config.get("ploy_system_simple") or {}).get("fund") or {}
        reward_cfg = config.get("return")
        if not isinstance(reward_cfg, list) or len(reward_cfg) < 3:
            raise GameplayFault("FundUnavailable", "Fund return schedule is not configured")
        key = self._op_key("user.fund", params)
        def mutate(p):
            attrs = p.setdefault("attrs", {})
            state = attrs.setdefault("fund", {"key":"1","money":0,"last_time":None})
            money = int(state.get("money", 0))
            if money < int(reward_cfg[0]): raise GameplayFault("FundNotActive", "Fund has not accumulated enough value")
            now = self._now(); last = state.get("last_time")
            if isinstance(last, dict): last = int(last.get("$date", 0))
            if last and game_day(now) == game_day(last): raise GameplayFault("FundAlreadyClaimed", "Today's fund return was already claimed")
            amount = min(int(reward_cfg[2]), int(money * 10 * float(reward_cfg[1])))
            if amount <= 0: raise GameplayFault("FundNoReward", "Fund return is zero")
            p["coin"] = int(p.get("coin", 0)) + amount
            state["last_time"] = {"$date":now}
            return p, int(p["coin"])
        result, replayed = self.store.atomic_update(uid, mutate, key, {"method":"fund","day":game_day()})
        return result

    def _economy_profile_response(self, profile, **extra):
        response = copy.deepcopy(profile)
        for key in ("attrs", "avatars", "my_equips", "avatar_soul", "equip_soul", "coin", "gold", "medal", "score", "mark", "energy", "exp", "lv"):
            if key not in response:
                response[key] = copy.deepcopy(profile.get(key, {} if key in {"attrs", "avatars", "my_equips", "avatar_soul", "equip_soul"} else 0))
        response.update(copy.deepcopy(extra))
        return response

    def get_pay_gift(self, uid, params):
        config = self._simple("pay_gift", [6, {"coin": 120}, 30])
        if not isinstance(config, list) or len(config) < 2 or not isinstance(config[1], dict):
            raise GameplayFault("PayGiftUnavailable", "Payment gift schedule is invalid")
        try: index = int(params.get("gnum", 0))
        except (TypeError, ValueError): raise GameplayFault("InvalidGift", "Payment gift index is invalid")
        if index not in (0, 1): raise GameplayFault("InvalidGift", "Unknown payment gift")
        key = self._op_key("user.get_pay_gift", params)
        def mutate(p):
            attrs = p.setdefault("attrs", {}); count = int(attrs.get("pay_gift_count", 0))
            if count >= 2: raise GameplayFault("AlreadyClaimed", "All payment gift stages have been claimed")
            threshold = int(config[0] if count == 0 else (config[2] if len(config) > 2 else config[0]))
            if int(attrs.get("pay_gift", 0)) < threshold: raise GameplayFault("PayGiftLocked", "Payment total has not reached this reward")
            reward = dict(config[1]); grant_reward(p, reward, {"cfg":self.config})
            attrs["pay_gift_count"] = count + 1
            # Keep the server's plural field for existing consumers and expose
            # the native ItemTaskAward contract (`data.gift`) as an alias.
            # Both names describe the same already-granted reward; neither
            # changes the atomic/idempotent mutation.
            return p, self._economy_profile_response(
                p, rewards=copy.deepcopy(reward), gift=copy.deepcopy(reward)
            )
        result, replayed = self.store.atomic_update(uid, mutate, key, {"gnum":index,"type":params.get("type"),"giftType":params.get("giftType")})
        result["replayed"] = replayed
        return result

    def get_consume_ranks(self, uid, params):
        profile=self.store.profile(uid); attrs=profile.setdefault("attrs",{})
        spend=attrs.setdefault("spend_rank",{"fixed_gift":[]})
        return {"my_coin_num":int(attrs.get("spend_total",0)),"rank_list":[],
            "fixed_gift":list(spend.get("fixed_gift",[]))}

    def get_spend_fixed_gift(self, uid, params):
        table=(self.config.get("ploy_system_simple") or {}).get("spend_rank",{}).get("fixed_gift") or {}
        try: requested=int(params.get("key"))
        except (TypeError,ValueError): raise GameplayFault("InvalidGift", "Spend reward key is required")
        row=table.get(str(requested),table.get(requested))
        if not isinstance(row,dict): raise GameplayFault("UnknownGift", "Spend reward is not configured")
        key=self._op_key("user.get_spend_fixed_gift",params)
        def mutate(p):
            attrs=p.setdefault("attrs",{}); paid=int(attrs.get("spend_total",0))
            spend=attrs.setdefault("spend_rank",{"fixed_gift":[]});claimed=spend.setdefault("fixed_gift",[])
            if paid<requested: raise GameplayFault("SpendRewardLocked", "Coin spending has not reached this reward")
            if requested in [int(x) for x in claimed]: raise GameplayFault("AlreadyClaimed", "Spend reward already claimed")
            reward=row
            grant_reward(p,reward,{"cfg":self.config});claimed.append(requested)
            return p,self._economy_profile_response(p,attrs=attrs)
        result,replayed=self.store.atomic_update(uid,mutate,key,{"key":requested})
        result["replayed"]=replayed
        return result

    def get_pass_battle_gift(self, uid, params):
        bid = str(params.get("bid", "")); diff = int(params.get("diff", 0))
        if not bid or diff not in (0,1,-1): raise GameplayFault("InvalidStage", "Stage or difficulty is invalid")
        tiers = self.config.get("pass_battle_gift") or {}
        row = (tiers.get(str(diff)) or {}).get(bid)
        if not isinstance(row, dict): raise GameplayFault("UnknownStage", "No stage-clear reward is configured")
        is_activity = diff == -1
        chapter_table = self.config.get("battle_ploy" if is_activity else "battle_main", {})
        chapter = chapter_table.get(bid) if isinstance(chapter_table, dict) else None
        chapter_count = 0
        if isinstance(chapter, dict):
            try: chapter_count = int(chapter.get("combat", 0))
            except (TypeError, ValueError): chapter_count = 0
        if chapter_count < 1:
            # Keep compatibility with older direct stage-id claims. Native
            # chapter panels send M_001 / P_001, so new configs use the branch
            # below and are checked against their configured chapter length.
            chapter = None
        key = self._op_key("user.get_pass_battle_gift", params)
        def mutate(p):
            mode = "normal" if diff == 0 else "hard" if diff == 1 else "ploy"
            score_bucket = p.setdefault("combat_score", {}).setdefault(mode, {})
            score_entry = score_bucket.get(bid)
            if chapter is not None:
                # The native chapter reward button is enabled only after every
                # configured stage in that chapter has three stars. The
                # chapter score row is [claim_flag, per_stage_stars].
                if not isinstance(score_entry, list) or len(score_entry) < 2 or not isinstance(score_entry[1], list):
                    raise GameplayFault("StageRewardLocked", "Complete every stage in this chapter with three stars")
                if str(score_entry[0]) == "1":
                    raise GameplayFault("AlreadyClaimed", "Chapter reward already claimed")
                stars = score_entry[1]
                if len(stars) < chapter_count:
                    raise GameplayFault("StageRewardLocked", "Complete every stage in this chapter with three stars")
                try:
                    total_stars = sum(max(0, min(3, int(value))) for value in stars[:chapter_count])
                except (TypeError, ValueError, OverflowError):
                    raise GameplayFault("InvalidProfile", "Chapter star progress is malformed")
                required_stars = max(chapter_count * 3, int(row.get("need_star", 0)))
                if total_stars < required_stars:
                    raise GameplayFault("StageRewardLocked", "Complete every stage in this chapter with three stars")

                # Match the native combat_score marker as well as the durable
                # record list, so the panel immediately disables its button.
                score_bucket[bid] = ["1", list(stars)]
            else:
                try:
                    score = int(score_entry if score_entry is not None else 0)
                except (TypeError, ValueError, OverflowError):
                    raise GameplayFault("InvalidProfile", "Stage star progress is malformed")
                if score < int(row.get("need_star", 3)):
                    raise GameplayFault("StageRewardLocked", "Stage star requirement has not been met")
            claimed = p.setdefault("records", {}).setdefault("pass_battle_gift", {}).setdefault(str(diff), [])
            if bid in claimed: raise GameplayFault("AlreadyClaimed", "Stage reward already claimed")
            reward = row.get("gift")
            grant_reward(p, reward, {"cfg":self.config}); claimed.append(bid)
            return p, self._economy_profile_response(p, records=p.get("records", {}))
        result, replayed = self.store.atomic_update(uid, mutate, key, {"bid":bid,"diff":diff})
        result["replayed"] = replayed
        return result

    def medal_exchange(self, uid, params):
        kind = params.get("exch_type"); item_id = params.get("exch_id")
        table = self.config.get("medal_exchange") or {}
        row = (table.get(str(kind)) or {}).get(str(item_id))
        if not isinstance(row, dict): raise GameplayFault("UnknownExchange", "Medal exchange item is not configured")
        cost = int(row.get("medal", -1))
        if type(params.get("need_medal")) is not int or int(params["need_medal"]) != cost:
            raise GameplayFault("InvalidExchangePrice", "Exchange price does not match the configured price")
        key = self._op_key("user.medal_exchange", params)
        def mutate(p):
            if int(p.get("medal", 0)) < cost: raise GameplayFault("InsufficientMedal", "Not enough medals")
            reward = row.get("gift")
            if not isinstance(reward, dict): raise GameplayFault("InvalidReward", "Exchange reward is invalid")
            p["medal"] = int(p.get("medal",0)) - cost
            grant_reward(p, reward, {"cfg":self.config})
            return p, self._economy_profile_response(p)
        result, replayed = self.store.atomic_update(uid, mutate, key, {"kind":kind,"id":item_id,"need_medal":cost})
        result["replayed"] = replayed
        return result

    def _redeem(self, uid, params, method):
        raw = params.get("code", params.get("key", "")); code = str(raw).strip().upper()
        codes = self.config.get("redeem_codes") or {}
        reward = codes.get(code)
        if not isinstance(reward, dict): raise GameplayFault("InvalidCode", "This local code is invalid or expired")
        key = self._op_key(method, params)
        def mutate(p):
            redeemed = p.setdefault("records", {}).setdefault("redeemed_codes", [])
            if code in redeemed: raise GameplayFault("CodeAlreadyUsed", "This code has already been redeemed")
            grant_reward(p, reward, {"cfg":self.config}); redeemed.append(code)
            data = self._economy_profile_response(p, rewards=copy.deepcopy(reward), info="兑换成功")
            return p, data
        result, replayed = self.store.atomic_update(uid, mutate, key, {"code":code})
        result["replayed"] = replayed
        return result

    def get_reward_by_code(self, uid, params): return self._redeem(uid, params, "user.get_reward_by_code")
    def exchange_key(self, uid, params): return self._redeem(uid, params, "user.exchange_key")

    def welfare_reward_info(self, uid, params):
        config = (self.config.get("ploy_system_simple") or {}).get("welfare")
        if not isinstance(config, dict): raise GameplayFault("WelfareUnavailable", "Welfare activity is not configured")
        p = self.store.profile(uid); records = p.setdefault("records", {})
        state = records.get("welfare", {}); count = len(config.get("reward", []))
        # The native screen requests this snapshot on entry. Treat the daily
        # claim flags as empty after midnight without mutating the profile on
        # this read RPC; the claim RPC performs the reset.
        if state.get("day") != game_day():
            state = {"had_reward": [0] * count, "coin_times": 0}
        info = [[int(x) for x in range(int(config.get("number_pool", 8)))] for _ in range(count)]
        return {"info":info,"welfare_times":list(records.get("welfare_times", [0]*count)),"had_reward":list(state.get("had_reward",[0]*count)),
            "coin_times":int(state.get("coin_times",0)),"number":-1,"had_play":1,"welfare_info":[],"flag":0}

    def welfare_buy_dust(self, uid, params):
        config = (self.config.get("ploy_system_simple") or {}).get("welfare") or {}
        try: color=int(params.get("color")); flag=int(params.get("flag",0))
        except (TypeError,ValueError): raise GameplayFault("InvalidWelfare", "Color or draw count is invalid")
        prices=config.get("dust_price",[])
        # Native PanelActivityWelfare sends flag=-1 for the button explicitly
        # labelled free; 0 is the paid single draw and 1 is the paid ten draw.
        if not 0<=color<len(prices) or flag not in (-1,0,1): raise GameplayFault("InvalidWelfare", "Welfare tier is invalid")
        price_index = 0 if flag == -1 else flag
        try:
            entry=prices[color][price_index]
            amount_key,costs=next(iter(entry.items()))
            currency,price=next(iter(costs.items()))
        except (IndexError, StopIteration, AttributeError, TypeError, ValueError):
            raise GameplayFault("InvalidWelfare", "Welfare cost table is invalid")
        dust_amount=int(amount_key)
        if currency not in {"gold","coin"} or type(price) is not int or price<0: raise GameplayFault("InvalidWelfare", "Welfare cost table is invalid")
        key=self._op_key("user.welfare_buy_dust",params)
        def mutate(p):
            attrs=p.setdefault("attrs",{}); balance=attrs.setdefault("dust",[0,0,0,0])
            used=p.setdefault("records",{}).setdefault("welfare_times",[0]*len(prices))
            if not isinstance(used,list): raise GameplayFault("InvalidWelfare", "Welfare usage record is invalid")
            while len(used)<len(prices): used.append(0)
            rec=p["records"].setdefault("welfare",{})
            today=game_day()
            if rec.get("day")!=today:
                rec.update(day=today,had_reward=[0]*len(prices),coin_times=0)
            free_limit=config.get("free_times",[0]*len(prices))
            free_limit=int(free_limit[color]) if isinstance(free_limit,list) and color<len(free_limit) else 0
            free = flag == -1
            if free and (free_limit<=0 or int(used[color])>=free_limit):
                raise GameplayFault("WelfareFreeUsed", "This free welfare draw has already been used")
            if not free and flag not in (0,1): raise GameplayFault("InvalidWelfare", "Welfare tier is invalid")
            rec.setdefault("coin_times", 0)
            if not free and int(p.get(currency,0))<price: raise GameplayFault("InsufficientResource", "Not enough "+currency)
            if not free:
                p[currency]=int(p.get(currency,0))-price
                if currency=="coin": self._record_coin_spend(p,price)
                rec["coin_times"]=int(rec.get("coin_times",0))+1
            balance[color]=int(balance[color])+dust_amount; used[color]=int(used[color])+dust_amount
            welfare_info={"pos_y":color,"pos_x":0,"num":dust_amount}
            out=self._economy_profile_response(p, welfare_times=used,coin_times=rec["coin_times"],dust=balance,welfare_info=welfare_info,flag=0,vip_exp=p.get("vip_exp",0),vip_lv=p.get("vip_lv",0))
            return p,out
        result,replayed=self.store.atomic_update(uid,mutate,key,{"color":color,"flag":flag})
        result["replayed"]=replayed;return result

    def welfare_get_reward(self, uid, params):
        config=(self.config.get("ploy_system_simple") or {}).get("welfare") or {}
        try: color=int(params.get("color"))
        except (TypeError,ValueError): raise GameplayFault("InvalidWelfare", "Welfare color is invalid")
        rewards=config.get("reward",[])
        if not 0<=color<len(rewards): raise GameplayFault("InvalidWelfare", "Welfare color is not configured")
        key=self._op_key("user.welfare_get_reward",params)
        def mutate(p):
            attrs=p.setdefault("attrs",{}); dust=attrs.setdefault("dust",[0,0,0,0]); cost=int(config.get("draw_dust",1))
            records=p.setdefault("records",{}); state=records.setdefault("welfare",{}); today=game_day()
            if state.get("day")!=today: state.update(day=today,free_used=[0]*len(rewards),had_reward=[0]*len(rewards),coin_times=0)
            if state.setdefault("had_reward",[0]*len(rewards))[color]: raise GameplayFault("AlreadyClaimed", "This welfare reward was already claimed today")
            if int(dust[color])<cost: raise GameplayFault("InsufficientDust", "Collect enough matching dust before drawing")
            dust[color]-=cost; prize=rewards[color]; grant_reward(p,prize,{"cfg":self.config})
            number=int(state.get("draw_index",0))%int(config.get("number_pool",8)); state["draw_index"]=int(state.get("draw_index",0))+1
            state.setdefault("had_reward",[0]*len(rewards))[color]=1
            response=self._economy_profile_response(p,reward=copy.deepcopy(prize),had_reward=state["had_reward"],
                coin=p.get("coin",0),gold=p.get("gold",0),medal=p.get("medal",0),score=p.get("score",0),mark=p.get("mark",0),
                welfare_times=records.get("welfare_times",[0]*len(rewards)),coin_times=state.get("coin_times",0),number=number,had_play=1)
            return p,response
        result,replayed=self.store.atomic_update(uid,mutate,key,{"color":color})
        result["replayed"]=replayed;return result

    def _roulette_cfg(self):
        config=(self.config.get("ploy_system_simple") or {}).get("roulette")
        if not isinstance(config,dict): raise GameplayFault("RouletteUnavailable", "Roulette activity is not configured")
        return config

    def _validate_roulette_access(self, profile, config):
        """Apply the same time/level gate as PanelCenterActivity.checkClose_roulette."""
        start=self._timestamp_seconds(config.get("start_time"))
        end=self._timestamp_seconds(config.get("end_time"))
        if start is None or end is None or end < start:
            raise GameplayFault("RouletteUnavailable", "Roulette activity dates are invalid")
        now=self._now()
        if now < start or now > end:
            raise GameplayFault("RouletteClosed", "Roulette activity is outside its open period")
        try: minimum=int(config.get("start_lv"))
        except (TypeError,ValueError): raise GameplayFault("RouletteUnavailable", "Roulette level requirement is invalid")
        if int(profile.get("lv",1)) < minimum:
            raise GameplayFault("RouletteLevelLocked", "Player level is below the roulette requirement")

    def roulette(self, uid, params):
        config=self._roulette_cfg()
        try: num=int(params.get("num",1))
        except (TypeError,ValueError): raise GameplayFault("InvalidRoulette", "Draw count is invalid")
        if num not in (1,10): raise GameplayFault("InvalidRoulette", "Only one or ten draws are allowed")
        pool=config.get("pool",[])
        if not isinstance(pool,list) or not pool or any(not isinstance(gift,dict) or not gift for gift in pool):
            raise GameplayFault("RouletteUnavailable", "Roulette reward pool is invalid")
        key=self._op_key("user.roulette",params)
        def mutate(p):
            self._validate_roulette_access(p,config)
            attrs=p.setdefault("attrs",{}); state=self.store._normalize_roulette_state(attrs.get("roulette")); attrs["roulette"]=state
            count=state.get("fixed_count",0)
            if type(count) is not int or count<0:count=0
            state["fixed_count"]=count
            state.setdefault("last_time",None)
            fixed_draw=state.get("fixed_draw")
            if not isinstance(fixed_draw,dict):fixed_draw={}
            for tier in config.get("fixed_gift",{}):fixed_draw.setdefault(str(tier),0)
            state["fixed_draw"]=fixed_draw
            today=game_day(); last=state.get("last_time")
            if isinstance(last,dict) and "$date" in last: last=last["$date"]
            free=not last or game_day(last)!=today
            if free and num != 1:
                raise GameplayFault("InvalidRoulette", "The daily free draw is single-draw only")
            cost=0 if free else int(config.get("coin",50))*num
            if int(p.get("coin",0))<cost: raise GameplayFault("InsufficientCoin", "Not enough coin")
            p["coin"]=int(p.get("coin",0))-cost; self._record_coin_spend(p,cost); state["last_time"]={"$date":self._now()}
            avatar_before=set(p.get("avatars",{})); equip_before=set(p.get("my_equips",{}))
            gift_list=[copy.deepcopy(random.choice(pool)) for _ in range(num)]
            for gift in gift_list:grant_reward(p,gift,{"cfg":self.config})
            new_avatars={key:copy.deepcopy(value) for key,value in p.get("avatars",{}).items() if key not in avatar_before}
            new_equips={key:copy.deepcopy(value) for key,value in p.get("my_equips",{}).items() if key not in equip_before}
            previous_count=state["fixed_count"]
            count=previous_count+num; state["fixed_count"]=count
            milestones=sorted((int(k) for k in config.get("fixed_gift",{})),reverse=False)
            cycle=milestones[-1] if milestones else 0
            if cycle:
                old_cycle=previous_count//cycle
                new_cycle=count//cycle
                old_remainder=previous_count%cycle
                new_remainder=count%cycle
                crossed=[tier for tier in milestones if (tier>old_remainder and tier<=new_remainder) or (new_cycle>old_cycle and (tier>old_remainder or tier<=new_remainder))]
                level=max(crossed) if crossed else next((tier for tier in milestones if tier>new_remainder),milestones[0])
            else:
                crossed=[]
                level=1
            claimable=bool(crossed)
            attrs["roulette"]=state
            response=self._economy_profile_response(p,attr_roulette=state,coin=p["coin"],gold=p.get("gold",0),medal=p.get("medal",0),score=p.get("score",0),mark=p.get("mark",0),
                avatar_soul=p.get("avatar_soul",{}),equip_soul=p.get("equip_soul",{}),sp=attrs.get("sp",[0,0,0,0]),culture_book=attrs.get("culture_book",0),dn_stone=attrs.get("dn_stone",0),dust=attrs.get("dust",[0,0,0,0]),box_key=attrs.get("box_key",{}),fragment_energy=attrs.get("fragment_energy"),fragment_energy_extra=attrs.get("fragment_energy_extra",0),energy_extra=attrs.get("energy_extra",0),exp=p.get("exp",0),lv=p.get("lv",1),get_avatars=new_avatars,get_equips=new_equips,gift_list=gift_list,num=int(claimable),data={"max":str(level)})
            return p,response
        result,replayed=self.store.atomic_update(uid,mutate,key,{"num":num})
        result["replayed"]=replayed;return result

    def roulette_lottery(self, uid, params):
        config=self._roulette_cfg(); level=str(params.get("level","")); fixed=config.get("fixed_gift",{}); reward=fixed.get(level)
        if not isinstance(reward,dict): raise GameplayFault("InvalidRoulette", "Fixed reward tier is invalid")
        key=self._op_key("user.roulette_lottery",params)
        try: tier=int(level)
        except (TypeError,ValueError): raise GameplayFault("InvalidRoulette", "Fixed reward tier is invalid")
        milestones=sorted((int(key) for key in fixed),reverse=False)
        cycle=milestones[-1] if milestones else 0
        if tier not in milestones or cycle<=0: raise GameplayFault("InvalidRoulette", "Fixed reward tier is invalid")
        def mutate(p):
            self._validate_roulette_access(p,config)
            attrs=p.setdefault("attrs",{}); state=self.store._normalize_roulette_state(attrs.get("roulette")); attrs["roulette"]=state
            count=state.get("fixed_count",0)
            if type(count) is not int or count<0: raise GameplayFault("InvalidProfile", "Roulette draw count is invalid")
            fixed_draw=state.get("fixed_draw")
            if not isinstance(fixed_draw,dict):fixed_draw={}
            for key in fixed:fixed_draw.setdefault(str(key),0)
            claimed=fixed_draw.get(level,0)
            if type(claimed) is not int or claimed<0:claimed=0
            available=count//cycle + int(count%cycle>=tier)
            legacy_pending=state.get("legacy_pending_tier")==level
            if claimed>=available and not legacy_pending: raise GameplayFault("RoulettePending", "No unclaimed reward for this tier")
            grant_reward(p,reward,{"cfg":self.config}); fixed_draw[level]=claimed+1; state["fixed_draw"]=fixed_draw
            if legacy_pending:state.pop("legacy_pending_tier",None)
            out=self._economy_profile_response(p,attr_roulette=state,avatar_soul=p.get("avatar_soul",{}),equip_soul=p.get("equip_soul",{}),
                sp=attrs.get("sp",[0,0,0,0]),dust=attrs.get("dust",[0,0,0,0]),get_avatars={},get_equips={},gift=copy.deepcopy(reward))
            return p,out
        result,replayed=self.store.atomic_update(uid,mutate,key,{"level":level})
        result["replayed"]=replayed;return result

    def get_lottery_activity(self, uid, params):
        try: flag=int(params.get("flag",0))
        except (TypeError,ValueError): raise GameplayFault("InvalidLottery", "Lottery type is invalid")
        if flag not in (0,1): raise GameplayFault("InvalidLottery", "Lottery type is invalid")
        extract=(self.config.get("ploy_system_simple") or {}).get("extract_avatar") or {}
        cost=int(extract.get("coin_one",280) if flag==0 else extract.get("coin_ten",2500))
        pool=extract.get("activity_pool",[])
        if not isinstance(pool,list) or not pool:
            raise GameplayFault("LotteryUnavailable", "VIP activity pool is not configured")
        valid=[]; weight_total=0
        avatar_defs=self.config.get("avatar",{})
        blocked=skin_acquisition_blocked_ids(self.config)
        for row in pool:
            if not isinstance(row,dict) or row.get("kind") not in {"avatar","avatar_soul"}: continue
            aid=row.get("aid"); weight=row.get("weight",0)
            if not isinstance(aid,str) or aid not in avatar_defs or aid in blocked or type(weight) is not int or weight<=0: continue
            valid.append((row,weight));weight_total+=weight
        if not valid or weight_total<=0: raise GameplayFault("LotteryUnavailable", "VIP activity pool has no valid hero records")
        key=self._op_key("user.get_lottery_activity",params)
        def mutate(p):
            if int(p.get("coin",0))<cost: raise GameplayFault("InsufficientCoin", "Not enough coin")
            draws=10 if flag else 1
            attrs=p.setdefault("attrs",{}); state=attrs.get("lottery_activity")
            if not isinstance(state,dict): state={"score":0,"last_time":None}
            start_value=self._timestamp_seconds(extract.get("start_time"))
            prior_start=self._timestamp_seconds(state.get("start_time"))
            if start_value is not None and prior_start is not None and prior_start!=start_value:
                state={"score":0,"last_time":None}
            state.setdefault("score",0)
            picks=[]
            for _ in range(draws):
                ticket=random.randrange(weight_total)
                for row,weight in valid:
                    ticket-=weight
                    if ticket<0:
                        picks.append(row);break
            direct={}; souls={}
            for row in picks:
                aid=row["aid"]
                if row["kind"]=="avatar": direct[aid]=direct.get(aid,0)+1
                else:
                    amount=int(row.get("amount",5))
                    if amount<=0: raise GameplayFault("InvalidLottery", "VIP activity shard amount must be positive")
                    souls[aid]=souls.get(aid,0)+amount
            p["coin"]=int(p.get("coin",0))-cost;self._record_coin_spend(p,cost)
            before=set(p.get("avatars",{}))
            if direct: grant_reward(p,{"heroes":[{"aid":aid,"num":amount} for aid,amount in direct.items()]},{"cfg":self.config})
            if souls: grant_reward(p,{"avatar_soul":souls},{"cfg":self.config})
            avatar_rows=[{iid:p["avatars"][iid]} for iid in p.get("avatars",{}) if iid not in before]
            soul_rows=[{aid:amount} for aid,amount in souls.items()]
            categories={}
            if avatar_rows: categories["avatar"]=avatar_rows
            if soul_rows: categories["avatar_soul"]=soul_rows
            state["score"]=int(state.get("score",0))+draws
            state["last_time"]={"$date":self._now()}
            if start_value is not None: state["start_time"]={"$date":start_value}
            attrs["lottery_activity"]=state
            attrs["activity_time"]=state["last_time"]
            attrs["activity_score"]=int(attrs.get("activity_score",0))+draws
            response=self._economy_profile_response(p,coin=p["coin"],vip_exp=int(p.get("vip_exp",0)),vip_lv=int(p.get("vip_lv",0)),score=state["score"],avatars=categories)
            return p,response
        result,replayed=self.store.atomic_update(uid,mutate,key,{"flag":flag,"hit":params.get("hit")})
        result["replayed"]=replayed;return result

    def exchange_activity_avatar(self, uid, params):
        # The original integral-exchange panel and the timed ranking panel
        # share an RPC name, but they have different wallets and payloads.
        # Keep the index-based lottery exchange contract intact; TimedCharts
        # sends aid + score and spends attrs.activity_score.
        if "aid" in params:
            return self._exchange_timed_avatar(uid, params)
        try: index=int(params.get("index"))
        except (TypeError,ValueError): raise GameplayFault("InvalidExchange", "Activity exchange index is invalid")
        rows=((self.config.get("ploy_system_simple") or {}).get("extract_avatar") or {}).get("exchange",[])
        if not isinstance(rows,list) or not 0<=index<len(rows): raise GameplayFault("UnknownExchange", "Activity exchange is not configured")
        row=rows[index]
        if not isinstance(row,list) or len(row)<2 or not isinstance(row[0],dict):
            raise GameplayFault("InvalidExchange", "Activity exchange row does not match the client schema")
        reward=copy.deepcopy(row[0]);need=int(row[1]);key=self._op_key("user.exchange_activity_avatar",params)
        def mutate(p):
            attrs=p.setdefault("attrs",{}); state=attrs.setdefault("lottery_activity",{"score":0})
            if not isinstance(state,dict): state={"score":0};attrs["lottery_activity"]=state
            if int(state.get("score",0))<need: raise GameplayFault("ActivityScoreLow", "Not enough activity points")
            if "heroes" in reward and len(p.get("avatars",{}))>=int(attrs.get("avatar_len",0)):
                raise GameplayFault("AvatarCapacity", "Hero inventory is full")
            before=set(p.get("avatars",{}));grant_reward(p,reward,{"cfg":self.config})
            avatar={k:v for k,v in p.get("avatars",{}).items() if k not in before}
            state["score"]-=need
            out={"score":state["score"],"avatar":avatar}
            if "avatar_soul" in reward: out["avatar_soul"]=copy.deepcopy(reward["avatar_soul"])
            return p,out
        result,replayed=self.store.atomic_update(uid,mutate,key,{"index":index})
        result["replayed"]=replayed;return result

    def _exchange_timed_avatar(self, uid, params):
        aid=params.get("aid")
        if not isinstance(aid,str) or not aid.startswith("A_1"):
            raise GameplayFault("InvalidExchange", "Timed exchange requires a configured hero id")
        avatar_defs=self.config.get("avatar",{})
        if not isinstance(avatar_defs,dict) or aid not in avatar_defs:
            raise GameplayFault("UnknownAvatar", "Timed exchange hero is not configured")
        rows=(self.config.get("ploy_system_simple") or {}).get("timed_exchange",[])
        if not isinstance(rows,list):
            raise GameplayFault("TimedExchangeUnavailable", "Timed exchange table is invalid")
        price=None
        for row in rows:
            if isinstance(row,dict) and len(row)==1 and aid in row:
                configured=row[aid]
                if type(configured) is int and configured>0:
                    price=configured
                break
        if price is None:
            raise GameplayFault("UnknownExchange", "Hero is not available in timed exchange")
        requested=params.get("score")
        # AMF may decode a numeric score as int or integral float. Never accept
        # a client-selected discount or silently coerce bool/string values.
        if (isinstance(requested,bool) or not isinstance(requested,(int,float))
                or not math.isfinite(requested) or int(requested)!=requested or int(requested)!=price):
            raise GameplayFault("InvalidExchangePrice", "Timed exchange price does not match the configured price")
        key=self._op_key("user.exchange_activity_avatar",params)
        def mutate(p):
            attrs=p.setdefault("attrs",{})
            capacity=attrs.get("avatar_len",0)
            if type(capacity) is not int or capacity<0:
                raise GameplayFault("InvalidProfile", "Hero inventory capacity is invalid")
            avatars=p.setdefault("avatars",{})
            if not isinstance(avatars,dict):
                raise GameplayFault("InvalidProfile", "Hero inventory has an invalid shape")
            if len(avatars)>=capacity:
                raise GameplayFault("AvatarCapacity", "Hero inventory is full")
            score=attrs.get("activity_score",0)
            if type(score) is not int or score<0:
                raise GameplayFault("InvalidProfile", "Activity score is invalid")
            if score<price:
                raise GameplayFault("ActivityScoreLow", "Not enough activity points")
            before=set(avatars)
            grant_reward(p,{"heroes":[{"aid":aid,"num":1}]},{"cfg":self.config})
            minted={instance_id:copy.deepcopy(p["avatars"][instance_id])
                    for instance_id in p.get("avatars",{}) if instance_id not in before}
            if len(minted)!=1:
                raise GameplayFault("InvalidReward", "Timed exchange did not create exactly one hero")
            attrs["activity_score"]=score-price
            return p,{"score":attrs["activity_score"],"avatar":minted}
        result,replayed=self.store.atomic_update(uid,mutate,key,{"aid":aid,"score":price})
        result["replayed"]=replayed
        return result

    def _box_config(self):
        config=(self.config.get("ploy_system_simple") or {}).get("box_key")
        if not isinstance(config,dict): raise GameplayFault("BoxKeyUnavailable", "Box and key activity is not configured")
        return config

    def _box_state(self, profile):
        attrs=profile.setdefault("attrs",{}); state=attrs.get("box_key")
        if not isinstance(state,dict): state={}
        for kind in ("box","key"):
            entry=state.get(kind)
            if not isinstance(entry,dict): state[kind]={"num":0,"last_time":None}
            else:
                entry.setdefault("num",0);entry.setdefault("last_time",None)
        attrs["box_key"]=state
        return state

    def _box_response(self, p, **extra):
        attrs=p.setdefault("attrs",{}); state=self._box_state(p)
        fields={"attr_box_key":copy.deepcopy(state),"coin":p.get("coin",0),"gold":p.get("gold",0),"medal":p.get("medal",0),
            "score":p.get("score",0),"mark":p.get("mark",0),"sp":attrs.get("sp",[0,0,0,0]),"dust":attrs.get("dust",[0,0,0,0]),
            "dn_stone":attrs.get("dn_stone",0),"exp":p.get("exp",0),"lv":p.get("lv",1),"energy":p.get("energy"),
            "fragment_energy":attrs.get("fragment_energy"),"fragment_energy_extra":attrs.get("fragment_energy_extra",0),
            "energy_extra":attrs.get("energy_extra",0),"avatar_soul":p.get("avatar_soul",{}),"equip_soul":p.get("equip_soul",{}),
            "culture_book":attrs.get("culture_book",0),"get_avatars":{},"get_equips":{},"get_fragments":{}}
        fields.update(copy.deepcopy(extra));return fields

    def get_box_key(self, uid, params):
        what=str(params.get("what",""))
        if what not in {"box","key"}: raise GameplayFault("InvalidBoxKey", "Unknown box or key type")
        config=self._box_config(); windows=(config.get("time") or {}).get(what,[])
        # Schedule windows and claim de-duplication use the same authoritative
        # Shanghai calendar day; the host machine's local timezone may differ.
        today=datetime.date.fromisoformat(game_day(self._now())); active=None
        for i,row in enumerate(windows):
            if len(row)>=4 and int(row[0])==today.month and int(row[1])<=today.day<=int(row[3]): active=(i,row);break
        if active is None: raise GameplayFault("BoxKeyUnavailable", "No box or key is scheduled today")
        key=self._op_key("user.get_box_key",params)
        def mutate(p):
            state=self._box_state(p); entry=state[what]; last=entry.get("last_time")
            if isinstance(last,dict) and "$date" in last: last=last["$date"]
            if last and game_day(last)==game_day(): raise GameplayFault("DailyLimit", "This daily box or key was already claimed")
            entry["num"]=int(entry.get("num",0))+1;entry["last_time"]={"$date":self._now()}
            return p,self._box_response(p)
        result,replayed=self.store.atomic_update(uid,mutate,key,{"what":what,"window":active[0]})
        result["replayed"]=replayed;return result

    def box_key_exchange(self, uid, params):
        what=str(params.get("what","")); config=self._box_config(); rates=(config.get("exchange") or {}).get(what)
        if what not in {"box","key"} or not isinstance(rates,list) or len(rates)<2: raise GameplayFault("InvalidBoxExchange", "Unknown box/key exchange")
        need,give=int(rates[0]),int(rates[1]);other="key" if what=="box" else "box"
        key=self._op_key("user.box_key_exchange",params)
        def mutate(p):
            state=self._box_state(p)
            if int(state[what]["num"])<need: raise GameplayFault("InsufficientBoxKey", "Not enough items to exchange")
            state[what]["num"]-=need;state[other]["num"]+=give
            return p,self._box_response(p)
        result,replayed=self.store.atomic_update(uid,mutate,key,{"what":what})
        result["replayed"]=replayed;return result

    def box_key_gift(self, uid, params):
        config=self._box_config(); cost=(config.get("open_cost") or {}); rewards=config.get("rewards") or []
        key=self._op_key("user.box_key_gift",params)
        def mutate(p):
            state=self._box_state(p)
            for kind in ("box","key"):
                amount=int(cost.get(kind,1))
                if int(state[kind]["num"])<amount: raise GameplayFault("InsufficientBoxKey", "One box and one key are required")
            if len(p.get("avatars",{}))>=int(p.get("attrs",{}).get("avatar_len",0)): raise GameplayFault("AvatarCapacity", "Hero inventory is full")
            equip_capacity=int(self.config.get("system_simple",{}).get("equip_config",[100])[0])
            if len(p.get("my_equips",{}))>=equip_capacity: raise GameplayFault("EquipCapacity", "Equipment inventory is full")
            state["box"]["num"]-=int(cost.get("box",1));state["key"]["num"]-=int(cost.get("key",1))
            prize=copy.deepcopy(random.choice(rewards)) if rewards else {"coin":50}
            before_avatar=set(p.get("avatars",{}));before_equip=set(p.get("my_equips",{}))
            grant_reward(p,prize,{"cfg":self.config})
            new_avatars={k:v for k,v in p.get("avatars",{}).items() if k not in before_avatar}
            new_equips={k:v for k,v in p.get("my_equips",{}).items() if k not in before_equip}
            records=p.setdefault("records",{}).setdefault("box_record",[])
            records.append({"name":p.get("name","Test player"),"gift":prize,"time":{"$date":self._now()}})
            del records[:-50]
            return p,self._box_response(p,gift=prize,get_avatars=new_avatars,get_equips=new_equips)
        result,replayed=self.store.atomic_update(uid,mutate,key,{})
        result["replayed"]=replayed;return result

    def box_gift_record(self, uid, params):
        profile=self.store.profile(uid);records=profile.get("records",{}).get("box_record",[])
        return {"box_record":[{"name":row.get("name","Test player"),"gift":copy.deepcopy(row.get("gift",{}))} for row in records]}

    def rank_lv(self, uid, params):
        try:
            need = int(params.get("lv"))
        except (TypeError, ValueError):
            raise GameplayFault("InvalidRankReward", "Rank reward level is invalid")
        cfg = (self.config.get("ploy_system_simple") or {}).get("rank_lv") or {}
        rows = cfg.get("content", [])
        row = next((item for item in rows if isinstance(item, dict) and int(item.get("need", -1)) == need), None)
        if row is None:
            raise GameplayFault("UnknownRankReward", "Rank reward level is not configured")
        reward = row.get("gift")
        if not isinstance(reward, dict) or not reward:
            raise GameplayFault("InvalidRankReward", "Rank reward has no valid gift")
        key = self._op_key("user.rank_lv", params)
        def mutate(p):
            attrs = p.setdefault("attrs", {})
            claimed = attrs.get("rank_lv")
            if not isinstance(claimed, list):
                claimed = []; attrs["rank_lv"] = claimed
            if int(p.get("lv", 1)) < need:
                raise GameplayFault("RankLevelLow", "Player level has not reached this reward")
            if need in claimed:
                raise GameplayFault("RankRewardClaimed", "This rank reward was already claimed")
            grant_reward(p, copy.deepcopy(reward), {"cfg": self.config})
            claimed.append(need)
            return p, {"coin": int(p.get("coin", 0)), "attrs": copy.deepcopy(attrs)}
        result, replayed = self.store.atomic_update(uid, mutate, key, {"lv": need})
        result["replayed"] = replayed
        return result

    def groupon_info(self, uid, params):
        profile=self.store.profile(uid);state=profile.get("records",{}).get("groupon",{})
        return {"total_num":int(state.get("total_num",0)),"my_num":int(state.get("my_num",0)),
            "consume_coin":int(state.get("consume_coin",0)),"recoin":int(state.get("recoin",0)),
            "buy_gift":copy.deepcopy(state.get("buy_gift",[]))}

    def groupon_buy(self, uid, params):
        config=(self.config.get("ploy_system_simple") or {}).get("groupon") or {}
        unit=int(config.get("coin",100))
        try:num=int(params.get("num",1))
        except (TypeError,ValueError): raise GameplayFault("InvalidGroupon", "Purchase count is invalid")
        if num not in (1,10): raise GameplayFault("InvalidGroupon", "Only one or ten group-buy bundles are allowed")
        cost=unit*num*(9 if num==10 else 10)//10; rewards=config.get("rewards") or []
        key=self._op_key("user.groupon_buy",params)
        def mutate(p):
            if int(p.get("coin",0))<cost: raise GameplayFault("InsufficientCoin", "Not enough coin")
            records=p.setdefault("records",{});state=records.setdefault("groupon",{});p["coin"]-=cost;self._record_coin_spend(p,cost)
            buy_gift=state.setdefault("buy_gift",[]);total_reward={};awarded_heroes={};awarded_equips={}
            for i in range(num):
                reward=copy.deepcopy(rewards[(int(state.get("total_num",0))+i)%len(rewards)]) if rewards else {"coin":0}
                before_a=set(p.get("avatars",{}));before_e=set(p.get("my_equips",{}))
                grant_reward(p,reward,{"cfg":self.config})
                awarded_heroes.update({k:v for k,v in p.get("avatars",{}).items() if k not in before_a})
                awarded_equips.update({k:v for k,v in p.get("my_equips",{}).items() if k not in before_e})
                for kind,value in reward.items():
                    if isinstance(value,int): total_reward[kind]=total_reward.get(kind,0)+value
                    elif isinstance(value,dict):
                        target=total_reward.setdefault(kind,{})
                        for k,v in value.items(): target[k]=target.get(k,0)+v
                buy_gift.append(reward)
            state["my_num"]=int(state.get("my_num",0))+num;state["total_num"]=int(state.get("total_num",0))+num
            state["consume_coin"]=int(state.get("consume_coin",0))+cost;state["recoin"]=0
            return p,{"buy_gift":buy_gift[-num:],"new_avatar_soul":p.get("avatar_soul",{}),"new_equip_soul":p.get("equip_soul",{}),
                "vip_exp":p.get("vip_exp",0),"vip_lv":p.get("vip_lv",0),"coin":p["coin"],"new_avatars":awarded_heroes,
                "new_equips":awarded_equips,"total_num":state["total_num"],"my_num":state["my_num"],
                "consume_coin":state["consume_coin"],"recoin":0,"rewards":total_reward}
        result,replayed=self.store.atomic_update(uid,mutate,key,{"num":num})
        result["replayed"]=replayed;return result

    def groupon_close(self, uid, params):
        key=self._op_key("user.groupon_close",params)
        def mutate(p):
            state=p.setdefault("records",{}).setdefault("groupon",{});state["closed"]=True
            return p,{"closed":True,"total_num":int(state.get("total_num",0)),"my_num":int(state.get("my_num",0))}
        result,replayed=self.store.atomic_update(uid,mutate,key,{"close":True})
        result["replayed"]=replayed;return result

    def get_gamble_reports(self, uid, params):
        profile = self.store.profile(uid)
        # The client maps report values through GlobalLanguageStr("gamble", value).
        # Use the native scheduled tier index as the stable local report token.
        return [int(item.get("attempt", 0)) for item in profile.get("records", {}).get("gamble_reports", [])[-20:]]

    def task_done(self, uid, params):
        task_key = params.get("task_key") or params.get("type")
        task_code = params.get("task_code")
        if not isinstance(task_key, str) or not task_key:
            raise GameplayFault("InvalidTask", "Task key is required")
        key = self._op_key("user.task_done", params)
        tasks = self.config.get("task") or {}
        everyday = self.config.get("everyday_gift") or []
        def mutate(p):
            records = p.setdefault("records", {})
            catena = p.get("catena", 0)
            if type(catena) is not int or catena < 0:
                catena = p["catena"] = 0
            if task_key.startswith("_$everyday$_"):
                try: index = int(task_key.rsplit("_", 1)[1])
                except (ValueError, IndexError): raise GameplayFault("InvalidTask", "Invalid daily gift index")
                if not isinstance(everyday, list) or not 0 <= index < len(everyday): raise GameplayFault("UnknownTask", "Daily gift is not configured")
                claimed = records.setdefault("everyday_gift", [])
                if index in claimed: raise GameplayFault("AlreadyClaimed", "Daily gift already claimed")
                gift = everyday[index]
                if not isinstance(gift, dict) or not gift: raise GameplayFault("InvalidReward", "Daily gift has no reward")
                grant_reward(p, gift, {"cfg":self.config})
                claimed.append(index)
                return p, self._profile_result(p, records=records, task=p.get("task", {}), catena=catena)
            definition = tasks.get(task_key) if isinstance(tasks, dict) else None
            if not isinstance(definition, dict): raise GameplayFault("UnknownTask", "Task is not configured: " + task_key)
            content = definition.get("content")
            if not isinstance(content, list) or not content: raise GameplayFault("InvalidTask", "Task tiers are not configured")
            state = p.setdefault("task", {})
            if task_key in {"time_pay", "time_pay_loop"}:
                now = self._now()
                begin = self._timestamp_seconds(definition.get("begin_time"))
                end = self._timestamp_seconds(definition.get("end_time"))
                if begin is None or end is None or not begin <= now < end:
                    raise GameplayFault("TaskUnavailable", "Payment reward campaign is not open")
                try: requested_tier = int(task_code)
                except (TypeError, ValueError): raise GameplayFault("InvalidTask", "Task tier code is required")
                is_loop = task_key == "time_pay_loop"
                if is_loop:
                    if requested_tier != 0:
                        raise GameplayFault("InvalidTask", "Loop task tier code must be zero")
                    tier = 0
                else:
                    try: tier = int(state.get(task_key, 0))
                    except (TypeError, ValueError): raise GameplayFault("InvalidTaskState", "Task progress is invalid")
                    if requested_tier != tier:
                        raise GameplayFault("InvalidTask", "Requested tier does not match current task tier")
                if not 0 <= tier < len(content):
                    raise GameplayFault("TaskComplete", "All task tiers are already claimed")
                entry = content[tier]
                need = entry.get("need") if isinstance(entry, dict) else None
                gift = entry.get("gift") if isinstance(entry, dict) else None
                if type(need) is not int or need <= 0 or not isinstance(gift, dict) or len(gift) != 1:
                    raise GameplayFault("InvalidTask", "Payment task tier is malformed")
                attrs = p.setdefault("attrs", {})
                progress_state = attrs.get(task_key)
                if not isinstance(progress_state, dict):
                    raise GameplayFault("TaskNotComplete", "Payment progress has not been earned")
                progress = progress_state.get("money", 0)
                if type(progress) is not int or progress < need:
                    raise GameplayFault("TaskNotComplete", "Payment progress requirement has not been met")
                marker = self._timestamp_seconds(progress_state.get("time_key"))
                if marker != begin:
                    raise GameplayFault("TaskNotComplete", "Payment progress belongs to a different campaign window")
                grant_reward(p, gift, {"cfg": self.config})
                # These are progress balances (rather than unspent lifetime
                # totals): consuming the tier threshold makes a loop reward
                # finite and lets the native progress bar show the next loop.
                progress_state["money"] = progress - need
                claimed = progress_state.get("claimed", 0)
                if type(claimed) is not int or claimed < 0:
                    claimed = 0
                progress_state["claimed"] = claimed + 1
                if not is_loop:
                    state[task_key] = tier + 1
                return p, self._profile_result(p, task=state, records=records, catena=catena, gift=gift)
            try: tier = int(state.get(task_key, 0))
            except (TypeError, ValueError): raise GameplayFault("InvalidTaskState", "Task progress is invalid")
            if not 0 <= tier < len(content): raise GameplayFault("TaskComplete", "All task tiers are already claimed")
            try: requested_tier = int(task_code)
            except (TypeError, ValueError): raise GameplayFault("InvalidTask", "Task tier code is required")
            if requested_tier != tier: raise GameplayFault("InvalidTask", "Requested tier does not match current task tier")
            entry = content[tier]
            if not isinstance(entry, dict) or "need" not in entry or not isinstance(entry.get("gift"), dict):
                raise GameplayFault("InvalidTask", "Task tier is malformed")
            need = entry["need"]
            progress_key = definition.get("progress", task_key)
            if progress_key == "login_total":
                progress = int(p.get("attrs", {}).get("login_total", 0))
            elif progress_key == "level_up":
                progress = int(p.get("lv", 1))
            elif progress_key == "pay":
                progress = int(p.get("attrs", {}).get("pay_money", 0))
            elif progress_key == "pass_map_main":
                progress = int(p.get("records", {}).get("combat_main", {}).get("normal", 0))
            elif progress_key == "hero_score":
                progress = int(p.get("score", 0))
            else:
                progress = int(p.get("records", {}).get(progress_key, 0))
            if type(need) is int and progress < need: raise GameplayFault("TaskNotComplete", "Task progress requirement has not been met")
            grant_reward(p, entry["gift"], {"cfg":self.config})
            state[task_key] = tier + 1
            return p, self._profile_result(p, task=state, records=records, catena=catena)
        payload = {"task_key": task_key, "task_code": str(task_code)}
        result, replayed = self.store.atomic_update(uid, mutate, key, payload)
        result["replayed"] = replayed
        return result
