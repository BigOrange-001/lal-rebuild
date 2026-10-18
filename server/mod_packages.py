"""Verified local package storage. No game RPC accepts arbitrary install paths."""
from __future__ import annotations

import copy
import contextlib
import hashlib
import io
import os
import shutil
import stat
import struct
import threading
import time
import uuid
import zipfile
import zlib
from dataclasses import dataclass
from pathlib import Path

from mod_schema import (CHANNELS,SCOPES,LIMITS, ModError, canonical, digest, fail, package_id,
                        safe_path, strict_json, validate_data, validate_manifest, version)

ALLOWED_EXTENSIONS={".json",".png",".jpg",".jpeg",".wav",".mp3",".txt",".md"}
MAX_ARCHIVE_BYTES=LIMITS["archiveBytes"]
MAX_REGISTRY_BYTES=LIMITS["registryBytes"]


def _empty_registry():
    return {"schema":"lal-mod-registry-v1","packages":{},"identities":{},"families":{},"aliases":{},"nextFamily":180000,"nextAlias":170000,"nextSkill":800000}


def _registry_payload(value):
    raw=canonical(value)
    if len(raw)>MAX_REGISTRY_BYTES:fail("Installation registry exceeds its total byte quota", "registry.json", "ModRegistryLimit")
    return raw

def _validate_png(raw,path):
    if not raw.startswith(b"\x89PNG\r\n\x1a\n"):fail("Invalid PNG signature",path)
    offset=8; idat=[]; header=None; ended=False; seen_idat=False; idat_finished=False
    while offset<len(raw):
        if offset+12>len(raw):fail("Truncated PNG chunk",path)
        length=struct.unpack(">I",raw[offset:offset+4])[0];kind=raw[offset+4:offset+8]
        if offset+12+length>len(raw):fail("Truncated PNG chunk",path)
        data=raw[offset+8:offset+8+length];crc=struct.unpack(">I",raw[offset+8+length:offset+12+length])[0]
        if zlib.crc32(kind+data)&0xffffffff!=crc:fail("PNG CRC mismatch",path)
        if header is None and kind!=b"IHDR":fail("PNG IHDR must be first",path)
        if kind==b"IHDR":
            if header is not None or length!=13:fail("Invalid PNG IHDR",path)
            width,height,depth,color,compression,filter_,interlace=struct.unpack(">IIBBBBB",data)
            if not 1<=width<=LIMITS["imageDimension"] or not 1<=height<=LIMITS["imageDimension"] or width*height>LIMITS["imagePixels"]:fail("PNG dimensions exceed quota",path)
            # API 1 uses ordinary 8-bit RGB/RGBA so every supported runtime can decode.
            if depth!=8 or color not in (2,6) or compression or filter_ or interlace:fail("API 1 requires noninterlaced 8-bit RGB/RGBA PNG",path)
            header=(width,height,3 if color==2 else 4)
        elif kind==b"IDAT":
            if idat_finished:fail("Nonconsecutive PNG IDAT",path)
            seen_idat=True;idat.append(data)
        elif kind==b"IEND":
            if length or offset+12!=len(raw):fail("PNG trailing payload or invalid IEND",path)
            ended=True;break
        elif kind[0]&32==0 and kind!=b"PLTE":fail("Unsupported critical PNG chunk",path)
        if seen_idat and kind!=b"IDAT":idat_finished=True
        offset+=12+length
    if not header or not ended or not idat:fail("Incomplete PNG",path)
    width,height,channels=header;expected=(width*channels+1)*height
    try:
        inflater=zlib.decompressobj();pixels=inflater.decompress(b"".join(idat),expected+1)
        if len(pixels)!=expected or not inflater.eof or inflater.unused_data or inflater.unconsumed_tail:fail("PNG pixel stream length mismatch",path)
    except zlib.error:fail("PNG pixel decoding failed",path)
    stride=width*channels+1
    if any(pixels[i*stride]>4 for i in range(height)):fail("Invalid PNG row filter",path)
    return {"kind":"image","width":width,"height":height,"mime":"image/png"}

