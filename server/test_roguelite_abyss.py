"""Mode contracts: real store, seed domains, state machine and settlement races."""
import concurrent.futures
import copy
import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

from gateway import Backend
from player_store import GameplayFault, PlayerStore
from roguelite_abyss import (apply_abyss_config, generate_map, hero_record,
    standard_team, unlocked_pool, candidates, rules)

ROOT = Path(__file__).resolve().parents[1]


class AbyssTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        backend = Backend(':memory:',ROOT/'config/reconstruction/full-config.json')
        cls.document = backend.config
        cls.cfg = cls.document['cfg']
        backend.db.close()

    def setUp(self):
        self.db = sqlite3.connect(':memory:',check_same_thread=False)
        self.addCleanup(self.db.close)
        self.store = PlayerStore(self.db,self.document)
        self.login = self.store.login('abyss-test')
        self.uid = self.login['uid']
        self.seq = 0

    def call(self, name, **params):
        self.seq += 1
        params.setdefault('actionID',str(self.seq))
        return self.store.dispatch({**self.login,'method':'user.abyss_'+name,'params':params})

    def start(self, **params):
        return self.call('start',difficulty=1,deck='blade',seed=123,**params)['abyss_run']

    def enter(self, run):
        return self.call('route',node_id=run['available_nodes'][0])['abyss_run']

    def combat(self, run):
        return self.call('combat',team=[[hid,i%3,.2] for i,hid in enumerate(list(run['pool'])[:5])])

    def finish(self, battle, sign=1, **extra):
        return self.call('finish',fight_id=battle['fight_id'],fight_kind='abyss',
                         metadata=battle['metadata'],sign=sign,**extra)

    def test_map_seed_and_every_path_has_rest_elite_and_boss(self):
        for difficulty in (1,5,10):
            first = generate_map(17,difficulty,self.cfg)
            self.assertEqual(first,generate_map(17,difficulty,self.cfg))
            self.assertNotEqual(first,generate_map(18,difficulty,self.cfg))
            for act in range(1,4):
                nodes = [n for n in first if n['act']==act]
                layers = [{n['type'] for n in nodes if n['layer']==layer} for layer in range(1,8)]
                self.assertIn({'rest'},layers)
                self.assertGreaterEqual(layers.count({'elite'}),2 if difficulty==10 else 1)
                self.assertEqual(layers[-1],{'boss'})
                self.assertTrue(all(2<=len(n['next'])<=3 or n['type']=='boss' or n['layer']==6 for n in nodes if n['next']))

    def test_config_decks_unique_and_initial_pool_fifty(self):
        plan = rules(self.cfg)
        self.assertEqual(len(plan['initial_purple']),50)
        members = [a for d in plan['decks'].values() for a in d['members']]
        self.assertEqual(len(members),len(set(members)))
        self.assertTrue(set(members)<=set(plan['initial_purple']))
        self.assertTrue(all(a[:-1]+'6' in self.cfg['avatar'] for a in plan['skin_purple']))

    def test_standardized_level_quality_bonds_and_no_external_growth(self):
        heroes = {a:hero_record(a) for a in ('A_1001_5','A_1007_5','A_1009_5')}
        units = standard_team(self.cfg,heroes,[[a,i,.2] for i,a in enumerate(heroes)])
        self.assertTrue(units[0]['bonds_104'])
        self.assertTrue(all(u['lv']==125 and u['talent'] is None and 'limit_break' not in u for u in units))
        self.assertEqual(sum(u['leader'] for u in units),1)
        self.assertTrue(all(u['leader_skill'] is None for u in units[1:]))
        base = standard_team(self.cfg,{'a':hero_record('A_1002_5'),'b':hero_record('A_1003_5'),'c':hero_record('A_1004_5')},[['a',0,.2],['b',1,.2],['c',2,.2]])
        self.assertEqual(base[0]['ap'],int(self.cfg['avatar']['A_1002_5']['pl'][2]+124*self.cfg['avatar']['A_1002_5']['pl'][3]))

    def test_migration_before_sale_after_award_and_repeat_load(self):
        before = self.store.profile_raw(self.uid)
        before.pop('abyss_account',None)
        before['avatars'] = {'x':{'aid':'A_1201_5|1'}}
        self.db.execute('UPDATE players SET profile=? WHERE uid=?',(json.dumps(before),self.uid)); self.db.commit()
        def sale(p): p['avatars']={}; return p,{}
        self.store.atomic_update(self.uid,sale)
        self.assertIn('A_1201_5',self.store.profile_raw(self.uid)['abyss_account']['obtained'])
        def award(p): p['avatars']['gift']={'aid':'A_1202_6|gift'}; return p,{}
        self.store.atomic_update(self.uid,award)
        self.assertIn('A_1202_6',self.store.profile_raw(self.uid)['abyss_account']['obtained'])
        first = self.store.profile(self.uid)['abyss_account']
        self.assertEqual(first,self.store.profile(self.uid)['abyss_account'])
        self.assertEqual(len(first['obtained']),len(set(first['obtained'])))

    def test_first_load_backfills_existing_roster(self):
        p = self.store.profile_raw(self.uid); p.pop('abyss_account',None)
        self.db.execute('UPDATE players SET profile=? WHERE uid=?',(json.dumps(p),self.uid)); self.db.commit()
        first = self.store.profile(self.uid)
        self.assertTrue(first['abyss_account']['obtained'])
        revision = self.store.state_revision(self.uid)
        self.assertEqual(first['abyss_account'],self.store.profile(self.uid)['abyss_account'])
        self.assertEqual(revision,self.store.state_revision(self.uid))

    def test_locked_deck_and_difficulty_roll_back(self):
        for params in ({'difficulty':2,'deck':'blade'},{'difficulty':1,'deck':'summon'}):
            before = self.store.profile_raw(self.uid)
            with self.assertRaises(GameplayFault): self.call('start',seed=10,**params)
            self.assertEqual(before,self.store.profile_raw(self.uid))

    def test_invalid_formations_and_routes_rollback(self):
        run = self.enter(self.start()); heroes = list(run['pool'])
        for team in ([],[[heroes[0],0,.2]],[[heroes[0],0,.2]]*3,
                     [[heroes[i],i,float('nan')] for i in range(3)],
                     [[heroes[i],i,True] for i in range(3)],
                     [[heroes[i],True,.2] for i in range(3)]):
            before = self.store.profile_raw(self.uid)
            with self.assertRaises(GameplayFault): self.call('combat',team=team)
            self.assertEqual(before,self.store.profile_raw(self.uid))
        with self.assertRaises(GameplayFault): self.call('route',node_id='3-7-0')

    def test_loss_preserves_enemy_map_pool_and_twenty_retries_then_terminal(self):
        run = self.enter(self.start())
        for index in range(21):
            battle = self.combat(run)
            result = self.finish(battle,2)
            after = result['abyss_run']
            self.assertEqual(after['map'],run['map'])
            self.assertEqual({k:v['aid'] for k,v in after['pool'].items()},{k:v['aid'] for k,v in run['pool'].items()})
            self.assertEqual(after['retries'],max(0,19-index))
            self.assertEqual(after['status'],'failed' if index==20 else 'active')
            if index==0:
                self.assertTrue(set(h['aid'] for h in run['pool'].values())<=set(result['abyss_account']['appeared']))
            run = after

    def test_replay_payload_conflict_and_parallel_settlement(self):
        run = self.enter(self.start()); battle = self.combat(run)
        params = {'fight_id':battle['fight_id'],'metadata':battle['metadata'],'sign':1,'actionID':'concurrent'}
        with concurrent.futures.ThreadPoolExecutor(2) as executor:
            results = list(executor.map(lambda _:self.call('finish',**params),range(2)))
        self.assertEqual(sorted(r['replayed'] for r in results),[False,True])
        before = self.store.profile_raw(self.uid)
        with self.assertRaises(GameplayFault) as caught: self.call('finish',**{**params,'sign':2})
        self.assertEqual(caught.exception.code,'RequestKeyConflict')
        with self.assertRaises(GameplayFault): self.finish(battle)
        self.assertEqual(before,self.store.profile_raw(self.uid))

    def test_pending_choice_blocks_route_and_weak_requires_three(self):
        run = self.enter(self.start()); battle = self.combat(run)
        result = self.finish(battle)['abyss_run']; choice = result['pending_choice']
        self.assertEqual((len(choice['options']),choice['count']),(6,3))
        with self.assertRaises(GameplayFault): self.call('skip')
        with self.assertRaises(GameplayFault): self.call('route',node_id=result['available_nodes'][0])
        selected = [h['id'] for h in choice['options'][:3]]
        after = self.call('choose',heroes=selected)['abyss_run']
        self.assertEqual(len(after['pool']),8)
        self.assertEqual(after['pending_choice'],None)

    def test_resume_saved_candidates_and_active_battle(self):
        run = self.enter(self.start()); battle = self.combat(run)
        reloaded = PlayerStore(self.db,self.document)
        response = reloaded.dispatch({**self.login,'method':'user.abyss_query','params':{'actionID':'reload'}})
        self.assertEqual(battle['orgin_team_a'],response['abyss_run']['battle']['orgin_team_a'])
        self.assertEqual(battle['fight_id'],response['abyss_run']['battle']['fight_id'])
        before = self.store.profile_raw(self.uid)
        with self.assertRaises(GameplayFault): self.combat(run)
        self.assertEqual(before,self.store.profile_raw(self.uid))
        self.finish(battle)
        self.assertEqual(self.call('query')['abyss_run']['pending_choice'],self.call('query')['abyss_run']['pending_choice'])

    def test_orange_unlock_and_temporary_star_is_not_acquisition(self):
        def unlock(p): p['abyss_account']['cleared']=[1,2,3,4,5]; return p,{}
        self.store.atomic_update(self.uid,unlock)
        first = self.call('start',difficulty=6,deck='star',seed=28)
        temporary = next(h for h in first['abyss_run']['pool'].values() if h['temporary'])
        self.assertNotIn(temporary['aid'],first['abyss_account']['obtained'])
        self.assertNotIn(temporary['aid'],first['unlocked']['purple'])
        self.assertEqual(first['abyss_run']['pool'],self.call('query')['abyss_run']['pool'])
        run = self.enter(first['abyss_run']); battle = self.combat(run)
        final = self.finish(battle,2)
        self.assertIn(temporary['aid'][:-1]+'6',final['unlocked']['orange'])
        self.assertNotIn(temporary['aid'],final['unlocked']['purple'])

    def test_full_run_boss_clear_unlock_and_abandon(self):
        run = self.start()
        while run['status']=='active':
            if run['pending_choice']:
                choice = run['pending_choice']
                run = self.call('choose',heroes=[h['id'] for h in choice['options'][:choice['count']]])['abyss_run']
                self.assertLessEqual(len(run['pool']),20)
                continue
            run = self.enter(run)
            node = next(n for n in run['map'] if n['id']==run['current_node'])
            if node['type']=='rest':
                hero = next(h for h in run['pool'].values() if h['slv']==5)
                run = self.call('rest',hero_id=hero['id'],option='skill')['abyss_run']
            else:
                run = self.finish(self.combat(run))['abyss_run']
        self.assertEqual(run['status'],'cleared')
        self.assertGreaterEqual(len(run['rewards']),1)
        account = self.call('query')['abyss_account']
        self.assertEqual(account['max_difficulty'],2)
        self.assertIn('venom',account['decks'])
        self.call('start',difficulty=2,deck='venom',seed=10)
        self.assertEqual(self.call('abandon')['abyss_run']['status'],'abandoned')

    def test_orange_rest_and_pool_cap_and_standalone_elite(self):
        run = self.start()
        p = self.store.profile_raw(self.uid)
        hero = next(iter(run['pool'].values()))
        p['abyss_account']['appeared']=[hero['aid']]
        p['abyss_run']['current_node']='1-4-0'
        self.db.execute('UPDATE players SET profile=? WHERE uid=?',(json.dumps(p),self.uid)); self.db.commit()
        after = self.call('rest',hero_id=hero['id'],option='orange')['abyss_run']
        self.assertEqual(after['pool'][hero['id']]['quality'],6)
        for aid in rules(self.cfg)['initial_purple']:
            after['pool'][aid.rsplit('_',1)[0]]=hero_record(aid)
            if len(after['pool'])>=20: break
        self.assertIsNone(candidates(p,after,{'id':'2-1-0','type':'normal'},self.cfg))
        standalone = rules(self.cfg)['skin_orange_only']
        if standalone:
            p['abyss_account']['obtained']+=standalone
            purple, orange, unlocked = unlocked_pool(p,self.cfg)
            self.assertEqual(set(unlocked),set(standalone))
            self.assertFalse(set(standalone)&set(purple+orange))


if __name__=='__main__': unittest.main()
