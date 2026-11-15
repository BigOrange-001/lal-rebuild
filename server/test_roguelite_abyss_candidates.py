"""Candidate rolls, unlock fallback, guarantees and unique hero identities."""
import copy
import random
import unittest
from pathlib import Path
from unittest.mock import patch

from gateway import load_game_config
from roguelite_abyss import candidates, hero_record, is_skin, rules


class CandidateTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.cfg=load_game_config(Path(__file__).resolve().parents[1]/
            'config/reconstruction/full-config.json')['cfg']

    def profile(self, skins=False, orange_skins=False):
        plan=rules(self.cfg)
        return {'avatars':{},'abyss_account':{
            'obtained':plan['skin_purple']+plan['skin_orange_only'] if skins else [],
            'appeared':plan['skin_purple'][:] if orange_skins else [],'cleared':[]}}

    def draw(self, kind, act, seed=13, difficulty=1, profile=None, pool=None, cfg=None):
        return candidates(profile if profile is not None else self.profile(),
            {'pool':pool or {},'seed':seed,'difficulty':difficulty},
            {'id':f'{act}-5-0','act':act,'type':kind},cfg or self.cfg)

    @staticmethod
    def fixed_rng(values):
        from unittest.mock import Mock
        rng=Mock()
        rng.random.side_effect=values
        rng.choice.side_effect=lambda items:items[0]
        rng.shuffle.side_effect=lambda items:None
        return rng

    def test_source_sizes_weak_purple_only_boss_orange_only_and_final_boss_no_choice(self):
        p=self.profile(True,True)
        for seed in range(100):
            weak=self.draw('weak',1,seed,profile=p)
            self.assertEqual((len(weak['options']),weak['count'],weak['can_skip']),(6,3,False))
            self.assertTrue(all(h['quality']==5 and not is_skin(h['aid'],self.cfg) for h in weak['options']))
        self.assertEqual(len(self.draw('normal',2,profile=p)['options']),3)
        for act in (1,2):
            choice=self.draw('boss',act,profile=p)
            self.assertEqual((len(choice['options']),choice['count'],choice['can_skip']),(3,1,True))
            self.assertTrue(all(h['quality']==6 for h in choice['options']))
        self.assertIsNone(self.draw('boss',3,profile=p))

    def test_normal_orange_frequency_is_the_per_card_rate_not_half(self):
        for act,rate,tolerance in ((1,.01,.006),(2,.015,.007),(3,.04,.012)):
            options=[h for seed in range(2000) for h in self.draw('normal',act,seed)['options']]
            observed=sum(h['quality']==6 for h in options)/len(options)
            self.assertLess(abs(observed-rate),tolerance,(act,observed))

    def test_skin_frequency_and_first_act_exclusion(self):
        for act,rate in ((1,0),(2,.15),(3,.35)):
            p=self.profile(True,True)
            options=[h for seed in range(1000) for h in self.draw('normal',act,seed,profile=p)['options']]
            observed=sum(is_skin(h['aid'],self.cfg) for h in options)/len(options)
            if rate==0:self.assertEqual(observed,0)
            else:self.assertLess(abs(observed-rate),.035,(act,observed))

    def test_exact_quality_roll_boundaries_for_normal_and_non_guaranteed_elite(self):
        for kind,rates,size in (('normal',(.01,.015,.04),3),('elite',(.04,.15,.40),5)):
            for act,rate in enumerate(rates,1):
                for difficulty in (1,3):
                    forced=(2 if difficulty==1 else 1) if kind=='elite' else 0
                    for roll,orange in ((rate,False),(rate-1e-9,True)):
                        values=[1]*forced+[v for _ in range(size-forced) for v in (1,roll)]
                        rng=self.fixed_rng(values)
                        with patch('roguelite_abyss.rng_for',return_value=rng):
                            choice=self.draw(kind,act,difficulty=difficulty)
                        self.assertEqual(sum(h['quality']==6 for h in choice['options']),
                            size if orange else forced,(kind,act,difficulty,roll))

    def test_locked_skin_orange_falls_back_to_that_heroes_purple(self):
        p=self.profile();p['abyss_account']['obtained']=['A_1201_5']
        rng=self.fixed_rng([0,0, 1,1, 1,1])
        with patch('roguelite_abyss.rng_for',return_value=rng):
            choice=self.draw('normal',2,profile=p)
        self.assertEqual(choice['options'][0]['aid'],'A_1201_5')

    def test_missing_skin_category_falls_back_to_ordinary_and_guarantees_stay_orange(self):
        for difficulty,forced in ((1,2),(3,1)):
            # A purple-only skin cannot occupy a guaranteed orange slot.
            p=self.profile();p['abyss_account']['obtained']=['A_1201_5']
            values=[0]*forced+[v for _ in range(5-forced) for v in (0,1)]
            with patch('roguelite_abyss.rng_for',return_value=self.fixed_rng(values)):
                choice=self.draw('elite',2,difficulty=difficulty,profile=p)
            self.assertEqual(sum(h['quality']==6 for h in choice['options']),forced)
            self.assertTrue(all(not is_skin(h['aid'],self.cfg) for h in choice['options'][:forced]))
        with patch('roguelite_abyss.rng_for',return_value=self.fixed_rng([0,1]*3)):
            choice=self.draw('normal',3)
        self.assertTrue(all(not is_skin(h['aid'],self.cfg) for h in choice['options']))

    def test_orange_only_skins_require_both_skin_and_orange_rolls(self):
        standalone=rules(self.cfg)['skin_orange_only'][0]
        family=standalone.rsplit('_',1)[0]
        for skin_roll,orange_roll,expected in ((0,0,True),(0,1,False),(1,0,False)):
            p=self.profile();p['abyss_account']['obtained']=['A_1201_5',standalone]
            rng=self.fixed_rng([skin_roll,orange_roll]*3)
            rng.choice.side_effect=lambda items:family if family in items else items[0]
            with patch('roguelite_abyss.rng_for',return_value=rng):
                choice=self.draw('normal',2,profile=p)
            self.assertEqual(any(h['aid']==standalone for h in choice['options']),expected)

    def test_all_sources_exclude_pool_and_duplicate_family_near_capacity(self):
        initial=rules(self.cfg)['initial_purple']
        pool={a.rsplit('_',1)[0]:hero_record(a) for a in initial[:19]}
        p=self.profile(True,True)
        for kind,act,size in (('weak',1,6),('normal',3,3),('elite',3,5),('boss',2,3)):
            for seed in range(50):
                choice=self.draw(kind,act,seed,profile=p,pool=pool)
                ids=[h['id'] for h in choice['options']]
                self.assertEqual(len(ids),size)
                self.assertEqual(len(ids),len(set(ids)))
                self.assertFalse(set(ids)&set(pool))
                self.assertEqual(choice['count'],1)
        pool[initial[19].rsplit('_',1)[0]]=hero_record(initial[19])
        self.assertIsNone(self.draw('boss',2,pool=pool))


if __name__=='__main__':unittest.main()
