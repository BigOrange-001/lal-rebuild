from pathlib import Path
import unittest

from gateway import load_game_config
from hero_mechanic_terms_105 import NOTES, SLOTS, TERMS

ROOT = Path(__file__).resolve().parents[1]
# Popup markup colors: white text, gray (), yellow [], green {}.
MARKUP = {0xFFFFFF, 0xA0A0A0, 0xFFFF00, 0x62CD62}


class HeroMechanicTermTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.cfg = load_game_config(ROOT / 'config/reconstruction/full-config.json')['cfg']

    def skill_text(self, aid, hero):
        simple = self.cfg['system_simple']
        bonds = simple['bond_skill_variants_104'].get(aid, {})
        equipment = simple['equipment_skill_variants_104'].get(aid, {})
        sources = [sid for sid in hero['pl'][10:14] if sid]
        sources.extend(sid for variants in bonds.values() for sid in variants.values())
        ids = sources + [sid for source in sources for sid in equipment.get(source, {}).values()]
        return '\n'.join(str(self.cfg['skill'][sid].get('info', '')) for sid in ids if sid in self.cfg['skill'])

    def test_every_listed_mechanic_reaches_an_avatar_that_uses_it(self):
        found = {}
        for aid, hero in self.cfg['avatar'].items():
            terms = hero.get('tipTerms105') or {}
            text = self.skill_text(aid, hero)
            for term, color in terms.items():
                self.assertIn(term, text, (aid, term))
                self.assertNotIn(color, MARKUP, (aid, term))
                found.setdefault(int(aid.split('_')[1]), set()).add(term)
        for number, terms in TERMS.items():
            self.assertEqual(found.get(number, set()) >= set(terms), True, (number, set(terms) - found.get(number, set())))
        # The heroes named in the request, plus the earlier rage hero.
        for aid, term in (('A_1801_6', '电浆'), ('A_1802_6', '融入黑夜'), ('A_1120_6', '登神长阶'),
                          ('A_1803_6', '无尽怒火'), ('A_1054_6', '巨龙真身')):
            self.assertIn(term, self.cfg['avatar'][aid]['tipTerms105'])

    def test_notes_explain_named_mechanics_on_the_skills_that_use_them(self):
        for number, slots in NOTES.items():
            for aid, hero in self.cfg['avatar'].items():
                if not aid.startswith(f'A_{number}_') or not hero.get('tipTerms105'):
                    continue
                for slot, notes in slots.items():
                    pl = hero['pl']
                    row = self.cfg['skill'].get(pl[SLOTS[slot]]) if len(pl) > SLOTS[slot] else None
                    if row is None:
                        continue
                    own = {term for term, _ in row.get('tipNotes105', [])}
                    for term, _ in notes:
                        if term in hero['tipTerms105']:
                            self.assertIn(term, own, (aid, slot, term))
        kaisa = self.cfg['skill'][self.cfg['avatar']['A_1801_6']['pl'][10]]
        self.assertEqual(kaisa['tipNotes105'], [['电浆', '每发命中叠加1层，5层时引爆']])
        kayle = self.cfg['skill'][self.cfg['avatar']['A_1120_6']['pl'][11]]
        self.assertEqual([n[0] for n in kayle['tipNotes105']], ['登神长阶'])

    def test_aoxing_captain_notes_follow_each_charge_mechanic(self):
        for aid in ('A_1114_4', 'A_1114_5', 'A_1114_6'):
            captain = self.cfg['skill'][self.cfg['avatar'][aid]['pl'][SLOTS['C']]]
            notes = captain['tipNotes105']
            self.assertEqual(len(notes), 1, aid)
            if aid.endswith('_6'):
                self.assertEqual(notes[0][0], '电荷')
                self.assertIn('已有5层', notes[0][1])
            else:
                self.assertEqual(notes[0][0], '风暴电荷')
                self.assertIn('最多3层', notes[0][1])

    def test_caitlyn_wanted_note_uses_the_normal_skill_for_penetration(self):
        for quality, percentage in ((5, '25%'), (6, '100%')):
            hero = self.cfg['avatar'][f'A_1211_{quality}']
            normal = self.cfg['skill'][hero['pl'][SLOTS['N']]]
            captain = self.cfg['skill'][hero['pl'][SLOTS['C']]]
            self.assertIn('通缉', normal['info'])
            self.assertIn(f'{percentage}物防', normal['info'])
            self.assertIn('穿透比例见小技能', dict(captain['tipNotes105'])['通缉'])

    def test_bond_and_equipment_captain_variants_keep_mechanic_notes(self):
        aid = 'A_1211_6'
        simple = self.cfg['system_simple']
        bonds = simple['bond_skill_variants_104'][aid]
        equipment = simple['equipment_skill_variants_104'][aid]
        sources = {self.cfg['avatar'][aid]['pl'][SLOTS['C']]}
        sources.update(row['leader_skill'] for row in bonds.values() if 'leader_skill' in row)
        self.assertGreater(len(sources), 1)
        variants = {sid for source in sources for sid in equipment.get(source, {}).values()}
        self.assertTrue(variants)
        for sid in sources | variants:
            note = dict(self.cfg['skill'][sid]['tipNotes105'])['通缉']
            self.assertIn('穿透比例见小技能', note, sid)

    def test_applying_twice_changes_nothing(self):
        import copy
        from hero_mechanic_terms_105 import apply_hero_mechanic_terms
        again = copy.deepcopy(self.cfg)
        apply_hero_mechanic_terms(again)
        self.assertEqual(again, self.cfg)


if __name__ == '__main__':
    unittest.main()
