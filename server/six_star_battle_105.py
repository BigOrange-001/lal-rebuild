"""Stateful six-star actions in the reference simulator."""
from combat_math import damage_before_final
from six_star_extended_battle_105 import SixStarExtendedBattle
from six_star_reaction_battle_105 import SixStarReactionBattle
from six_star_followup_battle_105 import FOLLOWUP_ACTIONS, SixStarFollowupBattle
from six_star_next_battle_105 import SixStarNextBattle


def passive_kind(unit):
    actions = (unit.get('skillB') or {}).get('skills') or []
    return actions[0][1] if actions and actions[0][0] == 'manual_ability' and actions[0][1].startswith('six_') else None


class SixStarBattleMixin(SixStarFollowupBattle, SixStarExtendedBattle, SixStarReactionBattle, SixStarNextBattle):
    def six_star_row(self, skill):
        return self._config.get('skill', {}).get((skill or {}).get('skid'), {})

    def six_star_lane(self, owner, reach=3000, *, front=False, forward=False):
        return self.candidates(owner, 3-self._team_number(owner), owner['line'], owner['pos'], reach, -1,
                               order='front' if front else 'nearest', forward=forward)

    def six_star_execute(self, owner, kind, skill):
        if kind.startswith('six_next_'):
            return self.six_next_execute(owner, kind, skill)
        if kind.startswith('six_reaction_'):
            return self.six_reaction_execute(owner, kind, skill)
        if kind.startswith('six_batch_'):
            return self.six_batch_execute(owner, kind, skill)
        if kind in FOLLOWUP_ACTIONS:
            return self.six_followup_execute(owner,kind,skill)
        action = skill['skills'][0]
        ratio = action[4]
        state = self.state(owner)
        if kind == 'six_yi_c':
            self._remove_buff(owner, 'weak')
            self._add_buff(owner, 'strong', 2, ratio)
            state['highlander'] = dict(until=state['serial']+2, left=0, extra=action[5], debuff=False)
            return True
        if kind == 'six_shen_n':
            state['six_shen'] = dict(charges=3, ratio=ratio, debuff=False)
            return True
        if kind == 'six_caitlyn_c':
            target = min(self.opponents(owner), key=lambda u:(
                u['hp']/max(1,u['hp_max']), self.state(u)['index']), default=None)
            if target is None:
                return False
            self._native_damage(owner, target, ratio, 1)
            return True
        targets = self.six_star_lane(owner, abs(skill['pl'][2]), front=kind in (
            'six_yi_n', 'six_gangplank_c', 'six_ahri_c'), forward=kind == 'six_talon_n')
        if kind == 'six_kennen_p':
            targets = [target for target in targets if self._buff(target, 'stun')]
            if len(targets) < 3:
                return False
            for target in targets:
                self._native_damage(owner, target, ratio, 2)
            return True
        if not targets:
            return False
        if kind == 'six_yi_n':
            for target in targets[:4]:
                self._native_damage(owner, target, ratio, 1)
        elif kind == 'six_gangplank_c':
            anchor = targets[0]['pos']
            self._context(owner)['six_crit_true'] = True
            for target in targets:
                if abs(target['pos']-anchor) <= 300:
                    self._native_damage(owner, target, ratio, 1)
        elif kind == 'six_blitz_c':
            for target in targets:
                self._remove_buff(target, 'shield')
                # A single dispel takes one purify layer.
                self._remove_buff(target, 'purify', consume=True)
                self.control(owner, target, 'silence', 1)
                self._native_damage(owner, target, ratio, 2)
        elif kind in ('six_akali_c', 'six_ahri_c'):
            primary = max(targets, key=self._get_damage)
            if kind == 'six_akali_c':
                self.control(owner, primary, 'stun', 1)
                self._native_damage(owner, primary, ratio, 2)
            else:
                self._check_move(owner, False, 300)
                self._check_move(primary, True, 500, forced=True)
                self._native_damage(owner, primary, ratio, 2)
                for target in [u for u in targets if u is not primary][:2]:
                    self._native_damage(owner, target, action[5], 2)
        elif kind == 'six_talon_n':
            for coefficient in action[4:6]:
                for target in targets:
                    if target['hp'] > 0:
                        self._native_damage(owner, target, coefficient, 1)
        elif kind == 'six_caitlyn_n':
            primary = targets[0]
            self._check_move(owner, False, 500)
            self._native_damage(owner, primary, ratio, 2)
            if primary['hp'] > 0:
                state['six_caitlyn_shot'] = dict(target=primary, ratio=action[5], debuff=False)
        else:
            return False
        return True

    def six_star_begin(self, owner, ctx, slot):
        ctx['six_slot'] = slot
        if self.six_star_row(ctx.get('skill')).get('sixStarBatchShacoBox105'):
            ctx['batch_shaco_origin'] = (owner['line'], owner['pos'])
        if slot != 'skillB' and self.state(owner).pop('six_fire', False):
            ctx['six_fire'] = True

    def six_star_finished(self, owner, slot, skill, ctx, cast):
        state = self.state(owner)
        if not cast:
            if ctx.get('six_fire'):
                state['six_fire'] = True
            return
        if owner['hp'] <= 0 or slot == 'skillB':
            return
        row = self.six_star_row(skill)
        if row.get('sixStarBatchSandHeal105'):
            for unit in owner.get('_team', ()):
                if unit['hp'] > 0 and unit.get('_batch_sand') and unit.get('summon_owner_token') == owner.get('_owner_token'):
                    unit['hp'] = unit['hp_max']
        if slot == 'skill' and self.six_batch_passive(owner, 'gabriel'):
            count = len(self.six_followup_allies(owner, exclude_self=True))
            original = skill['pl'][1]
            owner['_ability_cd_override'] = max(0, original-count)
        kind = passive_kind(owner)
        self.six_followup_finished(owner,kind)
        if self.six_star_row(skill).get('sixStarLeech105'):
            drained = ctx.get('hp_damage', 0)
            if drained:
                self._injured(owner, drained, 4, source=owner)
        for _ in range(ctx.get('six_katarina_recasts',0)):
            if owner['hp']>0:
                self.six_star_katarina_recast(owner)
        if kind == 'six_shen_p':
            action = owner['skillB']['skills'][0]
            self._add_buff(owner, 'shield', 2, int(owner['hp_max']*action[4]))
            self._add_buff(owner, 'steel', 2, action[5])
            self._add_buff(owner, 'taunt', 2)
        elif kind == 'six_gangplank_p' and slot == 'leader_skill':
            state['six_fire'] = True
        elif kind == 'six_wukong_p' and slot == 'leader_skill':
            for clone in state.get('summons_wukong', []):
                if clone['hp'] > 0:
                    clone['leader_skill'] = skill
                    try:
                        self._apply_native_skill(clone, self.opponents(clone), 'leader_skill')
                    finally:
                        clone['leader_skill'] = None

    def six_star_katarina_recast(self, owner):
        state = self.state(owner)
        state['six_katarina_recast'] = True
        try:
            skill = owner.get('skill')
            enemies = self.opponents(owner)
            if skill and enemies and self._apply_native_skill(owner,enemies,'skill'):
                owner['_skill_cd'] = skill['pl'][1]
        finally:
            state.pop('six_katarina_recast',None)

    def six_star_stun_applied(self, target):
        opposition = self.opponents(target)
        allies = self.b if self._team_number(target)==2 else self.a
        for opponent in opposition:
            if opponent['line']==target['line'] and passive_kind(opponent)=='six_kennen_p':
                warmup = opponent['skillB']['pl'][0]
                if opponent.get('_skill_cd_b',warmup)<0:
                    self._use_turn_start_passive(opponent,allies)

    def six_star_owner_turn(self, owner):
        self.six_followup_turn(owner)
        if owner.get('_six_star_turret'):
            self._injured(owner, int(owner['hp_max']*.3), 4, source=owner)
        shot = self.state(owner).pop('six_caitlyn_shot', None)
        if shot and shot['target']['hp'] > 0:
            with self.context(owner, 'active'):
                self._native_damage(owner, shot['target'], shot['ratio'], 1)

    def six_star_event(self, owner, event, target, amount=0, overheal=0):
        if not owner or owner['hp'] <= 0:
            return
        kind = passive_kind(owner)
        if kind is None:
            return
        action = owner['skillB']['skills'][0]
        state = self.state(owner)
        ctx = self._context(owner)
        if event == 'kill':
            if kind == 'six_katarina_p' and not state.get('six_katarina_recast'):
                self._add_buff(owner, 'strong', 2, action[4])
                if ctx and ctx['kind']=='active' and ctx.get('six_slot'):
                    ctx['six_katarina_recasts'] = ctx.get('six_katarina_recasts',0)+1
                else:
                    self.six_star_katarina_recast(owner)
        elif event == 'basic_attack' and kind == 'six_wukong_p':
            for clone in state.get('summons_wukong', []):
                if clone['hp'] <= 0:
                    continue
                victim = target if target and target['hp'] > 0 and target['line'] == clone['line'] else None
                if victim is None:
                    victim = next(iter(self.six_star_lane(clone)), None)
                if victim is not None:
                    self._basic_attack(clone, victim)
        elif event == 'healed' and kind == 'six_ahri_p' and owner['hp'] >= owner['hp_max'] and amount==0 and overheal > 0:
            self._add_buff(owner, 'purify', 1)
            self._add_buff(owner, 'hitup', 1, action[4])
            self._add_buff(owner, 'fleeup', 1, action[4])
        elif event == 'hit' and target and target['hp'] > 0 and ctx and not ctx.get('six_derived'):
            if kind == 'six_jarvan_p' and self._buff(owner, 'strong'):
                self.control(owner, target, 'sunder', 1, action[4])
                self.control(owner, target, 'weak', 1, action[4])
            elif kind == 'six_gangplank_p' and ctx.pop('six_fire', False):
                self._add_manual_skill_dot(target, (owner['_owner_token'], 'fire'), 'burn',
                                           self._get_damage(owner)*action[4], 0, 2, owner, 1, False)
            elif kind == 'six_darius_p':
                self.six_star_bleed(owner, target, action[4], action[5])
            elif kind == 'six_talon_p' and ctx['kind'] == 'active' and ctx.get('six_slot') != 'skillB':
                key = (owner['_owner_token'], 'talon_hits')
                hits = (self.state(target).get(key, 0)+1) % 3
                self.state(target)[key] = hits
                if not hits:
                    self._add_manual_skill_dot(target, (owner['_owner_token'], 'talon'), 'bleed',
                                               self._get_damage(owner)*action[4], 0, 3, owner, 1, False)

    def six_star_extend_yi(self, owner):
        state = self.state(owner)
        phase = state.get('highlander')
        if phase and phase.get('extra'):
            phase['until'] += 1
            strength = self._buff(owner, 'strong')
            if strength:
                strength.round += 1

    def six_star_bleed(self, owner, target, ratio, fury):
        token = owner['_owner_token']
        dots = target.get('_manual_dots', {})
        prefix = (token, 'darius')
        layers = [key for key in dots if isinstance(key, tuple) and key[:2] == prefix]
        key = (*prefix, next((i for i in range(5) if (*prefix,i) not in layers),4))
        damage = self._get_damage(owner)*ratio
        if not self._add_manual_skill_dot(target, key, 'bleed', damage, 0, 3, owner, 1, False):
            return
        for layer in layers:
            dots[layer]['round'] = 3
        state = self.state(owner)
        if len(layers) >= 4 and not state.get('six_bloodrage'):
            state['six_bloodrage'] = True
            self._add_manual_battle_stack(owner, 'attack', fury, 1)
            self._add_manual_battle_stack(owner, 'defense', fury, 1)

    def six_star_extra_damage(self, attacker, target, ctx, raw, share, crit, sign_a, sign_b):
        if not ctx or ctx.get('six_derived') or target['hp'] <= 0 or attacker['hp'] <= 0:
            return
        state = self.state(attacker)
        shen = state.get('six_shen')
        derived = bool(ctx.get('six_force_crit'))
        if ctx.get('six_fiora_true'):
            damage_type=3
            amount=self._final_direct_damage(int(target['hp_max']*ctx['six_fiora_true']),target,crit,ctx.get('six_force_crit',False))
        elif ctx.get('six_shen_strike') and shen is not None:
            damage_type = 1
            amount = damage_before_final(int(attacker['hp_max']*shen['ratio']), sign_a, sign_b, 1,
                                         self._defense_against(attacker,target,1), 0, self._attack, 1,
                                         base_attack=attacker.get('ap',0), rules=self._combat_rules)
            amount = self._final_direct_damage(amount, target, crit)
        elif ctx['kind'] in ('basic', 'active') and ctx.get('six_slot') != 'skillB' and state.get('highlander', {}).get('extra'):
            damage_type = 3
            derived = True
            sign = self._attack[2] if sign_a%3==sign_b-1 else 1
            amount = int(raw*share*crit*sign*state['highlander']['extra'])
        else:
            return
        if amount > 0:
            ctx['six_derived'] = True
            try:
                self._injured(target, amount, damage_type, source=attacker, derived=derived)
            finally:
                ctx.pop('six_derived', None)


def configure_turret(unit):
    unit['skill'] = unit['leader_skill'] = unit['skillB'] = unit['book_skill'] = None
    unit['_six_star_turret'] = True
    unit['manual_attack_range'] = 1000
    unit['manualActionTypeOverride'] = 1
