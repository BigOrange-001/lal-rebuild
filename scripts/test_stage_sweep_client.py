"""The sweep card's free-quota and price preview matches server/stage_sweep.py."""
import shutil
import subprocess
import sys
import unittest
from pathlib import Path

import test_material_stacks_client as stacks

ROOT = Path(__file__).resolve().parents[1]
CARD = ROOT / 'client/src/stages/056_ItemPVEcombat.as'


@unittest.skipUnless(shutil.which('node'), 'Node is required for the AS behavior harness')
class StageSweepClientTests(unittest.TestCase):
    run_rule = stacks.MaterialStackClientTests.run_rule

    def test_sweep_quote_matches_the_server_day_and_price(self):
        sys.path.insert(0, str(ROOT / 'server'))
        import stage_sweep
        from game_calendar import game_day
        simple = {"stage_sweep": {"free": 20, "vip_bonus": 5, "extra_cost": 20, "stars": 3, "max_times": 100},
                  "daily_reset_hour": 0, "daily_timezone_offset_hours": 8}
        now = 1792425600
        for vip, used, day, times in ((0, 0, None, 1), (0, 18, "today", 5), (3, 30, "today", 10),
                                      (2, 40, "yesterday", 3), (0, 25, "today", 2)):
            stamp = game_day(now) if day == "today" else "2000-01-01"
            profile = {"vip_lv": vip, "records": {} if day is None else {"stage_sweep": {"day": stamp, "used": used, "paid": 0}}}
            actual = self.run_rule({"simple": simple, "profile": profile},
                                   f'[gameDayKey({now}*1000),stageSweepQuote({times},{now})]')
            self.assertEqual(actual[0], game_day(now))
            expected = stage_sweep.quote(profile, now, times)
            self.assertEqual((actual[1]["freeLeft"], actual[1]["free"], actual[1]["paid"], actual[1]["cost"]),
                             (expected["free_left"], expected["free"], expected["paid"], expected["coin_cost"]),
                             (vip, used, day, times))


    def test_card_sends_the_confirmed_price_and_only_offers_three_star_stages(self):
        source = CARD.read_text('utf-8-sig')
        self.assertIn('SendAndSelect.sendAndSelectService("user.stage_sweep",params', source)
        for field in ('"cid":cid', '"diff":sweepDiff()', '"times":times', '"max_coin":cost', '"actionID":'):
            self.assertIn(field, source)
        self.assertIn('>= int(GlobalData.stageSweepPolicy().stars)', source)
        self.assertIn('setupSweep(_loc13_);', source)
        self.assertNotIn('Tools.getGameDayKey', source)  # Tools compiles after this stage


    def test_paid_sweep_asks_in_a_second_dialog_at_the_quoted_price(self):
        from test_vital_bar_104 import method

        path = CARD.relative_to(ROOT).as_posix()
        quote = method(path, 'changeSweepTimes')
        confirm = method(path, 'confirmSweep')
        send = method(path, 'sendSweep').replace('function(receipt:Object):void', 'function(receipt)')
        script = f"const changeSweepTimes = {quote}, confirmSweep = {confirm}, sendSweep = {send};" + '''
const assert = require("node:assert/strict");
const int = Number;
let price = {cost: 20, free: 1, price: 20};
let request;
const GlobalData = {$userData: {uid: "u1", coin: 100}, stageSweepQuote: () => price};
const SendAndSelect = {
    $SendServiceAMFDispatcher: {addEventListener() {}},
    sendAndSelectService(method, params) {
        assert.equal(method, "user.stage_sweep");
        request = params;
    }
};
let $sweepLastTimes;
const card = {
    mSweepTimes: 1, mSweepQuote: null, mSweepBusy: false, mSweepAction: "",
    mSweepEnergy: 5, mSweepCountText: {}, mSweepCostText: {}, mSweepOk: {}, mSweepBtn: {},
    data: {id: "M_001_1"}, sweepMax: () => 5, sweepDiff: () => 0,
    closeSweepDialog() {}, onSweepError() {}, changeSweepTimes, confirmSweep, sendSweep,
    openSweepCoinDialog(times, quote) { this.coinDialog = [times, quote]; }
};
card.changeSweepTimes(2);
// The price is on the cost line, never in brackets on the button.
assert.equal(card.mSweepOk.text, "扫荡2次");
assert.match(card.mSweepCostText.text, /需要金砖20/);
price = {cost: 80, free: 0, price: 40};
card.confirmSweep();
// Nothing is sent until the second dialog is confirmed ...
assert.equal(request, undefined);
assert.deepEqual(card.coinDialog, [2, {cost: 20, free: 1, price: 20}]);
// ... which sends at the price the player was shown, not a later one.
card.sendSweep(card.coinDialog[0], card.coinDialog[1].cost);
assert.equal(request.times, 2);
assert.equal(request.max_coin, 20);
// A free sweep skips the second dialog.
request = undefined; card.coinDialog = undefined; card.mSweepBusy = false;
price = {cost: 0, free: 2};
card.changeSweepTimes(2);
card.confirmSweep();
assert.equal(card.coinDialog, undefined);
assert.equal(request.max_coin, 0);
'''
        result = subprocess.run(["node"], input=script, text=True, encoding="utf-8", capture_output=True, cwd=ROOT)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


    def test_full_inventory_does_not_block_the_sweep_dialog(self):
        from test_vital_bar_104 import method

        on_sweep = method(CARD.relative_to(ROOT).as_posix(), 'onSweep')
        script = f"const onSweep = {on_sweep};" + '''
const assert = require("node:assert/strict");
const int = Number;
const GlobalData = {
    $tempPVE_type: "status_pve_activities",
    $userData: {attrs: {avatar_len: 10}, vip_lv: 0},
    $mConfig_simple: {equip_config: [10]},
    rosterSlotCount: () => 10,
    equipSlotCount: () => 10
};
const GlobalFunction = {
    popAvatarLen() { assert.fail("The actual reward may fit a stack"); },
    popEquipFull() { assert.fail("This stage may award no equipment"); },
    getEnergy: () => ({energy: 10})
};
let opened = false;
const card = {
    mSweepBusy: false, stage: {}, data: {activity_kind: "material", needvip: 0},
    mLimit: 1, mSweepEnergy: 5, refreshSweepLimit() {}, sweepMax: () => 1,
    openSweepDialog() { opened = true; }, onSweep
};
card.onSweep({stopPropagation() {}});
assert.equal(opened, true);
'''
        result = subprocess.run(["node"], input=script, text=True, encoding="utf-8", capture_output=True, cwd=ROOT)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == '__main__':
    unittest.main()
