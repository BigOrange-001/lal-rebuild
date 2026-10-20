"""Skill-complete study engine for Avatar.executeAbility and its state hooks.

The named abilities follow the recovered client formulas. Rendering is absent;
the underlying ReferenceBattle remains an offline model, not the AIR runtime.
"""
from __future__ import annotations

import math
from contextlib import contextmanager

from battle_engine import ReferenceBattle, _to_int
from combat_math import (miss_chance, crit_chance, critical_multiplier,
                         damage_before_final, to_int)


KINDS = frozenset(f'{hero}_{slot}' for hero in (
    'illaoi','jayce','nidalee','kayle','maokai','wukong','gangplank','yi','veigar',
    'elise','riven','orianna','nunu','alistar','diana','khazix','malzahar','jinx',
    'tahm','caitlyn','kaelthas','aoxing') for slot in ('n','c'))


class SkillCompleteBattle(ReferenceBattle):
    def __init__(self, *args, trace_abilities=False, **kwargs):
        super().__init__(*args, **kwargs)
        self.ability_contexts=[]
        self.ability_events=[] if trace_abilities else None
        self.manual_casts={}
        self._ability_next=0
        for roster in (self.a,self.b):
            for unit in roster:
                unit['_team']=roster
                tpl=unit.get('tpl') or []
                if len(tpl)>3:unit.setdefault('speed',tpl[3])
                self.state(unit)

    def state(self, unit):
        if '_ability' not in unit:
            self._ability_next+=1
            unit['_ability']={'index':self._ability_next,'serial':0,'entry_ap':unit.get('ap',0)}
        return unit['_ability']

    @staticmethod
    def _factor(value):
        return float(value) if type(value) in (int,float) and math.isfinite(value) and value>0 else 1.0

    def _event(self, kind, owner, target=None, **data):
        if self.ability_events is not None:
            self.ability_events.append(dict(kind=kind,owner=owner.get('aid'),target=(target or {}).get('aid'),**data))

    @contextmanager
    def context(self, owner, kind='active', skill=None, damage=1, effect=1):
        ctx=dict(owner=owner,kind=kind,skill=skill,damage_factor=damage,effect_factor=effect,
                 targets={},guards={},kills=[])
        self.ability_contexts.append(ctx)
        try:
            yield ctx
        finally:
            self.ability_contexts.pop()
            self._end_context(ctx)

    def _context(self, owner=None):
        ctx=self.ability_contexts[-1] if self.ability_contexts else None
        return ctx if ctx and (owner is None or ctx['owner'] is owner) else None

    def _end_context(self, ctx):
        owner=ctx['owner']
        for target,amount in ctx['targets'].values():
            state=self.state(target);guard=state.get('guard')
            if guard and id(target) in ctx['guards']:
                guard['charges']-=1
                if guard['charges']<=0:state.pop('guard',None)
                source=guard.get('owner')
                if guard['kind']=='kayle' and target.get('hp',0)>0 and owner.get('hp',0)>0 and source and source.get('hp',0)>0:
                    with self.context(source,'response',damage=guard.get('damage',1)):
                        for victim in self.enemies(source,300,target,3):self.hit(source,victim,1.5,2)
            if amount<=0 or owner.get('hp',0)<=0 or target.get('hp',0)<=0 or not self.hero(owner):continue
            sap=state.get('sap')
            if sap and ctx['kind']=='active':
                state.pop('sap',None)
                with self.context(target,'response',effect=sap.get('effect',1)):self.heal(target,target,.6)
            counter=state.get('counter')
            if (counter and counter['left']>0 and ctx['kind'] in ('active','basic') and id(owner) not in counter['seen']
                    and owner['line']==target['line'] and abs(owner['pos']-target['pos'])<=400):
                counter['left']-=1;counter['seen'].add(id(owner))
                with self.context(target,'response',damage=counter['damage'],effect=counter['effect']):
                    if self.hit(target,owner,1,1):self.heal(target,target,.2)
        highlander=self.state(owner).get('highlander')
        if owner.get('hp',0)>0 and ctx['kills'] and highlander and ctx['kind'] in ('basic','active'):
            if highlander['left']>0 and owner.get('_ability_normal_cast') and owner.get('_skill_cd',0)>0:
                highlander['left']-=1;owner['_skill_cd']=max(0,owner['_skill_cd']-2)

    def hero(self, unit):
        return self._get_type(unit)==1 and not unit.get('summon_owner')

    def candidates(self, owner, team, lane, position, distance, maximum=1, hero=False, order='nearest', excluded=(), forward=False):
        roster=self.a if team==1 else self.b
        excluded_ids={id(u) for u in (excluded or ())}
        found=[u for u in roster if u.get('hp',0)>0 and u['line']==lane and abs(u['pos']-position)<=distance
               and (not hero or self.hero(u)) and id(u) not in excluded_ids
               and (not forward or (u['pos']<=position if self._team_number(owner)==1 else u['pos']>=position))]
        def sort_key(u):
            tie=self.state(u)['index']
            if order=='ratio':return u['hp']/max(1,u['hp_max']),tie
            if order=='front':return u['pos']*(1 if team==1 else -1),tie
            return abs(u['pos']-position)*(-1 if order=='farthest' else 1),tie
        found.sort(key=sort_key)
        return found if maximum<0 else found[:maximum]

    def enemies(self, owner, distance, center=None, maximum=1, hero=False, order='nearest', excluded=(), forward=False):
        ctx=self._context(owner)
        if center is None and ctx and ctx.get('skill'):
            configured=self._get_cast_range(owner,ctx['skill'])
            if configured>0:distance=configured
            actions=ctx['skill'].get('skills') or []
            if actions and len(actions[0])>1 and actions[0][1]=='jayce_n':
                distance=1500 if self.state(owner).get('form',{}).get('hammer') else self._LINE_POS
        if center is not None or maximum!=1:distance=self._skill_area_radius(distance)
        center=center or owner
        return self.candidates(owner,3-self._team_number(owner),center['line'],center['pos'],distance,maximum,hero,order,excluded,forward)

    def ally(self, owner, distance=3001, order='ratio', exclude=False):
        found=self.candidates(owner,self._team_number(owner),owner['line'],owner['pos'],distance,1,True,order,[owner] if exclude else [])
        return found[0] if found else None

    def marked(self, owner, target, mark):
        entry=self.state(target).get(('mark',mark,self.state(owner)['index']))
        return bool(entry and entry['until']>=self.state(target)['serial'])

    def mark(self, owner, target, mark, duration, scale=1):
        if target.get('hp',0)>0:
            self.state(target)[('mark',mark,self.state(owner)['index'])]=dict(until=self.state(target)['serial']+duration,owner=owner,debuff=True,scale=scale)

    def marked_target(self, owner, mark, distance, order='nearest'):
        ctx=self._context(owner)
        if ctx and ctx.get('skill'):distance=self._get_cast_range(owner,ctx['skill'])
        units=self.candidates(owner,3-self._team_number(owner),owner['line'],owner['pos'],distance,-1,True,order)
        return next((u for u in units if self.marked(owner,u,mark)),units[0] if units else None)

    def hit(self, owner, target, coefficient, damage_type, shared_total=0):
        if not target or target.get('hp',0)<=0 or owner.get('hp',0)<=0:return False
        ctx=self._context(owner);factor=ctx['damage_factor'] if ctx else 1
        coefficient*=factor
        self._event('hit',owner,target,coefficient=coefficient,damage_type=damage_type)
        # True-damage manual actions cancel countDamage's native 0.3 factor.
        if damage_type==3:coefficient/=0.3
        total=shared_total*factor if shared_total>0 else coefficient
        self._native_damage(owner,target,total,damage_type,coefficient/total if total else 1)
        return self._ability_last_hit

    def heal(self, owner, target, coefficient):
        if target and target.get('hp',0)>0:
            ctx=self._context(owner);factor=ctx['effect_factor'] if ctx else 1
            self._event('heal',owner,target,coefficient=coefficient*factor)
            amount=_to_int(self._heal_channel_value(owner,coefficient)*factor)
            self._injured(target,amount,4,source=owner)

    def shield(self, owner, target, coefficient, duration=2, health=False):
        if target and target.get('hp',0)>0:
            ctx=self._context(owner);factor=ctx['effect_factor'] if ctx else 1
            amount=_to_int((self._get_hp(owner) if health else self._get_damage(owner)+self._get_hp(owner)*.1)*coefficient)
            self._event('shield',owner,target,amount=amount,duration=duration)
            self._add_buff(target,'shield',duration,amount)

    @staticmethod
    def _get_hp(owner):return owner.get('hp_max',1)

    def control(self, owner, target, kind, duration, value=0):
        if not target or target.get('hp',0)<=0:return
        if kind=='root':
            if self._buff(target,'purify'):
                self._remove_buff(target,'purify',consume=True);return
            self.state(target)['root']=dict(until=self.state(target)['serial']+duration,debuff=True)
        self._add_buff(target,kind,duration,value)

    def dash(self, owner, target, enemy_side=False):
        if not target or target.get('hp',0)<=0 or self.state(owner).get('root'):return False
        destination=target['pos']+(125 if self._team_number(owner)==1 else -125)*(-1 if enemy_side else 1)
        return self._reline(owner,target['line'],max(0,min(self._LINE_POS,destination)))

    def isolated(self, target):
        return not self.candidates(target,self._team_number(target),target['line'],target['pos'],300,-1,True,excluded=[target])

    def summon(self, owner, aid, count, ratio, turns, key, focus=None, clone=False):
        ctx=self._context(owner);ratio*=ctx['effect_factor'] if ctx else 1
        state=self.state(owner)
        for old in state.get('summons_'+key,[]):old['hp']=0;self.death(old)
        units=[]
        for i in range(count):
            unit=self._spawn_summon(owner,owner['aid'] if clone else aid,ratio,turns)
            if unit is None:raise ValueError(f'Missing manual summon template: {aid}')
            unit['skill']=unit['leader_skill']=unit['skillB']=None
            unit.update(speed=220,range=125,manualActionTypeOverride=1)
            unit['pos']=max(0,min(self._LINE_POS,owner['pos']+(-1 if self._team_number(owner)==1 else 1)*(125+100*i)))
            if clone:self._add_buff(unit,'taunt',1,0)
            if focus:unit['_ability_focus']=focus
            self.state(unit);units.append(unit)
        state['summons_'+key]=units

    def _get_damage(self, unit):
        value=_to_int(super()._get_damage(unit)*(1+self._get_manual_battle_stack(unit,'attack')+self._get_manual_timed_stack(unit,'attack')))
        state=self.state(unit)
        value=max(0,value+_to_int(state['entry_ap']*state.get('evil_bonus',0)))
        return _to_int(value*(1+.05*state.get('santa_stacks',0)))

    def _get_de_ph(self, unit):
        base=dict(unit,de_ph=unit.get('de_ph',0)*(1+self._get_manual_battle_stack(unit,'defense')))
        return super()._get_de_ph(base)

    def _get_de_ma(self, unit):
        base=dict(unit,de_ma=unit.get('de_ma',0)*(1+self._get_manual_battle_stack(unit,'defense')))
        return super()._get_de_ma(base)

    def _summon_panel_snapshot(self, owner):
        result=dict(hp_max=self._get_hp(owner),ap=self._ap_with_talent(owner),
                    de_ph=self._get_de_ph(owner),de_ma=self._get_de_ma(owner))
        for key in ('hit','flee','crit','tough'):
            result[key]=self._stat_buff(owner,key)+(int(self._get_manual_battle_stack(owner,'flee')) if key=='flee' else 0)
        return result

    def execute(self, owner, kind, scale, skill):
        if kind in ('cat_n','cat_c'):return self.execute_cat_skin(owner,kind,skill)
        if kind in ('polar_n','polar_c'):return self.execute_polar_skin(owner,kind,skill)
        if kind in ('santa_n','santa_c'):return self.execute_santa_skin(owner,kind,skill)
        if kind in ('nurse_n','nurse_c'):return self.execute_nurse_skin(owner,kind,skill)
        if kind not in KINDS:raise ValueError(f'Unsupported client manual ability: {kind}')
        state=self.state(owner);serial=state['serial']
        ctx=self._context(owner);damage=ctx['damage_factor'];effect=ctx['effect_factor']
        row=self._config['skill'].get(skill.get('skid'),{})
        defense=self._factor(row.get('manualDefenseBuffMultiplier'))
        orange=5 if str(owner['aid']).endswith('_6') else 1
        en=lambda distance,center=None,maximum=1,hero=False,order='nearest',excluded=(),forward=False:self.enemies(owner,distance,center,maximum,hero,order,excluded,forward)
        hit=lambda target,coef,typ,shared=0:self.hit(owner,target,coef,typ,shared)
        ctl=lambda target,name,turns,value=0:self.control(owner,target,name,turns,value)
        buff=lambda name,turns,value=0:self._add_buff(owner,name,turns,value)
        def group(primary,radius,maximum):return [primary]+en(radius,primary,maximum,excluded=[primary])
        match kind:
            case 'illaoi_n':
                enemies=en(500)
                if not enemies:return False
                count=0
                for target in group(enemies[0],250,3):
                    if hit(target,1.2*scale,1) and self.hero(target):count+=1
                if count:self.heal(owner,owner,.15*min(3,count)*scale)
            case 'illaoi_c':
                for target in en(350,maximum=3):hit(target,2,1)
                state['counter']=dict(until=serial+2,left=2,seen=set(),damage=damage,effect=effect,debuff=False)
            case 'jayce_n':
                form=state.setdefault('form',{'hammer':False});enemies=en(500 if form['hammer'] else 700)
                if not enemies:return False
                primary=enemies[0]
                if not form['hammer']:
                    hit(primary,1.4*scale,1)
                    for target in en(200,primary,1,excluded=[primary]):hit(target,.8*scale,1)
                else:
                    if not self.dash(owner,primary):return False
                    if hit(primary,1.8*scale,1):self._check_move(primary,False,200,True)
                    self.shield(owner,owner,.5*scale)
                form['hammer']=not form['hammer']
            case 'jayce_c':
                enemies=en(700)
                if not enemies:return False
                primary=enemies[0]
                for target in group(primary,250,3):hit(target,1.6,1,3 if target is primary else 0)
                if primary['hp']>0:
                    if not state.get('root'):self.dash(owner,primary)
                    if hit(primary,1.4,1,3):self._check_move(primary,False,250,True)
                state['form']={'hammer':False}
            case 'nidalee_n':
                enemies=en(650,order='farthest')
                if not enemies:return False
                target=enemies[0];reach=abs((skill.get('pl') or [0,0,650])[2])
                coefficient=(1+min(reach,abs(owner['pos']-target['pos']))/max(1,reach))*scale
                if hit(target,coefficient,2):self.mark(owner,target,'hunt',3)
            case 'nidalee_c':
                self.heal(owner,self.ally(owner),.7);target=self.marked_target(owner,'hunt',700)
                if target and self.dash(owner,target):
                    marked=self.marked(owner,target,'hunt')
                    if hit(target,3.2 if marked else 2.2,2) and marked:self.state(target).pop(('mark','hunt',state['index']),None)
            case 'kayle_n':
                enemies=en(500)
                if enemies and hit(enemies[0],1.2*scale,2):ctl(enemies[0],'sunder',2,.2*scale)
                self.heal(owner,self.ally(owner),.45*scale)
            case 'kayle_c':
                target=self.ally(owner,600)
                if target is None:return False
                self.state(target)['guard']=dict(kind='kayle',charges=1,until=self.state(target)['serial']+2,owner=owner,damage=damage,debuff=False)
            case 'maokai_n':
                enemies=en(500)
                if not enemies or not self.dash(owner,enemies[0]):return False
                if hit(enemies[0],scale,2):ctl(enemies[0],'root',1)
                state['sap']=dict(until=serial+2,effect=effect,debuff=False)
            case 'maokai_c':
                for target in en(700,maximum=3,forward=True):
                    if hit(target,1.8,2):ctl(target,'root',2)
                self.shield(owner,owner,.2,2,True)
            case 'wukong_n':
                enemies=en(175)
                if not enemies:return False
                if hit(enemies[0],1.4*scale,1):ctl(enemies[0],'sunder',2,.25*scale)
                self.summon(owner,owner['aid'],1,.35*scale,2,'wukong',clone=True)
                self._check_move(owner,False,200)
            case 'wukong_c':
                enemies=en(700)
                if not enemies or not self.dash(owner,enemies[0]):return False
                targets=group(enemies[0],300,3)
                for i in range(2):
                    for target in targets:
                        if hit(target,1.3,1,2.6) and i==0:ctl(target,'stun',1)
                buff('steel',2,.4*defense)
            case 'gangplank_n':
                marked=owner['hp']/owner['hp_max']<.5;enemies=en(600)
                if not enemies:return False
                hit(enemies[0],1.6*scale,1)
                if marked:self._remove_all_debuff(owner);self.heal(owner,owner,.4*scale)
            case 'gangplank_c':
                enemies=en(800)
                if not enemies:return False
                primary=enemies[0];state['zone']=dict(line=primary['line'],pos=primary['pos'],left=2,damage=damage,effect=effect)
                for target in en(350,primary,3):
                    if hit(target,1.2,1):ctl(target,'weak',1,.2)
            case 'yi_n':
                enemies=en(600,maximum=-1)
                if not enemies:return False
                for target in enemies[:3]:hit(target,(2 if len(enemies)==1 else 1.1)*scale,1)
                buff('fleeup',1,600*scale*orange)
            case 'yi_c':
                buff('strong',3,.5);buff('hitup',3,800*orange);self._remove_buff(owner,'weak')
                state['highlander']=dict(until=serial+3,left=2,debuff=False)
                if owner.get('skill'):self._apply_native_skill(owner,self.opponents(owner),'skill')
            case 'veigar_n':
                enemies=en(600)
                if not enemies:return False
                if hit(enemies[0],1.2*scale,2) and self.hero(enemies[0]):
                    old=state.get('evil_stacks',0);state['evil_stacks']=min(10,old+1)
                    if state['evil_stacks']>old:state['evil_bonus']=state.get('evil_bonus',0)+.03*effect
            case 'veigar_c':
                enemies=en(700,hero=True,order='ratio') or en(700)
                if not enemies:return False
                target=enemies[0];hit(target,2+3*(1-target['hp']/target['hp_max']),2)
            case 'elise_n':
                enemies=en(600)
                if not enemies:return False
                target=enemies[0];ap=self._get_damage(owner)
                coef=scale+min(ap,target['hp']*.04*scale)/max(1,ap)
                if hit(target,coef,2):ctl(target,'stun',1)
            case 'elise_c':
                enemies=en(650,hero=True,order='ratio')
                if not enemies or not self.dash(owner,enemies[0]):return False
                target=enemies[0];ap=self._get_damage(owner)
                hit(target,1.8+min(ap*1.8,(target['hp_max']-target['hp'])*.12)/max(1,ap),2)
                self.summon(owner,'A_2013_5',2,.3,2,'elise')
            case 'riven_n':
                enemies=en(450)
                if not enemies or not self.dash(owner,enemies[0]):return False
                primary=enemies[0];count=state.get('riven_step',0)%3+1;state['riven_step']=count%3
                for target in group(primary,200,2):
                    if hit(target,(1.4 if count==3 else .8)*scale,1) and count==3:ctl(target,'stun',1)
                if count==2:self.shield(owner,owner,.6*scale)
            case 'riven_c':
                buff('strong',2,.35)
                for target in en(700,maximum=3,forward=True):hit(target,1.6+.96*(1-target['hp']/target['hp_max']),1)
                state['riven_step']=2
            case 'orianna_n':
                target=self.ally(owner,3001,'front',True) or owner;state['ball']=target
                self.shield(owner,target,.8*scale)
                for enemy in en(300,target,2):hit(enemy,scale,2)
            case 'orianna_c':
                ally=state.get('ball')
                if not ally or ally['hp']<=0 or ally['line']!=owner['line']:ally=owner
                state['ball']=ally
                for target in en(350,ally,3):
                    self._check_move(target,True,200,True)
                    if hit(target,2.2,2):ctl(target,'stun',1)
                self.shield(owner,ally,.8)
            case 'nunu_n':
                enemies=en(175)
                if not enemies:return False
                target=enemies[0];summoned=bool(target.get('summon_owner'))
                hit(target,(3 if summoned else 1.4)*scale,3 if summoned else 2)
                self.heal(owner,owner,.7*scale)
            case 'nunu_c':
                self.shield(owner,owner,1.2)
                state['channel']=dict(pos=owner['pos'],line=owner['line'],damage=damage,effect=effect)
            case 'alistar_n':
                enemies=en(500)
                if not enemies or not self.dash(owner,enemies[0]):return False
                primary=enemies[0];targets=group(primary,250,3)
                hit(primary,.8*scale,2,1.4*scale)
                for target in targets:
                    if hit(target,.6*scale,2,1.4*scale if target is primary else 0):ctl(target,'stun',1)
                buff('taunt',2)
            case 'alistar_c':
                self._remove_all_debuff(owner);self.heal(owner,owner,.5)
                state['guard']=dict(kind='alistar',charges=3,until=serial+2,owner=owner,effect=effect,debuff=False)
            case 'diana_n':
                enemies=en(650)
                if not enemies:return False
                for target in group(enemies[0],250,3):
                    if hit(target,scale,2):self.mark(owner,target,'moon',3)
            case 'diana_c':
                primary=self.marked_target(owner,'moon',650)
                if not primary or not self.dash(owner,primary):return False
                targets=en(300,owner,3)
                if all(u is not primary for u in targets):targets=([primary]+targets)[:3]
                for target in targets:
                    marked=self.marked(owner,target,'moon');self._check_move(target,True,150,True)
                    if hit(target,2.7 if marked else 1.8,2) and marked:self.state(target).pop(('mark','moon',state['index']),None)
                self.shield(owner,owner,1)
            case 'khazix_n':
                enemies=en(500)
                if not enemies or not self.dash(owner,enemies[0]):return False
                hit(enemies[0],(2.4 if self.isolated(enemies[0]) else 1.6)*scale,1)
            case 'khazix_c':
                enemies=en(700,maximum=-1,hero=True)
                primary=next((u for u in enemies if self.isolated(u)),enemies[0] if enemies else None)
                if primary is None or not self.dash(owner,primary,True):return False
                hit(primary,4.2 if self.isolated(primary) else 2.8,1);buff('fleeup',2,800*orange)
                if primary['hp']<=0 and self.hero(primary):owner['_ability_cd_override']=3
            case 'malzahar_n':
                enemies=en(600)
                if not enemies:return False
                target=enemies[0]
                if self._buff(target,'purify'):self._remove_buff(target,'purify',consume=True)
                else:self.state(target)[('malz',state['index'])]=dict(owner=owner,until=self.state(target)['serial']+1,ticks=3,tick_damage=self._get_damage(owner)*scale*damage,hops=0,debuff=True)
            case 'malzahar_c':
                enemies=en(650)
                if not enemies:return False
                target=enemies[0]
                if hit(target,2.4,2):ctl(target,'stun',2)
                self.summon(owner,'A_2013_5',2,.35,2,'malzahar',target)
            case 'jinx_n':
                enemies=en(650)
                if not enemies:return False
                primary=enemies[0];hit(primary,1.5*scale,1)
                for target in en(250,primary,2,excluded=[primary]):hit(target,1.1*scale,1)
            case 'jinx_c':
                enemies=en(1000,hero=True,order='ratio')
                if not enemies:return False
                primary=enemies[0];targets=en(300,primary,2,excluded=[primary]);ap=self._get_damage(owner)
                hit(primary,2+min(2*ap,(primary['hp_max']-primary['hp'])*.12)/max(1,ap),1)
                for target in targets:hit(target,1.2,1)
                if ctx['kills']:
                    buff('strong',2,.3);buff('critup',2,800*orange)
                    if owner.get('skill'):self._apply_native_skill(owner,self.opponents(owner),'skill')
            case 'tahm_n':
                enemies=en(500)
                if not enemies:return False
                if hit(enemies[0],1.1*scale,2):ctl(enemies[0],'stun',1)
                state['grey']=dict(until=serial+1,value=0,effect=effect)
            case 'tahm_c':
                ally=self.ally(owner,500,'ratio',True) or owner
                if ally is not owner:self._reline(ally,owner['line'],max(0,min(self._LINE_POS,owner['pos']+(100 if self._team_number(owner)==1 else -100))),forced=True)
                self.shield(owner,ally,1.6);self._add_buff(ally,'purify',2,0);buff('taunt',2);buff('steel',2,.4*defense)
            case 'caitlyn_n':
                enemies=en(600)
                if not enemies:return False
                if hit(enemies[0],scale,1):self.mark(owner,enemies[0],'aim',2,scale)
                self._check_move(owner,False,250)
            case 'caitlyn_c':
                primary=self.marked_target(owner,'aim',1000,'farthest')
                if primary is None:return False
                target=primary
                for other in en(200,primary,-1,True,excluded=[primary]):
                    if primary['pos']<other['pos']<owner['pos'] if self._team_number(owner)==1 else owner['pos']<other['pos']<primary['pos']:
                        target=other;break
                buff('hitup',1,800*orange);marked=self.marked(owner,target,'aim')
                if hit(target,5 if marked else 4,1) and marked:self.state(target).pop(('mark','aim',state['index']),None)
            case 'kaelthas_n':
                enemies=en(600)
                if not enemies:return False
                target=enemies[0]
                if hit(target,.8*scale,2) and target['hp']>0 and not self._buff(target,'purify'):
                    self.state(target)[('bomb',state['index'])]=dict(owner=owner,until=self.state(target)['serial']+1,coefficient=1.2*scale,damage=damage,debuff=True)
            case 'kaelthas_c':
                enemies=en(700)
                if not enemies:return False
                for target in group(enemies[0],300,3):
                    key=('bomb',state['index']);bomb=self.state(target).get(key)
                    self.state(target)['bomb_consume_owner']=owner
                    landed=hit(target,4 if bomb else 2.2,2)
                    self.state(target).pop('bomb_consume_owner',None)
                    if landed and bomb:self.state(target).pop(key,None)
            case 'aoxing_n':
                enemies=en(650)
                if not enemies:return False
                primary=enemies[0];targets=[primary];marked=False
                for i in range(3):
                    if i:
                        enemies=en(300,primary,1,excluded=targets)
                        if not enemies:break
                        primary=enemies[0];targets.append(primary)
                    if hit(primary,(1.4 if i==0 else 1)*scale,2) and self.hero(primary):marked=True
                if marked:state['thunder']=min(3,state.get('thunder',0)+1)
            case 'aoxing_c':
                count=state.get('thunder',0);state['thunder']=0;largest=-1;targets=[]
                for lane in range(3):
                    found=self.candidates(owner,3-self._team_number(owner),lane,owner['pos'],self._LINE_POS,-1,True,'front')
                    if len(found)>largest:
                        largest=len(found);targets=self.candidates(owner,3-self._team_number(owner),lane,owner['pos'],self._LINE_POS,4,False,'front')
                stuns=0
                for target in targets:
                    if hit(target,1.8+.4*count,2) and count==3 and self.hero(target) and stuns<2:
                        stuns+=1;ctl(target,'stun',1)
        self.manual_casts[kind]=self.manual_casts.get(kind,0)+1
        return True

    def opponents(self, owner):
        return [u for u in (self.b if self._team_number(owner)==1 else self.a) if u.get('hp',0)>0]

    def add_purify_charges(self,owner,count):
        self._remove_all_debuff(owner)
        guard=self._buff(owner,'purify')
        count=max(count,int(guard.value) if guard else 0)
        self._remove_buff(owner,'purify')
        self._add_buff(owner,'purify',0,count)

    def _get_hit(self,owner):
        return super()._get_hit(owner)+int(self.state(owner).get('polar_cast_hit',0))

    def execute_santa_skin(self,owner,kind,skill):
        targets=(self.candidates(owner,3-self._team_number(owner),owner['line'],owner['pos'],self._LINE_POS,-1)
                 if kind=='santa_n' else self.opponents(owner))
        if not targets or owner.get('hp',0)<=0:return False
        if kind=='santa_n':
            state=self.state(owner)
            count=1+int(state.get('santa_kills',0))
            for _ in range(count):
                targets=self.candidates(owner,3-self._team_number(owner),owner['line'],owner['pos'],self._LINE_POS,-1)
                if not targets or owner.get('hp',0)<=0:break
                target=targets[int(self.rng.get_random(len(targets)))%len(targets)]
                self.hit(owner,target,float(skill['skills'][0][4]),2)
                state['santa_stacks']=state.get('santa_stacks',0)+1
        else:
            for target in targets:
                if self.hit(owner,target,.3,3) and target['hp']>0:self.control(owner,target,'stun',1)
        self.manual_casts[kind]=self.manual_casts.get(kind,0)+1
        return True

    def execute_nurse_skin(self,owner,kind,skill):
        if owner.get('hp',0)<=0:return False
        allies=[u for u in (self.a if self._team_number(owner)==1 else self.b) if u.get('hp',0)>0]
        if not allies:return False
        if kind=='nurse_n':
            for target in allies:self._add_buff(target,'purify',1)
            amount=_to_int(self._ap_with_talent(owner)*float(skill['skills'][0][4]))
            for target in allies:
                if target.get('hp',0)<=0:continue
                self._injured(target,amount,4,source=owner)
        else:
            # Select once; healing the first target must not retarget the second.
            primary=min(allies,key=lambda u:u['hp']/max(1,u['hp_max']))
            amount=_to_int(owner['hp_max']*.5)
            for target in (primary,owner):
                if owner.get('hp',0)<=0:break
                if target.get('hp',0)<=0:continue
                self._add_buff(target,'purify',1)
                self._add_buff(target,'bless',1)
                self._injured(target,amount,4,source=owner)
        self.manual_casts[kind]=self.manual_casts.get(kind,0)+1
        return True

    def _on_healing_received(self,target,amount,overheal=0):
        actions=(target.get('skillB') or {}).get('skills') or []
        if target.get('hp',0)<=0 or amount<=0 or not actions or actions[0][0]!='nurse_healing':return
        state=self.state(target);pending=state.setdefault('nurse_pending',[])
        overheal=max(0,min(amount,overheal))
        overflow_rate=float(actions[0][2]) if len(actions[0])>2 else 1.0
        pending.append(_to_int((amount-overheal)*float(actions[0][1])+overheal*overflow_rate))
        if state.get('nurse_busy'):return
        state['nurse_busy']=True
        try:
            while pending and target.get('hp',0)>0:
                raw=pending.pop(0)
                if raw<=0:continue
                with self.context(target,'passive'):
                    for victim in self.opponents(target):
                        if target.get('hp',0)<=0:break
                        # A fixed true amount: no AP coefficient, miss or crit.
                        amount=raw
                        attack=self._config.get('system_simple',{}).get('attack') or []
                        if len(attack)>21:
                            amount=_to_int(amount*float(attack[21]))
                            tough=max(0,self._get_tough(victim))
                            amount=_to_int(amount/(1+tough*float(attack[15])/(tough+float(attack[13]))))
                        amount=_to_int(amount*(1+self._talent(victim,16)))
                        self._event('nurse_retribution',target,victim,amount=amount)
                        self._injured(victim,amount,3,source=target)
        finally:
            state['nurse_busy']=False
            if target.get('hp',0)<=0:pending.clear()

    def queue_santa_kill(self,owner):
        actions=(owner.get('skillB') or {}).get('skills') or []
        if owner.get('hp',0)<=0 or not actions or actions[0][0]!='santa_kill':return
        state=self.state(owner)
        state['santa_stacks']=state.get('santa_stacks',0)+int(actions[0][1])
        state['santa_kills']=state.get('santa_kills',0)+int(actions[0][2])

    def execute_polar_skin(self,owner,kind,skill):
        if kind=='polar_n':
            targets=self.candidates(owner,3-self._team_number(owner),owner['line'],owner['pos'],self._LINE_POS,-1)
            if not targets:return False
            params=skill['skills'][0];self._add_buff(owner,'critup',1,float(params[4]))
            reduction=float(params[5])
            for target in targets:
                if self.hit(owner,target,float(params[6]),1) and target['hp']>0:
                    self.control(owner,target,'sunder',1,reduction/(1-reduction))
        else:
            targets=self.opponents(owner)
            if not targets:return False
            primary=max(targets,key=self._get_damage)
            targets=self.candidates(owner,3-self._team_number(owner),primary['line'],primary['pos'],300,-1)
            state=self.state(owner);old=state.get('polar_cast_hit',0);state['polar_cast_hit']=old+50000
            try:
                for target in targets:
                    if self.hit(owner,target,3,2) and target['hp']>0:
                        self.control(owner,target,'curse',1);self.control(owner,target,'stun',1)
            finally:state['polar_cast_hit']=old
        self.manual_casts[kind]=self.manual_casts.get(kind,0)+1
        return True

    def polar_basic_attack(self,owner):
        actions=(owner.get('skillB') or {}).get('skills') or []
        if owner.get('hp',0)<=0 or not actions or actions[0][0]!='polar_basic':return
        state=self.state(owner);current=self.round_index
        if 'polar_round' not in state:state.update(polar_round=current,polar_count=0,polar_basic=False)
        elapsed=current-state['polar_round']
        if elapsed>0:
            lost=elapsed-int(bool(state['polar_basic']))
            state.update(polar_count=max(0,state['polar_count']-lost),polar_round=current,polar_basic=False)
        policy=actions[0]
        if not state['polar_basic']:state['polar_count']=min(int(policy[2]),state['polar_count']+1)
        state['polar_basic']=True
        targets=self.candidates(owner,3-self._team_number(owner),owner['line'],owner['pos'],self._LINE_POS,-1)
        if not targets:return
        target=targets[int(self.rng.get_random(len(targets)))%len(targets)]
        with self.context(owner,'passive'):self.hit(owner,target,float(policy[1])*state['polar_count'],1)

    def execute_cat_skin(self,owner,kind,skill):
        ctx=self._context(owner)
        if not ctx or owner.get('hp',0)<=0:return False
        if kind=='cat_n':
            if self.state(owner).get('root'):return False
            targets=self.candidates(owner,3-self._team_number(owner),owner['line'],owner['pos'],self._LINE_POS,3,False,'front')
            if not targets:return False
            primary=targets[0];params=skill['skills'][0]
            self._add_buff(owner,'hitup',2,float(params[4]));self.dash(owner,primary)
            before=ctx.get('hp_damage',0)
            for target in targets:self.hit(owner,target,float(params[5]),3)
            self.hit(owner,primary,float(params[6]),3)
            dealt=ctx.get('hp_damage',0)-before
            if owner['hp']>0:self._injured(owner,_to_int(dealt*float(params[7])),4,source=owner)
        else:
            if not self.opponents(owner):return False
            self.add_purify_charges(owner,2);ctx.update(cat_capture=True,cat_crits=0)
            try:
                for _ in range(6):
                    for target in self.opponents(owner):self.hit(owner,target,.3,3)
            finally:ctx['cat_capture']=False
            if owner['hp']>0 and ctx['cat_crits']>0:self._add_buff(owner,'strong',2,.03*ctx['cat_crits'])
        self.manual_casts[kind]=self.manual_casts.get(kind,0)+1
        return True

    def queue_cat_skin_kill(self,owner):
        actions=(owner.get('skillB') or {}).get('skills') or []
        if owner.get('hp',0)<=0 or not actions or actions[0][0]!='cat_passive':return
        state=self.state(owner);round_index=self.round_index
        if state.get('cat_round')!=round_index:state.update(cat_round=round_index,cat_count=0,cat_pending=0)
        state['cat_pending']+=1
        if state.get('cat_busy'):return
        state['cat_busy']=True;policy=actions[0]
        try:
            while state['cat_pending']>0 and state['cat_count']<int(policy[3]) and owner['hp']>0:
                state['cat_pending']-=1;state['cat_count']+=1
                with self.context(owner,'passive'):
                    for _ in range(int(policy[2])):
                        targets=self.opponents(owner)
                        if not targets:break
                        target=targets[int(self.rng.get_random(len(targets)))]
                        self.hit(owner,target,float(policy[1]),3)
        finally:state.update(cat_busy=False,cat_pending=0)

    def _add_buff(self, unit, kind, rounds, value=0):
        ctx=self._context()
        if ctx and value and kind!='summon':value*=ctx['effect_factor']
        return super()._add_buff(unit,kind,rounds,value)

    def _remove_all_debuff(self, unit):
        super()._remove_all_debuff(unit)
        state=self.state(unit)
        for key,value in list(state.items()):
            if isinstance(value,dict) and value.get('debuff') is True:state.pop(key,None)

    def _remove_all_good(self, unit):
        super()._remove_all_good(unit)
        state=self.state(unit)
        for key,value in list(state.items()):
            if isinstance(value,dict) and value.get('debuff') is False:state.pop(key,None)

    def _injured(self, target, amount, damage_type=0, source=None, dot_kind=None):
        ctx=self._context(source) if source else None
        state=self.state(target);guard=state.get('guard')
        if ctx and ctx['kind'] in ('active','basic') and 1<=damage_type<=3 and guard and guard['charges']>0:
            ctx['guards'][id(target)]=target
            amount=_to_int(amount*(0 if guard['kind']=='kayle' else max(0,1-.55*guard.get('effect',1))))
        before=target.get('hp',0);shield_before=self._buff_value(target,'shield')
        dealt=super()._injured(target,amount,damage_type,source=source,dot_kind=dot_kind)
        taken=max(0,before-max(0,target.get('hp',0)))+max(0,shield_before-self._buff_value(target,'shield'))
        grey=state.get('grey')
        if grey and taken>0 and damage_type!=4:
            factor=grey['effect'];grey['value']=min(target['hp_max']*.2*factor,grey['value']+taken*.4*factor)
        if ctx and 1<=damage_type<=3:
            ctx['hp_damage']=ctx.get('hp_damage',0)+min(max(0,before),max(0,dealt))
            entry=ctx['targets'].setdefault(id(target),[target,0]);entry[1]+=taken
            if target['hp']<=0 and self.hero(target) and all(u is not target for u in ctx['kills']):ctx['kills'].append(target)
        if target.get('hp',0)<=0:self.death(target)
        if before>0 and target.get('hp',0)<=0 and source is not None and self._team_number(source)!=self._team_number(target):
            self.queue_cat_skin_kill(source)
            self.queue_santa_kill(source)
        return dealt

    def _native_damage(self, attacker, target, multiplier, damage_type, share=1):
        attack=self._config.get('system_simple',{}).get('attack')
        if not attack:
            self._ability_last_hit=True
            return super()._native_damage(attacker,target,multiplier*share,damage_type)
        hit=max(0,self._get_hit(attacker));flee=max(0,self._get_flee(target))
        action_type=(target.get('tpl') or [0,0])[1]
        if action_type!=3 and self.rng.get_random(100)<miss_chance(hit,flee,attack):
            self._ability_last_hit=False;return 0
        self._ability_last_hit=True
        critical=max(0,self._get_crit(attacker));tough=max(0,self._get_tough(target))
        crit=critical_multiplier(critical,attack) if self.rng.get_random(100)<crit_chance(critical,tough,attack) else 1
        ctx=self._context(attacker)
        if ctx and ctx.get('cat_capture') and crit>1:ctx['cat_crits']+=1
        row_a=self._config.get('avatar',{}).get(attacker.get('aid'),{});row_b=self._config.get('avatar',{}).get(target.get('aid'),{})
        sign_a=(row_a.get('tl') or [0,0,0])[0];sign_b=(row_b.get('tl') or [0,0,0])[0]
        raw=to_int(self._get_damage(attacker)*float(multiplier))
        amount=damage_before_final(raw,sign_a,sign_b,damage_type,self._get_de_ph(target),self._get_de_ma(target),attack,share)
        amount=to_int(to_int(amount*crit)*attack[21])
        amount=to_int(amount/(1+tough*attack[15]/(tough+attack[13])))
        result=self._injured(target,amount,damage_type,source=attacker)
        self._ability_last_hit=True
        return result

    def _basic_attack(self, attacker, target):
        with self.context(attacker,'basic'):
            before=target['hp'];damage_type=(attacker.get('tpl') or [0,1,1])[2]
            self._native_damage(attacker,target,1,damage_type)
            if self._ability_last_hit:self._book_attack_effects(attacker,target,max(0,before-target['hp']))
        self.polar_basic_attack(attacker)

    def _check_move(self, unit, forward, distance=0, forced=False):
        previous=unit['pos'];result=super()._check_move(unit,forward,distance,forced)
        if unit['pos']!=previous:self.state(unit).pop('channel',None)
        return result

    def _reline(self, unit, line, pos=None, offset=None, forced=False):
        previous=(unit['line'],unit['pos']);result=super()._reline(unit,line,pos,offset,forced)
        if (unit['line'],unit['pos'])!=previous:self.state(unit).pop('channel',None)
        return result

    def _get_speed(self, unit):
        value=super()._get_speed(unit)
        return _to_int(value*(1+self._buff_value(unit,'strong'))/(1+self._buff_value(unit,'weak')))

    def _apply_native_skill(self, attacker, enemies, slot='skill'):
        skill=attacker.get(slot)
        if not isinstance(skill,dict) or not skill.get('skills'):return False
        actions=skill['skills'];manual=[a for a in actions if a and a[0]=='manual_ability']
        row=self._config.get('skill',{}).get(skill.get('skid'),{})
        with self.context(attacker,'active',skill,self._factor(row.get('manualDamageMultiplier')) if manual else 1,
                          self._factor(row.get('manualEffectMultiplier')) if manual else 1):
            if manual:
                if len(actions)!=1:raise ValueError(f'Mixed manual action list needs explicit support: {skill.get("skid")}')
                result=self.execute(attacker,str(manual[0][1]),float(manual[0][2]),skill)
            else:result=super()._apply_native_skill(attacker,enemies,slot)
        if result and slot=='skill':attacker['_ability_normal_cast']=True
        return result

    def _use_skill_slot(self, attacker, enemies, slot, cd_key):
        attacker.pop('_ability_cd_override',None)
        result=super()._use_skill_slot(attacker,enemies,slot,cd_key)
        override=attacker.pop('_ability_cd_override',None)
        if result and override is not None:attacker[cd_key]=override
        return result

    def explode(self, target, bomb):
        owner=bomb['owner']
        if owner['hp']<=0:return
        with self.context(owner,'active',damage=bomb['damage']):
            targets=self.candidates(owner,3-self._team_number(owner),target['line'],target['pos'],250,4)
            if target['hp']>0 and all(u is not target for u in targets):targets=([target]+targets)[:4]
            for victim in targets:self.hit(owner,victim,bomb['coefficient'],2)

    def death(self, unit):
        state=self.state(unit)
        if state.get('death_handled'):return
        state['death_handled']=True
        for key,entry in list(state.items()):
            if not isinstance(key,tuple):continue
            if key[0]=='bomb':
                state.pop(key,None)
                if state.get('bomb_consume_owner') is not entry['owner']:self.explode(unit,entry)
            elif key[0]=='malz' and entry['hops']==0 and entry['ticks']>0:
                state.pop(key,None);owner=entry['owner']
                targets=self.candidates(owner,self._team_number(unit),unit['line'],unit['pos'],300,1,excluded=[unit])
                if targets:
                    entry['hops']=1;entry['until']=self.state(targets[0])['serial']+1
                    self.state(targets[0])[key]=entry

    def turn_start(self, owner):
        state=self.state(owner);state['serial']+=1;serial=state['serial']
        for key,entry in list(state.items()):
            if not isinstance(entry,dict):continue
            if isinstance(key,tuple) and key[0]=='bomb' and serial>=entry['until']:
                state.pop(key,None);self.explode(owner,entry)
            elif isinstance(key,tuple) and key[0]=='malz' and serial>=entry['until']:
                entry['ticks']-=1;entry['until']=serial+1
                self._injured(owner,int(entry['tick_damage']),6,source=entry['owner'],dot_kind='phantasm')
                if owner['hp']<=0:return True
                if entry['ticks']<=0:state.pop(key,None)
            elif key=='grey' and serial>=entry['until']:
                state.pop(key,None)
                if owner['hp']>0 and entry['value']>0:self._add_buff(owner,'shield',2,int(entry['value']))
            elif 'until' in entry and serial>entry['until']:state.pop(key,None)
        zone=state.get('zone')
        if zone and owner['hp']>0:
            with self.context(owner,'active',damage=zone['damage'],effect=zone['effect']):
                for target in self.candidates(owner,3-self._team_number(owner),zone['line'],zone['pos'],350,3):
                    if self.hit(owner,target,1.2,1):self.control(owner,target,'weak',1,.2)
            zone['left']-=1
            if zone['left']<=0:state.pop('zone',None)
        channel=state.pop('channel',None)
        if channel and owner['hp']>0 and not self._buff(owner,'stun') and not self._buff(owner,'silence') and owner['pos']==channel['pos'] and owner['line']==channel['line']:
            with self.context(owner,'active',damage=channel['damage'],effect=channel['effect']):
                for target in self.enemies(owner,400,maximum=3):
                    if self.hit(owner,target,3.6,2):self.control(owner,target,'weak',2,.3)
            return True
        return owner['hp']<=0

    def _run_unit_turn(self, attacker, sides, side):
        attacker['_team']=sides[side]
        self._resolve_pending_strike(attacker)
        if attacker['hp']<=0:return True
        enemies=self.opponents(attacker)
        if not enemies:return False
        for cd in ('_skill_cd','_skill_cd_b','_skill_cd_leader','_skill_cd_book'):self._tick_slot_cd(attacker,cd)
        self._use_turn_start_passive(attacker,enemies)
        if attacker['hp']<=0 or self.turn_start(attacker) or self._tick_buffs(attacker) or attacker['hp']<=0:return True
        if self._buff(attacker,'stun'):return True
        enemies=self.opponents(attacker)
        if not enemies:return False
        focus=attacker.get('_ability_focus')
        target=focus if focus and focus.get('hp',0)>0 else min(enemies,key=lambda u:(u['line']!=attacker['line'],abs(u['pos']-attacker['pos']),self.state(u)['index']))
        # Close into the actual native attack/cast range before trying melee
        # abilities. The old study attacked across the map without moving.
        if target['line']!=attacker['line']:self._reline(attacker,target['line'],attacker['pos'])
        action_type=(attacker.get('tpl') or [0,1])[1]
        if abs(target['pos']-attacker['pos'])>self._get_range(attacker) and action_type!=3:
            self._check_move(attacker,True)
        acted=False
        if not self._buff(attacker,'silence'):
            for slot,cd in (('book_skill','_skill_cd_book'),('skill','_skill_cd')):
                acted=self._use_skill_slot(attacker,enemies,slot,cd) or acted
        if attacker.get('leader'):acted=self._use_skill_slot(attacker,enemies,'leader_skill','_skill_cd_leader') or acted
        if not acted and target.get('hp',0)>0 and abs(target['pos']-attacker['pos'])<=self._get_range(attacker):
            self._basic_attack(attacker,target)
        return True
