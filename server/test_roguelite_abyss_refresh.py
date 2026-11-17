"""Enemy refresh budgets, frozen battles, migration and per-act skin limits."""
import copy
import unittest

from player_store import GameplayFault, PlayerStore
from roguelite_abyss import hero_record, rules, is_skin
import test_roguelite_abyss as fixtures


class AbyssRefreshTests(unittest.TestCase):
    setUpClass=fixtures.AbyssTests.__dict__['setUpClass']
    setUp=fixtures.AbyssTests.setUp
    call=fixtures.AbyssTests.call
    start=fixtures.AbyssTests.start
    enter=fixtures.AbyssTests.enter
    combat=fixtures.AbyssTests.combat
    finish=fixtures.AbyssTests.finish

    def test_budgets_refresh_replay_reload_and_current_preview_match_combat(self):
        self.assertEqual([d['enemy_refreshes'] for d in rules(self.cfg)['difficulties']],
                         [8,8,7,7,6,6,5,5,4,4])
        run=self.enter(self.start())
        node=next(n for n in run['map'] if n['id']==run['current_node'])
        old_preview=copy.deepcopy(node['enemy_preview'])
        params={'node_id':node['id'],'actionID':'refresh-one'}
        first=self.call('refresh',**params)['abyss_run']
        refreshed=next(n for n in first['map'] if n['id']==node['id'])
        self.assertNotEqual(old_preview,refreshed['enemy_preview'])
        self.assertEqual((first['enemy_refreshes'],first['retries'],first['attempt']),(7,run['retries'],0))
        self.assertTrue(self.call('refresh',**params)['replayed'])
        other_before=[n for n in run['map'] if n['id']!=node['id']]
        self.assertEqual(other_before,[n for n in first['map'] if n['id']!=node['id']])
        store=PlayerStore(self.db,self.document)
        restored=store.dispatch({**self.login,'method':'user.abyss_query','params':{'actionID':'reload'}})['abyss_run']
        self.assertEqual(restored,first)
        battle=self.combat(first)
        self.assertEqual([u['aid'] for u in battle['orgin_team_b']],
                         [u['aid'] for u in refreshed['enemy_preview']])
        before=self.store.profile_raw(self.uid)
        with self.assertRaises(GameplayFault):self.call('refresh',node_id=node['id'])
        self.assertEqual(before,self.store.profile_raw(self.uid))

    def test_refresh_budget_exhaustion_and_wrong_node_roll_back(self):
        run=self.enter(self.start())
        before=self.store.profile_raw(self.uid)
        with self.assertRaises(GameplayFault):self.call('refresh',node_id='other-node')
        self.assertEqual(before,self.store.profile_raw(self.uid))
        for _ in range(8):self.call('refresh',node_id=run['current_node'])
        before=self.store.profile_raw(self.uid)
        with self.assertRaises(GameplayFault) as error:self.call('refresh',node_id=run['current_node'])
        self.assertEqual(error.exception.code,'AbyssRefreshEmpty')
        self.assertEqual(before,self.store.profile_raw(self.uid))

    def test_expired_battle_releases_formation_and_allows_enemy_refresh(self):
        run=self.enter(self.start());battle=self.combat(run)
        def expire(p):
            expired=int(self.store.clock.now())-1
            p['abyss_run']['battle']['expires']=expired
            p['pending_battles']['abyss'][battle['fight_id']]['expires']=expired
            return p,{}
        self.store.atomic_update(self.uid,expire)
        restored=self.call('query')['abyss_run']
        self.assertIsNone(restored['battle'])
        self.assertEqual(restored['enemy_refreshes'],8)
        self.assertEqual(self.call('refresh',node_id=run['current_node'])['abyss_run']['enemy_refreshes'],7)

    def test_player_skin_limits_for_every_act_and_over_limit_roll_back(self):
        self.enter(self.start())
        plan=rules(self.cfg)
        skins=plan['skin_purple'][:4]
        normals=plan['initial_purple'][:3]
        for act in (1,2,3):
            def seed(p):
                run=p['abyss_run'];run['battle']=None
                run['current_node']=next(n['id'] for n in run['map'] if n['act']==act and n['type']=='normal')
                run['pool']={a:hero_record(a) for a in skins+normals}
                p['pending_battles']['abyss']={}
                return p,{}
            self.store.atomic_update(self.uid,seed)
            def form(count):
                ids=skins[:count]+normals[:max(0,3-count)]
                return [[aid,i%3,.2] for i,aid in enumerate(ids)]
            before=self.store.profile_raw(self.uid)
            with self.assertRaises(GameplayFault) as error:self.call('combat',team=form(act+1))
            self.assertEqual(error.exception.code,'AbyssSkinLimit')
            self.assertEqual(before,self.store.profile_raw(self.uid))
            battle=self.call('combat',team=form(act))
            self.assertEqual(sum(is_skin(u['aid'],self.cfg) for u in battle['orgin_team_a']),act)

    def test_old_run_migration_preserves_pending_battle_and_spent_refreshes(self):
        run=self.enter(self.start());battle=self.combat(run)
        def legacy(p):
            r=p['abyss_run'];r.pop('enemy_refreshes');r.pop('enemy_refresh_total')
            for node in r['map']:node.pop('enemy_rules_schema',None)
            return p,{}
        self.store.atomic_update(self.uid,legacy)
        after=self.call('query')['abyss_run']
        self.assertEqual(after['battle']['orgin_team_b'],battle['orgin_team_b'])
        self.assertEqual(after['enemy_refreshes'],8)
        self.finish(battle,2)
        after=self.call('query')['abyss_run']
        node=next(n for n in after['map'] if n['id']==run['current_node'])
        self.assertEqual(node['enemy_rules_schema'],rules(self.cfg)['schema'])
        self.call('refresh',node_id=node['id'])
        self.assertEqual(self.call('query')['abyss_run']['enemy_refreshes'],7)