def validate_media(raw,path):
    ext=Path(path).suffix.lower()
    if ext==".png":return _validate_png(raw,path)
    if ext in (".jpg",".jpeg"):
        try:
            from PIL import Image
        except ImportError:fail("JPEG verification requires Pillow; use a standard RGB/RGBA PNG",path,"ModUnsupportedMedia")
        try:
            with Image.open(io.BytesIO(raw)) as picture:
                if picture.format!="JPEG":fail("JPEG format mismatch",path)
                w,h=picture.size
                if w<1 or h<1 or max(w,h)>LIMITS["imageDimension"] or w*h>LIMITS["imagePixels"]:fail("JPEG dimensions exceed quota",path)
                picture.load()
        except (OSError,ValueError):fail("JPEG decoding failed",path)
        return {"kind":"image","width":w,"height":h,"mime":"image/jpeg"}
    if ext==".wav":
        fail("AIR API 1 audio playback supports MP3; convert WAV to MP3 before packaging",path,"ModUnsupportedMedia")
    if ext==".mp3":
        # Validate every MPEG frame, rather than accepting files with an ID3 prefix.
        offset=0
        if raw.startswith(b"ID3"):
            if len(raw)<10 or any(v&128 for v in raw[6:10]):fail("Invalid ID3 size",path)
            offset=10+sum(v<<(7*(3-i)) for i,v in enumerate(raw[6:10]))
        count=0;duration=0
        bitrates={3:[0,32,40,48,56,64,80,96,112,128,160,192,224,256,320],2:[0,8,16,24,32,40,48,56,64,80,96,112,128,144,160],0:[0,8,16,24,32,40,48,56,64,80,96,112,128,144,160]}
        while offset<len(raw):
            if len(raw)-offset==128 and raw[offset:offset+3]==b"TAG":offset=len(raw);break
            if offset+4>len(raw):fail("Truncated MP3 frame",path)
            b0,b1,b2,b3=raw[offset:offset+4];mpeg=(b1>>3)&3;layer=(b1>>1)&3;index=b2>>4;freq=(b2>>2)&3
            if b0!=255 or b1&224!=224 or mpeg==1 or layer!=1 or index in (0,15) or freq==3:fail("Invalid MPEG Layer III frame",path)
            rate=[44100,48000,32000][freq]//(1 if mpeg==3 else 2 if mpeg==2 else 4)
            size=(144000 if mpeg==3 else 72000)*bitrates[mpeg][index]//rate+((b2>>1)&1)
            if size<4 or offset+size>len(raw):fail("Truncated MP3 data",path)
            duration+=(1152 if mpeg==3 else 576)/rate;offset+=size;count+=1
        if not count or duration>120:fail("Empty MP3 or duration exceeds 120s",path)
        # Flash Sound keeps decoded floating-point stereo samples. Bound the
        # expensive representation as well as compressed archive/media bytes;
        # 48 kHz stereo float32 conservatively covers every accepted MP3 rate.
        return {"kind":"sound","mime":"audio/mpeg","duration":duration,
                "decodedBytes":int(duration*48000*2*4)+1}
    return None

@dataclass(frozen=True)
class Package:
    manifest: dict
    data: dict
    digest: str
    path: Path | None
    media: dict
    payloads: dict | None = None
    @property
    def package_id(self):return self.manifest["packageId"]
    @property
    def version(self):return self.manifest["version"]
    def metadata(self):
        return {"packageId":self.package_id,"version":self.version,"digest":self.digest,"contentDigest":self.digest,
                "kind":self.manifest["kind"],"name":self.manifest["name"],"author":self.manifest["author"],
                "description":self.manifest.get("description",""),"sourceNotes":self.manifest.get("sourceNotes"),
                "dependencies":copy.deepcopy(self.manifest.get("dependencies",[])),"status":"installed",
                "heroes":copy.deepcopy(self.data.get("heroes",{}).get("heroes",[])),
                "patches":copy.deepcopy(self.data.get("patches",{}).get("patches",[]))}

def package_digest(manifest):
    normalized=copy.deepcopy(manifest);normalized.pop("signature",None)
    normalized["files"]=sorted(normalized["files"],key=lambda r:r["path"])
    return digest(normalized)

def inspect_package(source,base_document=None):
    source=Path(source)
    if source.is_symlink():fail("Package source may not be a symlink",str(source))
    if not source.is_file() or source.stat().st_size>LIMITS["archiveBytes"]:fail("Missing package or archive quota exceeded",str(source))
    payload={};total=0;seen=set()
    try:
        with zipfile.ZipFile(source) as archive:
            members=archive.infolist()
            if len(members)>LIMITS["files"]+1:fail("Too many ZIP members")
            for info in members:
                safe_path(info.filename)
                if info.filename.casefold() in seen:fail("Duplicate or case-colliding ZIP path",info.filename)
                seen.add(info.filename.casefold())
                if info.is_dir() or stat.S_ISLNK(info.external_attr>>16) or (info.external_attr>>16)&0o170000 not in (0,stat.S_IFREG):fail("Directories and special ZIP entries are forbidden",info.filename)
                if info.flag_bits&1:fail("Encrypted ZIP entries are unsupported",info.filename)
                if info.compress_type not in (zipfile.ZIP_STORED,zipfile.ZIP_DEFLATED):fail("Unsupported ZIP compression",info.filename)
                if info.file_size>LIMITS["fileBytes"] or info.file_size>max(1,info.compress_size)*LIMITS["compressionRatio"]:fail("ZIP entry exceeds size/compression quota",info.filename)
                total+=info.file_size
                if total>LIMITS["expandedBytes"]:fail("Expanded archive exceeds quota")
                if Path(info.filename).suffix.lower() not in ALLOWED_EXTENSIONS:fail("Executable or unsupported payload type",info.filename)
                with archive.open(info) as stream:raw=stream.read(LIMITS["fileBytes"]+1)
                if len(raw)!=info.file_size:fail("ZIP size mismatch",info.filename)
                payload[info.filename]=raw
    except (zipfile.BadZipFile,OSError,RuntimeError) as exc:fail("Cannot read ZIP: "+str(exc),str(source))
    package=_inspect_payload(payload)
    if base_document is not None:validate_package_references(package,base_document)
    return package

