"""Run the actual client stat getters and wave attack with presentation stubs.

This verifies combat values and scheduling; it does not emulate Flash rendering.
"""
import json
import re
import subprocess
import sys
import unittest

from test_avatar_passive import NODE, ROOT, method_body

sys.path.insert(0, str(ROOT / 'server'))
from upstream_skill_priority import apply_upstream_skill_priority


HARNESS = r'''
const fs = require('node:fs');
const vm = require('node:vm');
const input = JSON.parse(fs.readFileSync(0, 'utf8'));
const noop = () => {};
const hits = [], scheduled = [], tweens = [], visuals = [];
const map = {getAliveList() { return []; }, getShowLine(line) { return input.reverse ? 2-line : line; }};
const GameMap = {currentMap: map, actionDelay: 1};
function Sprite() { this.children = []; this.scaleY = 1; this.alpha = 1; }
Sprite.prototype.addChild = function(child) { this.children.push(child); return child; };
Sprite.prototype.removeFromParent = noop;
function Quad(width, height, color) { Sprite.call(this); Object.assign(this, {width, height, color}); }
function Tween(target, duration, transition='linear') {
  if (!['linear','easeIn','easeOut','easeInOut','easeOutIn','easeInBack','easeOutBack',
        'easeInOutBack','easeOutInBack','easeInElastic','easeOutElastic',
        'easeInOutElastic','easeOutInElastic','easeInBounce','easeOutBounce',
        'easeInOutBounce','easeOutInBounce'].includes(transition))
    throw Error('Unsupported Starling transition: '+transition);
  Object.assign(this, {target, duration, values: {}});
}
Tween.prototype.animate = function(key, value) { this.values[key] = value; };
Tween.prototype.fadeTo = function(value) { this.values.alpha = value; };
Tween.prototype.moveTo = function(x,y) { this.values.x=x; this.values.y=y; };
function Point(x=0,y=0) { this.x=x; this.y=y; }
function Rectangle(x,y,width,height){Object.assign(this,{x,y,width,height});}
function DragonBonesSprite(attrs){Sprite.call(this);Object.assign(this,{attrs,width:216,height:216,stopped:false,advanced:[]});
 this.armature={advanceTime:(v)=>this.advanced.push(v)};this.stop=()=>{this.stopped=true;};}
DragonBonesSprite.prototype=Object.create(Sprite.prototype);
const lineSprite={localToGlobal(p){return new Point(p.x+300,p.y+15);}};
const rendered={parent:{},x:37,y:476,pivotX:0,pivotY:0,
  localToGlobal(p){return new Point(p.x+337,p.y+491);}};
const layer = {
  effectLayer: {addChild(child) { visuals.push(child); },globalToLocal(p){return new Point(p.x-10,p.y-20);}},
  getLineSpr(){return lineSprite;},
  delayCall(fn, delay, ...args) { scheduled.push({delay, args}); },
  addTween(tween) { tweens.push(tween); }
};
const context = vm.createContext({
  GameMap, GameMapLayer: {gl: layer},
  GameMapConfig: {LINE_POS: 3000, MIN_SPACE_POS: 300, lineOffset: 1200,
    lineToPixel(line, offset) { return 100 + line*200 + offset/6; },
    posToPixel(pos) { return 140 + pos*680/3000; }, offsetToPixel(offset) { return offset/6; }},
  Tools: {toInt: Math.trunc, clone(v) { return v && {...v}; }},
  DisplayTools: {getAttrs() { return input.effect; },
    newDisplayObject(attrs){return new DragonBonesSprite(attrs);},
    addBullet() { throw Error('Lane wave must not emit per-target projectiles'); }},
  AvatarData: {isAttack() { return true; }, canMiss() { return true; }},
  GlobalData: {$modRuntime:{}}, Sprite, Quad, Tween, trace: noop, int: Math.trunc,
  Math, Number, isFinite, Point, Rectangle, DragonBonesSprite
});
function install(target, name, params) {
  target[name] = vm.runInContext('(function(' + params + ') { with (this) {' + input.methods[name] + '\n} })', context);
}
install(context.GlobalData,'baseModHeroId','id');
install(context.GlobalData,'modDefinitionId','id,scope');
if (input.mode === 'summon') {
  const fields = ['hpMax','hp','ap','dePh','deMa','hit','flee','crit','tough',
    'lv','slv','phase','limitBreak','hpP','apP','dePhP','deMaP','exp','loveExp','morph'];
  function Avatar(aid, data) {
    const row = input.rows[aid], pl = row.pl;
    Object.assign(this, {id: aid, avatarData: {id: aid, hp0:pl[0], hp1:pl[1], ap0:pl[2], ap1:pl[3],
      d10:pl[4], d11:pl[5], d20:pl[6], d21:pl[7], speed:pl[8], range:pl[9]},
      mData: null, m_avatarRes: null, equips: [], buffs: {}, skill0:null, skill1:null, skill2:null,
      skillB:null, talent:null, mDestiny:null, mDNdata:null, abilityEntryAttack:0,
      abilityState:{}, abilitySerial:0, abilityIndex:0, team:0, isLeader:false, pos:0, offset:0, line:0,
      actionNum:0, index:0, manualAttackRangeOverride:NaN, cultureSchema:'', isNPC:false,
      getManualBattleStack() { return 0; }, getManualTimedStack() { return 0; },
      getPhaseLv() { return 0; }, getStar() { return Number(aid.split('_').at(-1)); },
      getCultivationGainFromSlope() { return 0; }, getSymp() { return [0,0,0,0]; },
      applyOwnedGuildResearch(key, value) { return value; },
      initHalo:noop, initSkills:noop, ready:noop, initbuffs() { this.buffs = {}; },
      addBuff(key, rounds) { this.buffs[key] = {rounds}; }});
    for (const key of fields) {
      let value=0;
      Object.defineProperty(this,key,{enumerable:true,get(){return value;},set(v){value=Math.trunc(Number(v))||0;}});
    }
    for (const name of ['getHpMax','getDamage','getDePh','getDeMa'])
      install(this,name,'param1=-1,param2=-1,param3=false');
    for (const name of ['getHit','getFlee','getCrit','getTough','initFightAttr']) install(this,name,'');
    install(this,'ownGrowthValue','effect');
    install(this,'inheritSummonPanel','owner,apRatio,hpRatio=-1,dePhRatio=-1,deMaRatio=-1,secondaryRatio=-1');
    install(this,'scaledSummonStat','value,ratio,minimum');
    this.isValidSummonMultiplier=ratio=>Avatar.isValidSummonMultiplier(ratio);
    install(this,'teamTalentFlat','effect');
    install(this,'getBookCombatBonus','stat');
    for (const name of ['getSpeed','getRange']) install(this,name,'param1=false');
    install(this,'init','param1');
    install(this,'goFight','param1,param2,param3,param4=true');
    this.init(data);
  }
  context.Avatar=Avatar;
  Avatar.isValidSummonMultiplier = vm.runInContext(
    '(function(ratio) {' + input.methods.isValidSummonMultiplier + '\n})', context);
  context.GameMapTools={gameTrace:noop};
  context.abilityNextIndex=0;
  context.int=v=>Math.trunc(Number(v))||0;
  context.GameMapConfig.SUMMON_POS=200;
  const owner = {lv:input.level, hpMax:1000, hp:25, ap:300, dePh:70, deMa:80,
    team:input.team, line:1, pos:1500, hit:11, flee:12, crit:13, tough:14,
    getManualBattleStack() {return 0;},
    teamTalentFlat() {return 0;},
    getHpMax(){return this.hpMax;},getDamage(){return this.ap;},
    getDePh(){return this.dePh;},getDeMa(){return this.deMa;},checkTalent(){return 0;},
    buffs:input.buffed ? {hitup:{value:5},fleeup:{value:6},critup:{value:7},toughup:{value:8}} : {}};
  for (const name of ['getHit','getFlee','getCrit','getTough']) install(owner,name,'');
  install(owner,'getSummonPanelSnapshot','');
  const skill = {avatar:owner, skillSetData:{id:input.skillId}, boundedSummons:[],activeNativeSettings:null,activeNativeSource:null,
    captainSummonMultiplier:input.captainSummonMultiplier,
    hasBoundedSummonPolicy(){return true;}};
  install(skill,'getNativeSetting','key,fallback=null');
  install(skill,'getMechanismId','');
  install(skill,'getSummonCombatSnapshotApFactor','');
  install(skill,'summonAction','_loc20_,_loc14_=0,actionTargets=null,targetGroups=null');
  context._loc16_=layer;
  const added=[];
  context._loc26_={addAvatar(unit,team,line,pos) {unit.pos=pos; added.push(unit);}};
  // Run the actual summon branch, including new Avatar -> init -> goFight -> initFightAttr.
  skill.summonAction(input.action);
  const summoned=added[0];
  if (!summoned) throw Error('No summon reached the map');
  const panel=new Avatar(input.action[2],{lv:input.level,slv:1});
  function stats(unit) {
    return [unit.getHpMax(-1,-1,true),unit.getDamage(-1,-1,true),
      unit.getDePh(-1,-1,true),unit.getDeMa(-1,-1,true)];
  }
  process.stdout.write(JSON.stringify({panel:stats(panel),combat:stats(summoned),
    hp:summoned.hp,level:summoned.lv,secondary:[summoned.getHit(),summoned.getFlee(),
      summoned.getCrit(),summoned.getTough()],bounded:skill.boundedSummons.length}));
} else if (input.mode === 'wave') {
  const targets = input.positions.map((pos, index) => ({pos, line: 1, offset: 0,
    getTeamHp: noop, injured(damage) {
      hits.push({index, delay: GameMap.actionDelay, damage});
      // Reactions must not shift the next enemy's wave impact.
      if (index === 0) GameMap.actionDelay += .4;
      return damage;
    }}));
  const caster = {line: 1, pos: 1500, offset: 0, team: 1, otherTeam: 2,
    currentAbilityAttack() { return {kind: 'active'}; }, purpleBondMultiplier() { return 1; },
    queueRangePreview:noop,
    getTeamHp: noop, checkTalent() { return 0; }, getDamage() { return 100; },
    fightRes: {parent: null}, avatarData: {}, skillB: null, attackTween: noop,
    showLaneShockwave: noop, checkMiss(a, b) { return input.missIndex === targets.indexOf(b); },
    countDamage(a, b, base) { return [base, false]; }, checkCrit() { return 1; }};
  install(caster, 'attackAimList', 'param1,param2=-1,param3=1,param4=0,param5=null,param6=false,param7=null,param8=-1,param9=1,effectSource=null');
  let total = 0;
  for (let segment=0; segment<(input.segments || 1); segment++) {
    total += caster.attackAimList(targets, 1, input.coefficient || 3, targets.length-1,
      'FX_STEEL_LANE_WAVE');
  }
  process.stdout.write(JSON.stringify({total,hits,scheduled:scheduled.map(p=>({delay:p.delay,args:p.args.map(a=>a===caster?'caster':a)})),endDelay:GameMap.actionDelay}));
} else {
  const host = {};
  install(host, 'showLaneShockwave', 'source');
  host.showLaneShockwave({team:input.team||1,line:1,pos:1500,offset:222,fightRes:rendered});
  process.stdout.write(JSON.stringify({visuals, tweens}));
}
'''


