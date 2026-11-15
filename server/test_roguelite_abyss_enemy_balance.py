"""User-specified enemy scaling: all tiers/acts, and fixed weak encounters."""
import unittest
from pathlib import Path
from unittest.mock import patch

from gateway import load_game_config
from roguelite_abyss import generate_enemies, hero_record, rules, standard_team


class EnemyBalanceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.cfg=load_game_config(Path(__file__).resolve().parents[1]/
            'config/reconstruction/full-config.json')['cfg']

    def test_published_enemy_tables_and_retry_budgets(self):
        plan=rules(self.cfg)
        self.assertEqual(plan['enemy_rates'],
            {'weak':.55,'normal':[.8,1,1.2],'elite':1.3,'boss':1.6})
        self.assertEqual([d['multiplier'] for d in plan['difficulties']],
            [.80,.86,.92,.99,1.06,1.13,1.22,1.30,1.40,1.50])
        self.assertEqual([d['retries'] for d in plan['difficulties']],
            [20,20,18,18,16,16,14,14,12,10])

    def unscaled(self, units):
        heroes={str(i):hero_record(u['aid']) for i,u in enumerate(units)}
        formation=[[str(i),i%3,.15+.18*(i//3)] for i in range(len(units))]
        return standard_team(self.cfg,heroes,formation,2,1)

    def test_first_act_weak_enemies_are_identical_at_every_difficulty(self):
        for layer in (1,2,3):
            node={'id':f'1-{layer}-0','act':1,'type':'weak'}
            first=generate_enemies(20261116,1,node,self.cfg)
            self.assertEqual(len(first),3)
            for unit,raw in zip(first,self.unscaled(first)):
                for key in ('hp','ap','de_ph','de_ma'):
                    self.assertEqual(unit[key],max(1,int(raw[key]*.55)))
                self.assertEqual(unit['hp'],unit['hp_max'])
            for difficulty in range(2,11):
                self.assertEqual(first,generate_enemies(20261116,difficulty,node,self.cfg),
                    (layer,difficulty))

    def test_normal_elite_and_boss_apply_act_and_difficulty_to_all_four_stats(self):
        factors=[.80,.86,.92,.99,1.06,1.13,1.22,1.30,1.40,1.50]
        for act,act_factor in enumerate((.8,1,1.2),1):
            for kind,node_factor in (('normal',1),('elite',1.3),('boss',1.6)):
                for difficulty,difficulty_factor in enumerate(factors,1):
                    with self.subTest(act=act,kind=kind,difficulty=difficulty):
                        node={'id':f'{act}-7-0','act':act,'type':kind}
                        units=generate_enemies(20261116,difficulty,node,self.cfg)
                        factor=act_factor*node_factor*difficulty_factor
                        for index,(unit,raw) in enumerate(zip(units,self.unscaled(units))):
                            for key in ('hp','ap','de_ph','de_ma'):
                                expected=max(1,int(raw[key]*factor))
                                if kind=='elite' and index==0:expected=int(expected*1.2)
                                self.assertEqual(unit[key],expected)
                            self.assertEqual(unit['hp'],unit['hp_max'])
                        if kind=='boss':
                            self.assertEqual(len(units),6 if difficulty>=7 else 5)

    def test_optional_research_top_multiplier_preserves_the_new_lower_bound(self):
        from abyss_calibrate import study
        def fake_run(document,difficulty,deck,seed,max_rounds):
            return {'difficulty':difficulty,'deck':deck,'seed':seed,
                    'status':'cleared','retries_used':0,'rows':[]}
        with patch('abyss_calibrate.run_one',side_effect=fake_run),patch('builtins.print'):
            result=study({'cfg':self.cfg},[1],top_multiplier=1.2,decks=('blade',))
        self.assertEqual(result['difficulties'][0]['multiplier'],.8)
        self.assertEqual(result['difficulties'][1]['multiplier'],.8343)
        self.assertEqual(result['difficulties'][-1]['multiplier'],1.2)
        self.assertFalse(result['weak_uses_difficulty_multiplier'])
        self.assertEqual(rules(self.cfg)['difficulties'][-1]['multiplier'],1.5)


if __name__=='__main__':unittest.main()
