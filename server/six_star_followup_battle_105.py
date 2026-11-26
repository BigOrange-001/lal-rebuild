"""Follow-up battle actions shared by the six-star reference simulation."""


IRELIA_IMMUNITIES = frozenset(('weak', 'silence', 'sunder', 'curse', 'stun'))
def percent_debuff(ratio):
    ratio=min(.95,max(0,ratio))
    return ratio/(1-ratio)


FOLLOWUP_ACTIONS = frozenset((
    'six_irelia_c', 'six_lee_c', 'six_fiora_n', 'six_fiora_c',
    'six_nami_n', 'six_morgana_n', 'six_morgana_c',
))


class SixStarFollowupBattle:
    def six_followup_passive(self, unit, kind):
        actions = (unit.get('skillB') or {}).get('skills') or []
        if actions and actions[0][:2] == ['manual_ability', 'six_'+kind+'_p']:
            return actions[0][4:]

    def six_followup_allies(self, owner, exclude_self=False):
        return [u for u in owner.get('_team',[]) if u['hp']>0 and u['line']==owner['line']
                and (not exclude_self or u is not owner)]

    def six_followup_hit(self, owner, target, ratio, kind):
        if owner['hp']<=0 or target['hp']<=0:
            return False
        self._native_damage(owner,target,ratio,kind)
        return self._ability_last_hit

    def six_followup_execute(self, owner, kind, skill):
        action = skill['skills'][0]
        if kind == 'six_nami_n':
            target = max(self.six_followup_allies(owner,True),key=self._get_damage,default=None)
            if target is None:
                return False
            self.state(target)['six_nami_bless'] = dict(source=owner, left=3, ratio=action[5],
                                                       weak=action[6], debuff=False)
            self._injured(target,int(self._get_damage(owner)*action[4]),4,source=owner)
            return True

        foes = self.six_star_lane(owner,abs(skill['pl'][2]),front=kind!='six_lee_c')
        if not foes:
            return False
        target = foes[0]
        hit = self.six_followup_hit
        state = self.state(owner)
        attack = self._context(owner)
        if kind == 'six_irelia_c':
            origin=target['pos']
            group=[u for u in foes if abs(u['pos']-origin)<=700]
            for foe in group:
                if hit(owner,foe,action[4],2):
                    self.control(owner,foe,'sunder',2,percent_debuff(action[5]))
            prior=attack.get('six_physical_hp',0)
            for foe in group:
                hit(owner,foe,action[6],1)
            drained=attack.get('six_physical_hp',0)-prior
            if owner['hp']>0:
                for name in IRELIA_IMMUNITIES:
                    self._remove_buff(owner,name)
                state['six_irelia_immune'] = dict(until=state['serial']+2, debuff=False)
                if drained>0:
                    self._injured(owner,int(drained*action[7]),4,source=owner)
        elif kind == 'six_lee_c':
            start=target['pos']
            side=self._team_number(target)
            end=self._get_final_pos(side,target['line'],start+(800 if side==1 else -800))
            hit(owner,target,action[4],1)
            if target['hp']>0:
                self.control(owner,target,'stun',1)
                self._check_move(target,False,800,forced=True)
                end=target['pos']
            for foe in self.six_star_lane(owner):
                if foe is not target and min(start,end)<=foe['pos']<=max(start,end):
                    hit(owner,foe,action[5],1)
            self._add_buff(owner,'purify',1)
        elif kind == 'six_fiora_n':
            if not self.dash(owner,target):
                return False
            casts=state.get('six_fiora_casts',0)+1
            state['six_fiora_casts']=casts
            attack['six_force_crit'] = casts%2==0 and bool(self.six_followup_passive(owner,'fiora'))
            attack['six_fiora_true'] = action[5]
            hit(owner,target,action[4],1)
            attack.pop('six_fiora_true',None)
            attack.pop('six_force_crit',None)
            self._add_buff(owner,'purify',1)
            drained=attack.get('hp_damage',0)
            if drained>0 and owner['hp']>0:
                attack['six_fiora_overflow']=action[6]
                try:
                    self._injured(owner,drained,4,source=owner)
                finally:
                    attack.pop('six_fiora_overflow',None)
        elif kind == 'six_fiora_c':
            for _ in range(5):
                targets=self.six_star_lane(owner)
                if not targets or owner['hp']<=0:
                    break
                primary=targets[self.rng.get_random(len(targets))%len(targets)]
                position=primary['pos']
                hit(owner,primary,action[4],1)
                for foe in targets:
                    if foe is not primary and abs(foe['pos']-position)<=300:
                        hit(owner,foe,action[4]*action[5],1)
            if owner['hp']>0:
                amount=int(attack.get('hp_damage',0)*action[6])
                if amount:
                    self._add_buff(owner,'shield',2,amount)
        elif kind == 'six_morgana_n':
            if hit(owner,target,action[4],2):
                self.control(owner,target,'stun',2)
            dealt=attack.get('hp_damage',0)
            if dealt>0:
                self._injured(owner,dealt,4,source=owner)
            ally=max(self.six_followup_allies(owner),key=self._get_damage,default=None)
            if ally is not None:
                self._add_buff(ally,'purify',2)
        elif kind == 'six_morgana_c':
            self.six_followup_unlink(owner)
            state['six_morgana_links']=dict(targets=foes, turns=3, damage=action[5])
            for foe in foes:
                self.state(foe).setdefault('six_morgana_sources',{})[state['index']]=(owner,action[4])
        return True

    def six_followup_unlink(self, owner):
        state=self.state(owner)
        group=state.pop('six_morgana_links',None)
        if group:
            for foe in group['targets']:
                self.state(foe).get('six_morgana_sources',{}).pop(state['index'],None)
        return group

    def six_followup_turn(self, owner):
        state=self.state(owner)
        grey=state.pop('six_tahm_grey',0)
        if grey and owner['hp']>0:
            factor,=self.six_followup_passive(owner,'tahm')
            self._injured(owner,int(grey*factor),4,source=owner)
        link=state.get('six_morgana_links')
        if link:
            link['turns']-=1
            if link['turns']<=0:
                self.six_followup_unlink(owner)
                if owner['hp']>0:
                    with self.context(owner,'active',owner.get('leader_skill')):
                        for foe in link['targets']:
                            if self.six_followup_hit(owner,foe,link['damage'],2):
                                self.control(owner,foe,'stun',1)
        growth=self.six_star_row(owner.get('skillB')).get('sixStarPolarGrowth105')
        if growth and owner['hp']>0:
            state['six_polar_turns']=state.get('six_polar_turns',0)+1

    def six_followup_finished(self, owner, kind):
        if kind == 'six_lee_p':
            self.state(owner)['six_lee_armed'] = True
        elif kind == 'six_morgana_p':
            ratio,=self.six_followup_passive(owner,'morgana')
            self._add_buff(owner,'purify',2)
            self._add_buff(owner,'shield',2,int(owner['hp_max']*ratio))

    def six_followup_event(self, owner, event, target, source, overheal):
        if not owner or owner['hp']<=0:
            return
        ctx=self._context(owner)
        if event=='healed' and source is owner and ctx and ctx.get('six_fiora_overflow') and overheal>0:
            self._add_buff(owner,'shield',2,int(overheal*ctx['six_fiora_overflow']))
        if event=='basic_attack':
            lee=self.six_followup_passive(owner,'lee')
            if lee and target and self.state(owner).pop('six_lee_armed',False):
                with self.context(owner,'response'):
                    radius=self.candidates(owner,3-self._team_number(owner),target['line'],target['pos'],400,-1)
                    for foe in radius:
                        if self.six_followup_hit(owner,foe,lee[0],2):
                            self.control(owner,foe,'weak',1,percent_debuff(lee[1]))

    def six_followup_damage_received(self, target, amount, damage_type, source, dot_kind):
        if damage_type not in (1,2,3,6,7,8):
            return amount
        multiplier=1
        if not dot_kind and damage_type in (1,2,3,8):
            sources=self.state(target).get('six_morgana_sources',{}).values()
            amp=max((ratio for owner,ratio in sources if owner['hp']>0),default=0)
            multiplier += amp
        if source and source['line']==target['line'] and self._team_number(source)!=self._team_number(target):
            passive=self.six_followup_passive(source,'irelia')
            if passive:
                deficit=len(self.six_star_lane(source))-len(self.six_followup_allies(source))
                multiplier *= 1+max(0,deficit)*passive[0]
        return int(round(amount*multiplier,5)) if multiplier!=1 else amount

    def six_followup_direct_hit(self, owner, target, ctx, taken):
        if not ctx or taken<=0 or ctx.get('six_derived') or ctx['kind'] not in ('active','basic') or ctx.get('six_slot')=='skillB':
            return
        if self.six_star_row(ctx.get('skill')).get('sixStarNamiWave105') and self.hero(target) and target['hp']>0:
            # Hero-specific slow: outside purify's generic debuff list.
            if not self._status_immune(target):
                state=self.state(target)
                state['six_nami_slow']=dict(until=state['serial']+2,debuff=True)
        aura=ctx.get('six_nami_ticket')
        if aura is None:
            aura=self.state(owner).get('six_nami_bless')
            if not aura or aura['left']<=0:
                return
            aura['left']-=1
            ctx['six_nami_ticket']=aura
            ctx['six_nami_targets']=set()
        seen=ctx['six_nami_targets']
        if id(target) in seen or target['hp']<=0:
            return
        seen.add(id(target))
        ctx['six_derived']=True
        try:
            self._fixed_true_damage(owner,target,int(self._get_damage(aura['source'])*aura['ratio']))
            self.control(owner,target,'weak',3,percent_debuff(aura['weak']))
        finally:
            ctx.pop('six_derived',None)

    def six_followup_speed(self, unit):
        effect=.5 if self.state(unit).get('six_nami_slow') else 1
        for ally in self.six_followup_allies(unit,True):
            passive=self.six_followup_passive(ally,'nami')
            if passive:
                return effect*passive[0]
        return effect
