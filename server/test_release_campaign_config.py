"""Production loading must never activate the separate hero-training fixture."""
import unittest
from pathlib import Path
from gateway import load_game_config

ROOT = Path(__file__).resolve().parents[1]


class ReleaseCampaignTests(unittest.TestCase):
    def test_default_configuration_keeps_real_campaign_and_enemy_rosters(self):
        document=load_game_config(ROOT/'config/reconstruction/full-config.json')
        cfg=document['cfg']
        self.assertNotIn('kaisa_playtest',document)
        self.assertNotIn('A_1880_3',cfg['avatar'])
        self.assertNotEqual(cfg['battle_main']['M_001']['name'],'卡莎技能测试场')
        for number in range(1,7):
            stage=cfg['combat_main'][f'M_001_{number}']
            self.assertNotIn('靶场',stage['name'])
            self.assertGreater(stage['energy'],0)
            self.assertTrue(stage['team2'])
            self.assertTrue(all(row[0]!='A_1880_3' for row in stage['team2']))


if __name__=='__main__':unittest.main()
