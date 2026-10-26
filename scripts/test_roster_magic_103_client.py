"""Execute the actual filtering, auto-feed, quote and sync control flow."""
import json
import re
import shutil
import unittest
from pathlib import Path

from test_avatar_passive import method_body
import test_playtest_client as harness

ROOT = Path(__file__).resolve().parents[1]


def method(file, name, params=''):
    body = method_body((ROOT / 'client/src/stages' / file).read_text('utf-8'), name)
    body = re.sub(r'for each\(var (\w+) in ([^)]+)\)', r'for(var \1 of Object.values(\2))', body)
    body = re.sub(r'for each\((\w+) in ([^)]+)\)', r'for(\1 of Object.values(\2))', body)
    body = re.sub(r'(\w+(?:\.\w+)*(?:\[\d+\])?) is Array', r'Array.isArray(\1)', body)
    body = re.sub(r'([A-Za-z_$][\w$]*(?:\.[A-Za-z_$][\w$]*)*) is Function', r'typeof \1 === "function"', body)
    body = re.sub(r'catch\((\w+):Error\)', r'catch(\1)', body)
    body = re.sub(r'(function\s*\([^)]*)\b(\w+):\w+', r'\1\2', body)
    body = re.sub(r'(function\s*\([^)]*)\b(\w+):\w+', r'\1\2', body)
    return f'unit.{name}=function({params}){{with(this){{{body}\n}}}};\n'


