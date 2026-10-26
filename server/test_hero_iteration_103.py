"""Calibration changes magnitudes without leaking across shared skills."""
import copy
import unittest

from hero_accuracy_103 import apply_hero_accuracy_103
from hero_iteration_103 import SCHEMA, apply_hero_iteration_103


def avatar(normal='S_shared_6', captain='S_other_6'):
    return {'pl': [100, 10, 200, 20, 30, 3, 40, 4, 0, 0, normal, captain, 0, '']}


class HeroIteration103Tests(unittest.TestCase):
    def document(self):
        return {'cfg': {'avatar': {'A_1001_6': avatar(), 'A_1001_5': avatar(),
                                   'A_1002_6': avatar()},
                        'skill': {'S_shared_6': {'id': 'S_shared_6', 'pl': [1, 3],
                                                'skill': [['damage', 2, 1, 'FX']],
                                                'skillUp': [0, .2], 'info': '造成200%伤害'},
                                  'S_other_6': {'id': 'S_other_6', 'pl': [2, 5],
                                               'skill': [['strong', .2, 2, 'FX']]}}}}

    def plan(self, **changes):
        row = {'aid': 'A_1001_6', 'panel_factor': 1.1, 'skill_factor': .9}
        row.update(changes)
        return {'schema': SCHEMA, 'heroes': [row]}

    def test_family_stats_and_private_skill_preserve_excluded_consumer(self):
        document = self.document()
        original = copy.deepcopy(document)
        apply_hero_iteration_103(document, self.plan())
        cfg = document['cfg']
        for aid in ('A_1001_5', 'A_1001_6'):
            self.assertEqual(cfg['avatar'][aid]['pl'][:8], [110, 11, 220, 22, 33, 3.3, 44, 4.4])
            sid = cfg['avatar'][aid]['pl'][10]
            self.assertNotEqual(sid, 'S_shared_6')
            row = cfg['skill'][sid]
            self.assertEqual(row['skill'][0], ['damage', 1.8, 1, 'FX'])
            self.assertEqual(row['skillUp'], [0, .18])
            self.assertEqual(row['pl'], [1, 3])
            self.assertEqual(row['info'], '造成180%伤害')
        self.assertEqual(cfg['avatar']['A_1002_6'], original['cfg']['avatar']['A_1002_6'])
        self.assertEqual(cfg['skill']['S_shared_6'], original['cfg']['skill']['S_shared_6'])
        first = copy.deepcopy(document)
        apply_hero_iteration_103(document, self.plan())
        self.assertEqual(first, document)
        with self.assertRaisesRegex(ValueError, 'different'):
            apply_hero_iteration_103(document, self.plan(panel_factor=1.2))

    def test_unreviewed_shared_native_skill_fails_atomically(self):
        document = self.document()
        document['cfg']['skill']['S_shared_6']['skill'] = [['manual_ability', 'veigar_c', 1]]
        before = copy.deepcopy(document)
        with self.assertRaisesRegex(ValueError, 'shared native'):
            apply_hero_iteration_103(document, self.plan())
        self.assertEqual(before, document)

    def test_invalid_plan_cannot_change_configuration(self):
        for change in ({'panel_factor': float('nan')}, {'skill_factor': True},
                       {'aid': 'A_180003_6'}, {'panel_factor': .1}):
            document = self.document()
            before = copy.deepcopy(document)
            with self.assertRaises(ValueError):
                apply_hero_iteration_103(document, self.plan(**change))
            self.assertEqual(before, document)

    def test_skill_only_scope_rejects_panel_changes(self):
        document=self.document()
        before=copy.deepcopy(document)
        plan=self.plan();plan['scope']='skill-magnitudes-only'
        with self.assertRaisesRegex(ValueError,'cannot change hero panels'):
            apply_hero_iteration_103(document,plan)
        self.assertEqual(before,document)
        plan=self.plan(panel_factor=1,skill_factor=.4);plan['scope']='skill-magnitudes-only'
        apply_hero_iteration_103(document,plan)
        for aid in document['cfg']['avatar']:
            self.assertEqual(document['cfg']['avatar'][aid]['pl'][:8],before['cfg']['avatar'][aid]['pl'][:8])

    def test_flat_and_percentage_fallback_text_matches_scaled_actions(self):
        document=self.document()
        document['cfg']['skill']['S_shared_6'].update(
            skill=[['stat_flat','hit',6300,2,'FX'],['caster_hp_heal',.12,'FX']],
            rankInfoTemplate='精准{flat:0:2}点，治疗{rank:1:1}，持续2回合。')
        apply_hero_iteration_103(document,self.plan(panel_factor=1))
        sid=document['cfg']['avatar']['A_1001_6']['pl'][10]
        self.assertEqual(document['cfg']['skill'][sid]['info'],'精准5670点，治疗10.8%，持续2回合。')

    def test_veigar_accuracy_text_is_scoped_to_ordinary_family_and_idempotent(self):
        document = self.document()
        document['cfg']['avatar'] = {'A_1027_6': avatar(captain='S_shared_6'),
                                      'A_1217_6': avatar(captain='S_other_6')}
        old_skin = copy.deepcopy(document['cfg']['skill']['S_other_6'])
        apply_hero_accuracy_103(document)
        info = document['cfg']['skill']['S_shared_6']['info']
        self.assertIn('30000', info)
        self.assertIn('释放结束后还原', info)
        apply_hero_accuracy_103(document)
        self.assertEqual(info, document['cfg']['skill']['S_shared_6']['info'])
        self.assertEqual(old_skin, document['cfg']['skill']['S_other_6'])


if __name__ == '__main__':
    unittest.main()
