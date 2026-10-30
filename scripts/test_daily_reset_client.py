"""Run shipped AS calendar methods with only type syntax removed for Node."""
import datetime
import json
import os
from pathlib import Path
import shutil
import subprocess
import unittest

from game_calendar import game_day, LOCAL_TZ
from test_avatar_passive import method_body

ROOT=Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which('node'),'Node is required')
class DailyResetClientTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        source=(ROOT/'client/src/stages/085_Tools.as').read_text('utf8')
        cls.methods=''
        for name,args in [('getGameDayNumber','milliseconds'),('getGameDayKey','milliseconds'),('checkIsSameDay','param1,param2'),('checkIsPrevDay','param1,param2')]:
            cls.methods+='Tools.'+name+'=function('+args+'){with(Tools){'+method_body(source,name)+'}};\n'
        panel=(ROOT/'client/src/stages/008_PanelShopCoin.as').read_text('utf8')
        cls.shop=method_body(panel,'shanghaiDayKey')
        cls.stamps=[int(datetime.datetime(2026,10,d,h,m,s,tzinfo=LOCAL_TZ).timestamp())
                    for d,h,m,s in [(29,23,59,59),(30,0,0,0),(30,11,59,59),(30,12,0,0),(30,23,59,59),(31,0,0,0)]]

    def run_client(self,timezone,settings):
        script='const GlobalData={$mConfig_simple:'+json.dumps(settings)+'},Tools={},SendAndSelect={};\n'+self.methods
        script+="for(const [key,method] of Object.entries({monthUTC:'getUTCMonth',dateUTC:'getUTCDate',fullYearUTC:'getUTCFullYear'}))Object.defineProperty(Date.prototype,key,{get(){return this[method]();}});\n"
        script+='function shop(){'+self.shop+'}\n'
        script+='const times='+json.dumps(self.stamps)+';let days=times.map(t=>{SendAndSelect.$systemTimer_nowSecond=t;return shop()});'
        script+='let pairs=times.slice(1).map((t,i)=>[Tools.checkIsSameDay(times[i]*1000,t*1000),Tools.checkIsPrevDay(times[i]*1000,t*1000)]);console.log(JSON.stringify({days,pairs}));'
        result=subprocess.run(['node','-e',script],capture_output=True,text=True,encoding='utf8',env=dict(os.environ,TZ=timezone),timeout=15)
        self.assertEqual(result.returncode,0,result.stderr)
        return json.loads(result.stdout)

    def test_server_and_client_agree_independent_of_device_timezone(self):
        expected=[game_day(t) for t in self.stamps]
        for timezone in ('UTC','America/Los_Angeles','Asia/Tokyo'):
            result=self.run_client(timezone,dict(daily_reset_hour=0,daily_timezone_offset_hours=8))
            self.assertEqual(result['days'],expected)
            self.assertEqual(result['pairs'],[[False,True],[True,False],[True,False],[True,False],[False,True]])

    def test_uncached_calendar_settings_default_to_midnight(self):
        self.assertEqual(self.run_client('UTC',None)['days'],[game_day(t) for t in self.stamps])

    def test_pve_uses_daily_quota_and_does_not_show_stale_yesterdays_usage(self):
        body=method_body((ROOT/'client/src/stages/170_GlobalFunction.as').read_text('utf8'),'getUserCombat')
        script='const Tools={},GlobalData={$mConfig_simple:{daily_reset_hour:0,daily_timezone_offset_hours:8},$userData:{records:{combat_main:{M_001_1:99},daily_stage_attempts:{day:"2026-10-30",combat_main:{M_001_1:2},combat_main_hard:{M_001_1:3}}}}},SendAndSelect={$systemTimer_nowSecond:'+str(self.stamps[1])+'};\n'+self.methods
        script+="for(const [key,method] of Object.entries({monthUTC:'getUTCMonth',dateUTC:'getUTCDate',fullYearUTC:'getUTCFullYear'}))Object.defineProperty(Date.prototype,key,{get(){return this[method]();}});\n"
        script+='const int=Math.trunc;function usage(param1,param2){'+body+'}\nlet out=[usage("status_pve_normal","M_001_1"),usage("status_pve_hard","M_001_1")];'
        script+='SendAndSelect.$systemTimer_nowSecond='+str(self.stamps[-1])+';out.push(usage("status_pve_normal","M_001_1"));console.log(JSON.stringify(out));'
        result=subprocess.run(['node','-e',script],capture_output=True,text=True,encoding='utf8',timeout=15)
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertEqual(json.loads(result.stdout),[2,3,0])


if __name__=='__main__':unittest.main()