def validate_package_references(package,base_document=None):
    """Check package-local references at import; cross-package values at activation."""
    values=[];pid=package.package_id
    skills={row["id"] for row in package.data.get("skills",{}).get("skills",[])}
    heroes={row["id"]+"/"+row["variant"] for row in package.data.get("heroes",{}).get("heroes",[])}
    for hero in package.data.get("heroes",{}).get("heroes",[]):
        values.extend((value,"heroes."+hero["id"]+".skills."+key) for key,value in hero["skills"].items() if value is not None)
        values.extend((value,"heroes."+hero["id"]+".presentation."+key) for key,value in hero["presentation"].items() if value is not None)
        if hero["progression"]["starUp"] is not None:values.append((hero["progression"]["starUp"],"heroes."+hero["id"]+".progression.starUp"))
    for skill in package.data.get("skills",{}).get("skills",[]):
        values.extend((a["effect"],"skills."+skill["id"]+".actions.effect") for a in skill["actions"] if a["effect"] is not None)
    for patch in package.data.get("patches",{}).get("patches",[]):
        values.append((patch["target"],"patches."+patch["id"]+".target"))
        for operation in patch["operations"]:
            path=operation["path"]
            if operation["op"]!="clear" and (path.startswith("presentation.") or (path.startswith("skills.") and path.count(".")==1)):
                from mod_schema import reference
                types=("skill",) if path.startswith("skills.") else {"presentation.portrait":("portrait","asset"),"presentation.icon":("icon","asset"),"presentation.voice":("audio","asset"),"presentation.basicAttackEffect":("effect",)}[path]
                reference(operation["value"],"patches."+patch["id"]+"."+path,types)
                values.append((operation["value"],"patches."+patch["id"]+"."+path))
    baseline=(base_document or {}).get("cfg",base_document or {})
    deps={dep["packageId"] for dep in package.manifest.get("dependencies",[])}
    for value,path in values:
        domain,tail=value.split(":",1)
        if domain=="mod":
            dependency,kind,local=tail.split("/",2)
            if dependency not in deps:fail("Cross-package reference has no declared direct dependency",path,"ModMissingDependency")
            continue
        kind,local=tail.split("/",1)
        if domain=="self":
            if kind=="skill":exists=local in skills
            elif kind in ("hero","avatar"):exists=local in heroes
            elif kind=="asset":exists=local in package.media or "assets/"+local in package.media
            else:exists=False
            if not exists:fail("Local reference does not exist or has unsupported type",path,"ModMissingReference")
        elif baseline:
            table="avatar" if kind in ("hero","avatar","portrait","icon") else kind if kind in ("skill","effect") else None
            if table and local not in baseline.get(table,{}):fail("Builtin reference does not exist",path,"ModMissingReference")

def _inspect_payload(payload,path=None):
    if "manifest.json" not in payload:fail("Root manifest.json is required")
    manifest=validate_manifest(strict_json(payload["manifest.json"],"manifest.json"))
    declared={row["path"]:row["sha256"] for row in manifest["files"]}
    if set(payload)!=(set(declared)|{"manifest.json"}):fail("Payload table differs from archive (undeclared or missing file)")
    media={}
    for name,sha in declared.items():
        raw=payload[name]
        if hashlib.sha256(raw).hexdigest()!=sha:fail("SHA-256 mismatch",name)
        if Path(name).suffix.lower()==".json":strict_json(raw,name)
        checked=validate_media(raw,name)
        if checked:media[name]={**checked,"bytes":len(raw)}
    data={key:strict_json(payload[file],file) for key,file in manifest["entrypoints"].items()}
    validate_data(manifest,data)
    package=Package(manifest,data,package_digest(manifest),path,media,payload if path is None else None)
    validate_package_references(package)
    return package

def _atomic_json(path,value,raw=None):
    path=Path(path);path.parent.mkdir(parents=True,exist_ok=True)
    temporary=path.with_name(path.name+"."+uuid.uuid4().hex+".tmp")
    with temporary.open("xb") as stream:stream.write(canonical(value) if raw is None else raw);stream.flush();os.fsync(stream.fileno())
    os.replace(temporary,path)

