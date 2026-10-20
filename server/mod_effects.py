"""Bounded, data-only effect sequences shared by the importer and editor.

Runtime arrays are compiler-owned. No source identity spoofing, eval, scripts,
arbitrary config paths, or unbounded summon/target expansion is accepted.
"""
from __future__ import annotations

import copy
import re
from mod_schema import (fail, object_, text_, local_id, enum, number, reference)

MODEL = 'effect-sequence-v1'
CAPABILITY = 'skill.effect-sequence.v1'
SUMMON_CAPABILITY = 'unit.summon.v1'
EVENT_CAPABILITY = 'skill.events.v1'
EVENTS = ('turn_start','turn_end','basic_attack','skill_cast','hit','crit','miss','damage_taken','damage_dealt','healed','heal_done','dodge','kill','death','shield_break')
OPERATIONS = ('heal', 'damage', 'buff', 'push', 'move', 'summon')
TARGETS = ('self', 'all_allies', 'all_enemies', 'ally_radius',
           'lane_lowest_hp', 'lane_front', 'enemy_radius', 'previous','event_source','event_target')
BUFFS = ('shield', 'purify', 'strong', 'weak', 'sunder', 'steel',
         'bless', 'critup', 'toughup', 'fleeup', 'hitup', 'stun','curse','timed_bless')
CONDITION_BUFFS = BUFFS + ('root','poison','burn','evil','silence','taunt','armor','book_penetration')
GROWTH_FIELDS = {'attackRatio': 5, 'maxHpRatio': 6, 'amount': 7,'eventRatio':18,'overhealRatio':19}
DEFAULTS = dict(target='self', centerAction=-1, radius=0, attackRatio=0,
                maxHpRatio=0, amount=0, buff='shield', duration=1, distance=0,
                unit=None, statRatio=1, lifetime=3, maxAlive=1,
                excludeCenter=False, damageType='true', effect=None, growth={},eventRatio=0,overhealRatio=0)


