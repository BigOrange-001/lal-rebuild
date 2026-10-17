"""Equipment sale previews for ordinary gear and books without dust rows."""
import json
import shutil
import unittest
from pathlib import Path

from test_avatar_passive import method_body
import test_playtest_client as harness


ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which('node'), 'Node is required for the AS behavior harness')
class EquipmentSaleClientTests(unittest.TestCase):
    def test_dust_preview_matches_each_supported_type_and_star(self):
        cfg = json.loads((ROOT / 'config/reconstruction/full-config.json').read_text('utf8'))['cfg']['system_simple']
        body = method_body((ROOT / 'client/src/stages/084_Equip.as').read_text('utf8'), 'getSellDust')
        script = '''const int=v=>Math.trunc(Number(v))||0;
const GlobalData={$mConfig_simple:OPTIONS};
let kind=1,star=3;
const unit={getType:()=>kind,getStar:()=>star,magic:[1,2,3,4]};
'''.replace('OPTIONS', json.dumps(cfg))
        script += 'unit.getSellDust=function(){with(this){' + body + '}};\n'
        script += '''let rows=[];for(kind of [1,3,4,5,6])for(star of [1,3,6,7,8])
rows.push({kind,star,dust:unit.getSellDust()});console.log(JSON.stringify(rows));'''
        actual = harness.PlaytestClientTests.run_js(self, script)
        for row in actual:
            expected = [1, 1, 2, 2]
            index = 0 if row['kind'] == 1 else row['kind'] - 2
            offset = row['star'] - 3
            if index < len(cfg['dust']['tear']):
                tear = cfg['dust']['tear'][index]
                if 0 <= offset < min(4, len(tear)):
                    expected[offset] += tear[offset]
                elif 4 <= offset < len(tear):
                    expected[2] += tear[offset][0]
                    expected[3] += tear[offset][1]
            self.assertEqual(row['dust'], expected, row)

    def test_sale_button_uses_the_starling_display_receiver(self):
        source = (ROOT / 'client/src/stages/113_PanelEquipSellSelect.as').read_text('utf8')
        self.assertIn('param1.currentTarget as DisplayObject', source)
        self.assertNotIn('import flash.events.EventDispatcher;', source)


if __name__ == '__main__':
    unittest.main()
