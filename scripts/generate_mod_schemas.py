"""Regenerate editor schemas and API capability catalogue from runtime constants."""
import json
import sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/"server"))
from mod_schema import ACTIONS,CAPABILITIES,CHANNELS,FORMAT,LIMITS,PATCH_PATHS,POLICIES,SCOPES,STATS

def obj(properties,required=()):return {"type":"object","properties":properties,"required":list(required),"additionalProperties":False}
def arr(items,**kw):return {"type":"array","items":items,**kw}
def enum(values):return {"enum":sorted(values)}
def num(minimum=0,maximum=10_000_000,integer=False):return {"type":"integer" if integer else "number","minimum":minimum,"maximum":maximum}
text={"type":"string","minLength":1,"maxLength":200}
local={"type":"string","pattern":"^[A-Za-z][A-Za-z0-9_-]{0,63}$"}
ref={"type":"string","pattern":"^(builtin|self):[A-Za-z]+/.+|^mod:[0-9a-f-]+/[A-Za-z]+/.+"}
nullable={"oneOf":[ref,{"type":"null"}]}
sha={"type":"string","pattern":"^[0-9a-f]{64}$"}
uuid={"type":"string","format":"uuid","pattern":"^[0-9a-f-]{36}$"}
version={"type":"string","pattern":"^(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)$"}
channels=obj({k:{"type":"boolean"} for k in CHANNELS})
scopes=obj({k:{"type":"boolean"} for k in SCOPES})
manifest_fields={"format":{"const":FORMAT},"kind":enum(("new","patch")),"packageId":uuid,"name":text,"author":text,"version":version,"engineApi":{"const":"1"},"requiredCapabilities":arr(enum(CAPABILITIES),uniqueItems=True),"entrypoints":obj({k:{"type":"string","minLength":1} for k in ("heroes","patches","skills","effects")}),"files":arr(obj({"path":{"type":"string","minLength":1},"sha256":sha},("path","sha256")),maxItems=512),"dependencies":arr(obj({"packageId":uuid,"version":{"type":"string"},"digest":sha},("packageId","version"))),"integrationDefaults":channels,"description":{"type":"string"},"preview":{"type":"string"},"sourceNotes":{},"signature":{}}
manifest=obj(manifest_fields,("format","kind","packageId","name","author","version","engineApi","requiredCapabilities","entrypoints","files"))
stats=obj({s:num() for s in STATS},STATS)
hero_fields={"id":local,"variant":local,"name":text,"unitType":{"const":"hero"},"quality":num(2,6,True),"signType":enum(("attack","tank","assist")),"actionType":enum(("forward","sly","stand","cunning")),"damageType":enum(("physical","magic")),"baseStats":stats,"growth":stats,"speed":num(0,10000,True),"attackRange":num(0,10000,True),"leadership":num(0,10000,True),"levelCap":num(1,99,True),"progression":obj({"preset":{"const":"builtin:progression/default-player-hero"},"starUp":nullable},("preset","starUp")),"skills":obj({s:nullable for s in ("normal","captain","passive")},("normal","captain","passive")),"presentation":obj({"portrait":ref,"icon":ref,"basicAttackEffect":ref,"voice":nullable},("portrait","icon","basicAttackEffect","voice")),"description":{"type":"string"},"role":text,"integrationDefaults":channels,"acquisition":{"enum":[{},None]},"destiny":{"enum":[{},[],None]}}
hero_required=tuple(k for k in hero_fields if k not in ("description","role","integrationDefaults","acquisition","destiny"))
hero_fields['damageType']=enum(('physical','magic','true'))
heroes=obj({"heroes":arr(obj(hero_fields,hero_required),minItems=1,maxItems=256)},("heroes",))
action_fields={"type":enum(ACTIONS),"effect":nullable,"coefficient":num(0,1000),"damageType":enum(("physical","magic")),"duration":num(1,100,True),"amount":num(0,1000),"targetPolicy":enum(POLICIES),"maxTargets":num(1,6,True),"lockToAction":num(0,30,True)}
action_fields.update(distance=num(0,10000,True),lockOnly={"type":"boolean"})
action_fields['maxTargets']={"enum":[-1,1,2,3,4,5,6]}
skill_fields={"id":local,"name":text,"description":{"type":"string","maxLength":4000},"timingUnit":{"const":"ownerTurns"},"warmup":num(0,100,True),"cooldown":num(1,100,True),"range":num(0,10000,True),"targetPolicy":enum(POLICIES),"actions":arr(obj(action_fields,("type","effect")),minItems=1,maxItems=32),"upgrades":arr(obj({"action":num(0,31,True),"field":enum(("coefficient","amount")),"perLevel":num(-1000,1000)},("action","field","perLevel")),maxItems=128),"maxLevel":{"const":10},"aoe":num(-1,6,True),"banStand":{"type":"boolean"}}
skill_fields['rankInfoTemplate']={"type":"string","maxLength":4000}
skill_fields['actions']['items']['allOf']=[{
    "if":{"properties":{"type":{"const":"move_to_target"}},"required":["type"]},
    "then":{"required":["distance"],"properties":{"maxTargets":{"const":1},"lockOnly":{"const":False}},
            "not":{"anyOf":[{"required":[key]} for key in ('coefficient','damageType','duration','amount')]}},
    "else":{"not":{"required":["distance"]}},
},{"if":{"properties":{"lockOnly":{"const":True}},"required":["lockOnly"]},
   "then":{"required":["lockToAction"]}}]
