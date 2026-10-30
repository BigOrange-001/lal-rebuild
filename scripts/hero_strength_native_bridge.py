"""Run maintained skin AS method bodies (syntax-translated JS) in the study engine.

The damage, movement and RNG primitives remain the offline ReferenceBattle model.
No gameplay/client files are changed. One JS runtime is reused per worker.
"""
import json
from contextlib import nullcontext
import quickjs
from hero_strength_instrumentation import MeasuredBattle
from test_skin_revision_native_104 import translate
from battle_engine import _to_int

BOOT = r'''
let skin2Depth=0;
const int=x=>Math.trunc(Number(x)||0),Tools={toInt:int};
const GameMapConfig={LINE_POS:3000};
const Buff={LIST_BUFF:[],LIST_DEBUFF:[]};
const GlobalData={$mConfig_skill:{},$mConfig_avatar:{}};
const methods={},units=new Map();
function enc(v){if(v && v.__uid!==undefined)return {$unit:v.__uid};if(Array.isArray(v))return v.map(enc);return v;}
function dec(v){if(v && v.$unit!==undefined)return unit(v.$unit);if(Array.isArray(v))return v.map(dec);if(v&&typeof v==='object')return Object.fromEntries(Object.entries(v).map(([k,x])=>[k,dec(x)]));return v;}
function call(id,name,args=[]){return dec(JSON.parse(pycall(id,name,JSON.stringify(args.map(enc)))));}
function unit(id){
 if(units.has(id))return units.get(id);
 const own={__uid:id,skin2:{},abilityState:{}};
 const proxy=new Proxy(own,{
  has(t,k){return k in t||k in methods||['buffs','avatarData','skill0','skill1','skillB','statisticsOwner104','manualOwnerActionSerial','abilityIndex','isManualSummonUnit','team','otherTeam','hpMax','range','hp','ap','line','pos','manualFocusTarget','getDamage','getHpMax','getType','heroSkillOutputRate104','abilityFeedback','abilityCandidates','abilityAllEnemies','abilityHit','abilityControl','addBuff','removeBuff','removeAllDebuff','injured','abilityDash','abilityPull','checkMove','reline','abilitySummon'].includes(k);},
  get(t,k){if(k in t)return t[k];if(k in methods)return methods[k];
   if(typeof k==='symbol')return undefined;
   if(k==='buffs')return call(id,'buffs');
   if(k==='avatarData')return {id:call(id,'get',['aid'])};
   if(k==='skill0'||k==='skill1'||k==='skillB'){
    let s=call(id,'skill',[k]);if(!s)return null;
    return new Proxy(s,{set(t,p,v){t[p]=v;if(p==='abilityCooldownOverride')call(id,'cooldown',[v]);return true;}});
   }
   if(k==='statisticsOwner104')return call(id,'owner');
   if(k==='manualOwnerActionSerial')return call(id,'serial');
   if(k==='abilityIndex')return id;
   if(k==='isManualSummonUnit')return call(id,'summoned');
   if(k==='team')return call(id,'team');if(k==='otherTeam')return 3-call(id,'team');
   if(k==='hpMax')return call(id,'get',['hp_max']);
   if(k==='range')return call(id,'range');
   if(k==='hp'||k==='ap'||k==='line'||k==='pos')return call(id,'get',[k]);
   if(k==='manualFocusTarget')return own.focus;
   return (...args)=>call(id,k,args);
  },
  set(t,k,v){if(['hp','ap','line','pos','hpMax'].includes(k))call(id,'set',[k==='hpMax'?'hp_max':k,v]);
   else if(k==='manualFocusTarget'){t.focus=v;call(id,'focus',[v]);}
   else t[k]=v;return true;}
 });units.set(id,proxy);return proxy;
}
const GameMap={currentMap:{getAliveList:team=>call(-1,'alive',[team])}};
const currentAbilityAttack=()=>call(-1,'context');
const beginAbilityAttack=(owner,kind)=>call(owner.__uid,'begin',[kind]);
const endAbilityAttack=()=>call(-1,'end');
function reset(){units.clear();skin2Depth=0;}
function invoke(id,name,args){let a=dec(JSON.parse(args));let r=unit(id)[name](...a);if(name==='executeSkin2'&&a[1].abilityCooldownOverride!==undefined)call(id,'cooldown',[a[1].abilityCooldownOverride]);return r;}
'''


