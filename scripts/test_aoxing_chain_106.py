"""Aurelion Sol's chain lightning (every star): the client rule, the offline simulation
and the skill texts agree.

    python scripts/test_aoxing_chain_106.py
"""
from pathlib import Path
import json
import random
import re
import subprocess
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(ROOT / 'scripts'), str(ROOT / 'server')]
from test_vital_bar_104 import method  # noqa: E402

AVATAR = 'client/src/stages/137_Avatar.as'


def js(name):
    code = method(AVATAR, name)
    return re.sub(r'for each\((var )?(\w+) in ', r'for (\1\2 of ', code)


def scenes(count=300, seed=106):
    rng = random.Random(seed)
    out = []
    for n in range(count):
        enemies = []
        for i in range(rng.randint(1, 9)):
            # Positions on a coarse grid so equal distances (the tie-break) really happen.
            enemies.append(dict(index=10 + i, line=rng.randrange(3), pos=rng.randrange(0, 1201, 50),
                                hp=0 if rng.random() < .12 else 100, hero=rng.random() < .7))
        rng.shuffle(enemies)
        out.append(dict(owner=dict(line=rng.randrange(3), pos=rng.randrange(0, 1201, 50)), enemies=enemies))
    return out


SCRIPT = '''
const assert=require('assert');
const fns={next:%s,targets:%s,chain:%s};
const scenes=%s;
function caster(scene){
 const me={line:scene.owner.line,pos:scene.owner.pos,AOXING_CHAIN_MAX106:5,AOXING_CHAIN_SOLO106:3,AOXING_CHAIN_STEP106:.12,
  hits:[],claims:[],waves:[],batches:0,
  abilityAllEnemies(){return this.foes.filter(u=>u.hp>0);},
  abilityHit(target,ratio,kind,effect,shared,from){this.hits.push([target.index,ratio,kind,from===this?'me':from.index]);return target.hp>0;},
  sixStarHit105(target,ratio,kind,effect){this.hits.push([target.index,ratio,kind,'six']);},
  beginParallelVisualBatch(){this.batches++;return {};},setParallelVisualWave(b,i,s){this.waves.push([i,s]);},endParallelVisualBatch(){},
  heroFxClaim106(event,kind,target,extra){this.claims.push([event,kind,target.index,extra.hop,extra.solo]);return true;}};
 me.foes=scene.enemies.map(u=>Object.assign({abilityIndex:u.index,getType(){return this.hero?1:2;},isManualSummonUnit:false},u));
 me.aoxingChainNext106=fns.next;me.aoxingChainTargets106=fns.targets;me.aoxingChain106=fns.chain;
 return me;
}
const orders=[];
for(const scene of scenes){
 const me=caster(scene);
 const order=me.aoxingChainTargets106().map(u=>u.index);
 orders.push(order);
 const alive=scene.enemies.filter(u=>u.hp>0).length;
 assert.equal(order.length,Math.min(5,alive));
 assert.equal(new Set(order).size,order.length,'a target twice');
 // A full chain fires: first ratio (x3 alone), then the bounce ratio, each bolt from the last target.
 const hero=me.aoxingChain106(1.4,1,2,'FX_A_1114_MAGIC',true);
 assert.deepEqual(me.hits.map(h=>h[0]),order);
 me.hits.forEach((h,i)=>{assert.ok(Math.abs(h[1]-(i?1:(order.length==1?1.4*3:1.4)))<1e-9,'ratio '+h[1]);assert.equal(h[3],i?order[i-1]:'me');});
 assert.equal(hero,order.some(i=>scene.enemies.find(u=>u.index==i).hero));
 assert.deepEqual(me.claims.map(c=>[c[0],c[1],c[2],c[3]]),order.map((t,i)=>['chain','1114',t,i]));
 assert.ok(me.claims.every(c=>c[4]===(order.length==1)));
 assert.equal(me.batches,order.length>1?1:0);
 if(order.length>1)assert.deepEqual(me.waves,order.map((t,i)=>[i,.12]));
 // Six stars: the same chain, no manual damage factor.
 const six=caster(scene);six.aoxingChain106(1.375,.625,2,'FX_A_1114_MAGIC',false);
 assert.deepEqual(six.hits.map(h=>[h[0],h[3]]),order.map(t=>[t,'six']));
}
console.log(JSON.stringify(orders));
'''


