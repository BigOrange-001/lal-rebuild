"""Focused regressions for PR 17 native-template review findings."""
import copy
from pathlib import Path
import sys
import unittest

ROOT=Path(__file__).resolve().parents[1]
sys.path[:0]=[str(ROOT),str(ROOT/'server')]
from scripts.mod_tools import load_base
from mod_schema import ModError
from mod_native import make_template,validate_template,reorder_actions,remove_action


class NativeReviewTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.base=load_base(ROOT/'config/reconstruction/full-config.json')

    def template(self,sid):
        return make_template(sid,self.base['cfg']['skill'][sid],self.base)

    def test_reorders_removals_and_forward_references_are_atomic(self):
        for sid,kind,order,raw_pos in [
            ('S_621021_5','battle_stack',[1,0,2],4),
            ('S_621019_5','heal_missing_hp_per_hero',[0,2,1,3,4],3),
        ]:
            with self.subTest(kind=kind):
                skill=self.template(sid)
                target=next(a['arguments'][raw_pos-1] for a in skill['actions'] if a['type']==kind)
                reorder_actions(skill,order)
                linked=next(a['arguments'][raw_pos-1] for a in skill['actions'] if a['type']==kind)
                self.assertEqual(linked,order.index(target))
                self.assertEqual(skill['actions'][linked]['type'],'damage')
                validate_template(skill,self.base)
                before=copy.deepcopy(skill)
                with self.assertRaises(ModError):remove_action(skill,linked)
                self.assertEqual(skill,before)
                dependent=next(i for i,a in enumerate(skill['actions']) if a['type']==kind)
                bad_order=list(range(len(skill['actions'])))
                bad_order[linked],bad_order[dependent]=bad_order[dependent],bad_order[linked]
                with self.assertRaises(ModError):reorder_actions(skill,bad_order)
                self.assertEqual(skill,before)

    def test_modulo_bounds_and_pre_review_contract_compatibility(self):
        sid=next(sid for sid,row in self.base['cfg']['skill'].items()
                 if any(a[:2]==['manual_ability','riven_n'] for a in row.get('skill',[])))
        skill=self.template(sid)
        for contract in [skill['nativeTemplate']['abilityContract'],
                         'e51a0c4280e7a861b0c8397e8c8877061c5396bda525a7c144823ee244d09f46']:
            for key in ('cast_3','cast_5'):
                for value in (0,-1,0.5,True):
                    with self.subTest(contract=contract,key=key,value=value):
                        changed=copy.deepcopy(skill)
                        changed['nativeTemplate']['abilityContract']=contract
                        changed['nativeTemplate']['abilityParameters']['riven_n'][key]=value
                        with self.assertRaises(ModError):validate_template(changed,self.base)
                changed=copy.deepcopy(skill)
                changed['nativeTemplate']['abilityContract']=contract
                changed['nativeTemplate']['abilityParameters']['riven_n'][key]=1
                validate_template(changed,self.base)
        skill['nativeTemplate']['abilityContract']='0'*64
        with self.assertRaises(ModError):validate_template(skill,self.base)

    def test_new_duration_actions_reject_invalid_rounds_and_accept_boundaries(self):
        for kind,position in (('caster_ap_shield',1),('book_burn',1),('book_bonus',2),('timed_bless',0)):
            sid=next(sid for sid,row in self.base['cfg']['skill'].items()
                     if any(action[0]==kind for action in row.get('skill',[])))
            template=self.template(sid)
            for rounds in (-999,0,101,1.5,True):
                with self.subTest(kind=kind,rounds=rounds):
                    changed=copy.deepcopy(template)
                    next(a for a in changed['actions'] if a['type']==kind)['arguments'][position]=rounds
                    with self.assertRaises(ModError):validate_template(changed,self.base)
            for rounds in (1,100):
                with self.subTest(kind=kind,rounds=rounds):
                    changed=copy.deepcopy(template)
                    next(a for a in changed['actions'] if a['type']==kind)['arguments'][position]=rounds
                    validate_template(changed,self.base)


if __name__=='__main__':unittest.main()
