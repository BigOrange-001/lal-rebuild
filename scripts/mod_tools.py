#!/usr/bin/env python3
"""Author, validate, install and inspect lal-mod-v1 declarative hero packages."""
from __future__ import annotations
import argparse
import copy
import json
import hashlib
import sys
import uuid
import zipfile
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/"server"))
from mod_schema import FORMAT, CAPABILITIES, LIMITS, ModError, canonical, safe_path, strict_json
from mod_packages import ModCatalog, inspect_package
from mod_compile import target_digest

def load_base(path):
    document=json.loads(Path(path).read_text(encoding="utf-8-sig"))
    # Patch guards must target the same post-overlay baseline as Backend.
    from recruit_exchange import apply_recruit_exchange_config
    from equipment_capacity import apply_equipment_capacity
    from equipment_upgrade_cost import apply_equipment_upgrade_config
    from captain_timing import apply_captain_timing
    from upstream_skill_priority import apply_upstream_skill_priority
    from battle_status_effects import apply_battle_status_effects
    from halo_progression import apply_halo_progression
    for apply in (apply_recruit_exchange_config,apply_equipment_capacity,apply_equipment_upgrade_config,apply_captain_timing,apply_upstream_skill_priority,apply_battle_status_effects):apply(document)
    document=apply_halo_progression(document)
    from mod_authoring_103 import apply_mod_authoring_103
    apply_mod_authoring_103(document)
    from hero_packs_104 import apply_hero_packs_104
    apply_hero_packs_104(document)
    from tower_rewards_103 import apply_tower_rewards_103
    from ancient_trial_103 import apply_ancient_trial_103
    from material_attempts_103 import apply_material_attempts_103
    for apply in (apply_tower_rewards_103,apply_ancient_trial_103,apply_material_attempts_103):apply(document)
    from power_balance_104 import apply_power_balance_104
    from resource_drops_104 import apply_resource_drops_104
    from bonds_104 import apply_bonds_104
    from equipment_bonds_104 import apply_equipment_bonds_104
    from skill_output_104 import apply_skill_output_104
    for apply in (apply_power_balance_104,apply_resource_drops_104,apply_bonds_104,apply_equipment_bonds_104,apply_skill_output_104):apply(document)
    document['cfg_version']=(ROOT/'VERSION').read_text(encoding='utf-8').strip()
    return document

def pack_directory(directory,output):
    directory=Path(directory).resolve();output=Path(output).resolve()
    if output.is_relative_to(directory):raise ModError("ModInvalidPath","Output archive must be outside its source directory")
    manifest=strict_json((directory/"manifest.json").read_bytes(),"manifest.json")
    payload={}
    for source in sorted(directory.rglob("*")):
        if source.is_symlink():raise ModError("ModInvalidPath","Source symlinks are forbidden",str(source))
        if not source.is_file():continue
        name=source.relative_to(directory).as_posix();safe_path(name)
        if name=="manifest.json":continue
        if name.lower().endswith(".json"):
            # Reformatting is allowed; duplicate keys/nonfinite data is never silently repaired.
            strict_json(source.read_bytes(),name)
        payload[name]=source.read_bytes()
    manifest["files"]=[{"path":name,"sha256":hashlib.sha256(raw).hexdigest()} for name,raw in payload.items()]
    payload["manifest.json"]=canonical(manifest)
    output.parent.mkdir(parents=True,exist_ok=True)
    staged=output.with_name(output.name+".tmp")
    try:
        with zipfile.ZipFile(staged,"w",compression=zipfile.ZIP_DEFLATED,compresslevel=6) as archive:
            for name,raw in sorted(payload.items()):
                info=zipfile.ZipInfo(name,date_time=(2020,1,1,0,0,0));info.compress_type=zipfile.ZIP_DEFLATED;info.external_attr=0o100644<<16
                archive.writestr(info,raw)
        package=inspect_package(staged)
        staged.replace(output)
        return package.metadata()
    finally:
        if staged.exists():staged.unlink()

