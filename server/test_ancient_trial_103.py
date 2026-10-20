"""Ancient tier 11..15 power, independent exclusive loot and shared quotas."""
import copy,json,sqlite3,unittest
from pathlib import Path
from ancient_trial_103 import apply_ancient_trial_103,target_power,EXTENDED_CHANCES_BP
from ancient_trial_drop import roll_ancient_trial_drop,roll_ancient_exclusive_drop
from material_attempts_103 import apply_material_attempts_103,remaining
from campaign_workbook_overlay import _power
from gameplay_common import equipment_exclusive_ids
from player_store import PlayerStore,GameplayFault
from gameplay_combat import GameplayCombat

class Roll:
    def __init__(self,value):self.value=value
    def randrange(self,n):return self.value
    def choice(self,pool):return pool[0]

class AncientTrial103Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source=json.loads((Path(__file__).resolve().parents[1]/'config/reconstruction/full-config.json').read_text('utf-8'))
        cls.config=copy.deepcopy(cls.source);apply_ancient_trial_103(cls.config);apply_material_attempts_103(cls.config)
    def test_extension_keeps_existing_enemies_and_power_then_scales_to_two_billion(self):
        cfg=self.config['cfg'];self.assertEqual(cfg['battle_ploy']['P_001']['combat'],15)
        for n in range(1,11):
            old=self.source['combat_ploy'][f'P_001_{n}'];new=cfg['combat_ploy'][f'P_001_{n}']
            for key in ('team2','recommended_power','ancient_equip_drop','enemy_unit_stats_by_diff','reward'):
                self.assertEqual(new[key],old[key])
        last=cfg['combat_ploy']['P_001_10']['recommended_power']
        for tier in range(11,16):
            stage=cfg['combat_ploy'][f'P_001_{tier}'];actual=_power(cfg,stage['team2'],stage['enemy_unit_stats_by_diff']['0'])
            self.assertEqual(stage['win'],[-2]);self.assertEqual(len(stage['team2']),10)
            self.assertEqual(stage['recommended_power'],actual)
            self.assertTrue(last<actual<last*2)
            self.assertLess(abs(actual-target_power(tier))/target_power(tier),.00001)
            last=actual
            self.assertTrue(all((row[1],row[2],row[13],row[14])==(125,10,1,3) for row in stage['team2']))
            self.assertEqual(stage['activity_kind'],'material');self.assertEqual(stage['limit'],[12])
        self.assertLess(abs(last-2_000_000_000),20000)
        for key in ('battle_ploy','combat_ploy'):
            self.assertEqual(cfg[key],self.config[key]);self.assertEqual(cfg[key],self.config['pve'][key])
        before=copy.deepcopy(self.config);apply_ancient_trial_103(before);self.assertEqual(before,self.config)
    def test_exact_normal_and_exclusive_probability_boundaries(self):
        config=self.config;exclusive=set(equipment_exclusive_ids(config))
        for tier,chance in EXTENDED_CHANCES_BP.items():
            sid=f'P_001_{tier}';stage=config['combat_ploy'][sid]
            pool=stage['ancient_equip_drop']['pool'];self.assertFalse(set(pool)&exclusive)
            self.assertEqual(roll_ancient_trial_drop(config,stage,sid,True,Roll(chance-1)),pool[0])
            self.assertIsNone(roll_ancient_trial_drop(config,stage,sid,True,Roll(chance)))
        stage=config['combat_ploy']['P_001_15'];pool=stage['ancient_exclusive_drop']['pool']
        self.assertTrue(set(pool)<=exclusive)
        self.assertEqual(roll_ancient_exclusive_drop(config,stage,'P_001_15',True,Roll(499)),pool[0])
        self.assertIsNone(roll_ancient_exclusive_drop(config,stage,'P_001_15',True,Roll(500)))
        self.assertIsNone(roll_ancient_exclusive_drop(config,stage,'P_001_15',False,Roll(0)))
        bad=copy.deepcopy(stage);bad['ancient_exclusive_drop']['pool']=[stage['ancient_equip_drop']['pool'][0]]
        with self.assertRaises(GameplayFault):roll_ancient_exclusive_drop(config,bad,'P_001_15',True,Roll(0))
    def test_two_independent_rolls_settle_atomically_and_failure_spends_no_attempt(self):
        for normal,special,sign,expected in [(0,0,1,2),(9999,0,1,1),(0,9999,1,1),(9999,9999,1,0),(0,0,2,0)]:
            with self.subTest(normal=normal,special=special,sign=sign):
                db=sqlite3.connect(':memory:',check_same_thread=False);self.addCleanup(db.close)
                store=PlayerStore(db,self.config);uid=store.login(self.id()+str((normal,special,sign)))['uid']
                combat=GameplayCombat(store,self.config);original=combat._reward_rng
                combat._reward_rng=lambda *args:Roll(normal) if args[-1]=='ancient-trial-equipment' else Roll(special) if args[-1]=='ancient-trial-exclusive' else original(*args)
                team=[[aid,i,.2] for i,aid in enumerate(list(store.profile_raw(uid)['avatars'])[:3])]
                started=combat._start_main(uid,{'cid':'P_001_15','diff':0,'team':team})
                params={'cid':'P_001_15','diff':0,'fight_id':started['fight_id'],'sign':sign,'combat_star':3 if sign==1 else 0,'actionID':'finish'}
                won=combat._finish(uid,params);self.assertEqual(len(won['get_equips']),expected)
                self.assertEqual(remaining(store.profile_raw(uid),'P_001',store.clock.now()),11 if sign==1 else 12)
                before=store.profile_raw(uid);self.assertTrue(combat._finish(uid,params)['replayed'])
                self.assertEqual(before,store.profile_raw(uid))
                receipt=combat.dispatch(uid,'user.material_buy_attempt',{'bid':'P_001','actionID':'buy'})
                self.assertEqual(receipt['material_challenge']['remaining'],12 if sign==1 else 13)
    def test_second_item_capacity_failure_rolls_back_first_item_and_challenge_count(self):
        config=copy.deepcopy(self.config);config['cfg']['system_simple']['equip_config'][0]=2
        db=sqlite3.connect(':memory:',check_same_thread=False);self.addCleanup(db.close)
        store=PlayerStore(db,config);uid=store.login(self.id())['uid'];combat=GameplayCombat(store,config)
        combat._reward_rng=lambda *args:Roll(0)
        eid=config['combat_ploy']['P_001_15']['ancient_equip_drop']['pool'][0]
        def seed(p):p['my_equips']={'existing':{'eid':eid,'lv':1,'slv':1}};p['as_equips']=[[] for _ in range(6)];return p,{}
        store.atomic_update(uid,seed)
        team=[[aid,i,.2] for i,aid in enumerate(list(store.profile_raw(uid)['avatars'])[:3])]
        started=combat._start_main(uid,{'cid':'P_001_15','diff':0,'team':team})
        params={'cid':'P_001_15','diff':0,'fight_id':started['fight_id'],'sign':1,'combat_star':3,'actionID':'finish'}
        before=store.profile_raw(uid)
        with self.assertRaises(GameplayFault):combat._finish(uid,params)
        self.assertEqual(store.profile_raw(uid),before)
        def free(p):p['my_equips']={};return p,{}
        store.atomic_update(uid,free)
        won=combat._finish(uid,params);self.assertEqual(len(won['get_equips']),2)
        self.assertEqual(remaining(store.profile_raw(uid),'P_001',store.clock.now()),11)

if __name__=='__main__':unittest.main()
