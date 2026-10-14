"""Exercise release version drift through the real build-config entry point."""
import hashlib
import json
import re
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import build_client


ROOT = Path(__file__).resolve().parents[1]


class BuildRuntimeVersionTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.client = self.root / 'client'
        self.client.mkdir()
        self.source_text = (ROOT / 'client/src/stages/136_MainLLOL.as').read_text(encoding='utf-8')
        project_version = (ROOT / 'VERSION').read_text(encoding='utf-8').strip()
        self.source_text = self.source_text.replace(f'"{project_version}"', '"1.0.1"')
        self.source_path = self.client / 'MainLLOL.as'
        self.source_path.write_text(self.source_text, encoding='utf-8')
        self.version_file = self.root / 'VERSION'
        self.config_file = self.client / 'build.json'
        self.descriptor = self.client / 'application.xml'
        (self.client / 'template.swf').write_bytes(b'resource hash fixture')
        (self.client / 'assets.json').write_text('[]', encoding='utf-8')
        self.config = {
            'schema': 'lal-client-build-v2', 'stage_count': 1, 'unique_class_count': 1,
            'stages': [{'index': 1, 'class': 'MainLLOL', 'source': 'client/MainLLOL.as'}],
            'template_swf': {'path': 'client/template.swf'},
            'descriptor': {'path': 'client/application.xml'},
            'assets_manifest': {'path': 'client/assets.json'},
        }
        self.set_release('1.0.1')
        changes = patch.multiple(build_client, ROOT=self.root, CLIENT=self.client,
                                 CONFIG=self.config_file, VERSION_FILE=self.version_file)
        changes.start()
        self.addCleanup(changes.stop)

    def set_release(self, version):
        self.version_file.write_text(version, encoding='utf-8')
        self.config['version'] = version
        self.descriptor.write_text(f'<application><versionNumber>{version}</versionNumber></application>', encoding='utf-8')
        for key in ('template_swf', 'descriptor', 'assets_manifest'):
            self.config[key]['sha256'] = hashlib.sha256((self.root / self.config[key]['path']).read_bytes()).hexdigest()
        self.config_file.write_text(json.dumps(self.config), encoding='utf-8')

    def test_current_release_accepts_consistent_runtime(self):
        self.assertEqual(build_client.read_build_config()[1], '1.0.1')

    def test_each_stale_startup_path_is_rejected(self):
        occurrences = list(re.finditer(r'"1\.0\.1"', self.source_text))
        self.assertEqual(len(occurrences), 3)
        for index, occurrence in enumerate(occurrences):
            with self.subTest(startup_path=index):
                text = self.source_text[:occurrence.start()] + '"1.0.0"' + self.source_text[occurrence.end():]
                self.source_path.write_text(text, encoding='utf-8')
                with self.assertRaisesRegex(ValueError, 'MainLLOL runtime versions'):
                    build_client.read_build_config()

    def test_future_metadata_without_runtime_update_is_rejected(self):
        self.set_release('1.0.2')
        with self.assertRaisesRegex(ValueError, 'MainLLOL runtime versions'):
            build_client.read_build_config()

    def test_future_consistent_release_is_accepted(self):
        self.set_release('1.0.2')
        self.source_path.write_text(self.source_text.replace('"1.0.1"', '"1.0.2"'), encoding='utf-8')
        self.assertEqual(build_client.read_build_config()[1], '1.0.2')

    def test_commented_startup_path_is_not_counted(self):
        text = self.source_text.replace('MainConfig.VERSION_CURR = "1.0.1";',
                                        '/*\nMainConfig.VERSION_CURR = "1.0.1";\n*/', 1)
        self.source_path.write_text(text, encoding='utf-8')
        with self.assertRaisesRegex(ValueError, 'MainLLOL runtime versions'):
            build_client.read_build_config()


if __name__ == '__main__':
    unittest.main()