@unittest.skipUnless(NODE, 'Node is needed for the ActionScript control-flow harness')
class TeemoClientCombatTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        avatar = (ROOT / 'client/src/stages/137_Avatar.as').read_text(encoding='utf-8')
        skill = (ROOT / 'client/src/stages/139_SkillSet.as').read_text(encoding='utf-8')
        cls.methods = {}
        global_data = (ROOT / 'client/src/stages/001_GlobalData.as').read_text(encoding='utf-8')
        for name in ('baseModHeroId', 'modDefinitionId'):
            cls.methods[name] = method_body(global_data, name)
        # Typed ActionScript locals have zero defaults; retain those in Node.
        avatar = re.sub(r'(var\s+\w+:int)\s*;', r'\1 = 0;', avatar)
        for source, names in ((avatar, ('attackAimList', 'showLaneShockwave', 'getHpMax',
                                        'getDamage', 'getDePh', 'getDeMa', 'getHit',
                                        'getFlee', 'getCrit', 'getTough', 'init', 'goFight',
                                        'initFightAttr', 'getSpeed', 'getRange',
                                        'ownGrowthValue', 'teamTalentFlat', 'getBookCombatBonus',
                                        'isValidSummonMultiplier','inheritSummonPanel','scaledSummonStat','getSummonPanelSnapshot')),
                              (skill, ('getNativeSetting','getMechanismId','getSummonCombatSnapshotApFactor'))):
            for name in names:
                body = method_body(source, name)
                body = re.sub(r'for each\s*\(([^)]+) in ([^)]+)\)', r'for (\1 of \2)', body)
                body = re.sub(r'new Vector\.<\w+>\(\)', '[]', body)
                body = body.replace('param1 is Array', 'Array.isArray(param1)')
                cls.methods[name] = body
        branch = skill.rsplit('case "summon":', 1)[1].split('case "clone_normal":', 1)[0]
        branch = branch.replace('break;', 'return;').replace('new Vector.<Avatar>()', '[]')
        cls.methods['summonAction'] = ('var limitedSummon,summonLevel,summonApFactor,_loc1_,_loc23_,_loc12_;'
                                      'var captainSummonMultiplier=this.captainSummonMultiplier;'
                                      + branch)
        document = json.loads((ROOT / 'config/reconstruction/full-config.json').read_text(encoding='utf-8'))
        apply_upstream_skill_priority(document)
        cls.config = document['cfg']
        cls.effect = {key: value for key, value in
                      cls.config['effect']['FX_STEEL_LANE_WAVE'].items()
                      if key != 'laneWave'}

    def run_client(self, **options):
        if 'skillId' in options:
            options.setdefault('captainSummonMultiplier',
                               self.config['skill'][options['skillId']].get('captainSummonMultiplier', 1))
        result = subprocess.run([NODE, '-e', HARNESS],
                                input=json.dumps(dict(methods=self.methods, effect=self.effect, rows=self.config["avatar"], **options)),
                                capture_output=True, text=True, encoding='utf-8', timeout=15)
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout)

    def test_full_summon_path_inherits_owner_panel_at_all_owner_levels(self):
        authored = {
            'A_2003_2': [3729.6,447.3,1073.8,128.8,385,46.2,464.8,56],
            'A_2018_2': [6393.6,766.8,1840.8,220.8,660,79.2,796.8,96],
            'A_2024_6': [7992,958.5,2301,276,825,99,996,120],
        }
        for skill_id in ('S_301209_4', 'S_301209_5', 'S_301209_6',
                         'S_301310_5', 'S_301310_6', 'S_301226_6'):
            for level in (1, 49, 50, 99, 125):
                for team in (1, 2):
                    with self.subTest(skill=skill_id, level=level, team=team):
                        result = self.run_client(mode='summon', skillId=skill_id, level=level, team=team,
                                                 action=self.config['skill'][skill_id]['skill'][0])
                        aid = self.config['skill'][skill_id]['skill'][0][2]
                        pl = authored[aid]
                        self.assertEqual(self.config['avatar'][aid]['pl'][:8], pl)
                        panel = [int(pl[i]+pl[i+1]*(level-1)) for i in (0,2,4,6)]
                        factor = self.config['skill'][skill_id].get('captainSummonMultiplier', 1)
                        self.assertEqual(factor, 1)
                        combat = [int(value * factor) for value in (1000,300,70,80)]
                        self.assertEqual(result['panel'], panel)
                        self.assertEqual(result['combat'], combat)
                        self.assertEqual(result['hp'], combat[0])
                        self.assertEqual(result['level'], level)
                        self.assertEqual(result['secondary'], [int(value * factor) for value in (11,12,13,14)])
                        self.assertEqual(result['bounded'], 1)

    def test_original_secondary_inheritance_includes_owner_buffs_once(self):
        sid = 'S_301310_6'
        result = self.run_client(mode='summon', skillId=sid, level=50, team=1, buffed=True,
                                 action=self.config['skill'][sid]['skill'][0])
        factor = self.config['skill'][sid].get('captainSummonMultiplier', 1)
        self.assertEqual(result['secondary'], [int(value * factor) for value in (16,18,20,22)])
        self.assertEqual(result['combat'], [int(value * factor) for value in (1000,300,70,80)])

    def test_steel_impact_is_three_full_lane_segments(self):
        expected = ['damage', 1.0, 1, 'FX_STEEL_LANE_WAVE']
        for star in ('5', '6'):
            with self.subTest(star=star):
                skill = self.config['skill'][f'S_201310_{star}']
                self.assertEqual(skill['skill'][:3], [expected, expected, expected])
                self.assertEqual(skill['actionTargetPolicies'][:3],
                                 ['enemy_lane_all'] * 3)
                self.assertEqual(skill['actionTargetMaxTargets'][:3], [-1, -1, -1])
                self.assertIn('3段', skill['rankInfoTemplate'])
                self.assertIn('100%', skill['rankInfoTemplate'])
                self.assertNotIn('300%', skill['rankInfoTemplate'])

    def test_steel_impact_has_two_turn_cooldown(self):
        for star in ('5', '6'):
            with self.subTest(star=star):
                self.assertEqual(self.config['skill'][f'S_201310_{star}']['pl'][1], 2)

    def test_wave_hits_near_and_far_targets_at_the_same_time_with_no_six_target_cap(self):
        for count in (1, 8, 301):
            with self.subTest(count=count):
                positions = [3000 * index/max(1, count-1) for index in range(count)]
                result = self.run_client(mode='wave', positions=positions)
                self.assertEqual(len(result['hits']), count)
                self.assertEqual(result['total'], 300 * count)
                self.assertEqual(len({hit['delay'] for hit in result['hits']}), 1)
                self.assertEqual(result['hits'][0]['delay'], 1.48)
                self.assertGreaterEqual(result['endDelay'], 1.88)

    def test_three_steel_segments_schedule_three_lane_waves_and_hit_everyone(self):
        result = self.run_client(mode='wave', positions=[0, 1500, 3000],
                                 segments=3, coefficient=1)
        self.assertEqual(len(result['hits']), 9)
        self.assertEqual(result['total'], 9 * 100)
        wave_calls = [entry for entry in result['scheduled']
                      if entry['args'] == ['caster']]
        self.assertEqual(len(wave_calls), 3)
        self.assertEqual(len({hit['delay'] for hit in result['hits']}), 3)

    def test_thunder_force_uses_a_distinct_visible_curse_effect(self):
        skill = self.config['skill']['S_201226_6']
        curse = next(action for action in skill['skill'] if action[0] == 'curse')
        self.assertEqual(curse[2], 'FX_S9150_CURSE')
        self.assertEqual(self.config['effect']['curse']['id'], 'e704')
        self.assertTrue(self.config['effect']['curse']['loop'])
        self.assertEqual(self.config['effect']['CURSE_IMPACT']['id'], 'e712')

    def test_wave_keeps_the_normal_miss_check(self):
        result = self.run_client(mode='wave', positions=[0, 1500, 3000], missIndex=1)
        self.assertEqual([hit['index'] for hit in result['hits']], [0, 2])
        self.assertEqual(result['total'], 600)

    def test_wave_starts_at_rendered_caster_and_moves_towards_enemy_for_both_teams(self):
        for team in (1,2):
            result = self.run_client(mode='visual',team=team)
            wave = result['visuals'][0]
            self.assertEqual((wave['x'],wave['y']), (327,471))
            self.assertEqual(len(wave['children']),3)
            for echo in wave['children']:
                art=echo['children'][0]
                self.assertEqual(art['attrs']['id'],'e001')
                self.assertEqual(art['advanced'],[0,0.52])
                self.assertTrue(art['stopped'])
                self.assertGreater(art['scaleX']*art['width'],180)
                self.assertEqual(echo['clipRect']['y'] < 0,team==1)
            for tween in result['tweens'][:3]:
                self.assertEqual(tween['values']['x'], -37)
                expected_y=140+(-150 if team==1 else 3150)*680/3000-5-471
                self.assertAlmostEqual(tween['values']['y'],expected_y)
                self.assertGreater(tween['values']['scaleX'],wave['children'][0]['scaleX'])
            self.assertEqual(result['tweens'][-1]['values'], {'alpha': 0})
            self.assertEqual(result['tweens'][-1]['onCompleteArgs'], [True])


if __name__ == '__main__':
    unittest.main()
