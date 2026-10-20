"""Local AMF3 compatibility gateway. Missing gameplay data is an explicit fault."""
from __future__ import annotations
import argparse,datetime,hashlib,hmac,json,pathlib,secrets,shlex,sqlite3,sys,threading,time
from http.server import BaseHTTPRequestHandler,ThreadingHTTPServer
from urllib.parse import urlsplit,unquote
ROOT=pathlib.Path(__file__).resolve().parents[1]
PROJECT_VERSION=(ROOT/'VERSION').read_text(encoding='utf-8').strip()
if not PROJECT_VERSION:
 raise RuntimeError('VERSION must contain a project version')
from pyamf import remoting
from player_store import PlayerStore,GameplayFault,native_dates
from game_clock import GameClock,utc_datetime,duration_seconds
from gameplay_common import game_day
from check_in_rewards import apply_check_in_rewards
from equipment_capacity import apply_equipment_capacity
from equipment_upgrade_cost import apply_equipment_upgrade_config
from captain_timing import apply_captain_timing
from upstream_skill_priority import apply_upstream_skill_priority
from summon_panel_103 import apply_summon_panel_config
from battle_status_effects import apply_battle_status_effects
from halo_progression import apply_halo_progression
from hero_skills_103 import apply_hero_skills_103, finalize_hero_skills_103
from talent_stats_103 import apply_talent_stats_103
from hero_balance_103 import apply_hero_balance_103
from dot_rules_103 import apply_dot_rules_103
from tower_rewards_103 import apply_tower_rewards_103
from material_attempts_103 import apply_material_attempts_103
from ancient_trial_103 import apply_ancient_trial_103
from cat_katarina_103 import apply_cat_katarina_103
from polar_ashe_103 import apply_polar_ashe_103
from santa_veigar_103 import apply_santa_veigar_103
from nurse_akali_103 import apply_nurse_akali_103
from hero_accuracy_103 import apply_hero_accuracy_103
from hero_iteration_103 import apply_hero_iteration_103
from gameplay_energy import apply_energy_purchase_103
from recruit_exchange import apply_recruit_exchange_config
from help_pages import render_help,render_notice

class RpcFault(Exception):
 def __init__(self,code,message): self.code,self.message=code,message

