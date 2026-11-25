"""Offline counterpart of the maintained Demonblade Tryndamere client methods."""
from battle_engine import _to_int
from demonblade_tryndamere_105 import (
    C_AURA_CAP, C_AURA_RAGE, C_CRIT, C_HEAL_ATK, C_HEAL_HP, C_POWER, C_SPEND, C_SPEND_MIN, C_WEAK,
    N_DAMAGE, N_HEAL_ATK, N_HEAL_HP, N_LOW_HP, N_RADIUS, N_RAGE_NEED, N_SUNDER, N_TARGETS,
    P_ATK_CAP, P_ATK_PER_MISSING, P_BASIC, P_CRIT_DAMAGE_RATE, P_CRIT_PER_RAGE, P_FURY_ATK, P_FURY_COOLDOWN,
    P_FURY_END_HEAL, P_FURY_LIMIT, P_FURY_RAGE, P_FURY_ROUNDS, P_FURY_ROUNDS_MEMBER, P_RAGE_BASIC, P_RAGE_CRIT,
    P_RAGE_DECAY, P_RAGE_HURT, P_RAGE_HURT_CAP, P_RAGE_SKILL, P_RAGE_SKILL_CAP, P_RAGE_START,
)
from new_skin_bonds_104 import mechanic_value
from six_star_followup_battle_105 import percent_debuff

RAGE_MAX = 100


