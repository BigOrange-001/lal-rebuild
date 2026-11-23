"""Battle simulation for the fourth six-star balance batch."""

import copy
from combat_rules import ratio_enabled



class SixStarNextBattle:
    def six_next_passive(self, unit, name):
        actions = (unit.get('skillB') or {}).get('skills', [])
        return actions[0] if actions and actions[0][:2] == ['manual_ability', f'six_next_{name}_p'] else None

    def six_next_radius(self, owner, target, radius, maximum=-1, excluded=()):
        return self.candidates(owner, 3-self._team_number(owner), target['line'],
                               target['pos'], radius, maximum, excluded=excluded)

    def six_next_heal(self, owner, amount):
        if owner['hp'] > 0 and amount > 0:
            self._injured(owner, int(amount), 4, source=owner, fixed_recovery=True)

    def six_next_stack_shield(self, owner, key, amount):
        if amount <= 0 or owner['hp'] <= 0 or self._buff(owner, 'curse'):
            return
        if self._buff(owner, 'evil'):
            self._remove_buff(owner, 'evil')
            return
        from abyss_equip_passives import amplify_shield
        from battle_engine import _Buff
        if ratio_enabled(self._combat_rules):
            amount *= self._precision_recovery(owner)
        shield = owner['_buffs'].setdefault(key, _Buff('shield', 2, 0, owner))
        shield.round = 2
        shield.value += int(amplify_shield(owner, 'shield', amount))

    def six_next_raw(self, owner, target, amount, kind, defense_base=None):
        if owner['hp'] > 0 and target['hp'] > 0 and amount > 0:
            if kind == 3:
                amount /= self._real_damage_rate
            self._native_damage(owner, target, 1, kind, raw_override=amount, defense_base=defense_base)

    def six_next_lightning(self, owner, action):
        targets = self.six_star_lane(owner, 650)
        if not targets:
            return
        target = targets[0]
        visited = [target]
        self._native_damage(owner, target, action[4], 2)
        for _ in range(2):
            targets = self.six_next_radius(owner, target, 300, 1, visited)
            if not targets:
                break
            target = targets[0]
            visited.append(target)
            self._native_damage(owner, target, action[5], 2)

    def six_next_copy_normal(self, clone, owner):
        clone.update(skill=copy.deepcopy(owner.get('skill')), skillB=None, leader_skill=None,
                     book_skill=None, manualActionTypeOverride=1)

    def six_next_execute(self, owner, kind, skill):
        a = skill['skills'][0]
        state = self.state(owner)
        foes = self.six_star_lane(owner)
        defenses = self._get_de_ph(owner)+self._get_de_ma(owner)
        if kind == 'six_next_graves_n':
            targets = self.six_star_lane(owner, 600)
            if not targets or not self.dash(owner, targets[0]):
                return False
            if not state.get('next_graves_basic'):
                state['next_graves_basic'] = a[5]
                for stat in ('de_ph', 'de_ma'):
                    owner[stat] += int(owner[stat]*a[4])
            self._basic_attack(owner, targets[0])
        elif kind == 'six_next_shyvana_c':
            targets = self.opponents(owner) if state.get('next_dragon') else foes
            for target in targets:
                self._native_damage(owner, target, a[4], 2)
                if target['hp'] > 0:
                    self._add_manual_skill_dot(target, f'next_dragon_{state["index"]}', 'burn',
                                               self._get_damage(owner)*a[5], 0, 3, owner, 2, False)
            return bool(targets)
        elif kind == 'six_next_riven_n':
            targets = self.six_star_lane(owner, 450)
            if not targets or not self.dash(owner, targets[0]):
                return False
            primary = targets[0]
            stage = state.get('riven_step', 0) % 3
            state['riven_step'] = (stage+1) % 3
            self._context(owner)['six_next_leech'] = a[7]
            for target in [primary, *self.six_next_radius(owner, primary, 200, 2, (primary,))]:
                self._native_damage(owner, target, a[4+stage], 1)
                if stage == 2 and target['hp'] > 0:
                    self.control(owner, target, 'stun', 1)
            if stage == 1:
                self._add_buff(owner, 'shield', 2, self._get_damage(owner)*a[8], source=owner)
        elif kind == 'six_next_riven_c':
            self._add_buff(owner, 'strong', 2, a[6], source=owner)
            self._add_buff(owner, 'shield', 2, owner['hp_max']*a[7], source=owner)
            for target in foes:
                ratio = a[4]+(a[5]-a[4])*(1-target['hp']/target['hp_max'])
                self._native_damage(owner, target, ratio, 1)
            state['riven_step'] = 2
            return bool(foes)
        elif kind == 'six_next_sivir_p':
            if self._buff(owner, 'purify'):
                return False
            self._add_buff(owner, 'purify', 1, 1)
        elif kind == 'six_next_diana_n':
            shield = owner['hp_max']*a[4]+defenses*a[5]
            self._add_buff(owner, 'shield', 2, shield, source=owner)
            hits = 0
            for target in self.six_star_lane(owner, 600):
                # Diana's damage comes from her defenses, so the target's defense is measured against them.
                self.six_next_raw(owner, target, shield*a[6], 2, defenses)
                hits += bool(self._ability_last_hit)
            if hits >= 3:
                self.six_next_stack_shield(owner, 'next_diana_shield', shield)
            return bool(foes)
        elif kind == 'six_next_diana_c':
            if not foes:
                return False
            team = self._team_number(owner)
            self._reline(owner, owner['line'], 0 if team == 1 else self._LINE_POS)
            anchor = owner['pos'] + (-200 if team == 1 else 200)
            hits = 1
            for target in foes:
                start = target['pos']
                self._reline(target, owner['line'], anchor, forced=True)
                hits += abs(target['pos']-start) >= 100
            for _ in range(hits):
                for target in foes:
                    self.six_next_raw(owner, target, defenses*a[4], 2, defenses)
        elif kind == 'six_next_karthus_c':
            if state.get('next_requiem') or not self.opponents(owner):
                return False
            state['next_requiem'] = a[4]
        elif kind == 'six_next_aoxing_n':
            if state.get('next_storm') or not self.six_star_lane(owner, 650):
                return False
            if state.get('next_charge', 0) >= 5:
                state['next_storm'] = a
            else:
                self.six_next_lightning(owner, a)
                state['next_charge'] = state.get('next_charge', 0)+1
        elif kind == 'six_next_aoxing_c':
            if state.get('next_charge', 0) < 5:
                state['next_charge'] = state.get('next_charge', 0)+1
            elif (owner.get('skill') or {}).get('skills'):
                for _ in range(3):
                    self.six_next_lightning(owner, owner['skill']['skills'][0])
        elif kind == 'six_next_aoxing_p':
            for target in self.opponents(owner):
                self.six_next_raw(owner, target, target['hp']*a[4], 3)
                self.control(owner, target, 'stun', 1)
        elif kind == 'six_next_leblanc_n':
            targets = self.six_star_lane(owner, 1500)
            if not targets:
                return False
            target = targets[0]
            token = owner.get('summon_owner_token')
            mark_owner = next((u for u in owner.get('_team', []) if token and u.get('_owner_token')==token), owner)
            if self.marked(mark_owner, target, 'next_mirror'):
                self.state(target).pop(('mark', 'next_mirror', self.state(mark_owner)['index']), None)
                self._native_damage(owner, target, a[5]/self._real_damage_rate, 3)
                self.control(owner, target, 'silence', 1)
            else:
                self._native_damage(owner, target, a[4], 2)
                if self._ability_last_hit:
                    self.mark(mark_owner, target, 'next_mirror', 2)
        elif kind in ('six_next_baron_n', 'six_next_baron_c'):
            if kind.endswith('_c'):
                state['next_baron_drain'] = state['serial']+1
                for target in foes:
                    self._native_damage(owner, target, a[4], 2)
                    if target['hp'] > 0:
                        self._add_buff(target, 'curse', 2, source=owner)
                self._add_buff(owner, 'shield', 2, owner['hp_max']*a[5], source=owner)
            else:
                for target in foes:
                    cursed = self._buff(target, 'curse')
                    self._add_buff(target, 'curse', 2, source=owner)
                    self._native_damage(owner, target, a[4], 2)
                    if cursed and cursed.source is owner and self._ability_last_hit:
                        self.six_next_heal(owner, self._get_damage(owner)*a[5])
            return bool(foes)
        elif kind == 'six_next_maokai_n':
            targets = self.six_star_lane(owner, 1500, front=True)
            if not targets or not self.dash(owner, targets[0]):
                return False
            primary = targets[0]
            nearby = self.six_next_radius(owner, primary, 300)
            self._native_damage(owner, primary, a[4], 2)
            self.control(owner, primary, 'stun', 1)
            for target in nearby:
                self.six_next_raw(owner, target, owner['hp_max']*a[5], 2)
                if target['hp'] > 0:
                    self._check_move(target, False, 400, forced=True)
                    self.control(owner, target, 'weak', 2, a[6]/(1-a[6]))
        elif kind == 'six_next_maokai_c':
            for lane in sorted({u['line'] for u in self.opponents(owner)}):
                targets = self.candidates(owner, 3-self._team_number(owner), lane, owner['pos'],
                                          self._LINE_POS, 1, order='front')
                if targets:
                    self.control(owner, targets[0], 'stun', 2)
                    self.six_next_raw(owner, targets[0], owner['hp_max']*a[4], 2)
        else:
            return False
        return True

    def six_next_rage(self, owner):
        if not self.six_next_passive(owner, 'shyvana') or owner['hp'] <= 0:
            return
        state = self.state(owner)
        if state.get('next_dragon'):
            return
        state['next_rage'] = state.get('next_rage', 0)+5
        if state['next_rage'] >= 100:
            state['next_dragon'] = True
            self._remove_all_debuff(owner)
            owner['hp_max'] *= 2
            owner['hp'] = owner['hp_max']
            for key, factor in (('ap', 1.6), ('de_ph', 1.5), ('de_ma', 1.5)):
                owner[key] = int(owner[key]*factor)

    def six_next_event(self, owner, event, target):
        if owner['hp'] <= 0 or event not in ('turn_start', 'dodge', 'basic_attack'):
            return
        state = self.state(owner)
        if event == 'turn_start' and (passive := self.six_next_passive(owner, 'baron')):
            keys = ('hp_max', 'ap', 'de_ph', 'de_ma')
            base = state.setdefault('next_baron_base', {key: owner[key] for key in keys})
            scale = sum(bool(self._buff(u, 'curse')) for u in self.six_star_lane(owner))*passive[4]
            for key in keys:
                owner[key] += int(base[key]*scale)
            owner['hp'] += int(base['hp_max']*scale)
        if event == 'dodge' and (passive := self.six_next_passive(owner, 'leblanc')):
            living = [u for u in state.get('next_mirrors', []) if u['hp'] > 0]
            clone = self._spawn_summon(owner, owner['aid'], passive[4], 3, level=owner['lv'])
            if clone is not None:
                self.six_next_copy_normal(clone, owner)
                if len(living) >= 3:
                    old = living.pop(0)
                    old['hp'] = 0
                    self.death(old)
                living.append(clone)
                state['next_mirrors'] = living
        if event != 'basic_attack' or target is None:
            return
        if passive := self.six_next_passive(owner, 'maokai'):
            self.six_next_heal(owner, owner['hp_max']*passive[4])
        if passive := self.six_next_passive(owner, 'sivir'):
            captain = owner.get('leader_skill')
            if captain is None:
                avatar = self._config.get('avatar', {}).get(owner['aid'], {})
                slots = avatar.get('pl', [])
                definition = self._config.get('skill', {}).get(slots[11], {}) if len(slots) > 11 else {}
                actions = definition.get('skill', [])
            else:
                actions = captain.get('skills', [])
            ricochet = next((step for step in actions if step[0] == 'ricochet_bursts'), None)
            if ricochet:
                with self.context(owner, 'passive') as ctx:
                    ctx['six_next_leech'] = passive[4]
                    visited = [target]
                    radius = self._skill_area_radius(ricochet[3])
                    for ratio in ricochet[2][1:3]:
                        targets = self.six_next_radius(owner, target, radius, 1, visited)
                        if not targets:
                            targets = self.six_next_radius(owner, target, radius, 1, (target,))
                        if not targets:
                            break
                        target = targets[0]
                        visited.append(target)
                        self._native_damage(owner, target, ratio, ricochet[4])

    def six_next_stun(self, target):
        for ally in self.opponents(target):
            if ally['line'] != target['line'] or not (passive := self.six_next_passive(ally, 'lux')):
                continue
            state = self.state(ally)
            if state.get('next_lux_round') != self.round_index:
                state.update(next_lux_round=self.round_index, next_lux_count=0)
            if state['next_lux_count'] >= 3:
                continue
            state['next_lux_count'] += 1
            for friend in self.candidates(ally, self._team_number(ally), ally['line'],
                                          ally['pos'], self._LINE_POS, -1):
                self._add_buff(friend, 'shield', 2, self._get_damage(ally)*passive[4], source=ally)

    def six_next_interrupt(self, unit):
        state = self.state(unit)
        state.pop('next_requiem', None)
        if state.pop('next_storm', None):
            state.pop('next_charge', None)

    def six_next_channel_turn(self, owner):
        state = self.state(owner)
        if self._buff(owner, 'stun') or self._buff(owner, 'silence'):
            self.six_next_interrupt(owner)
            return False
        requiem = state.pop('next_requiem', None)
        storm = state.get('next_storm')
        if not requiem and not storm:
            return False
        with self.context(owner, 'active'):
            if requiem:
                for target in self.opponents(owner):
                    self._native_damage(owner, target, requiem, 2)
            else:
                for _ in range(3):
                    if state.get('next_storm'):
                        self.six_next_lightning(owner, storm)
        return bool(requiem)

    def six_next_last_cast(self, owner):
        state = self.state(owner)
        if not self.six_next_passive(owner, 'karthus') or state.get('next_last_cast') or not owner.get('skill'):
            return
        allies = owner.get('_team', [])
        if not any(u is not owner and u['line']==owner['line'] and u['hp']>0 for u in allies):
            return
        state['next_last_cast'] = True
        self.six_next_interrupt(owner)
        owner['hp'] = 1
        try:
            for _ in range(2):
                if owner['hp'] > 0:
                    self._apply_native_skill(owner, self.opponents(owner), 'skill')
        finally:
            owner['hp'] = 0

    def six_next_command_void(self, owner, target):
        for unit in owner.get('_team', []):
            if (unit['hp'] <= 0 or target['hp'] <= 0 or unit['line'] != owner['line']
                    or unit['aid'] != 'A_2904002_5' or not self._buff(unit, 'summon')
                    or self._buff(unit, 'stun') or self._buff(unit, 'silence')):
                continue
            with self.context(unit, 'active', unit.get('skill')):
                for step in (unit.get('skill') or {}).get('skills', []):
                    if step[0] == 'burn':
                        self._add_buff(target, 'burn', step[2], self._get_damage(unit)*step[1], source=unit)
                    elif step[0] == 'poison':
                        self._native_damage(unit, target, step[1], step[2])
                        if target['hp'] > 0:
                            self._add_buff(target, 'poison', step[4], self._get_damage(unit)*step[3], source=unit)

    def six_next_after_damage(self, source, target, kind, lost, taken, dot_kind, ctx):
        if taken <= 0 or kind in (0,4,5):
            return
        direct = 1 <= kind <= 3 and not dot_kind
        if source and self._team_number(source) != self._team_number(target):
            if demon := self.demon_state(source):
                demon['dealt'] = True
            self.six_next_rage(source)
            if direct:
                self.six_next_rage(target)
                self.demon_hurt(target)
                if self.six_next_passive(target, 'graves') and target['hp'] > 0:
                    state = self.state(target)
                    state['next_graves_hits'] = (state.get('next_graves_hits', 0)+1) % 3
                    if not state['next_graves_hits']:
                        self._tick_slot_cd(target, '_skill_cd')
            if ctx:
                leech = ctx.get('six_next_leech', 0)
                if (passive := self.six_next_passive(source, 'sivir')) and (
                        ctx['kind'] == 'basic' or ctx.get('skill') is source.get('leader_skill')):
                    leech = max(leech, passive[4])
                if direct and ctx['kind']=='active' and self.state(source).get('next_baron_drain', -1)>=self.state(source)['serial']:
                    leech = max(leech, .7)
                self.six_next_heal(source, lost*leech)
                # Diana's basic attack is magic: guard re-entry instead of filtering by channel.
                if (direct and ctx['kind']=='basic' and not ctx.get('six_next_lunar')
                        and (passive := self.six_next_passive(source, 'diana'))):
                    ctx['six_next_lunar'] = True
                    try:
                        defenses = self._get_de_ph(source)+self._get_de_ma(source)
                        self.six_next_raw(source, target, defenses*passive[4], 2, defenses)
                    finally:
                        ctx['six_next_lunar'] = False
                if direct and ctx['kind'] in ('basic','active') and self.six_next_passive(source, 'malzahar'):
                    if ctx['kind']=='basic' and target['hp']>0:
                        self.control(source, target, 'silence', 1)
                    self.six_next_command_void(source, target)
        if lost and (kind==7 or dot_kind=='burn'):
            for dragon in self.opponents(target):
                if self.state(dragon).get('next_dragon') and (passive := self.six_next_passive(dragon, 'shyvana')):
                    self.six_next_stack_shield(dragon, 'next_dragon_shield', lost*passive[4])