class ModCatalog:
    """Installation registry and stable number allocator; instances share a lock."""
    _lock=threading.RLock()
    _transaction_owner=threading.local()
    def __init__(self,root,base_document=None):
        self.root=Path(root).resolve();self.base_document=base_document
        self.root.mkdir(parents=True,exist_ok=True)
        self.registry_path=self.root/"registry.json"
        self.catalog_error=None
        self.recovery_error=None
        try:
            for name in ("inbox","packages","staging"):
                directory=self.root/name;self._guard_storage(directory);directory.mkdir(exist_ok=True)
            self.registry=self._load();self._recover()
        except ModError as exc:
            # Never reset a corrupt identity registry: that would reuse IDs.
            # Base-game saves must still be able to log in and use management.
            self.catalog_error=exc if exc.code in ("ModUnsafeStorage","ModRegistryLimit") else ModError("ModRegistryCorrupt","Installation registry is unreadable; restore a known registry backup before changing packages. "+str(exc),"registry.json")
            self.registry=None
    @property
    def error(self):return self.catalog_error.as_dict() if self.catalog_error else None
    def _guard_storage(self,path):
        """Refuse pre-existing symlinks/junctions before local storage writes.

        A configured root is resolved once; descendants must remain ordinary
        directories inside it. Checking only the final resolved destination
        after publication would already have written through a parent link.
        """
        path=Path(path).absolute()
        if not path.is_relative_to(self.root):fail("Mod storage path escaped configured root",str(path),"ModUnsafeStorage")
        current=self.root
        for part in path.relative_to(self.root).parts:
            current=current/part
            try:attributes=current.lstat()
            except FileNotFoundError:continue
            if stat.S_ISLNK(attributes.st_mode) or getattr(attributes,"st_file_attributes",0)&getattr(stat,"FILE_ATTRIBUTE_REPARSE_POINT",0x400):
                fail("Mod storage contains a symlink or junction",str(current),"ModUnsafeStorage")
        if not path.resolve().is_relative_to(self.root):fail("Mod storage path escaped configured root",str(path),"ModUnsafeStorage")
        return path
    @contextlib.contextmanager
    def _transaction(self):
        """Coordinate host and author CLI without a third-party lock library."""
        with self._lock:
            if self.catalog_error:raise self.catalog_error
            owned=getattr(self._transaction_owner,"paths",None)
            if owned is None:owned={};self._transaction_owner.paths=owned
            key=os.path.normcase(str(self.root))
            if key in owned:
                owned[key]+=1
                try:yield
                finally:owned[key]-=1
                return
            lockfile=self.root/"registry.lock"
            self._guard_storage(lockfile)
            with lockfile.open("a+b") as stream:
                stream.seek(0,os.SEEK_END)
                if stream.tell()==0:stream.write(b"\0");stream.flush()
                deadline=time.monotonic()+10;locked=False
                while not locked:
                    stream.seek(0)
                    try:
                        if os.name=="nt":
                            import msvcrt
                            msvcrt.locking(stream.fileno(),msvcrt.LK_NBLCK,1)
                        else:
                            import fcntl
                            fcntl.flock(stream.fileno(),fcntl.LOCK_EX|fcntl.LOCK_NB)
                        locked=True
                    except OSError:
                        if time.monotonic()>=deadline:fail("Another Mod tool is updating the registry; retry shortly","registry.lock","ModRegistryBusy")
                        time.sleep(0.025)
                owned[key]=1
                try:yield
                finally:
                    del owned[key]
                    stream.seek(0)
                    if os.name=="nt":msvcrt.locking(stream.fileno(),msvcrt.LK_UNLCK,1)
                    else:fcntl.flock(stream.fileno(),fcntl.LOCK_UN)
    def _load(self):
        if getattr(self,"catalog_error",None):raise self.catalog_error
        try:return self._read_registry()
        except ModError as exc:
            if exc.code=="ModRegistryLimit":raise
            self.catalog_error=exc if exc.code=="ModUnsafeStorage" else ModError("ModRegistryCorrupt","Installation registry is unreadable; restore a known registry backup before changing packages. "+str(exc),"registry.json")
            raise self.catalog_error from exc
    def _read_registry(self):
        self._guard_storage(self.registry_path)
        if not self.registry_path.exists():
            previous=getattr(self,"registry",None) or {}
            if any(previous.get(key) for key in ("packages","identities","families","aliases","skills")):fail("Previously loaded registry disappeared; refusing to reuse reserved IDs","registry.json","ModRegistryCorrupt")
            return _empty_registry()
        try:
            with self.registry_path.open("rb") as stream:raw=stream.read(MAX_REGISTRY_BYTES+1)
            if len(raw)>MAX_REGISTRY_BYTES:fail("Installation registry exceeds its total byte quota", "registry.json", "ModRegistryLimit")
            value=strict_json(raw,"registry.json",max_bytes=MAX_REGISTRY_BYTES)
        except OSError as exc:fail("Registry cannot be read: "+str(exc),"registry.json","ModRegistryCorrupt")
        if not isinstance(value,dict) or value.get("schema")!="lal-mod-registry-v1":fail("Invalid registry schema","registry.json")
        for key in ("packages","identities","families","aliases"):
            if not isinstance(value.get(key),dict):fail("Registry table is missing or invalid","registry.json."+key)
        for key,minimum,maximum in (("nextFamily",180000,200000),("nextAlias",170000,180000),("nextSkill",800000,900000)):
            if type(value.get(key)) is not int or not minimum<=value[key]<=maximum:fail("Invalid allocation cursor","registry.json."+key)
        self.validate_identity_snapshot({key:value[key] for key in ("identities","families")})
        import re
        for key,row in value["packages"].items():
            if not isinstance(row,dict) or any(not isinstance(row.get(field),str) for field in ("packageId","version","digest","name","author","kind")):
                fail("Invalid package registry row","registry.json.packages")
            package_id(row["packageId"]);version(row["version"])
            if key!=row["packageId"]+"@"+row["version"] or not re.fullmatch(r"[0-9a-f]{64}",row["digest"]) or row["kind"] not in ("new","patch"):
                fail("Invalid package registry binding","registry.json.packages")
            if any(not isinstance(row.get(field,[]),list) for field in ("heroes","patches")):
                fail("Invalid package registry entities","registry.json.packages")
        for table,pattern,cursor in (("aliases",r"A_17[0-9]{4}_[2-6]","nextAlias"),("skills",r"S_8[0-9]{5}_[1-6]","nextSkill")):
            rows=value.get(table,{})
            if not isinstance(rows,dict) or any(not isinstance(item,str) or not re.fullmatch(pattern,item) for item in rows.values()):
                fail("Invalid definition allocation table","registry.json."+table)
            if len(set(rows.values()))!=len(rows) or any(int(item.split("_")[1])>=value[cursor] for item in rows.values()):
                fail("Duplicate definition allocation or unsafe cursor","registry.json."+table)
        return value
    def _save(self):
        try:raw=_registry_payload(self.registry)
        except ModError:
            # Allocation/restore callers may have built a larger candidate in
            # memory. Reject it without retaining half of the proposed state.
            self.registry=self._read_registry() if self.registry_path.exists() else _empty_registry()
            raise
        self._guard_storage(self.registry_path);_atomic_json(self.registry_path,self.registry,raw)
    def _recover(self):
        # Published directories contain their own verified manifest; an interrupted
        # registry write is recovered by inspection, never by loading cached data.
        recovered={}
        for candidate in (self.root/"packages").glob("*/*/*"):
            if candidate.is_dir() and not candidate.is_symlink():
                try:pkg=self._read_directory(candidate)
                except ModError:continue
                key=pkg.package_id+"@"+pkg.version
                old=self.registry["packages"].get(key)
                if old is None:recovered[key]=pkg.metadata()
        if recovered:
            with self._transaction():
                planned=self._load()
                for key,value in recovered.items():planned["packages"].setdefault(key,value)
                try:_registry_payload(planned)
                except ModError as exc:
                    if exc.code!="ModRegistryLimit":raise
                    # A crash-recovery candidate can exceed capacity while the
                    # previous registry remains valid. Preserve its active
                    # packages and show a management diagnostic separately.
                    self.recovery_error=exc;return
                self.registry=planned
                self._save()
    def _read_directory(self,path):
        self._guard_storage(path)
        root=path.resolve()
        if not root.is_relative_to((self.root/"packages").resolve()) or path.is_symlink():fail("Installed package path escaped root")
        files={};total=0
        for child in path.rglob("*"):
            self._guard_storage(child)
            if not child.is_file():continue
            name=child.relative_to(path).as_posix();safe_path(name)
            if Path(name).suffix.lower() not in ALLOWED_EXTENSIONS:fail("Unsupported installed payload type",name)
            if child.stat().st_size>LIMITS["fileBytes"]:fail("Installed payload exceeds quota",name)
            total+=child.stat().st_size
            if len(files)>=LIMITS["files"]+1 or total>LIMITS["expandedBytes"]:fail("Installed package exceeds quota")
            files[name]=child.read_bytes()
        if len(files)>LIMITS["files"]+1 or sum(map(len,files.values()))>LIMITS["expandedBytes"]:fail("Installed package exceeds quota")
        return _inspect_payload(files,path)
    def install(self,source):
        pkg=inspect_package(source,self.base_document)
        with self._transaction():
            self.registry=self._load();key=pkg.package_id+"@"+pkg.version
            old=self.registry["packages"].get(key)
            if old and old["digest"]!=pkg.digest:fail("Same package/version has different content",key,"ModIdentityConflict")
            destination=self.root/"packages"/pkg.package_id/pkg.version/pkg.digest
            self._guard_storage(destination)
            if destination.exists():
                existing=self._read_directory(destination)
                if existing.digest!=pkg.digest:fail("Installed directory was modified",key)
                if old is None:
                    # An interrupted earlier publication is not an installed
                    # package until its registration can be committed as well.
                    planned=copy.deepcopy(self.registry);planned["packages"][key]=existing.metadata()
                    _registry_payload(planned);self.registry=planned;self._save()
                result=existing.metadata();result["duplicate"]=True;return result
            planned=copy.deepcopy(self.registry);planned["packages"][key]=pkg.metadata()
            # The exact registration must fit before publishing any payload.
            # The cross-process transaction prevents a concurrent writer from
            # changing this budget between preflight and the atomic save.
            _registry_payload(planned)
            staging=self.root/"staging"/uuid.uuid4().hex
            self._guard_storage(staging)
            staging.mkdir()
            try:
                for name,raw in pkg.payloads.items():
                    target=staging/name;target.parent.mkdir(parents=True,exist_ok=True)
                    with target.open("xb") as stream:stream.write(raw);stream.flush();os.fsync(stream.fileno())
                self._guard_storage(destination.parent);destination.parent.mkdir(parents=True,exist_ok=True)
                self._guard_storage(destination);self._guard_storage(staging);os.replace(staging,destination)
                self.registry=planned;self._save()
            finally:
                if staging.exists() and staging.resolve().is_relative_to((self.root/"staging").resolve()):shutil.rmtree(staging)
            return pkg.metadata()
    def get(self,package_id_,version_,digest_=None):
        package_id(package_id_);version(version_)
        self.registry=self._load();meta=self.registry["packages"].get(package_id_+"@"+version_)
        if not meta or (digest_ and meta["digest"]!=digest_):fail("Package version/content is not installed",package_id_+"@"+version_,"ModMissingPackage")
        path=self.root/"packages"/package_id_/version_/meta["digest"]
        if not path.is_dir():fail("Active package files were removed",str(path),"ModMissingPackage")
        pkg=self._read_directory(path)
        if pkg.digest!=meta["digest"]:fail("Installed package content was changed",str(path),"ModCorruptPackage")
        return pkg
    def scan(self):
        def failure(error):
            limited=error.code=="ModRegistryLimit"
            return [{"packageId":"","version":"0.0.0","digest":"","contentDigest":"","name":"安装注册表达到容量限制" if limited else "安装注册表损坏","author":"","kind":"error","status":"error" if limited else "corrupt","reason":str(error),"error":error.as_dict(),"heroes":[],"patches":[]}]
        if self.catalog_error:return failure(self.catalog_error)
        from mod_compile import Compiler
        try:self.registry=self._load()
        except ModError as exc:return failure(exc)
        result=[]
        for meta in sorted(self.registry["packages"].values(),key=lambda x:(x["name"],version(x["version"]))):
            row=copy.deepcopy(meta)
            row["defaultChannels"]={key:True for key in CHANNELS};row["defaultPatchScopes"]={key:True for key in SCOPES}
            try:
                pkg=self.get(row["packageId"],row["version"],row["digest"])
                # Presentation/entities come from verified active bytes, never
                # stale or externally edited descriptive registry cache rows.
                row.update(pkg.metadata());row["status"]="installed"
                row["defaultChannels"].update(pkg.manifest.get("integrationDefaults",{}))
                for hero in row.get("heroes",[]):
                    hero["identity"]=f"mod:{pkg.package_id}/hero/{hero['id']}/{hero['variant']}"
                    hero["aid"]=self.allocate_hero(pkg.package_id,hero["id"],hero["variant"],hero["quality"],{"name":hero["name"],"packageName":pkg.manifest["name"],"progression":hero["progression"],"levelCap":hero["levelCap"],"unitType":"hero"})
                    unavailable,support=Compiler.channel_applicability(hero["quality"])
                    channels={**row["defaultChannels"],**hero.get("integrationDefaults",{})};default_channels=copy.deepcopy(channels)
                    for channel in unavailable:channels[channel]=False
                    hero.update({"kind":"new","available":True,"channels":channels,"channelSupport":support,"unavailableChannels":unavailable,"patchScopes":{},"defaultChannels":default_channels,"defaultPatchScopes":{key:True for key in SCOPES}})
                if pkg.manifest["kind"]=="patch":
                    targets={}
                    for patch in pkg.data.get("patches",{}).get("patches",[]):
                        identity=patch["target"];definition={};aid=None
                        if identity.startswith("builtin:avatar/") or identity.startswith("builtin:hero/"):
                            aid=identity.split("/",1)[1];definition=(self.base_document or {}).get("cfg",self.base_document or {}).get("avatar",{}).get(aid,{})
                        elif identity.startswith("mod:"):
                            binding=self._load()["identities"].get(identity,{})
                            aid=binding.get("aid");definition=binding
                        quality=int(aid.rsplit("_",1)[1]) if aid and aid.rsplit("_",1)[-1].isdigit() else 0
                        unavailable,support=Compiler.channel_applicability(quality,False)
                        channels={**row["defaultChannels"],**patch.get("integrationDefaults",{})};default_channels=copy.deepcopy(channels)
                        if not definition:
                            unavailable={key:"Install and resolve the precise target dependency before configuring this integration" for key in CHANNELS}
                            support={key:{"supported":False,"applicable":False,"reason":unavailable[key]} for key in CHANNELS}
                        for channel in unavailable:channels[channel]=False
                        scopes={key:True for key in SCOPES};scopes.update(patch.get("patchScopes",{}))
                        if identity not in targets:targets[identity]={"identity":identity,"aid":aid,"id":patch["id"],"name":definition.get("name",identity),"variant":"quality"+str(quality),"quality":quality,"kind":"builtin" if identity.startswith("builtin:") else "new","available":bool(definition),"channels":channels,"channelSupport":support,"unavailableChannels":unavailable,"patchScopes":scopes,"defaultChannels":default_channels,"defaultPatchScopes":copy.deepcopy(scopes),"patchIds":[patch["id"]]}
                        else:
                            target=targets[identity];target["channels"]={key:target["channels"][key] and channels[key] for key in CHANNELS};target["patchIds"].append(patch["id"])
                    row["heroes"]=list(targets.values())
            except ModError as exc:row["status"]="missing" if exc.code=="ModMissingPackage" else "error" if exc.code=="ModRegistryLimit" else "corrupt";row["error"]=exc.as_dict();row["reason"]=str(exc)
            result.append(row)
        if getattr(self,"recovery_error",None):result.extend(failure(self.recovery_error))
        return result
    def import_inbox(self):
        """Explicit local-folder import. Files stay in inbox; retries deduplicate."""
        results=[]
        self._guard_storage(self.root/"inbox")
        sources=sorted((path for path in (self.root/"inbox").iterdir() if path.suffix.lower()==".heropack"),key=lambda p:p.name.casefold())
        if len(sources)>128:fail("Inbox has more than 128 package files; import in smaller batches","inbox","ModQuotaExceeded")
        for source in sources:
            try:results.append({**self.install(source),"source":source.name,"ok":True})
            except (ModError,OSError) as exc:
                error=exc.as_dict() if isinstance(exc,ModError) else {"code":"ModFileError","message":str(exc),"path":source.name}
                results.append({"source":source.name,"name":source.name,"packageId":"","version":"0.0.0","contentDigest":"","kind":"error","status":"corrupt","ok":False,"reason":str(exc),"error":error,"heroes":[],"patches":[]})
        return results
    def uninstall(self,package_id_,version_,digest_=None):
        with self._transaction():
            package_id(package_id_);version(version_);self.registry=self._load()
            key=package_id_+"@"+version_;meta=self.registry["packages"].get(key)
            if not meta:fail("Package is not registered",key,"ModMissingPackage")
            if digest_ and digest_!=meta["digest"]:fail("Stale package digest",key,"ModStalePlan")
            target=self.root/"packages"/package_id_/version_/meta["digest"]
            self._guard_storage(target);target=target.resolve()
            if not target.is_relative_to((self.root/"packages").resolve()) or target==self.root:fail("Unsafe uninstall path")
            if target.exists():shutil.rmtree(target)
            # Keep metadata and all identity tombstones. Missing is observable.
            self.registry["packages"][key]["status"]="missing";self._save()
            return copy.deepcopy(self.registry["packages"][key])
    def allocate_hero(self,pid,local,variant,quality,metadata=None):
        identity=f"mod:{pid}/hero/{local}/{variant}";family=f"mod:{pid}/hero/{local}"
        with self._transaction():
            self.registry=self._load()
            if identity in self.registry["identities"]:
                old=self.registry["identities"][identity]
                if int(old["aid"].rsplit("_",1)[1])!=quality:fail("Existing identity cannot change quality",identity,"ModMigrationRequired")
                for key in ("progression","levelCap","unitType"):
                    if metadata and key in old and key in metadata and old[key]!=metadata[key]:fail("Persistent progression change needs an explicit migration; API 1 refuses it",identity+"."+key,"ModMigrationRequired")
                return old["aid"]
            families=self.registry["families"]
            if family not in families:
                occupied={str(v) for v in families.values()}
                base=(self.base_document or {}).get("cfg",self.base_document or {}).get("avatar",{})
                while self.registry["nextFamily"]<=199999:
                    number=self.registry["nextFamily"];self.registry["nextFamily"]+=1
                    if str(number) not in occupied and not any(f"A_{number}_{q}" in base for q in range(2,7)):families[family]=number;break
                else:fail("Compatible hero number range exhausted",code="ModIdentityExhausted")
            aid=f"A_{families[family]}_{quality}"
            if any(v["aid"]==aid for v in self.registry["identities"].values()):fail("Two variants claim the same quality in a hero family",identity,"ModIdentityConflict")
            self.registry["identities"][identity]={"aid":aid,"identity":identity,"packageId":pid,**(metadata or {})};self._save();return aid
    def allocate_alias(self,key,quality):
        with self._transaction():
            self.registry=self._load();aliases=self.registry["aliases"]
            if key in aliases:return aliases[key]
            if self.registry["nextAlias"]>179999:fail("Definition alias range exhausted",code="ModIdentityExhausted")
            value=f"A_{self.registry['nextAlias']}_{quality}";self.registry["nextAlias"]+=1;aliases[key]=value;self._save();return value
    def allocate_skill(self,key,quality=1):
        with self._transaction():
            self.registry=self._load();aliases=self.registry.setdefault("skills",{})
            if key in aliases:return aliases[key]
            if self.registry["nextSkill"]>899999:fail("Skill number range exhausted",code="ModIdentityExhausted")
            value=f"S_{self.registry['nextSkill']}_{quality}";self.registry["nextSkill"]+=1;aliases[key]=value;self._save();return value
    def identity_snapshot(self):
        self.registry=self._load();return copy.deepcopy({k:self.registry[k] for k in ("identities","families")})
    def validate_identity_snapshot(self,snapshot):
        """Validate a backup without reserving numbers or touching the registry."""
        import re
        if not isinstance(snapshot,dict) or set(snapshot)!={"identities","families"} or any(not isinstance(snapshot[k],dict) for k in snapshot):fail("Invalid identity snapshot structure",code="ModInvalidBackup")
        families=snapshot["families"];numbers=set();bound=set()
        for family,value in families.items():
            m=re.fullmatch(r"mod:([0-9a-f-]+)/hero/([A-Za-z][A-Za-z0-9_-]{0,63})",str(family))
            if not m:fail("Invalid restored family identity",str(family),"ModInvalidBackup")
            package_id(m.group(1))
            if type(value) is not int or not 180000<=value<=199999 or value in numbers:fail("Invalid/duplicate restored family number",family,"ModInvalidBackup")
            numbers.add(value)
        for identity,row in snapshot["identities"].items():
            m=re.fullmatch(r"(mod:([0-9a-f-]+)/hero/([A-Za-z][A-Za-z0-9_-]{0,63}))/([A-Za-z][A-Za-z0-9_-]{0,63})",str(identity))
            if not m or not isinstance(row,dict):fail("Invalid restored entity identity",str(identity),"ModInvalidBackup")
            package_id(m.group(2));aid=row.get("aid")
            if not isinstance(aid,str) or not re.fullmatch(r"A_1[89][0-9]{4}_[2-6]",aid) or aid in bound:fail("Invalid/duplicate restored hero number",identity,"ModInvalidBackup")
            if families.get(m.group(1))!=int(aid.split("_")[1]):fail("Restored hero and family number differ",identity,"ModInvalidBackup")
            if aid in (self.base_document or {}).get("cfg",self.base_document or {}).get("avatar",{}):fail("Restored number collides with builtin content",identity,"ModMigrationRequired")
            if row.get("identity",identity)!=identity or row.get("packageId",m.group(2))!=m.group(2):fail("Restored identity metadata differs",identity,"ModInvalidBackup")
            bound.add(aid)
        return copy.deepcopy(snapshot)
    def restore_identities(self,snapshot):
        snapshot=self.validate_identity_snapshot(snapshot)
        with self._transaction():
            self.registry=self._load();planned=copy.deepcopy(self.registry)
            for identity,row in snapshot.get("identities",{}).items():
                if identity in planned["identities"] and planned["identities"][identity]["aid"]!=row["aid"]:fail("Restore identity uses a different internal number; migration required",identity,"ModMigrationRequired")
                if any(k!=identity and v["aid"]==row["aid"] for k,v in planned["identities"].items()):fail("Restored internal number is already bound; full migration required",identity,"ModMigrationRequired")
                if not __import__("re").fullmatch(r"A_1[89][0-9]{4}_[2-6]",str(row.get("aid"))):fail("Invalid restored hero number",identity)
                planned["identities"][identity]=copy.deepcopy(row)
            for key,value in snapshot.get("families",{}).items():
                if key in planned["families"] and planned["families"][key]!=value:fail("Restored family conflicts",key,"ModMigrationRequired")
                if any(other!=key and number==value for other,number in planned["families"].items()):fail("Restored family number is already reserved",key,"ModMigrationRequired")
                planned["families"][key]=value
            self.registry=planned;self._save()
    def preview_restore(self,snapshot,base_document,settings,roster_side=None,allow_missing=True):
        """Compile restored bindings using an isolated in-memory registry.

        Package bytes are still read and verified from active installation, but
        ID/skill/alias allocations never reserve a number on disk. The owner
        should hold its existing activation lock from preview through commit.
        """
        source=self
        class PreviewCatalog(ModCatalog):
            def __init__(self):
                self.root=source.root;self.registry_path=source.registry_path
                self.base_document=source.base_document;self.catalog_error=source.catalog_error
                self._memory=copy.deepcopy(source._load());self.registry=copy.deepcopy(self._memory)
            def _load(self):
                if self.catalog_error:raise self.catalog_error
                return copy.deepcopy(self._memory)
            def _save(self):
                try:_registry_payload(self.registry)
                except ModError:
                    self.registry=copy.deepcopy(self._memory);raise
                self._memory=copy.deepcopy(self.registry)
            @contextlib.contextmanager
            def _transaction(self):
                with self._lock:yield
        preview=PreviewCatalog();preview.restore_identities(snapshot)
        return preview.compile(base_document,settings,roster_side,allow_missing)
    def resolve_digest_asset(self,digest_,path):
        safe_path(path)
        if not isinstance(digest_,str) or not __import__("re").fullmatch(r"[0-9a-f]{64}",digest_):fail("Invalid content digest")
        # Asset reads must not enumerate/validate every installed archive or
        # allocate unrelated hero identities. The registry locates one precise
        # content version; get() still verifies all bytes of that selected pack.
        self.registry=self._load()
        row=next((row for row in self.registry["packages"].values() if row["digest"]==digest_),None)
        if row is None:fail("Active asset package is missing",path,"ModMissingPackage")
        pkg=self.get(row["packageId"],row["version"],digest_)
        if path not in pkg.media:fail("Path is not a declared media asset",path)
        target=(pkg.path/path).resolve()
        if not target.is_relative_to(pkg.path.resolve()):fail("Asset escaped package root",path)
        return target
    def resolve_asset(self,pid,version_,digest_,path):
        pkg=self.get(pid,version_,digest_);return self.resolve_digest_asset(pkg.digest,path)
    def compile(self,base_document,settings,roster_side=None,allow_missing=False):
        from mod_compile import compile_config
        return compile_config(self,base_document,settings,roster_side,allow_missing)
