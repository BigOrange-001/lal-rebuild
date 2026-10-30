import unittest
from collections import Counter
from run_hero_strength_independent_104 import focal_schedule


class IndependentSamplingTests(unittest.TestCase):
    def test_exact_focal_count_seats_and_disjoint_unique_lineups(self):
        for size in (35,94,129):
            pool=[f'A_{1000+i}_6' for i in range(size)]
            for aid in (pool[0],pool[-1]):
                with self.subTest(size=size,focal=aid):
                    rows=list(focal_schedule(pool,aid,'mixed'))
                    self.assertEqual(len(rows),1000);self.assertEqual(Counter(r[1] for r in rows),dict.fromkeys(range(10),100))
                    self.assertEqual(len({r[2] for r in rows}),1000)
                    teams=set();enemies=set()
                    for index,seat,seed,roster in rows:
                        self.assertEqual(roster[seat],aid);self.assertEqual(len(set(roster)),10)
                        side=seat//5;t=frozenset(roster[side*5:side*5+5]);e=frozenset(roster[(1-side)*5:(1-side)*5+5])
                        self.assertNotIn(t,teams);self.assertNotIn(e,enemies);teams.add(t);enemies.add(e)

    def test_focal_and_environment_seed_namespaces_do_not_overlap(self):
        pool=[str(i) for i in range(35)];seeds=set()
        for mode in ('mixed','ordinary','skin'):
            for aid in pool[:2]:
                current={x[2] for x in focal_schedule(pool,aid,mode)}
                self.assertFalse(seeds&current);seeds|=current


if __name__=='__main__':unittest.main()
