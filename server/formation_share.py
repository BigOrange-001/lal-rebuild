"""Portable, bounded arena snapshots and a persistent private challenge library."""
from __future__ import annotations

import base64
import copy
import hashlib
import json
import math
import re
import struct
import zlib

from arena_opponents import COMBAT_CONFIG_TABLES, _signature_date
from battle_engine import validate_team_lane_coverage
from battle_intents import create_intent, consume_intent
from native_skill_snapshot import _native_skill_snapshot
from player_store import GameplayFault

PREFIX = 'LALF1'
MAX_CODE = 131072
MAX_PAYLOAD = 262144
METHODS = {'user.export_formation', 'user.import_formation', 'user.list_formations',
           'user.delete_formation', 'user.pk_combat_formation'}
UNIT_KEYS = {'aid','ap','morph','buffs','de_ma','de_ph','hp','hp_max','isme','leader','line','lv',
             'new_4attrs','pos','slv','tpl','talent','skill','leader_skill','book_skill','skillB',
             'skill_diff','modUnitType','phase','culture_schema','bonds_104','equipment_bonds_104',
             'limit_break','growth_stats_applied','base_aid'}


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


def portable_rule_value(value):
    if isinstance(value,float): return {'$number':format(value,'.12g')}
    if isinstance(value,dict): return {key:portable_rule_value(v) for key,v in value.items()}
    if isinstance(value,list): return [portable_rule_value(v) for v in value]
    return value


def same_skill_value(left,right):
    # Skill formulas evaluated on different CPU architectures may differ by an
    # ULP. Reject material changes while allowing that numeric representation.
    if type(left) in (int,float) and type(right) in (int,float):
        return math.isfinite(left) and math.isfinite(right) and math.isclose(left,right,rel_tol=1e-12,abs_tol=1e-12)
    if isinstance(left,list) and isinstance(right,list):
        return len(left)==len(right) and all(same_skill_value(a,b) for a,b in zip(left,right))
    if isinstance(left,dict) and isinstance(right,dict):
        return left.keys()==right.keys() and all(same_skill_value(left[k],right[k]) for k in left)
    return type(left) is type(right) and left==right


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
    parts = code.split('.')
    if len(parts) != 3 or parts[0] != PREFIX:
        fail('InvalidFormationCode', '无法识别阵容代码，请复制完整代码。')
    try:
        packed = base64.b64decode(parts[1]+'='*(-len(parts[1])%4), altchars=b'-_', validate=True)
        decoder = zlib.decompressobj()
        raw = decoder.decompress(packed, MAX_PAYLOAD+1)
        if len(raw) > MAX_PAYLOAD or not decoder.eof or decoder.unconsumed_tail or decoder.unused_data:
            raise ValueError('bounded stream')
        if not re.fullmatch('[a-f0-9]{20}', parts[2]) or hashlib.sha256(raw).hexdigest()[:20] != parts[2]:
            raise ValueError('checksum')
        payload = json.loads(raw.decode('utf-8'), parse_constant=lambda value: (_ for _ in ()).throw(ValueError(value)))
    except (ValueError, UnicodeError, zlib.error, RecursionError) as error:
        fail('InvalidFormationCode', '阵容代码不完整或已损坏，请重新复制。')
    try:
        if not isinstance(payload, dict) or canonical(payload) != raw: raise ValueError('noncanonical snapshot')
        return unwire_value(payload)
    except (ValueError,RecursionError):
        fail('InvalidFormationCode', '阵容代码内容格式不正确。')


