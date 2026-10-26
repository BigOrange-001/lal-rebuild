"""Arena requests through the production gateway and native AMF date conversion."""
import datetime
import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pyamf import remoting
from arena_opponents import combat_config_signature
from gateway import Backend
from player_store import native_dates

CONFIG = Path(__file__).resolve().parents[1] / 'config/reconstruction/full-config.json'


class ArenaGatewayTests(unittest.TestCase):
    def test_raw_and_native_config_dates_have_the_same_signature(self):
        cfg = json.loads(CONFIG.read_text('utf8'))['cfg']
        self.assertEqual(combat_config_signature(cfg),
                         combat_config_signature(native_dates(cfg)))
        raw = {'system_simple': {'window': [{'$date': 1767225600}]}}
        native = native_dates(raw)
        self.assertEqual(combat_config_signature(raw), combat_config_signature(native))
        native['system_simple']['window'][0] += datetime.timedelta(seconds=1)
        self.assertNotEqual(combat_config_signature(raw), combat_config_signature(native))

    def test_aware_dates_use_their_actual_utc_time(self):
        utc = datetime.datetime(2026, 1, 1, tzinfo=datetime.timezone.utc)
        local = utc.astimezone(datetime.timezone(datetime.timedelta(hours=8)))
        self.assertEqual(combat_config_signature({'system_simple': {'time': utc}}),
                         combat_config_signature({'system_simple': {'time': local}}))
        with self.assertRaises(TypeError):
            combat_config_signature({'system_simple': {'unsupported': object()}})

    def test_authenticated_amf_rank_list_refresh_and_retry(self):
        backend = Backend(':memory:', CONFIG)
        self.addCleanup(backend.db.close)
        credentials = {'pf': 'local', 'session_key': 'arena-gateway-test', 'sessionid': 'test-password'}
        backend.call({'method': 'user.register', 'params': {'actionID': 'register', **credentials}})
        login = backend.call({'method': 'user.login', 'params': {'actionID': 'login', **credentials}})['data']

        def rpc(method, action):
            envelope = remoting.Envelope(amfVersion=3)
            envelope['/1'] = remoting.Request(target='http_api', body=[{
                'method': method, 'uid': login['uid'], 'sessionid': login['sessionid'],
                'params': {'actionID': action}}])
            response = backend.process(remoting.encode(envelope, strict=True).getvalue())
            reply = list(remoting.decode(response))[0][1].body
            self.assertEqual(reply['return_code'], 0)
            self.assertIsInstance(reply['server_now'], datetime.datetime)
            return reply['data']

        initial = rpc('user.get_rank_list', 'rank-list')
        self.assertEqual(len(initial), 7)
        self.assertEqual(len(initial[2]), 10)
        self.assertEqual(initial[1][0][1], login['uid'])
        self.assertEqual(rpc('user.get_rank_list', 'rank-list-retry')[2], initial[2])
        refreshed = rpc('user.refresh_pvp_opponents', 'refresh')
        self.assertEqual(len(refreshed[2]), 10)
        self.assertNotEqual([row[1] for row in refreshed[2]], [row[1] for row in initial[2]])
        self.assertEqual(rpc('user.refresh_pvp_opponents', 'refresh')[2], refreshed[2])
        self.assertEqual(rpc('user.get_rank_list', 'rank-list-after-refresh')[2], refreshed[2])


if __name__ == '__main__':
    unittest.main()
