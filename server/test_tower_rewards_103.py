"""Tower loot quality, exact totals, weighted uniqueness and atomic receipts."""
import copy,random,sqlite3,unittest
from pathlib import Path
from gateway import Backend
from tower_rewards_103 import roll_tower_reward,apply_tower_rewards_103,_enemy_team,_enemy_pools
from campaign_workbook_overlay import _power
from gameplay_economy import GameplayEconomy
from summon_pools import SummonPools
from gameplay_combat import GameplayCombat
from player_store import PlayerStore,GameplayFault

class TowerRewards103Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.backend=Backend(':memory:',Path(__file__).resolve().parents[1]/'config/reconstruction/full-config.json')
        cls.config=cls.backend.config
    @classmethod
    def tearDownClass(cls):cls.backend.db.close()
    def store(self,floor,config=None):
        config=config or self.config
        db=sqlite3.connect(':memory:',check_same_thread=False);self.addCleanup(db.close)
        store=PlayerStore(db,config);uid=store.login(self.id())['uid']
        def unlock(p):p['records']['tower_floor']=floor;return p,{}
        store.atomic_update(uid,unlock)
        team=[[aid,i,.2] for i,aid in enumerate(list(store.profile_raw(uid)['avatars'])[:3])]
        return store,uid,GameplayCombat(store,config),team
    def fight(self,combat,uid,team,floor,action='finish'):
        cid=f'P_200_{floor}';started=combat._start_main(uid,{'cid':cid,'diff':0,'team':team})
        params={'cid':cid,'diff':0,'fight_id':started['fight_id'],'sign':1,'combat_star':3,
                'teams':{'team_a':started['orgin_team_a'],'team_b':started['orgin_team_b']},'actionID':action}
        return params
    def test_all_floor_tables_updated_and_idempotent(self):
        for floor in range(1,181):
            key=f'P_200_{floor}';stage=self.config['cfg']['combat_ploy'][key]
            self.assertEqual(stage,self.config['combat_ploy'][key])
            self.assertEqual(stage,self.config['pve']['combat_ploy'][key])
            self.assertNotIn('soul_candidates',stage)
            self.assertEqual(stage['win'],[-2])
            rule=stage['tower_reward_rule']
            self.assertEqual(rule['amount'],1 if floor<=40 else 100+2*floor)
        config=copy.deepcopy(self.config);apply_tower_rewards_103(config);self.assertEqual(config,self.config)
        self.assertEqual(self.config['cfg']['pass_battle_gift']['-1']['P_200'],{'need_star':540,'gift':{'coin':188888}})
        for table in ('battle_ploy','pass_battle_gift'):
            self.assertEqual(self.config['cfg'][table],self.config[table])
            self.assertEqual(self.config['cfg'][table],self.config['pve'][table])
    def test_new_floor_power_grows_smoothly_and_matches_serialized_snapshots(self):
        previous=self.config['combat_ploy']['P_200_150']['recommended_power_original_104']['0']
        for floor in range(151,181):
            stage=self.config['combat_ploy'][f'P_200_{floor}']
            self.assertEqual(len(stage['team2']),9)
            actual=_power(self.config['cfg'],stage['team2'],stage['enemy_unit_stats_by_diff']['0'])
            from power_balance_104 import normalize_team_power
            self.assertEqual(stage['recommended_power'],normalize_team_power(actual))
            self.assertTrue(previous<actual<previous*1.06)
            self.assertLess(abs(actual-stage['tower_enemy_rule']['target_power'])/actual,.00001)
            previous=actual
        self.assertLess(abs(previous-50_000_000_000),500_000)
    def test_category_probability_boundaries_and_full_progression(self):
        class Draws:
            def __init__(self):self.tickets=iter([0,39,40,69,70,99,39,69])
            def choice(self,rows):return rows[0]
            def randrange(self,n):return next(self.tickets)
        cfg=self.config['cfg'];team=_enemy_team(cfg,Draws())
        skins=set(cfg['system_simple']['skin_hero_ids'])
        kinds=['skin' if row[0] in skins and row[0].endswith('_6') else 'orange' if row[0].endswith('_6') else 'purple' for row in team]
        self.assertEqual(kinds,['skin','skin','skin','orange','orange','orange','orange','skin','orange'])
        self.assertTrue(all(row[0].endswith('_6') for row in team))
        from battle_engine import serialize_stage_team
        units=serialize_stage_team(cfg,team)
        self.assertEqual({u['line'] for u in units},{0,1,2})
        self.assertEqual(sum(u['leader'] for u in units),1)
        self.assertTrue(all((u['lv'],u['slv'],u['phase'],u['limit_break'])==(125,10,3,1) for u in units))

    def test_mod_summons_missing_heroes_and_scoped_aliases_are_not_extra_candidates(self):
        cfg=copy.deepcopy(self.config['cfg'])
        template=copy.deepcopy(cfg['avatar']['A_1226_6'])
        rows={'A_180002_6':('hero',True),'A_180003_6':('summon',True),
              'A_180004_5':('summon',True),'A_180005_6':('hero',False),
              'A_180006_6':('hero',True)}
        metadata={}
        for aid,(kind,available) in rows.items():
            cfg['avatar'][aid]={**copy.deepcopy(template),'id':aid,'modUnitType':kind}
            metadata[aid]={'kind':'new','unitType':kind,'available':available}
        cfg['avatar']['A_170001_6']={**template,'modBaseAid':'A_1226_6'}
        cfg['avatar']['A_170002_6']={**template,'modBaseAid':'A_180003_6'}
        cfg['mod_runtime']={'heroes':metadata,'missingHeroIds':['A_180006_6'],
                            'aliasBaseIds':{'A_170001_6':'A_1226_6','A_170002_6':'A_180003_6'}}
        pools=_enemy_pools(cfg);aids=[a for group in pools.values() for a in group]
        self.assertIn('A_180002_6',aids)
        self.assertEqual(aids.count('A_1226_6'),1)
        self.assertFalse(set(aids)&{'A_180003_6','A_180004_5','A_180005_6','A_180006_6',
                                    'A_170001_6','A_170002_6','A_190001_5'})
        store,uid,combat,team=self.store(153,{'cfg':cfg,**{k:v for k,v in self.config.items() if k!='cfg'}})
        started=combat._start_main(uid,{'cid':'P_200_153','diff':0,'team':team,'actionID':'mod-enemies'})
        self.assertTrue(all(u['modUnitType']=='hero' for u in started['orgin_team_b']))
    def test_random_encounters_are_bound_to_the_fight_and_final_floor_is_playable(self):
        store,uid,combat,team=self.store(180)
        first=combat._start_main(uid,{'cid':'P_200_180','diff':0,'team':team,'actionID':'start-one'})
        self.assertEqual(first['win'],[-2])
        self.assertEqual(len(first['orgin_team_b']),9)
        pending=store.profile_raw(uid)['pending_pve'][first['fight_id']]
        self.assertEqual(pending['team_b'],first['orgin_team_b'])
        self.assertEqual(pending['stage']['team2'],first['team2'])
        replay=combat._start_main(uid,{'cid':'P_200_180','diff':0,'team':team,'actionID':'start-one'})
        self.assertEqual(replay['fight_id'],first['fight_id'])
        self.assertEqual(replay['team2'],first['team2'])
        params={'cid':'P_200_180','diff':0,'fight_id':first['fight_id'],'sign':1,'combat_star':3,'actionID':'end-one',
                'teams':{'team_a':first['orgin_team_a'],'team_b':first['orgin_team_b']}}
        won=combat._finish(uid,params)
        self.assertEqual(sum(won['new_avatar_soul'].values()),460)
        self.assertEqual(won['tower_floor'],181)
        self.assertEqual(len(won['combat_score']['ploy']['P_200'][1]),180)
        with self.assertRaises(GameplayFault):combat._start_main(uid,{'cid':'P_200_181','diff':0,'team':team})
    def test_completion_requires_180_distinct_three_star_wins_and_pays_once(self):
        store,uid,combat,team=self.store(151);economy=GameplayEconomy(store,self.config)
        def seed(p,count):
            ids=[f'P_200_{n}' for n in range(1,count+1)]
            p['combat_score']['ploy']['P_200']=['0',[3]*count]
            p.setdefault('ploy_cids',{})['P_200']=ids
            p['records']['combat_ploy']={cid:1 for cid in ids}
            return p,{}
        claim=lambda action:economy.get_pass_battle_gift(uid,{'bid':'P_200','diff':-1,'actionID':action})
        store.atomic_update(uid,lambda p:seed(p,150))
        with self.assertRaises(GameplayFault):claim('old150')
        store.atomic_update(uid,lambda p:seed(p,180))
        before=store.profile_raw(uid)['coin'];won=claim('complete')
        self.assertEqual(won['coin']-before,188888)
        self.assertTrue(claim('complete')['replayed'])
        with self.assertRaises(GameplayFault):claim('again')
        self.assertEqual(store.profile_raw(uid)['coin'],won['coin'])
    def test_lower_quality_is_one_full_card_from_advanced_matching_quality(self):
        cfg=self.config['cfg'];pools=cfg['summon_calibration']['pools']['advanced']['qualities']
        for floor,q,key in [(1,4,'blue'),(20,4,'blue'),(21,5,'purple'),(40,5,'purple')]:
            eligible={x['id'] for x in pools[key]['cards'] if x['weight']>0}
            for seed in range(4):
                reward=roll_tower_reward(self.config,self.config['combat_ploy'][f'P_200_{floor}'],random.Random(seed))
                self.assertEqual(set(reward),{'heroes'})
                self.assertEqual(reward['heroes'][0]['num'],1)
                self.assertIn(reward['heroes'][0]['aid'],eligible)
                self.assertTrue(reward['heroes'][0]['aid'].endswith(f'_{q}'))
    def test_orange_exact_total_ten_distinct_positive_shares_and_vip_membership(self):
        eligible={x['id'] for x in self.config['cfg']['summon_calibration']['pools']['vip']['qualities']['orange']['cards'] if x['weight']>0}
        for floor in (41,60,61,80,81,100,101,149,150,151,180):
            for seed in range(4):
                reward=roll_tower_reward(self.config,self.config['combat_ploy'][f'P_200_{floor}'],random.Random(seed))
                self.assertEqual(set(reward),{'avatar_soul'})
                souls=reward['avatar_soul'];self.assertEqual(len(souls),10)
                self.assertEqual(sum(souls.values()),100+floor*2)
                self.assertTrue(set(souls)<=eligible)
                self.assertTrue(all(type(x) is int and x>=1 for x in souls.values()))
    def test_fractional_weights_are_exact_and_draws_are_without_replacement(self):
        calibration=copy.deepcopy(self.config['cfg']['summon_calibration'])
        ids=[x['id'] for x in calibration['pools']['vip']['qualities']['orange']['cards'][:2]]
        calibration['pools']['vip']['qualities']['orange']['cards']=[{'id':ids[0],'weight':.25},{'id':ids[1],'weight':.75}]
        pools=SummonPools(calibration,self.config['cfg']['avatar'])
        class Tickets:
            def __init__(self):self.totals=[]
            def randrange(self,n):self.totals.append(n);return 0
        rng=Tickets();self.assertEqual(pools.draw_quality('vip','orange',rng,2),ids)
        self.assertEqual(rng.totals,[100,75])
        with self.assertRaises(GameplayFault):pools.draw_quality('vip','orange',rng,3)
    def test_full_card_settlement_advances_frontier_and_retry_does_not_duplicate(self):
        store,uid,combat,team=self.store(1);before=store.profile_raw(uid)
        params=self.fight(combat,uid,team,1);won=combat._finish(uid,params)
        self.assertEqual(len(won['get_avatars']),1);self.assertEqual(won['tower_floor'],2)
        self.assertEqual(won['tower_soul_reward'],{})
        after=store.profile_raw(uid);self.assertEqual(len(after['avatars']),len(before['avatars'])+1)
        self.assertTrue(combat._finish(uid,params)['replayed']);self.assertEqual(store.profile_raw(uid),after)
    def test_floor_150_settlement_exposes_all_ten_souls_and_no_extra_card(self):
        store,uid,combat,team=self.store(150);before=store.profile_raw(uid)
        params=self.fight(combat,uid,team,150);won=combat._finish(uid,params)
        self.assertEqual(len(won['new_avatar_soul']),10)
        self.assertEqual(sum(won['new_avatar_soul'].values()),400)
        self.assertEqual(won['new_avatar_soul'],won['tower_soul_reward'])
        self.assertEqual(won['get_avatar_soul'],won['avatar_soul'])
        self.assertEqual(won['get_avatars'],{})
        after=store.profile_raw(uid)
        self.assertEqual(after['avatar_soul'],won['get_avatar_soul'])
        self.assertEqual(len(after['avatars']),len(before['avatars']))
        self.assertTrue(combat._finish(uid,params)['replayed']);self.assertEqual(store.profile_raw(uid),after)
        with self.assertRaises(GameplayFault):combat._finish(uid,dict(params,actionID='different-id'))
        self.assertEqual(store.profile_raw(uid),after)
    def test_invalid_pool_rolls_back_awards_and_preserves_unsettled_intent(self):
        config=copy.deepcopy(self.config)
        cards=config['cfg']['summon_calibration']['pools']['vip']['qualities']['orange']['cards']
        config['cfg']['summon_calibration']['pools']['vip']['qualities']['orange']['cards']=cards[:9]
        store,uid,combat,team=self.store(150,config);params=self.fight(combat,uid,team,150)
        before=store.profile_raw(uid)
        with self.assertRaises(GameplayFault):combat._finish(uid,params)
        self.assertEqual(store.profile_raw(uid),before)

    def test_modded_tower_uses_calibrated_rewards_at_low_orange_and_final_floors(self):
        config=copy.deepcopy(self.config)
        config['cfg']['mod_runtime']={'digest':'tower-review','heroes':{},'scopedAvatarIds':{},
                                     'missingHeroIds':[],'knownHeroIds':[]}
        for floor in (1,150,180):
            with self.subTest(floor=floor):
                store,uid,combat,team=self.store(floor,config)
                params=self.fight(combat,uid,team,floor,action=f'mod-floor-{floor}')
                won=combat._finish(uid,params)
                self.assertEqual(won['tower_floor'],floor+1)
                if floor==1:self.assertEqual(len(won['get_avatars']),1)
                else:
                    self.assertEqual(len(won['new_avatar_soul']),10)
                    self.assertEqual(sum(won['new_avatar_soul'].values()),100+2*floor)

    def test_modded_tower_filtered_vip_pool_rejects_before_spending_or_creating_intent(self):
        config=copy.deepcopy(self.config)
        cards=config['cfg']['summon_calibration']['pools']['vip']['qualities']['orange']['cards']
        config['cfg']['mod_runtime']={'digest':'tower-review','heroes':{
            row['id']:{'available':True,'channels':{'acquisition.summon.activity':False}}
            for row in cards[9:]},'scopedAvatarIds':{},'missingHeroIds':[],'knownHeroIds':[]}
        store,uid,combat,team=self.store(150,config)
        before=store.profile_raw(uid)
        with self.assertRaisesRegex(GameplayFault,'Not enough distinct heroes'):
            combat._start_main(uid,{'cid':'P_200_150','diff':0,'team':team,'actionID':'invalid-mod-pool'})
        self.assertEqual(store.profile_raw(uid),before)

if __name__=='__main__':unittest.main()