class NativeSkinBattle(MeasuredBattle):
    _runtime = None
    _active = None

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._uids = {}
        self._by_uid = {}
        self._bridge_ready = False
        self._js_contexts = []
        if NativeSkinBattle._runtime is None:
            ctx = quickjs.Context()
            ctx.add_callable('pycall', NativeSkinBattle._dispatch)
            ctx.eval(BOOT + translate())
            NativeSkinBattle._runtime = ctx
        self.js = NativeSkinBattle._runtime
        NativeSkinBattle._active = self
        self.js.eval('reset()')
        # Config is frozen within a worker; install it once.
        if not getattr(self.__class__, '_configured', False):
            from battle_engine import _GOOD_BUFFS, _DEBUFFS
            self.js.eval('GlobalData.$mConfig_skill='+json.dumps(self._config.get('skill', {}))+';'
                         'GlobalData.$mConfig_avatar='+json.dumps(self._config.get('avatar', {}))+';'
                         'Buff.LIST_BUFF='+json.dumps(sorted(_GOOD_BUFFS))+';'
                         'Buff.LIST_DEBUFF='+json.dumps(sorted(_DEBUFFS))+';'
                         f'GameMapConfig.LINE_POS={self._LINE_POS};')
            self.__class__._configured = True
        self._invoke = self.js.get('invoke')
        self._bridge_ready = True
        for u in self.a + self.b:
            self.invoke(u, 'skin2Initialize')

    def uid(self, u):
        if u is None:
            return None
        if id(u) not in self._uids:
            index = len(self._uids) + 1
            self._uids[id(u)] = index
            self._by_uid[index] = u
        return self._uids[id(u)]

    def ref(self, u):
        return {'$unit': self.uid(u)} if u is not None else None

    def invoke(self, u, name, *args):
        return self._invoke(self.uid(u), name, json.dumps(args, separators=(',', ':')))

    @staticmethod
    def _dispatch(uid, name, arguments):
        b = NativeSkinBattle._active
        def decode(v):
            if isinstance(v, dict) and '$unit' in v: return b._by_uid[v['$unit']]
            if isinstance(v, list): return [decode(x) for x in v]
            return v
        args = decode(json.loads(arguments))
        try:
            value = b.callback(b._by_uid.get(uid), name, args)
            return json.dumps(value, separators=(',', ':'))
        except Exception as exc:
            b.bridge_error = (name, args, exc)
            raise

    def callback(self, u, name, a):
        if name == 'get': return u.get(a[0], 0)
        if name == 'set': u[a[0]] = a[1]; return None
        if name == 'buffs': return {k:dict(value=v.value,round=v.round) for k,v in u.get('_buffs',{}).items()}
        if name == 'skill':
            s=u.get({'skill0':'skill','skill1':'leader_skill','skillB':'skillB'}[a[0]])
            return dict(skills=s['skills'],skillSetData=dict(id=s['skid'],cooldown=s['pl'][1])) if s else None
        if name == 'cooldown': u['_ability_cd_override']=a[0]; return None
        if name == 'team': return self._team_number(u)
        if name == 'range': return self._get_range(u)
        if name == 'owner':
            token=u.get('summon_owner_token');side=self._team_number(u)
            return next((self.ref(x) for x in self.a+self.b if x.get('_owner_token')==token and self._team_number(x)==side),None)
        if name == 'serial': return self.state(u)['serial']
        if name == 'summoned': return bool(u.get('summon_owner') or u.get('summon_owner_token') or self._get_type(u)!=1)
        if name == 'alive': return [self.ref(x) for x in (self.a if a[0]==1 else self.b) if x['hp']>0]
        if name == 'context':
            ctx=self._context()
            return dict(owner=self.ref(ctx['owner']),kind=ctx['kind'],damage=ctx.get('hp_damage',0)) if ctx else None
        if name == 'begin':
            cm=self.context(u,a[0]);cm.__enter__();self._js_contexts.append(cm)
            return self.callback(None,'context',[])
        if name == 'end': self._js_contexts.pop().__exit__(None,None,None); return None
        if name == 'focus': u['_ability_focus']=a[0];return None
        if name == 'getDamage': return self._get_damage(u)
        if name == 'getHpMax': return u['hp_max']
        if name == 'getType': return self._get_type(u)
        if name == 'heroSkillOutputRate104': return self.hero_output_rate_104(u)
        if name == 'abilityFeedback': return None
        if name == 'abilityCandidates':
            team,lane,pos,distance,maximum=a[:5];hero=a[5] if len(a)>5 else False
            order=a[6] if len(a)>6 else 'nearest';excluded=a[7] if len(a)>7 else []
            return [self.ref(x) for x in self.candidates(u,team,lane,pos,distance,maximum,hero,order,excluded)]
        if name == 'abilityAllEnemies': return [self.ref(x) for x in self.opponents(u)]
        if name == 'abilityHit': return self.hit(u,a[0],a[1],a[2])
        if name == 'abilityControl': self.control(u,*a); return None
        if name == 'addBuff':
            self._add_buff(u,a[0],a[1],a[2] if len(a)>2 else 0,source=a[5] if len(a)>5 else u);return None
        if name == 'removeBuff': self._remove_buff(u,a[0],consume=a[1] if len(a)>1 else False);return None
        if name == 'removeAllDebuff': self._remove_all_debuff(u);return None
        if name == 'injured': return self._injured(u,a[0],a[3],source=(a[6] if len(a)>6 else None) or a[4])
        if name == 'abilityDash': return self.dash(u,a[0])
        if name == 'abilityPull': return self._check_move(a[0],True,a[2],forced=True)
        if name == 'checkMove': return self._check_move(u,a[0],a[1],forced=a[4] if len(a)>4 else False)
        if name == 'reline': return self._reline(u,a[0],a[1])
        if name == 'abilitySummon':
            self.summon(u,*a)
            pets=self.state(u)['summons_'+a[4]]
            self.js.eval(f'unit({self.uid(u)}).abilityState.summons_{a[4]}='+json.dumps([self.uid(x) for x in pets])+'.map(unit)')
            return None
        raise ValueError(f'Unmapped client skin primitive {name}')

    def _emit_mod_event(self, owner, event, source=None, target=None, amount=0, overheal=0):
        if owner is not None and event!='turn_start' and getattr(self,'_bridge_ready',False):
            self.invoke(owner,'skin2Event',event,self.ref(source),self.ref(target),amount,overheal)
        return super()._emit_mod_event(owner,event,source,target,amount,overheal)

    def _injured_base(self,target,amount,damage_type=0,source=None,dot_kind=None):
        if getattr(self,'_bridge_ready',False):
            amount=self.invoke(target,'skin2Incoming',amount,self.ref(source),damage_type)
        result=super()._injured_base(target,amount,damage_type,source,dot_kind)
        if damage_type==6 and source is not None and result>0:
            self.invoke(source,'skin2PoisonTick',self.ref(target))
        return result

    def _resolve_lethal(self,target):
        if getattr(self,'_bridge_ready',False):self.invoke(target,'skin2Lethal')
        return super()._resolve_lethal(target)

    def _remove_all_debuff(self,u):
        if getattr(self,'_bridge_ready',False):self.invoke(u,'skin2ClearDebuffs')
        return super()._remove_all_debuff(u)

    def turn_start(self,u):
        result=super().turn_start(u)
        self.invoke(u,'skin2Event','turn_start',self.ref(u),self.ref(u),0,0)
        egg=self.js.eval(f'Boolean(unit({self.uid(u)}).skin2.eggUntil)')
        return result or egg or u['hp']<=0

    def _check_move(self,u,forward,distance=0,forced=False):
        if getattr(self,'_bridge_ready',False) and not forced and distance>0 and self.invoke(u,'s2LiveMark',self.ref(u),'cold'):
            distance=int(distance*self.invoke(u,"s2ColdMoveFactor")+.5)
        result=super()._check_move(u,forward,distance,forced)
        if getattr(self,'_bridge_ready',False):self.invoke(u,'skin2Moved')
        return result

    def _reline(self,u,line,pos=None,offset=None,forced=False):
        if getattr(self,'_bridge_ready',False) and not forced and pos is not None and self.invoke(u,'s2LiveMark',self.ref(u),'cold'):
            pos=u['pos']+int((pos-u['pos'])*self.invoke(u,"s2ColdMoveFactor")+.5)
        result=super()._reline(u,line,pos,offset,forced)
        if getattr(self,'_bridge_ready',False):self.invoke(u,'skin2Moved')
        return result

    def _defense_against(self,source,target,damage_type):
        base=super()._defense_against(source,target,damage_type)
        if source is None or damage_type!=1 or not getattr(self,'_bridge_ready',False):return base
        pen=self.js.eval(f'(function(){{let t=unit({self.uid(target)}),s=unit({self.uid(source)});return Math.max(t.s2LiveMark(t,"wanted")&&t.skin2.wanted.owner===s?s.s2Value(s.skill0,"penetration"):0,s.skin2.penetrationEnd&&s.manualOwnerActionSerial<=s.skin2.penetrationEnd?s.s2Value(s.skill1,"penetration"):0)}})()')
        if not pen:return base
        sunder=max(0,self._buff_value(target,'sunder'))
        return min(base,max(0,_to_int(self._get_de_ph(target,ignore_sunder=True)*(1-max(pen,sunder/(1+sunder))))))

    def execute(self,owner,kind,scale,skill):
        if not kind.startswith('skin2_'):return super().execute(owner,kind,scale,skill)
        s=dict(skills=skill['skills'],skillSetData=dict(id=skill['skid'],cooldown=skill['pl'][1]))
        if not self.invoke(owner,'skin2CanCast',kind,s):return False
        result=self.invoke(owner,'executeSkin2',kind,s)
        self.manual_casts[kind]=self.manual_casts.get(kind,0)+int(bool(result))
        return result
