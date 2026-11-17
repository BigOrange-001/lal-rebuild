"""Guild chat storage and offline template lines for local AI players.

Chat rows live in their own SQLite table instead of the profile JSON, so
conversation history never enlarges the per-request profile rewrite. Rows are
written inside the caller's atomic_update transaction and therefore commit or
roll back together with the guild state that produced them.
"""
from __future__ import annotations

import random
import re

MAX_ROWS_PER_OWNER = 200
MAX_TEXT = 40
MAX_PLAYER_TEXT = 60

# Characters accepted by the native PanelChatRoom.chat_send_msg pattern, plus
# common full-width punctuation it already allows, minus angle brackets
# so text never reaches an HTML-capable text field as markup. Anything else is removed so
# LLM output cannot carry markup, links or control characters to the client.
_ALLOWED = re.compile(r"[^0-9A-Za-z一-龥 ~!@#$%^&*()_+\-=:;\"',.?/！￥（）{}【】；：‘’“”《》，。？、…—～·]")
_URL = re.compile(r"(?:https?://|www\.)\S+", re.I)


def clean_text(text, limit=MAX_TEXT):
    if not isinstance(text, str):
        return ""
    text = _URL.sub("", text.replace("\r", " ").replace("\n", " "))
    text = _ALLOWED.sub("", text).strip()
    return text[:limit]


def ensure_table(db):
    db.execute("""CREATE TABLE IF NOT EXISTS guild_chat(
        id INTEGER PRIMARY KEY AUTOINCREMENT, owner_uid TEXT NOT NULL,
        guild_id TEXT NOT NULL, ts INTEGER NOT NULL, speaker_uid TEXT NOT NULL,
        speaker_name TEXT NOT NULL, text TEXT NOT NULL, source TEXT NOT NULL)""")
    db.execute("CREATE INDEX IF NOT EXISTS guild_chat_owner ON guild_chat(owner_uid, id)")


def append(db, owner, guild_id, ts, speaker_uid, speaker_name, text, source):
    db.execute("INSERT INTO guild_chat(owner_uid,guild_id,ts,speaker_uid,speaker_name,text,source)"
               " VALUES(?,?,?,?,?,?,?)",
               (str(owner), str(guild_id), int(ts), str(speaker_uid), str(speaker_name), text, source))
    db.execute("""DELETE FROM guild_chat WHERE owner_uid=? AND id NOT IN (
        SELECT id FROM guild_chat WHERE owner_uid=? ORDER BY id DESC LIMIT ?)""",
               (str(owner), str(owner), MAX_ROWS_PER_OWNER))


def recent(db, owner, guild_id, limit=50):
    rows = db.execute("SELECT ts,speaker_uid,speaker_name,text,source FROM guild_chat"
                      " WHERE owner_uid=? AND guild_id=? ORDER BY id DESC LIMIT ?",
                      (str(owner), str(guild_id), int(limit))).fetchall()
    return [{"ts": ts, "uid": uid, "name": name, "text": text, "source": source}
            for ts, uid, name, text, source in reversed(rows)]


# Template lines by event, with optional archetype-specific variants.
# Placeholders: {name} speaker, {guild} guild name, {other} another member,
# {damage} boss damage.
TEMPLATES = {
    "greet": {
        "hot": ["兄弟们上线了！今天冲一波！", "我来了，今天Boss谁一起？", "打卡！今天也要变强"],
        "chill": ["早呀各位~", "上线签个到，佛系养老中", "大家好，今天也慢慢玩"],
        "chatty": ["哈喽哈喽！有人在吗？", "我又来啦，今天有什么好玩的", "早上好！昨晚抽卡又歪了……"],
        "veteran": ["上线了，有阵容问题可以问我", "大家记得先把日常做完", "签到，今天的贡献别忘了"],
        "lone": ["在。", "上线。", "嗯，来了"],
        "rookie": ["大家好，我还是新手，请多关照", "我来啦！今天学到好多", "早上好，我该先练哪个英雄呀"],
    },
    "donate": {
        "": ["刚捐了一波贡献，公会冲冲冲", "贡献已交，大家加油", "今天的捐献搞定"],
        "lone": ["捐了。", "贡献交了"],
    },
    "worship": {
        "": ["给公会上了柱香，保佑出货", "供奉完成，公会繁荣+1", "今天的供奉打卡"],
    },
    "worship_member": {
        "": ["膜拜一下大佬{other}", "{other}太强了，膜一下", "给{other}点个赞"],
    },
    "boss": {
        "hot": ["Boss吃我一刀，{damage}伤害！", "冲Boss！打了{damage}", "还差一点，大家一起上！"],
        "": ["打了{damage}伤害，交给你们了", "Boss打完了一轮，{damage}", "Boss血还挺厚，留给后面的兄弟"],
        "rookie": ["我才打了{damage}……大家别嫌弃", "第一次打Boss，好紧张"],
    },
    "join": {
        "": ["大家好，我是新来的{name}，请多指教！", "新人报到，以后一起冲！", "加入{guild}啦，请多关照"],
        "lone": ["新人，{name}。", "来了，请多指教"],
    },
    "welcome": {
        "": ["欢迎{other}！", "欢迎新人{other}，有问题随时问", "{other}欢迎欢迎~"],
        "lone": ["欢迎。"],
    },
    "leave": {
        "": ["这段时间谢谢大家照顾，有缘再见", "我去别的地方转转，大家保重", "先走了，祝公会越来越好"],
        "lone": ["走了。"],
    },
    "idle": {
        "hot": ["今天战力又涨了，爽！", "竞技场冲到前面了，谁来挑战", "我要冲榜，谁陪我刷本"],
        "chill": ["随缘玩就好，开心最重要", "今天也是挂机的一天", "有人一起聊天吗~"],
        "chatty": ["你们阵容都怎么搭的？", "今天抽到一张新卡，开心！", "有没有人觉得这关好难"],
        "veteran": ["羁绊搭配好，战力能高一截", "装备先强化主力，别平均分", "公会技能记得研究"],
        "lone": ["……", "嗯。"],
        "rookie": ["新手问一下，天赋点怎么加？", "我终于过了第三章！", "大家一般几点打Boss呀"],
    },
}


def template_line(event, archetype, rng, **values):
    group = TEMPLATES.get(event, TEMPLATES["idle"])
    lines = group.get(archetype) or group.get("") or next(iter(group.values()))
    line = rng.choice(lines) if isinstance(rng, random.Random) else lines[0]
    try:
        line = line.format(**{key: values.get(key, "") for key in ("name", "guild", "other", "damage")})
    except (KeyError, IndexError, ValueError):
        pass
    return clean_text(line)
