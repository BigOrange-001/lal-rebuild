"""Public, deliberately bounded v1 Mod protocol (stdlib only).

The same functions back package import, author tooling and activation. Native
AS3 arrays are compiler output, never an author-supplied execution surface.
"""
from __future__ import annotations

import hashlib
import json
import math
import re
import uuid
from pathlib import PurePosixPath

FORMAT = "lal-mod-v1"
ENGINE_API = "1"
LIMITS = {"archiveBytes": 64*1024*1024, "expandedBytes": 128*1024*1024,
          "fileBytes": 32*1024*1024, "jsonBytes": 4*1024*1024, "files": 512,
          "entities": 256, "imageDimension": 2048, "imagePixels": 4_194_304,
          "compressionRatio": 200, "dependencyDepth": 16, "skillActions": 32,
          "skillLevel": 10, "turns": 100, "stat": 10_000_000,
          "textureBytes":128*1024*1024,"mediaBytes":128*1024*1024,"activeHeroes":1024,
          "activeSkills":2048,"activePatches":1024,"activePatchOperations":4096,"combinedDataBytes":16*1024*1024,
          "decodedAudioBytes":128*1024*1024,"registryBytes":64*1024*1024}
CHANNELS = (
 "appearance.arena_enemy", "acquisition.summon.normal", "acquisition.summon.advanced",
 "acquisition.shop.hero_soul", "appearance.fragment_enemy", "appearance.exploration_enemy",
 "appearance.expedition_enemy", "appearance.campaign_random_enemy", "appearance.assist_bot",
 "acquisition.summon.activity", "acquisition.exchange.hero", "acquisition.exchange.activity",
 "acquisition.drop.campaign", "acquisition.drop.activity", "acquisition.drop.tower_hero",
 "acquisition.drop.tower_soul", "usage.friend_assist", "usage.destiny", "usage.auxiliary_formation")
SCOPES = ("owned", "arenaEnemy", "pveEnemy", "assist", "summoned")
STATS = ("health", "attack", "physicalDefense", "magicDefense")
POLICIES = frozenset(("enemy_lane_frontmost", "enemy_lane_farthest", "enemy_lane_all",
 "enemy_lane_lowest_current_hp_hero", "enemy_global_lowest_current_hp", "enemy_global_lowest_hpmax",
 "enemy_global_highest_hpmax_hero", "enemy_global_lowest_hp_ratio_hero", "enemy_global_highest_attack_hero",
 "enemy_lane_highest_attack_hero", "enemy_lane_lowest_hp_ratio_any", "enemy_lane_lowest_hp_ratio_n",
 "ally_self", "ally_all", "ally_lane_all", "ally_lane_lowest_current_hp_hero",
 "ally_lane_lowest_current_hp_any", "ally_lane_highest_attack_any", "ally_lane_lowest_hp_ratio_hero",
 "ally_lane_lowest_hp_ratio_any", "ally_lane_lowest_hp_ratio_n", "ally_all_lowest_hp_ratio"))
ACTIONS = frozenset(("damage", "cure", "shield", "hp_shield", "caster_hp_shield", "target_hp_shield",
 "stun", "silence", "weak", "sunder", "poison", "burn", "strong", "purify", "armor", "move_to_target"))
CAPABILITIES = frozenset(("hero.register", "hero.patch.skill", "hero.patch.stats", "hero.patch.presentation",
 "hero.patch.text", "skill.reference.builtin", "asset.image", "asset.sound", "effect.reference.builtin",
 "patch.scopes", "progression.default-player-hero", "hero.damage.true", "hero.patch.damage-type", "skill.target.lock-only",
 "skill.target.unlimited", "skill.description.rank-template", "skill.native-template.v1") + tuple("skill."+a for a in ACTIONS))
