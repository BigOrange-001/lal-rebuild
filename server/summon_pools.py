"""Calibrated two-stage hero draws shared by normal, advanced and VIP summons."""
from __future__ import annotations

import copy
import json
import math
from decimal import Decimal
from pathlib import Path

from player_store import GameplayFault

QUALITY_IDS = {"white": 2, "green": 3, "blue": 4, "purple": 5, "orange": 6}
POOL_KEYS = ("normal", "advanced", "vip")
CALIBRATION_PATH = Path(__file__).resolve().parents[1] / "config/reconstruction/summon-calibration.json"


def apply_summon_config(document):
    """Install the reviewed calibration and unlock skin acquisition globally."""
    cfg = document.get("cfg", document)
    calibration = json.loads(CALIBRATION_PATH.read_text(encoding="utf-8"))
    # Validate against the final hero definitions before exposing the document.
    SummonPools(calibration, cfg.get("avatar", {}))
    cfg["summon_calibration"] = calibration
    simple = cfg.setdefault("system_simple", {})
    simple["skin_hero_ids"] = sorted(set(simple.get("skin_hero_ids", [])) |
                                    set(calibration["normalization"]["skin_hero_ids"]))
    simple["skin_acquisition_blocked_heroes"] = []
    for hero in cfg.get("avatar", {}).values():
        hero.pop("skin_exchange_only", None)
    cfg.setdefault("return_msg_config", {}).update({
        "90426": "按当前品质出率独立抽取",
        "90445": "按当前品质出率独立抽取",
        "90427": "十次召唤，每次独立抽取",
    })
    # Existing client tables must not continue advertising VIP soul drops.
    extract = cfg.get("ploy_system_simple", {}).get("extract_avatar", {})
    extract["activity_pool"] = [
        {"kind": "avatar", "aid": card["id"], "weight": card["weight"]}
        for row in calibration["pools"]["vip"]["qualities"].values()
        if row["probability_percent"] > 0 for card in row["cards"]
    ]
    return document


def _number(value, label, *, maximum=None):
    if (type(value) not in (int, float) or not math.isfinite(value) or value < 0
            or maximum is not None and value > maximum):
        raise GameplayFault("InvalidConfig", f"Invalid summon {label}")
    return Decimal(str(value))


