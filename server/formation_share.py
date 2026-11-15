"""Portable, bounded arena snapshots and a persistent private challenge library.

Codes carry a frozen battle snapshot. Importing only requires that every hero
still exists in the current version: attributes and positions are kept as
exported, skill rows are refreshed from the current configuration and battle
power is recomputed. Combat-rule differences between versions are accepted.
"""
from __future__ import annotations

import base64
import copy
import hashlib
import json
import math
import re
import struct
import time
import zlib

from battle_engine import validate_team_lane_coverage
from battle_intents import create_intent, consume_intent
from native_skill_snapshot import _native_skill_snapshot
from player_store import GameplayFault

PREFIX = 'LALF1'
MAX_CODE = 131072
MAX_PAYLOAD = 262144
NAME_LIMIT = 16
FORMATION_ID = re.compile('s[a-f0-9]{32}')
METHODS = {'user.export_formation', 'user.import_formation', 'user.list_formations',
           'user.delete_formation', 'user.pk_combat_formation', 'user.rename_formation',
           'user.formation_code'}
UNIT_KEYS = {'aid','ap','morph','buffs','de_ma','de_ph','hp','hp_max','isme','leader','line','lv',
             'new_4attrs','pos','slv','tpl','talent','skill','leader_skill','book_skill','skillB',
             'skill_diff','modUnitType','phase','culture_schema','bonds_104','equipment_bonds_104',
             'limit_break','growth_stats_applied','base_aid'}
REQUIRED_UNIT_KEYS = {'aid','hp','hp_max','ap','de_ph','de_ma','lv','slv','line','pos','leader','tpl','new_4attrs'}
SKILL_KEYS = ('skill','leader_skill','book_skill','skillB')
RESULT_COLUMNS = (('wins','INTEGER NOT NULL DEFAULT 0'),('losses','INTEGER NOT NULL DEFAULT 0'),
                  ('last_result','INTEGER NOT NULL DEFAULT 0'),('last_at','INTEGER NOT NULL DEFAULT 0'))


def fail(code, message):
    raise GameplayFault(code, message)


def wire_value(value):
    # Preserve IEEE doubles exactly. Android's translated ARM runtime can parse
    # a JSON decimal one ULP differently even when it wrote that decimal itself.
    if isinstance(value,float):
        if not math.isfinite(value): raise ValueError('nonfinite snapshot')
        return {'$f64':struct.pack('>d',value).hex()}
    if isinstance(value,dict): return {key:wire_value(v) for key,v in value.items()}
    if isinstance(value,list): return [wire_value(v) for v in value]
    return value


def unwire_value(value):
    if isinstance(value,dict):
        if '$f64' in value:
            if set(value)!={'$f64'} or not isinstance(value['$f64'],str) or not re.fullmatch('[a-f0-9]{16}',value['$f64']):
                raise ValueError('invalid double')
            number=struct.unpack('>d',bytes.fromhex(value['$f64']))[0]
            if not math.isfinite(number): raise ValueError('nonfinite double')
            return number
        return {key:unwire_value(v) for key,v in value.items()}
    if isinstance(value,list): return [unwire_value(v) for v in value]
    return value


def canonical(value):
    return json.dumps(wire_value(value), ensure_ascii=False, sort_keys=True, separators=(',', ':'), allow_nan=False).encode('utf-8')


def same_skill_value(left,right):
    # Skill formulas evaluated on different CPU architectures may differ by an ULP.
    if type(left) in (int,float) and type(right) in (int,float):
        return math.isfinite(left) and math.isfinite(right) and math.isclose(left,right,rel_tol=1e-12,abs_tol=1e-12)
    if isinstance(left,list) and isinstance(right,list):
        return len(left)==len(right) and all(same_skill_value(a,b) for a,b in zip(left,right))
    if isinstance(left,dict) and isinstance(right,dict):
        return left.keys()==right.keys() and all(same_skill_value(left[k],right[k]) for k in left)
    return type(left) is type(right) and left==right


