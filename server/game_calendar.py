"""One UTC+8 gameplay day: inclusive midnight through the next midnight, exclusive."""
from __future__ import annotations

import datetime
import copy
from zoneinfo import ZoneInfo

LOCAL_TZ = ZoneInfo('Asia/Shanghai')
DAILY_RESET_HOUR = 0


def local_datetime(now=None):
    if now is None:
        now = datetime.datetime.now(datetime.timezone.utc)
    if isinstance(now, (int, float)):
        now = datetime.datetime.fromtimestamp(now, datetime.timezone.utc)
    if now.tzinfo is None:
        now = now.replace(tzinfo=datetime.timezone.utc)
    return now.astimezone(LOCAL_TZ)


def game_day(now=None):
    """Label the gameplay day with the date on which its midnight began."""
    return (local_datetime(now)-datetime.timedelta(hours=DAILY_RESET_HOUR)).date().isoformat()


def game_day_number(now=None):
    return (datetime.date.fromisoformat(game_day(now))-datetime.date(1970,1,1)).days


def next_daily_reset(now=None):
    local = local_datetime(now)
    reset = local.replace(hour=DAILY_RESET_HOUR,minute=0,second=0,microsecond=0)
    if local >= reset:
        reset += datetime.timedelta(days=1)
    return int(reset.timestamp())


def normalize_daily_counters(profile, now):
    """Shared daily caps not owned by a feature; retain legacy first-day use."""
    records=profile.setdefault('records',{})
    today=game_day(now)
    previous=records.get('shared_daily_day')
    if isinstance(previous,str) and previous != today:
        records['free_wager_count']=0
        records['help_suids']={}
        records['help_fuids']={}
    records['shared_daily_day']=today
    attempts=records.get('daily_stage_attempts')
    if not isinstance(attempts,dict):
        # Legacy counts also prove prior wins/first clears. Copy, never erase
        # those lifetime records while adopting today's challenge allowance.
        attempts={key:copy.deepcopy(records[key]) if isinstance(records.get(key),dict) else {}
                  for key in ('combat_main','combat_main_hard','combat_ploy')}
        attempts['day']=today
        records['daily_stage_attempts']=attempts
    elif attempts.get('day')!=today:
        records['daily_stage_attempts']={'day':today,'combat_main':{},'combat_main_hard':{},'combat_ploy':{}}


def apply_daily_reset_config(document):
    cfg=document.get('cfg',document)
    cfg.setdefault('system_simple',{}).update(daily_reset_hour=DAILY_RESET_HOUR,
                                             daily_timezone_offset_hours=8)
    return document
