"""Exercise real formation-dialog callbacks with delayed transport replies."""
import re
import shutil
import unittest
from pathlib import Path

from test_avatar_passive import method_body
import test_playtest_client as harness

ROOT = Path(__file__).resolve().parents[1]
SOURCES = ('client/src/formation_share_104.aspart',
           'client/src/stages/046_PanelCenterPVP.as')


@unittest.skipUnless(shutil.which('node'), 'Node is required for AS behavior checks')
class FormationDialogTests(unittest.TestCase):
    run_js = harness.PlaytestClientTests.run_js

    def script(self, source):
        script = r'''
class Sprite {removeFromParent(){this.removed=true;}}
let pending=[],notices=[],refreshes=0,buttons={};
const FORMATION_BROWN104=0;
const GlobalData={$mEventDispatcher:{dispatchEventWith(){refreshes++;}}};
const GlobalFunction={popToast(text){notices.push(text);},uiRow(){}};
const SendAndSelect={sendAndSelectService(method,params,callback){pending.push(callback);}};
const unit={stage:{},shareModal104:null,shareInput104:null,shareNameInput104:null,
  mTabBar:{selectedIndex:4},$tabBarSelectedIndex:4,
  formationAction104:()=> 'test-action',formationText104(){},
  formationName104(input){return input.text.trim();},
  formationField104(box,label,y,text){return {text};},
  formationButton104(label,w,h,primary,box,x,y,callback){
    return buttons[label]={enabled:true,trigger:callback};
  },
  openFormationModal104(){this.closeFormationCode104();this.shareModal104=new Sprite();return {};}
};
'''
        methods = (('closeFormationCode104', 'event=null'),
                   ('formationModalOwner104', 'owner'),
                   ('saveFormation104', 'code,name,done=null'),
                   ('showImportFormation104', 'code=""'),
                   ('showRenameFormation104', 'row'))
        text = (ROOT / source).read_text('utf-8')
        for name, params in methods:
            body = method_body(text, name)
            body = re.sub(r'(\bfunction\s*\()([^)]*)(\))',
                          lambda m: m[1] + re.sub(r':\s*\w+', '', m[2]) + m[3], body)
            script += f'unit.{name}=(function({params}){{with(this){{{body}\n}}}}).bind(unit);\n'
        return script

    def test_late_import_success_keeps_new_dialog_draft_and_selected_tab(self):
        for source in SOURCES:
            with self.subTest(source=source):
                result = self.run_js(self.script(source) + r'''
unit.showImportFormation104('old-code');buttons['导入保存'].trigger();
unit.closeFormationCode104();unit.mTabBar.selectedIndex=1;
unit.showImportFormation104('new-unsaved-draft');let owner=unit.shareModal104;
pending.shift()({return_code:0,data:{formation:{name:'saved'},already_saved:false}});
console.log(JSON.stringify({kept:unit.shareModal104===owner,draft:unit.shareInput104?.text,
  tab:unit.mTabBar.selectedIndex,refreshes,notices:notices.length}));
''')
                self.assertEqual(result, dict(kept=True, draft='new-unsaved-draft',
                                              tab=1, refreshes=1, notices=0))

    def test_current_import_success_closes_and_failure_allows_retry(self):
        for source in SOURCES:
            for success in (False, True):
                with self.subTest(source=source, success=success):
                    result = self.run_js(self.script(source) + f'const success={str(success).lower()};' + r'''
unit.showImportFormation104('code');let owner=unit.shareModal104;
buttons['导入保存'].trigger();
pending.shift()({return_code:success?0:1,data:{formation:{name:'saved'},already_saved:false}});
console.log(JSON.stringify({closed:unit.shareModal104===null,enabled:buttons['导入保存'].enabled,
  refreshes,notices:notices.length}));
''')
                    self.assertEqual(result, dict(closed=success, enabled=True,
                                                  refreshes=int(success), notices=int(success)))

    def test_success_after_leaving_panel_only_refreshes_library(self):
        for source in SOURCES:
            with self.subTest(source=source):
                result = self.run_js(self.script(source) + r'''
unit.showImportFormation104('code');buttons['导入保存'].trigger();
unit.closeFormationCode104();unit.stage=null;unit.mTabBar.selectedIndex=1;
pending.shift()({return_code:0,data:{formation:{name:'saved'},already_saved:false}});
console.log(JSON.stringify({tab:unit.mTabBar.selectedIndex,refreshes,notices:notices.length}));
''')
                self.assertEqual(result, dict(tab=1, refreshes=1, notices=0))

    def test_late_rename_success_keeps_replacement_dialog(self):
        for source in SOURCES:
            with self.subTest(source=source):
                result = self.run_js(self.script(source) + r'''
unit.showRenameFormation104({formation_id:'saved-id',name:'old-name'});
unit.shareNameInput104.text='renamed';buttons['保存'].trigger();
unit.showImportFormation104('new-unsaved-draft');let owner=unit.shareModal104;
pending.shift()({return_code:0,data:{name:'renamed'}});
console.log(JSON.stringify({kept:unit.shareModal104===owner,draft:unit.shareInput104?.text,
  refreshes,notices:notices.length}));
''')
                self.assertEqual(result, dict(kept=True, draft='new-unsaved-draft',
                                              refreshes=1, notices=0))


if __name__ == '__main__':
    unittest.main()
