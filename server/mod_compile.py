"""Per-save Mod configuration compiler, with reversible scoped patch layers."""
from __future__ import annotations

import copy
from dataclasses import dataclass

from mod_schema import (CAPABILITIES, CHANNELS, ENGINE_API, LIMITS, PATCH_PATHS, SCOPES, STATS,
                        ModError, boolean_map, canonical, digest, enum, fail,
                        matches_version, number, object_, reference, text_)

# Trusted builtin data may be reused only through this reviewed generic profile.
# In particular hitup/fleeup are historical no-ops, and ID-dependent summons,
# ability callbacks and bespoke conditional actions are not public API 1.
PUBLIC_BUILTIN_ACTIONS=frozenset(("damage","cure","shield","hp_shield","caster_hp_shield","target_hp_shield",
 "stun","silence","weak","sunder","poison","burn","strong","purify","armor","attrup","combo","suck",
 "pull","push","dash","reline","gank","taunt","bless","steel","evil","back",
 "move_to_target","move_to_target_lane","move_self","move_to_ally","select_target"))

@dataclass
class CompiledModConfig:
    document: dict
    roster: dict
    runtime: dict
    digest: str
    preview: dict
    warnings: list

def normalize_settings(settings):
    if settings is None:settings={}
    if isinstance(settings,list):settings={"packages":settings}
    object_(settings,"settings")
    raw=settings.get("packages",settings.get("selections",[]))
    if isinstance(raw,dict):raw=[dict(value,packageId=pid) for pid,value in raw.items()]
    if not isinstance(raw,list) or len(raw)>128:fail("Expected at most 128 package selections","settings.packages")
    result=[];seen=set()
    for i,entry in enumerate(raw):
        p="settings.packages[%d]"%i;object_(entry,p,("packageId","version"))
        row=copy.deepcopy(entry);row.setdefault("enabled",True)
        if type(row["enabled"]) is not bool:fail("Expected boolean",p+".enabled")
        row["digest"]=row.get("digest",row.get("contentDigest"))
        if row["packageId"] in seen:fail("Only one version of a package may be selected",p)
        seen.add(row["packageId"])
        boolean_map(row.get("channels",{}),CHANNELS,p+".channels")
        boolean_map(row.get("patchScopes",{}),SCOPES,p+".patchScopes")
        object_(row.get("heroes",{}),p+".heroes")
        for key,hero in row.get("heroes",{}).items():
            object_(hero,p+".heroes."+key,allowed={"channels","patchScopes"})
            boolean_map(hero.get("channels",{}),CHANNELS,p+".heroes."+key+".channels")
            boolean_map(hero.get("patchScopes",{}),SCOPES,p+".heroes."+key+".patchScopes")
        result.append(row)
    return {"packages":result,"knownHeroes":copy.deepcopy(settings.get("knownHeroes",{}))}

def _hero_override(selection,identity,aid,local):
    choices=selection.get("heroes",{})
    return choices.get(identity,choices.get(aid,choices.get(local,{})))

def _options(pkg,selection,entity,identity,aid,local):
    channels={key:True for key in CHANNELS};channels.update(pkg.manifest.get("integrationDefaults",{}));channels.update(entity.get("integrationDefaults",{}));channels.update(selection.get("channels",{}))
    override=_hero_override(selection,identity,aid,local)
    channels.update(override.get("channels",{}))
    scopes={key:True for key in SCOPES};scopes.update(entity.get("patchScopes",{}));scopes.update(selection.get("patchScopes",{}));scopes.update(override.get("patchScopes",{}))
    return channels,scopes

def _defaults(pkg,entity):
    channels={key:True for key in CHANNELS};channels.update(pkg.manifest.get("integrationDefaults",{}));channels.update(entity.get("integrationDefaults",{}))
    scopes={key:True for key in SCOPES};scopes.update(entity.get("patchScopes",{}))
    return channels,scopes

def _dependency_order(packages,selected):
    ordered=[];visiting=set();done=set()
    def visit(pid,depth=0):
        if depth>16:fail("Dependency depth exceeds 16",pid,"ModDependencyCycle")
        if pid in visiting:fail("Dependency cycle",pid,"ModDependencyCycle")
        if pid in done:return
        visiting.add(pid)
        for dep in packages[pid].manifest.get("dependencies",[]):
            other=packages.get(dep["packageId"])
            if other is None:fail("Required package is not enabled",pid+" → "+dep["packageId"],"ModMissingDependency")
            if not matches_version(other.version,dep["version"]) or dep.get("digest",other.digest)!=other.digest:fail("Dependency version/content contract failed",pid+" → "+dep["packageId"],"ModIncompatibleDependency")
            visit(other.package_id,depth+1)
        visiting.remove(pid);done.add(pid);ordered.append(packages[pid])
    for pid in sorted(packages):visit(pid)
    return ordered

def _declares_dependency(pkg,target_pid,packages):
    pending=[d["packageId"] for d in pkg.manifest.get("dependencies",[])];seen=set()
    while pending:
        current=pending.pop()
        if current==target_pid:return True
        if current in seen:continue
        seen.add(current)
        if current in packages:pending.extend(d["packageId"] for d in packages[current].manifest.get("dependencies",[]))
    return False

