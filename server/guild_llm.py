"""Optional LLM planner for the guild AI players.

The player supplies their own key. ``protocol`` selects an adapter: any
provider speaking the OpenAI ``/chat/completions`` protocol, or the Anthropic
Messages API. DeepSeek is the default and can be changed in ``llm.json`` (next to the save database) or with environment
variables. Without a key the rule planner and template chat are used.

Requests are few and coarse: one call returns a structured plan for every AI
player over the next window of game hours (default 6). Calls run on a
background thread; RPCs never wait for the network. Results are stored in the
``guild_ai_plan`` table and picked up by ``guild_world`` on a later request,
where every action is validated against the game rules again.
"""
from __future__ import annotations

import json
import logging
import os
import queue
import threading
import time
import urllib.error
import urllib.request
from pathlib import Path

import guild_chat
from game_calendar import game_day

LOG = logging.getLogger(__name__)

DEFAULT_SETTINGS = {
    "enabled": True,
    # "openai" = OpenAI-compatible chat/completions (DeepSeek, Qwen, Kimi, Ollama...);
    # "anthropic" = Anthropic Messages API (base_url https://api.anthropic.com).
    "protocol": "openai",
    "base_url": "https://api.deepseek.com",
    "model": "deepseek-chat",
    "api_key": "",
    "timeout_seconds": 30,
    "json_mode": True,
    "temperature": 0.9,
    "max_output_tokens": 2000,
    "min_interval_seconds": 60,
    "max_calls_per_hour": 10,
    "max_calls_per_day": 30,
    "max_tokens_per_day": 60000,
    "reply_cooldown_seconds": 600,
    "send_player_messages": True,
    "system_prompt_extra": "",
}
ENV = {"api_key": "LAL_LLM_API_KEY", "base_url": "LAL_LLM_BASE_URL", "model": "LAL_LLM_MODEL",
       "protocol": "LAL_LLM_PROTOCOL"}
ACTIONS = ("chat", "donate", "worship_guild", "worship_member", "boss", "apply", "leave", "found")
MAX_EVENTS = 160

SYSTEM_PROMPT = """你是一款单机卡牌游戏里“公会系统”的幕后编剧，负责安排一群AI玩家在接下来一段游戏时间里的行为。
这些AI玩家和真人玩家一起玩游戏，要让真人玩家感觉公会里有一群性格各异、真实的伙伴。

输入是一个JSON，包含：
- hours：本时间窗的每个小时（h从0开始）、当地时间、该小时公会Boss是否开放（boss_open）。
- player：真人玩家的名字、等级、战力、所在公会和职位（0会长 1副会长 3成员）。
- guilds：所有公会（id、名称、等级、人数、join_type：0不收人 1需申请 2直接加入）。
- agents：所有AI玩家（uid、名字、性格persona、活跃度/慷慨度/忠诚度/野心/话痨程度0-100、等级、战力、所在公会guild、职位rank、心情mood、最近记忆memory）。
- recent_chat：真人玩家所在公会最近的聊天。
- player_message：如果不为空，是真人玩家刚在公会频道说的话，需要有1-3个AI自然地回应。

你只输出一个JSON对象，格式：
{"events":[{"h":0,"uid":"AI的uid","act":"动作","tier":0,"target":"","text":"","name":""}]}
act只能是：
- chat：在公会频道说一句话，text必填，30字以内，口语化，符合该AI的性格和记忆，可以接上最近的聊天。
- donate：捐献公会贡献，tier 0普通 1高级。每人每天最多一次。
- worship_guild：公会供奉，tier 0/1/2。每人每天最多一次。
- worship_member：膜拜一名同公会成员，target填对方uid（可以是真人玩家的uid）。
- boss：攻击公会Boss，只能安排在boss_open为true的小时，每人每天最多3次。
- apply：没有公会的AI申请加入公会，target填公会id。
- leave：心情很低的AI离开公会（会长不能离开），要少见。
- found：野心很高、等级30以上、没有公会的AI创建公会，name填2-8个字的公会名，要少见。

要求：
1. 只使用输入里存在的uid和公会id；h必须在hours范围内。
2. 不是每个AI每小时都在线：按活跃度安排，深夜很少有人在线。
3. 聊天要像真实玩家：简短、自然、有个性，可以聊阵容、抽卡、Boss、日常，不要每句都是客套话；不要提到自己是AI或程序。
4. 不要输出链接、联系方式、现实中的政治、色情、暴力或广告内容。
5. 游戏规则会再次校验每个动作，不合法的会被丢弃，所以不必安排不可能的动作。
6. 只输出JSON，不要输出其他文字。"""