# Exact business-code translations for the native client popup. Unknown codes
# retain the originating module message instead of receiving a generic label.
GAMEPLAY_ERROR_MESSAGES_ZH={
 'SkinAcquisitionRestricted':'该皮肤仅能通过指定来源获得对应碎片后合成。',
 'InsufficientCoin':'金砖不足','InsufficientResource':'资源不足','InsufficientDust':'对应尘埃不足','InsufficientMedal':'勋章不足','InsufficientBoxKey':'宝箱钥匙不足','InsufficientContribution':'公会贡献不足','InsufficientEnergy':'体力不足',
 'EnergyFull':'体力已满','EnergyPurchaseLimit':'今日体力购买次数已用完','FragmentEnergyFull':'碎片体力已满','FragmentEnergyPurchaseLimit':'今日碎片体力购买次数已用完',
 'VipLevelRequired':'VIP等级不足，暂时无法领取该礼包','VipRequired':'需要达到指定VIP等级','LevelRequired':'等级不足，暂时无法进行此操作','RankLevelLow':'等级不足，暂时无法领取该奖励','StageLocked':'该关卡尚未解锁','UnavailableDifficulty':'该难度暂不可挑战',
 'AlreadyClaimed':'该奖励已经领取','AlreadyCheckedIn':'今日签到奖励已经领取','AlreadySignedIn':'今日活动签到已经完成','AlreadyBought':'该物品已经购买','FundAlreadyClaimed':'今日基金奖励已经领取','FightAlreadySettled':'本场战斗奖励已经结算','CodeAlreadyUsed':'该兑换码已经使用',
 'InvalidCheckInState':'请先领取今日普通签到奖励，再领取VIP双倍奖励。','VipLevelTooLow':'VIP等级不足，无法领取双倍签到奖励。',
 'DailyLimit':'今日次数已用完','ActivityAttemptsExhausted':'今日活动挑战次数已用完','StageAttemptsExhausted':'该关卡今日挑战次数已用完','CapacityMax':'背包容量已达上限','AvatarCapacity':'英雄背包空间不足','EquipCapacity':'装备背包空间不足','NoRevives':'本次可复活次数已用完','NoRefreshes':'可刷新次数已用完','GambleLimit':'今日抽奖次数已用完',
 'SignRewardRequired':'请先领取本轮签到奖励','SignCycleIncomplete':'签到天数不足，暂时无法领取本轮奖励','PayGiftLocked':'充值累计未达到该奖励条件','SpendRewardLocked':'累计消费未达到该奖励条件','StageRewardLocked':'尚未满足关卡星级奖励条件','TaskNotComplete':'任务条件尚未完成','TaskComplete':'任务奖励已经领取或任务已完成',
 'InvalidGift':'礼包参数无效','UnknownGift':'该礼包当前不可领取','InvalidTask':'任务参数无效','UnknownTask':'该任务不存在','ShopUnavailable':'商店当前没有可用商品','StaleShop':'商店库存已刷新，请重新查看','StaleCapacity':'背包容量已变化，请刷新后重试',
 'HeroInTeam':'英雄仍在队伍中，请先下阵','HeroInDestiny':'英雄已绑定命运节点，请先解除绑定','MaxCulture':'培养属性已达到上限','InvalidAssist':'助战英雄信息无效，请刷新后重试',
 'ActivityClosed':'活动当前未开放','FundNotActive':'基金尚未达到领取条件','FundNoReward':'当前没有可领取的基金奖励','RoulettePending':'请先领取上一次转盘奖励','InvalidExchangePrice':'兑换价格无效，请刷新后重试','InvalidName':'名称需为1至18个字符',
 'ActivityScoreLow':'活动积分不足，无法兑换。','BossClosed':'首领挑战当前不在开放时间内。','BossCooldown':'攻击冷却中，请稍后再试。','BossDefeated':'本轮首领已被击败。','BossNotRecoverable':'当前没有需要恢复的攻击冷却。',
 'BoxKeyUnavailable':'宝箱钥匙活动当前不可用。','ExplorationBattlePending':'请先返回探索地图，再开始下一场战斗。','ExplorationComplete':'当前探索区域已全部完成。','ExplorationHeroDefeated':'请先复活已倒下的英雄，再继续探索。','ExplorationRewardPending':'请先领取已完成探索阶段的奖励。',
 'GuildLevelRequired':'公会等级不足，无法进行此操作。','InvalidGuildName':'公会名称需为2至8个字符。','InvalidGroupon':'团购数量无效，请选择单次或十次购买。','InvalidLottery':'招募类型无效，请刷新后重试。','InvalidRoulette':'抽奖次数无效，请选择单次或十次。',
 'InvalidWelfare':'福利抽取选项无效，请刷新后重试。','LotteryUnavailable':'活动招募当前没有可用奖池。','NoExplorationReward':'当前探索阶段尚未完成。','NoFallenHero':'当前没有倒下的英雄需要复活。','NoGuild':'请先加入公会。','NoWorshipGold':'当前没有可领取的公会供奉金币。',
 'RankRewardClaimed':'该榜单奖励已经领取。','RouletteUnavailable':'幸运转盘当前未开放。','RouletteClosed':'幸运转盘不在开放时间内。','RouletteLevelLocked':'等级不足，暂时无法参与幸运转盘。','SkillMaxLevel':'该技能等级限制不允许此操作。','UnknownMember':'请选择一名当前公会成员。','UnknownRankReward':'该等级榜单奖励不存在。','UnknownSkill':'该公会研究项目不存在。','WelfareFreeUsed':'本周期的免费福利抽取次数已使用。','WelfareUnavailable':'福利活动当前未开放。',
 'TaskUnavailable':'累计领取活动当前未开放，请在活动时间内领取。',
 'SkillNotResearched':'请先研究目标技能，再进行替换。','UnknownLearnedSkill':'当前没有学会要替换的源技能。','InvalidSkillReplacement':'技能替换条件无效，请检查目标技能和替换方式。','InvalidSkillState':'公会技能数据无效，请刷新后重试。','InvalidSkillCost':'技能替换费用未正确配置，请稍后重试。','SkillAlreadyLearned':'目标技能已经学会，不能重复替换。',
 'MorphUnavailable':'当前没有有效的变形机会，请先完成对应章节关卡。','MorphRequirements':'该英雄未满足变形条件，请检查英雄类别、星级和等级上限。','AlreadyMorphed':'该英雄已经变形。',
 'WashPotentialFull':'装备洗练潜能已达到上限。',
 'AlreadyFriend':'该好友已在列表中。','AlreadyUnlocked':'该命运节点已经解锁。','AlreadyWorshipped':'今天已供奉过该成员。',
 'DuplicateHero':'队伍中不能重复上阵同一名英雄。','EquipmentInUse':'请先卸下正在使用的装备。','FragmentOwned':'已拥有该装备碎片。',
 'FreeWagerLimit':'今日免费友情招募次数已用完。','FriendListFull':'好友列表已满。','HeroInBattle':'该英雄正在未结算的战斗中，不能作为材料。',
 'IncompatibleEquipment':'只能合成同类装备。','IncompatibleMaterial':'阶段晋升材料必须与目标同阶段且未变形。',
 'InsufficientFragmentEnergy':'碎片能量不足。','InsufficientFragments':'请先集齐该装备的全部碎片。','InsufficientLevel':'等级不足，无法解锁该节点。',
 'InsufficientMaterials':'所选材料数量或类型不符合要求。','InsufficientSoul':'魂魄不足。',
 'InvalidBattleIntent':'战斗开局数据无效，请返回后重新挑战即可。','InvalidBattleReport':'本地战斗记录无效或已过期。','InvalidEquipment':'装备星级信息无效，请刷新后重试。',
 'InvalidEquipmentGroup':'装备编队数据无效，请重新设置。','InvalidFragment':'碎片位置无效，请刷新后重试。',
 'InvalidLevel':'等级状态已变化，请刷新后重试。','InvalidMaterials':'所选材料无效，请检查后重试。','InvalidSelection':'所选条目无效，请重新选择。',
 'InvalidTarget':'请选择有效的技能书。','InvalidWager':'招募选项无效，请刷新后重试。','InvalidWashType':'洗练消耗类型无效，请重新选择。',
 'LockedNode':'请先解锁该命运节点的前置节点。','MagicAtMaximum':'该装备属性已强化至上限。',
 'MaxGrowth':'该项目已达到当前可提升的最高阶段。','MaxLevel':'该项目已达到当前等级上限，或需先升至上限。',
 'NoPendingCulture':'当前没有待确认的培养结果。','NoPendingTalent':'当前没有待确认的天赋选择。','NoPendingWash':'当前没有待确认的洗练结果。',
 'NotFriend':'该玩家不在好友列表中。','PendingOperation':'请先完成或取消当前操作。','RosterFull':'英雄仓库空间不足。',
 'UnknownBattleReport':'找不到该本地战斗记录。','UnknownFriendRequest':'没有来自该好友的待处理申请。','UnknownOpponent':'未找到该对手，请刷新列表。',
 'UnknownRecipe':'当前物品没有可用的碎片合成配方。','UnknownHero':'该英雄不存在或已不属于当前账号，请刷新后重试。',
 'UnknownAvatar':'该英雄不存在或已不属于当前账号，请刷新后重试。','UnknownEquipment':'该装备不存在或已不属于当前账号，请刷新后重试。',
 'WagerCooldown':'免费招募尚未冷却完成。','WrongEquipmentSlot':'该装备不适用于所选槽位。',
 'CheckInUnavailable':'本月签到奖励暂不可用，请稍后再试。','FundUnavailable':'基金活动当前没有可用奖励。','GambleUnavailable':'当前抽奖活动暂不可用。','InvalidBattle':'探索状态已变化，请返回地图刷新后再试。','InvalidBoxExchange':'宝箱或钥匙兑换选项无效。','InvalidBoxKey':'宝箱或钥匙类型无效。','InvalidCode':'兑换码无效或已过期。','InvalidDifficulty':'关卡难度无效，请返回关卡列表重新选择。','InvalidExchange':'兑换选项无效，请刷新后重试。','InvalidGamble':'抽取档位无效，请重新选择。','InvalidShop':'商店选项无效，请重新打开商店。','InvalidShopItem':'商品信息已过期，请重新打开商店。','InvalidTeam':'队伍需由1至5名不同英雄组成。','UnknownExchange':'该兑换项目当前不可用。','PayGiftUnavailable':'充值赠送奖励配置暂不可用。','InvalidRankReward':'榜单奖励档位无效，请重新打开奖励面板。','InvalidStage':'关卡或难度信息无效，请返回关卡列表重试。','InvalidPayProduct':'充值档位无效，请重新打开充值页面。','UnknownStage':'关卡数据无效，请返回关卡列表刷新。','UnknownFight':'战斗记录已过期或不属于当前账号，请返回后重新挑战。','MissingFight':'缺少本场战斗记录，请重新开始挑战。'
}
GAMEPLAY_ERROR_MESSAGES_ZH.update({
 'InvalidAdventureTask':'任务信息无效，请重新进入奇遇。',
 'AdventureTaskIncomplete':'任务尚未完成，或累计充值尚未达到要求。',
 'AdventureTaskClaimed':'该任务奖励已经领取。',
 'AdventureRewardUnavailable':'任务奖励暂不可用，请重新进入奇遇。',
 'DailyRecruitRequired':'英雄勋章兑换请从今日招募列表进入。',
 'DailyRecruitExpired':'今日招募列表已更新，请刷新后重试。',
 'EquipmentLocked':'装备已锁定，请先解锁后再操作。',
 'HeroLocked':'英雄已锁定，请先解锁后再出售。',
 'MagicLocked':'请先解锁前一附魔阶段。',
 'MagicAtMaximum':'该附魔阶段已达到上限。',
 'RuneLocked':'请先附魔装备，激活风林火山符文。',
 'RuneAtMaximum':'该装备符文已强化至满级。',
})