def validate(skill, path='skill'):
    fields = {'id','name','description','model','warmup','cooldown','range',
              'trigger','actions','rankInfoTemplate','maxLevel'}
    object_(skill,path,fields,fields)
    local_id(skill['id'],path+'.id')
    text_(skill['name'],path+'.name')
    text_(skill['description'],path+'.description',4000,True)
    text_(skill['rankInfoTemplate'],path+'.rankInfoTemplate',4000,True)
    enum(skill['model'],(MODEL,),path+'.model')
    number(skill['warmup'],path+'.warmup',0,100,True)
    number(skill['cooldown'],path+'.cooldown',0 if skill.get('trigger',{}).get('kind')=='event' else 1,100,True)
    number(skill['range'],path+'.range',0,10000,True)
    number(skill['maxLevel'],path+'.maxLevel',1,10,True)
    trigger=skill['trigger']
    object_(trigger,path+'.trigger',('kind',),{'kind','buff','event','maxPerRound','allowChain','relation','unitType','minAmount','hpBelow','requiredBuff','absentBuff'})
    enum(trigger['kind'],('ready','absent_buff','event'),path+'.trigger.kind')
    if trigger['kind']=='event':
        if 'buff' in trigger:fail('Use requiredBuff/absentBuff for event filters',path+'.trigger')
        enum(trigger.get('event'),EVENTS,path+'.trigger.event')
        number(trigger.get('maxPerRound',1),path+'.trigger.maxPerRound',1,16,True)
        if type(trigger.get('allowChain',False)) is not bool:fail('Expected boolean',path+'.trigger.allowChain')
        enum(trigger.get('relation','any'),('any','self','ally','enemy'),path+'.trigger.relation')
        enum(trigger.get('unitType','any'),('any','hero','summon'),path+'.trigger.unitType')
        number(trigger.get('minAmount',0),path+'.trigger.minAmount',0,10000000)
        number(trigger.get('hpBelow',1),path+'.trigger.hpBelow',0,1)
        for key in ('requiredBuff','absentBuff'):
            if key in trigger:enum(trigger[key],CONDITION_BUFFS,path+'.trigger.'+key)
        if trigger.get('requiredBuff') and trigger.get('requiredBuff')==trigger.get('absentBuff'):fail('Contradictory buff filters',path+'.trigger')
    else:
        if set(trigger)-{'kind','buff'}:fail('Event filters require an event trigger',path+'.trigger')
        if trigger['kind']=='absent_buff':enum(trigger.get('buff'),CONDITION_BUFFS,path+'.trigger.buff')
        elif 'buff' in trigger:fail('Ready trigger must not contain a buff',path+'.trigger')
    actions=skill['actions']
    if not isinstance(actions,list) or not 1<=len(actions)<=32:fail('Expected 1..32 effect steps',path+'.actions')
    max_summons=0
    for i,action in enumerate(actions):
        p=path+'.actions[%d]'%i
        object_(action,p,('type',),{'type',*DEFAULTS})
        a={**DEFAULTS,**action}
        enum(a['type'],OPERATIONS,p+'.type');enum(a['target'],TARGETS,p+'.target')
        number(a['centerAction'],p+'.centerAction',-1,i-1,True)
        if a['target'] in ('previous','enemy_radius') and a['centerAction']<0:fail('This selector requires a preceding target anchor',p)
        if a['target']=='previous':
            prior={**DEFAULTS,**actions[a['centerAction']]}
            # Reusing opposite-side locks would apply buffs/damage to the wrong team.
            if prior['type']=='summon':fail('Summon is not a target anchor',p)
        for key in ('radius','distance'):number(a[key],p+'.'+key,0,10000)
        for key in ('attackRatio','maxHpRatio','eventRatio','overhealRatio'):number(a[key],p+'.'+key,0,1000)
        number(a['amount'],p+'.amount',0,100000)
        for key in ('duration','lifetime'):number(a[key],p+'.'+key,1,100,True)
        number(a['maxAlive'],p+'.maxAlive',1,16,True)
        number(a['statRatio'],p+'.statRatio',.01,100)
        enum(a['buff'],BUFFS,p+'.buff')
        enum(a['damageType'],('physical','magic','true'),p+'.damageType')
        if type(a['excludeCenter']) is not bool:fail('Expected boolean',p+'.excludeCenter')
        reference(a['effect'],p+'.effect',('effect',),True)
        if a['type']=='summon':
            reference(a['unit'],p+'.unit',('hero',))
            if a['target']!='self':fail('Summon must use its caster as spawn anchor',p+'.target')
            max_summons+=a['maxAlive']
        elif a['unit'] is not None:fail('Only summon may reference a unit',p+'.unit')
        selector=a['target'];source_index=i
        while selector=='previous':
            source_index=({**DEFAULTS,**actions[source_index]})['centerAction']
            if source_index<0:fail('Previous target requires a valid earlier anchor',p)
            selector=({**DEFAULTS,**actions[source_index]})['target']
        if (a['eventRatio'] or a['overhealRatio'] or selector in ('event_source','event_target')) and trigger['kind']!='event':fail('Event values/targets require an event trigger',p)
        beneficial=selector in ('self','all_allies','ally_radius')
        if a['type'] in ('heal','summon') and not beneficial and selector not in ('event_source','event_target'):fail('Healing and summons require allied targets',p+'.target')
        if a['type'] in ('damage','push','move') and beneficial:fail('Offensive actions require enemy targets',p+'.target')
        if a['type']=='buff' and selector not in ('event_source','event_target'):
            if a['buff']=='timed_bless' and not beneficial:fail('Timed blessing requires allied targets',p+'.target')
            if a['buff']=='curse' and beneficial:fail('Curse requires enemy targets',p+'.target')
        if a['type']=='buff' and a['buff'] in ('strong','weak','sunder','steel') and a['amount']>1:fail('Percentage buff must be in 0..1',p+'.amount')
        if a['type']=='move' and a['target'] not in ('previous','lane_front','lane_lowest_hp'):fail('Move requires a single target',p+'.target')
        object_(a['growth'],p+'.growth',(),set(GROWTH_FIELDS))
        for key,delta in a['growth'].items():
            if key in ('eventRatio','overhealRatio') and trigger['kind']!='event':fail('Event growth requires an event trigger',p)
            number(delta,p+'.growth.'+key,0,100000)
            cap=1 if key=='amount' and a['type']=='buff' and a['buff'] in ('strong','weak','sunder','steel') else (100000 if key=='amount' else 1000)
            number(a[key]+delta*(skill['maxLevel']-1),p+'.maxLevel.'+key,0,cap)
    if max_summons>16:fail('At most 16 summoned units across one skill sequence',path+'.actions')
    # Same numeric array indices are consumed by SkillSet's live description renderer.
    template=skill['rankInfoTemplate']
    for match in re.finditer(r'\{(rank|flat):(\d+):(\d+)\}',template):
        i,j=int(match[2]),int(match[3])
        if j>=18 and trigger['kind']!='event':fail('Event description fields require an event trigger',path+'.rankInfoTemplate')
        if i>=len(actions) or j not in (4,5,6,7,9,10,12,13,14,18,19):fail('Description token must bind a numeric effect field',path+'.rankInfoTemplate')
    if re.search(r'\{(?:rank|flat|scale):',re.sub(r'\{(?:rank|flat):\d+:\d+\}','',template)):
        fail('Unsupported description binding',path+'.rankInfoTemplate')


