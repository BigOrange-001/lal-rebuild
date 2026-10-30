"""Regression cases for native exploration preview, requests and HP settlement."""
import copy
import math
import unittest
import test_exploration_overhaul as exploration_helpers
from gameplay_combat import GameplayCombat
from player_store import GameplayFault


class ExplorationRegressions(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        exploration_helpers.ExplorationOverhaulTests.setUpClass()
        cls.config = exploration_helpers.ExplorationOverhaulTests.config

    make_medium_roster = exploration_helpers.ExplorationOverhaulTests.make_medium_roster

    def fixture(self):
        store, login, _, ids = self.make_medium_roster()
        combat = GameplayCombat(store, self.config)
        combat._dispatch_exploration(login['uid'], 'user.exploration_make_army', {'aids': ids})
        return store, login['uid'], combat, ids

    def start(self, combat, uid, ids):
        return combat._dispatch_exploration(uid, 'user.exploration_combat',
            {'team': [[iid, 0, .2 + .2*i] for i, iid in enumerate(ids)] + ['', '']})

    def test_preview_health_and_stats_match_all_four_actual_enemies(self):
        store, uid, combat, ids = self.fixture()
        def advance(p): p['exploration']['stage']=12; return p, {}
        store.atomic_update(uid, advance)
        preview = combat._dispatch_exploration(uid, 'user.exploration_opponent', {})
        battle = self.start(combat, uid, ids)
        self.assertEqual(len(preview['army']), 4)
        for row, unit in zip(preview['army'], battle['orgin_team_b']):
            self.assertEqual(row[6:8], [unit['hp'], unit['hp_max']])
            self.assertGreater(row[7], 0)
        self.assertEqual(preview['power'], battle['pr_power'])
        self.assertEqual(preview['units'], battle['orgin_team_b'])

    def test_invalid_or_empty_team_never_silently_selects_another_hero(self):
        for value in ([], ['','',''], 'bad', [['A_1001_5|0', 0, float('nan')]], [['not-owned',0,.2]]):
            store, uid, combat, ids = self.fixture()
            before=store.profile_raw(uid)
            with self.subTest(value=value), self.assertRaises(GameplayFault):
                combat._dispatch_exploration(uid, 'user.exploration_combat', {'team': value})
            self.assertEqual(before, store.profile_raw(uid))

    def test_inflight_roster_or_mode_change_cannot_erase_combat_health(self):
        store, uid, combat, ids = self.fixture()
        self.start(combat, uid, ids)
        for method, params in [('make_army', {'aids':ids[1:]}), ('buy_mode',{})]:
            before=store.profile_raw(uid)
            with self.subTest(method=method), self.assertRaises(GameplayFault) as caught:
                combat._dispatch_exploration(uid, 'user.exploration_'+method, params)
            self.assertEqual(caught.exception.code, 'ExplorationBattlePending')
            self.assertEqual(before, store.profile_raw(uid))

    def test_reordered_same_hero_instances_keep_their_own_health(self):
        store, uid, combat, ids = self.fixture()
        base=ids[0].split('|')[0]
        clones=[base+'|duplicate0',base+'|duplicate1']
        def seed(p):
            for iid in clones:
                p['avatars'][iid]=copy.deepcopy(p['avatars'][ids[0]])
                p['avatars'][iid]['aid']=p['avatars'][iid]['id']=iid
            return p, {}
        store.atomic_update(uid, seed)
        combat._dispatch_exploration(uid,'user.exploration_make_army',{'aids':clones})
        battle=self.start(combat,uid,clones)
        final=copy.deepcopy(battle['orgin_team_a'])
        final[0]['hp']=0; final[1]['hp']=final[1]['hp_max']//2
        combat._finish_exploration(uid, {'fight_id':battle['fight_id'], 'metadata':battle['metadata'],
            'sign':2,'teams':{'team_a':list(reversed(final)),'team_b':[]}})
        army=store.profile_raw(uid)['exploration']['army']
        self.assertEqual(army[clones[0]]['current_hp'],0)
        self.assertAlmostEqual(army[clones[1]]['current_hp']/army[clones[1]]['max_hp'],.5,delta=.001)

    def test_nonfinite_health_is_rejected_before_consuming_battle(self):
        store, uid, combat, ids = self.fixture()
        battle=self.start(combat,uid,ids)
        for field in ('hp','hp_max'):
            final=copy.deepcopy(battle['orgin_team_a']);final[0][field]=float('nan')
            before=store.profile_raw(uid)
            with self.subTest(field=field), self.assertRaises(GameplayFault):
                combat._finish_exploration(uid, {'fight_id':battle['fight_id'], 'metadata':battle['metadata'],
                    'sign':1,'teams':{'team_a':final,'team_b':[]}})
            self.assertEqual(before,store.profile_raw(uid))

    def test_maximum_health_changes_preserve_remaining_percentage(self):
        store, uid, combat, ids = self.fixture()
        def change(p):
            hero=p['exploration']['army'][ids[0]]
            hero['current_hp']=hero['max_hp']//2
            p['avatars'][ids[0]]['hp']+=1000
            return p,{}
        store.atomic_update(uid,change)
        battle=self.start(combat,uid,ids)
        unit=battle['orgin_team_a'][0]
        self.assertAlmostEqual(unit['hp']/unit['hp_max'],.5,delta=.001)

    def test_full_twelve_stage_settlement_claim_replay_and_new_outing(self):
        from battle_engine import ReferenceBattle
        store,uid,combat,ids=self.fixture()
        for stage in range(1,13):
            battle=self.start(combat,uid,ids)
            report=ReferenceBattle(battle['orgin_team_a'],battle['orgin_team_b'],seed=stage*137).run()
            self.assertEqual(report['winner'],1,stage)
            request={'fight_id':battle['fight_id'],'metadata':battle['metadata'],'sign':1,
                     'teams':{name:[{k:u[k] for k in ('aid','hp','hp_max','instance_id') if k in u} for u in report[name]] for name in ('team_a','team_b')},'actionID':'finish-'+str(stage)}
            combat._finish_exploration(uid,request)
            self.assertTrue(combat._finish_exploration(uid,request)['replayed'])
            claim={'actionID':'claim-'+str(stage)}
            first=combat._dispatch_exploration(uid,'user.exploration_get_reward',claim)
            before=store.profile_raw(uid)
            self.assertEqual(first,combat._dispatch_exploration(uid,'user.exploration_get_reward',claim))
            self.assertEqual(before,store.profile_raw(uid))
            self.assertEqual(first['stage'],stage+1)
        self.assertEqual(first['army'],{})
        next_map=combat._dispatch_exploration(uid,'user.exploration_start',{})
        self.assertEqual(next_map['stage'],1)

    def test_paid_refresh_limit_and_unclaimed_reward_do_not_consume_coin(self):
        store,uid,combat,ids=self.fixture()
        def seed(p):
            p['records']['exploration_times'].update(refresh_count=0,refresh_buy=0)
            p['coin']=1000
            return p,{}
        store.atomic_update(uid,seed)
        for index in range(3):
            result=combat._dispatch_exploration(uid,'user.exploration_refresh',{'actionID':'refresh-'+str(index)})
            self.assertEqual(result['refresh_buy'],index+1)
        before=store.profile_raw(uid)
        with self.assertRaises(GameplayFault):combat._dispatch_exploration(uid,'user.exploration_refresh',{})
        self.assertEqual(before,store.profile_raw(uid))
        def ready(p):
            p['records']['exploration_times']['refresh_count']=3
            p['exploration']['current_stage_finish']=1
            return p,{}
        store.atomic_update(uid,ready);before=store.profile_raw(uid)
        with self.assertRaises(GameplayFault):combat._dispatch_exploration(uid,'user.exploration_refresh',{})
        self.assertEqual(before,store.profile_raw(uid))

    def test_reenter_and_reselect_cannot_heal_removed_or_defeated_heroes(self):
        store,uid,combat,ids=self.fixture()
        def seed(p):
            e=p['exploration'];e['stage']=4
            e['army'][ids[0]]['current_hp']=0
            e['army'][ids[1]]['current_hp']=e['army'][ids[1]]['max_hp']//2
            for iid in ids:e['health_ledger'][iid]={k:e['army'][iid][k] for k in ('current_hp','max_hp')}
            return p,{}
        store.atomic_update(uid,seed)
        before=store.profile_raw(uid)['exploration']
        combat._dispatch_exploration(uid,'user.exploration_start',{})
        combat._dispatch_exploration(uid,'user.exploration_make_army',{'aids':ids[1:]})
        reply=combat._dispatch_exploration(uid,'user.exploration_make_army',{'aids':ids})
        self.assertEqual(reply['stage'],4)
        for iid in ids:self.assertEqual(reply['army'][iid]['current_hp'],before['army'][iid]['current_hp'])
        self.assertEqual(store.profile_raw(uid)['exploration']['difficulty'],before['difficulty'])

if __name__=='__main__': unittest.main()
