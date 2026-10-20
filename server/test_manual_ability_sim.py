"""Delayed effects and state lifetimes in the study's recovered abilities."""
import copy
import unittest

from manual_ability_sim import SkillCompleteBattle


def unit(aid,side,pos):
    return dict(aid=aid,isme=side==1,line=0,pos=pos,hp=10000,hp_max=10000,ap=1000,de_ph=0,de_ma=0,
                lv=99,slv=10,tpl=[1,1,1,200,337],new_4attrs={},range=337)


class ManualAbilityStateTests(unittest.TestCase):
    def battle(self):
        a=[unit('A_1001_6',1,1800)]
        b=[unit('A_1002_6',2,1600),unit('A_1003_6',2,1500),unit('A_1004_6',2,1400)]
        cfg={'avatar':{u['aid']:{'range':337} for u in a+b},'skill':{'TEST':{}},'system_simple':{}}
        return SkillCompleteBattle(a,b,config=cfg,trace_abilities=True)

    def cast(self,battle,kind):
        skill=dict(skid='TEST',pl=[0,0,700],skills=[['manual_ability',kind,1]])
        with battle.context(battle.a[0],'active',skill):return battle.execute(battle.a[0],kind,1,skill)

    def test_guard_is_consumed_per_attack_sequence_and_retalitates(self):
        b=self.battle();owner=b.a[0];enemy=b.b[0]
        self.cast(b,'kayle_c')
        with b.context(enemy,'active'):
            b.hit(enemy,owner,.5,1);b.hit(enemy,owner,.5,1)
            self.assertEqual(owner['hp'],10000)
        self.assertNotIn('guard',b.state(owner))
        self.assertLess(enemy['hp'],10000)
        with b.context(enemy,'active'):b.hit(enemy,owner,.5,1)
        self.assertEqual(owner['hp'],9500)

    def test_counter_only_responds_once_to_each_attacker(self):
        b=self.battle();owner=b.a[0];enemy=b.b[0]
        self.cast(b,'illaoi_c')
        for _ in range(2):
            with b.context(enemy,'active'):b.hit(enemy,owner,.1,1)
        self.assertEqual(b.state(owner)['counter']['left'],1)
        with b.context(b.b[1],'active'):b.hit(b.b[1],owner,.1,1)
        self.assertEqual(b.state(owner)['counter']['left'],0)

    def test_channel_releases_next_turn_and_any_displacement_cancels_it(self):
        b=self.battle();owner=b.a[0];self.cast(b,'nunu_c')
        self.assertTrue(b.turn_start(owner));self.assertTrue(all(u['hp']<10000 for u in b.b))
        b=self.battle();owner=b.a[0];self.cast(b,'nunu_c')
        b._check_move(owner,False,25,True)
        self.assertNotIn('channel',b.state(owner))
        self.assertFalse(b.turn_start(owner));self.assertTrue(all(u['hp']==10000 for u in b.b))

    def test_malzahar_dot_moves_on_death_only_once(self):
        b=self.battle();self.cast(b,'malzahar_n');first=b.b[0]
        key=next(k for k in b.state(first) if isinstance(k,tuple) and k[0]=='malz')
        first['hp']=1;b._injured(first,10,6,source=b.a[0])
        second=b.b[1];self.assertIn(key,b.state(second));self.assertEqual(b.state(second)[key]['hops'],1)
        second['hp']=1;b._injured(second,10,6,source=b.a[0])
        self.assertNotIn(key,b.state(b.b[2]))

    def test_bomb_detonates_on_expiry_or_death_and_purify_clears_it(self):
        for mode in ('expiry','death','purify'):
            with self.subTest(mode=mode):
                b=self.battle();self.cast(b,'kaelthas_n');target=b.b[0]
                before=b.b[1]['hp']
                if mode=='expiry':b.turn_start(target)
                elif mode=='death':target['hp']=1;b._injured(target,10,6,source=b.a[0])
                else:b._add_buff(target,'purify',2,0);b.turn_start(target)
                self.assertEqual(b.b[1]['hp']==before,mode=='purify')

    def test_unknown_ability_fails_explicitly(self):
        b=self.battle()
        with self.assertRaisesRegex(ValueError,'Unsupported'):
            self.cast(b,'unimplemented')

    def test_expiring_dot_can_trigger_revival_and_cleanse_itself(self):
        for kind,value in (('poison',10000),('burn',10000)):
            with self.subTest(kind=kind):
                b=self.battle();owner=b.a[0];owner['hp']=1
                b._add_buff(owner,'bless',1,0);b._add_buff(owner,kind,1,value)
                b._tick_buffs(owner)
                self.assertEqual(owner['hp'],5000)
                self.assertIsNone(b._buff(owner,kind));self.assertIsNone(b._buff(owner,'bless'))


if __name__=='__main__':unittest.main()