@unittest.skipUnless(shutil.which('node'), 'Node is required for AS behavior checks')
class RosterMagic103ClientTests(unittest.TestCase):
    run_js = harness.PlaytestClientTests.run_js

    def auto(self, rows, *, remaining=100000, gold=100000, skill=1, rarity=False):
        script = '''const input=JSON.parse(require('fs').readFileSync(0,'utf8'));
const selected=[],errors=[];
Array.prototype.sortOn=function(key){return this.sort((a,b)=>a[key]-b[key]);};
const int=Math.trunc;
const GlobalData={$tempAvatarBetter:{id:'A_1001_6|0'},$mConfig_simple:{slv_config:[10]},
$mConfig_avatar:{},$userData:{gold:input.gold,avatars:input.rows}};
for(const id in input.rows)GlobalData.$mConfig_avatar[id.split('|')[0]]={};
function Avatar(id){let row=input.rows[id]||{};Object.assign(this,{id,resId:id.split('|')[0],lv:row.lv||1,phase:row.phase||0,
slv:row.slv||1,loveExp:0,exp:0,morph:0,skill0:{},getAllExp:cap=>cap?input.remaining:0,
getLvMax:()=>99,getOfferExp:()=>row.offer||10,getPithNum:()=>row.pith||0,clear:()=>{}});
if(id==='A_1001_6|0')this.slv=input.skill;}
const PanelAvatarSell={isHeroAssigned:id=>!!input.rows[id].assigned,isAutoBlocked:row=>row.lv>1||!!row.talent};
const GlobalFunction={checkLock:id=>!!input.rows[id].lock,changeAvatarBetterArray:id=>selected.push(id),popError:v=>errors.push(v)};
const GlobalLanguageStr={getLanguageStr:v=>String(v)};
const unit={$betterRarityFilter:{'2':true,'3':true,'4':true,'5':true,'6':true}},PanelBetterSelect=unit;
'''
        for name, params in [('isAutoMinion', 'param1'), ('autoFeedMaterialKind', 'param1'),
                             ('autoMaterialPriority', 'param1'), ('matchesBetterRarity', 'param1'),
                             ('autoFeedMaterialSafe', 'param1,param2,param3'), ('checkBetterFood', 'respectRarity=false')]:
            script += method('034_PanelBetterSelect.as', name, params)
        script += '''if(input.rarity)unit.$betterRarityFilter['3']=false;
unit.checkBetterFood(input.rarity);console.log(JSON.stringify({selected,errors}));'''
        return self.run_js(script, {'rows': rows, 'remaining': remaining, 'gold': gold, 'skill': skill, 'rarity': rarity})

    def test_auto_includes_every_minion_and_monster_category_after_special_materials(self):
        rows = {'A_4001_3|1': {'offer': 100}, 'A_3008_2|2': {'offer': 100},
                'A_2004_4|3': {'offer': 100}, 'A_6996_3|4': {'offer': 1000},
                'A_6992_4|5': {'offer': 5}, 'A_1002_3|6': {'offer': 10000},
                'A_5009_3|7': {'offer': 10000}, 'A_5001_2|8': {'offer': 10000}}
        answer = self.auto(rows)
        self.assertEqual(answer['selected'][:2], ['A_6992_4|5', 'A_6996_3|4'])
        self.assertEqual(set(answer['selected'][2:]), {'A_4001_3|1', 'A_3008_2|2', 'A_2004_4|3'})
        for family in ('A_3009_3', 'A_3010_3'):
            self.assertEqual(self.auto({family+'|1': {'offer':17}})['selected'], [family+'|1'])

    def test_auto_respects_locks_assignments_investment_and_per_ten_xp_price(self):
        rows = {'A_4001_3|1': {'offer': 17}, 'A_4001_3|2': {'offer': 17, 'lock': 1},
                'A_3001_1|3': {'offer': 17, 'assigned': True},
                'A_2004_4|4': {'offer': 17, 'pith': 1}, 'A_2004_4|5': {'offer': 17, 'lv': 2},
                'A_6996_3|6': {'offer': 1000}}
        self.assertEqual(self.auto(rows, gold=2)['selected'], ['A_4001_3|1'])
        self.assertEqual(self.auto({'A_4001_3|1': {'offer': 17}}, gold=1)['selected'], [])
        self.assertEqual(set(self.auto(rows, gold=3_000_000_000)['selected']), {'A_6996_3|6','A_4001_3|1'})

    def test_auto_max_level_only_uses_biscuits_and_rarity_can_exclude_monsters(self):
        rows = {'A_4001_3|1': {'offer': 17}, 'A_6996_3|2': {'offer': 1000}, 'A_6992_4|3': {'offer': 5}}
        self.assertEqual(self.auto(rows, remaining=0)['selected'], ['A_6992_4|3'])
        self.assertEqual(self.auto(rows, remaining=0, skill=10)['selected'], [])
        self.assertEqual(self.auto(rows, rarity=True)['selected'], ['A_6992_4|3'])

    def test_quality_filter_and_assignment_sort_use_main_over_dn_over_inactive(self):
        script = '''const GlobalData={$userData:{team:[['A_1001_6|a']],attrs:{dn:{1:[1,'A_1002_5|b']}}}};
const int=Math.trunc,unit={};
'''
        script += method('030_PanelAvatarSell.as', 'filterRosterRows', 'rows,state')
        script += '''let rows=[{id:'A_1003_5|c',lv:30},{id:'A_1002_5|b',lv:20},{id:'A_1001_6|a',lv:10}];
const ids=x=>x.map(r=>r.id);let out=[];
out.push(ids(unit.filterRosterRows(rows,{quality:0,order:2,descending:true})));
out.push(ids(unit.filterRosterRows(rows,{quality:0,order:2,descending:false})));
out.push(ids(unit.filterRosterRows(rows,{quality:5,order:1,descending:true})));
out.push(ids(unit.filterRosterRows(rows,{quality:5,order:1,descending:false})));
out.push(ids(unit.filterRosterRows(rows,{quality:1,order:1,descending:false})));
out.push(ids(unit.filterRosterRows(rows,{quality:0,order:2,descending:true,previewTeam:['A_1003_5|c']})));
console.log(JSON.stringify(out));'''
        self.assertEqual(self.run_js(script), [['A_1001_6|a', 'A_1002_5|b', 'A_1003_5|c'],
                                              ['A_1003_5|c', 'A_1002_5|b', 'A_1001_6|a'],
                                              ['A_1003_5|c', 'A_1002_5|b'], ['A_1002_5|b', 'A_1003_5|c'], [],
                                              ['A_1003_5|c', 'A_1002_5|b', 'A_1001_6|a']])

    def test_magic_quote_accounts_for_price_growth_partial_cap_and_partial_funds(self):
        script = '''const int=Math.trunc;
const GlobalData={$tempEquipCurrSelected:'eq', $userData:{my_equips:{eq:{magic:[9,1,0,0]}},attrs:{dust:[1000,1000,1000,1000]}},
$mConfig_simple:{dust:{max:[100,100,100,100],add_magic:[[1,2,3,4]]},equipment_magic:{cost_growth_every:10}}};
const unit={};
'''
        script += method('062_PanelEquipMagic.as', 'magicUpgradeQuote', 'color,times')
        script += '''let out=[unit.magicUpgradeQuote(0,10)];
GlobalData.$userData.my_equips.eq.magic[0]=98;out.push(unit.magicUpgradeQuote(0,10));
GlobalData.$userData.my_equips.eq.magic[0]=0;GlobalData.$userData.attrs.dust[0]=2;out.push(unit.magicUpgradeQuote(0,10));
out.push(unit.magicUpgradeQuote(1,10));GlobalData.$userData.attrs.dust[0]=3000000000;
out.push(unit.magicUpgradeQuote(0,10));console.log(JSON.stringify(out));'''
        out = self.run_js(script)
        self.assertEqual([(x['count'], x['cost']) for x in out], [(10, 19), (2, 20), (2, 2), (0, 0), (10, 10)])

    def test_ui_refresh_exception_cannot_reject_an_applied_profile_or_block_power_refresh(self):
        for filename in ('002_GlobalFunction.as', '017_GlobalFunction.as', '045_GlobalFunction.as'):
            script = '''const events=[],logs=[],Tools={getElementNum:o=>Object.keys(o).length},trace=v=>logs.push(v);
const GlobalData={$userData:{avatars:{h:{}},team:[['h']]},$tempTeamPowerTemp:1,$mConfig_avatar:{h:{}},$mConfig_simple:{},
applyProfileSnapshot:()=>true,$mEventDispatcher:{dispatchEventWith:name=>{events.push(name);if(name==='profile_state_sync')throw Error('closed panel');}}};
const unit={getTeamPower:()=>12345,refreshProfileTopBar:()=>{throw Error('closed top bar');}};
'''
            script += method(filename, 'refreshOwnedTeamPower')
            script += method(filename, 'applyProfileStateSync', 'param1')
            script += '''let result=unit.applyProfileStateSync({});console.log(JSON.stringify({result,power:GlobalData.$tempTeamPowerTemp,events,logs:logs.length}));'''
            self.assertEqual(self.run_js(script), {'result': True, 'power': 12345,
                                                   'events': ['update_team_power', 'profile_state_sync'], 'logs': 2}, filename)

    def test_sync_rebinds_committed_team_but_preserves_detached_edit_preview(self):
        script = '''const int=Math.trunc;
const unit={$userData:{uid:'u',team:[['old']]},$profileSyncUid:'u',$profileSyncRevision:1,isValidProfileSyncEnvelope:()=>true};
unit.$tempTeam=unit.$userData.team[0];
'''
        script += method('001_GlobalData.as', 'applyProfileSnapshot', 'param1')
        script += '''let snapshot={uid:'u',revision:2,profile:{uid:'u',team:[['new']]}};
unit.applyProfileSnapshot(snapshot);let first=unit.$tempTeam===unit.$userData.team[0];
unit.$tempTeam=['preview'];unit.applyProfileSnapshot({uid:'u',revision:3,profile:{uid:'u',team:[['newer']]}});
console.log(JSON.stringify([first,unit.$tempTeam,unit.$userData.team]));'''
        self.assertEqual(self.run_js(script), [True, ['preview'], [['newer']]])

    def test_late_lock_callback_mirrors_current_authoritative_flag(self):
        script = '''let pending=[],listeners=new Set(),done=0;
const GlobalData={$userData:{uid:'u',avatars:{'A_1137_6|1':{lock:1}}},$tempAvatarLock:{1:'1'},$localUser:{},$mServiceID:'s',
$mEventDispatcher:{dispatchEventWith:()=>{}},$tempLockItem:null};
const GlobalLocalStore={setCurrUserData:()=>{}};
const SendAndSelect={$uid:'u',$SendServiceAMFDispatcher:{addEventListener:(n,f)=>listeners.add(f),removeEventListener:(n,f)=>listeners.delete(f)},
sendAndSelectService:(n,p,f)=>{p.actionID='one';pending.push(f);}};
const unit={inventoryLockPending:{}};
'''
        script += method('045_GlobalFunction.as', 'setInventoryLock', 'kind,id,locked,done=null')
        script += '''unit.setInventoryLock('hero','A_1137_6|1',false,()=>done++);
GlobalData.$userData.avatars['A_1137_6|1']={lock:1};pending.shift()({});let relocked=!!GlobalData.$tempAvatarLock[1];
unit.setInventoryLock('hero','A_1137_6|1',true,()=>done++);
GlobalData.$userData.avatars['A_1137_6|1']={lock:0};pending.shift()({});
console.log(JSON.stringify({relocked,unlocked:!GlobalData.$tempAvatarLock[1],done,listeners:listeners.size}));'''
        self.assertEqual(self.run_js(script), {'relocked':True,'unlocked':True,'done':2,'listeners':0})

    def test_talent_configured_icon_is_preserved_with_power_bound_fix(self):
        script = '''class Sprite{constructor(){this.children=[];}addChild(c){this.children.push(c);}}
const int=Math.trunc,GlobalData={$mConfig_talent:{T_01_06:{rank:6,icon:'H_0010000'}}};
const GlobalFunction={createImage:id=>id},unit={};
'''
        script += method('145_Talent.as', 'getImage', 'param1')
        script += '''console.log(JSON.stringify(unit.getImage('T_01_06').children));'''
        self.assertEqual(self.run_js(script), ['all0004','H_0010000'])


if __name__ == '__main__':
    unittest.main()
