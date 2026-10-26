"""Preset asset protection and bounded, idempotent dust batches."""
import copy
import json
import sqlite3
import unittest
from pathlib import Path
from unittest.mock import patch

from equipment_magic import apply_equipment_magic_config
from equipment_magic import upgrade_cost as magic_upgrade_cost
from gameplay_roster import GameplayRosterEquipment
from inventory_locks import migrate_preset_locks
from player_store import GameplayFault, PlayerStore


class InventoryMagic103Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = json.loads((Path(__file__).resolve().parents[1] / 'config/reconstruction/full-config.json').read_text('utf-8'))

    def setUp(self):
        self.config = apply_equipment_magic_config(self.source)
        self.db = sqlite3.connect(':memory:', check_same_thread=False)
        self.addCleanup(self.db.close)
        self.store = PlayerStore(self.db, self.config)
        self.uid = self.store.login('inventory-magic-test')['uid']
        self.roster = GameplayRosterEquipment(self.store, self.config)
        def seed(p):
            p['avatars'] = {f'h{i}': {'aid': 'A_1001_3', 'lv': 1} for i in range(4)}
            p['team'] = [['h0', 'h1'] + [None] * 4, [None] * 6, [None] * 6]
            p['attrs']['dn'] = {'1': [1, 'h2']}
            p['my_equips'] = {'eq0': {'eid': 'E_1001_3', 'lv': 1},
                              'eq1': {'eid': 'E_6001_2', 'slv': 1}}
            p['as_equips'] = [['eq0', None, None, None, None, 'eq1']] + [[None] * 6 for _ in range(5)]
            p['attrs']['dust'] = [10000] * 4
            p['gold'] = 100000
        self.change(seed)

    def change(self, fn):
        def mutate(p):
            fn(p)
            return p, {}
        self.store.atomic_update(self.uid, mutate)

    def call(self, method, action='op', **params):
        return self.roster.dispatch(self.uid, method, {'actionID': action, **params})

    def fault(self, code, method, **params):
        before = self.store.profile_raw(self.uid)
        with self.assertRaises(GameplayFault) as caught:
            self.call(method, **params)
        self.assertEqual(caught.exception.code, code)
        self.assertEqual(self.store.profile_raw(self.uid), before)

    def test_preset_locks_main_assist_dn_and_equipment_without_unlock_on_delete(self):
        self.call('user.team_preset_save', 'save', slot=1)
        p = self.store.profile_raw(self.uid)
        self.assertTrue(all(p['avatars'][h]['lock'] == 1 for h in ('h0', 'h1', 'h2')))
        self.assertFalse(p['avatars']['h3'].get('lock'))
        self.assertTrue(all(e['lock'] == 1 for e in p['my_equips'].values()))
        self.call('user.team_preset_delete', 'delete', slot=1)
        self.assertTrue(self.store.profile_raw(self.uid)['my_equips']['eq0']['lock'])

    def test_explicit_unlock_survives_relogin_and_save_relocks(self):
        self.call('user.team_preset_save', 'save', slot=1)
        self.call('user.inventory_lock', 'unlock', kind='hero', id='h1', locked=False)
        self.call('user.inventory_lock', 'unlock-eq', kind='equipment', id='eq1', locked=False)
        self.store.login('inventory-magic-test')
        p = self.store.profile_raw(self.uid)
        self.assertEqual(p['avatars']['h1']['lock'], 0)
        self.assertEqual(p['my_equips']['eq1']['lock'], 0)
        self.call('user.team_preset_save', 'save-again', slot=1)
        self.assertEqual(self.store.profile_raw(self.uid)['avatars']['h1']['lock'], 1)

    def test_legacy_preset_migration_runs_once(self):
        p = self.store.profile_raw(self.uid)
        p['attrs'].pop('preset_auto_lock_version', None)
        p['attrs']['team_presets'] = [{'team': [['h3']], 'as_equips': [['eq1']], 'dn_bindings': {'1': 'h2'}}]
        self.assertTrue(migrate_preset_locks(p))
        self.assertEqual(p['avatars']['h3']['lock'], 1)
        p['avatars']['h3']['lock'] = 0
        self.assertFalse(migrate_preset_locks(p))
        self.assertEqual(p['avatars']['h3']['lock'], 0)

    def test_server_rejects_locked_hero_material_and_equipment_after_unassigning(self):
        self.call('user.team_preset_save', 'save', slot=1)
        self.change(lambda p: p.update(team=[['h3'] + [None] * 5, [], []], as_equips=[[] for _ in range(6)]))
        self.fault('HeroLocked', 'user.swallow_avatar', aid='h3', aids=['h1'])
        self.fault('HeroLocked', 'user.sell_avatars', aids=['h1'])
        self.fault('EquipmentLocked', 'user.equip_sell', eqids=['eq0'])
        self.change(lambda p: p['my_equips'].update(eq2={'eid': 'E_6001_2', 'slv': 1}))
        self.fault('EquipmentLocked', 'user.swallow_skillbook', eqid='eq2', eqids=['eq1'])

    def test_strengthened_copy_is_valid_phase_material_but_locked_copy_is_not(self):
        self.change(lambda p: p['avatars']['h3'].update(lv=40,slv=6,hp=2000,ap=50,lock=1))
        self.fault('HeroLocked','user.phase_up',aid='h0',aids=['h3'])
        self.call('user.inventory_lock','unlock-phase',kind='hero',id='h3',locked=False)
        self.call('user.phase_up','phase',aid='h0',aids=['h3'])
        profile=self.store.profile_raw(self.uid)
        self.assertNotIn('h3',profile['avatars'])
        self.assertEqual(profile['avatars']['h0']['phase'],1)

    def test_lock_input_and_ownership_are_validated(self):
        self.fault('UnknownHero', 'user.inventory_lock', kind='hero', id='other-account', locked=True)
        self.fault('InvalidSelection', 'user.inventory_lock', kind='hero', id='h3', locked=1)
        self.fault('InvalidSelection', 'user.inventory_lock', kind='anything', id='h3', locked=True)

    def test_ten_upgrades_price_each_level_and_replay_does_not_repeat(self):
        self.change(lambda p: p['my_equips']['eq0'].update(magic=[9, 0, 0, 0]))
        expected = sum(magic_upgrade_cost(self.roster.simple, 0, lv) for lv in range(9, 19))
        with patch('gameplay_roster.random.randrange', return_value=2) as draw:
            result = self.call('user.add_magic', 'magic-ten', eqid='eq0', color=0, times=10)
            self.assertEqual(draw.call_count, 10)
            replay = self.call('user.add_magic', 'magic-ten', eqid='eq0', color=0, times=10)
            self.assertEqual(draw.call_count, 10)
        self.assertEqual(result['magic_batch']['completed'], 10)
        self.assertEqual(result['magic_batch']['dust_spent'], expected)
        self.assertEqual(replay['magic_batch'], result['magic_batch'])
        self.assertEqual(self.store.profile_raw(self.uid)['attrs']['dust'][0], 10000 - expected)
        self.assertEqual(self.store.profile_raw(self.uid)['my_equips']['eq0']['magic'][0], 19)

    def test_partial_batch_stops_at_cap_or_insufficient_dust(self):
        cap = int(self.roster.simple['dust']['max'][0])
        self.change(lambda p: p['my_equips']['eq0'].update(magic=[cap - 3, 0, 0, 0]))
        result = self.call('user.add_magic', 'cap', eqid='eq0', color=0, times=10)
        self.assertEqual(result['magic_batch']['completed'], 3)
        self.assertEqual(result['magic_batch']['stop_reason'], 'maximum')
        first = magic_upgrade_cost(self.roster.simple, 0, 0)
        self.change(lambda p: (p['my_equips']['eq0'].update(magic=[0, 0, 0, 0]), p['attrs'].update(dust=[first * 2, 0, 0, 0])))
        result = self.call('user.add_magic', 'poor', eqid='eq0', color=0, times=10)
        self.assertEqual(result['magic_batch']['completed'], 2)
        self.assertEqual(result['magic_batch']['stop_reason'], 'insufficient_dust')
        self.assertEqual(self.store.profile_raw(self.uid)['attrs']['dust'][0], 0)

    def test_invalid_batch_or_unavailable_stage_never_charges(self):
        for times in (True, '10', 0, 2, 11):
            self.fault('InvalidSelection', 'user.add_magic', eqid='eq0', color=0, times=times)
        self.fault('InvalidSelection', 'user.add_magic', eqid='eq0', color=4, times=10)
        self.fault('MagicLocked', 'user.add_magic', eqid='eq0', color=1, times=10)
        self.change(lambda p: p['attrs'].update(dust=[0] * 4))
        self.fault('InsufficientResource', 'user.add_magic', eqid='eq0', color=0, times=10)


if __name__ == '__main__':
    unittest.main()
