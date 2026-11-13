import copy
import unittest
import json
import subprocess
from unittest.mock import patch
from pathlib import Path

from gateway import load_game_config
from bonds_104 import profile_bonds
from gameplay_roster import GameplayRosterEquipment
from battle_engine import base_unit
from manual_ability_sim import SkillCompleteBattle
from new_skin_bonds_104 import apply_new_skin_bonds_104, mechanic_value
import test_stat_power_103 as stat_tests

ROOT = Path(__file__).resolve().parents[1]
KAISA = 'A_1801_6'
YASUO = 'A_1802_6'
PARTNERS = ['A_1219_6', 'A_1210_6', 'A_1206_6']


class NewSkinBondsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.doc = load_game_config(ROOT/'config/reconstruction/full-config.json')
        cls.cfg = cls.doc['cfg']

    def profile(self, heroes=None, equipment=False):
        heroes = heroes or [YASUO, KAISA, *PARTNERS]
        ids = [aid+'|bond-test' for aid in heroes]
        p = {'avatars':{iid:{'aid':aid,'lv':99,'slv':10,'phase':0} for iid,aid in zip(ids,heroes)},
             'team':[ids+[None]*(6-len(ids))], 'attrs':{'team_num':0,'dn':{}},
             'my_equips':{}, 'as_equips':[[] for _ in range(6)]}
        if equipment:
            for slot, aid in enumerate(heroes):
                for row in self.cfg['system_simple']['equipment_bonds_104'].get(aid,[]):
                    if row['kind']!='stats':
                        continue
                    eid = row['equipment'];key=str(slot)+eid
                    p['my_equips'][key]={'eid':eid,'lv':1,'stat_roll_ppm':1000000}
                    p['as_equips'][slot].append(key)
        return p, ids

    def test_membership_and_snapshots_do_not_activate_from_inventory_or_duplicates(self):
        p,ids=self.profile()
        active = profile_bonds(self.cfg,p,ids[0])
        self.assertEqual({b['id'] for b in active},{'dragon_night_104','otherworld_swords_104'})
        p['team'][0][1]=None
        self.assertNotIn('dragon_night_104',{b['id'] for b in profile_bonds(self.cfg,p,ids[0])})
        p['team'][0][2]=ids[0]
        self.assertFalse(profile_bonds(self.cfg,p,ids[0]))
        p['team'][0][1]=ids[1]
        raw=GameplayRosterEquipment(None,self.doc).battle_attributes(p,ids[0])
        self.assertEqual(raw['bonds_104'],['dragon_night_104'])
        self.assertEqual(mechanic_value(self.cfg,raw,'yasuo_crit_true',.35),.5)
        self.assertEqual(mechanic_value(self.cfg,dict(raw,bonds_104=[]),'yasuo_crit_true',.35),.35)
        self.assertFalse(profile_bonds(self.cfg,p,ids[0],hero_only=True))

    def test_both_new_skin_stat_affinities_apply_once_and_never_change_skills(self):
        p,ids=self.profile(equipment=True)
        neutral=copy.deepcopy(self.doc)
        for aid in (KAISA,YASUO):
            neutral['cfg']['system_simple']['equipment_bonds_104'][aid]=[]
        for aid,iid in zip([YASUO,KAISA],ids[:2]):
            with_affinity=GameplayRosterEquipment(None,self.doc).battle_attributes(p,iid)
            without=GameplayRosterEquipment(None,neutral).battle_attributes(p,iid)
            self.assertEqual(with_affinity['ap'],int(round(without['ap']*1.2,5)))
            self.assertEqual(with_affinity['hp_max'],int(round(without['hp_max']*1.2,5)))
            for field in ('skill','leader_skill','skillB'):
                self.assertEqual(with_affinity[field],without[field])
            # The slots belong to the wearer; an unassigned new skin has no gear bonus.
            for slot in range(len(p['as_equips'])):
                p['as_equips'][slot]=list(dict.fromkeys(p['as_equips'][slot]))
            self.assertEqual(len(with_affinity['equipment_bonds_104']),2)

    def test_stat_only_hero_bonds_and_idempotent_config(self):
        p,ids=self.profile()
        neutral=copy.deepcopy(self.doc)
        neutral['cfg']['system_simple']['bonds_104']=[b for b in neutral['cfg']['system_simple']['bonds_104']
                if b['id'] not in ('otherworld_swords_104','dragon_heart_hunters_104')]
        for aid,iid in zip([YASUO,KAISA,*PARTNERS],ids):
            extra=GameplayRosterEquipment(None,self.doc).battle_attributes(p,iid)
            base=GameplayRosterEquipment(None,neutral).battle_attributes(p,iid)
            rate=.14 if aid in (KAISA,'A_1206_6') else .2 if aid in PARTNERS[:2] else 0
            self.assertEqual(extra['ap'],int(round(base['ap']*(1+rate),5)))
            self.assertEqual(extra['hp_max'],int(round(base['hp_max']*(1+rate),5)))
        current=copy.deepcopy(self.doc)
        apply_new_skin_bonds_104(current)
        self.assertEqual(current,self.doc)
        before={'cfg':{'system_simple':{}}}
        self.assertIs(apply_new_skin_bonds_104(before),before)
        self.assertEqual(before,{'cfg':{'system_simple':{}}})

    def battle(self, aid, bonds):
        cfg=copy.deepcopy(self.cfg);cfg['combat_rules']={}
        attack=cfg['system_simple']['attack'];attack[2]=1;attack[4]=attack[15]=attack[16]=0
        attack[3]=2;attack[5]=0;attack[21]=1
        o=base_unit(cfg,aid,1,1,leader=True);e=base_unit(cfg,'A_1001_6',1,1,team=2)
        for unit in (o,e):
            unit.update(hp=100000,hp_max=100000,ap=100,de_ph=0,de_ma=0)
            unit['new_4attrs']={'hit':1000000,'flee':0,'crit':0,'tough':0}
        o.update(pos=2400,bonds_104=bonds);e['pos']=1400
        b=SkillCompleteBattle([o],[e],config=cfg,trace_abilities=True)
        return b,b.a[0],b.b[0]

    def test_kaisa_q_sunder_is_33_percent_and_clone_uses_root_snapshot(self):
        for enabled in (False,True):
            b,o,e=self.battle(KAISA,['dragon_night_104'] if enabled else [])
            e['de_ph']=e['de_ma']=100
            b.execute_kaisa(o,'dragon_kaisa_n',o['skill'])
            self.assertEqual(bool(b._buff(e,'sunder')),enabled)
            if enabled:
                self.assertEqual(b._get_de_ph(e),67)
                self.assertEqual(b._get_de_ma(e),67)
                self.assertEqual(b._buff(e,'sunder').round,1)
                clone=base_unit(b._config,KAISA,1,1)
                clone.update(_kaisa_root=o,leader=False,hp=100000,pos=2400)
                b.a.append(clone);b.state(clone)
                b._remove_buff(e,'sunder')
                b.execute_kaisa(clone,'dragon_kaisa_n',clone['skill'])
                self.assertIsNotNone(b._buff(e,'sunder'))

    def test_yasuo_derived_damage_and_silence_exception_require_own_bond(self):
        for enabled,expected in ((False,35),(True,50)):
            b,o,e=self.battle(YASUO,['dragon_night_104'] if enabled else [])
            b.yasuo_critical(o,e,100)
            self.assertEqual(100000-e['hp'],expected)
        for enabled in (False,True):
            b,o,e=self.battle(YASUO,['otherworld_swords_104'] if enabled else [])
            b._add_buff(o,'silence',3);o['_skill_cd_leader']=-1
            self.assertEqual(b._use_skill_slot(o,[e],'leader_skill','_skill_cd_leader'),enabled)
            if enabled:
                self.assertIsNone(b._buff(o,'silence'))
                self.assertEqual(o['_skill_cd_leader'],4)
            else:
                self.assertIsNotNone(b._buff(o,'silence'))

    def test_captain_bonus_is_112_percent_only_for_captain_and_displays_12_percent(self):
        b,o,e=self.battle(YASUO,['otherworld_swords_104'])
        coefficients=[]
        with patch.object(b,'yasuo_hit',side_effect=lambda owner,target,coefficient,skill: coefficients.append(coefficient)):
            b.execute_yasuo(o,'night_yasuo_c',o['leader_skill'])
        for actual,base in zip(coefficients,[1.75,1.75,4.44]):
            self.assertAlmostEqual(actual,base*1.12)
        self.assertEqual(len(coefficients),3)
        b,o,e=self.battle(YASUO,['otherworld_swords_104'])
        b.execute_yasuo(o,'night_yasuo_n',o['skill'])
        self.assertEqual(100000-e['hp'],225)
        bond=next(r for r in self.cfg['system_simple']['bonds_104'] if r['id']=='otherworld_swords_104')
        self.assertIn('伤害提升12%',bond['benefits']['A_1802']['info'])
        self.assertIn('伤害提升12%',self.cfg['skill']['S_98618021_6']['info'])


class NewSkinNativeStatsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.harness=stat_tests.StatPower103Tests()
        stat_tests.StatPower103Tests.setUpClass()

    def test_native_panel_cached_battle_and_server_match_for_new_hero_and_gear_bonds(self):
        cfg=self.harness.document['cfg']
        builder=NewSkinBondsTests();builder.cfg=cfg
        for heroes in ([YASUO,KAISA,*PARTNERS],[YASUO,KAISA],[KAISA,'A_1206_6']):
            p,_=builder.profile(heroes,equipment=True)
            self.harness.compare(p)

    def test_native_bond_numbers_use_active_snapshot_and_owner_identity(self):
        definition=stat_tests.methods('137_Avatar.as',{'skinBondNumber104':'key,fallback=0'})['skinBondNumber104']
        rows=[b for b in self.harness.document['cfg']['system_simple']['bonds_104']
              if b['id'] in ('dragon_night_104','otherworld_swords_104')]
        script='const assert=require("assert");const rows='+json.dumps(rows)+';'
        script+='const effect=function('+definition[0]+'){with(this){'+definition[1]+'}};'
        script+='''
const owner={avatarData:{id:'A_1802_6'},getBondRows104:()=>[],effect};
assert.equal(owner.effect('yasuo_crit_true',.35),.35);
owner.getBondRows104=()=>rows;assert.equal(owner.effect('yasuo_crit_true',.35),.5);
assert.equal(owner.effect('yasuo_c_silenced'),1);assert.equal(owner.effect('kaisa_q_sunder'),0);
assert.equal(owner.effect('yasuo_c_damage',1),1.12);
owner.avatarData.id='A_1801_6';assert.equal(owner.effect('kaisa_q_sunder'),.33);
assert.equal(owner.effect('yasuo_crit_true',.35),.35);
owner.getBondRows104=()=>[];assert.equal(owner.effect('kaisa_q_sunder'),0);
'''
        run=subprocess.run(['node'],input=script,text=True,encoding='utf8',capture_output=True)
        self.assertEqual(run.returncode,0,run.stdout+run.stderr)
