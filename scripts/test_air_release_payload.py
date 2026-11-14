"""Catch post-ADT replacement even when Android's APK signature is valid."""
import io
import unittest
import zipfile
from verify_release_105 import assert_air_payload


def archive(files):
    stream = io.BytesIO()
    with zipfile.ZipFile(stream,'w') as z:
        for name,data in files.items():
            z.writestr(name,data)
    stream.seek(0)
    return zipfile.ZipFile(stream)


class AirPayloadTests(unittest.TestCase):
    def test_manager_additions_preserve_air_payload_but_stale_files_are_rejected(self):
        source = {'assets/MainLLOL.swf':b'final-swf',
                  'assets/META-INF/AIR/application.xml':b'1.0.5',
                  'assets/META-INF/AIR/license.txt':b'official-adt-license'}
        with archive(source) as adt,archive({**source,'classes2.dex':b'manager'}) as merged:
            self.assertEqual(assert_air_payload(adt,merged),3)
        for name in source:
            with self.subTest(changed=name),archive(source) as adt,archive({**source,name:b'stale-1.0.4'}) as broken:
                with self.assertRaisesRegex(ValueError,'ADT-protected'):
                    assert_air_payload(adt,broken)

    def test_missing_adt_license_is_rejected(self):
        with archive({'assets/MainLLOL.swf':b'swf'}) as adt,archive({}) as merged:
            with self.assertRaisesRegex(ValueError,'no AIR license'):
                assert_air_payload(adt,merged)


if __name__=='__main__':
    unittest.main()
