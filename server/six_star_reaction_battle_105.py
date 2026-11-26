"""Persistent and reactive combat mechanics for the six-star balance."""

from six_star_reactions_105 import PLANT_SKILL

MF_SHIELD = 'sixReactionMfShield105'


class SixStarReactionBattle:
    def six_reaction_passive(self, owner, kind):
        actions = (owner.get('skillB') or {}).get('skills', [])
        if actions and actions[0][:2] == ['manual_ability', 'six_reaction_' + kind + '_p']:
            return actions[0]
        return None

    def six_reaction_execute(self, owner, kind, skill):
        action = skill['skills'][0]
        if kind == 'six_reaction_plant_n':
            allies = self.six_followup_allies(owner)
            if not allies:
                return False
            attack = self._get_damage(owner)*action[4]
            for ally in allies:
                if ally['hp'] >= ally['hp_max']:
                    self._add_buff(ally, 'purify', 1, source=owner)
                else:
                    self._injured(ally, attack, 4, source=owner)
            return True
        if kind == 'six_reaction_evelynn_c':
            targets = self.six_star_lane(owner)
            candidates = [u for u in targets if u['hp'] < u['hp_max']*.4]
            if not candidates:
                return False
            target = min(candidates, key=lambda u: (u['hp']/u['hp_max'], self.state(u)['index']))
            self.six_followup_hit(owner, target, action[4], 2)
            for foe in targets:
                if foe is not target and self.six_followup_hit(owner, foe, action[5], 2):
                    self.control(owner, foe, 'silence', 1)
            if owner['hp'] > 0:
                owner['hp'] = owner['hp_max']
                self._check_move(owner, False, self._LINE_POS, forced=True)
                self._add_buff(owner, 'purify', 1, source=owner)
            return True
        if kind == 'six_reaction_elise_c':
            if self._rooted(owner) or self.state(owner).get('root'):
                return False
            targets = self.candidates(owner, 3-self._team_number(owner), owner['line'],
                                      owner['pos'], abs(skill['pl'][2]), -1, order='ratio')
            if not targets:
                return False
            target = targets[0]
            self._add_buff(owner, 'shield', 2, owner['hp_max']*action[4], source=owner)
            self.dash(owner, target)
            before = target['hp']
            missing = 1-before/target['hp_max']
            self.six_followup_hit(owner, target, action[5]+action[6]*min(1, missing/.67), 2)
            damage = max(0, before-target['hp'])
            if damage and owner['hp'] > 0:
                self._injured(owner, damage, 4, source=owner, fixed_recovery=True)
                if target['hp'] <= 0:
                    self._tick_slot_cd(owner, '_skill_cd_b')
                    self._tick_slot_cd(owner, '_skill_cd_b')
            return True
        return False

    def six_reaction_burn_changed(self, target):
        if target['hp'] <= 0:
            return
        native = self._buff(target, 'burn')
        layers = native.layers if native and native.round > 0 and native.value > 0 else 0
        total = int(native.value)*native.round if layers else 0
        dots = target.get('_manual_dots', {})
        for dot in dots.values():
            if dot['kind'] != 'burn' or dot['round'] <= 0:
                continue
            pending = dot.get('bookRemaining', (dot['apTick']+int(dot['hpMaxFraction']*target['hp_max']))*dot['round'])
            if pending > 0:
                layers += 1
                total += pending
        for dot in target.get('_relic_dots', ()):
            if dot['kind'] == 'burn' and dot['left'] > 0 and dot['amount'] > 0:
                layers += 1
                total += dot['amount']*dot['left']
        if layers < 4:
            return
        roster = self.b if self._team_number(target)==1 else self.a
        for observer in roster:
            passive = self.six_reaction_passive(observer, 'annie')
            if not passive or observer['hp'] <= 0:
                continue
            self._remove_buff(target, 'burn')
            for key in [key for key, dot in dots.items() if dot['kind'] == 'burn']:
                del dots[key]
            with self.context(observer, 'passive'):
                self._injured(target, total*passive[4], 3, source=observer, derived=True)
                self.control(observer, target, 'stun', 1)
            break

    def six_reaction_stun(self, target):
        roster = self.b if self._team_number(target)==1 else self.a
        for observer in roster:
            passive = self.six_reaction_passive(observer, 'thresh')
            if not passive or observer['hp'] <= 0 or observer['line'] != target['line'] or target['hp'] <= 0:
                continue
            owner_state, target_state = self.state(observer), self.state(target)
            for stat in ('de_ph', 'de_ma'):
                key = 'reaction_def_'+stat
                amount = self.six_reaction_defense(target, stat)*passive[4]
                target_state[key] = target_state.get(key, 0)-amount
                owner_state[key] = owner_state.get(key, 0)+amount
            with self.context(observer, 'passive'):
                self.control(observer, target, 'curse', 1)

    def six_reaction_defense(self, unit, stat):
        bonus = (unit.get('_ability') or {}).get('reaction_def_'+stat, 0)
        return max(0, unit.get(stat, 0)*(1+self._get_manual_battle_stack(unit,'defense'))+bonus)

    def six_reaction_taken(self, target, lost):
        if lost <= 0:
            return
        state = self.state(target)
        state.pop('reaction_mf_stacks', None)
        elise = self.six_reaction_passive(target, 'elise')
        if not elise or not 0 < target['hp'] < target['hp_max']*.35:
            return
        if state.get('reaction_elise_used') and target.get('_skill_cd_b', -1) >= 0:
            return
        state['reaction_elise_used'] = True
        state['reaction_elise_net'] = dict(until=state['serial']+1, skip=True)
        target['_skill_cd_b'] = target['skillB']['pl'][1]
        with self.context(target, 'passive'):
            self._add_buff(target, 'purify', 1, source=target)

    def six_reaction_incoming(self, target, amount, damage_type, source):
        state = self.state(target)
        if damage_type == 4:
            wound = state.get('reaction_mf_wound')
            return int(amount*(1-wound['value'])) if wound else amount
        if damage_type in (1, 2, 3, 6, 7, 8) and state.get('reaction_elise_net'):
            return 0
        mf = self.six_reaction_passive(source, 'mf') if source and self._team_number(source)!=self._team_number(target) else None
        return int(amount*(1+self.state(source).get('reaction_mf_stacks', 0)*mf[5])) if mf else amount

    def six_reaction_mf_dealt(self, owner, target, taken):
        if owner['hp'] <= 0 or taken <= 0 or self._team_number(owner)==self._team_number(target):
            return
        passive = self.six_reaction_passive(owner, 'mf')
        if not passive:
            return
        state = self.state(target)
        strength = min(1, self.state(owner).get('reaction_mf_stacks', 0)*passive[6])
        if strength and target['hp'] > 0:
            previous = state.get('reaction_mf_wound')
            if not previous or strength >= previous['value']:
                state['reaction_mf_wound'] = dict(until=state['serial']+1, value=strength)
        with self.context(owner, 'passive'):
            receipt = {}
            self._injured(owner, taken*passive[4], 4, source=owner, receipt=receipt, fixed_recovery=True)
        overflow = receipt.get('healing_overflow', 0)
        if overflow <= 0:
            return
        if self._buff(owner, 'evil'):
            self._remove_buff(owner, 'evil')
            return
        from battle_engine import _Buff
        shields = owner.setdefault('_buffs', {})
        pool = shields.setdefault(MF_SHIELD, _Buff('shield', 0, 0, owner))
        pool.value += overflow

    def six_reaction_turn(self, owner):
        if self.six_reaction_passive(owner, 'mf') and self._buff_value(owner, MF_SHIELD) > 0:
            state = self.state(owner)
            state['reaction_mf_stacks'] = state.get('reaction_mf_stacks', 0)+1

    def six_reaction_death(self, owner):
        passive = self.six_reaction_passive(owner, 'zyra')
        if not passive:
            return
        ratio = next((a[1] for a in (owner.get('skill') or {}).get('skills', [])
                      if a[:1] == ['summon'] and a[2]=='A_2326_5'), passive[4])
        for _ in range(4):
            plant = self._spawn_summon(owner, 'A_2326_5', ratio, 99, skill_level=1)
            if plant:
                self._configure_reaction_plant(plant, PLANT_SKILL, owner)
