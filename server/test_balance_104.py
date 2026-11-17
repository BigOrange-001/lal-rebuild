"""Boundary and native arithmetic checks for the 1.0.4 migration."""
import copy
from collections import Counter
import unittest

from test_stat_power_103 import StatPower103Tests
from bonds_104 import active_bonds, profile_bonds, apply_bonds_104
from power_balance_104 import apply_power_balance_104, recommendation_blend, talent_power_factor
from resource_drops_104 import apply_resource_drops_104
from arena_opponents import opponent_ranks
from gameplay_roster import GameplayRosterEquipment
from battle_engine import base_unit


class Balance104Tests(StatPower103Tests):
    def test_generated_native_action_links_and_parallel_arrays(self):
        from mod_native import make_template, _validate_links
        cfg = self.document['cfg']
        checked = 0
        for sid, row in cfg['skill'].items():
            if not (row.get('bond_power_rate_104') or row.get('builtin_pack_104')) or row.get('modEffectSequence'):
                continue
            with self.subTest(skill=sid):
                _validate_links(make_template(sid, row, self.document), sid)
                for key in ('manualClonePolicy', 'manualSummonPolicy'):
                    if row.get(key):
                        self.assertEqual(row[key]['skillId'], sid)
            checked += 1
        self.assertGreater(checked, 100)

    def lineup(self, aids, level=60):
        ids = [aid+'|'+str(i) for i, aid in enumerate(aids)]
        return {'avatars': {iid: {'aid': aid, 'lv':level, 'slv':7, 'phase':0} for iid,aid in zip(ids,aids)},
                'team':[ids], 'as_equips':[[] for _ in ids], 'my_equips':{}, 'attrs':{'team_num':0,'dn':{}}}

    def test_native_bonds_panel_skill_and_initialization(self):
        groups = [(['A_1009_5','A_1001_5','A_1007_5']),
                  ['A_1025_5','A_1021_4','A_1041_5'],
                  ['A_1030_5','A_1011_5','A_1053_5','A_1096_5'],
                  ['A_1082_6','A_1083_6','A_1045_6','A_1108_6','A_1123_6'],
                  ['A_1206_5','A_1129_5','A_1208_5']]
        for aids in groups:
            with self.subTest(aids=aids):
                self.compare(self.lineup(aids))

    def test_native_rework_target_policies(self):
        import json,re,subprocess
        from test_avatar_passive import method_body,ROOT
        from test_curse_combat import CurseClientCombatTests
        source=(ROOT/'client/src/stages/139_SkillSet.as').read_text('utf-8')
        source=re.sub(r'\)\s*:\s*Vector\.<\w+>',') : Object',source)
        definitions={}
        for name,params in [('getActionPolicy','param1,param2=null'),('getActionPolicyArgs','param1'),
                            ('getActionCenter','param1'),('hasActionCenter','param1'),
                            ('hasDistinctActionTarget','param1,param2,param3'),('isForwardOf','param1,param2'),
                            ('applyActionTargetPolicy','param1,param2,param3=null')]:
            definitions[name]=[params,CurseClientCombatTests.translate(method_body(source,name))]
        cfg=self.document['cfg']
        bond=next(b for b in cfg['system_simple']['bonds_104'] if b.get('focus')=='A_1030' and len(b['families'])==4)
        sid=cfg['system_simple']['bond_skill_variants_104']['A_1030_6'][bond['id']]['skill']
        script=r"""
const input=JSON.parse(require('fs').readFileSync(0,'utf8')),int=Math.trunc;
const Tools={clone:v=>JSON.parse(JSON.stringify(v)),sortVector:(v,f)=>v.slice().sort(f)},Avatar={skillAreaRadius:v=>v};
function actor(id,team,line,pos){return {id,team,line,pos,hp:100,hpMax:100,getType:()=>1,getEffectiveActionType:()=>1};}
const caster=actor('caster',1,0,500);caster.otherTeam=2;caster.getSortOnFun=()=>()=>0;caster.isRangedSkillCaster=()=>true;
const front=actor('front',2,0,700),rear=actor('rear',2,0,900),cross=actor('cross',2,1,900);
const unit={getActionSortFunction:()=>()=>0,avatar:caster,skillSetData:input.skill,currentActionTargets:[front],currentTargetGroups:{},sortAnchor:null,preparingCast:false};
for(const [name,[params,body]] of Object.entries(input.methods))unit[name]=eval('(function('+params+'){with(this){'+body+'}})');
let out=[unit.applyActionTargetPolicy([front,rear,cross],1).map(x=>x.id)];
unit.skillSetData={actionTargetPolicies:['enemy_global_lowest_hp_ratio_hero']};
out.push(unit.applyActionTargetPolicy([front,rear,cross],0).map(x=>x.id));
unit.skillSetData={actionTargetPolicies:['ally_self']};
out.push(unit.applyActionTargetPolicy([caster,actor('ally',1,1,900)],0).map(x=>x.id));
console.log(JSON.stringify(out));
"""
        run=subprocess.run(['node','-e',script],input=json.dumps({'skill':cfg['skill'][sid],'methods':definitions}),text=True,capture_output=True,encoding='utf-8')
        self.assertEqual(run.returncode,0,run.stderr)
        self.assertEqual(json.loads(run.stdout),[['rear'],['front','rear','cross'],['caster']])

    def test_preview_lineup_does_not_use_current_team(self):
        p=self.lineup(['A_1009_5','A_1001_5','A_1007_5'])
        expected=self.native(p,self.document['cfg'])
        p['team'].append([p['team'][0][0]])
        p['attrs']['team_num']=1
        self.assertEqual(self.native(p,self.document['cfg']),expected)

    def test_only_all_stat_dn_nodes_count_and_not_dn_recipients(self):
        p = self.lineup(['A_1009_5','A_1001_5','A_1007_5'])
        ids = list(p['avatars'])
        p['team'][0] = [ids[0]]
        p['attrs']['dn'] = {'1':[1,ids[1],[]], '10':[1,ids[2],[]]}
        cfg = self.document['cfg']
        self.assertTrue(profile_bonds(cfg,p,ids[0]))
        self.assertFalse(profile_bonds(cfg,p,ids[1]))
        self.compare(p)
        p['attrs']['dn']['2'] = p['attrs']['dn'].pop('10')
        self.assertFalse(profile_bonds(cfg,p,ids[0]))
        self.compare(p)

    def test_quality_and_skin_boundaries(self):
        cfg = self.document['cfg']
        self.assertTrue(active_bonds(cfg,'A_1021_4',['A_1025_5','A_1021_4','A_1041_5']))
        self.assertFalse(active_bonds(cfg,'A_1009_5',['A_1009_5','A_1001_4','A_1007_5']))
        self.assertFalse(active_bonds(cfg,'A_1009_5',['A_1009_5','A_1201_5','A_1007_5']))
        self.assertFalse(active_bonds(cfg,'A_1025_6',['A_1025_6','A_1021_5','A_1041_6']))
        self.assertFalse(active_bonds(cfg,'A_1009_5',['A_1009_5']*3))

    def test_large_bond_has_no_free_nested_bonds_even_through_dn(self):
        cfg=self.document['cfg']
        for bond in cfg['system_simple']['bonds_104']:
            if len(bond['families'])<4:
                continue
            aids=[f+'_5' for f in bond['families']]
            for aid in aids:
                self.assertEqual([b['id'] for b in active_bonds(cfg,aid,aids)],[bond['id']],bond['name'])
        # Four-member trial: three active heroes and one all-stat DN member.
        bond=next(b for b in cfg['system_simple']['bonds_104'] if len(b['families'])==4)
        p=self.lineup([f+'_5' for f in bond['families']])
        support=p['team'][0].pop()
        p['attrs']['dn']={'1':[1,support,[]]}
        for iid in p['team'][0]:
            self.assertEqual([b['id'] for b in profile_bonds(cfg,p,iid)],[bond['id']])

    def test_assist_snapshot_keeps_bonds_and_no_stat_double_application(self):
        p=self.lineup(['A_1009_5','A_1001_5','A_1007_5'])
        raw=GameplayRosterEquipment(None,self.document).battle_attributes(p,p['team'][0][0])
        unit=base_unit(self.document['cfg'],raw['aid'],level=raw['lv'],slv=raw['slv'],leader=True,overrides=raw)
        self.assertEqual(unit['bonds_104'],raw['bonds_104'])
        self.assertEqual(unit['hp_max'],raw['hp_max'])
        self.assertEqual(unit['skill'],raw['skill'])

    def test_recommendation_bounds_and_overlay_idempotence(self):
        self.assertEqual(recommendation_blend(10,11,26),1)
        self.assertLess(recommendation_blend(11,11,26),1)
        self.assertGreater(recommendation_blend(25,11,26),0)
        self.assertEqual(recommendation_blend(26,11,26),0)
        self.assertEqual(recommendation_blend(79,80,151),1)
        self.assertLess(recommendation_blend(80,80,151),1)
        self.assertEqual(recommendation_blend(151,80,151),0)
        doc=copy.deepcopy(self.document)
        apply_power_balance_104(doc);apply_resource_drops_104(doc);apply_bonds_104(doc)
        self.assertEqual(doc,self.document)

    def test_higher_resource_tier_never_loses_lower_colors(self):
        cfg=self.document['cfg']
        for chapter,key in [('P_103','dust'),('P_107','sp')]:
            prior=[]
            for tier in range(1,6):
                amounts=cfg['combat_ploy'][f'{chapter}_{tier}']['reward']['attrs'][key]
                self.assertTrue(all(a>=b for a,b in zip(amounts,prior)))
                prior=amounts
        items=cfg['combat_ploy']['P_105_4']['reward']['items']
        self.assertEqual(len(items),4)

    def test_rank_and_effect_based_talent(self):
        for rank in (101,150,100000):
            self.assertEqual(opponent_ranks(rank),list(range(91,101)))
        self.assertNotIn(100,opponent_ranks(100))
        for effect in ('hp','attack','defense','team_crit','team_hit','team_tough','team_flee'):
            self.assertEqual(talent_power_factor({'growth_effect':effect,'growth_value':60}),0)


if __name__=='__main__':
    unittest.main()
