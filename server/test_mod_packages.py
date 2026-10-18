"""Package protocol boundaries and per-save compiler invariants; no live DB."""
import copy
import hashlib
import json
import os
import shutil
import struct
import subprocess
import sys
import tempfile
import unittest
from unittest import mock
import uuid
import zipfile
import zlib
from pathlib import Path

sys.path.insert(0,str(Path(__file__).resolve().parent))
from mod_schema import LIMITS, ModError, canonical, digest, strict_json
from mod_packages import ModCatalog, inspect_package
from mod_compile import target_digest

PID1="11111111-1111-4111-8111-111111111111"
PID2="22222222-2222-4222-8222-222222222222"
PID3="33333333-3333-4333-8333-333333333333"

def base_config():
    skill={"id":"S_201001_5","name":"基础技能","info":"基础说明","res":"S_201001_5","pl":[1,3,1500,0,0,0],"skill":[["damage",1,1,"FX"]],"skillUp":[]}
    hero={"id":"A_1001_5","name":"基础英雄","res":"A_1001_5","tl":[3,1,1,26,99,1,125,100,[],4,1],"pl":[1200,100,100,8,60,5,40,3,245,337,"S_201001_5",None,"E_008"],"skillup":500,"love":500}
    other=copy.deepcopy(hero);other["id"]="A_1002_5"
    return {"cfg_version":"test","cfg":{"avatar":{"A_1001_5":hero,"A_1002_5":other},"skill":{"S_201001_5":skill},"effect":{"E_008":{"sp":850},"FX":{}},"system_simple":{}}}

def hero_definition():
    return {"id":"my_hero","variant":"quality5","name":"同名英雄","unitType":"hero","quality":5,"signType":"attack","actionType":"forward","damageType":"physical","baseStats":{"health":1200,"attack":100,"physicalDefense":60,"magicDefense":40},"growth":{"health":100,"attack":8,"physicalDefense":5,"magicDefense":3},"speed":245,"attackRange":337,"leadership":26,"levelCap":99,"progression":{"preset":"builtin:progression/default-player-hero","starUp":None},"skills":{"normal":"builtin:skill/S_201001_5","captain":None,"passive":None},"presentation":{"portrait":"builtin:portrait/A_1001_5","icon":"builtin:icon/A_1001_5","basicAttackEffect":"builtin:effect/E_008","voice":None}}

def png():
    def chunk(kind,data):return struct.pack(">I",len(data))+kind+data+struct.pack(">I",zlib.crc32(kind+data)&0xffffffff)
    return b"\x89PNG\r\n\x1a\n"+chunk(b"IHDR",struct.pack(">IIBBBBB",1,1,8,6,0,0,0))+chunk(b"IDAT",zlib.compress(b"\0\xff\x80\0\xff"))+chunk(b"IEND",b"")