class AoxingChainTests(unittest.TestCase):
    def client_orders(self, cases):
        script = SCRIPT % (js('aoxingChainNext106'), js('aoxingChainTargets106'), js('aoxingChain106'), json.dumps(cases))
        run = subprocess.run(['node'], input=script, text=True, encoding='utf-8', capture_output=True, cwd=ROOT)
        self.assertEqual(run.returncode, 0, run.stdout[-2000:] + run.stderr)
        return json.loads(run.stdout)

    def server_orders(self, cases):
        from six_star_next_battle_105 import SixStarNextBattle

        class Stub(SixStarNextBattle):
            def __init__(self, units):
                self.units = units

            def opponents(self, owner):
                return [u for u in self.units if u['hp'] > 0]

            def state(self, unit):
                return {'index': unit['index']}

            def hero(self, unit):
                return unit['hero']

        orders = []
        for case in cases:
            units = [dict(u) for u in case['enemies']]
            stub = Stub(units)
            orders.append([u['index'] for u in stub.aoxing_chain_targets(dict(case['owner']))])
            hits = []
            hero = stub.aoxing_chain(case['owner'], 1.4, 1, lambda target, ratio: hits.append((target['index'], ratio)) or True)
            self.assertEqual([h[0] for h in hits], orders[-1])
            self.assertEqual(hero, any(u['hero'] for u in units if u['index'] in orders[-1]))
            if hits:
                self.assertAlmostEqual(hits[0][1], 1.4 * 3 if len(hits) == 1 else 1.4)
                self.assertTrue(all(ratio == 1 for _, ratio in hits[1:]))
        return orders

    def test_client_and_simulation_pick_the_same_chain(self):
        cases = scenes()
        self.assertEqual(self.client_orders(cases), self.server_orders(cases))

    def test_rule_examples(self):
        def foe(index, line, pos, hp=100):
            return dict(index=index, line=line, pos=pos, hp=hp, hero=True)
        cases = [
            # Down his lane first (7, 2, 1), then the nearest lane from the last target (5, then 3 in
            # that lane); at most five, so 4 and 6 are left out.
            dict(owner=dict(line=1, pos=1000), enemies=[foe(1, 1, 300), foe(2, 1, 600), foe(3, 0, 650), foe(4, 2, 610),
                                                         foe(5, 0, 100), foe(6, 2, 50), foe(7, 1, 900)]),
            # Nobody in his lane: the chain starts in the nearest lane, however far.
            dict(owner=dict(line=0, pos=0), enemies=[foe(1, 2, 0), foe(2, 1, 1200)]),
            # A lone enemy, a dead one does not count.
            dict(owner=dict(line=0, pos=0), enemies=[foe(1, 2, 1200), foe(2, 0, 10, hp=0)]),
        ]
        self.assertEqual(self.client_orders(cases), [[7, 2, 1, 5, 3], [2, 1], [1]])
        self.assertEqual(self.server_orders(cases), [[7, 2, 1, 5, 3], [2, 1], [1]])

    def test_cast_gates_need_only_an_enemy_somewhere(self):
        avatar = (ROOT / AVATAR).read_text('utf-8')
        self.assertIn('case "aoxing_n": return abilityAllEnemies().length > 0;', avatar)
        self.assertIn('if(kind=="six_next_aoxing_n") return !abilityState.nextStorm && abilityAllEnemies().length>0;', avatar)
        branch = avatar[avatar.index('            case "aoxing_n":\n               if(!abilityAllEnemies().length) return false;'):]
        self.assertIn('marked=aoxingChain106(', branch[:600])
        self.assertIn('aoxingChain106(Number(action[4]),Number(action[5]),2,String(action[3]),false);', avatar)
        sim = (ROOT / 'server/manual_ability_sim.py').read_text('utf-8')
        self.assertIn("if not self.opponents(owner):return False\n                marked=self.aoxing_chain(", sim.replace('\r\n', '\n'))
        six = (ROOT / 'server/six_star_next_battle_105.py').read_text('utf-8')
        self.assertIn("if state.get('next_storm') or not self.opponents(owner):", six)

    def test_texts_describe_the_new_rule(self):
        from aoxing_chain_106 import rewrite, apply_aoxing_chain_106
        low = ('对本分路的当前目标造成{scale:0.0:129.3421772444}魔法伤害，再依次弹向上一个目标300范围内最近、且本次尚未命中的另一名敌人，'
               '最多弹射两次，每次{scale:0.0:92.3872694603}魔法伤害。本次至少命中一名敌方英雄时，获得一层风暴电荷，最多储存3层。 本分路内不受施法距离限制。')
        new = rewrite(low, 'aoxing_n')
        self.assertIn('{scale:0.0:129.3421772444}', new)
        self.assertIn('{scale:0.0:92.3872694603}', new)
        for phrase in ('最多命中5名敌人', '可跨分路', '3倍伤害', '风暴电荷'):
            self.assertIn(phrase, new)
        self.assertNotIn('本分路内不受施法距离限制', new)
        self.assertEqual(rewrite(new, 'aoxing_n'), new)
        six = ('向当前敌人发射闪电，首个目标{rank:0:4}攻击魔伤，弹射最多2次，每次{rank:0:5}。施放增加1层电荷；已有5层时改为开启持续引导。'
               '引导中不移动、普攻或施放小技能，每次自身行动开始释放3次同样的闪电，受到眩晕、沉默或死亡时中止并清空电荷。')
        new = rewrite(six, 'six_next_aoxing_n')
        for phrase in ('{rank:0:4}', '{rank:0:5}', '最多命中5名', '可跨分路', '3倍伤害', '站定引导，引导中不移动'):
            self.assertIn(phrase, new)
        document = {'cfg': {'skill': {'S': {'info': six, 'skill': [['manual_ability', 'six_next_aoxing_n', 1, 'FX', 1, 1]]},
                                      'T': {'info': six, 'skill': [['damage', 1, 1, 'FX']]}}}}
        apply_aoxing_chain_106(document)
        self.assertIn('最多命中5名', document['cfg']['skill']['S']['info'])
        self.assertEqual(document['cfg']['skill']['T']['info'], six)
        gateway = (ROOT / 'server/gateway.py').read_text('utf-8')
        self.assertLess(gateway.index('apply_native_fx_wiring(document)'), gateway.index('apply_aoxing_chain_106(document)'))
        self.assertLess(gateway.index('apply_aoxing_chain_106(document)'), gateway.index('apply_hero_mechanic_terms(document)'))

    def test_shipped_config_carries_the_texts(self):
        import prepared_config
        prepared = prepared_config.read_prepared(prepared_config.SOURCE)
        self.assertIsNotNone(prepared, 'prepared-config.bin is stale: run python server/prepared_config.py')
        skills = prepared['document']['cfg']['skill']
        rows = [row for row in skills.values() if isinstance(row, dict) and any(
            isinstance(a, list) and len(a) > 1 and a[1] in ('aoxing_n', 'six_next_aoxing_n') for a in row.get('skill') or ())]
        self.assertGreaterEqual(len(rows), 3)
        for row in rows:
            self.assertIn('可跨分路', row['info'])
            self.assertNotIn('最多弹射两次', row['info'])
            self.assertNotIn('弹射最多2次', row['info'])


if __name__ == '__main__':
    unittest.main()
