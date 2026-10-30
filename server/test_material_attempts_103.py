"""Resource victory quotas, per-chapter purchases, retries and day boundaries."""
import copy,json,sqlite3,unittest
from pathlib import Path
from gameplay_combat import GameplayCombat
from player_store import PlayerStore,GameplayFault
from material_attempts_103 import apply_material_attempts_103,remaining
from game_calendar import next_daily_reset

class MaterialAttempts103Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.config=json.loads((Path(__file__).resolve().parents[1]/'config/reconstruction/full-config.json').read_text('utf-8'))
        apply_material_attempts_103(cls.config)
    def setUp(self):
        class Clock:
            value=1792425600
            def now(self):return self.value
        self.clock=Clock();db=sqlite3.connect(':memory:',check_same_thread=False);self.addCleanup(db.close)
        self.store=PlayerStore(db,self.config,self.clock);self.uid=self.store.login(self.id())['uid']
        self.combat=GameplayCombat(self.store,self.config);self.sequence=0
        def seed(p):p['coin']=10000;p['attrs']['energy_extra']=10000;return p,{}
        self.store.atomic_update(self.uid,seed)
        self.team=[[aid,i,.2] for i,aid in enumerate(list(self.store.profile_raw(self.uid)['avatars'])[:3])]
    def start(self,cid):
        self.sequence+=1
        return self.combat._start_main(self.uid,{'cid':cid,'diff':0,'team':self.team,'actionID':f'start-{self.sequence}'})
    def finish(self,started,win=True):
        params={'cid':started['cid'],'diff':0,'fight_id':started['fight_id'],'sign':1 if win else 2,
                'combat_star':3 if win else 0,'actionID':'end-'+started['fight_id']}
        return self.combat._finish(self.uid,params),params
    def buy(self,bid,action):
        return self.combat.dispatch(self.uid,'user.material_buy_attempt',{'bid':bid,'actionID':action})
    def left(self,bid):return remaining(self.store.profile_raw(self.uid),bid,self.clock.now())
    def test_config_includes_biscuits_and_difficulties_share_one_quota(self):
        for stage in self.config['combat_ploy'].values():
            if stage.get('activity_kind')=='material':
                self.assertEqual(stage['limit'],[12]);self.assertNotIn('unlimited_attempts',stage)
        before=copy.deepcopy(self.config);apply_material_attempts_103(before);self.assertEqual(before,self.config)
        first=self.start('P_102_1');self.assertEqual(self.left('P_102'),12)
        _,params=self.finish(first,False);self.assertEqual(self.left('P_102'),12)
        self.combat._finish(self.uid,params);self.assertEqual(self.left('P_102'),12)
        for n in range(12):self.finish(self.start(f'P_102_{1+n%5}'))
        self.assertEqual(self.left('P_102'),0);self.assertEqual(self.left('P_103'),12)
        with self.assertRaises(GameplayFault):self.start('P_102_3')
        self.assertEqual(self.left('P_109'),12)
        self.finish(self.start('P_109_4'));self.assertEqual(self.left('P_109'),11)
    def test_purchase_cost_vip_limits_per_chapter_and_idempotence(self):
        first=self.buy('P_102','one');self.assertEqual((first['coin'],first['material_challenge']['remaining']),(9950,13))
        self.assertTrue(self.buy('P_102','one')['replayed']);self.assertEqual(self.left('P_102'),13)
        self.buy('P_102','two');before=self.store.profile_raw(self.uid)
        with self.assertRaises(GameplayFault):self.buy('P_102','over')
        self.assertEqual(self.store.profile_raw(self.uid),before)
        self.buy('P_109','biscuit');self.assertEqual(self.left('P_109'),13)
        def vip(p):p['vip_lv']=3;return p,{}
        self.store.atomic_update(self.uid,vip)
        for n in range(3):self.buy('P_102',f'vip-{n}')
        with self.assertRaises(GameplayFault):self.buy('P_102','vip-over')
        self.assertEqual(self.left('P_102'),17)
    def test_exhausted_quota_can_buy_then_win_and_failed_attempt_keeps_purchase(self):
        def seed(p):
            from material_attempts_103 import daily_state
            daily_state(p,self.clock.now())['uses']['P_102']=12
            return p,{}
        self.store.atomic_update(self.uid,seed);self.buy('P_102','extra')
        self.finish(self.start('P_102_5'),False);self.assertEqual(self.left('P_102'),1)
        won,params=self.finish(self.start('P_102_2'));self.assertEqual(self.left('P_102'),0)
        after=self.store.profile_raw(self.uid);self.combat._finish(self.uid,params)
        self.assertEqual(self.store.profile_raw(self.uid),after)
    def test_invalid_purchases_and_insufficient_coin_are_atomic(self):
        for bid in ('P_200','P_102_1','P','missing'):
            before=self.store.profile_raw(self.uid)
            with self.assertRaises(GameplayFault):self.buy(bid,bid)
            self.assertEqual(self.store.profile_raw(self.uid),before)
        def poor(p):p['coin']=49;return p,{}
        self.store.atomic_update(self.uid,poor);before=self.store.profile_raw(self.uid)
        with self.assertRaises(GameplayFault):self.buy('P_102','poor')
        self.assertEqual(self.store.profile_raw(self.uid),before)
    def test_new_game_day_resets_both_counts_and_midnight_fight_uses_new_day(self):
        self.clock.value=next_daily_reset(self.clock.value)-60
        self.buy('P_102','yesterday');self.finish(self.start('P_102_1'))
        pending=self.start('P_102_3');self.clock.value+=120
        self.finish(pending);self.assertEqual(self.left('P_102'),11)
        receipt=self.buy('P_102','today')
        self.assertEqual(receipt['material_challenge']['buys'],1)
        self.assertEqual(self.left('P_102'),12)

if __name__=='__main__':unittest.main()