class Compiler:
    def __init__(self,catalog,base,settings,roster,allow_missing):
        self.catalog=catalog;self.base=copy.deepcopy(base);self.document=copy.deepcopy(base)
        if "cfg" not in self.document:self.document={"cfg":self.document}
        self.cfg=self.document["cfg"];self.settings=normalize_settings(settings)
        self.roster=copy.deepcopy(roster or {});self.allow_missing=allow_missing
        self.packages={};self.selected={};self.hero_refs={};self.skill_refs={};self.hero_authored={}
        self.assets={};self.texture_aliases={};self.preview={"added":[],"patches":[],"missing":[],"packages":[],"warnings":[]}
        self.warnings=[];self.metadata={};self.missing=[];self.resolving=set();self.writes={}
        self.scoped={scope:{} for scope in SCOPES};self.aliases={}
        for table in ("avatar","skill","effect"):self.cfg.setdefault(table,{})
    def load(self):
        absent=set()
        for row in self.settings["packages"]:
            if not row["enabled"]:continue
            try:pkg=self.catalog.get(row["packageId"],row["version"],row.get("digest"))
            except ModError as exc:
                if not self.allow_missing:raise
                absent.add(row["packageId"]);self.warnings.append({"packageId":row["packageId"],**exc.as_dict()});continue
            self.packages[pkg.package_id]=pkg;self.selected[pkg.package_id]=row
        if self.allow_missing:
            # Remove complete dependent packages, never apply their surviving half.
            changed=True
            while changed:
                changed=False
                for pid,pkg in list(self.packages.items()):
                    if any(dep["packageId"] not in self.packages or not matches_version(self.packages[dep["packageId"]].version,dep["version"]) or dep.get("digest",self.packages[dep["packageId"]].digest)!=self.packages[dep["packageId"]].digest for dep in pkg.manifest.get("dependencies",[])):
                        del self.packages[pid];self.warnings.append({"packageId":pid,"code":"ModMissingDependency","message":"Disabled due to missing/incompatible dependency"});changed=True
        self.ordered=_dependency_order(self.packages,self.selected)
        # Bound the effective combination before reserving permanent IDs. A
        # collection of individually legal packages must not multiply quotas.
        counts={"activeHeroes":0,"activeSkills":0,"activePatches":0,"activePatchOperations":0,"combinedDataBytes":0}
        for pkg in self.ordered:
            counts["activeHeroes"]+=len(pkg.data.get("heroes",{}).get("heroes",[]))
            counts["activeSkills"]+=len(pkg.data.get("skills",{}).get("skills",[]))
            patches=pkg.data.get("patches",{}).get("patches",[])
            counts["activePatches"]+=len(patches)
            counts["activePatchOperations"]+=sum(len(row["operations"]) for row in patches)
            counts["combinedDataBytes"]+=len(canonical(pkg.data))
        for key,count in counts.items():
            if count>LIMITS[key]:fail("Combined Mod configuration exceeds "+key+" quota","packages","ModQuotaExceeded")
        for pkg in self.ordered:
            self.preview["packages"].append(pkg.metadata())
            for skill in pkg.data.get("skills",{}).get("skills",[]):
                self.skill_refs[(pkg.package_id,skill["id"])]=self.catalog.allocate_skill("mod:"+pkg.package_id+"/skill/"+skill["id"])
            for hero in pkg.data.get("heroes",{}).get("heroes",[]):
                identity=f"mod:{pkg.package_id}/hero/{hero['id']}/{hero['variant']}"
                aid=self.catalog.allocate_hero(pkg.package_id,hero["id"],hero["variant"],hero["quality"],{"name":hero["name"],"packageName":pkg.manifest["name"],"progression":hero["progression"],"levelCap":hero["levelCap"],"unitType":"hero"})
                self.hero_refs[identity]=aid;self.hero_authored[aid]=(pkg,hero)
        if len(self.hero_authored)>LIMITS["activeHeroes"]:fail("Active hero count exceeds the combined configuration limit","packages","ModQuotaExceeded")
    def resolve(self,value,pkg,types,path="",nullable=False):
        if value is None and nullable:return None
        reference(value,path,types,nullable)
        domain,tail=value.split(":",1)
        owner=pkg
        if domain=="mod":
            pid,kind,local=tail.split("/",2)
            if not any(d["packageId"]==pid for d in pkg.manifest.get("dependencies",[])):fail("Reference requires an explicit direct package dependency",path,"ModMissingDependency")
            if pid not in self.packages:fail("Referenced dependency is unavailable",path,"ModMissingDependency")
            owner=self.packages[pid]
        else:kind,local=tail.split("/",1)
        if domain=="builtin":
            if kind in ("avatar","hero","portrait","icon"):
                if local not in self.base.get("cfg",self.base).get("avatar",{}):fail("Builtin hero/resource does not exist",value,"ModMissingReference")
                if kind in ("portrait","icon"):return self.base.get("cfg",self.base)["avatar"][local].get("res",local)
                return local
            table={"skill":"skill","effect":"effect"}.get(kind)
            if table:
                if local not in self.base.get("cfg",self.base).get(table,{}):fail("Builtin reference does not exist",value,"ModMissingReference")
                return local
            if kind=="audio":
                # Builtin sound names must be evidenced by an actual effect sound.
                sounds=set()
                def walk(v):
                    if isinstance(v,dict):
                        if isinstance(v.get("s"),dict) and isinstance(v["s"].get("id"),str):sounds.add(v["s"]["id"])
                        for x in v.values():walk(x)
                    elif isinstance(v,list):
                        for x in v:walk(x)
                walk(self.base.get("cfg",self.base).get("effect",{}))
                if local not in sounds:fail("Unknown builtin audio reference",value,"ModMissingReference")
                return local
            fail("Unsupported builtin reference type",value,"ModMissingReference")
        if kind in ("hero","avatar"):
            identity=f"mod:{owner.package_id}/hero/{local}"
            if identity not in self.hero_refs:fail("Unknown hero variant reference",value,"ModMissingReference")
            return self.hero_refs[identity]
        if kind=="skill":
            result=self.skill_refs.get((owner.package_id,local))
            if result is None:fail("Unknown private skill",value,"ModMissingReference")
            return result
        if kind=="asset":
            # self:asset/portrait.png is shorthand for assets/portrait.png.
            candidate=local if local in owner.media else "assets/"+local
            if candidate not in owner.media:fail("Asset missing or not decodable media",value,"ModMissingReference")
            return {"package":owner,"path":candidate,"media":owner.media[candidate]}
        fail("Unsupported private reference type",value,"ModMissingReference")
    def add_asset(self,resolved,alias,role):
        if not isinstance(resolved,dict):return resolved
        required="sound" if role=="voice" else "image"
        if resolved["media"]["kind"]!=required:fail("Media type does not match usage",alias,"ModInvalidReference")
        pkg=resolved["package"];path=resolved["path"];sha=next(r["sha256"] for r in pkg.manifest["files"] if r["path"]==path)
        row={"alias":alias,"kind":required,"contentDigest":pkg.digest,"path":path,"sha256":sha,"packageId":pkg.package_id,"version":pkg.version,"role":role}
        for key in ("width","height","bytes","duration","decodedBytes"):
            if key in resolved["media"]:row[key]=resolved["media"][key]
        if alias in self.assets and self.assets[alias]!=row:fail("Resource alias collision",alias)
        self.assets[alias]=row;return alias
    def ensure_public_skill(self,sid,path):
        if not sid:return
        skill=self.cfg["skill"].get(sid)
        if not skill:fail("Skill does not exist",path,"ModMissingReference")
        actions=skill.get("skill",[])
        unsafe={"manual_ability","summon","summon_turret","clone_normal"}
        if skill.get("manualSummonPolicy") or skill.get("manualClonePolicy") or any(isinstance(a,list) and a and a[0] in unsafe for a in actions):
            fail("Builtin skill depends on a private hero/skill ability; API 1 does not expose rebinding or field patching it",path,"ModIncompatible")
        if any(not isinstance(a,list) or not a or a[0] not in PUBLIC_BUILTIN_ACTIONS for a in actions):
            fail("Builtin skill contains an action outside the reviewed generic reference profile",path,"ModIncompatible")
    def presentation(self,row,pkg,key):
        presentation=row["presentation"]
        portrait=self.resolve(presentation["portrait"],pkg,("portrait","asset"),"presentation.portrait")
        icon=self.resolve(presentation["icon"],pkg,("icon","asset"),"presentation.icon")
        # Always use one managed alias, so portrait-only/icon-only patches work.
        res="MOD_"+digest(key)[:24]
        if isinstance(portrait,dict):self.add_asset(portrait,res,"portrait")
        else:self.texture_aliases[res]=portrait
        if isinstance(icon,dict):self.add_asset(icon,res+"_icon0000","icon")
        else:self.texture_aliases[res+"_icon0000"]=icon+"_icon0000"
        voice=self.resolve(presentation["voice"],pkg,("audio","asset"),"presentation.voice",True)
        voice=self.add_asset(voice,res+"_voice","voice") if isinstance(voice,dict) else voice
        effect=self.resolve(presentation["basicAttackEffect"],pkg,("effect",),"presentation.basicAttackEffect")
        return res,{"portrait":res,"icon":res+"_icon0000","voice":voice,"basicAttackEffect":effect}
    def skill(self,pkg,skill):
        sid=self.skill_refs[(pkg.package_id,skill["id"])];native=[];upgrade_indices=[]
        policies=[];locks=[];maximum=[]
        for action in skill["actions"]:
            effect=self.resolve(action["effect"],pkg,("effect",),"skill.effect",True) or ""
            kind=action["type"];coefficient=action.get("coefficient",0);duration=action.get("duration",0)
            damage_type=1 if action.get("damageType")=="physical" else 2
            if kind=="damage":raw=[kind,coefficient,damage_type,effect]
            elif kind=="cure":raw=[kind,coefficient,effect]
            elif kind in ("stun","silence"):raw=[kind,coefficient,damage_type,duration,effect]
            elif kind in ("weak","sunder","poison"):raw=[kind,coefficient,damage_type,action["amount"],duration,effect]
            elif kind=="purify":raw=[kind,duration,effect]
            else:raw=[kind,coefficient,duration,effect]
            native.append(raw);policies.append(action.get("targetPolicy",skill["targetPolicy"]));locks.append(action.get("lockToAction"));maximum.append(action.get("maxTargets",1))
        for upgrade in skill["upgrades"]:
            index=3 if upgrade["field"]=="amount" else 1
            upgrade_indices.append([upgrade["action"],index,upgrade["perLevel"]])
        return {"id":sid,"name":skill["name"],"info":skill["description"],"res":sid,
                "pl":[skill["warmup"],skill["cooldown"],skill["range"],0,skill.get("aoe",0),0 if skill.get("banStand",True) else 1],
                "skill":native,"skillUp":upgrade_indices,"targetPolicy":skill["targetPolicy"],
                "actionTargetPolicies":policies,"actionTargetLocks":locks,"actionTargetMaxTargets":maximum,
                "modMaxLevel":skill.get("maxLevel",10)}
    @staticmethod
    def channel_applicability(quality,new=True):
        unavailable={"appearance.expedition_enemy":"Current expedition is dispatch-only and has no random enemy generator", "appearance.campaign_random_enemy":"Current campaign contains fixed formations"}
        if new:unavailable["usage.destiny"]="No declared destiny definitions"
        if quality!=5:unavailable["acquisition.summon.normal"]="Normal pool only has quality-5 playable hero category"
        if quality not in (4,5):unavailable["acquisition.summon.advanced"]="Advanced pool only has quality-4/5 playable hero categories"
        if quality!=5:unavailable["acquisition.summon.activity"]="Current activity summon playable hero category is quality 5"
        if quality!=6:unavailable["acquisition.exchange.hero"]="Current daily hero exchange template is quality 6"
        if quality not in (2,5,6):unavailable["acquisition.shop.hero_soul"]="Current hero-soul shop has templates only for qualities 2, 5 and 6"
        if quality!=6:unavailable["acquisition.drop.tower_hero"]="Current tower whole-hero template is quality 6"
        if quality not in (4,5,6):unavailable["acquisition.drop.tower_soul"]="Current tower hero-soul templates use qualities 4, 5 and 6"
        if quality not in (5,6):unavailable["acquisition.exchange.activity"]="Current activity exchange templates use qualities 5 and 6"
        unavailable["acquisition.drop.activity"]="Current non-tower activity rewards have no random playable-hero slot"
        support={key:{"supported":key not in ("appearance.expedition_enemy","appearance.campaign_random_enemy"),"applicable":key not in unavailable,"reason":unavailable.get(key,"")} for key in CHANNELS}
        return unavailable,support
    def new_hero(self,pkg,hero,aid):
        identity=f"mod:{pkg.package_id}/hero/{hero['id']}/{hero['variant']}"
        skills={key:self.resolve(value,pkg,("skill",),"skills."+key,True) for key,value in hero["skills"].items()}
        for key,sid in skills.items():self.ensure_public_skill(sid,"skills."+key)
        res,presentation=self.presentation(hero,pkg,identity)
        native={"id":aid,"name":hero["name"],"res":res,"role":hero.get("role",hero["signType"]),"info":hero.get("description",""),
                "tl":[{"attack":1,"tank":2,"assist":3}[hero["signType"]],{"forward":1,"sly":2,"stand":3,"cunning":4}[hero["actionType"]],1 if hero["damageType"]=="physical" else 2,hero["leadership"],hero["levelCap"],1,hero["quality"]*25,hero["quality"]*20,[],0,1],
                "pl":[n for stat in STATS for n in (hero["baseStats"][stat],hero["growth"][stat])]+[hero["speed"],hero["attackRange"],skills["normal"],skills["captain"],presentation["basicAttackEffect"],skills["passive"]],
                "skillup":hero["quality"]*100,"love":hero["quality"]*100,"modIdentity":identity,"modVoice":presentation["voice"] or ""}
        channels,scopes=_options(pkg,self.selected[pkg.package_id],hero,identity,aid,hero["id"])
        quality=hero["quality"]
        unavailable,support=self.channel_applicability(quality)
        default_channels,default_scopes=_defaults(pkg,hero)
        for channel in unavailable:channels[channel]=False
        meta={"packageId":pkg.package_id,"packageName":pkg.manifest["name"],"version":pkg.version,"contentDigest":pkg.digest,"identity":identity,"aid":aid,
              "id":hero["id"],"variant":hero["variant"],"name":hero["name"],"kind":"new","unitType":"hero","available":True,"quality":quality,
              "channels":channels,"unavailableChannels":unavailable,"channelSupport":support,"defaultChannels":default_channels,"defaultPatchScopes":default_scopes,"progression":copy.deepcopy(hero["progression"]),"presentation":presentation,"levelCap":hero["levelCap"],"patchScopes":scopes,"acquisition":copy.deepcopy(hero.get("acquisition",{}))}
        self.metadata[aid]=meta;self.cfg["avatar"][aid]=native;self.preview["added"].append(copy.deepcopy(meta))
    def validate_progression(self):
        for aid,(pkg,hero) in self.hero_authored.items():
            target=hero["progression"]["starUp"]
            if target is None:continue
            resolved=self.resolve(target,pkg,("hero",),"progression.starUp")
            if resolved.rsplit("_",1)[0]!=aid.rsplit("_",1)[0] or int(resolved.rsplit("_",1)[1])!=hero["quality"]+1:fail("Star-up must reference the next quality in the same registered family",target)
            self.metadata[aid]["progression"]["starUp"]=resolved
            self.cfg["avatar"][aid]["tl"][8]=["A_"]
    def validate_overrides(self):
        for pkg in self.ordered:
            valid=set()
            for aid,(owner,hero) in self.hero_authored.items():
                if owner.package_id==pkg.package_id:valid.update((aid,hero["id"],f"mod:{pkg.package_id}/hero/{hero['id']}/{hero['variant']}"))
            for patch in pkg.data.get("patches",{}).get("patches",[]):
                aid=self.resolve(patch["target"],pkg,("hero","avatar"),"patch.target")
                valid.update((aid,patch["id"],patch["target"],self.metadata.get(aid,{}).get("identity","builtin:avatar/"+aid)))
            for key in self.selected[pkg.package_id].get("heroes",{}):
                if key not in valid:fail("Hero override target does not belong to this package",f"{pkg.package_id}.heroes.{key}","ModInvalidSettings")
    def logical(self,row,path,cfg=None):
        cfg=cfg or self.cfg
        if path.startswith(("baseStats.","growth.")):
            key,stat=path.split(".");return row["pl"][STATS.index(stat)*2+(key=="growth")]
        if path in ("speed","attackRange"):return row["pl"][8 if path=="speed" else 9]
        if path=="leadership":return row["tl"][3]
        if path in ("name","role"):return row.get(path,"")
        if path=="description":return row.get("info","")
        if path.startswith("skills."):
            parts=path.split(".");index={"normal":10,"captain":11,"passive":13}[parts[1]]
            sid=row["pl"][index] if len(row["pl"])>index else None
            skill=cfg["skill"].get(sid) if sid else None
            if len(parts)==2:return copy.deepcopy(skill)
            if not skill:fail("Cannot patch a field in an empty skill slot",path)
            field=parts[2]
            if field=="description":return skill.get("info","")
            if not isinstance(skill.get("pl"),list) or len(skill["pl"])<3:fail("Passive skill has no active timing or range fields",path,"ModIncompatible")
            return skill["pl"][{"warmup":0,"cooldown":1,"range":2}[field]]
        if path.startswith("presentation."):
            key=path.split(".")[1]
            if key=="basicAttackEffect":return row["pl"][12]
            if key=="voice":return row.get("modVoice")
            return row.get("modPresentation",{}).get(key,row.get("res"))
        fail("Unknown semantic patch path",path)
    def expected(self,row,expect,pkg):
        actual=self.logical(row,expect["path"])
        if "sha256" in expect:
            if digest(actual)!=expect["sha256"]:fail("Target digest differs from patch contract",expect["path"],"ModTargetMismatch")
        else:
            wanted=expect["value"]
            if expect["path"].startswith("skills.") and expect["path"].count(".")==1 and isinstance(wanted,str):
                wanted=self.resolve(wanted,pkg,("skill",),"expect.value")
                actual=actual.get("id") if isinstance(actual,dict) else None
            if canonical(actual)!=canonical(wanted):fail("Target value differs from patch contract",expect["path"],"ModTargetMismatch")
    def apply_op(self,row,op,pkg,scope,aid):
        path=op["path"];value=None if op["op"]=="clear" else op["value"]
        if "expect" in op:
            if canonical(self.logical(row,path))!=canonical(op["expect"]):fail("Field original value differs",path,"ModTargetMismatch")
        before=self.logical(row,path)
        if path.startswith(("baseStats.","growth.")):
            number(value,path,1 if path=="baseStats.health" else 0)
            key,stat=path.split(".");row["pl"][STATS.index(stat)*2+(key=="growth")]=value
        elif path in ("speed","attackRange","leadership"):
            number(value,path,0,10000,True)
            if path=="leadership":row["tl"][3]=value
            else:row["pl"][8 if path=="speed" else 9]=value
        elif path in ("name","description","role"):
            text_(value,path,4000 if path=="description" else 200,True);row["info" if path=="description" else path]=value
        elif path.startswith("skills."):
            parts=path.split(".");index={"normal":10,"captain":11,"passive":13}[parts[1]]
            while len(row["pl"])<=index:row["pl"].append(None)
            if len(parts)==2:
                resolved=self.resolve(value,pkg,("skill",),path,True);self.ensure_public_skill(resolved,path);row["pl"][index]=resolved
            else:
                original=row["pl"][index]
                if not original or original not in self.cfg["skill"]:fail("Cannot patch an empty skill",path)
                self.ensure_public_skill(original,path)
                # Copy-on-write prevents shared skill mutation, including scopes.
                private=self.catalog.allocate_skill(f"patch:{pkg.package_id}:{scope}:{aid}:{parts[1]}:{original}:{digest(op)}",int(original.rsplit("_",1)[-1]))
                skill=copy.deepcopy(self.cfg["skill"][original]);skill["id"]=private
                if parts[2]=="description":
                    text_(value,path,4000,True);skill["info"]=value;skill.pop("rankInfoTemplate",None)
                else:
                    number(value,path,1 if parts[2]=="cooldown" else 0,10000 if parts[2]=="range" else 100,True)
                    skill["pl"][{"warmup":0,"cooldown":1,"range":2}[parts[2]]]=value
                self.cfg["skill"][private]=skill;row["pl"][index]=private
        elif path.startswith("presentation."):
            field=path.split(".")[1]
            if field=="basicAttackEffect":row["pl"][12]=self.resolve(value,pkg,("effect",),path)
            elif field=="voice":
                resolved=self.resolve(value,pkg,("audio","asset"),path,True)
                row["modVoice"]=self.add_asset(resolved,"MOD_"+digest((pkg.digest,aid,scope,path))[:24],"voice") or ""
            else:
                resolved=self.resolve(value,pkg,("portrait" if field=="portrait" else "icon","asset"),path)
                old_res=row["res"];res="MOD_"+digest((pkg.digest,aid,scope,path))[:24]
                # Preserve the other image through a visible alias chain.
                if field=="portrait":
                    self.texture_aliases[res+"_icon0000"]=old_res+"_icon0000"
                    if isinstance(resolved,dict):self.add_asset(resolved,res,"portrait")
                    else:self.texture_aliases[res]=resolved
                else:
                    self.texture_aliases[res]=old_res
                    if isinstance(resolved,dict):self.add_asset(resolved,res+"_icon0000","icon")
                    else:self.texture_aliases[res+"_icon0000"]=resolved+"_icon0000"
                row["res"]=res;row.setdefault("modPresentation",{})[field]=res if field=="portrait" else res+"_icon0000"
        return {"path":path,"before":before,"after":self.logical(row,path)}
    def patches(self):
        original=copy.deepcopy(self.cfg["avatar"])
        views={scope:copy.deepcopy(original) for scope in SCOPES}
        for pkg in self.ordered:
            for patch in pkg.data.get("patches",{}).get("patches",[]):
                aid=self.resolve(patch["target"],pkg,("hero","avatar"),"patch.target")
                if aid not in original:fail("Patch target does not exist",patch["target"],"ModMissingReference")
                if not aid.startswith("A_1"):fail("API 1 patch targets must be hero units; typed NPC/summon variants require a future capability",patch["target"],"ModIncompatible")
                identity=self.metadata.get(aid,{}).get("identity","builtin:avatar/"+aid)
                channels,scopes=_options(pkg,self.selected[pkg.package_id],patch,identity,aid,patch["id"])
                default_channels,default_scopes=_defaults(pkg,patch)
                meta=self.metadata.setdefault(aid,{"aid":aid,"identity":identity,"kind":"builtin","unitType":"hero","available":True,"name":original[aid].get("name",aid),"quality":int(aid.rsplit("_",1)[1]),"channels":{k:True for k in CHANNELS},"progression":{},"packageId":pkg.package_id})
                if "channelSupport" not in meta:
                    unavailable,support=self.channel_applicability(meta["quality"],False)
                    meta["unavailableChannels"]=unavailable;meta["channelSupport"]=support
                meta.setdefault("defaultChannels",default_channels);meta.setdefault("defaultPatchScopes",default_scopes)
                for channel in meta["unavailableChannels"]:channels[channel]=False
                # All active controllers must allow a channel; cancelling a flag
                # in one patch cannot be silently undone by an unrelated patch.
                meta["channels"]={k:meta["channels"].get(k,True) and channels[k] for k in CHANNELS}
                meta.setdefault("patchOwners",[]).append(pkg.package_id)
                for scope,enabled in scopes.items():
                    if not enabled:continue
                    row=views[scope][aid];backup=copy.deepcopy(row);write_backup=copy.deepcopy(self.writes)
                    try:
                        # Check before mutation; explicit dependencies may expect
                        # intermediate data, otherwise check the immutable base.
                        prior=[owner for (s,target,path),owner in self.writes.items() if s==scope and target==aid]
                        depends=any(_declares_dependency(pkg,owner,self.packages) for owner in prior)
                        self.expected(row if depends else original[aid],patch["expect"],pkg)
                        changes=[]
                        for op in patch["operations"]:
                            for (written_scope,written_aid,written_path),owner in self.writes.items():
                                if written_scope==scope and written_aid==aid and (written_path==op["path"] or written_path.startswith(op["path"]+".") or op["path"].startswith(written_path+".")):
                                    if not _declares_dependency(pkg,owner,self.packages):fail("Overlapping patches require explicit dependency and intermediate expectation",aid+"."+op["path"],"ModPatchConflict")
                                    guarded=patch["expect"]["path"]
                                    if "expect" not in op and guarded!=op["path"] and not op["path"].startswith(guarded+"."):fail("Dependent overlap must guard the overwritten logical unit, not an unrelated field",aid+"."+op["path"],"ModPatchConflict")
                            changes.append(self.apply_op(row,op,pkg,scope,aid));self.writes[(scope,aid,op["path"])]=pkg.package_id
                        for index in range(4):number(row["pl"][2*index]+row["pl"][2*index+1]*(row["tl"][4]-1),f"{aid}.maxLevelStats[{index}]")
                    except ModError as exc:
                        views[scope][aid]=backup;self.writes=write_backup
                        exc.package_id=pkg.package_id
                        raise
                    self.preview["patches"].append({"packageId":pkg.package_id,"patchId":patch["id"],"target":aid,"scope":scope,"changes":changes,"sourceNotes":pkg.manifest.get("sourceNotes")})
        # Owned definition is the UI/default view. Every distinct enemy/assist
        # definition receives an explicit alias, retaining a stable base identity.
        self.cfg["avatar"]=views["owned"]
        for scope in SCOPES:
            for aid in sorted(set(target for s,target,p in self.writes)):
                row=views[scope][aid]
                if canonical(row)==canonical(views["owned"][aid]):continue
                quality=int(aid.rsplit("_",1)[1]);alias=self.catalog.allocate_alias(f"{scope}:{aid}:{digest(row)}",quality)
                native=copy.deepcopy(row);native["id"]=alias;native["modBaseAid"]=aid
                self.cfg["avatar"][alias]=native;self.scoped[scope][aid]=alias;self.aliases[alias]=aid
    def add_missing(self):
        known=self.settings["knownHeroes"]
        if not isinstance(known,dict):fail("knownHeroes must be an object")
        for aid,meta in known.items():
            if aid in self.metadata or not isinstance(meta,dict) or meta.get("kind")!="new":continue
            # Only a saved permanent identity may be a placeholder; never turn
            # an arbitrary missing native hero into a silently usable card.
            if not isinstance(meta.get("identity"),str) or not meta["identity"].startswith("mod:"):fail("Invalid saved Mod hero identity",str(aid))
            old=copy.deepcopy(meta);old.update({"aid":aid,"available":False,"missingReason":"Required package is disabled, missing or invalid","channels":{k:False for k in CHANNELS}})
            self.metadata[aid]=old;self.missing.append(aid)
            self.cfg["avatar"][aid]={"id":aid,"name":"内容缺失："+str(meta.get("name",aid)),"res":"__modMissingHero","tl":[3,1,1,0,max(1,int(meta.get("levelCap",99))),1,0,0,[],0,1],"pl":[1,0,0,0,0,0,0,0,0,0,None,None,None,None],"skillup":0,"love":0,"modMissing":True,"modIdentity":meta["identity"]}
            self.preview["missing"].append(copy.deepcopy(old))
    def activity_exchange(self):
        simple=self.cfg.get("ploy_system_simple",{})
        rows=simple.get("timed_exchange")
        if isinstance(rows,list):
            templates={};existing=set();filtered=[]
            for row in rows:
                if not isinstance(row,dict):filtered.append(row);continue
                retained={}
                for aid,price in row.items():
                    if aid.startswith("A_1") and aid.rsplit("_",1)[-1] in ("5","6") and type(price) in (int,float) and price>0:templates.setdefault(int(aid.rsplit("_",1)[-1]),price)
                    meta=self.metadata.get(aid)
                    if meta and (not meta["available"] or not meta["channels"].get("acquisition.exchange.activity",True)):continue
                    retained[aid]=price;existing.add(aid)
                if retained:filtered.append(retained)
            for aid,meta in self.metadata.items():
                if meta.get("kind")=="new" and meta["available"] and meta["channels"].get("acquisition.exchange.activity",False) and aid not in existing:
                    price=templates.get(meta["quality"])
                    if price is None:
                        meta["channels"]["acquisition.exchange.activity"]=False
                        meta["unavailableChannels"]["acquisition.exchange.activity"]="No same-quality activity exchange template is configured"
                        meta["channelSupport"]["acquisition.exchange.activity"]={"supported":True,"applicable":False,"reason":meta["unavailableChannels"]["acquisition.exchange.activity"]}
                    else:filtered.append({aid:price})
            simple["timed_exchange"]=filtered
        extract=simple.get("extract_avatar",{})
        if isinstance(extract,dict) and isinstance(extract.get("exchange"),list):
            def references(v):
                if isinstance(v,dict):
                    for key,value in v.items():
                        if key in self.metadata:yield key
                        if key=="aid" and isinstance(value,str) and value in self.metadata:yield value
                        yield from references(value)
                elif isinstance(v,list):
                    for child in v:yield from references(child)
            extract["exchange"]=[row for row in extract["exchange"] if all(self.metadata[aid]["available"] and self.metadata[aid]["channels"].get("acquisition.exchange.activity",True) for aid in references(row))]
    def finish(self):
        self.load()
        for pkg in self.ordered:
            for skill in pkg.data.get("skills",{}).get("skills",[]):
                try:native=self.skill(pkg,skill);self.cfg["skill"][native["id"]]=native
                except ModError as exc:exc.package_id=pkg.package_id;raise
        for aid,(pkg,hero) in self.hero_authored.items():
            try:self.new_hero(pkg,hero,aid)
            except ModError as exc:exc.package_id=pkg.package_id;raise
        self.validate_progression();self.validate_overrides();self.patches();self.add_missing();self.activity_exchange()
        baseline=self.base.get("cfg",self.base).get("skill",{})
        if len(set(self.cfg["skill"])-set(baseline))>LIMITS["activeSkills"]:fail("Compiled Mod skills including scoped copies exceed quota","skills","ModQuotaExceeded")
        # Client aliases are flattened so arbitrarily long compatible patch
        # chains never rely on a client recursion limit or another package cache.
        for alias in self.texture_aliases:
            value=self.texture_aliases[alias];seen={alias}
            while value in self.texture_aliases and value not in self.assets:
                if value in seen:fail("Resource alias cycle",alias,"ModInvalidReference")
                seen.add(value);value=self.texture_aliases[value]
            self.texture_aliases[alias]=value
        if sum(row.get("width",0)*row.get("height",0)*4 for row in self.assets.values() if row["kind"]=="image")>LIMITS["textureBytes"]:fail("Combined decoded Mod textures exceed 128 MiB","assets","ModQuotaExceeded")
        if sum(row.get("bytes",0) for row in self.assets.values())>LIMITS["mediaBytes"]:fail("Combined Mod media exceed 128 MiB","assets","ModQuotaExceeded")
        if sum(row.get("decodedBytes",0) for row in self.assets.values() if row["kind"]=="sound")>LIMITS["decodedAudioBytes"]:fail("Combined decoded Mod audio exceeds 128 MiB","assets","ModQuotaExceeded")
        for aid,row in self.metadata.items():
            if row["available"]:
                native=self.cfg["avatar"][aid]
                for index in (10,11,13):
                    sid=native["pl"][index] if len(native["pl"])>index else None
                    if sid and sid not in self.cfg["skill"]:fail("Compiled hero references missing skill",aid)
        summary={"api":ENGINE_API,"base":digest(self.base),"effective":digest(self.cfg),"roster":digest(self.roster),"selections":[{**self.selected[p.package_id],"digest":p.digest} for p in self.ordered],"metadata":self.metadata,"scopeAliases":self.scoped,"warnings":self.warnings}
        effective_digest=digest(summary)
        runtime={"digest":effective_digest,"engineApi":ENGINE_API,"heroes":self.metadata,"scopedAvatarIds":self.scoped,"aliasBaseIds":self.aliases,"missingHeroIds":sorted(self.missing),"knownHeroIds":sorted(self.metadata),"assets":sorted(self.assets.values(),key=lambda r:r["alias"]),"textureAliases":self.texture_aliases,"packages":[{"packageId":p.package_id,"version":p.version,"contentDigest":p.digest} for p in self.ordered],"warnings":self.warnings,"errors":copy.deepcopy(self.warnings),"capabilities":sorted(CAPABILITIES)}
        if self.ordered or self.missing or self.warnings:self.cfg["mod_runtime"]=runtime
        self.roster["heroes"]=copy.deepcopy(self.cfg["avatar"]);self.roster["skills"]=copy.deepcopy(self.cfg["skill"]);self.roster["effects"]=copy.deepcopy(self.cfg["effect"])
        if self.ordered or self.missing or self.warnings:self.roster["mod_runtime"]=copy.deepcopy(runtime)
        self.preview["warnings"]=self.warnings;self.preview["digest"]=effective_digest
        return CompiledModConfig(self.document,self.roster,runtime,effective_digest,self.preview,self.warnings)

