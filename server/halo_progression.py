"""Five-rank equipment halo curve shared by configuration and server logic."""

from __future__ import annotations

import copy


HALO_CURVE = {
    "schema": "weighted-five-rank-v1",
    "wash_multiplier": 5,
    "exp_per_wash": 20,
    # Each successive rank needs more of the full progression budget.
    "rank_weights": [8, 12, 18, 26, 36],
}


def apply_halo_progression(document: dict) -> dict:
    """Return a configured copy; rerunning produces the same document value."""
    result = copy.deepcopy(document)
    simple = result["cfg"]["system_simple"]
    equipwash = simple["equipwash"]
    if len(equipwash) < 6 or int(equipwash[5]) != len(HALO_CURVE["rank_weights"]):
        raise ValueError("halo curve requires five equipwash ranks")
    simple["wash_halo_sync"] = True
    simple["wash_halo_curve"] = copy.deepcopy(HALO_CURVE)
    equipwash[2] = equipwash[3] = HALO_CURVE["exp_per_wash"]
    return result


def halo_rank_threshold(simple: dict, item_level: int, rank: int) -> int:
    """Experience for rank -> rank+1, scaled to five times wash saturation."""
    curve = simple["wash_halo_curve"]
    weights = curve["rank_weights"]
    cap = int(simple["equipwash"][5])
    if len(weights) != cap or rank < 0 or rank >= cap or any(int(w) <= 0 for w in weights):
        raise ValueError("invalid halo rank curve")
    if int(simple["equipwash"][2]) != int(curve["exp_per_wash"]) or int(simple["equipwash"][3]) != int(curve["exp_per_wash"]):
        raise ValueError("halo experience gains must match both wash currencies")
    item_level = max(1, int(item_level))
    equip_config = simple["equip_config"]
    potential = int(equip_config[3]) * item_level
    points_per_wash = max(5, item_level // 10)
    baseline_washes = (potential + points_per_wash - 1) // points_per_wash
    total_exp = baseline_washes * int(curve["wash_multiplier"]) * int(curve["exp_per_wash"])
    weight_sum = sum(int(w) for w in weights)

    def cumulative(index: int) -> int:
        weighted = total_exp * sum(int(w) for w in weights[:index])
        return (weighted + weight_sum - 1) // weight_sum

    return max(1, cumulative(rank + 1) - cumulative(rank))