skill_required=tuple(k for k in skill_fields if k not in ("maxLevel","aoe","banStand","rankInfoTemplate"))
skills=obj({"skills":arr(obj(skill_fields,skill_required),maxItems=256)},("skills",))
patch_fields={"id":local,"target":ref,"expect":obj({"path":enum(PATCH_PATHS),"sha256":sha,"value":{}},("path",)),"operations":arr(obj({"op":enum(("replace","set","clear")),"path":enum(PATCH_PATHS),"value":{},"expect":{}},("op","path")),minItems=1,maxItems=64),"integrationDefaults":channels,"patchScopes":scopes}
patches=obj({"patches":arr(obj(patch_fields,("id","target","expect","operations")),minItems=1,maxItems=256)},("patches",))

if __name__=="__main__":
    directory=ROOT/"schemas";directory.mkdir(exist_ok=True)
    sys.path.insert(0,str(ROOT))
    from scripts.mod_tools import load_base
    from mod_native import contracts, ability_contract, NODE_SETTINGS
    base=load_base(ROOT/'config/reconstruction/full-config.json')
    profile=contracts(base)
    def shape(value):
        if value is None:return {'type':'null'}
        if type(value) is bool:return {'type':'boolean'}
        if type(value) in (int,float):return num(-10_000_000,10_000_000)
        if isinstance(value,str):return {'type':'string','maxLength':8000}
        if isinstance(value,list):return {'type':'array','maxItems':256}
        return obj({k:shape(v) for k,v in value.items()},value.keys())
    native_settings={key:{'anyOf':[shape(e) for e in examples]} for key,examples in profile['fields'].items()
                     if key not in ('id','name','info','skill')}
    abilities={kind:obj({key:{'type':'integer' if d['integer'] else 'number','minimum':d['minimum'],'maximum':d['maximum']}
                              for key,d in values.items()},values.keys()) for kind,values in ability_contract()['mechanisms'].items()}
    native_fields={'id':local,'name':text,'description':{'type':'string','maxLength':4000},'model':{'const':'native-template-v1'},
        'nativeTemplate':obj({'source':enum('builtin:skill/'+sid for sid in base['cfg']['skill']),
            'sourceDigest':sha,'settings':obj(native_settings,('pl','skillUp')),'passiveTrigger':num(0,19,True),
            'abilityContract':sha,'abilityParameters':obj(abilities),'scaleActionIndex':num(0,31,True)},('source','sourceDigest','settings','passiveTrigger')),
        'actions':arr(obj({'type':enum(profile['operations']),'arguments':{'type':'array','maxItems':128},
                          'origin':{'type':'string','pattern':'^builtin:skill/'},
                          'settings':obj({k:native_settings[k] for k in NODE_SETTINGS if k in native_settings})},('type','arguments')),minItems=1,maxItems=32),
        'upgrades':{'const':[]}}
    native_schema=obj(native_fields,native_fields.keys())
    skills['properties']['skills']['items']={'oneOf':[skills['properties']['skills']['items'],native_schema]}
    (directory/'mod-native-template.schema.json').write_text(json.dumps({'$schema':'https://json-schema.org/draft/2020-12/schema',
        'title':'Complete native battle mechanism template',**native_schema},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    for name,value in (("mod-manifest",manifest),("mod-heroes",heroes),("mod-skills",skills),("mod-patches",patches)):
        value={"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://lal.local/schemas/"+name+".schema.json","title":name+" API 1","$comment":"Editor schema. Runtime additionally validates references, semantic action contracts, duplicate IDs/paths, media, dependencies and post-upgrade bounds.",**value}
        (directory/(name+".schema.json")).write_text(json.dumps(value,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    catalogue={"format":FORMAT,"engineApi":"1","capabilities":sorted(CAPABILITIES),"actions":sorted(ACTIONS),"targetPolicies":sorted(POLICIES),"channels":list(CHANNELS),"patchScopes":list(SCOPES),"limits":LIMITS,"skillSemantics":{"timingUnit":"ownerTurns","warmup":"caster action opportunities before first use","cooldown":"caster action opportunities between uses","statusDuration":"affected target action turns under native Buff rules","maxLevel":10,"actionOrder":"array order; no implicit recast or recursive triggers","targetLock":"earlier same-side action index; missing/dead targets follow native target validity checks","damage":"native physical/magic defense and hit rules; each action uses independent defense unless builtin complete skill defines a reviewed sharing group"},"media":{"images":["8-bit noninterlaced RGB/RGBA PNG","JPEG with Pillow verifier installed"],"audio":["MPEG Layer III MP3, <= 120 seconds"],"code":False},"identityRanges":{"newHeroFamilies":[180000,199999],"scopedAliases":[170000,179999],"privateSkillFamilies":[800000,899999]},"unsupported":["arbitrary executable code/SWF","custom summon/clone/manual abilities","custom effect animations","persistent progression migration","authored destiny relationships","custom acquisition prices/weights","signature trust verification"]}
    catalogue['skillSemantics'].update(
        movement='move_to_target: one enemy; distance 0 means no additional distance cap, positive distance caps native movement; no damage implied',
        lockOnly='requires lockToAction; compile action policy to null to preserve native lock without a second policy filter',
        maxTargets='-1 means all valid targets after range/policy filtering; otherwise 1..6; movement requires 1',
        rankInfoTemplate='optional reviewed rank/flat numeric tokens; reorder action indices with actions')
    catalogue['extensionCapabilities']={
        'asset.image.card-frame':'PNG lal.cardFrame [x,y,width,height] anchors a native 103x118 shield; overflow pixels do not affect layout',
        'skill.native-template.v1':'complete structured native battle templates; requires updated client mechanism dispatch and compound parameter support',
        'hero.damage.true':'required for new heroes with true basic attacks (native tl[2]=3)',
        'hero.patch.damage-type':'required for patches replacing basic attack damageType',
        'skill.move_to_target':'required for authored move_to_target actions',
        'skill.target.lock-only':'required for lockOnly true',
        'skill.target.unlimited':'required for maxTargets -1',
        'skill.description.rank-template':'required for rankInfoTemplate'}
    catalogue['nativeTemplates']={'model':'native-template-v1','skillCount':len(base['cfg']['skill']),
        'operations':sorted(profile['operations']),'compoundMechanisms':list(ability_contract()['mechanisms']),
        'compoundParameterCount':sum(map(len,ability_contract()['mechanisms'].values())),
        'schema':'mod-native-template.schema.json'}
    catalogue['unsupported']=[v for v in catalogue['unsupported'] if v!='custom summon/clone/manual abilities']
    (directory/"mod-engine-api-v1.json").write_text(json.dumps(catalogue,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
