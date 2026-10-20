"""Target identity, 1.0.3 combat recipients, expiry and repeat-start safety."""
import copy
import json
import unittest
from pathlib import Path

from battle_engine import ReferenceBattle, _native_skill_snapshot, base_unit
from hero_skills_103 import apply_hero_skills_103

ROOT = Path(__file__).resolve().parents[1]


class HeroSkills103Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.original = json.loads((ROOT / 'config/reconstruction/full-config.json').read_text('utf-8'))
        cls.document = copy.deepcopy(cls.original)
        apply_hero_skills_103(cls.document)
        cls.cfg = cls.document['cfg']

    def unit(self, aid='A_1311_6', *, team=1, line=0, pos=500, hp=10000):
        return {'aid': aid, 'isme': team == 1, 'line': line, 'pos': pos,
                'hp': hp, 'hp_max': 10000, 'ap': 100, 'de_ph': 20, 'de_ma': 30,
                'tpl': [1, 2, 1, 250, 600], 'new_4attrs': {}}

    def battle(self, allies=None, enemies=None):
        b = ReferenceBattle(allies or [self.unit()],
                            enemies or [self.unit('A_1001_6', team=2, pos=800)], config=self.cfg)
        for u in b.a:
            u['_team'] = b.a
        return b

    def cast(self, b, sid, level=1):
        b.a[0]['skill'] = _native_skill_snapshot(self.cfg, sid, level)
        self.assertTrue(b._apply_native_skill(b.a[0], b.b))

    def test_exact_portrait_family_and_independent_skills(self):
        old = self.original['cfg']
        changed = {aid for aid in old['avatar'] if old['avatar'][aid] != self.cfg['avatar'][aid]}
        self.assertEqual(changed, {'A_1311_5', 'A_1311_6'})
        for q in (5, 6):
            hero = self.cfg['avatar'][f'A_1311_{q}']
            self.assertIn(f'A_1311_{q}',self.cfg['system_simple']['skin_hero_ids'])
            self.assertEqual(hero['name'], '超级赛亚人孙悟空')
            self.assertEqual(hero['skill_diff'], 19)
            self.assertEqual(hero['res'], f'A_1311_{q}')
            for sid in hero['pl'][10:12]:
                self.assertEqual(self.cfg['skill'][sid]['pl'][:2],[0,0])
                self.assertIn('准备0，冷却0',self.cfg['skill'][sid]['info'])
            self.assertEqual([self.cfg['skill'][sid]['name'] for sid in hero['pl'][10:12] + hero['pl'][13:14]],
                             ['超赛变身', '真·龟派气功', '绝境逢生'])
            for sid in (f'S_9004_{q}', f'S_9005_{q}'):
                self.assertEqual(self.cfg['skill'][sid], old['skill'][sid])
        self.assertEqual(self.cfg['avatar']['A_1005_5'], old['avatar']['A_1005_5'])
        repeated = copy.deepcopy(self.document)
        apply_hero_skills_103(repeated)
        self.assertEqual(repeated, self.document)

    def test_mordekaiser_passive_fivefold_without_changing_trigger_or_duration(self):
        for q in (5, 6):
            aid, sid = f'A_1137_{q}', f'S_9150_{q}'
            self.assertEqual(self.cfg['avatar'][aid], self.original['cfg']['avatar'][aid])
            before = self.original['cfg']['skill'][sid]
            after = self.cfg['skill'][sid]
            self.assertEqual(after['pl'], before['pl'])
            for index, column in ((0, 1), (3, 1), (3, 3), (4, 1), (5, 1)):
                self.assertAlmostEqual(after['skill'][index][column], before['skill'][index][column] * 5)
            self.assertEqual(after['skill'][1:3], before['skill'][1:3])
            self.assertEqual(after['skill'][3][4:], before['skill'][3][4:])
            self.assertEqual(after['skill'][4][2:], before['skill'][4][2:])

    def test_goku_passive_requires_debuff_and_protects_all_lanes(self):
        b = self.battle([self.unit(), self.unit('A_1002_6', line=1, pos=2700)])
        caster = b.a[0]
        caster['skill_diff'] = 19
        caster['skillB'] = _native_skill_snapshot(self.cfg, 'S_401311_6')
        caster['_skill_cd_b'] = -1
        self.assertFalse(b._use_turn_start_passive(caster, b.b))
        b._add_buff(caster, 'curse', 1)
        b._add_buff(caster, 'stun', 1)
        b._add_buff(b.a[1], 'curse', 3)
        self.assertTrue(b._use_turn_start_passive(caster, b.b))
        for ally in b.a:
            self.assertIsNone(b._buff(ally, 'curse'))
            self.assertIsNone(b._buff(ally, 'stun'))
            self.assertEqual(b._buff_value(ally, 'shield'), 300)
            self.assertEqual(b._buff_value(ally, 'strong'), .5)
            self.assertEqual(b._buff_value(ally, 'steel'), 1.5)
            self.assertEqual(b._buff(ally, 'bless').round, 1)
            self.assertGreater(b._buff_value(ally, 'bless'), 0)
        self.assertFalse(b.b[0].get('_buffs'))

    def test_goku_transformation_self_only_and_rank_growth(self):
        for level, expected in ((1, 4500), (10, 9000)):
            b = self.battle([self.unit(hp=5000), self.unit('A_1002_6', pos=550, hp=5000)])
            b._add_buff(b.a[0], 'curse', 2)
            self.cast(b, 'S_201311_6', level)
            self.assertIsNone(b._buff(b.a[0], 'curse'))
            self.assertEqual(b._buff(b.a[0], 'purify').round, 2)
            self.assertEqual(b._buff(b.a[0], 'bless').round, 2)
            for stat in ('hit', 'flee', 'tough'):
                self.assertAlmostEqual(b._buff_value(b.a[0], stat + 'up'), expected)
            self.assertGreater(b.a[0]['hp'], 5000)
            self.assertEqual(b.a[1]['hp'], 5000)
            self.assertFalse(b.a[1].get('_buffs'))

    def test_goku_wave_hits_and_pushes_only_its_lane_even_with_area_scaling(self):
        enemies = [self.unit('A_1001_6', team=2, pos=800),
                   self.unit('A_1002_6', team=2, pos=1500),
                   self.unit('A_1003_6', team=2, line=1, pos=800)]
        b = self.battle([self.unit(pos=2200)], enemies=enemies)
        b._skill_radius_scale = 3
        self.cast(b, 'S_301311_6')
        for before, after in zip(enemies[:2], b.b[:2]):
            self.assertLess(after['hp'], before['hp'])
            self.assertEqual(after['pos'], max(0,before['pos'] - 1500))
        self.assertEqual(b.b[2]['hp'], enemies[2]['hp'])
        self.assertEqual(b.b[2]['pos'], enemies[2]['pos'])

    def test_mordekaiser_captain_cleanses_then_buffs_whole_team(self):
        b = self.battle([self.unit('A_1137_6'), self.unit('A_1002_6', line=2, pos=2500)])
        for ally in b.a:
            b._add_buff(ally, 'curse', 3)
        self.cast(b, 'S_631137_6')
        for ally in b.a:
            self.assertIsNone(b._buff(ally, 'curse'))
            self.assertEqual(b._buff_value(ally, 'shield'), 500)
            self.assertEqual(b._buff_value(ally, 'steel'), 1)
            self.assertEqual(b._buff_value(ally, 'strong'), .2)
            for kind in ('shield', 'steel', 'strong', 'purify', 'bless'):
                self.assertEqual(b._buff(ally, kind).round, 2)
        self.assertEqual(b.b[0]['hp'], 10000)

    def test_mordekaiser_curse_and_dispel_precede_damage(self):
        b = self.battle([self.unit('A_1137_6')], [self.unit('A_1001_6', team=2, pos=800),
                                               self.unit('A_1002_6', team=2, pos=850)])
        for enemy in b.b:
            b._add_buff(enemy, 'shield', 3, 9999)
            b._add_buff(enemy, 'strong', 3, 1)
        b._add_buff(b.a[0], 'curse', 2)
        self.cast(b, 'S_621137_6', 10)
        self.assertIsNone(b._buff(b.b[0], 'shield'))
        self.assertIsNone(b._buff(b.b[0], 'strong'))
        self.assertEqual(b._buff(b.b[0], 'curse').round, 1)
        self.assertLess(b.b[0]['hp'], 10000)
        self.assertEqual(b._buff_value(b.b[1], 'shield'), 9999)
        self.assertIsNone(b._buff(b.a[0], 'curse'))
        self.assertEqual(b._buff_value(b.a[0], 'hitup'), 12000)
        self.assertEqual(b._buff_value(b.a[0], 'critup'), 12000)

    def test_timed_revival_expires_but_legacy_and_stronger_duration_survive(self):
        b = self.battle()
        unit = b.a[0]
        b._add_buff(unit, 'bless', 2, 1)
        b._tick_buffs(unit)
        b._tick_buffs(unit)
        self.assertIsNotNone(b._buff(unit, 'bless'))
        b._tick_buffs(unit)
        self.assertIsNone(b._buff(unit, 'bless'))
        b._add_buff(unit, 'bless', 1, 0)
        b._add_buff(unit, 'bless', 3, 1)
        for _ in range(5):
            b._tick_buffs(unit)
        self.assertEqual(b._buff_value(unit, 'bless'), 0)
        b._remove_buff(unit, 'bless')
        b._add_buff(unit, 'bless', 3, 1)
        b._add_buff(unit, 'bless', 1, 0)
        for _ in range(5):
            b._tick_buffs(unit)
        self.assertEqual(b._buff_value(unit, 'bless'), 0)

    def test_timed_revival_is_consumed_on_lethal_hit(self):
        b = self.battle()
        unit = b.a[0]
        b._add_buff(unit, 'bless', 1, 1)
        b._injured(unit, 100000, damage_type=3, source=b.b[0])
        self.assertGreater(unit['hp'], 0)
        self.assertIsNone(b._buff(unit, 'bless'))

    def test_gateway_exports_effective_config_and_combat_snapshot(self):
        from gateway import Backend
        backend = Backend(':memory:', ROOT / 'config/reconstruction/full-config.json')
        self.addCleanup(backend.db.close)
        cfg = backend.config['cfg']
        row = cfg['avatar']['A_1311_6']
        self.assertEqual(row['skill_diff'], 19)
        unit = base_unit(cfg, 'A_1311_6', team=1, line=0, pos=500)
        self.assertEqual(unit['skill']['skid'], 'S_201311_6')
        self.assertEqual(unit['skillB']['skid'], 'S_401311_6')
        passive=cfg['avatar']['A_1137_6']['pl'][13]
        tuning=next(x for x in cfg['hero_balance_103']['skill_changes'] if x['target']==passive)
        self.assertEqual(tuning['source'],'S_9150_6')
        self.assertAlmostEqual(cfg['skill'][passive]['skill'][0][1],.75*tuning['factor'])
        for aid,normal in (('A_1129_6','S_271129_6'),('A_1202_6','S_271202_6'),('A_1217_6','S_271217_6')):
            self.assertEqual(base_unit(cfg,aid,slv=10)['skill']['skid'],normal)
        # Native banStand is true for pl[5] == 0. A whole-team defensive
        # captain skill must also reach stationary/defensive allies.
        self.assertEqual(cfg['skill']['S_631137_6']['pl'][5], 1)

    def test_latest_numbers_include_rank_growth_and_existing_balance_once(self):
        from gateway import Backend
        backend=Backend(':memory:',ROOT/'config/reconstruction/full-config.json')
        self.addCleanup(backend.db.close)
        cfg=backend.config['cfg']
        from hero_iteration_103 import PLAN
        plan=json.loads(PLAN.read_text('utf8'))
        factor=next((r['skill_factor'] for r in plan['heroes'] if r['aid']=='A_1137_6'),1)
        for q in (5,6):
            for level,stat,damage in ((1,6300,3.276),(10,12600,6.552)):
                h=cfg['avatar'][f'A_1137_{q}']
                s=_native_skill_snapshot(cfg,h['pl'][10],level)
                self.assertEqual(s['pl'][:2],[1,3])
                self.assertAlmostEqual(s['skills'][4][2],stat*factor)
                self.assertAlmostEqual(s['skills'][5][2],stat*factor)
                self.assertAlmostEqual(s['skills'][6][1],damage*factor)
            for level,stat in ((1,4500),(10,9000)):
                s=_native_skill_snapshot(cfg,f'S_201311_{q}',level)
                self.assertEqual(s['pl'][:2],[0,0])
                for index in (2,3,4):self.assertAlmostEqual(s['skills'][index][2],stat)
                self.assertEqual(s['skills'][5][0],'caster_hp_heal')
                self.assertAlmostEqual(s['skills'][5][1],.12 if level==1 else .18)
            self.assertEqual(cfg['skill'][f'S_301311_{q}']['skill'][1][2],1500)
            self.assertEqual(cfg['skill'][f'S_301311_{q}']['pl'][:2],[0,0])
            captain=cfg['skill'][cfg['avatar'][f'A_1137_{q}']['pl'][11]]
            self.assertEqual(captain['skill'][2][1],factor)
            self.assertIn(f'双防提高{100*factor:g}%',captain['info'])
            normal=cfg['skill'][cfg['avatar'][f'A_1137_{q}']['pl'][10]]
            self.assertIn(f'各{6300*factor:g}点',normal['info'])

    def test_goku_healing_uses_only_maximum_hp_at_both_skill_levels(self):
        for level,expected in ((1,1200),(10,1800)):
            for attack in (1,999999):
                b=self.battle([self.unit(hp=1000)])
                b.a[0]['ap']=attack
                b.a[0]['hit']=999999
                self.cast(b,'S_201311_6',level)
                self.assertEqual(b.a[0]['hp'],1000+expected)


if __name__ == '__main__':
    unittest.main()