def template(kind,directory,base,target="A_1001_5"):
    directory=Path(directory)
    if directory.exists():raise ModError("ModPathExists","Template destination already exists",str(directory))
    manifest={"format":FORMAT,"kind":"new" if kind=="new" else "patch","packageId":str(uuid.uuid4()),"name":"我的自制英雄" if kind=="new" else "我的英雄还原补丁","author":"请填写作者","version":"1.0.0","engineApi":"1","requiredCapabilities":["hero.register","skill.reference.builtin"] if kind=="new" else ["hero.patch.skill","skill.reference.builtin"],"entrypoints":{},"dependencies":[],"files":[]}
    directory.mkdir(parents=True)
    if kind=="new":
        hero={"id":"my_hero","variant":"quality5","name":"我的自制英雄","unitType":"hero","quality":5,"signType":"attack","actionType":"forward","damageType":"physical","baseStats":{"health":1200,"attack":100,"physicalDefense":60,"magicDefense":40},"growth":{"health":100,"attack":8,"physicalDefense":5,"magicDefense":3},"speed":245,"attackRange":337,"leadership":26,"levelCap":99,"progression":{"preset":"builtin:progression/default-player-hero","starUp":None},"skills":{"normal":"builtin:skill/S_201001_5","captain":None,"passive":None},"presentation":{"portrait":"builtin:portrait/A_1001_5","icon":"builtin:icon/A_1001_5","basicAttackEffect":"builtin:effect/E_008","voice":None}}
        manifest["entrypoints"]={"heroes":"heroes.json"};files={"heroes.json":{"heroes":[hero]}}
    elif kind=="patch":
        manifest["entrypoints"]={"patches":"patches.json","skills":"skills.json"}
        skill={"id":"restored_normal","name":"还原技能示例","description":"对一个敌人造成物理伤害并沉默1个目标行动回合，伤害倍率随技能等级提升。","timingUnit":"ownerTurns","warmup":1,"cooldown":3,"range":1500,"targetPolicy":"enemy_lane_frontmost","maxLevel":10,"actions":[{"type":"silence","coefficient":1.32,"damageType":"physical","duration":1,"effect":"builtin:effect/FX60_GAREN_SLASH","maxTargets":1}],"upgrades":[{"action":0,"field":"coefficient","perLevel":0.14}]}
        files={"skills.json":{"skills":[skill]},"patches.json":{"patches":[{"id":"restore_normal","target":"builtin:avatar/"+target,"expect":{"path":"skills.normal","sha256":target_digest(base,target,"skills.normal")},"operations":[{"op":"replace","path":"skills.normal","value":"self:skill/restored_normal"}]}]}}
        manifest["sourceNotes"]={"kind":"author-design","description":"演示格式，不宣称已确认原版技能"}
    else:
        manifest["entrypoints"]={"patches":"patches.json"};manifest["requiredCapabilities"]=["hero.patch.stats"]
        current=base["cfg"]["avatar"][target]["pl"][2]
        files={"patches.json":{"patches":[{"id":"adjust_attack","target":"builtin:avatar/"+target,"expect":{"path":"baseStats.attack","value":current},"operations":[{"op":"set","path":"baseStats.attack","value":current+1}]}]}}
    for name,value in files.items():(directory/name).write_bytes(canonical(value))
    (directory/"manifest.json").write_bytes(canonical(manifest))
    return {"path":str(directory),"packageId":manifest["packageId"]}

def fork_package(directory,new_directory):
    directory=Path(directory);new_directory=Path(new_directory)
    if new_directory.exists():raise ModError("ModPathExists","Fork destination exists")
    manifest=strict_json((directory/"manifest.json").read_bytes());old=manifest["packageId"];new=str(uuid.uuid4())
    new_directory.mkdir(parents=True)
    for source in directory.rglob("*"):
        if source.is_symlink():raise ModError("ModInvalidPath","Source symlink is forbidden")
        if not source.is_file():continue
        name=source.relative_to(directory);target=new_directory/name;target.parent.mkdir(parents=True,exist_ok=True)
        raw=source.read_bytes()
        if source.suffix.lower()==".json":
            def rewrite(value):
                if isinstance(value,str):return value.replace("mod:"+old+"/","mod:"+new+"/")
                if isinstance(value,list):return [rewrite(v) for v in value]
                if isinstance(value,dict):return {k:rewrite(v) for k,v in value.items()}
                return value
            value=rewrite(strict_json(raw))
            if name.as_posix()=="manifest.json":value["packageId"]=new;value.pop("signature",None);value["files"]=[]
            raw=canonical(value)
        target.write_bytes(raw)
    return {"packageId":new,"forkedFrom":old,"path":str(new_directory)}

def main(argv=None):
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config",default=str(ROOT/"config/reconstruction/full-config.json"))
    parser.add_argument("--mods-root",default=str(ROOT/"mods"))
    sub=parser.add_subparsers(dest="command",required=True)
    p=sub.add_parser("template");p.add_argument("kind",choices=("new","patch","data-patch"));p.add_argument("directory");p.add_argument("--target",default="A_1001_5")
    p=sub.add_parser("pack");p.add_argument("directory");p.add_argument("output")
    for command in ("validate","install"):
        p=sub.add_parser(command);p.add_argument("package")
    sub.add_parser("list");sub.add_parser("capabilities")
    p=sub.add_parser("uninstall");p.add_argument("packageId");p.add_argument("version");p.add_argument("--digest")
    p=sub.add_parser("target-digest");p.add_argument("aid");p.add_argument("path")
    p=sub.add_parser("fork");p.add_argument("directory");p.add_argument("new_directory")
    args=parser.parse_args(argv)
    try:
        if args.command=="template":result=template(args.kind,args.directory,load_base(args.config),args.target)
        elif args.command=="pack":result=pack_directory(args.directory,args.output)
        elif args.command=="validate":result=inspect_package(args.package,load_base(args.config)).metadata()
        elif args.command=="target-digest":result={"sha256":target_digest(load_base(args.config),args.aid,args.path)}
        elif args.command=="fork":result=fork_package(args.directory,args.new_directory)
        elif args.command=="capabilities":result={"engineApi":"1","capabilities":sorted(CAPABILITIES),"limits":LIMITS}
        else:
            catalog=ModCatalog(args.mods_root,load_base(args.config))
            if args.command=="install":result=catalog.install(args.package)
            elif args.command=="list":result=catalog.scan()
            else:result=catalog.uninstall(args.packageId,args.version,args.digest)
        print(json.dumps(result,ensure_ascii=False,indent=2));return 0
    except (ModError,OSError) as exc:
        print(json.dumps(exc.as_dict() if isinstance(exc,ModError) else {"code":"ModFileError","message":str(exc)},ensure_ascii=False),file=sys.stderr);return 2

if __name__=="__main__":raise SystemExit(main())