LOCAL_ID = re.compile(r"[A-Za-z][A-Za-z0-9_-]{0,63}\Z")
SHA256 = re.compile(r"[0-9a-f]{64}\Z")
VERSION = re.compile(r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\Z")

class ModError(ValueError):
    def __init__(self, code, message, path=""):
        self.code, self.message, self.path = code, message, path
        super().__init__((path+": " if path else "")+message)
    def as_dict(self):
        return {"code":self.code,"message":self.message,"path":self.path}

def fail(message, path="", code="ModInvalidPackage"):
    raise ModError(code, message, path)

def strict_json(raw, path="", *, max_bytes=None):
    if len(raw) > (LIMITS["jsonBytes"] if max_bytes is None else max_bytes): fail("JSON exceeds byte limit", path)
    def pairs(values):
        result = {}
        for key,value in values:
            if key in result: fail("Duplicate JSON key: "+key, path)
            result[key]=value
        return result
    try:
        value=json.loads(raw.decode("utf-8-sig") if isinstance(raw,bytes) else raw,
                         object_pairs_hook=pairs,parse_constant=lambda v:fail("Nonfinite number: "+v,path))
    except (UnicodeError,json.JSONDecodeError,RecursionError) as exc:
        fail("Invalid UTF-8 JSON: "+str(exc),path)
    def visit(v,depth=0):
        if depth>40:fail("JSON nesting exceeds 40",path)
        if isinstance(v,float) and not math.isfinite(v): fail("Nonfinite number",path)
        if isinstance(v,dict):
            for child in v.values():visit(child,depth+1)
        elif isinstance(v,list):
            for child in v:visit(child,depth+1)
    visit(value)
    return value

def canonical(value):
    return json.dumps(value,sort_keys=True,separators=(",",":"),ensure_ascii=False,allow_nan=False,default=lambda v:v.isoformat()).encode("utf-8")

def digest(value): return hashlib.sha256(canonical(value)).hexdigest()

def safe_path(value):
    if (not isinstance(value,str) or not value or len(value)>240 or "\\" in value or ":" in value
            or "\x00" in value or value.startswith("/") or "//" in value):
        fail("Expected a relative POSIX file path",str(value))
    parts=PurePosixPath(value).parts
    if any(part in (".","..") or part.endswith(("."," ")) or re.fullmatch(r"(?i:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\..*)?",part) for part in value.split("/")):
        fail("Unsafe path component",value)
    if str(PurePosixPath(value))!=value: fail("Path is not canonical",value)
    return value

def object_(value,path,required=(),allowed=None):
    if not isinstance(value,dict):fail("Expected object",path)
    for key in required:
        if key not in value:fail("Missing required field",path+"."+key)
    if allowed is not None:
        for key in value:
            if key not in allowed:fail("Unknown field",path+"."+key)
    return value

def text_(value,path,maximum=200,empty=False):
    if not isinstance(value,str) or len(value)>maximum or (not empty and not value.strip()):fail("Expected nonempty text (max %d)"%maximum,path)
    return value

def number(value,path,minimum=0,maximum=10_000_000,integer=False):
    if type(value) not in (int,float) or not math.isfinite(value) or not minimum<=value<=maximum or (integer and type(value) is not int):
        fail("Expected %s in [%s,%s]"%("integer" if integer else "finite number",minimum,maximum),path)
    return value

def enum(value,values,path):
    if not isinstance(value,(str,int,float,bool)) or value not in values:fail("Expected one of "+", ".join(map(str,values)),path)
    return value

def local_id(value,path):
    if not isinstance(value,str) or not LOCAL_ID.fullmatch(value):fail("Invalid local ID",path)
    return value

def package_id(value,path="packageId"):
    try:
        if str(uuid.UUID(value))!=value:fail("Expected lowercase canonical UUID",path)
    except (ValueError,TypeError,AttributeError):fail("Expected UUID",path)
    return value

def version(value,path="version"):
    if not isinstance(value,str) or not VERSION.fullmatch(value):fail("Expected MAJOR.MINOR.PATCH",path)
    return tuple(int(x) for x in value.split("."))

def matches_version(value,constraint):
    """A small documented grammar: *, exact, ^, ~, or comma separated comparisons."""
    actual=version(value)
    if constraint=="*":return True
    if not isinstance(constraint,str):fail("Invalid version constraint")
    if constraint.startswith(("^","~")):
        low=version(constraint[1:]); high=((low[0]+1,0,0) if low[0] else ((0,low[1]+1,0) if low[1] else (0,0,low[2]+1))) if constraint[0]=="^" else (low[0],low[1]+1,0)
        return low<=actual<high
    for term in constraint.split(","):
        term=term.strip(); m=re.fullmatch(r"(>=|<=|>|<|=)?(.+)",term)
        if not m:fail("Invalid version constraint")
        op,want=m.groups(); expected=version(want)
        if not {None:actual==expected,"=":actual==expected,">=":actual>=expected,"<=":actual<=expected,">":actual>expected,"<":actual<expected}[op]:return False
    return True

def boolean_map(value,keys,path):
    object_(value,path)
    for key,enabled in value.items():
        if key not in keys:fail("Unknown option",path+"."+key)
        if type(enabled) is not bool:fail("Expected boolean",path+"."+key)

def validate_manifest(manifest):
    required=("format","kind","packageId","name","author","version","engineApi","requiredCapabilities","entrypoints","files")
    object_(manifest,"manifest",required,set(required)|{"dependencies","integrationDefaults","description","preview","sourceNotes","signature"})
    enum(manifest["format"],(FORMAT,),"manifest.format"); enum(manifest["kind"],("new","patch"),"manifest.kind")
    package_id(manifest["packageId"]);version(manifest["version"])
    for key in ("name","author"):text_(manifest[key],"manifest."+key)
    if manifest["engineApi"]!=ENGINE_API:fail("Unsupported engine API","manifest.engineApi","ModIncompatible")
    caps=manifest["requiredCapabilities"]
    if not isinstance(caps,list) or any(not isinstance(c,str) or c not in CAPABILITIES for c in caps) or len(caps)!=len(set(caps)):fail("Unknown or duplicate required capability","manifest.requiredCapabilities","ModIncompatible")
    ep=object_(manifest["entrypoints"],"manifest.entrypoints",allowed={"heroes","patches","skills","effects"})
    if ("heroes" if manifest["kind"]=="new" else "patches") not in ep:fail("Missing main entrypoint","manifest.entrypoints")
    for key,path in ep.items():safe_path(path)
    if not isinstance(manifest["files"],list) or len(manifest["files"])>LIMITS["files"]:fail("Invalid file table","manifest.files")
    paths=set()
    for i,row in enumerate(manifest["files"]):
        p="manifest.files[%d]"%i;object_(row,p,("path","sha256"),{"path","sha256"});safe_path(row["path"])
        if row["path"].casefold() in paths or row["path"].casefold()=="manifest.json":fail("Duplicate/reserved payload path",p)
        paths.add(row["path"].casefold())
        if not isinstance(row["sha256"],str) or not SHA256.fullmatch(row["sha256"]):fail("Expected lowercase SHA-256",p+".sha256")
    declared={r["path"] for r in manifest["files"]}
    for path in ep.values():
        if path not in declared:fail("Entrypoint is not a declared payload",path)
    if "preview" in manifest and manifest["preview"] not in declared:fail("Preview is not declared","manifest.preview")
    dependencies=manifest.get("dependencies",[])
    if not isinstance(dependencies,list):fail("Expected dependency list","manifest.dependencies")
    seen=set()
    for i,dep in enumerate(dependencies):
        p="manifest.dependencies[%d]"%i;object_(dep,p,("packageId","version"),{"packageId","version","digest"})
        package_id(dep["packageId"],p)
        if dep["packageId"]==manifest["packageId"] or dep["packageId"] in seen:fail("Self or duplicate dependency",p)
        seen.add(dep["packageId"]);matches_version("0.0.0",dep["version"])
        if "digest" in dep and not SHA256.fullmatch(str(dep["digest"])):fail("Invalid dependency digest",p)
    boolean_map(manifest.get("integrationDefaults",{}),CHANNELS,"manifest.integrationDefaults")
    return manifest

def reference(value,path,types,nullable=False):
    if value is None and nullable:return
    text_(value,path,300)
    m=re.fullmatch(r"(builtin|self):([a-zA-Z]+)/(.+)|mod:([0-9a-f-]+)/([a-zA-Z]+)/(.+)",value)
    if not m:fail("Expected an explicit builtin:, self: or mod: reference",path)
    kind=m.group(2) or m.group(5)
    if kind not in types:fail("Reference type is incompatible",path)
    if m.group(4):package_id(m.group(4),path)
    return value

def validate_hero(hero,path):
    req=("id","variant","name","unitType","quality","signType","actionType","damageType","baseStats","growth","speed","attackRange","leadership","levelCap","progression","skills","presentation")
    object_(hero,path,req,set(req)|{"description","role","integrationDefaults","acquisition","destiny"})
    local_id(hero["id"],path+".id");local_id(hero["variant"],path+".variant");text_(hero["name"],path+".name")
    enum(hero["unitType"],("hero",),path+".unitType")
    number(hero["quality"],path+".quality",2,6,True)
    enum(hero["signType"],("attack","tank","assist"),path+".signType")
    enum(hero["actionType"],("forward","sly","stand","cunning"),path+".actionType")
    enum(hero["damageType"],("physical","magic","true"),path+".damageType")
    for key in ("baseStats","growth"):
        object_(hero[key],path+"."+key,STATS,set(STATS))
        for stat in STATS:number(hero[key][stat],path+"."+key+"."+stat,1 if key=="baseStats" and stat=="health" else 0)
    for key,low,high in (("speed",0,10000),("attackRange",0,10000),("leadership",0,10000),("levelCap",1,99)):
        number(hero[key],path+"."+key,low,high,True)
    for stat in STATS:number(hero["baseStats"][stat]+hero["growth"][stat]*(hero["levelCap"]-1),path+".levelCapStats."+stat)
    progression=object_(hero["progression"],path+".progression",("preset","starUp"),{"preset","starUp"})
    enum(progression["preset"],("builtin:progression/default-player-hero",),path+".progression.preset")
    reference(progression["starUp"],path+".progression.starUp",("hero",),True)
    skills=object_(hero["skills"],path+".skills",("normal","captain","passive"),{"normal","captain","passive"})
    for key,value in skills.items():reference(value,path+".skills."+key,("skill",),True)
    p=object_(hero["presentation"],path+".presentation",("portrait","icon","basicAttackEffect","voice"),{"portrait","icon","basicAttackEffect","voice"})
    reference(p["portrait"],path+".presentation.portrait",("portrait","asset"));reference(p["icon"],path+".presentation.icon",("icon","asset"))
    reference(p["basicAttackEffect"],path+".presentation.basicAttackEffect",("effect",));reference(p["voice"],path+".presentation.voice",("audio","asset"),True)
    boolean_map(hero.get("integrationDefaults",{}),CHANNELS,path+".integrationDefaults")
    if hero.get("acquisition") not in (None,{}):fail("API 1 uses the documented channel templates; custom acquisition parameters are not open",path+".acquisition","ModIncompatible")
    if hero.get("destiny") not in (None,{},[]):fail("API 1 has no authored destiny adapter; this interaction is marked unavailable",path+".destiny","ModIncompatible")

def skill_extension_capabilities(skill):
    if skill.get('model')=='native-template-v1':return {'skill.native-template.v1'}
    caps=set()
    if "rankInfoTemplate" in skill:caps.add("skill.description.rank-template")
    for action in skill.get("actions",[]):
        if action.get("type")=="move_to_target":caps.add("skill.move_to_target")
        if action.get("lockOnly"):caps.add("skill.target.lock-only")
        if action.get("maxTargets")==-1:caps.add("skill.target.unlimited")
    return caps

def validate_skill(skill,path):
    if isinstance(skill,dict) and skill.get('model')=='native-template-v1':
        from mod_native import validate_shape
        return validate_shape(skill,path)
    required=("id","name","description","timingUnit","warmup","cooldown","range","targetPolicy","actions","upgrades")
    object_(skill,path,required,set(required)|{"maxLevel","aoe","banStand","rankInfoTemplate"})
    local_id(skill["id"],path+".id");text_(skill["name"],path+".name");text_(skill["description"],path+".description",4000,True)
    enum(skill["timingUnit"],("ownerTurns",),path+".timingUnit")
    number(skill["warmup"],path+".warmup",0,100,True);number(skill["cooldown"],path+".cooldown",1,100,True)
    number(skill["range"],path+".range",0,10000,True);enum(skill["targetPolicy"],POLICIES,path+".targetPolicy")
    if "maxLevel" in skill:number(skill["maxLevel"],path+".maxLevel",10,10,True)
    if "aoe" in skill:number(skill["aoe"],path+".aoe",-1,6,True)
    if "banStand" in skill and type(skill["banStand"]) is not bool:fail("Expected boolean",path+".banStand")
    if "rankInfoTemplate" in skill:text_(skill["rankInfoTemplate"],path+".rankInfoTemplate",4000,True)
    actions=skill["actions"]
    if not isinstance(actions,list) or not 1<=len(actions)<=LIMITS["skillActions"]:fail("Expected 1..32 actions",path+".actions")
    for i,action in enumerate(actions):
        p=path+".actions[%d]"%i
        object_(action,p,("type","effect"),{"type","coefficient","damageType","duration","amount","effect","targetPolicy","maxTargets","lockToAction","lockOnly","distance"})
        enum(action["type"],ACTIONS,p+".type");reference(action["effect"],p+".effect",("effect",),True)
        moving=action["type"]=="move_to_target"
        if action["type"] not in ("purify","move_to_target"):number(action.get("coefficient"),p+".coefficient",0,1000)
        if moving:
            number(action.get("distance"),p+".distance",0,10000,True)
            if any(key in action for key in ("coefficient","damageType","duration","amount")):fail("Movement has distance, not damage/status fields",p)
            if action.get("maxTargets",1)!=1:fail("Movement selects exactly one target",p+".maxTargets")
            if action.get("lockOnly"):fail("Movement uses its explicit native target policy; lock-only is for follow-up actions",p+".lockOnly")
        elif "distance" in action:fail("Distance is only supported by movement",p+".distance")
        if action["type"] in ("damage","stun","silence","weak","sunder","poison"):enum(action.get("damageType"),("physical","magic"),p+".damageType")
        if action["type"] not in ("damage","cure","move_to_target"):number(action.get("duration"),p+".duration",1,100,True)
        if action["type"] in ("weak","sunder","poison"):number(action.get("amount"),p+".amount",0,1000)
        if "targetPolicy" in action:enum(action["targetPolicy"],POLICIES,p+".targetPolicy")
        beneficial=action["type"] in ("cure","shield","hp_shield","caster_hp_shield","target_hp_shield","strong","purify","armor")
        policy=action.get("targetPolicy",skill["targetPolicy"])
        if policy.startswith("ally_")!=beneficial:fail("Action and target side are incompatible",p+".targetPolicy")
        if action["type"]=="armor" and policy!="ally_self":fail("Armor currently applies only to the caster",p+".targetPolicy")
        if "maxTargets" in action:
            number(action["maxTargets"],p+".maxTargets",-1,6,True)
            if action["maxTargets"]==0:fail("Use -1 for all valid targets, or 1..6",p+".maxTargets")
        if "lockOnly" in action:
            if type(action["lockOnly"]) is not bool:fail("Expected boolean",p+".lockOnly")
            if action["lockOnly"] and "lockToAction" not in action:fail("Lock-only targeting requires an earlier action",p+".lockOnly")
        if "lockToAction" in action:number(action["lockToAction"],p+".lockToAction",0,i-1,True)
        if "lockToAction" in action:
            previous=actions[action["lockToAction"]].get("targetPolicy",skill["targetPolicy"])
            if previous.startswith("ally_")!=beneficial:fail("Action lock crosses incompatible target sides",p+".lockToAction")
    template=skill.get("rankInfoTemplate","")
    for match in re.finditer(r"\{(rank|flat):(\d+):([0-9.]+)\}",template):
        index=int(match[2]);field=match[3]
        if index>=len(actions):fail("Description template action is missing",path+".rankInfoTemplate")
        action=actions[index];kind=action["type"]
        numeric={"1"} if kind not in ("purify","move_to_target") else set()
        if kind in ("damage","stun","silence","weak","sunder","poison"):numeric.add("2")
        if kind in ("stun","silence"):numeric.add("3")
        if kind in ("weak","sunder","poison"):numeric.update(("3","4"))
        if kind=="purify":numeric.add("1")
        elif kind not in ("damage","cure","move_to_target","stun","silence","weak","sunder","poison"):numeric.add("2")
        if kind=="move_to_target":numeric.add("2")
        if field not in numeric:fail("Description template must reference a numeric action field",path+".rankInfoTemplate")
    # Only the reviewed rank/flat numeric tokens are authored; do not retain
    # legacy scale tokens that implicitly depend on the first action's type.
    if re.search(r"\{(?:rank|flat|scale):",re.sub(r"\{(?:rank|flat):\d+:[0-9.]+\}","",template)):
        fail("Unsupported description template token",path+".rankInfoTemplate")
    upgrades=skill["upgrades"]
    if not isinstance(upgrades,list) or len(upgrades)>128:fail("Invalid upgrade list",path+".upgrades")
    upgrade_paths=set()
    for i,up in enumerate(upgrades):
        p=path+".upgrades[%d]"%i;object_(up,p,("action","field","perLevel"),{"action","field","perLevel"})
        number(up["action"],p+".action",0,len(actions)-1,True);enum(up["field"],("coefficient","amount"),p+".field")
        if up["field"] not in actions[up["action"]]:fail("Upgrade field absent from action",p)
        key=(up["action"],up["field"])
        if key in upgrade_paths:fail("Duplicate upgrade path",p)
        upgrade_paths.add(key);number(up["perLevel"],p+".perLevel",-1000,1000)
        number(actions[key[0]][key[1]]+up["perLevel"]*(skill.get("maxLevel",10)-1),p+".maximumLevelValue",0,1000)

PATCH_PATHS = {"name","description","role","speed","attackRange","leadership","damageType"} | {"baseStats."+s for s in STATS} | {"growth."+s for s in STATS} | {"skills."+s for s in ("normal","captain","passive")} | {"presentation."+s for s in ("portrait","icon","voice","basicAttackEffect")}
PATCH_PATHS |= {"skills."+s+"."+f for s in ("normal","captain","passive") for f in ("cooldown","warmup","range","description")}
NULLABLE_PATHS={"skills.normal","skills.captain","skills.passive","presentation.voice"}

def validate_patch(patch,path):
    object_(patch,path,("id","target","expect","operations"),{"id","target","expect","operations","integrationDefaults","patchScopes"})
    local_id(patch["id"],path+".id");reference(patch["target"],path+".target",("avatar","hero"))
    expected=object_(patch["expect"],path+".expect",("path",),{"path","sha256","value"})
    if expected["path"] not in PATCH_PATHS:fail("Unknown expectation path",path+".expect.path")
    if ("sha256" in expected)==("value" in expected):fail("Provide exactly one sha256 or value expectation",path+".expect")
    if "sha256" in expected and not SHA256.fullmatch(str(expected["sha256"])):fail("Invalid SHA-256",path+".expect.sha256")
    operations=patch["operations"]
    if not isinstance(operations,list) or not 1<=len(operations)<=64:fail("Expected 1..64 operations",path+".operations")
    for i,op in enumerate(operations):
        p=path+".operations[%d]"%i;object_(op,p,("op","path"),{"op","path","value","expect"})
        enum(op["op"],("replace","set","clear"),p+".op")
        if op["path"] not in PATCH_PATHS:fail("Path is not open for v1 patching (persistent progression changes require migration)",p+".path")
        if op["op"]=="clear":
            if op["path"] not in NULLABLE_PATHS or "value" in op:fail("Only optional slots may be cleared",p)
        elif "value" not in op:fail("Missing replacement value",p+".value")
        elif op["value"] is None:fail("Use the explicit clear operation to disable optional content",p+".value")
        if op['path']=='damageType':enum(op.get('value'),('physical','magic','true'),p+'.value')
        if op["op"]=="set" and expected["path"]!=op["path"] and "expect" not in op:fail("Single-field set requires an exact field expectation",p)
    boolean_map(patch.get("integrationDefaults",{}),CHANNELS,path+".integrationDefaults")
    boolean_map(patch.get("patchScopes",{}),SCOPES,path+".patchScopes")

def validate_data(manifest,data):
    for kind,doc in data.items():
        object_(doc,kind,(kind,),{kind})
        rows=doc[kind]
        if not isinstance(rows,list) or len(rows)>LIMITS["entities"]:fail("Expected bounded entity list",kind)
        if kind in ("heroes","patches") and not rows and manifest["kind"]==("new" if kind=="heroes" else "patch"):fail("Main entity list cannot be empty",kind)
        seen=set()
        for i,row in enumerate(rows):
            p=kind+"[%d]"%i
            if kind=="heroes":
                validate_hero(row,p);key=(row["id"],row["variant"])
                if row['damageType']=='true' and 'hero.damage.true' not in manifest.get('requiredCapabilities',[]):
                    fail('Declare required capability hero.damage.true',p+'.damageType','ModIncompatible')
            elif kind=="skills":
                validate_skill(row,p);key=row["id"]
                missing=skill_extension_capabilities(row)-set(manifest.get("requiredCapabilities",[]))
                if missing:fail("Declare required capabilities: "+", ".join(sorted(missing)),p,"ModIncompatible")
            elif kind=="patches":
                validate_patch(row,p);key=row["id"]
                if any(op['path']=='damageType' for op in row['operations']) and 'hero.patch.damage-type' not in manifest.get('requiredCapabilities',[]):
                    fail('Declare required capability hero.patch.damage-type',p,'ModIncompatible')
            else:fail("Custom effects are not open in API 1; reference a builtin effect",p,"ModIncompatible")
            if key in seen:fail("Duplicate entity ID/variant",p)
            seen.add(key)
    if manifest["kind"]=="patch" and data.get("heroes",{}).get("heroes"):fail("Patch cannot hide newly ownable heroes; use a separate new package","heroes")
    return data