class DemonTryndBattleMixin:
    def demon_is(self, unit):
        return bool(unit and self._config.get('avatar', {}).get(unit.get('aid'), {}).get('demonbladeTryndamere105'))

    def demon_passive(self, unit):
        if not self.demon_is(unit):
            return None
        for action in (unit.get('skillB') or {}).get('skills', []):
            if action[:2] == ['manual_ability', 'demon_trynd_p']:
                return action
        return None

    def demon_state(self, unit):
        passive = self.demon_passive(unit)
        if passive is None:
            return None
        state = self.state(unit)
        if 'demon' not in state:
            state['demon'] = dict(rage=float(passive[P_RAGE_START]), fury=-1, ready=0, used=0,
                                  hurt=0, aura=0, dealt=False, acted=False, force=False)
        return state['demon']

    def demon_rage(self, unit):
        demon = self.demon_state(unit)
        return demon['rage'] if demon else 0

    def demon_gain(self, unit, amount, limit=RAGE_MAX):
        demon = self.demon_state(unit)
        if demon is None or unit.get('hp', 0) <= 0 or amount <= 0:
            return 0
        before = demon['rage']
        rate = mechanic_value(self._config, unit, 'demon_rage_gain', 1)
        demon['rage'] = min(RAGE_MAX, before + min(limit, amount * rate))
        return demon['rage'] - before

    def demon_fury(self, unit):
        demon = self.demon_state(unit)
        return bool(demon and demon['fury'] >= 0)

    def demon_crit_bonus(self, unit):
        passive = self.demon_passive(unit)
        return self.demon_rage(unit) * passive[P_CRIT_PER_RAGE] * 100 if passive else 0

    def _crit_damage_rate(self, unit):
        passive = self.demon_passive(unit)
        return passive[P_CRIT_DAMAGE_RATE] if passive else super()._crit_damage_rate(unit)

    def demon_attack(self, unit, value):
        passive = self.demon_passive(unit)
        if passive is None or not unit.get('hp_max'):
            return value
        missing = max(0.0, 1 - max(0, unit.get('hp', 0)) / unit['hp_max'])
        value = _to_int(value * (1 + min(passive[P_ATK_CAP], missing * 100 * passive[P_ATK_PER_MISSING])))
        if self.demon_fury(unit):
            value = _to_int(value * (1 + passive[P_FURY_ATK]))
        return value

    def demon_basic_ratio(self, unit):
        passive = self.demon_passive(unit)
        if passive is None:
            return None
        from equipment_bonds_104 import equipped_bonds
        for row in equipped_bonds(self._config, unit['aid'], unit.get('equipment_bonds_104', [])):
            ratio = row.get('mechanics', {}).get('demon_basic_ratio')
            if ratio is not None:
                return ratio
        return passive[P_BASIC]

    def demon_take_force_crit(self, unit):
        demon = self.demon_state(unit)
        if demon and demon['force']:
            demon['force'] = False
            return True
        return False

    def demon_immune(self, unit, kind):
        return kind == 'curse' and self.demon_fury(unit)

    def _add_buff(self, unit, kind, rounds, value=0, source=None, poison_hp_rate_104=1):
        if self.demon_immune(unit, kind):
            return None
        return super()._add_buff(unit, kind, rounds, value, source=source, poison_hp_rate_104=poison_hp_rate_104)

    def _get_damage(self, unit):
        return self.demon_attack(unit, super()._get_damage(unit))

    def _settle_turn_buffs(self, unit):
        self.demon_turn(unit)
        return super()._settle_turn_buffs(unit)

    def demon_turn(self, unit):
        demon = self.demon_state(unit)
        passive = self.demon_passive(unit)
        if demon is None or unit.get('hp', 0) <= 0:
            return
        if demon['acted'] and not demon['dealt']:
            demon['rage'] = max(0.0, demon['rage'] - passive[P_RAGE_DECAY])
        demon.update(acted=True, dealt=False, hurt=0, aura=0)
        if demon['fury'] >= 0:
            demon['fury'] -= 1
            if demon['fury'] < 0:
                demon['rage'] = 0.0
                self._remove_all_debuff(unit)
                heal = _to_int(unit['hp_max'] * passive[P_FURY_END_HEAL])
                if heal > 0:
                    self._injured(unit, heal, 4, source=unit, fixed_recovery=True)

    def _resolve_lethal(self, target):
        if int(target.get('hp', 0)) <= 0 and self.demon_lethal(target):
            return
        super()._resolve_lethal(target)

    def demon_lethal(self, unit):
        demon = self.demon_state(unit)
        passive = self.demon_passive(unit)
        if demon is None:
            return False
        if demon['fury'] >= 0:
            unit['hp'] = 1
            return True
        if demon['used'] >= passive[P_FURY_LIMIT] or self.round_index < demon['ready']:
            return False
        demon['used'] += 1
        demon['ready'] = self.round_index + int(passive[P_FURY_COOLDOWN])
        demon['fury'] = int(passive[P_FURY_ROUNDS] if unit.get('leader') else passive[P_FURY_ROUNDS_MEMBER])
        unit['hp'] = 1
        self._remove_buff(unit, 'curse')
        self.demon_gain(unit, passive[P_FURY_RAGE])
        self._event('demon_fury', unit, unit)
        return True

    def demon_hurt(self, unit):
        demon = self.demon_state(unit)
        passive = self.demon_passive(unit)
        if demon is None:
            return
        cap = passive[P_RAGE_HURT_CAP] * mechanic_value(self._config, unit, 'demon_rage_gain', 1)
        gained = self.demon_gain(unit, passive[P_RAGE_HURT], max(0, cap - demon['hurt']))
        demon['hurt'] += gained

    def demon_event(self, owner, event, source, target):
        if owner is None or source is not owner or target is None or self._team_number(owner) == self._team_number(target):
            return
        demon = self.demon_state(owner)
        if event == 'hit' and demon is not None:
            ctx = self._context(owner)
            if ctx and ctx['kind'] == 'basic':
                self.demon_gain(owner, self.demon_passive(owner)[P_RAGE_BASIC])
        if event != 'crit':
            return
        ctx = self._context(owner)
        if demon is not None and ctx and ctx['kind'] == 'basic':
            self.demon_gain(owner, self.demon_passive(owner)[P_RAGE_CRIT])
        for leader in (self.a if self._team_number(owner) == 1 else self.b):
            if leader is owner or leader.get('hp', 0) <= 0 or not leader.get('leader') or leader['line'] != owner['line']:
                continue
            captain = self.demon_captain(leader)
            lead = self.demon_state(leader)
            if captain is None or lead is None:
                continue
            cap = captain[C_AURA_CAP] * mechanic_value(self._config, leader, 'demon_rage_gain', 1)
            lead['aura'] += self.demon_gain(leader, captain[C_AURA_RAGE], max(0, cap - lead['aura']))

    def demon_captain(self, unit):
        for action in (unit.get('leader_skill') or {}).get('skills', []):
            if action[:2] == ['manual_ability', 'demon_trynd_c']:
                return action
        return None

    def demon_lane(self, owner):
        return self.candidates(owner, 3 - self._team_number(owner), owner['line'],
                               self._LINE_POS / 2, self._LINE_POS, -1, order='front')

    def demon_allies(self, owner):
        return [u for u in (self.a if self._team_number(owner) == 1 else self.b)
                if u.get('hp', 0) > 0 and u['line'] == owner['line']]

    def demon_hit(self, owner, target, coefficient, skill):
        rate = float(self._config['system_simple'].get('hero_skill_output_rate_104', 1))
        return self.hit(owner, target, coefficient / max(rate, .000001), 1)

    def execute_demon(self, owner, kind, skill):
        if not self.demon_is(owner) or kind == 'demon_trynd_p':
            return False
        action = skill['skills'][0]
        if kind == 'demon_trynd_c':
            return self.demon_war_cry(owner, action)
        front = self.demon_lane(owner)
        if not front:
            return False
        if self._rooted(owner) and abs(front[0]['pos'] - owner['pos']) > self._get_range(owner):
            return False
        demon = self.demon_state(owner)
        if (demon and owner['hp'] < owner['hp_max'] * action[N_LOW_HP]
                and demon['rage'] >= action[N_RAGE_NEED]):
            amount = _to_int(owner['hp_max'] * action[N_HEAL_HP] + self._get_damage(owner) * action[N_HEAL_ATK])
            self._injured(owner, amount, 4, source=owner)
        if not self._rooted(owner):
            self.dash(owner, front[0])
        # Centred on the front enemy: the native spacing keeps the landing point
        # in front of it, which would otherwise eat most of the radius.
        targets = self.candidates(owner, 3 - self._team_number(owner), front[0]['line'], front[0]['pos'],
                                  action[N_RADIUS], int(action[N_TARGETS]), order='nearest')
        gained = 0
        passive = self.demon_passive(owner)
        cap = passive[P_RAGE_SKILL_CAP] * mechanic_value(self._config, owner, 'demon_rage_gain', 1) if passive else 0
        damage = action[N_DAMAGE] * mechanic_value(self._config, owner, 'demon_q_damage', 1)
        summon_rate = mechanic_value(self._config, owner, 'demon_q_summon', 1)
        curse_rounds = mechanic_value(self._config, owner, 'demon_q_curse')
        with self.context(owner, 'active', skill=skill):
            for target in targets:
                if owner['hp'] <= 0:
                    break
                multiplier = summon_rate if self._buff(target, 'summon') or self._get_type(target) == 2 else 1
                if not self.demon_hit(owner, target, damage * multiplier, skill):
                    continue
                if target['hp'] > 0:
                    self.control(owner, target, 'sunder', 2, percent_debuff(action[N_SUNDER]))
                    if curse_rounds and target['hp'] > 0:
                        self.control(owner, target, 'curse', curse_rounds)
                if passive is not None and gained < cap:
                    gained += self.demon_gain(owner, passive[P_RAGE_SKILL], cap - gained)
        if demon is not None:
            demon['force'] = True
        return True

    def demon_war_cry(self, owner, action):
        allies = self.demon_allies(owner)
        for ally in allies:
            self._add_buff(ally, 'strong', 2, action[C_POWER], source=owner)
            self._add_buff(ally, 'critup', 2, action[C_CRIT], source=owner)
        enemies = self.demon_lane(owner)
        if enemies:
            weakened = [enemies[0]] + self.candidates(owner, 3 - self._team_number(owner), enemies[0]['line'],
                                                      enemies[0]['pos'], self._LINE_POS, 1, order='nearest',
                                                      excluded=[enemies[0]])
            for target in weakened:
                self.control(owner, target, 'weak', 2, percent_debuff(action[C_WEAK]))
        demon = self.demon_state(owner)
        if demon is None:
            return True
        spent = min(demon['rage'], max(demon['rage'] * action[C_SPEND], action[C_SPEND_MIN]))
        demon['rage'] -= spent
        amount = _to_int(spent * (self._get_damage(owner) * action[C_HEAL_ATK] + owner['hp_max'] * action[C_HEAL_HP]))
        if amount > 0:
            for ally in allies:
                if ally['hp'] >= ally['hp_max']:
                    self._add_buff(ally, 'shield', 2, amount, source=owner)
                else:
                    self._injured(ally, amount, 4, source=owner)
        return True
