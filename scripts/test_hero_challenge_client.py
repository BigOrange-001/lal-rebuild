"""Execute the final AS hero challenge quota and the no-sweep gate under Node."""
import shutil
import unittest

from test_skill_books_client import method
import test_playtest_client as harness


@unittest.skipUnless(shutil.which('node'), 'Node is required for AS behavior checks')
class HeroChallengeClientTests(unittest.TestCase):
    run_js = harness.PlaytestClientTests.run_js

    def test_tiers_share_the_vip_quota_like_the_server(self):
        for source in ('017_GlobalFunction.as', '045_GlobalFunction.as'):
            script = '''const int=v=>Math.trunc(Number(v))||0;let vip=0;
const SendAndSelect={$systemTimer_nowSecond:Date.parse('2026-11-26T08:00:00Z')/1000};
const policy={schema:'hero-challenge-106-v1',group:'demonblade_tryndamere'};
const GlobalData={$mConfig_combat_ploy:{P_300_1:{activity_kind:'hero_challenge',hero_challenge:policy},
P_300_3:{activity_kind:'hero_challenge',hero_challenge:policy},P_102_1:{activity_kind:'material'}},
$mConfig_simple:{hero_challenge:{base_attempts:2,vip_step:3},material_challenge:{base_attempts:12,buy_cost:50}},
$userData:{records:{hero_challenge:{day:'2026-11-26',uses:{demonblade_tryndamere:1}},material_activity:{}}}};
const unit={getVipLv:()=>vip};'''
            script += method(source, 'getHeroChallenge', 'param1')
            script += method(source, 'getMaterialChallenge', 'param1')
            script += '''let a=unit.getMaterialChallenge('P_300_1'),b=unit.getMaterialChallenge('P_300_3');
let result=[a.remaining,b.remaining,a.hero,a.buyLimit,unit.getMaterialChallenge('P_102_1').remaining];
for(vip of [2,3,6,15])result.push(unit.getMaterialChallenge('P_300_1').remaining);
SendAndSelect.$systemTimer_nowSecond+=86400;vip=0;result.push(unit.getMaterialChallenge('P_300_3').remaining);
console.log(JSON.stringify(result));'''
            self.assertEqual(self.run_js(script), [1, 1, True, 0, 12, 1, 2, 3, 6, 2], source)

    def test_sweep_button_is_hidden_for_sweep_disabled_stages(self):
        script = '''const int=v=>Math.trunc(Number(v))||0;
const GlobalData={$tempPVE_type:'status_pve_activities',stageSweepPolicy:()=>({stars:3})};
const GlobalFunction={getCombatStarById:()=>3};
const unit={data:{id:'P_300_1',sweep_disabled:true}};'''
        script += method('056_ItemPVEcombat.as', 'sweepUnlocked')
        script += '''let blocked=unit.sweepUnlocked();unit.data={id:'P_001_1'};
console.log(JSON.stringify([blocked,unit.sweepUnlocked()]));'''
        self.assertEqual(self.run_js(script), [False, True])


if __name__ == '__main__':
    unittest.main()