def gameplay_fault_message(error):
 return GAMEPLAY_ERROR_MESSAGES_ZH.get(error.code,error.message)

class Backend:
 def __init__(self,database,config=None,mods_root=None):
  database_path=str(database)
  if database_path!=':memory:':
   pathlib.Path(database_path).expanduser().resolve().parent.mkdir(parents=True,exist_ok=True)
  self.db=sqlite3.connect(database_path,check_same_thread=False)
  self.clock=GameClock(database_path if database_path!=':memory:' else self.db)
  self.lock=threading.RLock()
  self.retry_cache={}
  self.db.execute('CREATE TABLE IF NOT EXISTS accounts (name TEXT PRIMARY KEY,salt TEXT NOT NULL,password_hash TEXT NOT NULL)')
  if 'spending_tier' not in {row[1] for row in self.db.execute('PRAGMA table_info(accounts)')}:
   self.db.execute("ALTER TABLE accounts ADD COLUMN spending_tier TEXT NOT NULL DEFAULT 'small'")
  self.db.commit()
  self.config=None
  if config:
   self.config=json.loads(pathlib.Path(config).read_text(encoding='utf-8-sig'))
   if not isinstance(self.config,dict) or not isinstance(self.config.get('cfg'),dict):
    raise ValueError('Config file must contain {cfg_version, cfg: {...}, ...}')
   self.config=native_dates(self.config)
   apply_recruit_exchange_config(self.config)
   apply_equipment_capacity(self.config)
   apply_equipment_upgrade_config(self.config)
   apply_captain_timing(self.config)
   apply_upstream_skill_priority(self.config)
   apply_battle_status_effects(self.config)
   apply_summon_panel_config(self.config)
   self.config=apply_halo_progression(self.config)
   from skill_books import apply_equipment_calibration
   apply_equipment_calibration(self.config)
   apply_hero_skills_103(self.config)
   apply_talent_stats_103(self.config)
   apply_hero_balance_103(self.config)
   finalize_hero_skills_103(self.config)
   apply_dot_rules_103(self.config)
   apply_cat_katarina_103(self.config)
   apply_polar_ashe_103(self.config)
   apply_santa_veigar_103(self.config)
   apply_nurse_akali_103(self.config)
   apply_hero_accuracy_103(self.config)
   apply_hero_iteration_103(self.config)
   apply_energy_purchase_103(self.config)
   apply_tower_rewards_103(self.config)
   apply_ancient_trial_103(self.config)
   apply_material_attempts_103(self.config)
   apply_check_in_rewards(self.config,int(game_day(self.clock.now())[:4]))
   self.config['cfg_version']=(ROOT/'VERSION').read_text(encoding='utf-8').strip()
  self.players=PlayerStore(self.db,self.config,self.clock)
  self.players.lock=self.lock
  from mod_service import ModService
  default_mods=ROOT/'mods' if database_path==':memory:' else pathlib.Path(database_path).expanduser().resolve().parent/'mods'
  self.mods=ModService(self.players,self.config,mods_root if mods_root is not None else default_mods)
 def password_hash(self,password,salt):
  return hashlib.pbkdf2_hmac('sha256',password.encode(),bytes.fromhex(salt),100000).hex()
 def call(self,request):
  if not isinstance(request,dict): raise RpcFault('InvalidRequest','RPC argument must be an object')
  method=request.get('method'); params=request.get('params')
  if not isinstance(method,str) or not isinstance(params,dict) or not isinstance(params.get('actionID'),str) or not params['actionID']:
   raise RpcFault('InvalidRequest','method and params.actionID are required')
  data={}
  with self.lock:
   # Retries reuse params.actionID in SendAndSelect.reSend. Keep guest creation idempotent.
   retry_key=(method,params['actionID'],hashlib.sha256(json.dumps(params,sort_keys=True,default=str).encode()).digest())
   now=time.monotonic()
   self.retry_cache={k:v for k,v in self.retry_cache.items() if now-v[0]<600}
   cached=self.retry_cache.get(retry_key)
   if cached is not None: return cached[1]
   if method=='sys.get_config':
    if self.config is None:
     raise RpcFault('MissingGameConfig','Game configuration is unavailable.')
    apply_check_in_rewards(self.config,int(game_day(self.clock.now())[:4]))
    # Return all configured tables: client merges them into its cached object.
    data=self.config
    if request.get('uid'):
     try:
      owner=self.players.authenticate(request)
      data=self.mods.config(owner)['config']
     except GameplayFault as error:raise RpcFault(error.code,error.message) from error
   elif method in ('user.register','user.llogin','user.default_register','user.login'):
    if params.get('pf')!='local':
     raise RpcFault('UnsupportedPlatform','Only local accounts are supported; channel SDK authentication has not been reconstructed.')
    if method=='user.default_register':
     name='guest_'+secrets.token_hex(8); password=secrets.token_urlsafe(18)
    else:
     name=params.get('session_key'); password=params.get('sessionid')
    if not isinstance(name,str) or not 1<=len(name)<=256 or not isinstance(password,str) or not 1<=len(password)<=256:
     raise RpcFault('InvalidCredentials','Nonempty account and password strings are required (max 256 chars)')
    row=self.db.execute('SELECT salt,password_hash,spending_tier FROM accounts WHERE name=?',(name,)).fetchone()
    if method in ('user.llogin','user.login'):
     if row is None or not hmac.compare_digest(row[1],self.password_hash(password,row[0])):
      raise RpcFault('InvalidCredentials','Account or password is incorrect')
    else:
     if row is not None: raise RpcFault('AccountExists','Account already exists')
     from spending_budget import valid_registration_tier
     spending_tier=params.get('spending_tier','small')
     if not valid_registration_tier(spending_tier):raise RpcFault('InvalidSpendingTier','消费档位无效')
     salt=secrets.token_hex(16)
     self.db.execute('INSERT INTO accounts(name,salt,password_hash,spending_tier) VALUES(?,?,?,?)',(name,salt,self.password_hash(password,salt),spending_tier))
     self.db.commit()
    if method=='user.default_register': data={'session_key':name,'sessionid':password}
    elif method=='user.login':
     try:
      owner=self.db.execute('SELECT uid FROM players WHERE account=?',(name,)).fetchone()
      if owner is not None:
       self.mods.require_client(getattr(self.mods.context(owner[0]),'mod_resolved',None),request.get('client_capabilities'))
      data=self.players.login(name,row[2])
      data['mod_config']=self.mods.config(data['uid'])
     except GameplayFault as error:
      return {'method':method,'params':params,'return_code':1,'server_now':utc_datetime(self.clock.now()),
              'data':{'msg':gameplay_fault_message(error),'error_code':error.code}}
   elif isinstance(method,str) and method.startswith('user.'):
    try:data=self.players.dispatch(request)
    except GameplayFault as error:
     data={'msg':gameplay_fault_message(error),'error_code':error.code}
     reply={'method':method,'params':params,'return_code':1,'server_now':utc_datetime(self.clock.now()),'data':data}
     return reply
   else:
    raise RpcFault('NotImplemented','Method not reconstructed: '+method)
  # A native AMF Date is mandatory; the client casts server_now to flash Date.
   reply={'method':method,'params':params,'return_code':0,'server_now':utc_datetime(self.clock.now()),'data':data}
   if isinstance(method,str) and method.startswith('user.'):
    state_uid=None
    if method=='user.login' and isinstance(data,dict):state_uid=data.get('uid')
    elif method not in ('user.register','user.llogin','user.default_register'):
     try:state_uid=self.players.authenticate(request)
     except GameplayFault:state_uid=None
    if state_uid is not None:reply['state_sync']=self.players.state_snapshot(state_uid)
   if method in ('user.register','user.default_register'):
    if len(self.retry_cache)>=1000: self.retry_cache.pop(next(iter(self.retry_cache)))
    self.retry_cache[retry_key]=(time.monotonic(),reply)
   return reply
 def process(self,payload):
  incoming=remoting.decode(payload)
  outgoing=remoting.Envelope(amfVersion=incoming.amfVersion)
  for response_uri,message in incoming:
   request=None
   try:
    if not isinstance(message,remoting.Request) or message.target!='http_api' or len(message.body)!=1:
     raise RpcFault('InvalidTarget','Expected http_api with one RPC object argument')
    request=message.body[0]
    print('RPC',request.get('method','invalid') if isinstance(request,dict) else 'invalid',flush=True)
    reply=self.call(request)
    outgoing[response_uri]=remoting.Response(reply)
   except RpcFault as error:
    print('RPC fault',error.code,'message='+str(error.message)[:240],_safe_rpc_diagnostic(request),flush=True)
    outgoing[response_uri]=remoting.Response({'code':error.code,'description':error.message,'actions':[]},status=remoting.STATUS_ERROR)
  return remoting.encode(outgoing,strict=True).getvalue()

