"""Regressions for preserving native helpers when a new hero is enabled."""
import copy
import json
from pathlib import Path
import sys
from types import SimpleNamespace
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))
from gameplay_social import GameplaySocial


class ModAssistTests(unittest.TestCase):
    def test_one_new_hero_has_one_helper_and_keeps_native_captains(self):
        root = Path(__file__).resolve().parents[1]
        base = json.loads((root / 'config/reconstruction/full-config.json').read_text('utf-8'))
        cfg = base.get('cfg', base)
        source = next(aid for aid in cfg['avatar'] if aid.startswith('A_1') and aid.endswith('_6'))
        config = copy.deepcopy(base)
        cfg = config.get('cfg', config)
        aid = 'A_180000_6'
        cfg['avatar'][aid] = copy.deepcopy(cfg['avatar'][source])
        cfg['mod_runtime'] = {'heroes': {aid: {'kind': 'new', 'available': True, 'channels': {}}}}
        store = SimpleNamespace(clock=SimpleNamespace(now=lambda: 0))
        native, enabled = GameplaySocial(store, base), GameplaySocial(store, config)
        self.assertEqual([row['team'] for row in enabled.bots], [row['team'] for row in native.bots])
        self.assertEqual(len(enabled.mod_bots), 1)
        self.assertEqual(next(iter(enabled.mod_bots[0]['avatars'])).split('|')[0], aid)
        self.assertFalse(set(row['uid'] for row in enabled.bots) & set(row['uid'] for row in enabled.mod_bots))
        cfg['mod_runtime']['heroes'][aid]['channels']['appearance.assist_bot'] = False
        self.assertEqual(GameplaySocial(store, config).mod_bots, [])


if __name__ == '__main__':
    unittest.main()