def compile_skill(skill,sid,resolve):
    validate(skill)
    actions=[];growth=[]
    for i,authored in enumerate(skill['actions']):
        a={**DEFAULTS,**copy.deepcopy(authored)}
        unit=resolve(a['unit'],('hero',),'effects.unit',True)
        effect=resolve(a['effect'],('effect',),'effects.effect',True) or ''
        actions.append(['mod_step',a['type'],a['target'],a['centerAction'],a['radius'],
                        a['attackRatio'],a['maxHpRatio'],a['amount'],a['buff'],
                        a['duration'],a['distance'],unit,a['statRatio'],a['lifetime'],
                        a['maxAlive'],a['excludeCenter'],{'physical':1,'magic':2,'true':3}[a['damageType']],effect]+([a['eventRatio'],a['overhealRatio']] if skill['trigger']['kind']=='event' else []))
        for key,delta in a['growth'].items():growth.append([i,GROWTH_FIELDS[key],delta])
    return dict(id=sid,name=skill['name'],info=skill['description'],res=sid,
                pl=[skill['warmup'],skill['cooldown'],skill['range'],0,-1,1],
                skill=actions,skillUp=growth,modMaxLevel=skill['maxLevel'],
                modEffectSequence=1,modCondition=copy.deepcopy(skill['trigger']),
                modPassiveTrigger=20,rankInfoTemplate=skill['rankInfoTemplate'])


def json_schema():
    """Public shape; runtime additionally checks indices and grown values."""
    def obj(properties,required=()):
        return {'type':'object','properties':properties,'required':list(required),'additionalProperties':False}
    def num(low,high,integer=False):
        return {'type':'integer' if integer else 'number','minimum':low,'maximum':high}
    text={'type':'string','maxLength':4000}
    local={'type':'string','pattern':'^[A-Za-z][A-Za-z0-9_-]{0,63}$'}
    ref={'type':['string','null']}
    action={'type':{'enum':list(OPERATIONS)},'target':{'enum':list(TARGETS)},
            'centerAction':num(-1,30,True),'radius':num(0,10000),
            'attackRatio':num(0,1000),'maxHpRatio':num(0,1000),'amount':num(0,100000),
            'buff':{'enum':list(BUFFS)},'duration':num(1,100,True),'distance':num(0,10000),
            'unit':ref,'statRatio':num(.01,100),'lifetime':num(1,100,True),
            'maxAlive':num(1,16,True),'excludeCenter':{'type':'boolean'},
            'damageType':{'enum':['physical','magic','true']},'effect':ref,
            'eventRatio':num(0,1000),'overhealRatio':num(0,1000),
            'growth':obj({key:num(0,100000) for key in GROWTH_FIELDS})}
    properties={'id':local,'name':{'type':'string','minLength':1,'maxLength':200},
                'description':text,'model':{'const':MODEL},'warmup':num(0,100,True),
                'cooldown':num(0,100,True),'range':num(0,10000,True),
                'trigger':{'oneOf':[obj({'kind':{'const':'ready'}},('kind',)),
                                     obj({'kind':{'const':'absent_buff'},'buff':{'enum':list(CONDITION_BUFFS)}},('kind','buff')),
                                     obj({'kind':{'const':'event'},'event':{'enum':list(EVENTS)},'maxPerRound':num(1,16,True),
                                          'allowChain':{'type':'boolean'},'relation':{'enum':['any','self','ally','enemy']},
                                          'unitType':{'enum':['any','hero','summon']},'minAmount':num(0,10000000),'hpBelow':num(0,1),
                                          'requiredBuff':{'enum':list(CONDITION_BUFFS)},'absentBuff':{'enum':list(CONDITION_BUFFS)}},('kind','event'))]},
                'actions':{'type':'array','minItems':1,'maxItems':32,'items':obj(action,('type',))},
                'rankInfoTemplate':text,'maxLevel':num(1,10,True)}
    return obj(properties,properties)
