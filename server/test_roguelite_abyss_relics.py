import copy
import random
import unittest

from abyss_relics import (SUBSTATS, A_TYPES, main_effect, new_relic,
    normalize_relic_slots, apply_relic_config, variant_id)
from battle_engine import serialize_player_team
from gameplay_roster import GameplayRosterEquipment
from player_store import GameplayFault
from solo_progression import _native_team_power
from test_roguelite_abyss import AbyssTests


class RelicTests(unittest.TestCase):
    setUpClass = classmethod(AbyssTests.setUpClass.__func__)
    setUp = AbyssTests.setUp
    call = AbyssTests.call
    start = AbyssTests.start
    enter = AbyssTests.enter
    combat = AbyssTests.combat

    def give(self, kind=1):
        item = new_relic(self.cfg,random.Random(42),kind)
        def grant(p): p.setdefault('abyss_relics',{})[item['id']]=copy.deepcopy(item); return p,{}
        self.store.atomic_update(self.uid,grant)
        return item

    def test_three_distinct_substats_bounds_and_ancient_exact_ceiling(self):
        samples = [new_relic(self.cfg,random.Random(i),i%20+1) for i in range(1000)]
        ancient = 0
        for item in samples:
            self.assertEqual(len({a['stat'] for a in item['substats']}),3)
            for affix in item['substats']:
                _,lower,upper = SUBSTATS[affix['stat']]
                if affix['ancient']:
                    ancient+=1
                    self.assertEqual(affix['value'],upper*1.25)
                    self.assertTrue(affix['text'].startswith('*'))
                else: self.assertTrue(lower<=affix['value']<=upper)
        self.assertTrue(150<ancient<280)
        for ancient in (False,True):
            sand = main_effect(19,ancient)
            self.assertFalse(sand['ancient'])
            self.assertEqual(sand['value'],2)

    def test_all_main_values_ancient_threshold_duration_and_defender_exceptions(self):
        for kind in range(1,21):
            normal, ancient = main_effect(kind),main_effect(kind,True)
            if kind not in (3,12,19): self.assertAlmostEqual(ancient['value'],normal['value']*1.25)
            self.assertEqual(ancient['duration'],normal['duration'])
            self.assertEqual(ancient['threshold'],normal['threshold'])
            self.assertEqual(ancient['per_round'],normal['per_round'])
        self.assertEqual(main_effect(3,True)['shield_rate'],.25)
        self.assertEqual(main_effect(12,True)['value'],1.5)

    def test_slot_migration_preserves_six_and_is_idempotent(self):
        p = {'as_equips':[[str(j) for j in range(6)] for _ in range(6)]}
        old = copy.deepcopy(p['as_equips'])
        normalize_relic_slots(p)
        self.assertEqual([r[:6] for r in p['as_equips']],old)
        self.assertTrue(all(r[6] is None for r in p['as_equips']))
        before = copy.deepcopy(p)
        normalize_relic_slots(p)
        self.assertEqual(before,p)

    def test_equip_duplicate_guard_unequip_replay_and_legacy_six_slot_update(self):
        item = self.give()
        self.call('relic_equip',item_id=item['id'],slot=0)
        with self.assertRaises(GameplayFault): self.call('relic_equip',item_id=item['id'],slot=1)
        response = self.store.dispatch({**self.login,'method':'user.equip_dress',
            'params':{'actionID':'legacy-six','data':[[None]*6 for _ in range(6)]}})
        self.assertEqual(response['as_equips'][0][6],item['id'])
        response = self.call('relic_unequip',item_id=item['id'],actionID='undress')
        self.assertIsNone(response['as_equips'][0][6])
        self.assertTrue(self.call('relic_unequip',item_id=item['id'],actionID='undress')['replayed'])

    def test_reroll_consumes_only_other_relic_preserves_main_and_replay(self):
        target, material = self.give(3), self.give(19)
        self.call('relic_equip',item_id=material['id'],slot=0)
        before = self.store.profile_raw(self.uid)
        with self.assertRaises(GameplayFault):
            self.call('relic_reroll',item_id=target['id'],material_id=material['id'])
        self.assertEqual(before,self.store.profile_raw(self.uid))
        self.call('relic_unequip',item_id=material['id'])
        request = dict(item_id=target['id'],material_id=material['id'],actionID='reroll')
        first = self.call('relic_reroll',**request)
        self.assertNotIn(material['id'],first['abyss_relics'])
        self.assertEqual(first['abyss_relics'][target['id']]['main'],target['main'])
        self.assertEqual(first['abyss_relics'],self.call('relic_reroll',**request)['abyss_relics'])

    def test_relic_panel_power_and_all_battle_snapshots_and_abyss_isolation(self):
        item = self.give(1)
        item['substats']=[{'stat':k,'value':.12,'ancient':False} for k in ('hp','ap','de_ph')]
        def update(p):
            p['abyss_relics'][item['id']]=item
            return p,{}
        self.store.atomic_update(self.uid,update)
        before = self.store.profile_raw(self.uid)
        iid = before['team'][0][0]
        roster = GameplayRosterEquipment(self.store,self.document)
        bare = roster.battle_attributes(before,iid)
        self.call('relic_equip',item_id=item['id'],slot=0)
        after = self.store.profile_raw(self.uid)
        worn = roster.battle_attributes(after,iid)
        self.assertEqual(worn['hp'],int(bare['hp']*1.12))
        self.assertEqual(worn['ap'],int(bare['ap']*1.12))
        self.assertEqual(worn['equipment_bonds_104'],bare['equipment_bonds_104'])
        self.assertEqual(worn['skillB'],bare['skillB'])
        units = serialize_player_team(self.cfg,after,0,[[iid,0,.2]],roster.battle_attributes)
        self.assertEqual(units[0]['equip_passives'][0]['id'],1)
        self.assertGreater(_native_team_power(self.cfg,units),_native_team_power(self.cfg,[{**units[0],**bare,'new_4attrs':{'hit':0,'flee':0,'crit':0,'tough':0},'relic_contribution':{}}]))
        normalized = self.combat(self.enter(self.start()))['orgin_team_a']
        self.assertTrue(all('equip_passives' not in u and 'relic_contribution' not in u for u in normalized))

    def test_a_variants_preserve_skills_bonds_growth_and_source(self):
        for kind in A_TYPES:
            item = self.give(kind)
            self.call('relic_equip',item_id=item['id'],slot=0)
            p = self.store.profile_raw(self.uid);iid = p['team'][0][0]
            roster = GameplayRosterEquipment(self.store,self.document)
            worn = roster.battle_attributes(p,iid)
            neutral = copy.deepcopy(p); neutral['as_equips'][0][6]=None
            bare = roster.battle_attributes(neutral,iid)
            self.assertNotEqual(worn['skill']['skid'],bare['skill']['skid'])
            self.assertEqual(worn['skill']['skills'],bare['skill']['skills'])
            self.assertEqual(worn['skill']['abyss_relic_A']['id'],kind)
            self.assertEqual(worn['leader_skill'],bare['leader_skill'])
        self.assertIs(apply_relic_config(self.document),self.document)


if __name__=='__main__': unittest.main()
