"""Combat rules for the latest six-star balance batch."""

from six_star_followup_battle_105 import percent_debuff

STEALABLE = ('strong', 'steel', 'armor', 'hitup', 'fleeup', 'critup',
             'toughup', 'book_penetration', 'bless')


class SixStarExtendedBattle:
    def six_batch_passive(self, owner, kind):
        actions = (owner.get('skillB') or {}).get('skills', [])
        if actions and actions[0][:2] == ['manual_ability', 'six_batch_' + kind + '_p']:
            return actions[0]
        return None

    def six_batch_jinx_stacks(self, owner):
        state = self.state(owner)
        stacks = [end for end in state.get('batch_jinx', ()) if end >= state['serial']]
        if 'batch_jinx' in state:
            state['batch_jinx'] = stacks
        return stacks

    def six_batch_kayle_stage(self, owner):
        if self.six_batch_passive(owner, 'kayle'):
            return min(4, self.round_index // (7 if owner.get('leader') else 8))
        return 0

    def six_batch_near(self, owner, center, reach):
        return self.candidates(owner, 3-self._team_number(owner), center['line'],
                               center['pos'], reach, -1, excluded=(center,))

    def six_batch_execute(self, owner, kind, skill):
        action = skill['skills'][0]
        state = self.state(owner)
        ctx = self._context(owner)
        if kind == 'six_batch_kayle_c':
            state['batch_kayle_guard'] = (state['serial'] + (2 if self.six_batch_kayle_stage(owner) == 4 else 1), action[4])
            state['batch_kayle_hit'] = 2000
            return True
        if kind == 'six_batch_shaco_box':
            origin = ctx.get('batch_shaco_origin') if ctx else None
            if origin is None:
                return False
            unit = self._spawn_summon(owner, 'A_2019_5', action[4], 3, skill_level=1)
            if unit:
                unit['line'], unit['pos'] = origin
                return True
            return False
        if kind.endswith('_p'):
            return False
        if kind == 'six_batch_jinx_c':
            target = min(self.opponents(owner), key=lambda u: (
                u['hp']/max(1, u['hp_max']), self.state(u)['index']), default=None)
            if target is None:
                return False
            splash = self.six_batch_near(owner, target, 500)
            attack = self._ap_with_talent(owner)
            damage = attack * action[4] + (target['hp_max']-target['hp']) * action[5]
            ctx['batch_jinx_rocket'] = True
            try:
                self._native_damage(owner, target, action[4], 1, raw_override=damage)
                for foe in splash:
                    if owner['hp'] > 0 and foe['hp'] > 0:
                        self._native_damage(owner, foe, action[4], 1, raw_override=damage * action[6])
            finally:
                ctx.pop('batch_jinx_rocket', None)
            return True
        if kind == 'six_batch_tf_n':
            targets = sorted(self.opponents(owner), key=lambda unit: (
                unit['line'] != owner['line'], abs(unit['pos']-owner['pos']),
                self.state(unit)['index']))[:4]
            for foe in targets:
                if self.six_followup_hit(owner, foe, action[4], 2):
                    self.control(owner, foe, 'weak', 2, percent_debuff(action[5]))
            return bool(targets)
        if kind == 'six_batch_ziggs_c':
            target = max((u for u in self.opponents(owner) if self.hero(u)),
                         key=lambda u: (u['hp_max'], -self.state(u)['index']), default=None)
            if target is None:
                return False
            splash = self.six_batch_near(owner, target, 400)[:3]
            self.six_followup_hit(owner, target, self._true_skill_coefficient(action[4]), 3)
            for foe in splash:
                self.six_followup_hit(owner, foe, self._true_skill_coefficient(action[5]), 3)
            return True
        targets = self.six_star_lane(owner, front=True)
        if kind == 'six_batch_tf_c':
            if owner['hp'] >= owner['hp_max'] * .9:
                return False
            self._add_buff(owner, 'purify', 2)
            self._add_buff(owner, 'shield', 2, owner['hp_max'] * action[5])
            self._add_buff(owner, 'steel', 2, action[6])
            prior = self._buff(owner, 'strong')
            self._add_buff(owner, 'strong', 2, action[7])
            strong = self._buff(owner, 'strong')
            state['batch_tf_move'] = dict(until=state['serial']+2, value=action[8],
                                          strong=strong if strong is not prior else None, debuff=False)
            self._injured(owner, (owner['hp_max']-owner['hp'])*action[9], 4, source=owner)
            if targets and self.six_followup_hit(owner, targets[0], action[4], 2):
                self.control(owner, targets[0], 'stun', 1)
            return True
        if not targets:
            return False
        if kind == 'six_batch_jinx_n':
            repeats = 1+len(self.six_batch_jinx_stacks(owner))
            for _ in range(repeats):
                targets = self.six_star_lane(owner, front=True)
                if not targets or owner['hp'] <= 0:
                    break
                primary = targets[0]
                neighbors = self.six_batch_near(owner, primary, 350)
                self.six_followup_hit(owner, primary, action[4], 1)
                for foe in neighbors:
                    self.six_followup_hit(owner, foe, action[5], 1)
        elif kind == 'six_batch_ziggs_n':
            primary = targets[0]
            neighbors = self.six_batch_near(owner, primary, 400)
            if self.six_followup_hit(owner, primary, action[4], 2):
                self.control(owner, primary, 'weak', 2, percent_debuff(action[6]))
                self.control(owner, primary, 'sunder', 2, percent_debuff(action[7]))
            for foe in neighbors:
                self.six_followup_hit(owner, foe, action[5], 2)
        else:
            return False
        return True

    def six_batch_notify_death(self, unit, source):
        state = self.state(unit)
        if state.get('batch_death_notified') or unit['hp'] > 0:
            return
        state['batch_death_notified'] = True
        self.six_reaction_death(unit)
        self.six_batch_death(unit, source)

    def six_batch_death(self, unit, source):
        roster = self.b if self._team_number(unit)==1 else self.a
        for observer in list(roster):
            if observer['hp'] <= 0:
                continue
            same_lane = observer['line'] == unit['line']
            ctx = self._context(observer) if source is observer else None
            if self.six_batch_passive(observer, 'jinx') and (same_lane or ctx and ctx.get('batch_jinx_rocket')):
                state = self.state(observer)
                self.six_batch_jinx_stacks(observer)
                state.setdefault('batch_jinx', []).append(state['serial']+3)
            lissandra = self.six_batch_passive(observer, 'lissandra')
            if lissandra and same_lane:
                with self.context(observer, 'passive'):
                    for foe in self.six_batch_near(observer, unit, 300):
                        self.six_followup_hit(observer, foe, lissandra[4], 2)
            self.six_batch_vayne_event(observer, 'death', unit)

    def six_batch_curse(self, target):
        roster = self.b if self._team_number(target)==1 else self.a
        for observer in list(roster):
            shaco = self.six_batch_passive(observer, 'shaco')
            if shaco and observer['hp'] > 0 and target['hp'] > 0:
                with self.context(observer, 'passive'):
                    if self.six_followup_hit(observer, target, shaco[4], 2) and target['hp'] > 0:
                        self._add_buff(target, 'poison', 2, self._get_damage(observer)*shaco[5], source=observer)

    def six_batch_damage_received(self, target, amount, damage_type, source, dot_kind):
        state = self.state(target)
        if damage_type == 4:
            wound = state.get('batch_ziggs_wound')
            return int(amount*(1-wound['value'])) if wound else amount
        if source is None or self._team_number(source) == self._team_number(target):
            return amount
        yasuo = self.six_batch_passive(target, 'yasuo')
        if yasuo and 1 <= damage_type <= 3 and not dot_kind and target['hp'] > 0:
            if not self._buff_value(target, 'shield') and (
                not state.get('batch_yasuo_shield_used') or target.get('_skill_cd_b', -1) < 0
            ):
                with self.context(target, 'passive'):
                    self._add_buff(target, 'shield', 1, target['hp_max']*yasuo[5], source=target)
                if self._buff_value(target, 'shield'):
                    state['batch_yasuo_shield_used'] = True
                    target['_skill_cd_b'] = target['skillB']['pl'][1]
        guard = state.get('batch_kayle_guard')
        if guard and guard[0] >= state['serial']:
            amount = int(round(amount*(1-guard[1]), 8))
        syndra = self.six_batch_passive(source, 'syndra')
        if syndra:
            amount = int(amount*(1+(self.round_index//10)*syndra[4]))
        return amount

    def six_batch_after_damage(self, owner, target, taken):
        if taken <= 0 or owner['hp'] <= 0 or self._team_number(owner) == self._team_number(target):
            return
        ziggs = self.six_batch_passive(owner, 'ziggs')
        state = self.state(target)
        if ziggs and target['hp'] > 0:
            state['batch_ziggs_wound'] = dict(until=state['serial']+2, value=ziggs[4], debuff=True)
        twisted_fate = self.six_batch_passive(owner, 'tf')
        ctx = self._context(owner)
        if not twisted_fate or ctx and ctx.get('batch_tf_proc'):
            return
        key = ('batch_tf_hits', self.state(owner)['index'])
        state[key] = (state.get(key, 0)+1) % 4
        if state[key] != 0 or target['hp'] <= 0:
            return
        for name in STEALABLE:
            buff = self._buff(target, name)
            if buff:
                self._remove_buff(target, name)
                self._add_buff(owner, name, buff.round, buff.value, source=owner)
                return
        with self.context(owner, 'passive') as response:
            response['batch_tf_proc'] = True
            self.control(owner, target, 'curse', 1)
            self.six_followup_hit(owner, target, self._true_skill_coefficient(twisted_fate[4]), 3)

    def six_batch_speed(self, owner):
        jinx = self.six_batch_passive(owner, 'jinx')
        speed = 1+len(self.six_batch_jinx_stacks(owner))*jinx[4] if jinx else 1
        move = self.state(owner).get('batch_tf_move')
        if move:
            speed *= 1+move['value']
            strong = move['strong']
            if strong is not None and strong is self._buff(owner, 'strong'):
                speed /= 1+strong.value
        return speed

    def six_batch_kayle_attack(self, owner, damage_type):
        stage = self.six_batch_kayle_stage(owner)
        if stage < 2:
            return False
        action = self.six_batch_passive(owner, 'kayle')
        targets = self.six_star_lane(owner)
        positions = [target['pos'] for target in targets]
        main = self._true_skill_coefficient(action[5]) if stage >= 3 else action[4]
        for target in targets:
            before = target['hp']
            if self.six_followup_hit(owner, target, main, 3 if stage >= 3 else damage_type):
                self._book_attack_effects(owner, target, max(0, before-target['hp']))
        if stage >= 3:
            splash = self._true_skill_coefficient(action[6])
            for i, target in enumerate(targets):
                for j, position in enumerate(positions):
                    if i != j and abs(positions[i]-position) <= 200:
                        self.six_followup_hit(owner, target, splash, 3)
        return True

    def six_batch_vayne(self, owner, kind, skill):
        key = ('batch_vayne_rings', self.state(owner)['index'])
        targets = self.six_star_lane(owner, front=True)[::-1]
        target = next((u for u in targets if self.state(u).get(key, {}).get('count')),
                      targets[0] if targets else None)
        if target is None:
            return False
        captain = kind == 'skin2_1206_1'
        action = skill['skills'][0]
        if captain:
            self._remove_all_debuff(owner)
            self._add_buff(owner, 'strong', 2, action[5])
            self._add_buff(owner, 'fleeup', 2, action[6])
            self._add_buff(owner, 'bless', -1)
        self._context(owner)['batch_vayne_ring_hit'] = True
        for _ in range(3 if captain else 2):
            landed = self.six_followup_hit(owner, target, action[4], 1)
        self._context(owner).pop('batch_vayne_ring_hit', None)
        if captain and landed and target['hp'] > 0 and not self.state(target).get('channel'):
            self._check_move(target, False, 800, forced=True)
            if target['pos'] == (self._LINE_POS if self._team_number(target)==1 else 0):
                self.six_followup_hit(owner, target, self._true_skill_coefficient(6), 3)
                self.control(owner, target, 'curse', 1)
                self.control(owner, target, 'stun', 1)
        return True

    def six_batch_vayne_event(self, owner, event, target):
        passive = (owner.get('skillB') or {}).get('skills', [])
        if not passive or passive[0][:2] != ['manual_ability', 'skin2_1206_2']:
            return
        key = ('batch_vayne_rings', self.state(owner)['index'])
        if event == 'death':
            rings = self.state(target).pop(key, {}).get('count', 0)
            foes = self.six_star_lane(owner) if target['line'] == owner['line'] else []
            if rings and foes:
                victim = min(foes, key=lambda u: (u['hp']/u['hp_max'], self.state(u)['index']))
                mark = self.state(victim).setdefault(key, dict(count=0))
                mark['count'] = min(3, mark['count']+rings)
            return
        ctx = self._context(owner)
        if not ctx or not (ctx.get('batch_vayne_ring_hit') or ctx['kind']=='basic'):
            return
        serial = self.state(owner)['serial']
        mark = self.state(target).setdefault(key, dict(count=0))
        if mark.get('serial') != serial:
            mark.update(serial=serial, triggers=0)
        mark['count'] = min(3, mark['count']+1)
        if mark['count'] == 3 and mark['triggers'] < 2:
            mark.update(count=0, triggers=mark['triggers']+1)
            with self.context(owner, 'passive'):
                self.six_followup_hit(owner, target, passive[0][4], 3)
                self._injured(owner, self._get_damage(owner)*passive[0][5], 4, source=owner)