def _database_dir(db):
    try:
        for _, name, path in db.execute("PRAGMA database_list").fetchall():
            if name == "main" and path:
                return Path(path).resolve().parent
    except Exception:  # noqa: BLE001 - a closed or exotic connection means "no file"
        return None
    return None


def settings_path(db):
    path = os.environ.get("LAL_LLM_CONFIG")
    if not path:
        folder = _database_dir(db)
        path = str(folder / "llm.json") if folder else ""
    return path


def _stamp(path):
    try:
        stat = os.stat(path)
        return (stat.st_mtime_ns, stat.st_size)
    except OSError:
        return None


def load_settings(db):
    """Read llm.json beside the save, then apply environment overrides."""
    settings = dict(DEFAULT_SETTINGS)
    path = settings_path(db)
    if path and Path(path).is_file():
        try:
            data = json.loads(Path(path).read_text(encoding="utf-8"))
            if isinstance(data, dict):
                settings.update({k: v for k, v in data.items() if k in DEFAULT_SETTINGS})
        except (OSError, ValueError):
            LOG.warning("llm.json could not be read; the guild AI uses templates")
    for key, env in ENV.items():
        if os.environ.get(env):
            settings[key] = os.environ[env]
    return settings


def ensure_tables(db):
    db.execute("""CREATE TABLE IF NOT EXISTS guild_ai_plan(owner_uid TEXT NOT NULL, kind TEXT NOT NULL,
        win INTEGER NOT NULL, payload TEXT NOT NULL, created INTEGER NOT NULL,
        PRIMARY KEY(owner_uid, kind, win))""")
    db.execute("""CREATE TABLE IF NOT EXISTS llm_usage(day TEXT PRIMARY KEY, calls INTEGER NOT NULL,
        input_tokens INTEGER NOT NULL, output_tokens INTEGER NOT NULL)""")


def urllib_transport(url, headers, body, timeout):
    request = urllib.request.Request(url, data=json.dumps(body).encode("utf-8"), headers=headers, method="POST")
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return json.loads(response.read().decode("utf-8"))


def parse_events(content, plan_hours):
    """Validate the model's JSON shape; game rules are checked at execution."""
    if not isinstance(content, str):
        return None
    text = content.strip()
    if text.startswith("```"):
        text = text.strip("`")
        text = text[text.find("{"):] if "{" in text else text
    start, end = text.find("{"), text.rfind("}")
    if start < 0 or end <= start:
        return None
    try:
        data = json.loads(text[start:end + 1])
    except ValueError:
        return None
    rows = data.get("events") if isinstance(data, dict) else None
    if not isinstance(rows, list):
        return None
    events = []
    for row in rows[:MAX_EVENTS]:
        if not isinstance(row, dict) or row.get("act") not in ACTIONS or not isinstance(row.get("uid"), str):
            continue
        try:
            hour = int(row.get("h", 0))
            tier = int(row.get("tier", 0) or 0)
        except (TypeError, ValueError):
            continue
        if not 0 <= hour < plan_hours:
            continue
        event = {"h": hour, "uid": row["uid"][:32], "act": row["act"], "tier": max(0, min(2, tier))}
        for key, limit in (("target", 32), ("name", 8)):
            if isinstance(row.get(key), str) and row[key]:
                event[key] = row[key][:limit]
        if row["act"] == "chat":
            event["text"] = guild_chat.clean_text(row.get("text"))
            if not event["text"]:
                continue
        events.append(event)
    events.sort(key=lambda e: e["h"])
    return events


class OpenAICompatible:
    """``POST {base_url}/chat/completions``: DeepSeek, Qwen, Kimi, Ollama, OpenAI..."""

    @staticmethod
    def request(settings, messages):
        body = {"model": settings.get("model"), "messages": messages,
                "temperature": float(settings.get("temperature", 0.9)),
                "max_tokens": int(settings.get("max_output_tokens", 2000))}
        if settings.get("json_mode", True):
            body["response_format"] = {"type": "json_object"}
        headers = {"Content-Type": "application/json",
                   "Authorization": "Bearer " + str(settings.get("api_key", "")).strip()}
        return str(settings.get("base_url", "")).rstrip("/") + "/chat/completions", headers, body

    @staticmethod
    def parse(response):
        usage = response.get("usage") if isinstance(response, dict) else None
        usage = usage if isinstance(usage, dict) else {}
        try:
            content = response["choices"][0]["message"]["content"]
        except (KeyError, IndexError, TypeError):
            content = None
        return content, int(usage.get("prompt_tokens", 0) or 0), int(usage.get("completion_tokens", 0) or 0)