def _safe_rpc_diagnostic(request):
 if not isinstance(request,dict): return "request=non-object"
 params=request.get('params')
 if not isinstance(params,dict): return "params=non-object"
 method=request.get('method','')
 parts=["method="+str(method),"param_keys="+','.join(sorted(str(k) for k in params.keys()))]
 for key in ('fight_id','fight_kind','cid','diff','sign','combat_star','actionID'):
  if key in params:
   value=params[key]
   if key=='actionID': value='<present>'
   elif key=='sign': value=f'<length {len(value)}>' if isinstance(value,str) else '<redacted>'
   elif isinstance(value,(str,int,float,bool)) or value is None: value=repr(value)[:80]
   else: value=type(value).__name__
   parts.append(f"{key}={type(params[key]).__name__}:{value}")
 teams=params.get('teams')
 if isinstance(teams,dict):
  for side,units in teams.items():
   if isinstance(units,list):
    item=units[0] if units and isinstance(units[0],dict) else None
    parts.append(f"teams.{side}=list[{len(units)}]")
    if item is not None:
     parts.append(f"teams.{side}.unit_keys={','.join(sorted(str(k) for k in item.keys()))}")
     parts.append(f"teams.{side}.hp_types="+','.join(f"{k}:{type(item.get(k)).__name__}" for k in ('hp','hp_max','line','pos') if k in item))
 return ' '.join(parts)

