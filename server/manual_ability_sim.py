"""Skill-complete study engine for Avatar.executeAbility and its state hooks.

The named abilities follow the recovered client formulas. Rendering is absent;
the underlying ReferenceBattle remains an offline model, not the AIR runtime.
"""
from __future__ import annotations

import math
from contextlib import contextmanager

from attack_range_105 import MIN_ATTACK_RANGE
from battle_engine import ReferenceBattle, _to_int
from demonblade_tryndamere_sim import DemonTryndBattleMixin
from dragonmancer_kaisa_sim import KaisaBattleMixin
from nightbringer_yasuo_sim import YasuoBattleMixin
from combat_math import damage_before_final, to_int
from combat_rules import ratio_enabled
from six_star_battle_105 import SixStarBattleMixin, passive_kind
from six_star_followup_battle_105 import IRELIA_IMMUNITIES


KINDS = frozenset(f'{hero}_{slot}' for hero in (
    'illaoi','jayce','nidalee','kayle','maokai','wukong','gangplank','yi','veigar',
    'elise','riven','orianna','nunu','alistar','diana','khazix','malzahar','jinx',
    'tahm','caitlyn','kaelthas','karthus','aoxing') for slot in ('n','c'))


class SkillCompleteBattle(DemonTryndBattleMixin, SixStarBattleMixin, YasuoBattleMixin, KaisaBattleMixin, ReferenceBattle):
    def __init__(self, *args, trace_abilities=False, **kwargs):
        super().__init__(*args, **kwargs)
        self.ability_contexts=[]
        self.ability_events=[] if trace_abilities else None
        self.manual_casts={}
        self._ability_next=0
        self._kaisa_lane_sides={lane:{self._team_number(u) for u in self.a+self.b if u.get('line')==lane}
                               for lane in {u.get('line') for u in self.a+self.b}}
        self._kaisa_closed_lanes=set()
        for roster in (self.a,self.b):
            for unit in roster:
                # Combat-only Kai'Sa counters never survive a fresh battle.
                for key in tuple(unit):
                    if key.startswith(('_kaisa_', '_yasuo_')):unit.pop(key,None)
                for key in tuple(unit.get('_buffs',{})):
                    if key.startswith('yasuoShield104_'):unit['_buffs'].pop(key,None)
                unit['_team']=roster
                tpl=unit.get('tpl') or []
                if len(tpl)>3:unit.setdefault('speed',tpl[3])
                self.state(unit)
                if self.yasuo_passive(unit):unit['_yasuo_crit_bonus']=self._get_crit(unit)

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
        if target.get('hp',0)>0 and not self._status_immune(target):
            self.state(target)[('mark',mark,self.state(owner)['index'])]=dict(until=self.state(target)['serial']+duration,owner=owner,debuff=True,scale=scale)
            self._status_received(target,'mark')

    def marked_target(self, owner, mark, distance, order='nearest'):
        ctx=self._context(owner)
        if ctx and ctx.get('skill'):distance=self._get_cast_range(owner,ctx['skill'])
        units=self.candidates(owner,3-self._team_number(owner),owner['line'],owner['pos'],distance,-1,True,order)
        return next((u for u in units if self.marked(owner,u,mark)),units[0] if units else None)

    def hero_output_rate_104(self, owner):
        from equipment_bonds_104 import output_rate
        return float(self._config.get('system_simple',{}).get('hero_skill_output_rate_104',1))*output_rate(self._config,owner.get('aid'),owner.get('equipment_bonds_104')) if str(owner.get('aid','')).startswith('A_1') else 1.0

    def hit(self, owner, target, coefficient, damage_type, shared_total=0):
        if not target or target.get('hp',0)<=0 or owner.get('hp',0)<=0:return False
        ctx=self._context(owner);factor=ctx['damage_factor'] if ctx else 1
        factor*=self.hero_output_rate_104(owner)
        coefficient*=factor
        self._event('hit',owner,target,coefficient=coefficient,damage_type=damage_type)
        # Manual true skills cancel the native rate and apply the opt-in correction.
        if damage_type==3:coefficient=self._true_skill_coefficient(coefficient)
        total=shared_total*factor if shared_total>0 else coefficient
        self._native_damage(owner,target,total,damage_type,coefficient/total if total else 1)
        return self._ability_last_hit

    def heal(self, owner, target, coefficient):
        if target and target.get('hp',0)>0:
            ctx=self._context(owner);factor=ctx['effect_factor'] if ctx else 1
            self._event('heal',owner,target,coefficient=coefficient*factor)
            amount=_to_int(self._heal_channel_value(owner,coefficient*self.hero_output_rate_104(owner))*factor)
            self._injured(target,amount,4,source=owner)

    def shield(self, owner, target, coefficient, duration=2, health=False):
        if target and target.get('hp',0)>0:
            ctx=self._context(owner);factor=ctx['effect_factor'] if ctx else 1
            amount=_to_int((self._get_hp(owner) if health else self._get_damage(owner)+self._get_hp(owner)*.1)*coefficient*self.hero_output_rate_104(owner))
            self._event('shield',owner,target,amount=amount,duration=duration)
            self._add_buff(target,'shield',duration,amount,source=owner if ratio_enabled(self._combat_rules) else None)

    @staticmethod
    def _get_hp(owner):return owner.get('hp_max',1)

    def control(self, owner, target, kind, duration, value=0):
        if not target or target.get('hp',0)<=0:return
        if self.state(target).get('channel') and kind in ('stun','silence','root','pull','push'):return
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
        ctx=self._context(owner)
        if (clone and key == 'wukong' and ctx and
                self.six_star_row(ctx.get('skill')).get('sixStarClone105')):
            ratio = self.equipment_part(ctx['skill'], 'wukong_clone_panel', 1)
        else:
            ratio *= ctx['effect_factor'] if ctx else 1
        state=self.state(owner)
        for old in state.get('summons_'+key,[]):old['hp']=0;self.death(old)
        units=[]
        team=self._team_number(owner)
        for i in range(count):
            unit=self._spawn_summon(owner,owner['aid'] if clone else aid,ratio,turns)
            if unit is None:raise ValueError(f'Missing manual summon template: {aid}')
            unit.update(skill=None,leader_skill=None,book_skill=None,skillB=None)
            unit.update(speed=220,range=MIN_ATTACK_RANGE,manualActionTypeOverride=1)
            unit['pos']=self._get_final_pos(team,unit['line'],owner['pos']+(-1 if team==1 else 1)*(125+100*i))
            if clone:self._add_buff(unit,'taunt',1,0)
            if focus:unit['_ability_focus']=focus
            self.state(unit);units.append(unit)
        state['summons_'+key]=units

    def _get_damage(self, unit):
        value=_to_int(super()._get_damage(unit)*(1+self._get_manual_battle_stack(unit,'attack')+self._get_manual_timed_stack(unit,'attack')))
        state=self.state(unit)
        value=max(0,value+_to_int(state['entry_ap']*state.get('evil_bonus',0)))
        passive=(unit.get('skillB') or {}).get('skills',[])
        stack_rate=float(passive[0][3]) if passive and passive[0][0]=='santa_kill' else .05
        return self.yasuo_attack(unit, _to_int(value*(1+stack_rate*state.get('santa_stacks',0))))

    def _get_de_ph(self, unit, ignore_sunder=False):
        base=dict(unit,de_ph=self.six_reaction_defense(unit,'de_ph'))
        return super()._get_de_ph(base,ignore_sunder)

    def _get_de_ma(self, unit, ignore_sunder=False):
        base=dict(unit,de_ma=self.six_reaction_defense(unit,'de_ma'))
        return super()._get_de_ma(base,ignore_sunder)

    def _summon_panel_snapshot(self, owner):
        result=dict(hp_max=self._get_hp(owner),ap=self._ap_with_talent(owner),
                    de_ph=self._get_de_ph(owner),de_ma=self._get_de_ma(owner))
        for key in ('hit','flee','crit','tough'):
            result[key]=self._stat_buff(owner,key)+(int(self._get_manual_battle_stack(owner,'flee')) if key=='flee' else 0)
        return result

    def equipment_part(self, skill, part, value):
        row=self._config.get('skill',{}).get(skill.get('skid'),{})
        return value*float(row.get('equipment_parts_104',{}).get(part,1))

    def execute(self, owner, kind, scale, skill):
        if kind.startswith('six_'):return self.six_star_execute(owner,kind,skill)
        row=self.six_star_row(skill)
        if row.get('sixStarNextBaronLane105'):
            return self.six_next_execute(owner,'six_next_baron_n',skill)
        if row.get('sixStarNextBaronDrain105'):
            return self.six_next_execute(owner,'six_next_baron_c',skill)
        if kind in ('skin2_1206_0', 'skin2_1206_1') and self.six_star_row(skill).get('sixStarBatchRear105'):
            return self.six_batch_vayne(owner, kind, skill)
        if kind.startswith('dragon_kaisa_'):return self.execute_kaisa(owner,kind,skill)
        if kind.startswith('night_yasuo_'):return self.execute_yasuo(owner,kind,skill)
        if kind.startswith('demon_trynd_'):return self.execute_demon(owner,kind,skill)
        if kind in ('cat_n','cat_c'):return self.execute_cat_skin(owner,kind,skill)
        if kind in ('polar_n','polar_c'):return self.execute_polar_skin(owner,kind,skill)
        if kind in ('santa_n','santa_c'):return self.execute_santa_skin(owner,kind,skill)
        if kind in ('nurse_n','nurse_c'):return self.execute_nurse_skin(owner,kind,skill)
        if kind not in KINDS:raise ValueError(f'Unsupported client manual ability: {kind}')
        state=self.state(owner);serial=state['serial']
        ctx=self._context(owner);damage=ctx['damage_factor'];effect=ctx['effect_factor']
        row=self._config['skill'].get(skill.get('skid'),{})
        defense=self._factor(skill.get('nativeSettings104',{}).get('manualDefenseBuffMultiplier',row.get('manualDefenseBuffMultiplier')))
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
                    if hit(target,self.equipment_part(skill,'tentacle_hit',1.2)*scale,1) and self.hero(target):count+=1
                if count:self.heal(owner,owner,self.equipment_part(skill,'tentacle_heal',.15)*min(3,count)*scale)
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
                    if hit(primary,self.equipment_part(skill,'hammer_hit',1.8)*scale,1):self._check_move(primary,False,200,True)
                    self.shield(owner,owner,self.equipment_part(skill,'hammer_shield',.5)*scale)
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
                if hit(target,self.equipment_part(skill,'spear',coefficient),2):self.mark(owner,target,'hunt',3)
            case 'nidalee_c':
                self.heal(owner,self.ally(owner),self.equipment_part(skill,'primal_heal',.7));target=self.marked_target(owner,'hunt',700)
                if target and self.dash(owner,target):
                    marked=self.marked(owner,target,'hunt')
                    if hit(target,3.2 if marked else 2.2,2) and marked:self.state(target).pop(('mark','hunt',state['index']),None)
            case 'kayle_n':
                enemies=en(500)
                if enemies and hit(enemies[0],self.equipment_part(skill,'holy_hit',1.2)*scale,2):ctl(enemies[0],'sunder',2,.2*scale)
                self.heal(owner,self.ally(owner),self.equipment_part(skill,'holy_heal',.45)*scale)
            case 'kayle_c':
                target=self.ally(owner,600)
                if target is None:return False
                self.state(target)['guard']=dict(kind='kayle',charges=1,until=self.state(target)['serial']+2,owner=owner,damage=damage,debuff=False)
            case 'maokai_n':
                enemies=en(500)
                if not enemies or not self.dash(owner,enemies[0]):return False
                if hit(enemies[0],scale,2):ctl(enemies[0],'root',1)
                state['sap']=dict(until=serial+2,effect=self.equipment_part(skill,'sap_heal',effect),debuff=False)
            case 'maokai_c':
                for target in en(700,maximum=3,forward=True):
                    if hit(target,1.8,2):ctl(target,'root',2)
                self.shield(owner,owner,self.equipment_part(skill,'root_shield',.2),2,True)
            case 'wukong_n':
                enemies=en(175)
                if not enemies:return False
                if hit(enemies[0],self.equipment_part(skill,'wukong_hit',1.4)*scale,1):ctl(enemies[0],'sunder',2,.25*scale)
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
                if marked:
                    self._remove_all_debuff(owner)
                    self.heal(owner,owner,self.equipment_part(skill,'orange_heal_ap',.4)*scale)
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
                if not row.get('reviewFleeQuality104'):buff('fleeup',1,600*scale*orange)
            case 'yi_c':
                buff('strong',3,.5);buff('hitup',3,800*orange);self._remove_buff(owner,'weak')
                state['highlander']=dict(until=serial+3,left=2,debuff=False)
                if owner.get('skill'):self._apply_native_skill(owner,self.opponents(owner),'skill')
            case 'veigar_n':
                expanded=row.get('sixStarVeigar105')
                enemies=self.six_star_lane(owner,front=True)[:2] if expanded else en(600)
                if not enemies:return False
                grew=False
                for target in enemies:
                    if hit(target,1.2*scale,2) and self.hero(target):
                        grew=True
                if grew:
                    old=state.get('evil_stacks',0);state['evil_stacks']=min(10,old+1)
                    base=.07 if expanded else .03*effect
                    if state['evil_stacks']>old:state['evil_bonus']=state.get('evil_bonus',0)+self.equipment_part(skill,'evil_stack',base)
            case 'veigar_c':
                enemies=en(700,hero=True,order='ratio') or en(700)
                if not enemies:return False
                target=enemies[0];old=state.get('veigar_cast_hit',0);state['veigar_cast_hit']=old+30000*float(skill.get('nativeSettings104',{}).get('manualFixedScale104',1))
                try:hit(target,2+self.equipment_part(skill,'execution',3)*(1-target['hp']/target['hp_max']),2)
                finally:state['veigar_cast_hit']=old
            case 'elise_n':
                enemies=en(600)
                if not enemies:return False
                target=enemies[0];ap=self._get_damage(owner)
                coef=scale+min(ap,target['hp']*self.equipment_part(skill,'current_hp',.04)*scale)/max(1,ap)
                if hit(target,coef,2):ctl(target,'stun',1)
            case 'elise_c':
                enemies=en(650,hero=True,order='ratio')
                if not enemies or not self.dash(owner,enemies[0]):return False
                target=enemies[0];ap=self._get_damage(owner)
                hit(target,1.8+min(ap*1.8,(target['hp_max']-target['hp'])*self.equipment_part(skill,'venom_execute',.12))/max(1,ap),2)
                self.summon(owner,'A_2013_5',2,.3,2,'elise')
            case 'riven_n':
                enemies=en(450)
                if not enemies or not self.dash(owner,enemies[0]):return False
                primary=enemies[0];count=state.get('riven_step',0)%3+1;state['riven_step']=count%3
                for target in group(primary,200,2):
                    if hit(target,(self.equipment_part(skill,'third_dance',1.4) if count==3 else .8)*scale,1) and count==3:ctl(target,'stun',1)
                if count==2:self.shield(owner,owner,self.equipment_part(skill,'second_shield',.6)*scale)
            case 'riven_c':
                buff('strong',2,.35)
                for target in en(700,maximum=3,forward=True):hit(target,1.6+.96*(1-target['hp']/target['hp_max']),1)
                state['riven_step']=2
            case 'orianna_n':
                target=self.ally(owner,3001,'front',True) or owner;state['ball']=target
                self.shield(owner,target,self.equipment_part(skill,'ball_shield',.8)*scale)
                for enemy in en(300,target,2):hit(enemy,scale,2)
            case 'orianna_c':
                ally=state.get('ball')
                if not ally or ally['hp']<=0 or ally['line']!=owner['line']:ally=owner
                state['ball']=ally
                for target in en(350,ally,3):
                    self._check_move(target,True,200,True)
                    if hit(target,self.equipment_part(skill,'shockwave',2.2),2):ctl(target,'stun',1)
                self.shield(owner,ally,.8)
            case 'nunu_n':
                enemies=en(175)
                if not enemies:return False
                target=enemies[0];summoned=bool(target.get('summon_owner'))
                hit(target,(3 if summoned else 1.4)*scale,3 if summoned else 2)
                self.heal(owner,owner,self.equipment_part(skill,'consume_heal',.7)*scale)
            case 'nunu_c':
                self.shield(owner,owner,self.equipment_part(skill,'channel_shield',1.2))
                state['channel']=dict(pos=owner['pos'],line=owner['line'],damage=damage,effect=effect)
            case 'alistar_n':
                enemies=en(500)
                if not enemies or not self.dash(owner,enemies[0]):return False
                primary=enemies[0];targets=group(primary,250,3)
                hit(primary,.8*scale,2,1.4*scale)
                for target in targets:
                    if hit(target,self.equipment_part(skill,'pulverize',.6)*scale,2,1.4*scale if target is primary else 0):ctl(target,'stun',1)
                buff('taunt',2)
            case 'alistar_c':
                self._remove_all_debuff(owner);self.heal(owner,owner,self.equipment_part(skill,'will_heal',.5))
                state['alistar_guard104']=dict(until=serial,reduction=.8*float(skill.get('nativeSettings104',{}).get('manualFixedScale104',1)),debuff=False)
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
                    if hit(target,self.equipment_part(skill,'moon_mark',2.7) if marked else 1.8,2) and marked:self.state(target).pop(('mark','moon',state['index']),None)
                self.shield(owner,owner,self.equipment_part(skill,'moon_shield',1))
            case 'khazix_n':
                enemies=en(500)
                if not enemies or not self.dash(owner,enemies[0]):return False
                hit(enemies[0],(self.equipment_part(skill,'isolated_hit',2.4) if self.isolated(enemies[0]) else 1.6)*scale,1)
            case 'khazix_c':
                enemies=en(700,maximum=-1,hero=True)
                primary=next((u for u in enemies if self.isolated(u)),enemies[0] if enemies else None)
                if primary is None or not self.dash(owner,primary,True):return False
                hit(primary,4.2 if self.isolated(primary) else 2.8,1);buff('fleeup',2,self.equipment_part(skill,'escape_dodge',800)*orange)
                if primary['hp']<=0 and self.hero(primary):owner['_ability_cd_override']=3
            case 'malzahar_n':
                enemies=en(600)
                if not enemies:return False
                target=enemies[0]
                if self._status_immune(target):pass
                else:
                    self.state(target)[('malz',state['index'])]=dict(owner=owner,until=self.state(target)['serial']+1,ticks=3,tick_damage=self._get_damage(owner)*scale*damage*self.hero_output_rate_104(owner),hops=0,debuff=True)
                    self._status_received(target,'poison')
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
                for target in en(250,primary,2,excluded=[primary]):hit(target,self.equipment_part(skill,'rocket_splash',1.1)*scale,1)
            case 'jinx_c':
                enemies=en(1000,hero=True,order='ratio')
                if not enemies:return False
                primary=enemies[0];targets=en(300,primary,2,excluded=[primary]);ap=self._get_damage(owner)
                hit(primary,2+min(2*ap,(primary['hp_max']-primary['hp'])*self.equipment_part(skill,'missing_hp',.12))/max(1,ap),1)
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
                if hit(enemies[0],self.equipment_part(skill,'net_hit',scale),1):self.mark(owner,enemies[0],'aim',2,scale)
                self._check_move(owner,False,250)
            case 'caitlyn_c':
                primary=self.marked_target(owner,'aim',1000,'farthest')
                if primary is None:return False
                target=primary
                for other in en(200,primary,-1,True,excluded=[primary]):
                    if primary['pos']<other['pos']<owner['pos'] if self._team_number(owner)==1 else owner['pos']<other['pos']<primary['pos']:
                        target=other;break
                buff('hitup',1,800*orange);marked=self.marked(owner,target,'aim')
                if hit(target,self.equipment_part(skill,'marked_shot',5) if marked else 4,1) and marked:self.state(target).pop(('mark','aim',state['index']),None)
            case 'karthus_n':
                enemies=en(600)
                if not enemies:return False
                targets=group(enemies[0],200,2)
                factor=self.equipment_part(skill,'isolated_hit',2) if len(targets)==1 else 1
                for target in targets:hit(target,.875*scale*factor,2)
            case 'karthus_c':
                for target in list(self.opponents(owner)):
                    bonus=self.equipment_part(skill,'requiem_finish',.4) if target['hp']<target['hp_max']*.4 else 0
                    hit(target,2.75*(1+bonus),2)
            case 'kaelthas_n':
                enemies=en(600)
                if not enemies:return False
                target=enemies[0]
                if hit(target,.8*scale,2) and target['hp']>0 and not self._status_immune(target):
                    self.state(target)[('bomb',state['index'])]=dict(owner=owner,until=self.state(target)['serial']+1,coefficient=self.equipment_part(skill,'bomb_burst',1.2)*scale,damage=damage,debuff=True)
                    self._status_received(target,'bomb')
            case 'kaelthas_c':
                enemies=en(700)
                if not enemies:return False
                for target in group(enemies[0],300,3):
                    key=('bomb',state['index']);bomb=self.state(target).get(key)
                    self.state(target)['bomb_consume_owner']=owner
                    landed=hit(target,self.equipment_part(skill,'consume_bomb',4) if bomb else 2.2,2)
                    self.state(target).pop('bomb_consume_owner',None)
                    if landed and bomb:self.state(target).pop(key,None)
            case 'aoxing_n':
                if not self.opponents(owner):return False
                marked=self.aoxing_chain(owner,1.4*scale,self.equipment_part(skill,'lightning_bounce',1)*scale,lambda target,ratio:hit(target,ratio,2))
                if marked:state['thunder']=min(3,state.get('thunder',0)+1)
            case 'aoxing_c':
                count=state.get('thunder',0);state['thunder']=0;largest=-1;targets=[]
                for lane in range(3):
                    found=self.candidates(owner,3-self._team_number(owner),lane,owner['pos'],self._LINE_POS,-1,True,'front')
                    if len(found)>largest:
                        largest=len(found);targets=self.candidates(owner,3-self._team_number(owner),lane,owner['pos'],self._LINE_POS,4,False,'front')
                stuns=0
                for target in targets:
                    if hit(target,1.8+self.equipment_part(skill,'storm_charge',.4)*count,2) and count==3 and self.hero(target) and stuns<2:
                        stuns+=1;ctl(target,'stun',1)
        self.manual_casts[kind]=self.manual_casts.get(kind,0)+1
        return True

    def opponents(self, owner):
        return [u for u in (self.b if self._team_number(owner)==1 else self.a) if u.get('hp',0)>0]

    def add_purify_charges(self,owner,count):
        # Ordinary purify layers: each cancels one held debuff, the rest stack.
        if count>=1 and owner.get('hp',0)>0:self._add_buff(owner,'purify',0,count)

    def _get_hit(self,owner):
        state = self.state(owner)
        return super()._get_hit(owner)+int(state.get('polar_cast_hit',0))+int(state.get('veigar_cast_hit',0))+state.get('batch_kayle_hit',0)

    def execute_santa_skin(self,owner,kind,skill):
        targets=(self.candidates(owner,3-self._team_number(owner),owner['line'],owner['pos'],self._LINE_POS,-1)
                 if kind=='santa_n' else self.opponents(owner))
        if not targets or owner.get('hp',0)<=0:return False
        if kind=='santa_n':
            state=self.state(owner)
            count=1+int(state.get('santa_kills',0))//2
            for _ in range(count):
                targets=self.candidates(owner,3-self._team_number(owner),owner['line'],owner['pos'],self._LINE_POS,-1)
                if not targets or owner.get('hp',0)<=0:break
                target=targets[int(self.rng.get_random(len(targets)))%len(targets)]
                self.hit(owner,target,float(skill['skills'][0][4]),2)
                state['santa_stacks']=state.get('santa_stacks',0)+1
        else:
            state=self.state(owner);old=state.get('veigar_cast_hit',0);state['veigar_cast_hit']=old+10000*float(skill.get('nativeSettings104',{}).get('manualFixedScale104',1))
            try:
                for target in targets:
                    if self.hit(owner,target,.3,3) and target['hp']>0:self.control(owner,target,'stun',1)
            finally:state['veigar_cast_hit']=old
        self.manual_casts[kind]=self.manual_casts.get(kind,0)+1
        return True

    def execute_nurse_skin(self,owner,kind,skill):
        if owner.get('hp',0)<=0:return False
        allies=[u for u in (self.a if self._team_number(owner)==1 else self.b) if u.get('hp',0)>0]
        if not allies:return False
        row=self._config.get('skill',{}).get(skill.get('skid'),{})
        rate=self._factor(skill.get('nativeSettings104',{}).get('manualEffectMultiplier',row.get('manualEffectMultiplier')))
        if kind=='nurse_n':
            for target in allies:self._add_buff(target,'purify',1)
            amount=_to_int(self._ap_with_talent(owner)*float(skill['skills'][0][4])*rate*self.hero_output_rate_104(owner))
            for target in allies:
                if target.get('hp',0)<=0:continue
                self._injured(target,amount,4,source=owner)
        else:
            # Select once; healing the first target must not retarget the second.
            primary=min(allies,key=lambda u:u['hp']/max(1,u['hp_max']))
            amount=_to_int(owner['hp_max']*.5*rate*self.hero_output_rate_104(owner))
            for target in (primary,owner):
                if owner.get('hp',0)<=0:break
                if target.get('hp',0)<=0:continue
                self._add_buff(target,'purify',1)
                self._add_buff(target,'bless',1)
                self._injured(target,amount,4,source=owner)
        self.manual_casts[kind]=self.manual_casts.get(kind,0)+1
        return True

    def _on_healing_received(self,target,amount,overheal=0):
        if getattr(self,'_equip_origin',None)=='relic_lifesteal':return
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
                        if victim['line']!=target['line']:continue
                        if target.get('hp',0)<=0:break
                        # Fixed true damage: no AP coefficient, miss or crit.
                        amount=self._fixed_true_amount(victim,raw)
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
            params=skill['skills'][0]
            if params[4]>0:self._add_buff(owner,'critup',1,float(params[4]))
            reduction=float(params[5])
            for target in targets:
                if self.hit(owner,target,float(params[6]),1) and target['hp']>0:
                    self.control(owner,target,'sunder',1,reduction/(1-reduction))
        else:
            targets=self.opponents(owner)
            if not targets:return False
            primary=max(targets,key=self._get_damage)
            targets=self.candidates(owner,3-self._team_number(owner),primary['line'],primary['pos'],300,-1)
            state=self.state(owner);old=state.get('polar_cast_hit',0);state['polar_cast_hit']=old+50000*float(skill.get('nativeSettings104',{}).get('manualFixedScale104',1))
            try:
                for target in targets:
                    if self.hit(owner,target,3,2) and target['hp']>0:
                        self.control(owner,target,'curse',1)
                        self.control(owner,target,'stun',self.six_star_row(skill).get('sixStarPolarStun105',1))
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
            if owner['hp']>0:self._injured(owner,_to_int(dealt*float(params[7])*self.hero_output_rate_104(owner)),4,source=owner)
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

    def _add_buff(self, unit, kind, rounds, value=0, source=None, poison_hp_rate_104=1):
        state=self.state(unit)
        if self.yasuo_immune(unit,kind) or kind=='weak' and state.get('highlander'):return
        if kind in IRELIA_IMMUNITIES and state.get('six_irelia_immune'):return
        if self.state(unit).get("channel") and kind in ("stun","silence","root","pull","push"):return
        ctx=self._context()
        old_stun = self._buff(unit, 'stun') if kind == 'stun' else None
        old_burn = self._buff(unit, 'burn') if kind == 'burn' else None
        burn_layers = old_burn.layers if old_burn else 0
        relic_shield=kind=='shield' and getattr(self,'_equip_origin',None)=='relic_shield'
        # Purify layers and curse charges are counts, not scaled amounts.
        if ctx and value and kind not in ('summon','purify','curse') and not relic_shield:value*=ctx['effect_factor']
        result=super()._add_buff(unit,kind,rounds,value,source=source if source is not None else (ctx['owner'] if ctx else None),poison_hp_rate_104=poison_hp_rate_104)
        if kind in ('stun','silence') and self._buff(unit,kind):
            self.six_next_interrupt(unit)
        if kind=='stun' and self._buff(unit,'stun'):
            self.kaisa_stun(unit)
            self.six_star_stun_applied(unit)
            if self._buff(unit, 'stun') is not old_stun:
                self.six_reaction_stun(unit)
                self.six_next_stun(unit)
        if kind == 'burn':
            burn = self._buff(unit, 'burn')
            if burn and burn.layers > burn_layers:
                self.six_reaction_burn_changed(unit)
        return result

    def _status_received(self, target, kind):
        super()._status_received(target, kind)
        if kind == 'burn':
            self.six_reaction_burn_changed(target)

    def _emit_mod_event(self, owner, event, source=None, target=None, amount=0, overheal=0):
        if owner is not None:
            if event == 'death':
                self.six_batch_notify_death(owner, source)
            if event == 'damage_taken':
                self.six_reaction_taken(owner, amount)
            if event == 'hit' and target is not None:
                self.six_batch_vayne_event(owner, event, target)
            if event == 'crit' and self.six_batch_passive(owner, 'yasuo'):
                self._tick_slot_cd(owner, '_skill_cd_b')
            if event == 'kill':self.six_star_extend_yi(owner)
            self.six_next_event(owner,event,target)
            self.six_star_event(owner,event,target,amount,overheal)
            self.six_followup_event(owner,event,target,source,overheal)
        self.yasuo_event(owner,event,source,target,amount)
        self.kaisa_event(owner,event,source,target)
        self.demon_event(owner,event,source,target)
        return super()._emit_mod_event(owner,event,source,target,amount,overheal)

    def _tick_slot_cd(self, owner, key):
        super()._tick_slot_cd(owner,key)
        if key=='_skill_cd_leader':self.kaisa_try_hunt(owner)

    def _remove_buff(self, unit, kind, consume=False, clear_shields=True, clear_relic_dots=True):
        purify=self._buff(unit,'purify') if kind=='purify' else None
        if kind=='root':self.state(unit).pop('root',None)
        super()._remove_buff(unit, kind, consume, clear_shields, clear_relic_dots)
        if purify and not self._buff(unit,'purify') and (passive:=self.six_next_passive(unit,'sivir')):
            self.six_next_heal(unit,unit['hp_max']*passive[5])

    def _curse_applied(self, unit):
        super()._curse_applied(unit)
        self.six_batch_curse(unit)

    def _clear_other_debuffs(self, unit):
        super()._clear_other_debuffs(unit)
        state=self.state(unit)
        for key,value in list(state.items()):
            if isinstance(value,dict) and value.get('debuff') is True:state.pop(key,None)

    def _remove_all_good(self, unit):
        super()._remove_all_good(unit)
        state=self.state(unit)
        for key,value in list(state.items()):
            if isinstance(value,dict) and value.get('debuff') is False:state.pop(key,None)

    def _injured(self, target, amount, damage_type=0, source=None, dot_kind=None, receipt=None, fixed_recovery=False, derived=False):
        if (source and self._team_number(source)!=self._team_number(target) and damage_type in (1,2,3,6,7,8)
                and self._buff(target,'curse') and self.state(source).get('next_baron_drain',-1)>=self.state(source)['serial']):
            amount*=2
        amount = self.six_reaction_incoming(target, amount, damage_type, source)
        amount = self.six_batch_damage_received(target, amount, damage_type, source, dot_kind)
        ctx=self._context(source) if source else None
        state=self.state(target);guard=state.get('guard')
        relic_reflect=getattr(self,'_equip_origin',None)=='relic_reflect'
        if not relic_reflect and state.get('alistar_guard104') and damage_type!=4:amount=_to_int(amount*round(max(0,1-state['alistar_guard104'].get('reduction',.8)),10))
        if not relic_reflect and ctx and ctx['kind'] in ('active','basic') and 1<=damage_type<=3 and guard and guard['charges']>0:
            ctx['guards'][id(target)]=target
            amount=_to_int(amount*(0 if guard['kind']=='kayle' else max(0,1-.55*guard.get('effect',1))))
        amount=self.six_followup_damage_received(target,amount,damage_type,source,dot_kind)
        before=target.get('hp',0);shield_before=self._buff_value(target,'shield')
        sustain = source is not None and damage_type in (1, 2, 3, 6, 7, 8) and self.six_reaction_passive(source, 'mf')
        if sustain and receipt is None:
            receipt = {}
        dealt=super()._injured(target,amount,damage_type,source=source,dot_kind=dot_kind,receipt=receipt,
                              fixed_recovery=fixed_recovery,derived=derived)
        lost=max(0,before-max(0,target.get('hp',0)))
        taken=lost+max(0,shield_before-self._buff_value(target,'shield'))
        if lost and damage_type in (1,2,3,6,7,8) and self.six_followup_passive(target,'tahm'):
            state['six_tahm_grey']=state.get('six_tahm_grey',0)+lost
        grey=state.get('grey')
        if grey and taken>0 and damage_type!=4:
            factor=grey['effect'];grey['value']=min(target['hp_max']*.2*factor,grey['value']+taken*.4*factor)
        if ctx and 1<=damage_type<=3:
            dealt_hp=min(max(0,before),max(0,dealt))
            ctx['hp_damage']=ctx.get('hp_damage',0)+dealt_hp
            if damage_type==1:ctx['six_physical_hp']=ctx.get('six_physical_hp',0)+dealt_hp
            entry=ctx['targets'].setdefault(id(target),[target,0]);entry[1]+=taken
            if target['hp']<=0 and self.hero(target) and all(u is not target for u in ctx['kills']):ctx['kills'].append(target)
        if source is not None and 1<=damage_type<=3:
            self.six_followup_direct_hit(source,target,ctx,taken)
        if source is not None and damage_type in (1, 2, 3, 6, 7, 8):
            self.six_batch_after_damage(source, target, taken)
        if sustain:
            self.six_reaction_mf_dealt(source, target, receipt.get('actual', 0)+receipt.get('shield_absorbed', 0))
        self.six_next_after_damage(source,target,damage_type,lost,taken,dot_kind,ctx)
        if target.get('hp',0)<=0:self.death(target)
        if before>0 and target.get('hp',0)<=0 and source is not None and self._team_number(source)!=self._team_number(target):
            self.queue_cat_skin_kill(source)
            if self.hero(target):self.queue_santa_kill(source)
        return dealt

    def _native_damage(self, attacker, target, multiplier, damage_type, share=1, *, raw_override=None, defense_base=None):
        if attacker.get('_batch_sand'):
            self._ability_last_hit = False
            return 0
        attack=self._attack
        if not attack:
            self._ability_last_hit=True
            if raw_override is not None:
                multiplier = raw_override/max(1, self._get_damage(attacker))
            return super()._native_damage(attacker,target,multiplier*share,damage_type)
        ctx=self._context(attacker)
        rengar=self.six_followup_passive(attacker,'rengar')
        crit_rate = rengar[0] if rengar and ctx and ctx['kind']=='active' else 1
        force_crit = bool(ctx and ctx.get('six_force_crit'))
        crit = self._roll_attack(attacker, target, crit_rate=crit_rate, force_crit=force_crit,
                                 crit_bonus=self.demon_crit_bonus(attacker))
        self._ability_last_hit = bool(crit)
        if not crit:
            return 0
        if ctx and ctx.get('cat_capture') and crit>1:ctx['cat_crits']+=1
        if ctx and ctx.get('six_crit_true') and crit>1 and damage_type == 1:
            damage_type=3
            multiplier=self._true_skill_coefficient(multiplier)
        row_a=self._config.get('avatar',{}).get(attacker.get('aid'),{});row_b=self._config.get('avatar',{}).get(target.get('aid'),{})
        sign_a=(row_a.get('tl') or [0,0,0])[0];sign_b=(row_b.get('tl') or [0,0,0])[0]
        raw=to_int(self._get_damage(attacker)*float(multiplier) if raw_override is None else raw_override)
        # Damage scaled from another stat may name that stat as the base the target's defense is measured against.
        base_attack=attacker.get('ap',0) if defense_base is None else defense_base
        amount=damage_before_final(raw,sign_a,sign_b,damage_type,self._defense_against(attacker,target,1),self._defense_against(attacker,target,2),attack,share,base_attack=base_attack,rules=self._combat_rules)
        from abyss_equip_passives import conversion
        fraction = conversion(self,attacker) if damage_type in (1,2) else 0
        if fraction:
            amount=damage_before_final(raw*(1-fraction),sign_a,sign_b,damage_type,
                self._defense_against(attacker,target,1),self._defense_against(attacker,target,2),attack,share,
                base_attack=base_attack,rules=self._combat_rules)
            amount+=damage_before_final(raw*fraction,sign_a,sign_b,3,0,0,attack,share,
                base_attack=base_attack,rules=self._combat_rules)
        amount=self._final_direct_damage(amount,target,crit,force_crit)
        receipt={}
        result=self._injured(target,amount,damage_type,source=attacker,receipt=receipt,derived=force_crit)
        self.six_star_extra_damage(attacker,target,ctx,raw,share,crit,sign_a,sign_b)
        self._ability_last_hit=True
        if crit>1:
            self._emit_mod_event(attacker,'crit',attacker,target,receipt.get('actual',0))
            self.yasuo_critical(attacker,target,receipt.get('settled',0))
        return result

    def _basic_attack(self, attacker, target):
        riven = self.six_next_passive(attacker, 'riven')
        riven_targets = self.six_next_radius(attacker, target, 600) if riven else ()
        with self.context(attacker,'basic') as ctx:
            self.six_star_begin(attacker,ctx,None)
            before=target['hp'];damage_type=(attacker.get('tpl') or [0,1,1])[2]
            ratio=attacker['skillB']['skills'][0][4] if passive_kind(attacker)=='six_caitlyn_p' else 1
            if (demon_ratio:=self.demon_basic_ratio(attacker)) is not None:
                ratio=demon_ratio
                if self.demon_take_force_crit(attacker):ctx['six_force_crit']=True
            if passive:=self.six_next_passive(attacker,'graves'):
                gap=abs(attacker['pos']-target['pos'])
                ratio=passive[4 if gap<=200 else 5 if gap<=350 else 6]
                ratio*=1+self.state(attacker).get('next_graves_basic',0)
            shen=self.state(attacker).get('six_shen')
            if shen and shen['charges']>0:
                ctx['six_shen_strike']=True
                shen['charges']-=1
            if not self.six_batch_kayle_attack(attacker, damage_type):
                targets=[target]
                if self.six_next_passive(attacker,'diana'):
                    targets=self.six_star_lane(attacker,350,forward=True) or targets
                for victim in targets:
                    before=victim['hp']
                    self._native_damage(attacker,victim,ratio,damage_type)
                    if self._ability_last_hit:self._book_attack_effects(attacker,victim,max(0,before-victim['hp']))
        self.polar_basic_attack(attacker)
        if len(riven_targets) > 3 and attacker['hp'] > 0:
            with self.context(attacker, 'passive'):
                for foe in riven_targets:
                    if foe['hp'] > 0:
                        self.control(attacker, foe, 'stun', 1)
                        self._native_damage(attacker, foe, riven[4], 1)
        self._emit_mod_event(attacker,'basic_attack',attacker,target)

    def _check_move(self, unit, forward, distance=0, forced=False):
        if unit.get("_six_star_turret") or forced and self.state(unit).get("channel"):return False
        previous=unit['pos'];result=super()._check_move(unit,forward,distance,forced)
        if unit['pos']!=previous:self.state(unit).pop('channel',None)
        return result

    def _reline(self, unit, line, pos=None, offset=None, forced=False):
        if unit.get("_six_star_turret") or forced and self.state(unit).get("channel"):return False
        previous=(unit['line'],unit['pos']);result=super()._reline(unit,line,pos,offset,forced)
        if (unit['line'],unit['pos'])!=previous:self.state(unit).pop('channel',None)
        return result

    def _get_speed(self, unit):
        value=super()._get_speed(unit)
        return _to_int(value*(1+self._buff_value(unit,'strong'))/(1+self._buff_value(unit,'weak'))*self.six_followup_speed(unit)*self.six_batch_speed(unit))

    def _get_range(self, unit):
        if self.six_next_passive(unit,'graves'):return 500
        return 3000 if self.six_batch_kayle_stage(unit) else super()._get_range(unit)

    def _get_crit(self, unit):
        value=super()._get_crit(unit)
        yasuo = self.six_batch_passive(unit, 'yasuo')
        if yasuo:
            temporary = self._buff_value(unit, 'critup')
            value = int((value-temporary)*yasuo[4]+temporary)
        turns=self.state(unit).get('six_polar_turns',0)
        if turns:
            base=value-self._buff_value(unit,'critup')
            growth=self.six_star_row(unit.get('skillB')).get('sixStarPolarGrowth105',0)
            value+=int(max(0,base)*turns*growth)
        return value

    @contextmanager
    def manual_skill_context(self, attacker, skill):
        row=self._config.get('skill',{}).get(skill.get('skid'),{})
        settings=skill.get('nativeSettings104',{})
        ctx=self._context(attacker)
        previous=(ctx['damage_factor'],ctx['effect_factor'])
        ctx['damage_factor']=self._factor(settings.get('manualDamageMultiplier',row.get('manualDamageMultiplier')))
        ctx['effect_factor']=self._factor(settings.get('manualEffectMultiplier',row.get('manualEffectMultiplier')))
        try:
            yield ctx
        finally:
            ctx['damage_factor'],ctx['effect_factor']=previous

    def _apply_native_skill(self, attacker, enemies, slot='skill'):
        skill=attacker.get(slot)
        if not isinstance(skill,dict) or not skill.get('skills'):return False
        with self.context(attacker,'active',skill) as ctx:
            self.six_star_begin(attacker,ctx,slot)
            result=super()._apply_native_skill(attacker,enemies,slot)
        self.six_star_finished(attacker,slot,skill,ctx,result)
        if result and slot=='skill':
            attacker['_ability_normal_cast']=True
            state=self.state(attacker)
            if attacker['hp']>0 and state.get('next_dragon') and not state.get('next_dragon_recast'):
                state['next_dragon_recast']=True
                try:self._apply_native_skill(attacker,self.opponents(attacker),'skill')
                finally:state.pop('next_dragon_recast',None)
        return result

    def _use_skill_slot(self, attacker, enemies, slot, cd_key):
        if (slot=='leader_skill' and self.yasuo_is(attacker) and self._buff(attacker,'silence')
                and not self.yasuo_cast_silenced(attacker)):
            return False
        attacker.pop('_ability_cd_override',None)
        if slot=='skill':
            attacker.pop('_six_star_refresh_normal',None)
        result=super()._use_skill_slot(attacker,enemies,slot,cd_key)
        if slot=='skill' and attacker.pop('_six_star_refresh_normal',False):
            attacker[cd_key]=-1
        override=attacker.pop('_ability_cd_override',None)
        if result and override is not None:attacker[cd_key]=override
        return result

    def _use_turn_start_passive(self, attacker, enemies):
        if passive_kind(attacker) in ('six_next_aoxing_p','six_next_sivir_p'):
            if self._buff(attacker,'stun') or self._buff(attacker,'silence'):
                return False
            return self._use_skill_slot(attacker,enemies,'skillB','_skill_cd_b')
        return super()._use_turn_start_passive(attacker,enemies)

    def explode(self, target, bomb):
        from abyss_equip_passives import delayed_cast
        owner=bomb['owner']
        if owner['hp']<=0:return
        with self.context(owner,'active',damage=bomb['damage']), delayed_cast(self,owner,bomb):
            targets=self.candidates(owner,3-self._team_number(owner),target['line'],target['pos'],250,4)
            if target['hp']>0 and all(u is not target for u in targets):targets=([target]+targets)[:4]
            for victim in targets:self.hit(owner,victim,bomb['coefficient'],2)

    def death(self, unit):
        self.six_batch_notify_death(unit, None)
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
                    if self._status_immune(targets[0]):continue
                    entry['hops']=1;entry['until']=self.state(targets[0])['serial']+1
                    self.state(targets[0])[key]=entry
                    self._status_received(targets[0],'poison')

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
                if owner['hp']>0 and entry['value']>0:self._add_buff(owner,'shield',2,_to_int(entry['value']*self.hero_output_rate_104(owner)))
            elif 'until' in entry and serial>entry['until']:state.pop(key,None)
        self.six_star_owner_turn(owner)
        self.six_reaction_turn(owner)
        zone=state.get('zone')
        if zone and owner['hp']>0:
            from abyss_equip_passives import delayed_cast
            with self.context(owner,'active',damage=zone['damage'],effect=zone['effect']), delayed_cast(self,owner,zone):
                for target in self.candidates(owner,3-self._team_number(owner),zone['line'],zone['pos'],350,3):
                    if self.hit(owner,target,1.2,1):self.control(owner,target,'weak',1,.2)
            zone['left']-=1
            if zone['left']<=0:state.pop('zone',None)
        channel=state.pop('channel',None)
        if channel and owner['hp']>0 and not self._buff(owner,'stun') and not self._buff(owner,'silence') and owner['pos']==channel['pos'] and owner['line']==channel['line']:
            from abyss_equip_passives import delayed_cast
            with self.context(owner,'active',damage=channel['damage'],effect=channel['effect']), delayed_cast(self,owner,channel):
                for target in self.enemies(owner,400,maximum=3):
                    if self.hit(owner,target,3.6,2):self.control(owner,target,'weak',2,.3)
            return True
        return owner['hp']<=0

    def _run_unit_turn_base(self, attacker, sides, side):
        attacker['_team']=sides[side]
        self._resolve_pending_strike(attacker)
        if attacker['hp']<=0:return True
        enemies=self.opponents(attacker)
        if not enemies:return False
        for cd in ('_skill_cd','_skill_cd_b','_skill_cd_leader','_skill_cd_book'):self._tick_slot_cd(attacker,cd)
        self._use_turn_start_passive(attacker,enemies)
        if attacker['hp']<=0 or self.turn_start(attacker) or self._tick_buffs(attacker) or attacker['hp']<=0:
            if attacker['hp'] <= 0:
                self.six_batch_notify_death(attacker, None)
            return True
        net = self.state(attacker).get('reaction_elise_net')
        if net and net.pop('skip', False):
            net['until'] = self.state(attacker)['serial']
            return True
        if self._buff(attacker,'stun'):return True
        if self.six_next_channel_turn(attacker):return True
        if self.state(attacker).get('next_storm'):
            if attacker.get('leader'):
                self._use_skill_slot(attacker,enemies,'leader_skill','_skill_cd_leader')
            return True
        enemies=self.opponents(attacker)
        if not enemies:return False
        summoned=self._buff(attacker,'summon') is not None
        nearby_enemies=enemies
        if summoned:
            nearby_enemies=[u for u in enemies if u['line']==attacker['line']]
        focus=attacker.get('_ability_focus')
        if self.kaisa_is(attacker) and not self.kaisa_lane(attacker,attacker['line']):return True
        if self.yasuo_is(attacker) and not self.yasuo_lane(attacker):return True
        if not summoned and focus and focus.get('hp',0)>0:
            target=focus
        else:
            target=min(nearby_enemies,key=lambda u:(u['line']!=attacker['line'],
                                                    abs(u['pos']-attacker['pos']),self.state(u)['index']),
                       default=None)
        if attacker.get('_batch_sand'):
            if target and target['line'] == attacker['line'] and abs(target['pos']-attacker['pos']) > self._get_range(attacker):
                self._check_move(attacker, True)
            return True
        # Close into the actual native attack/cast range before trying melee
        # abilities. The old study attacked across the map without moving.
        if target is not None:
            if target['line']!=attacker['line']:self._reline(attacker,target['line'],attacker['pos'])
            if abs(target['pos']-attacker['pos'])>self._get_range(attacker) and self._get_action_type(attacker)!=3:
                self._check_move(attacker,True)
        acted=False
        if not self._buff(attacker,'silence'):
            for slot,cd in (('book_skill','_skill_cd_book'),('skill','_skill_cd')):
                acted=self._use_skill_slot(attacker,enemies,slot,cd) or acted
        if attacker.get('leader'):acted=self._use_skill_slot(attacker,enemies,'leader_skill','_skill_cd_leader') or acted
        if not acted:
            reach=self._get_range(attacker)
            if summoned:
                targets=self._find_aim_list(attacker,enemies,reach)
                if targets:
                    target=min(targets,key=lambda u:(u is not focus,abs(u['pos']-attacker['pos']),
                                                     self.state(u)['index']))
                    self._basic_attack(attacker,target)
                    if target is focus:
                        attacker.pop('_ability_focus',None)
            elif target and target.get('hp',0)>0 and abs(target['pos']-attacker['pos'])<=reach:
                self._basic_attack(attacker,target)
        return True
