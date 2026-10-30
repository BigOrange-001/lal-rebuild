import json
from pathlib import Path
import tempfile
import unittest
import io
from unittest.mock import patch

from hero_strength_freeze_104 import freeze_study
from run_hero_strength_independent_104 import focal_schedule, validate_games


class FrozenStudyTests(unittest.TestCase):
    def fixture(self, directory):
        root = Path(directory) / 'root'
        (root / 'server').mkdir(parents=True)
        (root / 'server/model.py').write_text('version=1', encoding='utf8')
        out = Path(directory) / 'study'
        return root, out

    def test_identical_resume_keeps_manifest_and_cached_battles(self):
        with tempfile.TemporaryDirectory() as temp:
            root, out = self.fixture(temp)
            freeze_study(out, b'config', root)
            (out / 'battles').mkdir()
            cached = out / 'battles/result.summary.json'
            cached.write_text('{}', encoding='utf8')
            manifest = (out / 'manifest.json').read_bytes()
            freeze_study(out, b'config', root)
            self.assertEqual((out / 'manifest.json').read_bytes(), manifest)
            self.assertEqual(cached.read_text(), '{}')

    def test_changed_implementation_rejected_before_snapshot_overwrite(self):
        with tempfile.TemporaryDirectory() as temp:
            root, out = self.fixture(temp)
            freeze_study(out, b'config', root)
            previous = {p.relative_to(out): p.read_bytes() for p in out.rglob('*') if p.is_file()}
            (root / 'server/model.py').write_text('version=2', encoding='utf8')
            with self.assertRaisesRegex(RuntimeError, 'source hashes changed'):
                freeze_study(out, b'config', root)
            self.assertEqual(previous, {p.relative_to(out): p.read_bytes() for p in out.rglob('*') if p.is_file()})

    def test_tampered_or_unverifiable_frozen_sources_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            root, out = self.fixture(temp)
            freeze_study(out, b'config', root)
            (out / 'sources/server/model.py').write_text('tampered', encoding='utf8')
            with self.assertRaisesRegex(RuntimeError, 'snapshot is missing or modified'):
                freeze_study(out, b'config', root)
            (out / 'manifest.json').unlink()
            (out / 'battles').mkdir()
            (out / 'battles/cache.summary.json').write_text('{}', encoding='utf8')
            with self.assertRaisesRegex(RuntimeError, 'without a frozen source manifest'):
                freeze_study(out, b'config', root)

    def test_changed_shared_block_plan_rejected_before_scheduling_or_reusing_cache(self):
        import run_hero_strength_104 as shared
        with tempfile.TemporaryDirectory() as temp:
            args=['study','--cycles','20','--block-cycles','10','--output',temp]
            with patch.object(shared,'study_config',return_value=({}, {}, {'mixed':['A_1001_6']})), \
                 patch('sys.argv',args), patch('sys.stdout',new=io.StringIO()), \
                 patch.object(shared.concurrent.futures,'ProcessPoolExecutor',side_effect=InterruptedError):
                with self.assertRaises(InterruptedError): shared.main()
            out=Path(temp)
            cached=out/'battles/mixed-0000-0010.summary.json'
            cached.write_text('{}',encoding='utf8')
            manifest=(out/'manifest.json').read_bytes()
            args[4]='20'
            with patch.object(shared,'study_config',return_value=({}, {}, {'mixed':['A_1001_6']})), \
                 patch('sys.argv',args), patch.object(shared.concurrent.futures,'ProcessPoolExecutor') as executor:
                with self.assertRaisesRegex(RuntimeError,'Frozen config changed'): shared.main()
            executor.assert_not_called()
            self.assertEqual((out/'manifest.json').read_bytes(),manifest)
            self.assertEqual(cached.read_text(),'{}')

    def test_game_count_is_rejected_before_schedule_generation(self):
        pool = [str(i) for i in range(35)]
        for count in (0, -10, 10010, 15):
            with self.assertRaises(ValueError):
                next(focal_schedule(pool, pool[0], 'mixed', count))
        validate_games(10)
        validate_games(10000)


if __name__ == '__main__':
    unittest.main()