class AnthropicMessages:
    """``POST {base_url}/v1/messages`` with the system prompt as a top-level field."""

    @staticmethod
    def request(settings, messages):
        system = "\n".join(m["content"] for m in messages if m["role"] == "system")
        body = {"model": settings.get("model"), "system": system,
                "messages": [m for m in messages if m["role"] != "system"],
                "temperature": min(1.0, float(settings.get("temperature", 0.9))),
                "max_tokens": int(settings.get("max_output_tokens", 2000))}
        headers = {"Content-Type": "application/json", "anthropic-version": "2023-06-01",
                   "x-api-key": str(settings.get("api_key", "")).strip()}
        base = str(settings.get("base_url", "")).rstrip("/")
        return (base if base.endswith("/v1") else base + "/v1") + "/messages", headers, body

    @staticmethod
    def parse(response):
        usage = response.get("usage") if isinstance(response, dict) else None
        usage = usage if isinstance(usage, dict) else {}
        blocks = response.get("content") if isinstance(response, dict) else None
        texts = [b.get("text", "") for b in blocks if isinstance(b, dict) and b.get("type") == "text"] \
            if isinstance(blocks, list) else []
        return ("".join(texts) or None), int(usage.get("input_tokens", 0) or 0), \
            int(usage.get("output_tokens", 0) or 0)


ADAPTERS = {"openai": OpenAICompatible, "anthropic": AnthropicMessages}