def _weighted(rows):
    """Scale finite decimal weights to integers to avoid truncating small weights."""
    rows = [(key, weight) for key, weight in rows if weight > 0]
    if not rows:
        return (), 0
    scale = max(0, -min(weight.as_tuple().exponent for _, weight in rows))
    # Decimal -> exact integer ratio, independent of the global Decimal precision.
    factor = 10 ** scale
    values = [(key, weight.as_integer_ratio()) for key, weight in rows]
    weighted = tuple((key, numerator * factor // denominator)
                     for key, (numerator, denominator) in values)
    return weighted, sum(weight for _, weight in weighted)


def _pick(compiled, rng):
    rows, total = compiled
    if total <= 0:
        raise GameplayFault("InvalidConfig", "Summon pool is empty")
    ticket = rng.randrange(total)
    for key, weight in rows:
        if ticket < weight:
            return key
        ticket -= weight
    raise RuntimeError("Summon ticket is outside its pool")


class SummonPools:
    def __init__(self, calibration, heroes):
        if calibration.get("schema") != "lal-summon-calibration-v1":
            raise GameplayFault("InvalidConfig", "Unknown summon calibration schema")
        self._qualities, self._cards = {}, {}
        for pool in POOL_KEYS:
            qualities = calibration.get("pools", {}).get(pool, {}).get("qualities", {})
            rates = []
            for quality, quality_id in QUALITY_IDS.items():
                row = qualities.get(quality)
                if not isinstance(row, dict) or not isinstance(row.get("cards"), list):
                    raise GameplayFault("InvalidConfig", f"Missing {pool}/{quality} summon pool")
                probability = _number(row.get("probability_percent"), "probability", maximum=100)
                rates.append((quality, probability))
                cards, seen = [], set()
                for card in row["cards"]:
                    aid = card.get("id") if isinstance(card, dict) else None
                    hero = heroes.get(aid)
                    if (not isinstance(aid, str) or aid in seen or not isinstance(hero, dict)
                            or not aid.endswith("_" + str(quality_id))):
                        raise GameplayFault("InvalidConfig", f"Invalid or duplicate summon hero: {aid}")
                    seen.add(aid)
                    cards.append((aid, _number(card.get("weight"), "card weight")))
                self._cards[pool, quality] = _weighted(cards)
                if probability > 0 and not self._cards[pool, quality][1]:
                    raise GameplayFault("InvalidConfig", f"Empty active summon pool: {pool}/{quality}")
            if sum(rate for _, rate in rates) != 100:
                raise GameplayFault("InvalidConfig", f"Summon probabilities must total 100: {pool}")
            self._qualities[pool] = _weighted(rates)

    @classmethod
    def from_config(cls, config):
        cfg = config.get("cfg", config)
        calibration = cfg.get("summon_calibration")
        metadata = cfg.get("mod_runtime", {}).get("heroes", {})
        if calibration is not None and metadata:
            # An applied Mod context is already user-confirmed. Respect its
            # per-channel consent and never leak entries into the base config.
            calibration = copy.deepcopy(calibration)
            for pool, channel in (("normal", "acquisition.summon.normal"),
                                  ("advanced", "acquisition.summon.advanced"),
                                  ("vip", "acquisition.summon.activity")):
                for quality, row in calibration["pools"][pool]["qualities"].items():
                    row["cards"] = [card for card in row["cards"]
                                    if card["id"] not in metadata or
                                    (metadata[card["id"]].get("available") is True and
                                     metadata[card["id"]].get("channels", {}).get(channel) is True)]
                    existing = {card["id"] for card in row["cards"]}
                    for aid, meta in metadata.items():
                        if (meta.get("kind") == "new" and meta.get("available") is True
                                and meta.get("channels", {}).get(channel) is True
                                and meta.get("quality") == QUALITY_IDS[quality]
                                and aid not in existing):
                            row["cards"].append({"id": aid, "weight": 1})
        return cls(calibration, cfg.get("avatar", {})) if calibration is not None else None

    def draw(self, pool, rng):
        quality = _pick(self._qualities[pool], rng)
        return _pick(self._cards[pool, quality], rng)

    def draw_quality(self, pool, quality, rng, count=1):
        """Weighted fixed-quality draw, without replacement when count > 1."""
        self.validate_quality(pool, quality, count)
        rows=list(self._cards[pool, quality][0])
        chosen=[]
        for _ in range(count):
            aid=_pick((rows,sum(weight for _,weight in rows)),rng)
            chosen.append(aid)
            rows=[row for row in rows if row[0]!=aid]
        return chosen

    def validate_quality(self, pool, quality, count=1):
        """Check a fixed-quality reward before spending resources or creating intent."""
        if (pool, quality) not in self._cards or type(count) is not int or count < 1:
            raise GameplayFault('InvalidConfig', 'Invalid fixed-quality summon request')
        if len(self._cards[pool, quality][0]) < count:
            raise GameplayFault('InvalidConfig', 'Not enough distinct heroes in the summon pool')


def confirm_custom_hero(document, aid, *, confirmed, pools=POOL_KEYS):
    """Explicit import-confirmation hook; never enable an unconfirmed hero.

    The caller invokes this on its resolved configuration after the user has
    confirmed the custom hero's acquisition channels. Existing entries, even
    explicit zero weights, are preserved and quality probabilities never change.
    """
    if confirmed is not True:
        return False
    cfg = document.get("cfg", document)
    hero = cfg.get("avatar", {}).get(aid)
    if not isinstance(hero, dict):
        raise GameplayFault("UnknownHero", "Custom summon hero is unavailable")
    quality = next((q for q, value in QUALITY_IDS.items() if aid.endswith("_" + str(value))), None)
    if quality is None or any(pool not in POOL_KEYS for pool in pools):
        raise GameplayFault("InvalidConfig", "Invalid custom summon quality or pool")
    updated = copy.deepcopy(cfg["summon_calibration"])
    for pool in pools:
        cards = updated["pools"][pool]["qualities"][quality]["cards"]
        if not any(card["id"] == aid for card in cards):
            cards.append({"id": aid, "name": hero.get("name", aid), "weight": 1,
                          "custom": True, "confirmed": True})
    SummonPools(updated, cfg["avatar"])
    cfg["summon_calibration"] = updated
    return True
