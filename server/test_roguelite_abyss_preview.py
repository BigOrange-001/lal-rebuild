"""Frozen display identities, delayed snapshots, boss offers and rest leave."""
import copy
import json
import unittest
from unittest.mock import patch

import test_roguelite_abyss as helpers
from player_store import GameplayFault
from roguelite_abyss import (enemy_role, generate_enemy_preview, generate_enemies,
                             preview_from_units, public_run, rules)


class PreviewTests(unittest.TestCase):
    setUpClass=classmethod(helpers.AbyssTests.setUpClass.__func__)
    setUp=helpers.AbyssTests.setUp
    call=helpers.AbyssTests.call
    start=helpers.AbyssTests.start
    enter=helpers.AbyssTests.enter
    combat=helpers.AbyssTests.combat
    finish=helpers.AbyssTests.finish

    def jump(self, node_id, full_pool=False):
        def update(p):
            run=p['abyss_run'];run['current_node']=node_id
            run['available_nodes']=[];run['battle']=None;run['pending_choice']=None
            if full_pool:
                for hero in run['pool'].values():hero.update(quality=6,aid=hero['aid'][:-1]+'6',slv=10)
            return p,{}
        self.store.atomic_update(self.uid,update)
        return self.call('query')['abyss_run']

    def test_map_query_and_route_only_build_preview_not_combat_stats(self):
        with patch('roguelite_abyss.standard_team',side_effect=AssertionError('built combat stats before combat')):
            run=self.start();self.enter(run);response=self.call('query')['abyss_run']
        private=self.store.profile_raw(self.uid)['abyss_run']
        self.assertTrue(all('enemies' not in n for n in private['map']))
        for node in response['map']:
            self.assertNotIn('enemies',node)
            self.assertTrue(all(set(u)=={'aid','quality','star','lv','slv','line','pos','leader','is_skin','limit_break'} for u in node['enemy_preview']))
            self.assertEqual(len(node['enemy_preview']),0 if node['type']=='rest' else len(next(
                n for n in private['map'] if n['id']==node['id'])['enemy_preview']))
        battle=self.combat(response)
        node=next(n for n in private['map'] if n['id']==response['current_node'])
        self.assertEqual(node['enemy_preview'],preview_from_units(battle['orgin_team_b'],self.cfg))
        self.finish(battle,2)
        retry=self.combat(self.call('query')['abyss_run'])
        self.assertEqual(battle['orgin_team_b'],retry['orgin_team_b'])

    def test_client_cannot_override_preview_and_legacy_snapshot_is_preserved(self):
        run=self.enter(self.start())
        team=[[h,i%3,.2] for i,h in enumerate(list(run['pool'])[:5])]
        battle=self.call('combat',team=team,enemy_preview=[])
        self.assertTrue(battle['orgin_team_b'])
        legacy=self.store.profile_raw(self.uid)['abyss_run']
        node=next(n for n in legacy['map'] if n['id']==legacy['current_node'])
        expected=copy.deepcopy(node['enemies']);node.pop('enemy_preview')
        view=public_run(legacy,self.store.profile_raw(self.uid),self.cfg)
        projected=next(n for n in view['map'] if n['id']==node['id'])
        self.assertEqual(projected['enemy_preview'],preview_from_units(expected,self.cfg))
        self.assertEqual(node['enemies'],expected)

    def test_rest_leave_without_a_hero_when_everyone_is_fully_upgraded(self):
        run=self.start();rest=next(n['id'] for n in run['map'] if n['type']=='rest')
        before=self.jump(rest,full_pool=True)
        first=self.call('rest',option='leave',actionID='leave-rest')['abyss_run']
        self.assertEqual(first['pool'],before['pool'])
        self.assertTrue(next(n for n in first['map'] if n['id']==rest)['completed'])
        self.assertTrue(first['available_nodes'])
        self.assertTrue(self.call('rest',option='leave',actionID='leave-rest')['replayed'])
        with self.assertRaises(GameplayFault):self.call('rest',option='leave')
        self.enter(first)
        with self.assertRaises(GameplayFault):self.call('rest',option='leave')

    def test_first_two_boss_offers_are_saved_replayable_and_skippable_final_boss_has_none(self):
        self.start()
        for act in (1,2,3):
            run=self.jump(f'{act}-8-0');battle=self.combat(run)
            response=self.finish(battle,actionID=f'boss-{act}')
            self.assertTrue(self.finish(battle,actionID=f'boss-{act}')['replayed'])
            run=response['abyss_run'];choice=run['pending_choice']
            if act<3:
                self.assertEqual(run['status'],'active')
                self.assertEqual(len(choice['options']),3)
                self.assertTrue(all(h['quality']==6 for h in choice['options']))
                self.assertEqual(choice,self.call('query')['abyss_run']['pending_choice'])
                with self.assertRaises(GameplayFault):self.enter(run)
                if act==1:
                    chosen=choice['options'][0]['id']
                    run=self.call('choose',heroes=[chosen])['abyss_run']
                    self.assertIn(chosen,run['pool'])
                else:
                    run=self.call('skip')['abyss_run']
                    self.assertIsNone(run['pending_choice'])
            else:
                self.assertEqual(run['status'],'cleared')
                self.assertIsNone(choice)

    def test_enemy_skin_and_orange_quotas_for_all_acts_layers_and_difficulties(self):
        scenarios=[(1,'weak',i,0,0) for i in (1,2,3)]
        scenarios += [(1,'elite',5,1,0),(1,'normal',6,1,0),(1,'boss',7,2,1),
            (2,'normal',1,2,0),(2,'elite',5,2,1),(2,'boss',7,3,2),
            (3,'normal',1,3,1),(3,'elite',3,3,2),(3,'normal',6,4,1),
            (3,'elite',5,4,2),(3,'boss',7,5,3)]
        for difficulty in range(1,11):
            for act,kind,layer,oranges,skins in scenarios:
                node={'id':f'{act}-{layer}-0','act':act,'layer':layer,'type':kind}
                for seed in range(8):
                    preview=generate_enemy_preview(seed,difficulty,node,self.cfg)
                    self.assertEqual(sum(u['quality']==6 for u in preview),oranges,(node,difficulty))
                    self.assertEqual(sum(u['is_skin'] for u in preview),skins,(node,difficulty))
                    self.assertEqual(sum(u['leader'] for u in preview),1)
                    self.assertEqual({u['line'] for u in preview},{0,1,2})
                    self.assertEqual(len({u['aid'].rsplit('_',1)[0] for u in preview}),len(preview))
                    self.assertTrue(all(u['quality']==6 for u in preview if u['is_skin']))
                    self.assertEqual(preview,generate_enemy_preview(seed,difficulty,node,self.cfg))

    def test_boss_replacements_preserve_roles_and_act_three_is_distinct(self):
        from roguelite_abyss import rng_for
        plan=rules(self.cfg)
        first={a.rsplit('_',1)[0] for d in plan['boss_decks']['1'] for a in d}
        third={a.rsplit('_',1)[0] for d in plan['boss_decks']['3'] for a in d}
        self.assertFalse(first&third)
        for act in (2,3):
            for seed in range(40):
                node={'id':f'{act}-8-0','act':act,'layer':8,'type':'boss'}
                template=rng_for(seed,'enemy',node['id']).choice(plan['boss_decks'][str(act)])
                preview=generate_enemy_preview(seed,1,node,self.cfg)
                for base,unit in zip(template,preview):
                    self.assertEqual(enemy_role(base,self.cfg),enemy_role(unit['aid'],self.cfg))
                    if unit['is_skin']:self.assertIn(unit['aid'],plan['enemy_skin_orange'])


if __name__=='__main__':unittest.main()
