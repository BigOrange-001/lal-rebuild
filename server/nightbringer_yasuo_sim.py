"""Offline counterpart of the maintained Yasuo client methods; no rendering."""
from battle_engine import _Buff, _to_int
from new_skin_bonds_104 import mechanic_value


class YasuoBattleMixin:
    def yasuo_is(self, unit):
        return bool(unit and self._config.get('avatar', {}).get(unit.get('aid'), {}).get('nightbringerYasuo104'))

    def yasuo_passive(self, unit):
        return self.yasuo_is(unit) and any(a[:2] == ['manual_ability', 'night_yasuo_p']
                                          for a in (unit.get('skillB') or {}).get('skills', []))

    def yasuo_night(self, unit):
        return bool(unit and unit.get('_yasuo_night_rounds', -1) >= 0)

    def yasuo_cast_silenced(self, unit):
        return self.yasuo_is(unit) and unit.get('hp',0)>0 and not self._buff(unit,'stun') and mechanic_value(self._config, unit, 'yasuo_c_silenced')>0

    def yasuo_immune(self, unit, kind):
        return self.yasuo_night(unit) and kind in ('stun', 'silence', 'curse', 'poison', 'burn')

    def _get_crit(self, unit):
        return super()._get_crit(unit) + unit.get('_yasuo_crit_bonus', 0)

    def _damage_modifiers_104(self, target, amount, damage_type, source):
        ctx = self._context(source) if source else None
        if self.yasuo_night(source) and not (ctx and ctx.get('derived_yasuo')):
            amount = _to_int(amount * 1.5)
        if self.yasuo_night(target):
            amount = _to_int(amount * .2)
        return amount

    def _tick_buffs(self, unit):
        for key in ('_yasuo_night_rounds', '_yasuo_vamp_rounds'):
            if unit.get(key, -1) >= 0:
                unit[key] -= 1
        return super()._tick_buffs(unit)

    def _add_manual_skill_dot(self, target, key, kind, *args, **kwargs):
        if self.yasuo_immune(target, kind):
            return False
        return super()._add_manual_skill_dot(target, key, kind, *args, **kwargs)

    def yasuo_lane(self, owner):
        return self.candidates(owner, 3-self._team_number(owner), owner['line'],
                               self._LINE_POS/2, self._LINE_POS, -1, order='front')

    def yasuo_cleanse(self, owner):
        for kind in ('stun', 'silence', 'curse', 'poison', 'burn'):
            self._remove_buff(owner, kind)
        for key, entry in list(owner.get('_manual_dots', {}).items()):
            if entry['kind'] in ('poison', 'burn'):
                del owner['_manual_dots'][key]

    def execute_yasuo(self, owner, kind, skill):
        targets = self.yasuo_lane(owner)
        if not self.yasuo_is(owner) or not targets or kind == 'night_yasuo_p':
            return False
        target = targets[0]
        if kind == 'night_yasuo_c':
            self.yasuo_cleanse(owner)
            owner.update(_yasuo_night_rounds=1, _yasuo_vamp_rounds=2)
            self._add_buff(owner, 'bless', 1, source=owner)
            position = target['pos'] + (200 if self._team_number(owner) == 1 else -200)
            self._reline(owner, owner['line'], max(0, min(self._LINE_POS, position)))
            for coefficient in skill['skills'][0][4:7]:
                if owner['hp'] <= 0 or target['hp'] <= 0:
                    break
                self.yasuo_hit(owner, target, coefficient*mechanic_value(self._config,owner,'yasuo_c_damage',1), skill)
            return True
        self.add_purify_charges(owner, 1)
        if not self._rooted(owner):self._check_move(owner, True, 400, forced=True)
        weak_percent = float(skill['skills'][0][5])
        rate = float(self._config['system_simple'].get('hero_skill_output_rate_104', 1))
        launch=owner['pos']
        direction=-1 if self._team_number(owner)==1 else 1
        plan=[(index,unit,unit['pos']) for index,unit in enumerate(targets) if (unit['pos']-launch)*direction>=0]
        self._event('yasuo_vortex_launch',owner,lane=owner['line'],position=launch,
                    end=0 if direction==-1 else self._LINE_POS,speed=2400)
        with self.context(owner, 'active', skill=skill):
            for index, unit, position in plan:
                if owner['hp'] <= 0:break
                if unit['hp'] <= 0 or unit['line']!=owner['line']:continue
                self._event('yasuo_vortex_contact',owner,unit,position=position,time=abs(position-launch)/2400)
                coefficient = skill['skills'][0][4] * (1 if index == 0 else .6)
                if self.hit(owner, unit, coefficient/max(rate,.000001), 1) and owner['hp'] > 0 and unit['hp'] > 0:
                    if index == 0:
                        self.control(owner, unit, 'stun', 1)
                    elif 0 < weak_percent < 1:
                        self.control(owner, unit, 'weak', 1, weak_percent/(1-weak_percent))
                if unit['hp']>0 and owner['hp']>0:
                    self._check_move(unit, False, 300, forced=True)
        return True

    def yasuo_hit(self, owner, target, coefficient, skill):
        rate = float(self._config['system_simple'].get('hero_skill_output_rate_104', 1))
        with self.context(owner, 'active', skill=skill):
            return self.hit(owner, target, coefficient/max(rate, .000001), 1)

    def yasuo_event(self, owner, event, source, target, amount):
        if not owner or source is not owner or owner.get('hp', 0) <= 0 or not target:
            return
        if self._team_number(owner) == self._team_number(target):
            return
        if event == 'hit' and owner.get('_yasuo_vamp_rounds', -1) >= 0 and amount > 0:
            # Settled HP damage is already the heal amount; no precision formula.
            self._injured(owner, _to_int(amount), 4, source=owner)
        if event != 'crit' or not self.yasuo_passive(owner) or self._buff(owner, 'curse'):
            return
        if self._buff(owner, 'evil'):
            self._remove_buff(owner, 'evil', consume=True)
            return
        amount = _to_int(owner['hp_max']*.05 + self._get_damage(owner)*.25)
        owner['_yasuo_shield_serial'] = owner.get('_yasuo_shield_serial', 0) + 1
        owner.setdefault('_buffs', {})['yasuoShield104_'+str(owner['_yasuo_shield_serial'])] = _Buff('shield', 2, amount, owner)

    def yasuo_critical(self, owner, target, settled):
        if not self.yasuo_passive(owner) or owner.get('_yasuo_crit_busy') or owner['hp'] <= 0 or target['hp'] <= 0:
            return
        amount = _to_int(settled * mechanic_value(self._config, owner, 'yasuo_crit_true', .35))
        if amount <= 0:
            return
        owner['_yasuo_crit_busy'] = True
        try:
            with self.context(owner, 'passive') as ctx:
                ctx['derived_yasuo'] = True
                self._event('yasuo_crit_true', owner, target, amount=amount)
                # Already-settled base: no second global output/crit/armor pass.
                self._injured(target, _to_int(amount*(1+self._talent(target,16))), 3, source=owner)
        finally:
            owner['_yasuo_crit_busy'] = False