class Handler(BaseHTTPRequestHandler):
 server_version=f'lal-rebuild/{PROJECT_VERSION}'
 def version_string(self): return self.server_version
 def send_body(self,status,body,content_type):
  self.send_response(status); self.send_header('Content-Type',content_type)
  self.send_header('Content-Length',str(len(body))); self.end_headers(); self.wfile.write(body)
 def do_GET(self):
  path=urlsplit(self.path).path
  if path=='/health':
   config_loaded=self.server.backend.config is not None
   gameplay_ready=config_loaded and len(self.server.backend.players.gameplay_handlers)>=5
   data={'status':'ok' if gameplay_ready else 'degraded','service':'lal-rebuild','config_loaded':config_loaded,'cfg_version':(self.server.backend.config or {}).get('cfg_version'),'gameplay_ready':gameplay_ready,'local_login_ready':True,'gift_mail_ready':True,'payment':'test-gift-only-no-external-charge'}
   self.send_body(200,json.dumps(data).encode(),'application/json')
  elif path.rstrip('/')=='/notice':
   self.send_body(200,render_notice(),'text/html; charset=utf-8')
  elif path.rstrip('/')=='/help' or path.startswith('/help/'):
   self.send_body(200,render_help(path),'text/html; charset=utf-8')
  elif path=='/crossdomain.xml':
   self.send_body(200,b'<cross-domain-policy><allow-access-from domain="*" secure="false" /></cross-domain-policy>','application/xml')
  elif path.startswith('/mods/assets/'):
   parts=path[len('/mods/assets/'):].split('/',1)
   try:
    if len(parts)!=2:raise GameplayFault('InvalidModAsset','Invalid asset path')
    with self.server.backend.lock:
     body,media_type=self.server.backend.mods.asset(parts[0],unquote(parts[1]))
    self.send_body(200,body,media_type)
   except (GameplayFault,OSError,ValueError):self.send_body(404,b'Mod asset unavailable','text/plain')
  else: self.send_body(404,b'Not found','text/plain')
 def do_POST(self):
  if urlsplit(self.path).path=='/mods/install':
   try:
    size=int(self.headers.get('Content-Length','0'))
    backend=self.server.backend
    if not 0<size<=backend.mods.MAX_UPLOAD_BYTES:raise GameplayFault('InvalidModPackage','英雄包为空或超过大小限制。')
    if self.headers.get('Content-Type','').split(';',1)[0].strip()!='application/octet-stream':
     raise GameplayFault('InvalidModPackage','上传必须是英雄包二进制文件。')
    with backend.lock:
     backend.players.authenticate({'uid':self.headers.get('X-Lal-Uid',''),'sessionid':self.headers.get('X-Lal-Session','')})
    self.connection.settimeout(30)
    payload=self.rfile.read(size)
    if len(payload)!=size:raise GameplayFault('InvalidModPackage','上传文件不完整。')
    with backend.lock:result=backend.mods.install_bytes(payload)
    self.send_body(200,json.dumps({'ok':True,'package':result},ensure_ascii=False).encode('utf-8'),'application/json; charset=utf-8')
   except GameplayFault as error:
    status=401 if error.code=='InvalidSession' else 200
    self.send_body(status,json.dumps({'ok':False,'error':{'code':error.code,'message':error.message}},ensure_ascii=False).encode('utf-8'),'application/json; charset=utf-8')
   except (ValueError,OSError,OverflowError):
    self.send_body(400,b'{"ok":false,"error":{"code":"InvalidModUpload","message":"Upload failed"}}','application/json')
   return
  if urlsplit(self.path).path=='/debug/client-error':
   try:
    size=int(self.headers.get('Content-Length','0'))
    if not 0<size<=16384:raise ValueError('size')
    error=self.rfile.read(size).decode('utf8',errors='replace')
    if not error.strip():raise ValueError('empty diagnostic')
   except (ValueError,OverflowError):
    self.send_body(400,b'Invalid diagnostic','text/plain'); return
   try:
    log_path=ROOT/'data'/'logs'/'client-errors.log'
    log_path.parent.mkdir(parents=True,exist_ok=True)
    with log_path.open('a',encoding='utf8') as log:log.write(error.rstrip('\r\n')+'\n')
    self.send_body(200,b'ok','text/plain')
   except OSError:
    self.send_body(500,b'Diagnostic storage unavailable','text/plain')
   return
  if urlsplit(self.path).path.rstrip('/')!='/gateway':
   self.send_body(404,b'Not found','text/plain'); return
  try:
   size=int(self.headers.get('Content-Length','0'))
   if not 0<size<=4*1024*1024: raise ValueError('Invalid body size')
   self.connection.settimeout(10)
   payload=self.rfile.read(size)
   if len(payload)!=size: raise ValueError('Truncated body')
   body=self.server.backend.process(payload)
  except Exception as error:
   # Never log login payloads or passwords.
   print('Rejected AMF request:',type(error).__name__,file=sys.stderr)
   self.send_body(400,b'Malformed AMF request','text/plain'); return
  self.send_body(200,body,'application/x-amf')

