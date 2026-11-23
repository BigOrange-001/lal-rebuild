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

    def skill_text(self, hero):
        return ''.join(str(self.cfg['skill'][sid].get('info', '')) for sid in hero['pl'][10:14]
                       if sid and sid in self.cfg['skill'])

    def test_every_listed_mechanic_reaches_an_avatar_that_uses_it(self):
        found = {}
        for aid, hero in self.cfg['avatar'].items():
            terms = hero.get('tipTerms105') or {}
            text = self.skill_text(hero)
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

    def test_applying_twice_changes_nothing(self):
        import copy
        from hero_mechanic_terms_105 import apply_hero_mechanic_terms
        again = copy.deepcopy(self.cfg)
        apply_hero_mechanic_terms(again)
        self.assertEqual(again, self.cfg)


if __name__ == '__main__':
    unittest.main()
