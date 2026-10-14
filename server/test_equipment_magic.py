"""Elemental enchantment cost, unlock, rune and potential-budget boundaries."""
import json
import sqlite3
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from equipment_magic import apply_equipment_magic_config, enchantment_stage, main_stat_multiplier, rune_bonus, rune_upgrade_cost, stat_bonus, symp_bonuses, upgrade_cost
from equipment_growth_v2 import main_stat
from gameplay_roster import GameplayRosterEquipment
from player_store import GameplayFault, PlayerStore


class EquipmentMagicTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = json.loads((Path(__file__).resolve().parents[1] /
                                 "config/reconstruction/full-config.json").read_text(encoding="utf-8"))

    def setUp(self):
        self.config = apply_equipment_magic_config(self.source)
        self.db = sqlite3.connect(":memory:", check_same_thread=False)
        self.addCleanup(self.db.close)
        self.store = PlayerStore(self.db, self.config)
        self.uid = self.store.login("magic-tester")["uid"]
        self.roster = GameplayRosterEquipment(self.store, self.config)
        self.eqid = "test-magic-equip"

        def seed(profile):
            profile.setdefault("my_equips", {})[self.eqid] = {
                "eid": "E_1001_3", "lv": 1, "magic": [0, 0, 0, 0], "symp": -1,
            }
            profile.setdefault("attrs", {})["dust"] = [100, 100, 100, 100]
            return profile, {}
        self.store.atomic_update(self.uid, seed)

    def _set_magic(self, levels, symp=-1):
        def mutate(profile):
            item = profile["my_equips"][self.eqid]
            item["magic"] = list(levels)
            item["symp"] = symp
            return profile, {}
        self.store.atomic_update(self.uid, mutate)

    def _upgrade(self, color, action):
        return self.roster.dispatch(self.uid, "user.add_magic", {
            "eqid": self.eqid, "color": color, "dust": 0, "actionID": action,
        })

    def _fault(self, color, action, expected):
        with self.assertRaises(GameplayFault) as result:
            self._upgrade(color, action)
        self.assertEqual(result.exception.code, expected)

    def test_config_is_idempotent_and_existing_levels_gain_new_stats(self):
        simple = self.source["cfg"]["system_simple"]
        base = simple["equip_config"][3]
        if simple.get("equipment_potential_schema") == "sixfold-v1":
            base /= 6
        repeated = apply_equipment_magic_config(self.config)
        self.assertEqual(repeated["cfg"]["system_simple"]["equip_config"][3], base * 6)
        self.assertEqual(self.config["cfg"]["system_simple"]["equip_config"][3], base * 6)
        self.assertEqual(stat_bonus(self.config, [2, 3, 4, 5]), {"hp": 1680, "ap": 180})
        self.assertEqual(symp_bonuses(self.config, [3, 2, 0, 0]),
                         {"hp": 15000, "ap": 600, "de_ph": 0, "de_ma": 0})
        self.assertEqual(symp_bonuses(self.config, [0, 0, 2, 6]),
                         {"hp": 0, "ap": 0, "de_ph": 1200, "de_ma": 7200})
        self.assertEqual([upgrade_cost(self.config, 0, level) for level in (0, 19, 20, 99)],
                         [2, 2, 3, 6])
        self.assertEqual(self.config['cfg']['system_simple']['equipment_magic']['stage5_cost'], [2, 3, 6, 8])

    def test_first_rune_replay_unlock_and_server_calculated_cost(self):
        self._fault(1, "locked", "MagicLocked")
        initial = self.store.profile_raw(self.uid)["attrs"]["dust"][0]
        first = self._upgrade(0, "first")
        self.assertEqual(first["magic"], [1, 0, 0, 0])
        self.assertIn(first["symp"], range(4))
        self.assertEqual(self.store.profile_raw(self.uid)["attrs"]["dust"][0], initial - 2)
        self.assertEqual(self._upgrade(0, "first"), first)
        self.assertEqual(self.store.profile_raw(self.uid)["attrs"]["dust"][0], initial - 2)
        blue = self._upgrade(1, "blue")
        self.assertEqual(blue["magic"], [1, 1, 0, 0])
        self.assertEqual(blue["symp"], first["symp"])
        self._fault(3, "gold-locked", "MagicLocked")

    def test_fifth_stage_requires_all_colors_and_is_atomic(self):
        self._fault(4, "early-stage5", "MagicLocked")
        self._set_magic([1, 1, 1, 1])
        before = list(self.store.profile_raw(self.uid)['attrs']['dust'])
        result = self._upgrade(4, 'stage5')
        self.assertEqual(result['magic'], [1, 1, 1, 1])
        self.assertEqual(result['magic_stage5'], 1)
        self.assertEqual(enchantment_stage(result), 5)
        self.assertAlmostEqual(main_stat_multiplier(self.config['cfg']['system_simple'], result), 1.5)
        self.assertEqual(self.store.profile_raw(self.uid)['attrs']['dust'],
                         [value - cost for value, cost in zip(before, [2, 3, 6, 8])])
        self.assertEqual(self._upgrade(4, 'stage5'), result)
        self._fault(4, 'stage5-twice', 'MagicAtMaximum')

    def test_independent_rune_upgrade_replay_and_max(self):
        with self.assertRaises(GameplayFault) as caught:
            self.roster.dispatch(self.uid, 'user.equip_rune_up',
                                 {'eqid': self.eqid, 'actionID': 'rune-locked'})
        self.assertEqual(caught.exception.code, 'RuneLocked')
        self._set_magic([1, 0, 0, 0], symp=2)
        def seed(profile):
            profile['mark'] = 10000
            return profile, {}
        self.store.atomic_update(self.uid, seed)
        before = self.store.profile_raw(self.uid)
        request = {'eqid': self.eqid, 'actionID': 'rune-one'}
        upgraded = self.roster.dispatch(self.uid, 'user.equip_rune_up', request)
        self.assertEqual(upgraded['rune_lv'], 1)
        self.assertEqual(rune_bonus(self.config, upgraded),
                         {'hp': 0, 'ap': 0, 'de_ph': 40, 'de_ma': 0})
        self.assertEqual(rune_upgrade_cost(self.config, 2, 0), (2, 100))
        self.assertEqual(self.roster.dispatch(self.uid, 'user.equip_rune_up', request), upgraded)
        after = self.store.profile_raw(self.uid)
        self.assertEqual(after['mark'], before['mark'] - 100)
        self.assertEqual(after['attrs']['dust'][2], before['attrs']['dust'][2] - 2)
        def maxed(profile):
            profile['my_equips'][self.eqid]['rune_lv'] = 10
            return profile, {}
        self.store.atomic_update(self.uid, maxed)
        with self.assertRaises(GameplayFault) as caught:
            self.roster.dispatch(self.uid, 'user.equip_rune_up',
                                 {'eqid': self.eqid, 'actionID': 'rune-max'})
        self.assertEqual(caught.exception.code, 'RuneAtMaximum')
        self.assertEqual(self.store.profile_raw(self.uid)['mark'], after['mark'])

    def test_rune_flat_bonus_in_battle_snapshot(self):
        profile = self.store.profile_raw(self.uid)
        hero_id = profile['team'][0][0]
        profile['as_equips'] = [[self.eqid]] + [[] for _ in range(5)]
        item = profile['my_equips'][self.eqid]
        item['symp'] = 3
        without = self.roster.battle_attributes(profile, hero_id)
        item['rune_lv'] = 2
        with_rune = self.roster.battle_attributes(profile, hero_id)
        self.assertEqual(with_rune['de_ma'] - without['de_ma'], 80)
        self.assertEqual(with_rune['ap'], without['ap'])

    def test_legacy_equipment_without_rune_fields_normalizes_once(self):
        original = self.store.profile_raw(self.uid)['my_equips'][self.eqid]
        self.assertNotIn('rune_lv', original)
        self.assertNotIn('magic_stage5', original)
        self.assertEqual(self.store.login('magic-tester')['uid'], self.uid)
        migrated = self.store.profile_raw(self.uid)['my_equips'][self.eqid]
        self.assertEqual((migrated['rune_lv'], migrated['magic_stage5']), (0, 0))
        self.store.login('magic-tester')
        self.assertEqual(self.store.profile_raw(self.uid)['my_equips'][self.eqid], migrated)

    def test_level_20_price_boundary_and_level_100_cap(self):
        self._set_magic([20, 0, 0, 0], symp=2)
        before = self.store.profile_raw(self.uid)["attrs"]["dust"][0]
        raised = self._upgrade(0, "level-21")
        self.assertEqual(raised["magic"][0], 21)
        self.assertEqual(raised["symp"], 2)
        self.assertEqual(self.store.profile_raw(self.uid)["attrs"]["dust"][0], before - 3)
        self._set_magic([100, 1, 0, 0], symp=2)
        self._fault(0, "maxed", "MagicAtMaximum")
        self.assertEqual(self.store.profile_raw(self.uid)["attrs"]["dust"][0], before - 3)

    def test_client_price_cannot_bypass_insufficient_dust(self):
        def empty(profile):
            profile["attrs"]["dust"][0] = 1
            return profile, {}
        self.store.atomic_update(self.uid, empty)
        self._fault(0, "fake-free", "InsufficientResource")
        self.assertEqual(self.store.profile_raw(self.uid)["my_equips"][self.eqid]["magic"], [0, 0, 0, 0])
        self.assertEqual(self.store.profile_raw(self.uid)["attrs"]["dust"][0], 1)

    def test_battle_snapshot_applies_magic_and_same_rune_flat_bonus(self):
        profile = self.store.profile_raw(self.uid)
        hero_id = profile["team"][0][0]
        equipped = [f"test-magic-{index}" for index in range(3)]
        for eid in equipped:
            profile["my_equips"][eid] = {"eid": "E_1001_3", "lv": 1,
                                          "magic": [1, 1, 0, 0], "symp": -1}
        profile["as_equips"] = [equipped] + [[] for _ in range(5)]
        no_rune = self.roster.battle_attributes(profile, hero_id)
        for eid in equipped:
            profile["my_equips"][eid]["symp"] = 0
        with_rune = self.roster.battle_attributes(profile, hero_id)
        self.assertEqual(with_rune["hp"] - no_rune["hp"], 15000)
        self.assertEqual(with_rune["ap"], no_rune["ap"])
        for eid in equipped:
            profile["my_equips"][eid]["symp"] = -1
            profile["my_equips"][eid]["magic"] = [0, 0, 0, 0]
        bare = self.roster.battle_attributes(profile, hero_id)
        # Two first-unlocked colors provide +20% to each equipment base main
        # stat, with the old flat 120 HP / 10 AP per item added separately.
        self.assertEqual(no_rune["hp"] - bare["hp"], 3 * 120)
        self.assertGreater(no_rune["ap"] - bare["ap"], 3 * 10)

    def test_fifth_stage_increases_only_main_stat_before_rounding(self):
        profile = self.store.profile_raw(self.uid)
        hero_id = profile['team'][0][0]
        profile['as_equips'] = [[self.eqid]] + [[] for _ in range(5)]
        item = profile['my_equips'][self.eqid]
        item['magic'] = [1, 1, 1, 1]
        item['stat_roll_ppm'] = 1_000_000
        before = self.roster.battle_attributes(profile, hero_id)
        item['magic_stage5'] = 1
        after = self.roster.battle_attributes(profile, hero_id)
        simple = self.config['cfg']['system_simple']
        base_ap = self.config['cfg']['equip'][item['eid']]['pl'][1]
        expected = main_stat(base_ap, 1, simple, item, magic_rate=1.5) - \
                   main_stat(base_ap, 1, simple, item, magic_rate=1.4)
        self.assertEqual(after['ap'] - before['ap'], expected)
        self.assertEqual(after['hp'], before['hp'])
        self.assertEqual(after['hit'], before['hit'])


if __name__ == "__main__":
    unittest.main()
