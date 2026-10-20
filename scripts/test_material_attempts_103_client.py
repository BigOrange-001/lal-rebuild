"""Execute final AS resource quotes and purchase error recovery under Node."""
import json,shutil,unittest
from test_skill_books_client import method
import test_playtest_client as harness

@unittest.skipUnless(shutil.which('node'),'Node is required for AS behavior checks')
class MaterialAttempts103ClientTests(unittest.TestCase):
    run_js=harness.PlaytestClientTests.run_js
    def test_shared_counts_biscuits_ancient_trial_vip_and_next_day(self):
        for source in ('017_GlobalFunction.as','045_GlobalFunction.as'):
            script='''const int=v=>Math.trunc(Number(v))||0;
const SendAndSelect={$systemTimer_nowSecond:Date.parse('2026-10-20T08:00:00Z')/1000};
const GlobalData={$mConfig_combat_ploy:{P_102_1:{activity_kind:'material'},P_102_5:{activity_kind:'material'},
P_109_4:{activity_kind:'material'},P_001_15:{activity_kind:'material'},P_200_180:{activity_kind:'tower'}},
$mConfig_simple:{material_challenge:{base_attempts:12,buy_cost:50}},
$userData:{records:{material_activity:{day:'2026-10-20',uses:{P_102:12,P_109:1},buys:{P_102:2}}}}};
const unit={getVipLv:()=>3};'''
            script+=method(source,'getMaterialChallenge','param1')
            script+='''let a=unit.getMaterialChallenge('P_102_1');let b=unit.getMaterialChallenge('P_102_5');
let result=[a.remaining,b.remaining,a.buys,a.buyLimit,a.price,unit.getMaterialChallenge('P_109_4').remaining,
unit.getMaterialChallenge('P_001_15').remaining,unit.getMaterialChallenge('P_200_180')];
SendAndSelect.$systemTimer_nowSecond+=86400;result.push(unit.getMaterialChallenge('P_102_5').remaining);
console.log(JSON.stringify(result));'''
            self.assertEqual(self.run_js(script),[2,2,2,5,50,11,12,None,12],source)
    def test_matching_error_reenables_purchase_and_ignores_other_requests(self):
        script='''let refreshed=0,removed=0;
const SendAndSelect={$SendServiceAMFDispatcher:{removeEventListener:()=>removed++}};
const unit={mMaterialBusy:true,mMaterialAction:'abc',refreshMaterialAttempts:()=>refreshed++};'''
        script+=method('056_ItemPVEcombat.as','onMaterialBuyError','event')
        script+='''unit.onMaterialBuyError({data:{params:{actionID:'other'}}});let first=unit.mMaterialBusy;
unit.onMaterialBuyError({data:{profile_receipt:{params:{actionID:'abc'}}}});
console.log(JSON.stringify([first,unit.mMaterialBusy,unit.mMaterialAction,refreshed,removed]));'''
        self.assertEqual(self.run_js(script),[True,False,'',1,1])
    def test_auto_fight_stops_at_zero_and_continues_with_a_paid_attempt(self):
        script='''let sent=0,errors=0,left=0;
const int=v=>Math.trunc(Number(v))||0;
const GlobalData={$tempPVE_type:'status_pve_activities',$tempPVE_combatID:'P_109_1'};
const GlobalFunction={getMaterialChallenge:()=>({remaining:left}),popError:()=>errors++};
const GameMapLayer={isAuto:true},GameMap={lastRe:{params:{cid:'P_109_1'}}};
const SendServiceAMFFun={send_user_pk_combat_main:()=>sent++};
const unit={stage:true,mBox_btn:{visible:false},mAutoTF:{visible:true},reAutoFight:()=>{}};'''
        script+=method('052_PanelGameEndAward.as','toAutoFight')
        script+='''unit.toAutoFight();let stopped=!GameMapLayer.isAuto;
GameMapLayer.isAuto=true;left=1;unit.toAutoFight();
console.log(JSON.stringify([stopped,unit.mBox_btn.visible,unit.mAutoTF.visible,sent,errors]));'''
        self.assertEqual(self.run_js(script),[True,True,False,1,1])

if __name__=='__main__':unittest.main()
