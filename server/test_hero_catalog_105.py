"""Abandoned heroes retain save compatibility but leave new-content pools."""
import copy
import unittest
from pathlib import Path

from gateway import load_game_config
from hero_catalog_105 import apply_hero_catalog, is_abandoned
from mod_policy import candidate_ids, channel_enabled, hero_available
from npc_cultivation import NpcCultivator
from arena_opponents import highest_rarity_heroes


class HeroCatalogTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.document=load_game_config(Path(__file__).resolve().parents[1]/'config/reconstruction/full-config.json')
        cls.cfg=cls.document['cfg']

    def test_archive_is_idempotent_and_legacy_heroes_remain_available(self):
        cfg=self.cfg
        families={'A_1224','A_1225','A_1997','A_1999'}
        self.assertEqual(set(cfg['system_simple']['abandoned_hero_families_105']),families)
        for family in families:
            aid=family+'_6'
            self.assertEqual(cfg['avatar'][aid]['development_status_105'],'abandoned')
            self.assertTrue(is_abandoned(cfg,aid+'|existing-instance'))
            self.assertTrue(hero_available(cfg,aid))
            self.assertTrue(channel_enabled(cfg,aid,'usage.friend_assist'))
            for channel in ('appearance.arena_enemy','appearance.friend_npc','acquisition.summon.advanced','acquisition.shop.guild'):
                self.assertFalse(channel_enabled(cfg,aid,channel))
                self.assertEqual(candidate_ids(cfg,[aid],channel),[])
        current=copy.deepcopy(self.document)
        apply_hero_catalog(current)
        self.assertEqual(current,self.document)

    def test_active_npc_summon_and_abyss_catalogues_exclude_abandoned_families(self):
        cfg=self.cfg
        cultivator=NpcCultivator(None,self.document)
        for channel in ('appearance.arena_enemy','appearance.friend_npc'):
            forms=cultivator.family_forms(channel)
            self.assertGreater(len(forms),5)
            self.assertFalse(set(forms)&set(cfg['system_simple']['abandoned_hero_families_105']))
        self.assertFalse(any(is_abandoned(cfg,aid) for aid in highest_rarity_heroes(cfg)))
        for pool in cfg['summon_calibration']['pools'].values():
            for quality in pool['qualities'].values():
                self.assertFalse(any(is_abandoned(cfg,row['id']) for row in quality['cards']))
        self.assertTrue(set(cfg['system_simple']['abandoned_hero_families_105'])<=
                        set(cfg['system_simple']['roguelite_abyss']['excluded_families']))
