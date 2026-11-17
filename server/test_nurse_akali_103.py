"""Nurse Akali's live stat bases, overhealing and receiver-side passive."""
import copy
import json
import unittest
from pathlib import Path

from battle_engine import _native_skill_snapshot
from manual_ability_sim import SkillCompleteBattle
from nurse_akali_103 import apply_nurse_akali_103


ROOT = Path(__file__).resolve().parents[1]


class NurseAkali103Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.original = json.loads((ROOT/'config/reconstruction/full-config.json').read_text('utf-8'))
        cls.document = copy.deepcopy(cls.original)
        apply_nurse_akali_103(cls.document)
        cls.cfg = cls.document['cfg']

    def battle(self, level=1, ally=True):
        def unit(aid, side, line=0):
            return dict(aid=aid, isme=side==1, line=line, pos=1800 if side==1 else 1500,
                        hp=10000, hp_max=10000, ap=300, de_ph=999999, de_ma=999999,
                        tpl=[1, 4, 3, 245, 688], new_4attrs={})
        owner = unit('A_1208_6', 1)
        owner.update(skill=_native_skill_snapshot(self.cfg, 'S_271208_6', level),
                     leader_skill=_native_skill_snapshot(self.cfg, 'S_371208_6', level),
                     skillB=_native_skill_snapshot(self.cfg, 'S_471208_6', level))
        friends = [owner, unit('A_1001_6', 1, 2)] if ally else [owner]
        cfg = dict(self.cfg, system_simple=dict(self.cfg['system_simple'], attack=[]))
        return SkillCompleteBattle(friends, [unit('A_1002_6', 2, i) for i in range(3)],
                                   config=cfg, trace_abilities=True)

    def cast(self, b, slot='skill'):
        return b._apply_native_skill(b.a[0], b.b, slot)

    def test_tank_panel_and_growth_convert_once_without_touching_other_heroes(self):
        for q in (5, 6):
            aid = f'A_1208_{q}'
            before = self.original['cfg']['avatar'][aid]['pl']
            h = self.cfg['avatar'][aid]
            self.assertEqual((h['role'], h['stat_profile'], h['tl'][2]), ('双抗坦克', 3, 3))
            for index, factor in ((0,1.2),(1,1.2),(2,.5),(3,.5)):
                self.assertAlmostEqual(h['pl'][index], before[index]*factor)
            for i in (0,1):
                self.assertAlmostEqual(h['pl'][4+i], (before[4+i]+before[6+i])*.75)
                self.assertEqual(h['pl'][4+i], h['pl'][6+i])
            self.assertEqual(h['pl'][8:10], before[8:10])
            low = _native_skill_snapshot(self.cfg, h['pl'][10], 1)
            high = _native_skill_snapshot(self.cfg, h['pl'][10], 10)
            self.assertEqual(low['pl'][:2], [1,2])
            self.assertAlmostEqual(high['skills'][0][4], 1.4)
            self.assertEqual(self.cfg['skill'][h['pl'][11]]['pl'][:2], [3,3])
            self.assertEqual(_native_skill_snapshot(self.cfg,h['pl'][13],1)['skills'],
                             _native_skill_snapshot(self.cfg,h['pl'][13],10)['skills'])
        self.assertEqual(self.cfg['avatar']['A_1217_6'], self.original['cfg']['avatar']['A_1217_6'])
        doc = copy.deepcopy(self.document)
        apply_nurse_akali_103(doc)
        self.assertEqual(doc, self.document)

    def test_dead_units_and_zero_healing_do_not_trigger_or_revive(self):
        b = self.battle()
        owner = b.a[0]
        b._injured(owner,0,4,source=owner)
        self.assertEqual([u['hp'] for u in b.b],[10000]*3)
        owner['hp']=0
        self.assertEqual(b._injured(owner,1000,4,source=b.a[1]),0)
        self.assertEqual(owner['hp'],0)
        self.assertEqual([u['hp'] for u in b.b],[10000]*3)

    def test_gateway_uses_same_panel_and_skills_after_generic_balance(self):
        from gateway import Backend
        backend=Backend(':memory:',ROOT/'config/reconstruction/full-config.json')
        self.addCleanup(backend.db.close)
        cfg=backend.config['cfg']
        h=cfg['avatar']['A_1208_6']
        self.assertEqual((h['role'],h['stat_profile'],h['tl'][2]),('双抗坦克',3,3))
        self.assertEqual(h['pl'][10:12],['S_271208_6','S_371208_6'])
        self.assertEqual(h['pl'][4:6],h['pl'][6:8])
        from mod_tools import load_base
        authored=load_base(ROOT/'config/reconstruction/full-config.json')['cfg']
        for table in ('avatar','skill','equip'):
            self.assertEqual(authored[table],cfg[table],table)


if __name__=='__main__':unittest.main()
