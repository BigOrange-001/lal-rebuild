"""Game-only PNG frame metadata and installation/compile boundaries."""
import copy
import hashlib
import json
from pathlib import Path
import struct
import sys
import tempfile
import unittest
import uuid
import zipfile
import zlib

sys.path.insert(0,str(Path(__file__).resolve().parent))
from mod_packages import validate_media,inspect_package,ModCatalog
from mod_schema import canonical,ModError
import test_mod_packages as legacy


def png(frame=None,duplicate=False):
    def chunk(kind,data):return struct.pack('>I',len(data))+kind+data+struct.pack('>I',zlib.crc32(kind+data)&0xffffffff)
    header=chunk(b'IHDR',struct.pack('>IIBBBBB',160,160,8,6,0,0,0))
    meta=b'' if frame is None else chunk(b'tEXt',b'lal.cardFrame\0'+json.dumps(frame).encode())
    pixels=chunk(b'IDAT',zlib.compress((b'\0'+b'\0'*640)*160))
    return b'\x89PNG\r\n\x1a\n'+header+meta+(meta if duplicate else b'')+pixels+chunk(b'IEND',b'')


class CardFrameTest(unittest.TestCase):
    def test_metadata_boundaries(self):
        self.assertEqual(validate_media(png([27,19,106,122]),'card.png')['cardFrame'],[27,19,106,122])
        self.assertNotIn('cardFrame',validate_media(png(),'card.png'))
        for value in [[-1,19,106,122],[27,19,200,122],[0,0,0,0],[0,0,80,80],[0,0,103.0,118],{},[0,0,True,118]]:
            with self.subTest(value=value),self.assertRaises(ModError):validate_media(png(value),'card.png')
        with self.assertRaises(ModError):validate_media(png([27,19,106,122],True),'card.png')

    def test_capability_and_compiled_geometry(self):
        hero=legacy.hero_definition();hero['presentation'].update(icon='self:asset/card.png',portrait='self:asset/card.png')
        payload={'heroes.json':canonical({'heroes':[hero]}),'assets/card.png':png([27,19,106,122])}
        manifest={'format':'lal-mod-v1','kind':'new','packageId':str(uuid.uuid4()),'name':'Frames','author':'Acceptance','version':'1.0.0','engineApi':'1',
            'requiredCapabilities':[],'entrypoints':{'heroes':'heroes.json'},'dependencies':[],
            'files':[{'path':k,'sha256':hashlib.sha256(v).hexdigest()} for k,v in payload.items()]}
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder);path=root/'test.heropack'
            def write():
                with zipfile.ZipFile(path,'w') as z:
                    for name,raw in payload.items():z.writestr(name,raw)
                    z.writestr('manifest.json',canonical(manifest))
            write()
            with self.assertRaises(ModError):inspect_package(path,legacy.base_config())
            manifest['requiredCapabilities']=['asset.image.card-frame'];write()
            catalog=ModCatalog(root/'mods',legacy.base_config());row=catalog.install(path)
            result=catalog.compile(legacy.base_config(),{'packages':[{'packageId':row['packageId'],'version':row['version'],'digest':row['digest']}]})
            self.assertEqual(result.runtime['requiredClientCapabilities'],['asset.image.card-frame'])
            self.assertEqual(len(result.runtime['assets']),2)
            for asset in result.runtime['assets']:self.assertEqual(asset['cardFrame'],[27,19,106,122])


if __name__=='__main__':unittest.main()
