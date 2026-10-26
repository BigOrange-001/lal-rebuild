"""Shared daily resource victories and paid extra attempts, in game time."""
from __future__ import annotations
import copy
from gameplay_common import game_day
from player_store import GameplayFault

BASE_ATTEMPTS=12
BUY_COST=50

def daily_state(profile,now):
    daily=profile.setdefault('records',{}).setdefault('material_activity',{})
    if not isinstance(daily,dict):
        raise GameplayFault('InvalidProfile','Malformed resource challenge state')
    today=game_day(now)
    if daily.get('day')!=today:
        daily.clear();daily.update(day=today,uses={},buys={})
    for key in ('uses','buys'):
        values=daily.setdefault(key,{})
        if not isinstance(values,dict) or any(type(n) is not int or n<0 for n in values.values()):
            raise GameplayFault('InvalidProfile','Malformed resource challenge counts')
    return daily

def remaining(profile,chapter,now):
    daily=daily_state(profile,now)
    return max(0,BASE_ATTEMPTS+daily['buys'].get(chapter,0)-daily['uses'].get(chapter,0))

def consume_win(profile,chapter,now):
    if remaining(profile,chapter,now)<=0:
        raise GameplayFault('ActivityAttemptsExhausted','今日该资源副本挑战次数已用完，可购买额外次数。')
    uses=daily_state(profile,now)['uses']
    uses[chapter]=uses.get(chapter,0)+1

def apply_material_attempts_103(document):
    cfg=document.get('cfg',document)
    cfg['system_simple']['material_challenge']={'base_attempts':BASE_ATTEMPTS,'buy_cost':BUY_COST,'buy_limit_vip_bonus':2,'consume':'victory'}
    stages=copy.deepcopy(cfg['combat_ploy']);chapters=copy.deepcopy(cfg['battle_ploy'])
    for stage in stages.values():
        if stage.get('ancient_equip_drop'):
            stage.update(activity_kind='material',material_kind='ancient_trial')
        if stage.get('activity_kind')!='material':continue
        stage.pop('unlimited_attempts',None)
        stage['limit']=[BASE_ATTEMPTS]
        stage['info']=stage.get('info','').split('；')[0]+'；每日12次，各难度共享，胜利扣次数、失败不扣。每日可购买VIP等级+2次，每次50金砖增加1次挑战。'
        bid=stage['id'].rsplit('_',1)[0]
        chapters[bid]['info']='常驻'+chapters[bid]['name']+'；每日12次，所有难度共享，胜利扣次数、失败不扣。每日可购买VIP等级+2次，每次50金砖增加1次挑战。'
    cfg['combat_ploy']=stages
    cfg['battle_ploy']=chapters
    if 'cfg' in document:
        for key in ('combat_ploy','battle_ploy'):
            document[key]=cfg[key]
            if isinstance(document.get('pve'),dict):document['pve'][key]=cfg[key]
    return document
