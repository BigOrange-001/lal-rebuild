import collections
import unittest
from pathlib import Path
from gateway import load_game_config
from native_skill_snapshot import _native_skill_snapshot
from hero_strength_native_bridge import NativeSkinBattle
from run_hero_strength_104 import schedule, study_config
from test_manual_ability_sim import unit

ROOT=Path(__file__).resolve().parents[1]


class NativeBridgeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.cfg=load_game_config(ROOT/'config/reconstruction/full-config.json')['cfg']

    def battle(self,family):
        aid=f'A_{family}_6';a=unit(aid,1,1800)
        for key,slot in [('skill',10),('leader_skill',11),('skillB',13)]:
            a[key]=_native_skill_snapshot(self.cfg,self.cfg['avatar'][aid]['pl'][slot],10 if slot==10 else 1)
        return NativeSkinBattle([a,unit('A_1001_6',1,1900)],
                                [unit('A_1002_6',2,1600),unit('A_1003_6',2,1500)],config=self.cfg)

    def test_every_revised_skin_slot_executes_through_real_method_body(self):
        from skin_revision_104 import PARAMS
        for family in PARAMS:
            for slot,key in [(0,'skill'),(1,'leader_skill')]:
                if family==1227 and slot==0:continue
                with self.subTest(family=family,slot=slot):
                    b=self.battle(family);owner=b.a[0]
                    if family==1219 and slot==1:
                        b.invoke(owner,'s2Mark',b.ref(b.b[0]),'airborne',1)
                    with b.context(owner,'active'):
                        self.assertTrue(b.execute(owner,f'skin2_{family}_{slot}',1,owner[key]))
                    self.assertFalse(b._js_contexts)

    def test_ekko_final_target_death_does_not_read_null(self):
        b=self.battle(1140);owner=b.a[0]
        b.b[1]['hp']=0;b.b[0]['hp']=1
        b.js.eval(f'unit({b.uid(owner)}).skin2.phase=true;unit({b.uid(owner)}).skin2.phaseValue=100')
        with b.context(owner,'active'):
            self.assertTrue(b.execute(owner,'skin2_1140_0',1,owner['skill']))
        self.assertEqual(b.b[0]['hp'],0)

    def test_annie_core_accepted_status_and_independent_cooldown(self):
        from equipment_bonds_104 import equipped_bonds, skill_id
        b=self.battle(1221);owner=b.a[0];ally=b.a[1];enemy=b.b[0]
        source=self.cfg['avatar']['A_1221_6']['pl'][13]
        sid=skill_id(self.cfg,'A_1221_6',source,equipped_bonds(self.cfg,'A_1221_6',['E_4999_6']))
        owner['skillB']=_native_skill_snapshot(self.cfg,sid,1)
        b._add_buff(owner,'stun',1,source=enemy)
        self.assertIsNone(b._buff(owner,'stun'))
        self.assertTrue(enemy.get('_manual_dots'))
        b.control(enemy,ally,'root',1)
        self.assertFalse(b.state(ally).get('root'),'immunity rejects the control state as well as its Buff')
        self.assertFalse(b._js_contexts)
        b.turn_start(owner)
        b._add_buff(owner,'silence',1,source=enemy)
        self.assertIsNotNone(b._buff(owner,'silence'),'one owner turn remains on cooldown')
        b.turn_start(owner)
        b._add_buff(owner,'stun',1,source=enemy)
        self.assertIsNone(b._buff(owner,'stun'))
        self.assertFalse(b._js_contexts)

    def test_annie_non_buff_status_paths_respect_immunity_and_retaliate(self):
        for path in ('infection','spread','bleed','mark','bomb','relic'):
            for mode in ('ready','immune','cooldown','purify'):
                if path in ('mark','bomb') and mode=='purify':continue
                with self.subTest(path=path,mode=mode):
                    b=self.battle(1221);annie,ally=b.a;enemy=b.b[0]
                    # Put Annie first in the ordinary caster's target order.
                    ally['pos']=2600
                    if mode=='immune':
                        b.js.eval(f'unit({b.uid(annie)}).skin2.anniePurifyUntil=999')
                    elif mode=='cooldown':
                        b.js.eval(f'unit({b.uid(annie)}).skin2.annieCoreNext=999')
                    elif mode=='purify':
                        b._add_buff(annie,'purify',1,2)
                    skill=dict(skid='TEST',pl=[0,0,700],skills=[['manual_ability','malzahar_n',1]])
                    if path in ('infection','bomb'):
                        with b.context(enemy,'active',skill):
                            b.execute(enemy,'malzahar_n' if path=='infection' else 'kaelthas_n',1,skill)
                    elif path=='spread':
                        ally['hp']=0;ally['pos']=annie['pos']-100
                        b.state(ally)[('malz',7)]={'owner':enemy,'hops':0,'ticks':2,'until':1,'tick_damage':100,'debuff':True}
                        b.death(ally)
                    elif path=='bleed':
                        b._add_manual_skill_dot(annie,'bleed-test','bleed',100,0,2,enemy,6,False)
                    elif path=='mark':
                        b.mark(enemy,annie,'test',2)
                    else:
                        from unittest.mock import patch
                        from abyss_equip_passives import after_damage
                        with patch('abyss_equip_passives.active_normal',return_value={'affix':{'id':10,'value':.5},'hit':set()}):
                            after_damage(b,enemy,annie,100,0,1,None)
                    entries=[v for k,v in b.state(annie).items() if isinstance(k,tuple) and isinstance(v,dict) and v.get('debuff')]
                    remaining=bool(entries or annie.get('_manual_dots') or annie.get('_relic_dots'))
                    self.assertEqual(remaining,mode=='cooldown')
                    # Purify only stops the generic relic DOT; hero statuses still land.
                    lands=mode=='ready' or mode=='purify' and path!='relic'
                    self.assertEqual(bool(enemy.get('_manual_dots')),lands)
                    self.assertFalse(b._js_contexts)
                    if mode=='purify':self.assertEqual(b._buff(annie,'purify').value,1 if path=='relic' else 2)

    def test_annie_poison_is_attack_only_two_ticks_and_independently_stackable(self):
        for hp_max in (10000,1000000):
            with self.subTest(hp_max=hp_max):
                b=self.battle(1221);annie=b.a[0];enemy=b.b[0]
                enemy['hp_max']=enemy['hp']=hp_max
                b._add_buff(annie,'stun',1,source=enemy)
                self.assertIsNone(b._buff(enemy,'poison'),'retaliation must not use native hp-based poison')
                dots=enemy['_manual_dots']
                self.assertEqual(len(dots),1)
                dot=next(iter(dots.values()))
                self.assertEqual((dot['apTick'],dot['hpMaxFraction'],dot['round']),(500,0,2))
                # Keep the existing global damage coefficient and poison
                # vulnerability: each layer must settle like a raw 500 DOT.
                before=enemy['hp']
                tick_damage=b._injured(enemy,500,6,source=annie,dot_kind='poison')
                enemy['hp']=before
                b._tick_manual_skill_dots(enemy)
                self.assertEqual(before-enemy['hp'],tick_damage)
                b.turn_start(annie);b.turn_start(annie)
                b._add_buff(annie,'stun',1,source=enemy)
                self.assertEqual(len(dots),2)
                for damage in (2*tick_damage,tick_damage,0):
                    before=enemy['hp'];b._tick_manual_skill_dots(enemy)
                    self.assertEqual(before-enemy['hp'],damage)
                self.assertFalse(dots)

    def test_native_rebirth_precedes_bless_and_is_not_counted_as_healing(self):
        b=self.battle(1216);bird=b.a[0];enemy=b.b[0]
        b._add_buff(bird,'bless',1)
        b._injured(bird,999999,1,source=enemy)
        self.assertEqual(bird['hp'],int(bird['hp_max']*.3))
        self.assertIsNotNone(b._buff(bird,'bless'))
        self.assertEqual(b.statistics[(1,bird['_owner_token'])]['healing'],0)
        self.assertTrue(b.turn_start(bird))
        self.assertFalse(b.turn_start(bird))
        self.assertEqual(bird['hp'],int(bird['hp_max']*.4))

    def test_ekko_rewind_stays_in_current_fight_after_recorded_lane_ends(self):
        b=self.battle(1140);owner=b.a[0]
        b.invoke(owner,'skin2Event','turn_start',b.ref(owner),b.ref(owner),0,0)
        b.b[0]['hp']=0
        owner['line']=b.a[1]['line']=b.b[1]['line']=1
        owner['hp']=5000
        b.js.eval(f'unit({b.uid(owner)}).skin2.lost=1000')
        with b.context(owner,'active'):
            self.assertTrue(b.execute(owner,'skin2_1140_1',1,owner['leader_skill']))
        self.assertEqual(owner['line'],1)
        self.assertEqual(owner['pos'],1800)
        self.assertGreater(owner['hp'],5000)
        self.assertLess(b.b[1]['hp'],b.b[1]['hp_max'])

    def test_effective_healing_aura_shield_and_attribution(self):
        b=self.battle(1228);owner,ally=b.a;enemy=b.b[0]
        ally['hp']=4000
        b.invoke(owner,'s2Heal',b.ref(ally),1)
        self.assertEqual(ally['hp'],5250)
        self.assertEqual(b.statistics[(1,owner['_owner_token'])]['healing'],1250)
        ally['hp']=ally['hp_max']
        b.invoke(owner,'s2Shield',b.ref(ally),2)
        with b.context(enemy,'active'):b._injured(ally,500,1,source=enemy)
        self.assertEqual(b.statistics[(1,ally['_owner_token'])]['taken'],425)
        self.assertEqual(b.statistics[(2,enemy['_owner_token'])]['damage'],425)

    def test_schedule_has_exact_sides_slots_and_no_duplicate_heroes(self):
        for size in (32,35,94,126,129):
            pool=[str(x) for x in range(size)]
            for cycle in (0,1,99,999):
                rows=schedule(pool,cycle,'mixed')
                self.assertEqual(len(rows),size)
                for row in rows:self.assertEqual(len(set(row)),10)
                for seat in range(10):self.assertEqual(collections.Counter(r[seat] for r in rows),collections.Counter(pool))

    def test_current_named_heroes_are_included_beyond_historical_roster(self):
        cfg,heroes,pools=study_config()
        for aid in ('A_1140_6','A_1139_6','A_1227_6','A_1311_6','A_1801_6','A_1802_6'):
            self.assertIn(aid,pools['skin'])
        self.assertFalse(set(pools['skin']) & set(pools['ordinary']))
        self.assertEqual(set(pools['mixed']),set(pools['skin'])|set(pools['ordinary']))
        self.assertNotIn('A_190001_5',pools['mixed'])
        self.assertTrue(all('序号' not in x['name'] for x in heroes))
        self.assertEqual({k:len(v) for k,v in pools.items()},{'mixed':130,'ordinary':93,'skin':37})
        for aid in ('A_1224_6','A_1225_6','A_1997_6','A_1999_6'):
            self.assertNotIn(aid,pools['mixed'])
        self.assertFalse({'A_1903','A_1904','A_1905','A_1909'} & {aid.rsplit('_',1)[0] for aid in pools['mixed']})

    def test_damage_receipt_keeps_settled_and_actual_damage_through_native_bridge(self):
        b=self.battle(1140);receipt={};before=b.b[0]['hp']
        b._injured(b.b[0],100,1,source=b.a[0],receipt=receipt)
        self.assertEqual(receipt['actual'],before-b.b[0]['hp'])
        self.assertEqual(receipt['settled'],100)


if __name__=='__main__':unittest.main()
