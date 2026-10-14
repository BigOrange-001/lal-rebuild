"""Persistent local players and original-client resource gift mail RPCs."""
import datetime,hashlib,hmac,json,secrets,time,sqlite3,threading
from vip_campaign import normalize_vip_profile,legacy_first_bonus_from_receipts
from gameplay_energy import normalize_energy_purchase_day
from cultivation_rules import normalize_profile as normalize_culture_profile
from game_clock import GameClock

class GameplayFault(Exception):
 def __init__(self,code,message):self.code,self.message=code,message

def native_dates(value):
 if isinstance(value,dict):
  if set(value)=={'$date'}:return datetime.datetime.fromtimestamp(value['$date'],datetime.timezone.utc).replace(tzinfo=None)
  return {k:native_dates(v) for k,v in value.items()}
 if isinstance(value,list):return [native_dates(v) for v in value]
 return value

# Client-owned durable projection. Optional top-level profile fields
# are copied only when present. Backend-only fight intents and independent
# mail/application counters never cross the state_sync wire boundary.
CLIENT_PROFILE_SYNC_REQUIRED_FIELDS = (
 'uid','name','exploration','cid','hid','lv','exp','gold','coin','score','medal','mark',
 'vip_lv','vip_exp','vip_time','catena','energy','fragment_energy','attrs','records',
 'avatars','my_equips','avatar_soul','equip_soul','team','fragment','pf_info','login_time',
 'create_time','add_time','friends','combat_main','combat_score','ploy_cids','tasks',
 'association','check_in','title','zone',
)
CLIENT_PROFILE_SYNC_OPTIONAL_FIELDS = ('as_equips','pending_pve','pending_limit_break','task','boss_state')

