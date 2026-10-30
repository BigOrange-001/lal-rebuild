"""No live database or machine-clock changes; exercise the real daily helpers."""
import copy
import datetime as dt
import json
from pathlib import Path
import sqlite3
import tempfile
import unittest
from unittest.mock import patch

from game_calendar import game_day, game_day_number, next_daily_reset, LOCAL_TZ
from game_clock import GameClock
from gateway import load_game_config
from material_attempts_103 import daily_state
from player_store import PlayerStore, GameplayFault
from spending_budget import charge_spending, normalize_spending

ROOT=Path(__file__).resolve().parents[1]


def stamp(day,hour,minute=0,second=0,month=10,year=2026):
    return int(dt.datetime(year,month,day,hour,minute,second,tzinfo=LOCAL_TZ).timestamp())


class CalendarTests(unittest.TestCase):
    def test_midnight_inclusive_noon_does_not_change_day(self):
        cases=[(stamp(29,23,59,59),'2026-10-29'),(stamp(30,0),'2026-10-30'),
               (stamp(30,11,59,59),'2026-10-30'),(stamp(30,12),'2026-10-30'),
               (stamp(30,23,59,59),'2026-10-30'),(stamp(31,0),'2026-10-31')]
        for now,expected in cases:
            self.assertEqual(game_day(now),expected)
            self.assertGreater(next_daily_reset(now),now)
            self.assertEqual(dt.datetime.fromtimestamp(next_daily_reset(now),LOCAL_TZ).hour,0)
            self.assertEqual(game_day(next_daily_reset(now)-1),expected)
            self.assertEqual(game_day_number(next_daily_reset(now)),game_day_number(now)+1)

    def test_month_year_leap_day_and_timezone_representations(self):
        for day,month,year,previous in [(1,11,2026,'2026-10-31'),(1,1,2027,'2026-12-31'),(1,3,2028,'2028-02-29')]:
            before=stamp(day,0,0,0,month,year)-1
            for timezone in (dt.timezone.utc,dt.timezone(dt.timedelta(hours=-7)),LOCAL_TZ):
                value=dt.datetime.fromtimestamp(before,timezone)
                self.assertEqual(game_day(value),previous)
            self.assertEqual(game_day(dt.datetime.fromtimestamp(before,dt.timezone.utc).replace(tzinfo=None)),previous)
            self.assertNotEqual(game_day(before+1),previous)

    def test_system_clock_and_persisted_admin_offset_share_midnight_boundary(self):
        with tempfile.TemporaryDirectory() as folder:
            db=Path(folder)/'clock.db'
            now=stamp(29,23,59,59)
            with patch('game_clock.time.time',return_value=now):
                clock=GameClock(db)
                try:
                    self.assertEqual(clock.now(),now)
                    self.assertEqual(game_day(clock.now()),'2026-10-29')
                    clock.advance(1)
                    self.assertEqual(game_day(clock.now()),'2026-10-30')
                finally:clock.close()
                reopened=GameClock(db)
                try:self.assertEqual(reopened.now(),now+1)
                finally:reopened.close()


class DailyFeatureTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.config=load_game_config(ROOT/'config/reconstruction/full-config.json')

    def setUp(self):
        class Clock:
            value=stamp(29,23,59,59)
            def now(self):return self.value
        self.clock=Clock()
        self.db=sqlite3.connect(':memory:',check_same_thread=False)
        self.addCleanup(self.db.close)
        self.store=PlayerStore(self.db,copy.deepcopy(self.config),self.clock)
        session=self.store.login(self.id())
        self.uid,self.token=session['uid'],session['sessionid']

    def service(self,name):
        return next(h for h in self.store.gameplay_handlers if type(h).__name__==name)

    def test_online_exploration_energy_assist_and_draw_caps_refresh_at_midnight(self):
        def exhaust(profile):
            profile['records']['exploration_times'].update(refresh_count=0,refresh_buy=3,relive_buy=2,vip_relive=0)
            profile['records']['energy_purchase_day']=game_day(self.clock.now())
            profile['records']['energy_times']=9
            profile['records'].update(free_wager_count=5,help_suids={'friend':1},help_fuids={'friend':1})
            return profile,None
        self.store.atomic_update(self.uid,exhaust)
        self.clock.value=stamp(30,0)
        p=self.store.profile(self.uid)
        self.assertEqual(p['records']['exploration_times']['refresh_count'],3)
        self.assertEqual(p['records']['exploration_times']['refresh_buy'],0)
        self.assertEqual(p['records']['energy_times'],0)
        self.assertEqual(p['records']['free_wager_count'],0)
        self.assertEqual(p['records']['help_suids'],{})
        self.store.atomic_update(self.uid,exhaust)
        self.clock.value=stamp(30,12)
        p=self.store.profile(self.uid)
        self.assertEqual(p['records']['exploration_times']['refresh_count'],0)
        self.assertEqual(p['records']['energy_times'],9)
        self.assertEqual(p['records']['free_wager_count'],5)
        self.clock.value=stamp(31,0)
        # An active session's write path refreshes caps without another login.
        result,_=self.store.atomic_update(self.uid,lambda p:(p,p['records']['free_wager_count']))
        self.assertEqual(result,0)

    def test_material_boss_guild_and_adventure_day_ownership(self):
        p=self.store.profile_raw(self.uid)
        material=daily_state(p,self.clock.now());material['uses']['P_001']=12;material['buys']['P_001']=2
        guild=self.service('GameplayGuildBoss')
        boss=guild._boss_state(p,'guild_boss');boss['free_num']=0
        p['records']['guild_daily']={'day':game_day(self.clock.now()),'donate':2}
        adventure=self.store.adventure._state(p);adventure['daily_counts']['draw']=3;adventure['daily_claimed']=['draw']
        self.clock.value=stamp(30,0)
        self.assertEqual(daily_state(p,self.clock.now())['uses'],{})
        self.assertEqual(daily_state(p,self.clock.now())['buys'],{})
        self.assertGreater(guild._boss_state(p,'guild_boss')['free_num'],0)
        self.assertEqual(guild._daily_record(p,'donate'),0)
        self.assertNotIn('draw',self.store.adventure._state(p)['daily_counts'])
        self.assertEqual(self.store.adventure._state(p)['daily_claimed'],[])

    def test_check_in_login_and_timestamp_use_the_same_day(self):
        self.assertEqual(self.store._check_in_today(),'2026-10-29')
        self.assertEqual(str(self.store._check_in_date(self.clock.now())),'2026-10-29')
        self.clock.value=stamp(30,0)
        self.assertEqual(self.store._check_in_today(),'2026-10-30')
        self.assertEqual(str(self.store._check_in_date(self.clock.now())),'2026-10-30')
        self.clock.value=stamp(30,12)
        self.assertEqual(self.store._check_in_today(),'2026-10-30')

    def test_spending_and_legacy_shared_caps_preserve_until_midnight(self):
        p=self.store.profile_raw(self.uid)
        self.assertTrue(charge_spending(p,648,self.clock.now()))
        self.assertFalse(charge_spending(p,1,self.clock.now()))
        self.clock.value=stamp(30,0)
        self.assertEqual(normalize_spending(p,self.clock.now())['spent_yuan'],0)
        self.assertTrue(charge_spending(p,100,self.clock.now()))
        self.clock.value=stamp(30,12)
        self.assertEqual(normalize_spending(p,self.clock.now())['spent_yuan'],100)
        p['records'].pop('shared_daily_day',None)
        p['records']['free_wager_count']=5
        from game_calendar import normalize_daily_counters
        normalize_daily_counters(p,self.clock.now())
        self.assertEqual(p['records']['free_wager_count'],5)

    def test_online_arena_rank_settles_once_after_midnight_without_relogin(self):
        def participate(p):
            p['records']['local_pvp_rank_days']={game_day(self.clock.now()):{'played':True,'rank':1}}
            return p,None
        self.store.atomic_update(self.uid,participate)
        request={'uid':self.uid,'sessionid':self.token,'method':'user.get_msg','params':{}}
        self.store.dispatch(request)
        count=lambda:self.db.execute("SELECT COUNT(*) FROM gift_mail WHERE uid=? AND title='本地竞技昨日排名奖励'",(self.uid,)).fetchone()[0]
        self.assertEqual(count(),0)
        self.clock.value=stamp(30,0)
        self.store.dispatch(request)
        self.assertEqual(count(),1)
        self.store.dispatch(request)
        self.assertEqual(count(),1)
        self.clock.value=stamp(30,12)
        self.store.dispatch(request)
        self.assertEqual(count(),1)

    def test_monthly_check_in_changes_month_at_midnight_and_keeps_lifetime_total(self):
        self.clock.value=stamp(31,0)
        def claimed(p):
            p['attrs']['check_in'].update(m=10,month_key='2026-10',last_day='2026-10-31',day=3,n=3,count=50,had_check=[1,1])
            return p,None
        self.store.atomic_update(self.uid,claimed)
        self.clock.value=stamp(31,23,59,59)
        state=self.store.profile(self.uid)['attrs']['check_in']
        self.assertEqual((state['m'],state['day'],state['had_check']),(10,3,[1,1]))
        self.clock.value=stamp(1,0,month=11)
        state=self.store.profile(self.uid)['attrs']['check_in']
        self.assertEqual((state['m'],state['day'],state['n'],state['had_check']),(11,0,0,[0,0]))
        self.assertEqual(state['count'],50)

    def test_main_and_elite_daily_caps_do_not_reset_lifetime_first_clear(self):
        combat=self.service('GameplayCombat')
        combat.config['combat_main']['M_001_1']['limit']=[1,1,1]
        combat.config['combat_main']['M_001_1'].pop('unlimited_attempts',None)
        ids=list(self.store.profile_raw(self.uid)['avatars'])[:3]
        def start(diff,label):
            return combat._start_main(self.uid,{'cid':'M_001_1','diff':diff,'team':[[aid,i,.2] for i,aid in enumerate(ids)],'actionID':label})
        def finish(result,diff,label):
            return combat._finish(self.uid,{'cid':'M_001_1','diff':diff,'fight_id':result['fight_id'],'sign':1,'combat_star':3,'actionID':label})
        for diff in (0,1):
            result=finish(start(diff,f'first-{diff}'),diff,f'first-end-{diff}')
            self.assertTrue(result['first_clear'])
            with self.assertRaises(GameplayFault) as error:start(diff,f'exhausted-{diff}')
            self.assertEqual(error.exception.code,'StageAttemptsExhausted')
        self.clock.value=stamp(30,0)
        for diff in (0,1):
            result=finish(start(diff,f'next-{diff}'),diff,f'next-end-{diff}')
            self.assertFalse(result['first_clear'])
        p=self.store.profile_raw(self.uid)
        for bucket in ('combat_main','combat_main_hard'):
            self.assertEqual(p['records'][bucket]['M_001_1'],2)
            self.assertEqual(p['records']['daily_stage_attempts'][bucket]['M_001_1'],1)


if __name__=='__main__':unittest.main()
