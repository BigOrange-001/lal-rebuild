"""Reference execution for Champion Camille and Golden Rain."""

from mod_policy import base_aid

WILD = 'camille_wild'


def kit_action(unit, slot, ability):
    for action in (unit.get(slot) or {}).get('skills', ()):
        if action[:2] == ['manual_ability', 'champion_camille_' + ability]:
            return action
    return None


def trigger_fmvp(battle, unit, before):
    action = kit_action(unit, 'skillB', 'fmvp')
    if not action or battle._buff(unit, WILD) is not None:
        return
    if unit.get('_camille_fmvp_fired') and unit.get('_skill_cd_b', -1) >= 0:
        return
    health = unit['hp_max']
    threshold, shield, turns, charges = action[4:8]
    if not before > health * threshold >= unit['hp'] > 0:
        return
    unit['_camille_fmvp_fired'] = True
    unit['_skill_cd_b'] = unit['skillB']['pl'][1]
    battle._add_buff(unit, 'purify', 0, charges)
    battle._add_buff(unit, 'bless', turns, 1)
    battle._add_buff(unit, 'shield', turns, int(health * shield), source=unit)


def execute(battle, owner, ability, action):
    if ability == 'fmvp':
        return False
    if ability == 'rain':
        champion, ratio, charges = action[4:7]
        allies = owner.get('_team', ())
        for target in (owner, *(unit for unit in allies if unit is not owner and
                                base_aid(battle._config, unit['aid']) == champion)):
            if target['hp'] > 0:
                battle._injured(target, int(target['hp_max'] * ratio), 4, source=owner, fixed_recovery=True)
                battle._add_buff(target, 'purify', 0, charges)
        battle._add_buff(owner, 'bless', 0)
        return True

    if battle._rooted(owner):
        return False
    foes = battle.opponents(owner)
    heroes = [unit for unit in foes if battle._get_type(unit) == 1 and not battle._buff(unit, 'summon')]
    if not heroes:
        return False
    if ability == 'smite':
        target = max(heroes, key=lambda unit: unit['hp_max'])
        ratio, turns, forms = action[4:7]
        battle._add_buff(target, WILD, turns)
        if battle._buff(target, WILD) is not None:
            battle.state(target).pop('channel', None)
            target['_camille_wild_card'] = forms.get(target['aid'].rsplit('_', 1)[-1])
        battle.dash(owner, target)
        battle._fixed_true_damage(owner, target, target['hp_max'] * ratio)
        return True

    trophy_aid, p_atk, p_hp, t_atk, t_hp, radius, extra, stun, lifetime = action[4:13]
    target = max(heroes, key=battle._get_damage)
    original_pos = owner['pos']
    trophy = battle._spawn_summon(owner, trophy_aid, 1, lifetime, bounded=True, skill_level=1)
    if trophy is None:
        return False
    trophy['pos'] = original_pos
    trophy['ap'] = trophy['range'] = 0
    trophy['new_4attrs'] = dict.fromkeys(('hit', 'flee', 'crit', 'tough'), 0)
    trophy.pop('_equip_reduction', None)
    panel = battle._summon_panel_snapshot(owner)
    trophy['hp'] = trophy['hp_max'] = panel['hp_max']
    trophy['de_ph'], trophy['de_ma'] = panel['de_ph'], panel['de_ma']
    enemy_side = battle._team_number(target)
    toward_owner = 1 if enemy_side == 2 else -1
    lane = [unit for unit in foes if unit['line'] == target['line']]
    front = max(lane, key=lambda unit: unit['pos'] * toward_owner)
    # Approach from in front of the existing front rank, leaving space for
    # the pull to respect the opposing formation's native movement clamp.
    if not battle._reline(owner, target['line'], front['pos'] + toward_owner * 250):
        return True
    if front is not target and not battle._buff(target, 'purify'):
        battle._reline(target, target['line'], front['pos'] + toward_owner * 125, forced=True)
    battle.control(owner, target, 'stun', stun)
    nearby = sorted((unit for unit in lane if unit is not target and abs(unit['pos'] - target['pos']) <= radius),
                    key=lambda unit: abs(unit['pos'] - target['pos']))
    targets = [target, *nearby[:extra]]
    for kind, attack_ratio, health_ratio in ((1, p_atk, p_hp), (3, t_atk, t_hp)):
        for victim in targets:
            if owner['hp'] > 0 and victim['hp'] > 0:
                ratio = attack_ratio + victim['hp_max'] * health_ratio / max(1, battle._get_damage(owner))
                battle.hit(owner, victim, ratio, kind)
    return True