class PlayerStore:
 def __init__(self,db,config,clock=None):
  self.db,self.config=db,config
  self.clock=clock if clock is not None else GameClock(db)
  db.executescript('''CREATE TABLE IF NOT EXISTS players(uid TEXT PRIMARY KEY,account TEXT UNIQUE NOT NULL,profile TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS sessions(token TEXT PRIMARY KEY,uid TEXT NOT NULL,expires INTEGER NOT NULL);
CREATE TABLE IF NOT EXISTS operation_ledger(uid TEXT NOT NULL,operation_key TEXT NOT NULL,payload_hash TEXT NOT NULL,result TEXT NOT NULL,created INTEGER NOT NULL,PRIMARY KEY(uid,operation_key));
CREATE TABLE IF NOT EXISTS gift_mail(id INTEGER PRIMARY KEY AUTOINCREMENT,uid TEXT NOT NULL,title TEXT NOT NULL,gifts TEXT NOT NULL,created INTEGER NOT NULL,claimed INTEGER NOT NULL DEFAULT 0,request_key TEXT UNIQUE NOT NULL,read_at INTEGER NOT NULL DEFAULT 0,allow_skin INTEGER NOT NULL DEFAULT 0);
CREATE TABLE IF NOT EXISTS player_state_revision(uid TEXT PRIMARY KEY,revision INTEGER NOT NULL CHECK(revision>=0));
INSERT OR IGNORE INTO player_state_revision(uid,revision) SELECT uid,0 FROM players;''')
  self.lock=threading.RLock()
  from gameplay_economy import GameplayEconomy
  self.economy=GameplayEconomy(self,config or {})
  self.gameplay_handlers=[]
  import importlib.util
  for module_name,class_name in [('gameplay_combat','GameplayCombat'),('gameplay_roster','GameplayRosterEquipment'),('gameplay_competition','GameplayCompetition'),('gameplay_guild_boss','GameplayGuildBoss'),('gameplay_social','GameplaySocial')]:
   if importlib.util.find_spec(module_name) is None: continue
   module=__import__(module_name)
   cls=getattr(module,class_name)
   self.gameplay_handlers.append(cls(self,config or {}))
  if 'read_at' not in {row[1] for row in db.execute('PRAGMA table_info(gift_mail)')}:
   db.execute('ALTER TABLE gift_mail ADD COLUMN read_at INTEGER NOT NULL DEFAULT 0');db.commit()
  if 'allow_skin' not in {row[1] for row in db.execute('PRAGMA table_info(gift_mail)')}:
   db.execute('ALTER TABLE gift_mail ADD COLUMN allow_skin INTEGER NOT NULL DEFAULT 0')
   # Older administration tools could attach heroes to mail.
   # Preserve that path for old unclaimed mail containing
   # one of the exact restricted IDs. New send_mail calls require the explicit
   # trusted allow_skin flag and ordinary sends reject these IDs.
   cfg=self.config.get('cfg',self.config) if isinstance(self.config,dict) else {}
   simple=cfg.get('system_simple',{}) if isinstance(cfg,dict) else {}
   blocked=simple.get('skin_acquisition_blocked_heroes',[]) if isinstance(simple,dict) else []
   blocked=set(blocked) if isinstance(blocked,list) and all(isinstance(aid,str) for aid in blocked) else set()
   if blocked:
    for mail_id,payload in db.execute('SELECT id,gifts FROM gift_mail WHERE claimed=0').fetchall():
     try: avatar_gifts=json.loads(payload).get('avatar',{})
     except (TypeError,ValueError,AttributeError): continue
     if isinstance(avatar_gifts,dict) and blocked.intersection(avatar_gifts):
      db.execute('UPDATE gift_mail SET allow_skin=1 WHERE id=?',(mail_id,))
   db.commit()
 def _default_lottery_state(self):
  cfg=self.config.get('cfg',self.config) if isinstance(self.config,dict) else {}
  extract=((cfg.get('ploy_system_simple') or {}).get('extract_avatar') or {}) if isinstance(cfg,dict) else {}
  start=extract.get('start_time')
  if isinstance(start,dict) and type(start.get('$date')) is int: start={'$date':start['$date']}
  elif type(start) is int: start={'$date':start}
  else: start={'$date':self.clock.now()}
  return {'score':0,'last_time':None,'start_time':start}
 def _default_roulette_state(self):
  cfg=self.config.get('cfg',self.config) if isinstance(self.config,dict) else {}
  simple=cfg.get('ploy_system_simple',{}) if isinstance(cfg,dict) else {}
  roulette=simple.get('roulette',{}) if isinstance(simple,dict) else {}
  fixed=roulette.get('fixed_gift',{}) if isinstance(roulette,dict) else {}
  draws={str(key):0 for key in fixed} if isinstance(fixed,dict) else {}
  return {'fixed_count':0,'last_time':None,'fixed_draw':draws}
 def _normalize_roulette_state(self,value):
  defaults=self._default_roulette_state()
  source=value if isinstance(value,dict) else {}
  count=source.get('fixed_count',0)
  if type(count) is not int or count<0:count=0
  cfg=self.config.get('cfg',self.config) if isinstance(self.config,dict) else {}
  roulette=((cfg.get('ploy_system_simple') or {}).get('roulette') or {}) if isinstance(cfg,dict) else {}
  fixed=roulette.get('fixed_gift',{}) if isinstance(roulette,dict) else {}
  try:tiers=sorted(int(key) for key in fixed)
  except (TypeError,ValueError):tiers=[]
  cycle=tiers[-1] if tiers else 0
  raw=source.get('fixed_draw')
  has_native_counters=isinstance(raw,dict)
  raw=raw if has_native_counters else {}
  draws={}
  legacy_pending_tier=None
  for tier in tiers:
   key=str(tier); available=count//cycle+int(count%cycle>=tier) if cycle else 0
   current=raw.get(key)
   # Missing legacy counters cannot safely imply unclaimed rewards: mark prior
   # entitlements as consumed to avoid reissuing historical milestones.
   if type(current) is not int or current<0:
    current=available
   draws[key]=current
  pending=source.get('pending')
  if not has_native_counters and isinstance(pending,dict):
   try:tier=int(pending.get('level'))
   except (TypeError,ValueError):tier=0
   key=str(tier)
   if tier in tiers:
    legacy_pending_tier=key
    if draws.get(key,0)>0:
     # Old server kept one fixed reward pending until claimed. Reserve that
     # entitlement; if issued early, count it against the next cycle.
     draws[key]-=1
  last=source.get('last_time')
  valid_last=(last is None or isinstance(last,datetime.datetime) or
              (isinstance(last,dict) and type(last.get('$date')) in (int,float)) or
              (type(last) in (int,float)))
  if not valid_last:last=None
  normalized={**source,'fixed_count':count,'last_time':last,'fixed_draw':draws}
  normalized.pop('pending',None)
  if legacy_pending_tier is not None:normalized['legacy_pending_tier']=legacy_pending_tier
  return normalized
 def _default_avatar_capacity(self,owned_count=0):
  cfg=self.config.get('cfg',{}) if isinstance(self.config,dict) else {}
  simple=cfg.get('system_simple',{}) if isinstance(cfg,dict) else {}
  row=simple.get('avatar_len',[0,20,100,1000,1]) if isinstance(simple,dict) else [0,20,100,1000,1]
  configured=int(row[3]) if isinstance(row,(list,tuple)) and len(row)>3 and type(row[3]) is int else 1000
  return max(1000,configured,int(owned_count or 0))
 def _talent_color_count(self):
  cfg=self.config.get('cfg',self.config) if isinstance(self.config,dict) else {}
  simple=cfg.get('system_simple',{}) if isinstance(cfg,dict) else {}
  table=simple.get('talent_config') if isinstance(simple,dict) else None
  return max(4,len(table)) if isinstance(table,(list,tuple)) else 4
 def initial_profile(self,uid,account):
  now=self.clock.now();available=self.config.get('cfg',{}).get('avatar',{}) if self.config else {}
  simple=self.config.get('cfg',{}).get('system_simple',{}) if isinstance(self.config,dict) else {}
  blocked_skin=set(simple.get('skin_acquisition_blocked_heroes',[])) if isinstance(simple,dict) and isinstance(simple.get('skin_acquisition_blocked_heroes',[]),list) else set()
  start_gifts=self.config.get('cfg',{}).get('everyday_gifts',{}).get('start_lv',{}) if self.config else {}
  starter_culture_book=start_gifts.get('culture_book',0) if isinstance(start_gifts,dict) else 0
  if type(starter_culture_book) is not int or starter_culture_book<0:starter_culture_book=0
  roster=[a for a in available if a.startswith('A_1') and a.endswith('_3') and a not in blocked_skin][:5]
  if not roster:roster=[a for a in available if a not in blocked_skin][:5]
  avatars={a+'|'+str(i):{'id':a+'|'+str(i),'aid':a+'|'+str(i),'lv':1,'slv':1,'exp':0,'hp':0,'ap':0,'de_ph':0,'de_ma':0,'phase':0,'morph':0,'love_exp':0,'equips':[]} for i,a in enumerate(roster)}
  attrs={'avatar_len':self._default_avatar_capacity(len(avatars)),'friend_len':30,'login_total':0,'pay_money':0,'pay_total':0,'pay_count':0,'pay_first':0,'pay_first_gift':0,'spend_total':0,'spend_rank':{'fixed_gift':[]},'check_in':{'m':time.gmtime(now+8*3600).tm_mon,'n':0,'had_check':[0,0],'day':0,'count':0,'month_key':time.strftime('%Y-%m',time.gmtime(now+8*3600))},'sign_in':{'k':1,'n':0,'t':None},'team_num':0,'gamble_index':0,'roulette':self._default_roulette_state(),'fund':{'key':'1','money':10,'last_time':None},'fund_add_time':{'$date':now},'energy_extra':0,'fragment_energy_extra':0,'fragment_energy':{'$date':now-12*1800},'guild_contribute':0,'association_id':'','dust':[0,0,0,0],'dn_stone':0,'box_key':0,'culture_book':starter_culture_book,'sp':[0]*self._talent_color_count(),'pvp_rank':99999,'pvp_count':0,'rank_lv':[],'dn':{},'morph':{'chance':0},'lottery_activity':self._default_lottery_state(),'vip_time':{'$date':0},'expedition':{},'culture':{},'guild_id':'','gift':{},'wager':{},'wager_coin_1_count':0,'love':{}}
  records={'guide':{},'current_rank':99999,'energy_times':0,'check_in':{},'pvp':{},'login':{},'combat':{},'battle':{},'gift':{},'task':{},'expedition':{},'pay':{},'ploy':{},'help_suids':{},'help_fuids':{},'exploration_times':{'day':time.strftime('%Y-%m-%d',time.gmtime(now+8*3600)),'refresh_count':3,'refresh_buy':0,'relive_buy':0,'mode_buy':0,'vip_relive':1}}
  exploration={'stage':1,'stage_mode':['ap','all',1.05,1],'current_stage_finish':0,'army':{},'combat_army':[]}
  attrs['time_pay']={'money':0,'time_key':None}
  attrs['time_pay_loop']={'money':0,'lifetime_money':0,'claimed':0}
  return {'uid':uid,'name':'测试玩家','exploration':exploration,'cid':'M_001_1','hid':'M_001_1','lv':1,'exp':0,'gold':1000,'coin':100,'score':0,'medal':0,'mark':0,'vip_lv':0,'vip_exp':0,'vip_time':{'$date':0},'catena':0,'energy':{'$date':now-100*300},'fragment_energy':{'$date':now-12*1800},'attrs':attrs,'records':records,'avatars':avatars,'my_equips':{},'avatar_soul':{},'equip_soul':{},'team':[list(avatars)+[None]*(6-len(avatars)) for _ in range(3)],'fragment':{'equips':{}},'msg_num':0,'apply_num':0,'pf_info':{'id':account,'pf':'local'},'login_time':{'$date':now},'create_time':{'$date':now},'add_time':{'$date':now},'friends':{},'combat_main':{},'combat_score':{'normal':{},'hard':{},'ploy':{}},'ploy_cids':{},'tasks':{},'association':{},'check_in':{},'title':'','zone':'1-01'}
 def login(self,account):
  row=self.db.execute('SELECT uid,profile FROM players WHERE account=?',(account,)).fetchone()
  if row:uid,raw=row;profile=json.loads(raw)
  else:
   uid=str(secrets.randbelow(89999999)+10000000);profile=self.initial_profile(uid,account)
   self.db.execute('INSERT INTO players VALUES(?,?,?)',(uid,account,json.dumps(profile,ensure_ascii=False)))
   self.db.execute('INSERT OR IGNORE INTO player_state_revision(uid,revision) VALUES(?,0)',(uid,))
  token=secrets.token_urlsafe(32)
  self.db.execute('INSERT INTO sessions VALUES(?,?,?)',(token,uid,int(time.time())+86400*30));self.db.commit()
  def track_login(p):
   normalize_energy_purchase_day(p,self.clock.now())
   receipts=[r[0] for r in self.db.execute("SELECT result FROM operation_ledger WHERE uid=? AND operation_key LIKE 'user.local_pay_test:%' ORDER BY created,operation_key",(str(uid),))]
   normalize_vip_profile(p,legacy_first_bonus_from_receipts(receipts))
   attrs=p.setdefault('attrs',{});attrs['login_total']=int(attrs.get('login_total',0))+1
   attrs.setdefault('sign_in',{'k':1,'n':0,'t':None})
   p['login_time']={'$date':self.clock.now()}
   # Keep profile migrations in this transaction so a client never receives
   # new curve metadata with legacy hero XP (or vice versa). Handlers that do
   # not have an active migration leave the profile untouched.
   for handler in self.gameplay_handlers:
    migrate=getattr(handler,'migrate_profile_for_login',None)
    if callable(migrate):
     migrate(p)
     break
   return p,{}
  self.atomic_update(uid,track_login)
  # Claim active monthly-card accrual on login through the same atomic
  # per-local-day markers used by the native user.get_coin callback.
  self.economy.get_coin(uid,{})
  # Settle the previous day's local NPC arena result once on login. The
  # competition handler owns participation/rank capture and the durable
  # idempotent mail marker; this explicit hook avoids profile-read side effects.
  from gameplay_common import game_day
  for handler in self.gameplay_handlers:
   settle=getattr(handler,'settle_daily_rank',None)
   if callable(settle):
    settle(uid,game_day(self.clock.now()))
    break
  profile=self.profile(uid);profile['sessionid']=token
  return profile
 def authenticate(self,request):
  row=self.db.execute('SELECT uid FROM sessions WHERE token=? AND expires>?',(request.get('sessionid',''),int(time.time()))).fetchone()
  if not row or str(request.get('uid',''))!=row[0]:raise GameplayFault('InvalidSession','Login required')
  return row[0]
 def _bump_revision(self,uid):
  uid=str(uid)
  self.db.execute('INSERT OR IGNORE INTO player_state_revision(uid,revision) VALUES(?,0)',(uid,))
  self.db.execute('UPDATE player_state_revision SET revision=revision+1 WHERE uid=?',(uid,))
 def state_revision(self,uid):
  uid=str(uid)
  row=self.db.execute('SELECT revision FROM player_state_revision WHERE uid=?',(uid,)).fetchone()
  if row:return int(row[0])
  if self.db.execute('SELECT 1 FROM players WHERE uid=?',(uid,)).fetchone():
   self.db.execute('INSERT OR IGNORE INTO player_state_revision(uid,revision) VALUES(?,0)',(uid,));self.db.commit()
   return 0
  raise GameplayFault('UnknownPlayer','Player does not exist')
 def state_snapshot(self,uid):
  """Read a consistent native-date profile and its per-player revision."""
  uid=str(uid)
  with self.lock:
   # Apply any legacy normalization first; its write increments the same UID revision.
   self.profile(uid)
   self.db.execute('BEGIN')
   try:
    row=self.db.execute('SELECT p.profile,r.revision FROM players p JOIN player_state_revision r ON r.uid=p.uid WHERE p.uid=?',(uid,)).fetchone()
    if not row:raise GameplayFault('UnknownPlayer','Player does not exist')
    raw_profile=native_dates(json.loads(row[0]))
    missing=[key for key in CLIENT_PROFILE_SYNC_REQUIRED_FIELDS if key not in raw_profile]
    if missing:raise GameplayFault('InvalidProfileSyncProjection','Missing required client profile fields: '+','.join(missing))
    profile={key:raw_profile[key] for key in CLIENT_PROFILE_SYNC_REQUIRED_FIELDS}
    profile.update({key:raw_profile[key] for key in CLIENT_PROFILE_SYNC_OPTIONAL_FIELDS if key in raw_profile})
    # This is intentionally a client-owned projection, not a copy of every
    # persisted backend field. msg_num/apply_num are independently derived,
    # pending_battles contains backend intent/replay state, and sessionid is
    # transport authentication state; none belongs in the snapshot.
    result={'uid':uid,'revision':int(row[1]),'profile':profile}
    self.db.commit()
    return result
   except Exception:
    self.db.rollback();raise
 def profile(self,uid):
  profile_row=self.db.execute('SELECT profile FROM players WHERE uid=?',(uid,)).fetchone()
  if not profile_row:raise GameplayFault('UnknownPlayer','Player does not exist')
  p=json.loads(profile_row[0])
  # The native activity-combat progress check indexes ploy_cids by chapter
  # before the first activity request. Preserve valid records on old saves.
  if not isinstance(p.get('ploy_cids'),dict):p['ploy_cids']={}
  fragment=p.get('fragment')
  if not isinstance(fragment,dict):fragment={}
  if not isinstance(fragment.get('equips'),dict):fragment['equips']={}
  p['fragment']=fragment
  # `catena` is the native consecutive-login count consumed by task panels.
  # Preserve valid legacy values; do not infer it from login_total.
  if type(p.get('catena')) is not int or p['catena'] < 0:p['catena']=0
  if not isinstance(p.get('records'),dict):p['records']={}
  p['records'].setdefault('help_suids',{})
  p['records'].setdefault('help_fuids',{})
  attrs=p.setdefault('attrs',{})
  # PanelActivityRoulette indexes these fields before any spin request.
  attrs['roulette']=self._normalize_roulette_state(attrs.get('roulette'))
  # PanelActivitySign indexes sign_in[k] before it sends an RPC. Normalize
  # legacy/invalid cycle keys against the actual configured table at login,
  # while preserving the current count and last-sign timestamp where valid.
  sign_state=attrs.get('sign_in')
  if not isinstance(sign_state,dict):sign_state={}
  config_root=self.config.get('cfg',self.config) if isinstance(self.config,dict) else {}
  sign_levels=((config_root.get('ploy_system_simple') or {}).get('sign_in') or {}) if isinstance(config_root,dict) else {}
  valid_sign_keys=sorted((str(key) for key in sign_levels if str(key).isdigit()),key=int)
  sign_key=str(sign_state.get('k',valid_sign_keys[0] if valid_sign_keys else '1'))
  if sign_key not in sign_levels and sign_key not in {str(key) for key in sign_levels}:
   sign_key=valid_sign_keys[0] if valid_sign_keys else '1'
  sign_row=sign_levels.get(sign_key,sign_levels.get(int(sign_key),{})) if isinstance(sign_levels,dict) else {}
  sign_max=sign_row.get('num',4) if isinstance(sign_row,dict) else 4
  if type(sign_max) is not int or sign_max<1:sign_max=4
  sign_count=sign_state.get('n',0)
  if type(sign_count) is not int:sign_count=0
  sign_state['k']=int(sign_key) if sign_key.isdigit() else 1
  sign_state['n']=min(sign_max,max(0,sign_count))
  sign_state.setdefault('t',None)
  attrs['sign_in']=sign_state
  # Native task panels read these progress records before any purchase occurs.
  # Keep valid accumulated progress and its campaign start marker across login.
  time_pay=attrs.get('time_pay')
  if not isinstance(time_pay,dict):time_pay={}
  money=time_pay.get('money',0)
  if type(money) is not int or money<0:money=0
  time_key=time_pay.get('time_key')
  if isinstance(time_key,(int,float)) and not isinstance(time_key,bool):time_key={'$date':int(time_key)}
  if not (isinstance(time_key,dict) and type(time_key.get('$date')) in (int,float)) and time_key is not None:time_key=None
  attrs['time_pay']={**time_pay,'money':money,'time_key':time_key}
  time_pay_loop=attrs.get('time_pay_loop')
  if not isinstance(time_pay_loop,dict):time_pay_loop={}
  for field in ('money','lifetime_money','claimed'):
   value=time_pay_loop.get(field,0)
   if type(value) is not int or value<0:value=0
   time_pay_loop[field]=value
  attrs['time_pay_loop']=time_pay_loop
  # Earlier local builds serialized the talent preview as a map in the field
  # the Flash client parses as `hero-id`talent-id. Preserve its spent-point
  # receipt, migrate the client-facing value to a string, and leave an already
  # structured pending choice untouched.
  legacy_talent=attrs.get('avatar_talent')
  if isinstance(legacy_talent,dict):
   aid,talent_id=legacy_talent.get('aid'),legacy_talent.get('id')
   if isinstance(aid,str) and aid and isinstance(talent_id,str) and talent_id:
    attrs.setdefault('pending_talent',dict(legacy_talent))
    if not isinstance(attrs.get('pending_talent'),dict):attrs['pending_talent']=dict(legacy_talent)
    attrs['avatar_talent']=aid+'`'+talent_id
   else:
    attrs.pop('avatar_talent',None)
  elif legacy_talent is not None and not isinstance(legacy_talent,str):
   attrs.pop('avatar_talent',None)
  elif isinstance(legacy_talent,str) and not isinstance(attrs.get('pending_talent'),dict):
   # Old strings do not contain the spent-point receipt needed to safely
   # complete/cancel the server transaction; do not expose them as a map.
   attrs.pop('avatar_talent',None)
  vip_time=p.get('vip_time')
  if not (isinstance(vip_time,datetime.datetime) or (isinstance(vip_time,dict) and type(vip_time.get('$date')) in (int,float))):
   vip_time=attrs.get('vip_time')
  if isinstance(vip_time,datetime.datetime):
   if vip_time.tzinfo is None:vip_time=vip_time.replace(tzinfo=datetime.timezone.utc)
   vip_time={'$date':int(vip_time.timestamp())}
  elif type(vip_time) in (int,float):vip_time={'$date':int(vip_time)}
  elif not (isinstance(vip_time,dict) and type(vip_time.get('$date')) in (int,float)):vip_time={'$date':0}
  p['vip_time']=vip_time
  if type(attrs.get('wager_coin_1_count')) is not int or attrs['wager_coin_1_count']<0:attrs['wager_coin_1_count']=0
  avatar_culture=attrs.get('avatar_culture')
  if isinstance(avatar_culture,dict):
   if not avatar_culture.get('eqid') and avatar_culture.get('aid'):avatar_culture['eqid']=avatar_culture['aid']
   if not isinstance(avatar_culture.get('save_status'),dict):
    rolled=avatar_culture.get('rolled')
    avatar_culture['save_status']=dict(rolled) if isinstance(rolled,dict) else {}
  activity=attrs.get('lottery_activity')
  if not isinstance(activity,dict):
   activity=self._default_lottery_state();attrs['lottery_activity']=activity
  else:
   activity.setdefault('score',0);activity.setdefault('last_time',None)
   if not isinstance(activity.get('start_time'),(dict,int)):
    activity['start_time']=self._default_lottery_state()['start_time']
  if not isinstance(p.get('exploration'),dict):p['exploration']={}
  for key,value in {'stage':1,'stage_mode':['ap','all',1.05,1],'current_stage_finish':0,'army':{},'combat_army':[]}.items():
   p['exploration'].setdefault(key,value)
  times=p['records'].get('exploration_times')
  if not isinstance(times,dict):times={}
  today=time.strftime('%Y-%m-%d',time.gmtime(self.clock.now()+8*3600))
  if times.get('day')!=today:
   times.update({'day':today,'refresh_count':3,'refresh_buy':0,'relive_buy':0,'mode_buy':0,'vip_relive':1})
  else:
   for key,value in {'refresh_count':3,'refresh_buy':0,'relive_buy':0,'mode_buy':0,'vip_relive':1}.items():times.setdefault(key,value)
  p['records']['exploration_times']=times
  if not isinstance(p.get('avatars'),dict):p['avatars']={}
  if not isinstance(p.get('my_equips'),dict):p['my_equips']={}
  if not isinstance(p.get('attrs'),dict):p['attrs']={}
  team=p.get('team')
  if not isinstance(team,list):team=[]
  while len(team)<3:team.append([None]*6)
  for row_index,row in enumerate(team[:3]):
   if not isinstance(row,list):row=[None]*6;team[row_index]=row
   if len(row)<6:row.extend([None]*(6-len(row)))
   for slot,value in enumerate(row[:6]):
    if value=='':row[slot]=None
  p['team']=team
  # Raise legacy capacity to the supported baseline without dropping heroes or
  # reducing any previously earned capacity.
  old_capacity=p['attrs'].get('avatar_len',0)
  if type(old_capacity) is not int or old_capacity<0:old_capacity=0
  p['attrs']['avatar_len']=max(self._default_avatar_capacity(len(p['avatars'])),old_capacity,len(p['avatars']))
  legacy={k for k in p['avatars'] if k.isdigit()}
  if legacy:
   mapping={k:v['aid']+'|'+str(int(k)-1) for k,v in p['avatars'].items() if k in legacy}
   p['avatars']={mapping.get(k,k):{**v,'id':mapping.get(k,k),'aid':mapping.get(k,v['aid'])} for k,v in p['avatars'].items()}
   p['team']=[[mapping.get(a,a) for a in team] for team in p['team']]
  cfg=self.config.get('cfg',self.config) if isinstance(self.config,dict) else {}
  normalize_culture_profile(p,cfg)
  for k in ['wager_free_score','wager_free_coin']:p['attrs'].setdefault(k,{'$date':self.clock.now()})
  p['records'].setdefault('free_wager_count',0)
  p.setdefault('as_equips',[[] for _ in range(6)])
  p.setdefault('cid','M_001_1');p.setdefault('hid','M_001_1')
  p.setdefault('add_time',p.get('create_time',{'$date':self.clock.now()}))
  p['attrs'].setdefault('gamble_index',0)
  if type(p['attrs'].get('wager_coin_1_count')) is not int or p['attrs']['wager_coin_1_count']<0:p['attrs']['wager_coin_1_count']=0
  p['attrs'].setdefault('fund',{'key':'1','money':10,'last_time':None})
  p['attrs'].setdefault('fund_add_time',p.get('add_time',{'$date':self.clock.now()}))
  p.setdefault('combat_score',{'normal':{},'hard':{},'ploy':{}})
  if not isinstance(p['combat_score'],dict):p['combat_score']={'normal':{},'hard':{},'ploy':{}}
  for difficulty in ('normal','hard','ploy'):p['combat_score'].setdefault(difficulty,{})
  p.setdefault('task',{})
  p['records'].setdefault('everyday_gift',[])
  normalize_energy_purchase_day(p,self.clock.now())
  p['attrs'].setdefault('login_total',0)
  p['attrs'].setdefault('pay_money',0)
  p['attrs'].setdefault('pay_total',0)
  p['attrs'].setdefault('pay_count',0)
  p['attrs'].setdefault('pay_first',0)
  p['attrs'].setdefault('pay_first_gift',0)
  receipts=[r[0] for r in self.db.execute("SELECT result FROM operation_ledger WHERE uid=? AND operation_key LIKE 'user.local_pay_test:%' ORDER BY created,operation_key",(str(uid),))]
  normalize_vip_profile(p,legacy_first_bonus_from_receipts(receipts))
  p['attrs'].setdefault('rank_lv',[])
  p['attrs'].setdefault('mon_card',{})
  p['attrs'].setdefault('mon_card_claim_day',{})
  p['attrs'].setdefault('vip_gift_buy',[])
  p['attrs'].setdefault('vip_gift_buy2',[])
  p['attrs'].setdefault('association_id','')
  p['attrs']['box_key']=self._normalize_box_key_state(p['attrs'].get('box_key'))
  p['records'].setdefault('box_record',[])
  p['records'].setdefault('welfare_times',[0,0,0,0])
  p['attrs'].setdefault('sign_in',{'k':1,'n':0,'t':None})
  p['attrs']['check_in']=self._refresh_check_in_for_login(self._normalize_check_in_state(p['attrs'].get('check_in')),self._check_in_today())
  p['records'].setdefault('vip_gift',[])
  p['attrs'].setdefault('pay_gift',0)
  p['attrs'].setdefault('spend_total',0)
  p['attrs'].setdefault('spend_rank',{'fixed_gift':[]})
  p['attrs'].setdefault('comment_gift',False)
  if not isinstance(p['attrs'].get('dust'),list):p['attrs']['dust']=[p['attrs'].get('dust',0),0,0,0]
  sp=p['attrs'].get('sp')
  if not isinstance(sp,list):sp=[sp if type(sp) is int and sp>=0 else 0]
  color_count=self._talent_color_count()
  if len(sp)<color_count:sp.extend([0]*(color_count-len(sp)))
  p['attrs']['sp']=sp
  self._normalize_equipment_attrs(p.get('my_equips'))
  normalized=json.dumps(self._profile_json(p),ensure_ascii=False,separators=(',',':'))
  if normalized!=profile_row[0]:
   with self.lock:
    self.db.execute('BEGIN IMMEDIATE')
    try:
     latest=self.db.execute('SELECT profile FROM players WHERE uid=?',(uid,)).fetchone()
     if not latest:raise GameplayFault('UnknownPlayer','Player does not exist')
     if latest[0]!=profile_row[0]:
      self.db.rollback()
      return self.profile(uid)
     self.db.execute('UPDATE players SET profile=? WHERE uid=?',(normalized,uid))
     self._bump_revision(uid)
     self.db.commit()
    except Exception:
     self.db.rollback();raise
  p['msg_num']=self.db.execute('SELECT COUNT(*) FROM gift_mail WHERE uid=? AND claimed=0',(uid,)).fetchone()[0]
  return native_dates(p)
 @staticmethod
 def _normalize_equipment_attrs(equips):
  """Migrate legacy flat equipment stats to the native nested schema."""
  if not isinstance(equips,dict):return
  for item in equips.values():
   if not isinstance(item,dict):continue
   nested=item.get('new_4attrs')
   source=nested if isinstance(nested,dict) else item
   values={}
   for key in ('hit','flee','crit','tough'):
    try:values[key]=int(source.get(key,0) or 0)
    except (TypeError,ValueError,OverflowError):values[key]=0
   item['new_4attrs']=values
   for key in ('hit','flee','crit','tough'):item.pop(key,None)
   # Equip.init reads halo.lv/halo.exp. Legacy profiles stored those values
   # only as haloLv/haloExp; prefer valid native fields when both exist, then
   # synchronize flat aliases for server helpers which still consume them.
   halo=item.get('halo')
   if isinstance(halo,dict):
    lv=halo.get('lv',0);exp=halo.get('exp',0)
   else:
    lv=item.get('haloLv',0);exp=item.get('haloExp',0)
   if type(lv) is not int or lv<0:lv=0
   if type(exp) is not int or exp<0:exp=0
   item['halo']={'lv':lv,'exp':exp}
   item['haloLv']=lv;item['haloExp']=exp
   rune_level=item.get('rune_lv',0)
   item['rune_lv']=rune_level if type(rune_level) is int and 0<=rune_level<=10 else 0
   item['magic_stage5']=1 if item.get('magic_stage5')==1 else 0
 def _normalize_check_in_state(self,value):
  """Migrate legacy sign-in state to the fields directly indexed by the client UI."""
  state=dict(value) if isinstance(value,dict) else {}
  m=state.get('m',1)
  if type(m) is not int or m<1:m=1
  if m>12:m=12
  count=state.get('count',0)
  if type(count) is not int or count<0:count=0
  day=state.get('day',0)
  if type(day) is not int or day<0:day=0
  month_key=state.get('month_key')
  last_day=state.get('last_day')
  if not month_key and isinstance(last_day,str) and len(last_day)>=10 and last_day[4:5]=='-' and last_day[7:8]=='-':
   try:
    m=int(last_day[5:7]);month_key=last_day[:7]
   except ValueError:pass
  cycle=(self.config.get('cfg',{}).get('check_in',{}).get(str(m)) or self.config.get('cfg',{}).get('check_in',{}).get(m) or []) if isinstance(self.config,dict) else []
  cycle_len=len(cycle) if isinstance(cycle,list) and cycle else 31
  had=state.get('had_check',[0,0])
  if not isinstance(had,(list,tuple)):had=[]
  had=[1 if entry in (1,True) else 0 for entry in had[:2]]
  while len(had)<2:had.append(0)
  n=state.get('n')
  if type(n) is not int or n<0:n=day if day>0 else 0
  # `day` is this month's regular-claim index; `count` is a lifetime total and
  # must not be used to reconstruct the calendar row. When a regular claim has
  # an outstanding VIP second-half claim, the native UI keeps that same row
  # active until the bonus is claimed, so n must remain day - 1.
  if day>0:
   day=min(day,cycle_len)
   reward_index=min(day-1,max(0,len(cycle)-1)) if isinstance(cycle,list) and cycle else -1
   reward_row=cycle[reward_index] if reward_index>=0 else None
   vip_need=reward_row.get('vip_double',0) if isinstance(reward_row,dict) else 0
   pending_vip=bool(had[0] and not had[1] and type(vip_need) is int and vip_need>0)
   n=max(0,day-1) if pending_vip else day
  else:
   n=min(n,cycle_len)
  # Some migrated profiles have a completed prior-day claim but both monthly
  # indices were reset to zero. last_day + had_check proves at least one day of
  # this month was claimed; preserve that progress instead of showing row 1 again.
  if day==0 and n==0 and had[0] and isinstance(last_day,str) and month_key==last_day[:7]:
   day=n=1
  state.update(m=m,n=n,count=count,day=day,had_check=had)
  if month_key:state['month_key']=month_key
  return state
 def _check_in_today(self):
  tz=datetime.timezone(datetime.timedelta(hours=8))
  return datetime.datetime.fromtimestamp(self.clock.now(),tz).date().isoformat()
 @staticmethod
 def _check_in_date(value):
  if isinstance(value,str):
   try:return datetime.date.fromisoformat(value[:10])
   except ValueError:return None
  if isinstance(value,dict) and set(value)=={'$date'}:value=value['$date']
  if isinstance(value,(int,float)):
   try:value=datetime.datetime.fromtimestamp(value,datetime.timezone.utc)
   except (OverflowError,OSError,ValueError):return None
  if isinstance(value,datetime.datetime):
   if value.tzinfo is None:value=value.replace(tzinfo=datetime.timezone.utc)
   return value.astimezone(datetime.timezone(datetime.timedelta(hours=8))).date()
  return None
 def _refresh_check_in_for_login(self,state,today):
  """Advance client-visible sign-in state across date/month boundaries once."""
  try:today_date=datetime.date.fromisoformat(today)
  except (TypeError,ValueError):return state
  month_key=today_date.strftime('%Y-%m')
  month=today_date.month
  cycle=(self.config.get('cfg',{}).get('check_in',{}).get(str(month)) or self.config.get('cfg',{}).get('check_in',{}).get(month) or []) if isinstance(self.config,dict) else []
  cycle_len=len(cycle) if isinstance(cycle,list) and cycle else 31
  previous=self._check_in_date(state.get('last_day'))
  if state.get('month_key')!=month_key:
   # Monthly progress is the next calendar row; `count` remains lifetime.
   state.update(m=month,month_key=month_key,day=0,n=0,had_check=[0,0])
   return state
  state['m']=month
  if previous is not None and previous<today_date:
   was_claimed=bool(state.get('had_check',[0,0])[0])
   state['had_check']=[0,0]
   if was_claimed and int(state.get('day',0))==0 and int(state.get('n',0))==0:
    # Repair legacy rows where yesterday's successful claim was persisted only
    # in had_check/last_day while day and n were left at their initial values.
    state['day']=state['n']=min(1,cycle_len)
   elif int(state.get('day',0))>0:
    state['day']=min(int(state['day']),cycle_len)
    state['n']=state['day']
  return state
 def profile_raw(self,uid):
  """Return a detached persisted-format profile; dates remain {$date: epoch_seconds}."""
  row=self.db.execute('SELECT profile FROM players WHERE uid=?',(str(uid),)).fetchone()
  if not row:raise GameplayFault('UnknownPlayer','Player does not exist')
  return json.loads(row[0])
 @staticmethod
 def _profile_json(value):
  if isinstance(value,datetime.datetime):return {'$date':int(value.replace(tzinfo=datetime.timezone.utc).timestamp())}
  if isinstance(value,dict):
   if set(value)=={'$date'}:return {'$date':int(value['$date'])}
   return {str(k):PlayerStore._profile_json(v) for k,v in value.items()}
  if isinstance(value,(list,tuple)):return [PlayerStore._profile_json(v) for v in value]
  if value is None or isinstance(value,(str,int,float,bool)):return value
  raise GameplayFault('InvalidProfileValue','Unsupported value in profile update: '+type(value).__name__)
 def atomic_update(self,uid,mutator,idempotency_key=None,request_payload=None):
  """Run one profile mutation and optional replay-safe operation in one SQLite transaction.

  mutator receives a detached JSON-profile and must return (updated_profile, response_dict).
  The callback must be pure with respect to this store and must not perform nested writes.
  """
  uid=str(uid)
  if idempotency_key is not None and (not isinstance(idempotency_key,str) or not 1<=len(idempotency_key)<=240):
   raise GameplayFault('InvalidRequestKey','Operation key must contain 1 to 240 characters')
  payload_hash=hashlib.sha256(json.dumps(request_payload,sort_keys=True,separators=(',',':'),ensure_ascii=False,default=str).encode('utf8')).hexdigest() if idempotency_key is not None else None
  with self.lock:
   self.db.execute('BEGIN IMMEDIATE')
   try:
    if idempotency_key is not None:
     previous=self.db.execute('SELECT payload_hash,result FROM operation_ledger WHERE uid=? AND operation_key=?',(uid,idempotency_key)).fetchone()
     if previous:
      if previous[0]!=payload_hash:raise GameplayFault('RequestKeyConflict','Operation key was reused with a different payload')
      self.db.commit();return native_dates(json.loads(previous[1])),True
    row=self.db.execute('SELECT profile FROM players WHERE uid=?',(uid,)).fetchone()
    if not row:raise GameplayFault('UnknownPlayer','Player does not exist')
    profile=json.loads(row[0]);updated,response=mutator(profile)
    if not isinstance(updated,dict) or not isinstance(response,(dict,list,int,float,str,bool,type(None))):raise GameplayFault('InvalidMutation','Mutator must return a profile object and JSON response value')
    updated_json=json.dumps(self._profile_json(updated),ensure_ascii=False,separators=(',',':'))
    response_json=json.dumps(self._profile_json(response),ensure_ascii=False,separators=(',',':'))
    if updated_json!=row[0]:
     self.db.execute('UPDATE players SET profile=? WHERE uid=?',(updated_json,uid))
     self._bump_revision(uid)
    if idempotency_key is not None:
     self.db.execute('INSERT INTO operation_ledger(uid,operation_key,payload_hash,result,created) VALUES(?,?,?,?,?)',(uid,idempotency_key,payload_hash,response_json,self.clock.now()))
    self.db.commit();return native_dates(json.loads(response_json)),False
   except Exception:self.db.rollback();raise
 @staticmethod
 def _normalize_box_key_state(value):
  # Legacy profiles used a scalar for the key count; current client expects
  # separate box/key records with num and last_time fields.
  scalar_key=value if type(value) is int and value>=0 else 0
  state=value if isinstance(value,dict) else {}
  result={}
  for kind in ('box','key'):
   entry=state.get(kind)
   if isinstance(entry,dict):
    num=entry.get('num',0)
    if type(num) is not int or num<0:num=0
    result[kind]={**entry,'num':num,'last_time':entry.get('last_time')}
   else:
    num=entry if type(entry) is int and entry>=0 else (scalar_key if kind=='key' else 0)
    result[kind]={'num':num,'last_time':None}
  return result
 @classmethod
 def _credit_box_key(cls,attrs,value):
  state=cls._normalize_box_key_state(attrs.get('box_key'))
  if isinstance(value,dict):
   if not value or any(k not in {'box','key'} or type(v) is not int or v<0 for k,v in value.items()):
    raise GameplayFault('InvalidGift','Box/key mail quantity must map box or key to a nonnegative integer')
   for kind,amount in value.items():state[kind]['num']+=amount
  elif type(value) is int and value>=0:
   # A scalar box_key reward is a key, matching the legacy aggregate field.
   state['key']['num']+=value
  else:raise GameplayFault('InvalidGift','Invalid box/key mail quantity')
  attrs['box_key']=state
 def send_mail(self,account,title,gifts,request_key,*,allow_skin=False):
  allowed={'gold','coin','score','medal','mark','dust','dn_stone','box_key','culture_book','sp'}
  if not isinstance(title,str) or not 1<=len(title)<=120:raise GameplayFault('InvalidTitle','Title must be 1 to 120 characters')
  if not isinstance(request_key,str) or not 1<=len(request_key)<=128:raise GameplayFault('InvalidRequestKey','Request key required')
  if type(allow_skin) is not bool:raise GameplayFault('InvalidGift','Skin mail override must be boolean')
  def valid_gift(key,value):
   if key=='box_key':return (isinstance(value,dict) and bool(value) and all(kind in {'box','key'} and type(amount) is int and 1<=amount<=100000000 for kind,amount in value.items())) or (type(value) is int and 1<=value<=100000000)
   if key=='sp':
    if type(value) is int:return 1<=value<=100000000
    if not isinstance(value,list) or not 1<=len(value)<=self._talent_color_count():return False
    return any(type(amount) is int and amount>0 for amount in value) and all(type(amount) is int and 0<=amount<=100000000 for amount in value)
   if key=='equip':
    equipment=(self.config.get('cfg',self.config).get('equip',{}) if isinstance(self.config,dict) else {})
    return isinstance(value,dict) and bool(value) and len(value)<=512 and all(isinstance(eid,str) and eid in equipment and type(amount) is int and 1<=amount<=1000 for eid,amount in value.items())
   if key=='avatar':
    avatars=(self.config.get('cfg',self.config).get('avatar',{}) if isinstance(self.config,dict) else {})
    return isinstance(value,dict) and bool(value) and len(value)<=512 and all(isinstance(aid,str) and aid in avatars and type(amount) is int and 1<=amount<=100 for aid,amount in value.items()) and sum(value.values())<=1000
   return key in allowed and type(value) is int and 1<=value<=100000000
  if not isinstance(gifts,dict) or not gifts or any(not valid_gift(k,v) for k,v in gifts.items()):raise GameplayFault('InvalidGift','Unsupported resource, equipment ID, or invalid quantity')
  if not allow_skin and isinstance(gifts.get('avatar'),dict):
   from gameplay_common import skin_acquisition_blocked_ids
   if set(gifts['avatar']) & skin_acquisition_blocked_ids(self.config):
    raise GameplayFault('SkinAcquisitionRestricted','This hero form is not available through player acquisition')
  row=self.db.execute('SELECT uid FROM players WHERE account=?',(account,)).fetchone()
  if not row:raise GameplayFault('UnknownPlayer','Account has no player yet')
  self.db.execute('BEGIN IMMEDIATE')
  try:
   existing=self.db.execute('SELECT id,uid,title,gifts,allow_skin FROM gift_mail WHERE request_key=?',(request_key,)).fetchone()
   payload=json.dumps(gifts,sort_keys=True)
   if existing:
    if existing[1:]!=(row[0],title,payload,int(allow_skin)):raise GameplayFault('RequestKeyConflict','Request key was used for different mail')
    mail_id=existing[0]
   else:
    mail_id=self.db.execute('INSERT INTO gift_mail(uid,title,gifts,created,request_key,allow_skin) VALUES(?,?,?,?,?,?)',(row[0],title,payload,self.clock.now(),request_key,int(allow_skin))).lastrowid
   self.db.commit();return str(mail_id)
  except Exception:self.db.rollback();raise
 def mails(self,uid):
  rows=self.db.execute('SELECT id,title,gifts,created,claimed FROM gift_mail WHERE uid=? ORDER BY id DESC',(uid,)).fetchall()
  def native_gift_value(key,value):
   if key not in {'dust','sp'}:return value
   size=self._talent_color_count() if key=='sp' else 4
   values=list(value) if isinstance(value,list) else [value]
   return values+[0]*max(0,size-len(values))
  gifts={str(i):{'id':str(i),'info_type':'debug_mail','info_data':{'title':title},'debug_title':title,'gift_dict':{k:native_gift_value(k,v) for k,v in json.loads(payload).items()},'time':datetime.datetime.fromtimestamp(created,datetime.timezone.utc).replace(tzinfo=None),'status':claimed} for i,title,payload,created,claimed in rows}
  # The native PanelCenterPVP message tab reads pvp_msg.pvp and ItemPVPMsg
  # sends its data.cpb_id to user.get_combat_playback. These are real local
  # NPC arena receipts retained by the competition handler, not gift mail.
  pvp=[]
  for handler in self.gameplay_handlers:
   if handler.__class__.__name__=='GameplayCompetition':
    pvp=handler.pvp_message_rows(uid)
    break
  return {'data':[],'gift_msg':gifts,'new_num':sum(1 for r in rows if r[4]==0),'pvp_msg':{'pvp':pvp,'server_pvp':[]}}
 def delete_mail(self,uid,params):
  mail_id=params.get('mnum')
  if mail_id is None: raise GameplayFault('InvalidMail','Mail id is required')
  with self.lock:
   row=self.db.execute('SELECT id FROM gift_mail WHERE id=? AND uid=?',(str(mail_id),str(uid))).fetchone()
   if row is None: raise GameplayFault('UnknownMail','Mail not found for this player')
   self.db.execute('DELETE FROM gift_mail WHERE id=? AND uid=?',(str(mail_id),str(uid)));self.db.commit()
  return {'ok':True,'mnum':str(mail_id)}
 def claim(self,uid,mail_id):
  self.db.execute('BEGIN IMMEDIATE')
  try:
   row=self.db.execute('SELECT gifts,claimed,allow_skin FROM gift_mail WHERE id=? AND uid=?',(str(mail_id),uid)).fetchone()
   if not row:raise GameplayFault('UnknownMail','Mail not found for this player')
   p=json.loads(self.db.execute('SELECT profile FROM players WHERE uid=?',(uid,)).fetchone()[0])
   if not row[1]:
    mail_gifts=json.loads(row[0])
    avatar_rewards=mail_gifts.get('avatar',{})
    if avatar_rewards:
     # Reuse the native hero-grant path: it validates every configured aid,
     # checks aggregate capacity before mutating, and creates aid|instance ids.
     from gameplay_common import grant_reward
     grant_reward(p,{'avatar':avatar_rewards},self.config,allow_skin=bool(row[2]))
    equipment_rewards=mail_gifts.get('equip',{})
    if equipment_rewards:
     available_equipment=(self.config.get('cfg',self.config).get('equip',{}) if isinstance(self.config,dict) else {})
     if not isinstance(equipment_rewards,dict) or any(eid not in available_equipment for eid in equipment_rewards):
      raise GameplayFault('InvalidGift','Mail contains an unknown equipment ID')
     simple=(self.config.get('cfg',self.config).get('system_simple',{}) if isinstance(self.config,dict) else {})
     equip_config=simple.get('equip_config',[100]) if isinstance(simple,dict) else [100]
     capacity=equip_config[0] if isinstance(equip_config,(list,tuple)) and equip_config and type(equip_config[0]) is int else 100
     owned=p.setdefault('my_equips',{})
     if not isinstance(owned,dict):raise GameplayFault('InvalidProfile','Equipment inventory has an invalid shape')
     total=sum(int(v) for v in equipment_rewards.values())
     if len(owned)+total>capacity:
      raise GameplayFault('EquipCapacity','Equipment inventory does not have enough free space to claim this mail')
     next_index=0
     for eid,amount in equipment_rewards.items():
      for _ in range(amount):
       while f'eq{next_index}' in owned:next_index+=1
       owned[f'eq{next_index}']={'eid':eid,'lv':1,'slv':0,'sexp':0,'new_4attrs':{'hit':0,'flee':0,'crit':0,'tough':0},'halo':{'lv':0,'exp':0},'haloLv':0,'haloExp':0,'alchemy':[0,0],'rune_lv':0,'magic_stage5':0}
       next_index+=1
    attrs=p.setdefault('attrs',{})
    for key,value in mail_gifts.items():
     if key in {'equip','avatar'}:continue
     target=p if key in {'gold','coin','score','medal','mark'} else attrs
     if key in {'dust','sp'}:
      size=self._talent_color_count() if key=='sp' else 4
      if not isinstance(target.get(key),list):
       old_value=target.get(key,0)
       target[key]=[old_value if type(old_value) is int and old_value>=0 else 0,0,0,0]
      target[key].extend([0]*max(0,size-len(target[key])))
      amounts=value if isinstance(value,list) else [value]
      if len(amounts)>size:raise GameplayFault('InvalidGift','Talent stone mail exceeds configured colors')
      for index,amount in enumerate(amounts):target[key][index]+=amount
     elif key=='box_key':
      attrs=p.setdefault('attrs',{})
      self._credit_box_key(attrs,value)
     else:target[key]=target.get(key,0)+value
    self.db.execute('UPDATE players SET profile=? WHERE uid=?',(json.dumps(self._profile_json(p),ensure_ascii=False,separators=(',',':')),uid))
    self._bump_revision(uid)
    self.db.execute('UPDATE gift_mail SET claimed=1 WHERE id=? AND uid=?',(str(mail_id),uid))
   self.db.commit()
  except Exception:self.db.rollback();raise
  p=self.profile(uid);a=p['attrs']
  return {**p,**{k:a.get(k,0) for k in ['guild_contribute','dust','dn_stone','box_key','culture_book','sp']},'attr_energy_extra':a['energy_extra']}
 def dispatch(self,request):
  uid=self.authenticate(request);method=request['method'];params=request['params']
  if method=='user.init_user':return self.profile(uid)
  if method=='user.do_guide':
   group=params.get('gid');code=params.get('code')
   if group not in {'A','B'} or type(code) is not int or not -1<=code<=10000:raise GameplayFault('InvalidGuide','Guide group or step is invalid')
   key='user.do_guide:'+str(params.get('actionID','')) if params.get('actionID') else None
   def save_guide(p):
    p.setdefault('records',{}).setdefault('guide',{})[group]=code
    return p,True
   return self.atomic_update(uid,save_guide,key,{'gid':group,'code':code})[0]
  if method=='user.get' and (not params.get('uid') or str(params.get('uid'))==str(uid)):return self.profile(uid)
  if method=='user.get_friends':
   for handler in self.gameplay_handlers:
    if handler.__class__.__name__=='GameplaySocial':return handler.dispatch(uid,method,params)
   return {'friends_list':[],'apply_list':[]}
  if method=='user.get_msg':return self.mails(uid)
  if method=='user.read_msg':
   self.db.execute('UPDATE gift_mail SET read_at=? WHERE uid=? AND claimed=1 AND read_at=0',(self.clock.now(),uid));self.db.commit()
   return {'msg_num':self.profile(uid)['msg_num']}
  if method=='user.get_gift_msg':return self.claim(uid,params.get('gk'))
  if method=='user.del_msg':return self.delete_mail(uid,params)
  if method in self.economy.METHODS:
   return self.economy.dispatch(uid,method,params)
  if method=='user.battle_finish':
   kind=params.get('fight_kind')
   wanted='GameplayCompetition' if kind in {'pvp','fragment'} else 'GameplayCombat'
   for handler in self.gameplay_handlers:
    if handler.__class__.__name__==wanted:return handler.dispatch(uid,method,params)
   raise GameplayFault('NotImplemented','Battle finish handler is not loaded for kind: '+str(kind))
  if method=='user.change_password':
   if params.get('pf')!='local':raise GameplayFault('UnsupportedPlatform','Only local account passwords can be changed')
   account=params.get('session_key');old_password=params.get('sessionid');new_password=params.get('new_sessionid')
   if not all(isinstance(v,str) and 1<=len(v)<=256 for v in (account,old_password,new_password)):
    raise GameplayFault('InvalidCredentials','Account and passwords must be 1 to 256 characters')
   profile=self.profile_raw(uid)
   if account!=profile.get('pf_info',{}).get('id'):raise GameplayFault('InvalidCredentials','Account does not match the authenticated player')
   def update_password(p):
    row=self.db.execute('SELECT salt,password_hash FROM accounts WHERE name=?',(account,)).fetchone()
    if row is None:raise GameplayFault('UnknownAccount','Local account was not found')
    actual=hashlib.pbkdf2_hmac('sha256',old_password.encode(),bytes.fromhex(row[0]),100000).hex()
    if not hmac.compare_digest(actual,row[1]):raise GameplayFault('InvalidCredentials','Current password is incorrect')
    digest=hashlib.pbkdf2_hmac('sha256',new_password.encode(),bytes.fromhex(row[0]),100000).hex()
    self.db.execute('UPDATE accounts SET password_hash=? WHERE name=?',(digest,account))
    return p,{'ok':True}
   self.atomic_update(uid,update_password,'user.change_password:'+str(params.get('actionID','')),{'account':account,'old_password':old_password,'new_password':new_password})
   return dict(params)
  for handler in self.gameplay_handlers:
   try:return handler.dispatch(uid,method,params)
   except GameplayFault as error:
    if error.code!='NotImplemented':raise
  raise GameplayFault('NotImplemented','Method not reconstructed: '+method)