def make_server(host,port,backend):
 service=ThreadingHTTPServer((host,port),Handler)
 service.daemon_threads=False
 service.block_on_close=True
 service.backend=backend
 return service

def _console_help():
 print('Server commands: help | status | time | time hours N | time days N | accounts | mail ACCOUNT REQUEST_ID "TITLE" \'{"coin":100,"gold":500}\' | exit',flush=True)
 print('mail gifts must be a JSON object accepted by the configured gift-mail rules; use a single-quoted JSON argument.',flush=True)

def _console_status(service):
 backend=service.backend
 with backend.lock:
  accounts=backend.db.execute('SELECT COUNT(*) FROM accounts').fetchone()[0]
  players=backend.db.execute('SELECT COUNT(*) FROM players').fetchone()[0]
  mails=backend.db.execute('SELECT COUNT(*) FROM gift_mail').fetchone()[0]
  db_path=backend.db.execute('PRAGMA database_list').fetchone()[2]
 print(json.dumps({'address':f'http://{service.server_address[0]}:{service.server_address[1]}','cfg_version':(backend.config or {}).get('cfg_version'),'database':db_path,'accounts':accounts,'players':players,'mail_count':mails},ensure_ascii=False),flush=True)

def _console_loop(service):
 _console_help()
 while True:
  try: line=input('server> ')
  except EOFError:
   print('Console input closed; the HTTP server is still running. Use Ctrl+C to stop it.',flush=True)
   return
  except KeyboardInterrupt:
   print('',flush=True)
   service.shutdown()
   return
  try: parts=shlex.split(line,posix=True)
  except ValueError as error:
   print(f'Invalid command quoting: {error}',flush=True)
   continue
  if not parts: continue
  command=parts[0].lower()
  if command=='help':
   _console_help()
  elif command=='status' and len(parts)==1:
   _console_status(service)
  elif command=='time':
   try:
    if len(parts)==1:
     print('Game time (UTC): '+str(utc_datetime(service.backend.clock.now())),flush=True)
    elif len(parts)==3 and parts[1] in ('hours','days'):
     seconds=duration_seconds(parts[2],3600 if parts[1]=='hours' else 86400)
     before,after=service.backend.clock.advance(seconds)
     print(f'Game time (UTC): {utc_datetime(before)} -> {utc_datetime(after)}',flush=True)
    else: raise ValueError('usage: time | time hours N | time days N')
   except (ValueError,OverflowError,sqlite3.Error) as error:
    print(f'Game time failed: {error}',flush=True)
  elif command=='accounts' and len(parts)==1:
   with service.backend.lock:
    total=service.backend.db.execute('SELECT COUNT(*) FROM accounts').fetchone()[0]
    rows=service.backend.db.execute('SELECT name FROM accounts ORDER BY name LIMIT 200').fetchall()
   print(json.dumps({'count':total,'returned':len(rows),'accounts':[row[0] for row in rows]},ensure_ascii=False),flush=True)
  elif command=='mail' and len(parts)==5:
   _,account,request_id,title,gifts_text=parts
   try:
    gifts=json.loads(gifts_text)
    if not isinstance(gifts,dict): raise ValueError('gifts must be a JSON object')
    with service.backend.lock:
     mail_id=service.backend.players.send_mail(account,title,gifts,request_id,allow_skin=True)
    print(json.dumps({'mail_id':mail_id,'account':account,'request_id':request_id,'title':title,'gifts':gifts},ensure_ascii=False),flush=True)
   except (ValueError,GameplayFault,sqlite3.Error) as error:
    code=f' ({error.code})' if isinstance(error,GameplayFault) else ''
    message=error.message if isinstance(error,GameplayFault) else str(error)
    print(f'Mail failed{code}: {message}',flush=True)
  elif command=='exit' and len(parts)==1:
   print('Stopping HTTP server...',flush=True)
   service.shutdown()
   return
  else:
   print('Unknown command or invalid arguments. Enter help for usage.',flush=True)

def main():
 parser=argparse.ArgumentParser(description=__doc__)
 parser.add_argument('--host',default='127.0.0.1'); parser.add_argument('--port',default=8080,type=int)
 parser.add_argument('--database',default=str(ROOT/'server/local.sqlite3')); parser.add_argument('--config',default=str(ROOT/'config/reconstruction/full-config.json'))
 parser.add_argument('--mods-root',default=None,help='Shared installed Mod directory (default: beside database)')
 args=parser.parse_args()
 backend=Backend(args.database,args.config,args.mods_root)
 service=make_server(args.host,args.port,backend)
 print(f'AMF gateway http://{service.server_address[0]}:{service.server_address[1]}/gateway/',flush=True)
 console=threading.Thread(target=_console_loop,args=(service,),name='server-console',daemon=True)
 console.start()
 try: service.serve_forever()
 except KeyboardInterrupt: pass
 finally:
  service.server_close()
  with backend.lock:
   backend.db.close()
   backend.clock.close()
if __name__=='__main__': main()