def clean_name(value, fallback=None):
    """Return a display-safe formation name, or ``fallback`` when blank."""
    if value is None: return fallback
    if not isinstance(value,str): fail('InvalidFormationName','阵容名称格式不正确。')
    text=''.join(c for c in value if ord(c)>=32 and c not in '  ').strip()
    text=re.sub(r'\s+',' ',text)
    if not text: return fallback
    return text[:NAME_LIMIT]


def encode_code(payload):
    raw = canonical(payload)
    if len(raw) > MAX_PAYLOAD:
        fail('FormationTooLarge', '阵容配置过大，无法生成分享代码。')
    packed = base64.urlsafe_b64encode(zlib.compress(raw, 9)).decode('ascii').rstrip('=')
    code = PREFIX+'.'+packed+'.'+hashlib.sha256(raw).hexdigest()[:20]
    if len(code) > MAX_CODE:
        fail('FormationTooLarge', '阵容配置过大，无法生成分享代码。')
    return code


def decode_code(code):
    if not isinstance(code, str) or not 1 <= len(code) <= MAX_CODE:
        fail('InvalidFormationCode', '阵容代码为空或过长。')
    code = ''.join(code.split())
    # Chat apps sometimes wrap a pasted code with quotes or other text.
    found = re.search(re.escape(PREFIX)+r'\.[A-Za-z0-9_-]+\.[a-f0-9]{20}', code)
    if found: code = found.group(0)
    parts = code.split('.')
    if len(parts) != 3 or parts[0] != PREFIX:
        fail('InvalidFormationCode', '无法识别阵容代码，请复制以 LALF1 开头的完整代码。')
    try:
        packed = base64.b64decode(parts[1]+'='*(-len(parts[1])%4), altchars=b'-_', validate=True)
        decoder = zlib.decompressobj()
        raw = decoder.decompress(packed, MAX_PAYLOAD+1)
        if len(raw) > MAX_PAYLOAD or not decoder.eof or decoder.unconsumed_tail or decoder.unused_data:
            raise ValueError('bounded stream')
        if not re.fullmatch('[a-f0-9]{20}', parts[2]) or hashlib.sha256(raw).hexdigest()[:20] != parts[2]:
            raise ValueError('checksum')
        payload = json.loads(raw.decode('utf-8'), parse_constant=lambda value: (_ for _ in ()).throw(ValueError(value)))
    except (ValueError, UnicodeError, zlib.error, RecursionError):
        fail('InvalidFormationCode', '阵容代码不完整或已损坏，请重新复制。')
    try:
        if not isinstance(payload, dict) or canonical(payload) != raw: raise ValueError('noncanonical snapshot')
        return unwire_value(payload)
    except (ValueError,RecursionError):
        fail('InvalidFormationCode', '阵容代码内容格式不正确。')


def formation_id(members):
    """Identity ignores the name, so renaming never creates a duplicate entry."""
    return 's'+hashlib.sha256(canonical(members)).hexdigest()[:32]


def _number(value, low, high):
    return type(value) in (int,float) and math.isfinite(value) and low <= value <= high