class ModPackageTest(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup)
        self.root=Path(self.temp.name);self.base=base_config();self.catalog=ModCatalog(self.root/"mods",self.base)
    def package(self,pid=PID1,kind="new",entities=None,version="1.0.0",dependencies=None,assets=None):
        if entities is None:entities={"heroes":{"heroes":[hero_definition()]}}
        payload={name+".json":canonical(value) for name,value in entities.items()};payload.update(assets or {})
        manifest={"format":"lal-mod-v1","kind":kind,"packageId":pid,"name":"测试包","author":"测试作者","version":version,"engineApi":"1","requiredCapabilities":[],"entrypoints":{key:key+".json" for key in entities},"files":[{"path":name,"sha256":hashlib.sha256(raw).hexdigest()} for name,raw in payload.items()],"dependencies":dependencies or []}
        payload["manifest.json"]=canonical(manifest)
        output=self.root/(uuid.uuid4().hex+".heropack")
        with zipfile.ZipFile(output,"w",compression=zipfile.ZIP_STORED) as archive:
            for name,raw in payload.items():archive.writestr(name,raw)
        return output
    def install(self,*args,**kwargs):return self.catalog.install(self.package(*args,**kwargs))
    def selection(self,row,**changes):return {"packageId":row["packageId"],"version":row["version"],"digest":row["digest"],**changes}
    def compile(self,*rows,known=None,allow_missing=False):return self.catalog.compile(self.base,{"packages":list(rows),"knownHeroes":known or {}},allow_missing=allow_missing)
    def patch(self,path,value,pid=PID1,expect=None,dependencies=None,other_ops=None):
        if expect is None:expect={"path":path,"sha256":target_digest(self.base,"A_1001_5",path)}
        patches={"patches":[{"id":"change","target":"builtin:avatar/A_1001_5","expect":expect,"operations":[{"op":"replace","path":path,"value":value}]+(other_ops or [])}]}
        return self.install(pid,"patch",{"patches":patches},dependencies=dependencies)
    def test_no_mod_preserves_original_and_side_tables(self):
        before=copy.deepcopy(self.base);out=self.compile()
        self.assertEqual(out.document,self.base);self.assertEqual(self.base,before)
        self.assertNotIn("mod_runtime",out.document["cfg"])
    def test_two_file_new_and_namespace_isolation_stable_ids(self):
        a=self.install();b=self.install(PID2)
        first=self.compile(self.selection(a),self.selection(b));second=self.compile(self.selection(b),self.selection(a))
        self.assertEqual(first.digest,second.digest)
        self.assertEqual(len(first.runtime["heroes"]),2)
        aids=list(first.runtime["heroes"]);self.assertNotEqual(aids[0],aids[1])
        self.assertEqual(first.document["cfg"]["avatar"][aids[0]]["tl"][:2],[1,1])
        self.assertTrue(all(a.startswith("A_1") for a in aids))
        self.assertTrue(all(v["channels"]["acquisition.summon.normal"] for v in first.runtime["heroes"].values()))
        self.assertEqual(self.base["cfg"]["avatar"]["A_1001_5"]["res"],"A_1001_5")
    def test_duplicate_install_and_same_version_content_conflict(self):
        source=self.package();a=self.catalog.install(source);b=self.catalog.install(source)
        self.assertEqual(a["digest"],b["digest"]);self.assertTrue(b["duplicate"])
        hero=hero_definition();hero["name"]="changed"
        with self.assertRaises(ModError) as raised:self.install(entities={"heroes":{"heroes":[hero]}})
        self.assertEqual(raised.exception.code,"ModIdentityConflict")
        self.assertEqual(self.catalog.get(PID1,"1.0.0").digest,a["digest"])
    def test_strict_json_keys_nonfinite_and_zip_payload_boundary(self):
        for raw in (b'{"a":1,"a":2}',b'{"a":NaN}',b'{"a":1e999}'):
            with self.assertRaises(ModError):strict_json(raw)
        good=self.package()
        for bad in ("../escape.json","/root.json","C:/escape.json","a\\b.json","CON.txt","data/../escape.json"):
            source=self.root/(uuid.uuid4().hex+".zip")
            with zipfile.ZipFile(good) as archive:items=[(i.filename,archive.read(i)) for i in archive.infolist()]
            with zipfile.ZipFile(source,"w") as archive:
                for name,raw in items:archive.writestr(name,raw)
                archive.writestr(bad,b"{}")
            with self.assertRaises(ModError):inspect_package(source)
        with zipfile.ZipFile(good,"a") as archive:archive.writestr("unlisted.json",b"{}")
        with self.assertRaises(ModError):inspect_package(good)
    def test_bad_hash_and_duplicate_entity_unknown_action(self):
        hero=hero_definition()
        with self.assertRaises(ModError):self.install(entities={"heroes":{"heroes":[hero,hero]}})
        skill={"id":"skill","name":"skill","description":"","timingUnit":"ownerTurns","warmup":0,"cooldown":3,"range":1500,"targetPolicy":"enemy_lane_frontmost","actions":[{"type":"manual_ability","effect":None}],"upgrades":[]}
        with self.assertRaises(ModError):self.install(entities={"heroes":{"heroes":[hero]},"skills":{"skills":[skill]}})
        source=self.package()
        with zipfile.ZipFile(source,"a") as archive:archive.writestr("heroes.json",b"{}")
        with self.assertRaises(ModError):inspect_package(source)
    def test_own_png_load_asset_checks_and_corruption(self):
        hero=hero_definition();hero["presentation"]["portrait"]="self:asset/portrait.png"
        row=self.install(entities={"heroes":{"heroes":[hero]}},assets={"assets/portrait.png":png()})
        out=self.compile(self.selection(row));asset=out.runtime["assets"][0]
        self.assertEqual(asset["role"],"portrait")
        self.assertEqual(self.catalog.resolve_digest_asset(row["digest"],asset["path"]).read_bytes(),png())
        installed=self.catalog.get(PID1,"1.0.0").path/asset["path"];installed.write_bytes(b"bad")
        with self.assertRaises(ModError):self.compile(self.selection(row))
        with self.assertRaises(ModError):self.catalog.resolve_digest_asset(row["digest"],asset["path"])
        self.assertEqual(self.catalog.scan()[0]["status"],"corrupt")
    def test_invalid_png_cannot_import_successfully(self):
        hero=hero_definition();hero["presentation"]["portrait"]="self:asset/portrait.png"
        with self.assertRaises(ModError):self.install(entities={"heroes":{"heroes":[hero]}},assets={"assets/portrait.png":png()[:-2]})
        raw=bytearray(png());raw[16:20]=struct.pack(">I",2049)
        raw[29:33]=struct.pack(">I",zlib.crc32(raw[12:29])&0xffffffff)
        with self.assertRaisesRegex(ModError,"dimensions exceed quota"):
            self.install(entities={"heroes":{"heroes":[hero]}},assets={"assets/portrait.png":bytes(raw)})
    def test_missing_and_disabled_preserve_only_current_save_identity(self):
        row=self.install();active=self.compile(self.selection(row));known=active.runtime["heroes"];aid=next(iter(known))
        self.catalog.uninstall(PID1,"1.0.0")
        degraded=self.compile(self.selection(row),known=known,allow_missing=True)
        self.assertEqual(degraded.runtime["missingHeroIds"],[aid]);self.assertIn(aid,degraded.document["cfg"]["avatar"])
        self.assertEqual(self.compile(allow_missing=True).runtime["missingHeroIds"],[])
        self.assertEqual(self.compile(self.selection(row,enabled=False),known=known).runtime["missingHeroIds"],[aid])
        reinstalled=self.install();restored=self.compile(self.selection(reinstalled),known=known)
        self.assertEqual(restored.runtime["missingHeroIds"],[]);self.assertEqual(next(iter(restored.runtime["heroes"])),aid)
    def test_tombstones_not_recycled_and_restore_collision_blocks(self):
        first=self.install();out=self.compile(self.selection(first));aid=next(iter(out.runtime["heroes"]))
        snap=self.catalog.identity_snapshot();self.catalog.uninstall(PID1,"1.0.0")
        second=self.install(PID2);other=self.compile(self.selection(second));other_aid=next(iter(other.runtime["heroes"]))
        self.assertNotEqual(aid,other_aid)
        bad=copy.deepcopy(snap);next(iter(bad["identities"].values()))["aid"]=other_aid
        bad["families"][next(iter(bad["families"]))]=int(other_aid.split("_")[1])
        with self.assertRaises(ModError) as raised:self.catalog.restore_identities(bad)
        self.assertEqual(raised.exception.code,"ModMigrationRequired")
    def test_patch_skill_copy_on_write_and_scope_variant(self):
        row=self.patch("skills.normal.cooldown",7)
        out=self.compile(self.selection(row,patchScopes={"arenaEnemy":False}))
        target=out.document["cfg"]["avatar"]["A_1001_5"];unrelated=out.document["cfg"]["avatar"]["A_1002_5"]
        self.assertNotEqual(target["pl"][10],unrelated["pl"][10])
        self.assertEqual(out.document["cfg"]["skill"][target["pl"][10]]["pl"][1],7)
        self.assertEqual(out.document["cfg"]["skill"][unrelated["pl"][10]]["pl"][1],3)
        alias=out.runtime["scopedAvatarIds"]["arenaEnemy"]["A_1001_5"]
        self.assertEqual(out.document["cfg"]["avatar"][alias]["modBaseAid"],"A_1001_5")
        self.assertEqual(out.document["cfg"]["avatar"][alias]["pl"][10],"S_201001_5")
        self.catalog.uninstall(PID1,"1.0.0")
        reverted=self.compile(self.selection(row),allow_missing=True)
        self.assertEqual(reverted.document["cfg"]["avatar"]["A_1001_5"],self.base["cfg"]["avatar"]["A_1001_5"])
    def test_disjoint_patch_and_conflict_and_explicit_dependency(self):
        a=self.patch("speed",300);b=self.patch("baseStats.attack",200,PID2)
        composed=self.compile(self.selection(a),self.selection(b))
        self.assertEqual(composed.document["cfg"]["avatar"]["A_1001_5"]["pl"][8],300)
        self.assertEqual(composed.document["cfg"]["avatar"]["A_1001_5"]["pl"][2],200)
        c=self.patch("speed",350,PID3)
        with self.assertRaises(ModError) as raised:self.compile(self.selection(a),self.selection(c))
        self.assertEqual(raised.exception.code,"ModPatchConflict")
        self.catalog.uninstall(PID3,"1.0.0")
        chained=self.install(PID3,"patch",{"patches":{"patches":[{"id":"chained","target":"builtin:avatar/A_1001_5","expect":{"path":"speed","value":300},"operations":[{"op":"replace","path":"speed","value":350}]}]}},version="1.0.1",dependencies=[{"packageId":PID1,"version":"^1.0.0","digest":a["digest"]}])
        final=self.compile(self.selection(chained),self.selection(a))
        self.assertEqual(final.document["cfg"]["avatar"]["A_1001_5"]["pl"][8],350)
    def test_target_mismatch_and_unrelated_base_update(self):
        a=self.patch("speed",300)
        self.base["cfg"]["skill"]["S_201001_5"]["info"]="unrelated change"
        self.assertEqual(self.compile(self.selection(a)).document["cfg"]["avatar"]["A_1001_5"]["pl"][8],300)
        self.base["cfg"]["avatar"]["A_1001_5"]["pl"][8]=246
        with self.assertRaises(ModError) as raised:self.compile(self.selection(a))
        self.assertEqual(raised.exception.code,"ModTargetMismatch")
    def test_degradation_suspends_entire_patch_and_dependents(self):
        patches={"patches":[{"id":"one","target":"builtin:avatar/A_1001_5","expect":{"path":"speed","value":245},"operations":[{"op":"set","path":"speed","value":300}]},{"id":"two","target":"builtin:avatar/A_1001_5","expect":{"path":"baseStats.attack","value":99999},"operations":[{"op":"set","path":"baseStats.attack","value":500}]}]}
        a=self.install(kind="patch",entities={"patches":patches})
        b=self.patch("name","dependent",PID2,dependencies=[{"packageId":PID1,"version":"1.0.0"}])
        result=self.compile(self.selection(a),self.selection(b),allow_missing=True)
        self.assertEqual(result.document["cfg"]["avatar"],self.base["cfg"]["avatar"])
        self.assertEqual(result.runtime["packages"],[])
        self.assertTrue(any(w.get("suspended") for w in result.warnings))
    def test_registry_corruption_base_game_boots_and_cannot_reuse_ids(self):
        self.catalog.registry_path.write_bytes(b'{"bad":')
        broken=ModCatalog(self.root/"mods",self.base)
        self.assertIsNotNone(broken.error);self.assertEqual(broken.scan()[0]["status"],"corrupt")
        self.assertEqual(broken.compile(self.base,{}).document,self.base)
        with self.assertRaises(ModError):broken.allocate_hero(PID1,"hero","quality5",5)
        self.assertEqual(broken.registry_path.read_bytes(),b'{"bad":')
    def test_live_registry_corruption_freezes_known_heroes_without_rewriting(self):
        row=self.install();active=self.compile(self.selection(row));known=active.runtime["heroes"]
        self.catalog.registry_path.write_bytes(b'{"bad":')
        self.assertEqual(self.catalog.scan()[0]["error"]["code"],"ModRegistryCorrupt")
        missing=self.compile(self.selection(row),known=known,allow_missing=True)
        self.assertEqual(missing.runtime["missingHeroIds"],list(known))
        self.assertEqual(self.compile().document,self.base)
        with self.assertRaises(ModError):self.install(PID2)
        self.assertEqual(self.catalog.registry_path.read_bytes(),b'{"bad":')
    def test_known_capability_and_quality_applicability(self):
        hero=hero_definition();hero["quality"]=6;hero["variant"]="quality6"
        row=self.install(entities={"heroes":{"heroes":[hero]}});out=self.compile(self.selection(row))
        meta=next(iter(out.runtime["heroes"].values()))
        self.assertFalse(meta["channels"]["acquisition.summon.normal"])
        self.assertFalse(meta["channelSupport"]["acquisition.summon.normal"]["applicable"])
        self.assertFalse(meta["channelSupport"]["appearance.expedition_enemy"]["supported"])
    def test_persistent_upgrade_refused_and_version_retained(self):
        old=self.install();self.compile(self.selection(old))
        hero=hero_definition();hero["levelCap"]=90
        updated=self.install(version="2.0.0",entities={"heroes":{"heroes":[hero]}})
        with self.assertRaises(ModError) as raised:self.compile(self.selection(updated))
        self.assertEqual(raised.exception.code,"ModMigrationRequired")
        self.assertTrue(self.compile(self.selection(old)).runtime["heroes"])
    def test_star_chain_native_ui_and_permanent_ids_agree(self):
        low=hero_definition();high=hero_definition();high["quality"]=6;high["variant"]="quality6"
        low["progression"]["starUp"]="self:hero/my_hero/quality6"
        row=self.install(entities={"heroes":{"heroes":[low,high]}})
        result=self.compile(self.selection(row));metadata=result.runtime["heroes"]
        low_aid=next(aid for aid in metadata if aid.endswith("_5"));high_aid=metadata[low_aid]["progression"]["starUp"]
        self.assertEqual(high_aid,low_aid[:-1]+"6")
        self.assertEqual(result.document["cfg"]["avatar"][low_aid]["tl"][8],["A_"])
        self.assertEqual(result.document["cfg"]["avatar"][high_aid]["tl"][8],[])
    def test_unknown_hero_override_and_unsafe_builtin_binding_rejected(self):
        row=self.install()
        with self.assertRaises(ModError) as raised:self.compile(self.selection(row,heroes={"typo_hero":{"channels":{"appearance.arena_enemy":False}}}))
        self.assertEqual(raised.exception.code,"ModInvalidSettings")
        for action in ("hitup","fleeup","manual_ability","summon_turret","summon"):
            self.base["cfg"]["skill"]["S_201001_5"]["skill"]=[[action,1,1,"FX"]]
            with self.assertRaises(ModError) as raised:self.compile(self.selection(row))
            self.assertEqual(raised.exception.code,"ModIncompatible")
    def test_restore_preview_allocates_only_in_memory(self):
        source=self.package();row=self.catalog.install(source);active=self.compile(self.selection(row));snapshot=self.catalog.identity_snapshot()
        destination=ModCatalog(self.root/"other-device",self.base);destination.install(source)
        before=destination.registry_path.read_bytes()
        preview=destination.preview_restore(snapshot,self.base,{"packages":[self.selection(row)]})
        self.assertEqual(preview.runtime["knownHeroIds"],active.runtime["knownHeroIds"])
        self.assertEqual(destination.registry_path.read_bytes(),before)
        self.assertEqual(destination.identity_snapshot()["identities"],{})
        destination.restore_identities(snapshot)
        committed=destination.compile(self.base,{"packages":[self.selection(row)]})
        self.assertEqual(preview.digest,committed.digest)
    def test_activity_exchange_uses_existing_quality_price_and_filters(self):
        self.base["cfg"]["ploy_system_simple"]={"timed_exchange":[{"A_1001_5":50},{"A_1001_6":100}],"extract_avatar":{"exchange":[[{"avatar_soul":{"A_1001_5":15}},100]]}}
        row=self.install();result=self.compile(self.selection(row));aid=next(iter(result.runtime["heroes"]))
        self.assertIn({aid:50},result.document["cfg"]["ploy_system_simple"]["timed_exchange"])
        off=self.compile(self.selection(row,channels={"acquisition.exchange.activity":False}))
        self.assertNotIn({aid:50},off.document["cfg"]["ploy_system_simple"]["timed_exchange"])
        patch=self.patch("speed",300,PID2)
        filtered=self.compile(self.selection(patch,channels={"acquisition.exchange.activity":False}))
        self.assertNotIn({"A_1001_5":50},filtered.document["cfg"]["ploy_system_simple"]["timed_exchange"])
        self.assertEqual(filtered.document["cfg"]["ploy_system_simple"]["extract_avatar"]["exchange"],[])
    def test_inactive_targets_defaults_and_explicit_inbox_import(self):
        source=self.package(kind="patch",entities={"patches":{"patches":[{"id":"speed_patch","target":"builtin:avatar/A_1001_5","expect":{"path":"speed","value":245},"operations":[{"op":"set","path":"speed","value":300}],"patchScopes":{"arenaEnemy":False}}]}})
        shutil.copyfile(source,self.catalog.root/"inbox"/"patch.heropack")
        self.assertEqual(self.catalog.scan(),[])
        self.assertTrue(self.catalog.import_inbox()[0]["ok"])
        self.assertTrue(self.catalog.import_inbox()[0]["duplicate"])
        row=self.catalog.scan()[0];hero=row["heroes"][0]
        self.assertEqual(hero["identity"],"builtin:avatar/A_1001_5")
        self.assertEqual(hero["aid"],"A_1001_5")
        self.assertFalse(hero["defaultPatchScopes"]["arenaEnemy"])
        self.assertTrue(row["defaultPatchScopes"]["arenaEnemy"])
        self.assertTrue(hero["defaultChannels"]["acquisition.exchange.hero"])
        self.assertFalse(hero["channelSupport"]["acquisition.exchange.hero"]["applicable"])
        self.assertTrue((self.catalog.root/"inbox"/"patch.heropack").is_file())
    def test_registry_lock_is_reentrant_and_serializes_author_processes(self):
        with self.catalog._transaction():
            first=self.catalog.allocate_hero(PID1,"parent","quality5",5)
        code="""import sys
sys.path.insert(0,sys.argv[1])
from mod_packages import ModCatalog
c=ModCatalog(sys.argv[2])
for index in range(8):c.allocate_hero(sys.argv[3],'child'+str(index),'quality5',5)
"""
        processes=[subprocess.Popen([sys.executable,"-B","-c",code,str(Path(__file__).resolve().parent),str(self.catalog.root),pid],stdout=subprocess.PIPE,stderr=subprocess.PIPE) for pid in (PID2,PID3)]
        for process in processes:
            _,error=process.communicate(timeout=20)
            self.assertEqual(process.returncode,0,error.decode("utf8",errors="replace"))
        identities=self.catalog.identity_snapshot()["identities"]
        self.assertEqual(len(identities),17);self.assertEqual(len({row["aid"] for row in identities.values()}),17)
    def test_preexisting_link_cannot_redirect_install_or_uninstall(self):
        outside=self.root/"outside";outside.mkdir();source=self.package()
        for relative in ("packages/"+PID1,"staging","packages"):
            with self.subTest(relative=relative):
                linked=self.catalog.root/relative
                if linked.exists():linked.rmdir()
                if os.name=="nt":
                    result=subprocess.run(["cmd","/c","mklink","/J",str(linked),str(outside)],capture_output=True)
                    self.assertEqual(result.returncode,0,result.stderr)
                else:linked.symlink_to(outside,target_is_directory=True)
                try:
                    with self.assertRaises(ModError) as raised:self.catalog.install(source)
                    self.assertEqual(raised.exception.code,"ModUnsafeStorage")
                    self.assertEqual(list(outside.iterdir()),[])
                finally:
                    if os.name=="nt":linked.rmdir()
                    else:linked.unlink()
                    if relative in ("staging","packages"):linked.mkdir()
        installed=self.catalog.install(source)
        parent=self.catalog.root/"packages"/PID1
        shutil.rmtree(parent)
        if os.name=="nt":
            result=subprocess.run(["cmd","/c","mklink","/J",str(parent),str(outside)],capture_output=True)
            self.assertEqual(result.returncode,0,result.stderr)
        else:parent.symlink_to(outside,target_is_directory=True)
        sentinel=outside/"retained.txt";sentinel.write_text("retained","utf8")
        try:
            with self.assertRaises(ModError):self.catalog.uninstall(PID1,"1.0.0",installed["digest"])
            self.assertEqual(sentinel.read_text("utf8"),"retained")
        finally:
            if os.name=="nt":parent.rmdir()
            else:parent.unlink()
    def test_combined_entity_quota_checked_before_allocating_ids(self):
        first=self.install();second=self.install(PID2)
        before=self.catalog.registry_path.read_bytes()
        with mock.patch.dict(LIMITS,{"activeHeroes":1}):
            with self.assertRaises(ModError) as raised:self.compile(self.selection(first),self.selection(second))
        self.assertEqual(raised.exception.code,"ModQuotaExceeded")
        self.assertEqual(self.catalog.registry_path.read_bytes(),before)
        patch=self.patch("speed",300,PID3)
        with mock.patch.dict(LIMITS,{"activePatchOperations":0}):
            with self.assertRaises(ModError) as raised:self.compile(self.selection(patch))
        self.assertEqual(raised.exception.code,"ModQuotaExceeded")
        skill={"id":"skill","name":"skill","description":"","timingUnit":"ownerTurns","warmup":0,"cooldown":3,"range":1500,"targetPolicy":"enemy_lane_frontmost","actions":[{"type":"damage","coefficient":1,"damageType":"physical","effect":None}],"upgrades":[]}
        source=self.install(str(uuid.uuid4()),entities={"heroes":{"heroes":[hero_definition()]},"skills":{"skills":[skill]}})
        with mock.patch.dict(LIMITS,{"activeSkills":0}):
            with self.assertRaises(ModError) as raised:self.compile(self.selection(source))
        self.assertEqual(raised.exception.code,"ModQuotaExceeded")
    def test_compressed_audio_is_bounded_by_decoded_memory(self):
        hero=hero_definition();hero["presentation"]["voice"]="self:asset/voice.mp3"
        mp3=b'\xff\xfb\x90\x00'+b'\0'*413
        row=self.install(entities={"heroes":{"heroes":[hero]}},assets={"assets/voice.mp3":mp3})
        result=self.compile(self.selection(row));asset=result.runtime["assets"][0]
        self.assertGreater(asset["decodedBytes"],len(mp3))
        with mock.patch.dict(LIMITS,{"decodedAudioBytes":1}):
            with self.assertRaises(ModError) as raised:self.compile(self.selection(row))
        self.assertEqual(raised.exception.code,"ModQuotaExceeded")

if __name__=="__main__":unittest.main()
