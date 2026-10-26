"""Account-owned team/equipment/destiny snapshots and atomic restore boundaries."""
import copy
import json
import sqlite3
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from gameplay_roster import GameplayRosterEquipment
from player_store import GameplayFault, PlayerStore


class TeamPresetTests(unittest.TestCase):
    def setUp(self):
        self.config = json.loads((Path(__file__).resolve().parents[1] / 'config/reconstruction/full-config.json').read_bytes())
        self.db = sqlite3.connect(':memory:', check_same_thread=False)
        self.addCleanup(self.db.close)
        self.store = PlayerStore(self.db, self.config)
        self.uid = self.store.login('team-preset-test')['uid']
        self.roster = GameplayRosterEquipment(self.store, self.config)
        def seed(p):
            p['avatars'] = {f'h{i}': {'aid': 'A_1001_3', 'lv': 1, 'phase': 0} for i in range(8)}
            p['team'] = [[f'h{i}' for i in range(6)], ['h1'], []]
            p['my_equips'] = {'eq0': {'eid': 'E_1001_3', 'lv': 1}, 'eq1': {'eid': 'E_6001_2', 'slv': 1}}
            p['as_equips'] = [['eq0', None, None, None, None, 'eq1']] + [[None] * 6 for _ in range(5)]
            p['attrs']['team_num'] = 0
            p['attrs']['dn'] = {'1': [2, 'h6'], '2': [3, None]}
            return p, {}
        self.store.atomic_update(self.uid, seed)

    def call(self, op, slot, action=None, **params):
        return self.roster.dispatch(self.uid, 'user.team_preset_' + op,
                                   {'actionID': action or f'{op}-{slot}', 'slot': slot, **params})

    def change(self, fn):
        def mutate(p):
            fn(p)
            return p, {}
        self.store.atomic_update(self.uid, mutate)

    def test_four_slots_preview_captain_and_server_owned_snapshot(self):
        for slot in range(1, 5):
            answer = self.call('save', slot, team=[['forged']], as_equips=[['forged']])
        presets = answer['attrs']['team_presets']
        self.assertEqual(len(presets), 4)
        self.assertEqual([p['name'] for p in presets], ['阵容1', '阵容2', '阵容3', '阵容4'])
        for preset in presets:
            self.assertEqual([h['id'] for h in preset['preview']], [f'h{i}' for i in range(5)])
            self.assertEqual([h['leader'] for h in preset['preview']], [True, False, False, False, False])
            self.assertEqual(preset['team'][0][5], 'h5')
            self.assertEqual(preset['as_equips'][0][5], 'eq1')
            self.assertEqual(preset['dn_bindings']['1'], 'h6')
        self.change(lambda p: p['team'][0].reverse())
        self.assertEqual(self.store.profile_raw(self.uid)['attrs']['team_presets'][0]['team'][0][0], 'h0')

    def test_restore_all_assignments_preserves_growth_and_new_dn_nodes(self):
        first = self.call('save', 1)
        original_team = copy.deepcopy(first['attrs']['team_presets'][0]['team'])
        original_equips = copy.deepcopy(first['as_equips'])
        def modify(p):
            p['team'] = [['h7'] + [None] * 5, [None] * 6, [None] * 6]
            p['as_equips'] = [[None] * 6 for _ in range(6)]
            p['attrs']['team_num'] = 1
            p['attrs']['dn'] = {'1': [8, None], '2': [9, 'h6'], '3': [1, 'h0']}
            p['avatars']['h0']['lv'] = 10
            p['my_equips']['eq0']['lv'] = 5
        self.change(modify)
        restored = self.call('load', 1)
        self.assertEqual(restored['team'], original_team)
        self.assertEqual(restored['as_equips'], original_equips)
        self.assertEqual(restored['attrs']['dn'], {'1': [8, 'h6'], '2': [9, None], '3': [1, None]})
        self.assertEqual(restored['attrs']['team_num'], 0)
        self.assertEqual(restored['avatars']['h0']['lv'], 10)
        self.assertEqual(restored['my_equips']['eq0']['lv'], 5)

    def test_slot_bounds_empty_team_and_empty_load_do_not_commit(self):
        for slot in (0, 5, -1, 1.5, True, '1', None):
            before = self.store.profile_raw(self.uid)
            with self.assertRaises(GameplayFault):
                self.call('save', slot)
            self.assertEqual(before, self.store.profile_raw(self.uid))
        with self.assertRaises(GameplayFault) as caught:
            self.call('load', 4)
        self.assertEqual(caught.exception.code, 'EmptyPreset')
        self.change(lambda p: p.update(team=[[None] * 6 for _ in range(3)]))
        with self.assertRaises(GameplayFault) as caught:
            self.call('save', 1)
        self.assertEqual(caught.exception.code, 'EmptyPresetTeam')

    def test_missing_hero_or_equipment_rejects_whole_restore(self):
        for asset, key in [('avatars', 'h0'), ('my_equips', 'eq0')]:
            self.call('save', 1, action='save-' + asset)
            original = self.store.profile_raw(self.uid)[asset][key]
            self.change(lambda p: p[asset].pop(key))
            before = self.store.profile_raw(self.uid)
            with self.assertRaises(GameplayFault) as caught:
                self.call('load', 1, action='missing-' + asset)
            self.assertEqual(caught.exception.code, 'PresetMissingAssets')
            self.assertEqual(before, self.store.profile_raw(self.uid))
            self.change(lambda p: p[asset].update({key: original}))

    def test_invalid_equipment_or_dn_conflict_rolls_back_team_change(self):
        self.call('save', 1)
        for kind in ('equipment', 'dn'):
            def corrupt(p):
                preset = p['attrs']['team_presets'][0]
                if kind == 'equipment':
                    preset['as_equips'][1][0] = 'eq0'
                else:
                    preset['as_equips'][1][0] = None
                    preset['dn_bindings']['1'] = 'h0'
            self.change(corrupt)
            before = self.store.profile_raw(self.uid)
            with self.assertRaises(GameplayFault):
                self.call('load', 1, action=kind)
            self.assertEqual(before, self.store.profile_raw(self.uid))

    def test_delete_overwrite_and_replays_are_isolated_per_slot(self):
        self.call('save', 1)
        self.call('save', 2)
        self.call('delete', 1, action='delete-once')
        self.assertIsNone(self.store.profile_raw(self.uid)['attrs']['team_presets'][0])
        self.call('save', 1, action='save-after-delete')
        before = self.store.profile_raw(self.uid)
        self.call('delete', 1, action='delete-once')
        self.assertEqual(before, self.store.profile_raw(self.uid))
        self.assertIsNotNone(before['attrs']['team_presets'][1])

    def test_persistence_and_account_isolation(self):
        self.call('save', 4)
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'players.sqlite3'
            disk = sqlite3.connect(str(path), check_same_thread=False)
            self.db.backup(disk)
            disk.close()
            disk = sqlite3.connect(str(path), check_same_thread=False)
            try:
                store = PlayerStore(disk, self.config)
                profile = store.profile_raw(self.uid)
                self.assertEqual(profile['attrs']['team_presets'][3]['preview'][0]['id'], 'h0')
                other_uid = store.login('other-preset-account')['uid']
                other = GameplayRosterEquipment(store, self.config)
                with self.assertRaises(GameplayFault) as caught:
                    other.dispatch(other_uid, 'user.team_preset_load', {'slot': 4, 'actionID': 'other-load'})
                self.assertEqual(caught.exception.code, 'EmptyPreset')
            finally:
                disk.close()

    def test_authenticated_amf_receipt_contains_preset_in_state_sync(self):
        from gateway import Backend
        from pyamf import remoting
        root = Path(__file__).resolve().parents[1]
        backend = Backend(':memory:', root / 'config/reconstruction/full-config.json')
        self.addCleanup(backend.db.close)
        credentials = {'pf': 'local', 'session_key': 'preset-gateway-test', 'sessionid': 'test-password'}
        backend.call({'method': 'user.register', 'params': {'actionID': 'register', **credentials}})
        login = backend.call({'method': 'user.login', 'params': {'actionID': 'login', **credentials}})['data']
        def seed(p):
            p['avatars'] = {'hero': {'aid': 'A_1001_3', 'lv': 1}}
            p['team'] = [['hero'], [], []]
            return p, {}
        backend.players.atomic_update(login['uid'], seed)
        envelope = remoting.Envelope(amfVersion=3)
        envelope['/1'] = remoting.Request(target='http_api', body=[{
            'method': 'user.team_preset_save', 'uid': login['uid'], 'sessionid': login['sessionid'],
            'params': {'actionID': 'save-preset', 'slot': 1}}])
        raw = backend.process(remoting.encode(envelope, strict=True).getvalue())
        reply = list(remoting.decode(raw))[0][1].body
        self.assertEqual(reply['return_code'], 0)
        preset = reply['state_sync']['profile']['attrs']['team_presets'][0]
        self.assertEqual(len(preset['preview']), 5)
        self.assertEqual(preset['preview'][0]['id'], 'hero')
        self.assertTrue(preset['preview'][0]['leader'])
        self.assertEqual(reply['state_sync']['profile']['avatars']['hero']['lock'], 1)


if __name__ == '__main__':
    unittest.main()
