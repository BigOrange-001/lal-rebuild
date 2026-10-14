"""Equipment transaction boundaries on an isolated in-memory player store."""
import copy
import json
import sqlite3
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from equipment_magic import apply_equipment_magic_config
from gameplay_roster import GameplayRosterEquipment
from player_store import GameplayFault, PlayerStore


class EquipmentFlowTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = json.loads((Path(__file__).resolve().parents[1] /
                                 'config/reconstruction/full-config.json').read_text(encoding='utf-8'))

    def setUp(self):
        self.config = apply_equipment_magic_config(self.source)
        self.db = sqlite3.connect(':memory:', check_same_thread=False)
        self.addCleanup(self.db.close)
        self.store = PlayerStore(self.db, self.config)
        self.uid = self.store.login('equipment-flow-test')['uid']
        self.roster = GameplayRosterEquipment(self.store, self.config)

        def seed(profile):
            profile['my_equips'] = {
                'eq0': {'eid': 'E_1001_3', 'lv': 1, 'alchemy': [0, 0]},
                'eq1': {'eid': 'E_1001_3', 'lv': 1, 'alchemy': [0, 0]},
            }
            profile['as_equips'] = [[] for _ in range(6)]
            profile['coin'] = 100000
            profile['mark'] = 100000
            return profile, {}
        self.store.atomic_update(self.uid, seed)

    def call(self, method, action, **params):
        return self.roster.dispatch(self.uid, method, {'actionID': action, **params})

    def fault(self, code, method, action, **params):
        with self.assertRaises(GameplayFault) as caught:
            self.call(method, action, **params)
        self.assertEqual(caught.exception.code, code)

    def test_full_bag_sale_replay_then_mail_claim(self):
        self.config['cfg']['system_simple']['equip_config'][0] = 2
        mail = self.store.send_mail('equipment-flow-test', 'equipment',
                                    {'equip': {'E_1001_3': 1}}, 'equip-flow-mail')
        with self.assertRaises(GameplayFault) as caught:
            self.store.claim(self.uid, mail)
        self.assertEqual(caught.exception.code, 'EquipCapacity')
        sold = self.call('user.equip_sell', 'sell-eq1', eqids=['eq1'])
        self.assertEqual(sold, self.call('user.equip_sell', 'sell-eq1', eqids=['eq1']))
        self.assertEqual(set(self.store.profile_raw(self.uid)['my_equips']), {'eq0'})
        self.store.claim(self.uid, mail)
        self.assertEqual(len(self.store.profile_raw(self.uid)['my_equips']), 2)

    def test_sale_rejects_equipped_locked_pending_and_duplicate_atomically(self):
        def protect(profile):
            profile['as_equips'][0] = ['eq0']
            profile['my_equips']['eq1']['lock'] = 1
            return profile, {}
        self.store.atomic_update(self.uid, protect)
        before = self.store.profile_raw(self.uid)
        self.fault('EquipmentInUse', 'user.equip_sell', 'equipped', eqids=['eq0'])
        self.fault('EquipmentLocked', 'user.equip_sell', 'locked', eqids=['eq1'])
        self.assertEqual(self.store.profile_raw(self.uid)['my_equips'], before['my_equips'])
        def pending(profile):
            profile['as_equips'][0] = []
            profile['my_equips']['eq1']['lock'] = 0
            profile['attrs']['equip_wash'] = {'eqid': 'eq1', 'rolled': {'hit': 1}}
            return profile, {}
        self.store.atomic_update(self.uid, pending)
        self.fault('InvalidSelection', 'user.equip_sell', 'duplicate', eqids=['eq0', 'eq0'])
        self.fault('PendingOperation', 'user.equip_sell', 'pending', eqids=['eq1'])
        self.assertIn('eq1', self.store.profile_raw(self.uid)['my_equips'])

    def test_wash_save_cancel_relogin_and_alchemy_replay(self):
        original = copy.deepcopy(self.store.profile_raw(self.uid)['my_equips']['eq0'])
        rolled = self.call('user.equip_wash', 'wash-1', eqid='eq0', num=1, ttype='coin')
        self.assertEqual(len(rolled), 2)
        pending = self.store.profile_raw(self.uid)['attrs']['equip_wash']
        self.assertEqual(pending['eqid'], 'eq0')
        self.assertEqual(self.call('user.equip_wash', 'wash-1', eqid='eq0', num=1, ttype='coin'), rolled)
        saved = self.call('user.equip_wash_save', 'save-1')
        self.assertEqual(saved, self.call('user.equip_wash_save', 'save-1'))
        self.assertNotIn('equip_wash', self.store.profile_raw(self.uid)['attrs'])
        self.assertNotEqual(saved['new_4attrs'], original.get('new_4attrs'))
        self.call('user.equip_wash', 'wash-2', eqid='eq0', num=10, ttype='mark')
        after_second_roll = copy.deepcopy(self.store.profile_raw(self.uid)['my_equips']['eq0'])
        self.call('user.equip_wash_cancel', 'cancel-2')
        self.assertEqual(self.store.profile_raw(self.uid)['my_equips']['eq0']['new_4attrs'],
                         after_second_roll['new_4attrs'])
        self.assertNotIn('equip_wash', self.store.profile_raw(self.uid)['attrs'])
        alchemy = self.call('user.equip_alchemy', 'alchemy-1', eqids=['eq0', 'eq1'])
        self.assertEqual(alchemy, self.call('user.equip_alchemy', 'alchemy-1', eqids=['eq0', 'eq1']))
        profile = self.store.profile_raw(self.uid)
        self.assertIn('eq0', profile['my_equips'])
        self.assertNotIn('eq1', profile['my_equips'])
        self.assertNotEqual(profile['my_equips']['eq0']['alchemy'], [0, 0])

    def test_alchemy_rejects_locked_or_higher_star_material(self):
        def locked(profile):
            profile['my_equips']['eq1']['lock'] = 1
            return profile, {}
        self.store.atomic_update(self.uid, locked)
        self.fault('EquipmentLocked', 'user.equip_alchemy', 'locked-mat', eqids=['eq0', 'eq1'])
        def advanced(profile):
            profile['my_equips']['eq1']['lock'] = 0
            profile['my_equips']['eq1']['alchemy'] = [0, 1]
            return profile, {}
        self.store.atomic_update(self.uid, advanced)
        self.fault('IncompatibleEquipment', 'user.equip_alchemy', 'advanced-mat', eqids=['eq0', 'eq1'])
        self.assertEqual(set(self.store.profile_raw(self.uid)['my_equips']), {'eq0', 'eq1'})


if __name__ == '__main__':
    unittest.main()
