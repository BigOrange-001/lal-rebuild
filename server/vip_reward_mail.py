"""VIP milestone mail queued inside the owning PlayerStore transaction."""
import json
from gameplay_common import game_day


def normalize_daily_reward(profile,now):
    records=profile.setdefault('records',{})
    today=game_day(now)
    previous=records.get('vip_daily_reward_day')
    if previous is not None and previous!=today:
        records['vip_gift']=[]
    elif records.get('vip_gift'):
        # A legacy multi-row claim already used today's reward opportunity.
        records['vip_gift']=[0]
    records['vip_daily_reward_day']=today


def queue_level_rewards(db,profile,config,now):
    if not isinstance(config,dict):return
    cfg=config.get('cfg',config)
    if not cfg.get('system_simple',{}).get('vip_free_rewards_by_mail_105'):return
    normalize_daily_reward(profile,now)
    attrs=profile.setdefault('attrs',{})
    received=attrs.setdefault('vip_gift_buy',[])
    uid=str(profile['uid'])
    queued=False
    for level in range(1,min(15,int(profile.get('vip_lv',0)))+1):
        if level in received:continue
        reward=cfg.get('vip',{}).get(str(level),{}).get('gift_buy',{}).get('data')
        if not reward:continue
        db.execute('INSERT OR IGNORE INTO gift_mail(uid,title,gifts,created,request_key,allow_skin) VALUES(?,?,?,?,?,0)',
                   (uid,f'VIP{level}等级奖励',json.dumps(reward,sort_keys=True),now,f'vip-level-free:{uid}:{level}'))
        received.append(level)
        queued=True
    if queued:
        profile['msg_num']=db.execute('SELECT COUNT(*) FROM gift_mail WHERE uid=? AND claimed=0',(uid,)).fetchone()[0]
