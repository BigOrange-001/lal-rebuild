import unittest
from pathlib import Path

from battle_engine import base_unit
from dafeiyu import AID
from gateway import load_game_config
from manual_ability_sim import SkillCompleteBattle


class BigFishCaptainTests(unittest.TestCase):
    def test_two_captain_blessings_expire_after_three_owner_actions(self):
        root = Path(__file__).resolve().parents[1]
        cfg = load_game_config(root / 'config/reconstruction/full-config.json')['cfg']
        owner = base_unit(cfg, AID, 10, 10, 0, .7, True, 1)
        friend = base_unit(cfg, 'A_1001_6', 10, 10, 0, .8, False, 1)
        enemy = base_unit(cfg, 'A_1028_6', 10, 10, 0, .3, False, 2)
        battle = SkillCompleteBattle([owner, friend], [enemy], config=cfg)
        owner, friend = battle.a
        self.assertTrue(battle._apply_native_skill(owner, battle.b, 'leader_skill'))
        for unit in (owner, friend):
            with self.subTest(unit=unit['aid']):
                bless = battle._buff(unit, 'bless')
                self.assertEqual((bless.round, bless.value), (3, 1))
                for _ in range(3):
                    battle._settle_turn_buffs(unit)
                    self.assertIs(battle._buff(unit, 'bless'), bless)
                battle._settle_turn_buffs(unit)
                self.assertIsNone(battle._buff(unit, 'bless'))