class GuildLLM:
    def __init__(self, store, settings=None, transport=None, threaded=True, plan_hours=6):
        self.store = store
        # Settings read from llm.json are re-read when the file changes, so the
        # Android settings screen (or an edited file on PC) applies without a restart.
        self._path = None if settings is not None else settings_path(store.db)
        self._stamp = _stamp(self._path) if self._path else None
        self.settings = settings if settings is not None else load_settings(store.db)
        self.transport = transport or urllib_transport
        self.threaded = threaded
        self.plan_hours = plan_hours
        self.jobs = queue.Queue()
        self.pending = set()
        self.calls = []
        self._thread = None
        self._guard = threading.Lock()

    @classmethod
    def for_store(cls, store):
        existing = getattr(store, "_guild_llm", None)
        if isinstance(existing, cls):
            return existing
        llm = cls(store)
        store._guild_llm = llm
        if llm.enabled():
            LOG.info("Guild AI model: enabled (%s)", llm.settings.get("model"))
        return llm

    def _reload_if_changed(self):
        if not self._path:
            return
        stamp = _stamp(self._path)
        if stamp != self._stamp:
            self._stamp = stamp
            self.settings = load_settings(self.store.db)
            LOG.info("Guild AI model settings reloaded: %s", "enabled" if self.enabled() else "templates only")

    def enabled(self):
        self._reload_if_changed()
        return bool(self.settings.get("enabled")) and bool(str(self.settings.get("api_key", "")).strip())

    def allows_player_text(self):
        return bool(self.settings.get("send_player_messages", True))

    # --------------------------------------------------------------- requests
    def request_plan(self, owner, window, snapshot):
        self._enqueue(("plan", str(owner), int(window), snapshot))

    def request_reply(self, owner, snapshot):
        self._enqueue(("reply", str(owner), int(self.store.clock.now()), snapshot))

    def _enqueue(self, job):
        key = job[:3]
        with self._guard:
            if key in self.pending:
                return
            self.pending.add(key)
        self.jobs.put(job)
        if self.threaded:
            with self._guard:
                if self._thread is None or not self._thread.is_alive():
                    self._thread = threading.Thread(target=self._run, name="guild-llm", daemon=True)
                    self._thread.start()

    def _run(self):
        while True:
            try:
                job = self.jobs.get(timeout=300)
            except queue.Empty:
                return
            self._process(job)

    def drain(self):
        """Process queued jobs on the calling thread (used by tests)."""
        while True:
            try:
                job = self.jobs.get_nowait()
            except queue.Empty:
                return
            self._process(job)

    # ---------------------------------------------------------------- budgets
    def _usage(self, day):
        with self.store.lock:
            ensure_tables(self.store.db)
            row = self.store.db.execute("SELECT calls,input_tokens,output_tokens FROM llm_usage WHERE day=?",
                                        (day,)).fetchone()
            self.store.db.commit()
        return row or (0, 0, 0)

    def _within_budget(self, day):
        now = time.monotonic()
        self.calls = [t for t in self.calls if now - t < 3600]
        if self.calls and now - self.calls[-1] < float(self.settings.get("min_interval_seconds", 60)):
            return False
        if len(self.calls) >= int(self.settings.get("max_calls_per_hour", 10)):
            return False
        calls, tokens_in, tokens_out = self._usage(day)
        return calls < int(self.settings.get("max_calls_per_day", 30)) and \
            tokens_in + tokens_out < int(self.settings.get("max_tokens_per_day", 60000))

    def _record_usage(self, day, usage):
        tokens_in = int(usage.get("prompt_tokens", 0) or 0) if isinstance(usage, dict) else 0
        tokens_out = int(usage.get("completion_tokens", 0) or 0) if isinstance(usage, dict) else 0
        with self.store.lock:
            ensure_tables(self.store.db)
            self.store.db.execute("""INSERT INTO llm_usage(day,calls,input_tokens,output_tokens) VALUES(?,1,?,?)
                ON CONFLICT(day) DO UPDATE SET calls=calls+1, input_tokens=input_tokens+excluded.input_tokens,
                output_tokens=output_tokens+excluded.output_tokens""", (day, tokens_in, tokens_out))
            self.store.db.commit()

    # ------------------------------------------------------------------- call
    def messages(self, kind, snapshot):
        extra = str(self.settings.get("system_prompt_extra", "") or "").strip()
        system = SYSTEM_PROMPT + ("\n" + extra if extra else "")
        if kind == "reply":
            instruction = ("真人玩家刚在公会频道发言。只安排1-3条chat事件回应他（h都填0），"
                           "由真人玩家所在公会的AI来说，不要安排其他动作。")
        else:
            instruction = "请为这个时间窗安排所有AI玩家的行为。"
        return [{"role": "system", "content": system},
                {"role": "user", "content": instruction + "\n" + json.dumps(snapshot, ensure_ascii=False)}]

    def _process(self, job):
        kind, owner, window, snapshot = job
        try:
            if not self.enabled():
                return
            day = game_day(self.store.clock.now())
            if not self._within_budget(day):
                return
            adapter = ADAPTERS.get(str(self.settings.get("protocol", "openai")), OpenAICompatible)
            url, headers, body = adapter.request(self.settings, self.messages(kind, snapshot))
            self.calls.append(time.monotonic())
            try:
                response = self.transport(url, headers, body, float(self.settings.get("timeout_seconds", 30)))
            except (urllib.error.URLError, OSError, ValueError) as error:
                LOG.warning("Guild AI model request failed (%s); using rule plans", type(error).__name__)
                return
            content, tokens_in, tokens_out = adapter.parse(response)
            self._record_usage(day, {"prompt_tokens": tokens_in, "completion_tokens": tokens_out})
            if content is None:
                LOG.warning("Guild AI model returned no message; using rule plans")
                return
            events = parse_events(content, self.plan_hours if kind == "plan" else 1)
            if events is None:
                LOG.warning("Guild AI model returned an invalid plan; using rule plans")
                return
            with self.store.lock:
                ensure_tables(self.store.db)
                self.store.db.execute("INSERT OR REPLACE INTO guild_ai_plan VALUES(?,?,?,?,?)",
                                      (owner, kind, window, json.dumps(events, ensure_ascii=False),
                                       int(self.store.clock.now())))
                self.store.db.commit()
        finally:
            with self._guard:
                self.pending.discard((kind, owner, window))

    # ------------------------------------------------------------------ reads
    # Called inside atomic_update: reads and deletes join the profile transaction.
    def take_plan(self, db, owner, window):
        ensure_tables(db)
        row = db.execute("SELECT payload FROM guild_ai_plan WHERE owner_uid=? AND kind='plan' AND win=?",
                         (str(owner), int(window))).fetchone()
        db.execute("DELETE FROM guild_ai_plan WHERE owner_uid=? AND kind='plan' AND win<=?",
                   (str(owner), int(window)))
        if not row:
            return None
        try:
            events = json.loads(row[0])
        except ValueError:
            return None
        return events if isinstance(events, list) else None

    def take_replies(self, db, owner):
        ensure_tables(db)
        rows = db.execute("SELECT payload FROM guild_ai_plan WHERE owner_uid=? AND kind='reply' ORDER BY win",
                          (str(owner),)).fetchall()
        db.execute("DELETE FROM guild_ai_plan WHERE owner_uid=? AND kind='reply'", (str(owner),))
        result = []
        for (payload,) in rows:
            try:
                events = json.loads(payload)
            except ValueError:
                continue
            if isinstance(events, list):
                result.append(events)
        return result
