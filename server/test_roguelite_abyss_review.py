import copy
import unittest

from abyss_equip_passives import tick_dots
from abyss_relics import A_TYPES, apply_relic_config, variant_id
from battle_engine import _native_skill_snapshot
from player_store import GameplayFault
import test_team_presets as presets
import test_roguelite_abyss_passives as passives
import test_mod_packages as mods
from mod_packages import ModCatalog


class PresetRelicTests(unittest.TestCase):
    setUp=presets.TeamPresetTests.setUp
    call=presets.TeamPresetTests.call
    change=presets.TeamPresetTests.change

    def test_new_seven_column_preset_roundtrips_owned_relic(self):
        def equip(p):
            p['abyss_relics']={'relic-owned':{'id':'relic-owned'}}
            p['as_equips'][0]=p['as_equips'][0][:6]+['relic-owned']
        self.change(equip)
        saved=self.call('save',1)
        self.change(lambda p:p['as_equips'][0].__setitem__(6,None))
        restored=self.call('load',1)
        self.assertEqual(restored['as_equips'],saved['as_equips'])

    def test_old_six_column_preset_preserves_current_relic_and_missing_relic_rolls_back(self):
        self.call('save',1)
        def legacy(p):
            for row in p['attrs']['team_presets'][0]['as_equips']:del row[6:]
            p['abyss_relics']={'relic-owned':{'id':'relic-owned'}}
            p['as_equips'][0][6]='relic-owned'
        self.change(legacy)
        self.assertEqual(self.call('load',1)['as_equips'][0][6],'relic-owned')
        self.call('save',2)
        self.change(lambda p:p['abyss_relics'].pop('relic-owned'))
        before=self.store.profile_raw(self.uid)
        with self.assertRaises(GameplayFault) as caught:self.call('load',2)
        self.assertEqual(caught.exception.code,'PresetMissingAssets')
        self.assertEqual(before,self.store.profile_raw(self.uid))


class CleansedDotTests(unittest.TestCase):
    setUpClass=classmethod(passives.PassiveTests.setUpClass.__func__)
    battle=passives.PassiveTests.battle

    def test_revive_cleansing_stops_other_attackers_dot_ticks(self):
        for ancient in (False,True):
            b,owner,enemy=self.battle(4,ancient)
            owner.update(hp=10,hp_max=100)
            owner['_relic_dots']=[{'kind':'burn','source':source,'amount':20,'left':2}
                                  for source in (enemy,b.a[1])]
            tick_dots(b,owner)
            self.assertEqual(owner['hp'],62 if ancient else 50)
            self.assertFalse(owner.get('_relic_dots'))
            self.assertEqual(sum(e['event']=='dot_tick' for e in b.equip_events),1)


class ModRelicTests(unittest.TestCase):
    package=mods.ModPackageTest.package
    install=mods.ModPackageTest.install
    selection=mods.ModPackageTest.selection
    compile=mods.ModPackageTest.compile
    patch=mods.ModPackageTest.patch

    def setUp(self):
        mods.ModPackageTest.setUp(self)
        apply_relic_config(self.base)
        self.catalog=ModCatalog(self.root/'mods-with-relics',self.base)

    def test_effective_mod_normal_skill_gets_variants_without_mutating_base(self):
        row=self.patch('skills.normal.cooldown',7)
        before=copy.deepcopy(self.base)
        compiled=self.compile(self.selection(row))
        cfg=compiled.document['cfg'];source=cfg['avatar']['A_1001_5']['pl'][10]
        self.assertNotEqual(source,'S_201001_5')
        for kind in A_TYPES:
            for ancient in (False,True):
                sid=variant_id(source,kind,ancient)
                variant=cfg['skill'][sid]
                self.assertEqual(variant['pl'],cfg['skill'][source]['pl'])
                self.assertEqual(variant['skill'],cfg['skill'][source]['skill'])
                self.assertEqual(variant['relic_source_skill'],source)
                self.assertIn(sid,compiled.roster['skills'])
                self.assertEqual(_native_skill_snapshot(cfg,sid,1)['skid'],sid)
        self.assertEqual(self.base,before)
        self.assertEqual(self.compile().document,self.base)


if __name__=='__main__':unittest.main()