def compile_config(catalog,base_document,settings,roster_side=None,allow_missing=False):
    normalized=normalize_settings(settings);warnings=[]
    # A failed package is removed as a whole and compilation restarts from the
    # immutable base. Dependency pruning then removes its dependent chain. No
    # successful earlier patch/scope/asset from a suspended package can leak.
    while True:
        try:
            result=Compiler(catalog,base_document,normalized,roster_side,allow_missing).finish()
            if warnings:
                result.warnings[:0]=warnings;result.preview["warnings"]=result.warnings
                result.runtime["warnings"]=result.warnings;result.runtime["errors"]=copy.deepcopy(result.warnings)
                result.document.setdefault("cfg",{})["mod_runtime"]=result.runtime
                result.roster["mod_runtime"]=copy.deepcopy(result.runtime)
            return result
        except ModError as exc:
            if not allow_missing:raise
            active=[r for r in normalized["packages"] if r["enabled"]]
            if not active:raise
            pid=getattr(exc,"package_id",None)
            affected=[r for r in active if pid is None or r["packageId"]==pid]
            if not affected:raise
            for row in affected:
                row["enabled"]=False;warnings.append({"packageId":row["packageId"],"suspended":True,**exc.as_dict()})

def target_digest(document,aid,path):
    """Author helper: digest the exact semantic unit a patch will guard."""
    compiler=Compiler(None,document,{},None,False)
    if aid not in compiler.cfg["avatar"]:fail("Unknown target hero",aid)
    if path not in PATCH_PATHS:fail("Unknown semantic path",path)
    return digest(compiler.logical(compiler.cfg["avatar"][aid],path))