class FormationLibrary:
    def __init__(self, competition):
        self.arena = competition
        self.store = competition.store
        self.cfg = competition.cfg

    @property
    def rules(self):
        from mod_policy import runtime, policy_signature
        tables={name:portable_rule_value(self.cfg.get(name,{})) for name in (*COMBAT_CONFIG_TABLES,'combat_rules')}
        if runtime(self.cfg):tables['mod_policy']=policy_signature(self.cfg)
        raw=json.dumps(tables,sort_keys=True,ensure_ascii=False,separators=(',',':'),default=_signature_date).encode('utf-8')
        return hashlib.sha256(raw).hexdigest()

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
        fail('NotImplemented', method)

    def own(self, profile, params):
        team, team_num = params.get('team'), params.get('team_num', 0)
        if type(team_num) not in (int,float) or not math.isfinite(team_num) or int(team_num)!=team_num or not 0 <= team_num <= 2:
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
                fail('InvalidFormation', '阵容包含重复、未拥有或不在当前队伍中的英雄。')
            if type(row[1]) not in (int,float) or not math.isfinite(row[1]) or int(row[1]) != row[1] or not 0 <= row[1] < self.lanes:
                fail('InvalidFormation', '阵容路线不正确。')
            if type(row[2]) not in (int,float) or not math.isfinite(row[2]) or not 0 <= row[2] <= 1:
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

    def export(self, uid, params):
        def change(profile):
            units = self.own(profile, params)
            members = []
            for unit in units:
                frozen = {key: copy.deepcopy(value) for key,value in unit.items() if key in UNIT_KEYS}
                frozen.update(buffs={}, hp=frozen['hp_max'], isme=True)
                members.append(frozen)
            author = str(profile.get('name') or '玩家')[:30]
            name = params.get('name') or author+'的阵容'
            payload = dict(v=1, rules=self.rules, name=name, author=author,
                           level=int(profile.get('lv',1)), members=members,power=self.arena._team_power(members))
            self.validate(payload)
            return {'code': encode_code(payload), 'name': name, 'power': self.arena._team_power(members),
                    'hero_count': len(members)}
        return self.arena._write(uid, 'user.export_formation', params, change)

    def validate(self, payload):
        if set(payload) != {'v','rules','name','author','level','members','power'} or type(payload['v']) is not int or payload['v'] != 1:
            fail('InvalidFormationCode', '不支持此阵容代码版本。')
        if payload['rules'] != self.rules:
            fail('FormationRulesMismatch', '阵容与当前战斗规则不兼容，请使用相同版本导出的代码。已保存的阵容不会被删除。')
        for key in ('name','author'):
            if not isinstance(payload[key],str) or not 1 <= len(payload[key].strip()) <= 40 or any(ord(c)<32 for c in payload[key]):
                fail('InvalidFormationCode', '阵容名称格式不正确。')
        if type(payload['level']) is not int or not 1 <= payload['level'] <= 125:
            fail('InvalidFormationCode', '阵容等级不正确。')
        units = payload['members']
        if not isinstance(units,list) or not 1 <= len(units) <= 5:
            fail('InvalidFormationCode', '阵容英雄数量不正确。')
        for index,unit in enumerate(units):
            if not isinstance(unit,dict) or set(unit)-UNIT_KEYS or not set(('aid','hp','hp_max','ap','de_ph','de_ma','lv','slv','line','pos','leader','tpl','new_4attrs')).issubset(unit):
                fail('InvalidFormationCode', '英雄战斗属性不完整。')
            if not isinstance(unit['aid'],str) or unit['aid'] not in self.cfg['avatar']:
                fail('FormationHeroUnavailable', '阵容中的英雄或英雄包在当前版本不可用。')
            for key,low,high in (('lv',1,125),('slv',1,10),('line',0,self.lanes-1),('leader',0,1),('phase',0,3)):
                value=unit.get(key,0)
                if type(value) is not int or not low <= value <= high:
                    fail('InvalidFormationCode', '英雄等级、进阶或路线不正确。')
            if unit['leader'] != (1 if index == 0 else 0) or unit.get('buffs') != {} or unit.get('isme') is not True:
                fail('InvalidFormationCode', '阵容队长或初始状态不正确。')
            for key in ('hp','hp_max','ap','de_ph','de_ma','pos'):
                value=unit[key]
                maximum=self.line_size if key=='pos' else 1_000_000_000
                if type(value) not in (int,float) or not math.isfinite(value) or not 0 <= value <= maximum:
                    fail('InvalidFormationCode', '英雄战斗属性超出范围。')
            if unit['hp_max'] <= 0 or unit['hp'] != unit['hp_max']:
                fail('InvalidFormationCode', '导出的英雄必须使用满生命的初始状态。')
            if not isinstance(unit['tpl'],list) or len(unit['tpl']) != 5 or any(type(v) not in (int,float) or not math.isfinite(v) or not 0<=v<=100000 for v in unit['tpl']):
                fail('InvalidFormationCode', '英雄基础参数不正确。')
            attrs=unit['new_4attrs']
            if not isinstance(attrs,dict) or set(attrs) != {'hit','flee','crit','tough'} or any(type(v) not in (int,float) or not math.isfinite(v) or not 0<=v<=1_000_000_000 for v in attrs.values()):
                fail('InvalidFormationCode', '英雄四维属性不正确。')
            if unit.get('talent') is not None and (not isinstance(unit['talent'],str) or unit['talent'] not in self.cfg.get('talent',{})):
                fail('InvalidFormationCode', '英雄天赋不可用。')
            if (type(unit.get('limit_break',0)) is not int or unit.get('limit_break',0) not in (0,1)
                    or (unit['lv']>99 and unit.get('limit_break')!=1)
                    or not isinstance(unit.get('culture_schema',''),str) or len(unit.get('culture_schema',''))>64
                    or type(unit.get('growth_stats_applied',True)) is not bool):
                fail('InvalidFormationCode', '英雄突破或成长参数不正确。')
            for key in ('bonds_104','equipment_bonds_104'):
                rows=unit.get(key,[])
                if not isinstance(rows,list) or len(rows)>64 or any(not isinstance(v,str) or len(v)>128 for v in rows):
                    fail('InvalidFormationCode', '英雄羁绊信息不正确。')
            for key in ('skill','leader_skill','book_skill','skillB'):
                snapshot=unit.get(key)
                if snapshot is None: continue
                if not isinstance(snapshot,dict) or not isinstance(snapshot.get('skid'),str):
                    fail('InvalidFormationCode', '英雄技能信息不正确。')
                rank=snapshot.get('slv', unit['slv'] if key=='skill' else 1)
                if type(rank) is not int or not 1<=rank<=10:
                    fail('InvalidFormationCode', '英雄技能等级不正确。')
                expected=_native_skill_snapshot(self.cfg,snapshot['skid'],rank)
                if expected is None or any(not same_skill_value(snapshot.get(k),expected.get(k)) for k in ('pl','skills','cd')):
                    fail('FormationSkillMismatch', '阵容技能配置不匹配，请重新导出。')
        try: validate_team_lane_coverage(units,self.lanes,'imported formation')
        except ValueError: fail('InvalidFormationCode','阵容没有覆盖全部路线。')
        if type(payload['power']) is not int or payload['power']!=self.arena._team_power(units):
            fail('InvalidFormationCode','阵容战力与战斗属性不一致。')

    def _stored(self, uid, formation_id):
        if not isinstance(formation_id,str) or not re.fullmatch('s[a-f0-9]{32}',formation_id):
            fail('UnknownFormation','该阵容不存在或已经删除。')
        row=self.store.db.execute('SELECT payload FROM formation_library WHERE uid=? AND id=?',(str(uid),formation_id)).fetchone()
        if row is None: fail('UnknownFormation','该阵容不存在或已经删除。')
        return unwire_value(json.loads(row[0]))

    def enemy(self,payload):
        enemy=copy.deepcopy(payload['members'])
        for unit in enemy:unit['isme']=False;unit['pos']=self.line_size-unit['pos']
        return enemy

    def summary(self, formation_id, payload, created, rules=None):
        compatible=payload['rules']==(rules if rules is not None else self.rules) and all(u['aid'] in self.cfg['avatar'] for u in payload['members'])
        compact=self.arena._compact(self.enemy(payload)) if all(u['aid'] in self.cfg['avatar'] for u in payload['members']) else []
        return dict(id=formation_id,formation_id=formation_id,status=0,indexID_s=1000,numberIndex=0,
                    name=payload['name'],author=payload['author'],lv=payload['level'],data_base=compact,
                    is_enemy=-1,mark=0,formation_power=payload['power'],
                    compatible=compatible,created=created)

    def list(self, uid):
        with self.store.lock:
            rows=self.store.db.execute('SELECT id,payload,created FROM formation_library WHERE uid=? ORDER BY created DESC,id',(str(uid),)).fetchall()
            rules=self.rules if rows else None
            return [self.summary(fid,unwire_value(json.loads(raw)),created,rules) for fid,raw,created in rows]

    def import_code(self, uid, params):
        payload=decode_code(params.get('code'))
        self.validate(payload)
        raw=canonical(payload).decode('utf-8')
        formation_id='s'+hashlib.sha256(raw.encode()).hexdigest()[:32]
        def change(profile):
            exists=self.store.db.execute('SELECT created FROM formation_library WHERE uid=? AND id=?',(str(uid),formation_id)).fetchone()
            created=exists[0] if exists else self.store.clock.now()
            self.store.db.execute('INSERT OR IGNORE INTO formation_library(uid,id,payload,created) VALUES(?,?,?,?)',(str(uid),formation_id,raw,created))
            return {'formation':self.summary(formation_id,payload,created),'already_saved':bool(exists)}
        return self.arena._write(uid,'user.import_formation',params,change)

    def delete(self, uid, params):
        formation_id=params.get('formation_id')
        if not isinstance(formation_id,str) or not re.fullmatch('s[a-f0-9]{32}',formation_id):
            fail('UnknownFormation','该阵容不存在或已经删除。')
        def change(profile):
            count=self.store.db.execute('DELETE FROM formation_library WHERE uid=? AND id=?',(str(uid),formation_id)).rowcount
            return {'formation_id':formation_id,'deleted':bool(count)}
        return self.arena._write(uid,'user.delete_formation',params,change)

    def start(self, uid, params):
        def change(profile):
            payload=self._stored(uid,params.get('formation_id'))
            self.validate(payload)
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
            return dict(fight_id=intent['fight_id'],fight_kind='formation',sign=intent['sign'],metadata=intent['metadata'],
                        poke_data=dict(gift_list=[{},{},{}],poke_gift_index=0,user_gift={}))
        return self.arena._write(uid,'user.battle_finish',params,change)