class FormationLibrary:
    def __init__(self, competition):
        self.arena = competition
        self.store = competition.store
        self.cfg = competition.cfg
        db=getattr(self.store,'db',None)
        if db is None: return  # power-only tools construct the arena without storage
        db.execute('CREATE TABLE IF NOT EXISTS formation_library(uid TEXT NOT NULL,id TEXT NOT NULL,payload TEXT NOT NULL,created INTEGER NOT NULL,PRIMARY KEY(uid,id))')
        columns={row[1] for row in db.execute('PRAGMA table_info(formation_library)')}
        for name,kind in RESULT_COLUMNS:
            if name not in columns: db.execute(f'ALTER TABLE formation_library ADD COLUMN {name} {kind}')
        db.commit()

    @property
    def line_size(self):
        return int(self.cfg['system_simple']['battle'][1])

    @property
    def lanes(self):
        return len(self.cfg['system_simple']['pvp_line'][0][1])

    def dispatch(self, uid, method, params):
        if method == 'user.export_formation': return self.export(uid, params)
        if method == 'user.import_formation': return self.import_code(uid, params)
        if method == 'user.list_formations': return {'formations': self.list(uid)}
        if method == 'user.delete_formation': return self.delete(uid, params)
        if method == 'user.pk_combat_formation': return self.start(uid, params)
        if method == 'user.rename_formation': return self.rename(uid, params)
        if method == 'user.formation_code': return self.code(uid, params)
        fail('NotImplemented', method)

    # ----- own team -------------------------------------------------------
    def own(self, profile, params):
        team, team_num = params.get('team'), params.get('team_num', 0)
        if not _number(team_num,0,2) or int(team_num)!=team_num:
            fail('InvalidFormation', '请选择有效的出战队伍。')
        team_num=int(team_num)
        if not isinstance(team, list) or not 1 <= len(team) <= 5 or not team[0]:
            fail('InvalidFormation', '竞技场阵容最多5人，且必须布置队长。')
        selected = []
        saved = (profile.get('team') or [[], [], []])[team_num]
        for row in team:
            if not row:
                selected.append(None)
                continue
            if not isinstance(row, list) or len(row) < 3 or not isinstance(row[0], str):
                fail('InvalidFormation', '阵容站位格式不正确。')
            iid = row[0]
            if iid not in saved or iid not in profile.get('avatars', {}) or iid in selected:
                fail('InvalidFormation', '阵容包含重复、未拥有或不在当前队伍中的英雄，请先保存队伍。')
            if not _number(row[1],0,self.lanes-1) or int(row[1]) != row[1]:
                fail('InvalidFormation', '阵容路线不正确。')
            if not _number(row[2],0,1):
                fail('InvalidFormation', '阵容站位超出地图范围。')
            selected.append(iid)
        # Only the actual five combat slots may activate bonds and team auras.
        projection = copy.deepcopy(profile)
        projection['team'][team_num] = selected+[None]*(6-len(selected))
        units = self.arena._own_team(projection, params)
        try:
            validate_team_lane_coverage(units, self.lanes, 'formation')
        except ValueError:
            fail('InvalidFormation', '每条路线至少布置1名英雄。')
        return units

    # ----- snapshot normalization ----------------------------------------
    def _skill(self, unit, key):
        snapshot=unit.get(key)
        if snapshot is None: return None
        if not isinstance(snapshot,dict) or not isinstance(snapshot.get('skid'),str):
            fail('InvalidFormationCode', '英雄技能信息不正确。')
        rank=snapshot.get('slv', unit['slv'] if key=='skill' else 1)
        if type(rank) is not int or not 1<=rank<=10:
            fail('InvalidFormationCode', '英雄技能等级不正确。')
        expected=_native_skill_snapshot(self.cfg,snapshot['skid'],rank)
        if expected is None: return None
        refreshed=copy.deepcopy(snapshot)
        # Skill rows follow the current version; rank and identity are kept.
        for name in ('pl','skills','cd'):
            if name in expected and not same_skill_value(snapshot.get(name),expected[name]):
                refreshed[name]=copy.deepcopy(expected[name])
        return refreshed

    def _unit(self, index, raw):
        if not isinstance(raw,dict) or not REQUIRED_UNIT_KEYS.issubset(raw):
            fail('InvalidFormationCode', '英雄战斗属性不完整。')
        unit={key:copy.deepcopy(value) for key,value in raw.items() if key in UNIT_KEYS}
        if not isinstance(unit['aid'],str) or unit['aid'] not in self.cfg['avatar']:
            fail('FormationHeroUnavailable', '阵容中有英雄在当前版本不可用。')
        for key,low,high in (('lv',1,125),('slv',1,10),('line',0,self.lanes-1),('phase',0,3)):
            value=unit.get(key,0)
            if type(value) is not int or not low <= value <= high:
                fail('InvalidFormationCode', '英雄等级、进阶或路线不正确。')
        for key in ('hp_max','ap','de_ph','de_ma','pos'):
            if not _number(unit[key],0,self.line_size if key=='pos' else 1_000_000_000):
                fail('InvalidFormationCode', '英雄战斗属性超出范围。')
        if unit['hp_max'] <= 0:
            fail('InvalidFormationCode', '英雄生命值不正确。')
        if not isinstance(unit['tpl'],list) or len(unit['tpl']) != 5 or not all(_number(v,0,100000) for v in unit['tpl']):
            fail('InvalidFormationCode', '英雄基础参数不正确。')
        attrs=unit['new_4attrs']
        if not isinstance(attrs,dict) or set(attrs) != {'hit','flee','crit','tough'} or not all(_number(v,0,1_000_000_000) for v in attrs.values()):
            fail('InvalidFormationCode', '英雄四维属性不正确。')
        if unit.get('talent') is not None:
            if not isinstance(unit['talent'],str) or len(unit['talent'])>64:
                fail('InvalidFormationCode', '英雄天赋信息不正确。')
            # A talent removed in this version is dropped; the hero stays.
            if unit['talent'] not in self.cfg.get('talent',{}): unit.pop('talent')
        if (type(unit.get('limit_break',0)) is not int or unit.get('limit_break',0) not in (0,1)
                or not isinstance(unit.get('culture_schema',''),str) or len(unit.get('culture_schema',''))>64
                or type(unit.get('growth_stats_applied',True)) is not bool):
            fail('InvalidFormationCode', '英雄突破或成长参数不正确。')
        if unit['lv']>99: unit['limit_break']=1
        for key in ('bonds_104','equipment_bonds_104'):
            rows=unit.get(key,[])
            if not isinstance(rows,list) or len(rows)>64 or any(not isinstance(v,str) or len(v)>128 for v in rows):
                fail('InvalidFormationCode', '英雄羁绊信息不正确。')
        for key in SKILL_KEYS:
            if key not in unit: continue
            skill=self._skill(unit,key)
            if skill is None:
                if key=='skill': fail('FormationHeroUnavailable', '阵容中有英雄技能在当前版本不可用。')
                unit.pop(key)
            else: unit[key]=skill
        unit.update(buffs={}, hp=unit['hp_max'], isme=True, leader=1 if index==0 else 0)
        return unit

    def normalize(self, payload):
        """Return a version-independent snapshot or raise for unusable codes."""
        if not isinstance(payload,dict) or payload.get('v')!=1 or type(payload.get('v')) is not int:
            fail('InvalidFormationCode', '不支持此阵容代码版本。')
        members=payload.get('members')
        if not isinstance(members,list) or not 1 <= len(members) <= 5:
            fail('InvalidFormationCode', '阵容英雄数量不正确。')
        units=[self._unit(i,unit) for i,unit in enumerate(members)]
        try: validate_team_lane_coverage(units,self.lanes,'imported formation')
        except ValueError: fail('InvalidFormationCode','阵容没有覆盖全部路线。')
        author=clean_name(payload.get('author') if isinstance(payload.get('author'),str) else None,'玩家')
        level=payload.get('level')
        level=level if type(level) is int and 1 <= level <= 125 else max(u['lv'] for u in units)
        name=clean_name(payload.get('name') if isinstance(payload.get('name'),str) else None,author+'的阵容')
        return dict(v=1,name=name,author=author,level=level,members=units,power=self.arena._team_power(units))

    def enemy(self,payload):
        enemy=copy.deepcopy(payload['members'])
        for unit in enemy:unit['isme']=False;unit['pos']=self.line_size-unit['pos']
        return enemy

    # ----- storage ---------------------------------------------------------
    def _row(self, uid, fid):
        if not isinstance(fid,str) or not FORMATION_ID.fullmatch(fid):
            fail('UnknownFormation','该阵容不存在或已经删除。')
        row=self.store.db.execute('SELECT payload,created,wins,losses,last_result,last_at FROM formation_library WHERE uid=? AND id=?',(str(uid),fid)).fetchone()
        if row is None: fail('UnknownFormation','该阵容不存在或已经删除。')
        return row

    def _stored(self, uid, fid):
        return unwire_value(json.loads(self._row(uid,fid)[0]))

    def preview(self, uid, fid):
        """Compact enemy rows for the native embattle preview, or None."""
        if not isinstance(fid,str) or not FORMATION_ID.fullmatch(fid): return None
        row=self.store.db.execute('SELECT payload FROM formation_library WHERE uid=? AND id=?',(str(uid),fid)).fetchone()
        if row is None: return []
        payload=unwire_value(json.loads(row[0]))
        try: payload=self.normalize(payload)
        except GameplayFault: return []
        return self.arena._compact(self.enemy(payload))

    @staticmethod
    def _date(seconds):
        return time.strftime('%m-%d %H:%M',time.localtime(seconds)) if seconds else ''

    def summary(self, fid, payload, created, wins=0, losses=0, last_result=0, last_at=0):
        try:
            current=self.normalize(payload);playable=True
        except GameplayFault:
            current=payload;playable=False
        compact=self.arena._compact(self.enemy(current)) if playable else []
        return dict(id=fid,formation_id=fid,status=0,indexID_s=1000,numberIndex=0,
                    name=current['name'],author=current['author'],lv=current['level'],data_base=compact,
                    is_enemy=-1,mark=0,formation_power=int(current.get('power',0)),hero_count=len(current['members']),
                    compatible=playable,created=created,created_text=self._date(created),
                    wins=wins,losses=losses,last_result=last_result,last_at=last_at)

    def list(self, uid):
        with self.store.lock:
            rows=self.store.db.execute('SELECT id,payload,created,wins,losses,last_result,last_at FROM formation_library WHERE uid=? ORDER BY created DESC,id',(str(uid),)).fetchall()
            return [self.summary(fid,unwire_value(json.loads(raw)),*rest) for fid,raw,*rest in rows]

    def _save(self, uid, payload, name=None):
        if name: payload=dict(payload,name=name)
        fid=formation_id(payload['members'])
        db=self.store.db
        exists=db.execute('SELECT payload,created,wins,losses,last_result,last_at FROM formation_library WHERE uid=? AND id=?',(str(uid),fid)).fetchone()
        if exists:
            stored=unwire_value(json.loads(exists[0]))
            if name and stored.get('name')!=name:
                stored['name']=name
                db.execute('UPDATE formation_library SET payload=? WHERE uid=? AND id=?',(canonical(stored).decode('utf-8'),str(uid),fid))
            return self.summary(fid,stored,*exists[1:]),True
        created=self.store.clock.now()
        db.execute('INSERT INTO formation_library(uid,id,payload,created) VALUES(?,?,?,?)',(str(uid),fid,canonical(payload).decode('utf-8'),created))
        return self.summary(fid,payload,created),False

    # ----- RPC methods ---------------------------------------------------------
    def export(self, uid, params):
        def change(profile):
            units = self.own(profile, params)
            members = []
            for unit in units:
                frozen = {key: copy.deepcopy(value) for key,value in unit.items() if key in UNIT_KEYS}
                frozen.update(buffs={}, hp=frozen['hp_max'], isme=True)
                members.append(frozen)
            author = clean_name(str(profile.get('name') or ''),'玩家')
            default = author+'的阵容'
            name = clean_name(params.get('name'),default)
            payload = self.normalize(dict(v=1, name=name, author=author, level=int(profile.get('lv',1)), members=members))
            result={'code': encode_code(payload), 'name': payload['name'], 'default_name': default,
                    'power': payload['power'], 'hero_count': len(payload['members'])}
            if params.get('save') is True:
                result['formation'],result['already_saved']=self._save(uid,payload)
            return result
        return self.arena._write(uid, 'user.export_formation', params, change)

    def import_code(self, uid, params):
        payload=self.normalize(decode_code(params.get('code')))
        name=clean_name(params.get('name'))
        def change(profile):
            summary,existed=self._save(uid,payload,name)
            return {'formation':summary,'already_saved':existed}
        return self.arena._write(uid,'user.import_formation',params,change)

    def code(self, uid, params):
        """Re-encode a saved entry or a code under an optional new name."""
        if params.get('formation_id') is not None:
            payload=self.normalize(self._stored(uid,params['formation_id']))
        else:
            payload=self.normalize(decode_code(params.get('code')))
        name=clean_name(params.get('name'))
        if name: payload['name']=name
        return {'code':encode_code(payload),'name':payload['name'],'power':payload['power']}

    def rename(self, uid, params):
        fid=params.get('formation_id')
        name=clean_name(params.get('name'))
        if not name: fail('InvalidFormationName','请输入阵容名称。')
        def change(profile):
            payload=self._stored(uid,fid)
            payload['name']=name
            self.store.db.execute('UPDATE formation_library SET payload=? WHERE uid=? AND id=?',(canonical(payload).decode('utf-8'),str(uid),fid))
            return {'formation_id':fid,'name':name}
        return self.arena._write(uid,'user.rename_formation',params,change)

    def delete(self, uid, params):
        fid=params.get('formation_id')
        if not isinstance(fid,str) or not FORMATION_ID.fullmatch(fid):
            fail('UnknownFormation','该阵容不存在或已经删除。')
        def change(profile):
            count=self.store.db.execute('DELETE FROM formation_library WHERE uid=? AND id=?',(str(uid),fid)).rowcount
            return {'formation_id':fid,'deleted':bool(count)}
        return self.arena._write(uid,'user.delete_formation',params,change)

    def start(self, uid, params):
        def change(profile):
            payload=self.normalize(self._stored(uid,params.get('formation_id')))
            own=self.own(profile,params)
            enemy=self.enemy(payload)
            metadata=dict(formation_id=params['formation_id'],team_num=params.get('team_num',0),opponent_name=payload['name'])
            token=create_intent(profile,'formation',metadata,own,enemy,now=self.store.clock.now(),config=self.cfg)
            my_power,enemy_power=self.arena._team_power(own),self.arena._team_power(enemy)
            return dict(fight_kind='formation',fight_id=token['fight_id'],seed=token['seed'],metadata=metadata,
                        cid='V_000_0',def_th=self.arena._pvp_def_th(my_power,enemy_power),orgin_team_a=own,
                        orgin_team_b=enemy,team1=[],team2=[],sign=0,my_pr_power=my_power,pr_power=enemy_power,
                        poke_data=dict(gift_list=[{},{},{}],poke_gift_index=0,user_gift={}))
        return self.arena._write(uid,'user.pk_combat_formation',params,change)

    def finish(self, uid, params):
        def change(profile):
            intent=consume_intent(profile,'formation',params,metadata_keys=('formation_id','team_num'),now=self.store.clock.now(),config=self.cfg)
            fid=intent['metadata'].get('formation_id');won=intent['sign']==1
            # A deleted entry keeps no record; the battle itself still settles.
            self.store.db.execute('UPDATE formation_library SET wins=wins+?,losses=losses+?,last_result=?,last_at=? WHERE uid=? AND id=?',
                                  (int(won),int(not won),intent['sign'],self.store.clock.now(),str(uid),str(fid)))
            row=self.store.db.execute('SELECT wins,losses FROM formation_library WHERE uid=? AND id=?',(str(uid),str(fid))).fetchone()
            record=dict(wins=row[0],losses=row[1],last_result=intent['sign']) if row else None
            return dict(fight_id=intent['fight_id'],fight_kind='formation',sign=intent['sign'],metadata=intent['metadata'],
                        formation_record=record,poke_data=dict(gift_list=[{},{},{}],poke_gift_index=0,user_gift={}))
        return self.arena._write(uid,'user.battle_finish',params,change)
