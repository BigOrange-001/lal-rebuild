"""Exercise imported damage passives through the client's actual damage hook."""

import json
import subprocess
import unittest

from test_avatar_passive import NODE, ROOT, method_body
from test_summon_panel_103_client import translated


HARNESS = r'''
const methods = JSON.parse(require('node:fs').readFileSync(0, 'utf8'));
const int = value => Number(value) | 0;
const attach = (target, name, params='') => {
    target[name] = eval('(function('+params+'){with(this){'+methods[name]+'}})');
};
function Buff(type, round, value) { Object.assign(this, {type, round, value}); }
const result = {};
for (const [kind, amount] of [['six_reaction_mf_p',.8], ['six_batch_ziggs_p',.6], ['six_batch_tf_p',1.7]]) {
    const owner = {
        avatarData:{id:'A_1900000_6'}, team:1, hp:70, hpMax:100, abilityIndex:3, abilityState:{},
        skillB:{skills:[['manual_ability',kind,0,'FX',amount,0,0]]}, buffs:{},
        currentAbilityAttack(){ return this.activeAttack; },
        beginAbilityAttack(){ return this.activeAttack = {owner:this}; },
        endAbilityAttack(){ this.activeAttack = null; },
        sixFollowupHeal105(unit, heal) {
            const actual = Math.min(heal, unit.hpMax-unit.hp);
            unit.hp += actual;
            this.activeAttack.sixReactionMfOverflow105 = heal-actual;
        },
        queueVitalBar104(){},
        addBuff(name, round, value){ this.buffs[name] = new Buff(name, round, value); }
    };
    const target = {
        team:2, hp:100, abilitySerial:0, abilityState:{}, buffs:{strong:new Buff('strong',2,.3)},
        removeBuff(name){ delete this.buffs[name]; },
        sixNextAfterDamage105(){}
    };
    attach(owner, 'sixStarPassive105');
    attach(owner, 'sixReactionPassive105', 'kind');
    attach(owner, 'sixBatchPassive105', 'kind');
    attach(owner, 'sixReactionMfDealt105', 'target,amount');
    attach(owner, 'sixBatchAfterDamage105', 'target,taken');
    attach(target, 'settle', 'param7,param4,param1,abilityDamageTaken,modActualDamage,statisticsShield104,dotKind=""');
    target.settle(owner, 4, 40, 40, 40, 0);
    if (owner.hp !== 70 || Object.keys(target.abilityState).length)
        throw Error('Damage passives unexpectedly fired from healing');
    for (let hit=0; hit<(kind==='six_batch_tf_p'?4:1); hit++)
        target.settle(owner, 1, 40, 40, 40, 0);
    result[kind] = [owner.hp, owner.buffs.sixReactionMfShield105?.value,
                    target.abilityState.sixBatchZiggsWound105?.value,
                    owner.buffs.strong?.value, !!target.buffs.strong];
}
process.stdout.write(JSON.stringify(result));
'''


@unittest.skipUnless(NODE, 'Node is required to execute the actual ActionScript')
class ImportedPassiveTests(unittest.TestCase):
    def test_imported_passives_trigger_on_damage_with_a_different_avatar_id(self):
        avatar = (ROOT / 'client/src/stages/137_Avatar.as').read_text('utf-8')
        names = ('sixStarPassive105', 'sixReactionPassive105', 'sixBatchPassive105',
                 'sixReactionMfDealt105', 'sixBatchAfterDamage105')
        methods = {name: translated(avatar, name) for name in names}
        injured = method_body(avatar, 'injured')
        anchor = 'param7.sixFollowupAfterHit105(this,catContext,abilityDamageTaken+statisticsShield104);'
        methods['settle'] = injured.split(anchor, 1)[1]
        result = subprocess.run([NODE, '-e', HARNESS], input=json.dumps(methods),
                                capture_output=True, text=True, encoding='utf-8', timeout=15)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), {
            'six_reaction_mf_p': [100, 2, None, None, True],
            'six_batch_ziggs_p': [70, None, .6, None, True],
            'six_batch_tf_p': [70, None, None, .3, False],
        })
