"""VIP progression from lifetime local gift coins.

The client-facing vip_exp is progress within the current tier.  The durable
counter is separate from the spendable coin wallet and includes first-gift
double coins on new transactions.
"""
import json

VIP_THRESHOLDS = (
    0, 60, 180, 300, 1_000, 2_000, 5_000, 10_000, 15_000,
    20_000, 30_000, 40_000, 50_000, 80_000, 120_000, 200_000,
)


def vip_level(total_coin):
    total = max(0, int(total_coin))
    return max(level for level, threshold in enumerate(VIP_THRESHOLDS) if total >= threshold)


def legacy_first_bonus_from_receipts(rows):
    """Recover the old first-gift extra from payment ledger results, if saved.

    Old transactions without actionID had no ledger entry, so None means the
    historical bonus is unknown; it must not be guessed from wallet balance.
    """
    for raw in rows:
        try:
            row = json.loads(raw) if isinstance(raw, str) else raw
            if not isinstance(row, dict) or row.get("first_double") is not True:
                continue
            base, granted = row.get("base_coin"), row.get("granted_coin")
            if type(base) is int and base > 0 and type(granted) is int and granted == 2 * base:
                return base
        except (TypeError, ValueError):
            continue
    return None


def normalize_vip_profile(profile, legacy_first_bonus_coin=None):
    """Migrate the old base/10 VIP EXP once, then project the native fields.

    Old saves stored the base gift total in tenths.  A receipt in the
    operation ledger can recover the first doubled denomination; otherwise
    only that known base is retained. Future credits use actual granted coin.
    """
    attrs = profile.setdefault("attrs", {})
    if type(attrs.get("vip_gift_total_coin")) is not int or attrs["vip_gift_total_coin"] < 0:
        pay_units = attrs.get("pay_total", 0)
        old_exp = profile.get("vip_exp", 0)
        records = profile.get("records", {})
        pay_records = records.get("pay", {}) if isinstance(records, dict) else {}
        old_coin = pay_records.get("coin", 0) if isinstance(pay_records, dict) else 0
        candidates = []
        for value, multiplier in ((pay_units, 10), (old_exp, 10), (old_coin, 1)):
            if type(value) is int and value >= 0:
                candidates.append(value * multiplier)
        base_total = max(candidates, default=0)
        first_bonus = (legacy_first_bonus_coin if type(legacy_first_bonus_coin) is int
                       and legacy_first_bonus_coin > 0 else 0)
        attrs["vip_gift_total_coin"] = base_total + first_bonus
    total = attrs["vip_gift_total_coin"]
    level = vip_level(total)
    profile["vip_lv"] = level
    profile["vip_exp"] = total - VIP_THRESHOLDS[level]
    return total


def credit_vip_gift(profile, granted_coin):
    if type(granted_coin) is not int or granted_coin <= 0:
        raise ValueError("VIP gift credit must be a positive integer")
    total = normalize_vip_profile(profile) + granted_coin
    profile["attrs"]["vip_gift_total_coin"] = total
    profile["vip_lv"] = vip_level(total)
    profile["vip_exp"] = total - VIP_THRESHOLDS[profile["vip_lv"]]
    return total
