"""Stardust decomposition, stardust alchemy and affix inheritance."""
import json
import sqlite3
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from equipment_growth_v2 import template_wash_stats, wash_stats
from equipment_magic import apply_equipment_magic_config
from equipment_stardust import alchemy_cost, decompose_yield, stardust_for_star
from gameplay_roster import GameplayRosterEquipment
from player_store import GameplayFault, PlayerStore


class FixedRandom:
    def __init__(self, value):
        self.value = value

    def random(self):
        return self.value

    @staticmethod
    def randint(low, _high):
        return low


class StardustRulesTest(unittest.TestCase):
    def test_yield_tracks_alchemy_copy_value(self):
        self.assertEqual([stardust_for_star(s) for s in range(1, 9)],
                         [1, 4, 16, 64, 256, 1024, 4096, 16384])
        self.assertEqual(decompose_yield({'eid': 'E_1001_6', 'alchemy': [2, 0]}), 3072)
        # A 5-star base alchemized to 6 stars is worth a native 6-star item.
        self.assertEqual(decompose_yield({'eid': 'E_1001_5', 'alchemy': [0, 1]}),
                         decompose_yield({'eid': 'E_1002_6', 'alchemy': [0, 0]}))
        self.assertEqual(decompose_yield({'eid': 'E_6001_2'}), 0)

    def test_alchemy_cost_is_five_same_star_copies(self):
        self.assertEqual(alchemy_cost({'eid': 'E_1001_6', 'alchemy': [0, 0]}), 5 * 1024)
        # The in-star phase does not change which copy ordinary alchemy needs.
        self.assertEqual(alchemy_cost({'eid': 'E_1001_6', 'alchemy': [2, 1]}), 5 * 4096)


class StardustFlowTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = json.loads((Path(__file__).resolve().parents[1] /
                                 'config/reconstruction/full-config.json').read_text(encoding='utf-8'))

    def setUp(self):
        self.config = apply_equipment_magic_config(self.source)
        self.simple = self.config['cfg']['system_simple']
        self.db = sqlite3.connect(':memory:', check_same_thread=False)
        self.addCleanup(self.db.close)
        self.store = PlayerStore(self.db, self.config)
        self.uid = self.store.login('stardust-test')['uid']
        self.roster = GameplayRosterEquipment(self.store, self.config)

        def seed(profile):
            profile['my_equips'] = {
                'eq0': {'eid': 'E_1001_3', 'lv': 1, 'alchemy': [0, 0]},
                'eq1': {'eid': 'E_1001_3', 'lv': 1, 'alchemy': [0, 0]},
                'eq2': {'eid': 'E_1002_3', 'lv': 1, 'alchemy': [0, 0]},
                'eq3': {'eid': 'E_3001_3', 'lv': 1, 'alchemy': [0, 0]},
                'eq4': {'eid': 'E_1503_3', 'lv': 1, 'alchemy': [0, 0]},
                'eq5': {'eid': 'E_1502_3', 'lv': 1, 'alchemy': [0, 0]},
                'eq6': {'eid': 'E_1504_3', 'lv': 1, 'alchemy': [0, 0]},
                'book': {'eid': 'E_6001_2', 'lv': 1, 'slv': 1},
            }
            profile['as_equips'] = [[] for _ in range(6)]
            profile['vip_lv'] = 0
            return profile, {}
        self.store.atomic_update(self.uid, seed)

    def call(self, method, action, **params):
        return self.roster.dispatch(self.uid, method, {'actionID': action, **params})

    def fault(self, code, method, action, **params):
        before = self.store.profile_raw(self.uid)
        with self.assertRaises(GameplayFault) as caught:
            self.call(method, action, **params)
        self.assertEqual(caught.exception.code, code)
        self.assertEqual(self.store.profile_raw(self.uid), before)

    def patch(self, fn):
        def change(profile):
            fn(profile)
            return profile, {}
        self.store.atomic_update(self.uid, change)

    def test_decompose_adds_stardust_to_sale_refund_and_replays(self):
        item = self.store.profile_raw(self.uid)['my_equips']['eq1']
        gold, mark, dust = self.roster._equip_sell_rewards(item)
        before = self.store.profile_raw(self.uid)
        result = self.call('user.equip_decompose', 'dec-1', eqids=['eq1', 'eq2'])
        self.assertEqual(result['stardust_gain'], 32)
        self.assertEqual(self.call('user.equip_decompose', 'dec-1', eqids=['eq1', 'eq2']), result)
        after = self.store.profile_raw(self.uid)
        self.assertNotIn('eq1', after['my_equips'])
        self.assertNotIn('eq2', after['my_equips'])
        self.assertEqual(after['attrs']['stardust'], 32)
        self.assertEqual(after['gold'], before['gold'] + 2 * gold)
        self.assertEqual(after['mark'], before['mark'] + 2 * mark)
        self.assertEqual(after['attrs']['dust'],
                         [a + 2 * b for a, b in zip(before['attrs'].get('dust', [0, 0, 0, 0]), dust)])

    def test_decompose_rejects_protected_items_atomically(self):
        self.patch(lambda p: p['as_equips'].__setitem__(0, ['eq0']))
        self.fault('EquipmentInUse', 'user.equip_decompose', 'worn', eqids=['eq1', 'eq0'])
        self.patch(lambda p: p['my_equips']['eq1'].__setitem__('lock', 1))
        self.fault('EquipmentLocked', 'user.equip_decompose', 'locked', eqids=['eq2', 'eq1'])
        self.patch(lambda p: p['attrs'].__setitem__('equip_wash', {'eqid': 'eq2', 'rolled': {}}))
        self.fault('PendingOperation', 'user.equip_decompose', 'pending', eqids=['eq2'])
        self.fault('IncompatibleEquipment', 'user.equip_decompose', 'book', eqids=['book'])
        self.fault('InvalidSelection', 'user.equip_decompose', 'dup', eqids=['eq3', 'eq3'])

    def test_stardust_alchemy_spends_five_copies_and_keeps_inventory(self):
        cost = 5 * 16
        self.patch(lambda p: p['attrs'].__setitem__('stardust', cost - 1))
        self.fault('InsufficientStardust', 'user.equip_alchemy', 'poor', eqids=['eq0'], stardust=1)
        self.patch(lambda p: p['attrs'].__setitem__('stardust', cost + 7))
        before = self.store.profile_raw(self.uid)
        result = self.call('user.equip_alchemy', 'rich', eqids=['eq0'], stardust=1)
        self.assertEqual(self.call('user.equip_alchemy', 'rich', eqids=['eq0'], stardust=1), result)
        after = self.store.profile_raw(self.uid)
        self.assertEqual(after['my_equips']['eq0']['alchemy'], [1, 0])
        self.assertEqual(after['attrs']['stardust'], 7)
        self.assertEqual(set(after['my_equips']), set(before['my_equips']))
        self.assertEqual((after['gold'], after['mark']), (before['gold'], before['mark']))
        self.fault('InvalidSelection', 'user.equip_alchemy', 'two', eqids=['eq0', 'eq1'], stardust=1)
        self.fault('IncompatibleEquipment', 'user.equip_alchemy', 'book-alc', eqids=['book'], stardust=1)

    def test_stardust_alchemy_keeps_vip_bonus_and_star_cap(self):
        self.patch(lambda p: (p.__setitem__('vip_lv', 15), p['attrs'].__setitem__('stardust', 10 ** 9)))
        self.roster.rng = FixedRandom(0.0)
        result = self.call('user.equip_alchemy', 'vip', eqids=['eq0'], stardust=1)
        self.assertEqual(result['alchemy_bonus_step'], 1)
        self.assertEqual(self.store.profile_raw(self.uid)['my_equips']['eq0']['alchemy'], [2, 0])
        max_star = min(8, int(self.simple['equip_alchemy']['star_lv']))
        self.patch(lambda p: p['my_equips']['eq0'].__setitem__('alchemy', [0, max_star - 3]))
        self.fault('MaxGrowth', 'user.equip_alchemy', 'capped', eqids=['eq0'], stardust=1)

    def test_ordinary_alchemy_is_unchanged(self):
        self.roster.rng = FixedRandom(0.99)
        result = self.call('user.equip_alchemy', 'normal', eqids=['eq0', 'eq1'])
        after = self.store.profile_raw(self.uid)
        self.assertEqual(result['alchemy_bonus_step'], 0)
        self.assertEqual(after['my_equips']['eq0']['alchemy'], [1, 0])
        self.assertNotIn('eq1', after['my_equips'])
        self.assertNotIn('stardust', after['attrs'])

    def test_inheritance_adds_displayed_affixes_up_to_three_times(self):
        profile = self.store.profile_raw(self.uid)
        equipment = self.config['cfg']['equip']
        target_mark = self.roster._equip_sell_rewards(profile['my_equips']['eq0'])[1]
        expected = {key: 0 for key in ('hit', 'flee', 'crit', 'tough')}
        for action, mat in (('inh-1', 'eq2'), ('inh-2', 'eq4'), ('inh-3', 'eq5')):
            item = self.store.profile_raw(self.uid)['my_equips'][mat]
            gained = template_wash_stats(item, equipment[item['eid']], self.simple)
            refund = self.roster._equip_sell_rewards(item)
            before = self.store.profile_raw(self.uid)
            result = self.call('user.equip_inherit', action, eqids=['eq0', mat])
            self.assertEqual(self.call('user.equip_inherit', action, eqids=['eq0', mat]), result)
            after = self.store.profile_raw(self.uid)
            for key in expected:
                expected[key] += gained[key]
            self.assertEqual(after['my_equips']['eq0']['inherit_4attrs'], expected)
            self.assertNotIn(mat, after['my_equips'])
            self.assertEqual(after['gold'], before['gold'] + refund[0])
            self.assertEqual(after['mark'], before['mark'] + refund[1])
            self.assertEqual(after['attrs'].get('stardust', 0), before['attrs'].get('stardust', 0))
        self.assertEqual(self.store.profile_raw(self.uid)['my_equips']['eq0']['inherit_count'], 3)
        self.assertTrue(all(expected.values()))
        self.fault('MaxGrowth', 'user.equip_inherit', 'inh-4', eqids=['eq0', 'eq6'])
        target = self.store.profile_raw(self.uid)['my_equips']['eq0']
        # Inherited points never become sale marks, so they cannot be farmed.
        self.assertEqual(self.roster._equip_sell_rewards(target)[1], target_mark)
        own = template_wash_stats(target, equipment['E_1001_3'], self.simple)
        self.assertEqual(wash_stats(target, equipment['E_1001_3'], self.simple),
                         {key: own[key] + expected[key] for key in expected})

    def test_inheritance_does_not_chain_material_inheritance(self):
        self.call('user.equip_inherit', 'chain-1', eqids=['eq1', 'eq2'])
        mat = self.store.profile_raw(self.uid)['my_equips']['eq1']
        own = template_wash_stats(mat, self.config['cfg']['equip']['E_1001_3'], self.simple)
        self.call('user.equip_inherit', 'chain-2', eqids=['eq0', 'eq1'])
        self.assertEqual(self.store.profile_raw(self.uid)['my_equips']['eq0']['inherit_4attrs'], own)

    def test_inheritance_rejects_other_slots_and_protected_material(self):
        self.fault('IncompatibleEquipment', 'user.equip_inherit', 'slot', eqids=['eq0', 'eq3'])
        self.fault('IncompatibleEquipment', 'user.equip_inherit', 'book-inh', eqids=['eq0', 'book'])
        self.patch(lambda p: p['my_equips']['eq2'].__setitem__('lock', 1))
        self.fault('EquipmentLocked', 'user.equip_inherit', 'locked-mat', eqids=['eq0', 'eq2'])
        self.patch(lambda p: p['as_equips'].__setitem__(0, ['eq4']))
        self.fault('EquipmentInUse', 'user.equip_inherit', 'worn-mat', eqids=['eq0', 'eq4'])
        # A worn target may receive affixes.
        self.patch(lambda p: p['as_equips'].__setitem__(0, ['eq0']))
        self.call('user.equip_inherit', 'worn-target', eqids=['eq0', 'eq5'])

    def test_inherited_affixes_reach_battle_snapshot(self):
        profile = self.store.profile_raw(self.uid)
        hero_id = profile['team'][0][0]
        profile['as_equips'] = [['eq0']] + [[] for _ in range(5)]
        before = self.roster.battle_attributes(profile, hero_id)
        profile['my_equips']['eq0']['inherit_4attrs'] = {'hit': 0, 'flee': 11, 'crit': 0, 'tough': 7}
        after = self.roster.battle_attributes(profile, hero_id)
        self.assertEqual(after['flee'] - before['flee'], 11)
        self.assertEqual(after['tough'] - before['tough'], 7)
        self.assertEqual(after['hit'], before['hit'])


if __name__ == '__main__':
    unittest.main()
