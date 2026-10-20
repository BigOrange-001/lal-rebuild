"""Local single-player arena and fragment battles with persistent, one-shot intents."""
from __future__ import annotations
import copy, hashlib, json, math, time
import datetime
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path
from player_store import GameplayFault
from gameplay_common import grant_reward, game_day, equipment_exclusive_ids
from battle_intents import create_intent, consume_intent
from battle_engine import serialize_player_team, serialize_stage_team, validate_team_lane_coverage
from solo_progression import arena_equipment
from arena_opponents import POWER_ORDER_SCHEMA, combat_config_signature, generate_opponents
from arena_rewards import DAILY_RANK_MARK, DAILY_PAID_BATTLES, DAILY_BATTLE_MARK
from mod_policy import (runtime as mod_runtime, candidate_ids, channel_enabled,
                        effective_digest)

class GameplayCompetition:
    METHODS={"user.get_rank_list","user.refresh_pvp_opponents","user.get_fragment_users","user.get_battle_users","user.get_my_fragments","user.pk_combat_pvp","user.pk_combat_fragment","user.battle_finish","user.get_combat_playback"}
    DAILY_RANK_MARK=DAILY_RANK_MARK
    DAILY_PAID_BATTLES=DAILY_PAID_BATTLES
    DAILY_BATTLE_MARK=DAILY_BATTLE_MARK
    def __init__(self,store,full_config):
        self.store=store
        self.full_config=full_config if isinstance(full_config,dict) else {}
        self.cfg=self.full_config.get("cfg",self.full_config)
        path=Path(__file__).resolve().parents[1]/"config/reconstruction/competition-config.json"
        self.side=json.loads(path.read_text(encoding="utf-8")) if path.exists() else {}
        roster_path=Path(__file__).resolve().parents[1]/"config/reconstruction/roster-config.json"
        self.roster=json.loads(roster_path.read_text(encoding="utf-8")) if roster_path.exists() else {}
        self.simple=self.cfg.get("system_simple",{})
        self.heroes=self.cfg.get("avatar",self.roster.get("heroes",{}))
        self.equipment=self.cfg.get("equip") or self.roster.get("equipment",{})
        self.rules=self.side.get("rules",{})
        self.pvp_bots=self.side.get("pvp_bots",[])
        self.fragment_bots=self.side.get("fragment_bots",[])
        if mod_runtime(self.cfg):
            self.fragment_bots = self._filtered_bots(self.fragment_bots, "appearance.fragment_enemy")
            self.pvp_bots = self._filtered_bots(self.pvp_bots, "appearance.arena_enemy")

    def _filtered_bots(self, bots, channel):
        pool = candidate_ids(self.cfg, [], channel, include_new=True)
        result = []
        for index, original in enumerate(bots):
            bot = copy.deepcopy(original)
            entries = [row for row in bot.get("team", []) if isinstance(row, list) and row
                       and channel_enabled(self.cfg, row[0], channel)]
            if pool:
                # Deterministic candidate selection keeps preview/start stable.
                templates = [row for row in bot.get("team", []) if isinstance(row, list) and row]
                for slot, template in enumerate(templates[:5]):
                    if slot >= len(entries):
                        replacement = copy.deepcopy(template)
                        choices = [aid for aid in pool if aid.rsplit("_", 1)[0] not in
                                   {row[0].rsplit("_", 1)[0] for row in entries}]
                        if choices:
                            replacement[0] = choices[(index + slot) % len(choices)]
                            entries.append(replacement)
                if entries and index % (len(pool) + 1) < len(pool):
                    selected = pool[index % len(pool)]
                    if selected.rsplit("_", 1)[0] not in {row[0].rsplit("_", 1)[0] for row in entries}:
                        entries[-1][0] = selected
            if len(entries) >= 3:
                if entries != bot.get("team", []):
                    for slot, row in enumerate(entries):
                        if len(row) > 3:
                            row[3] = slot % 3
                bot["team"] = entries
                bot["mod_policy_digest"] = effective_digest(self.cfg)
                result.append(bot)
        return result
    @staticmethod
    def _fail(code,msg): raise GameplayFault(code,msg)
    @staticmethod
    def _num(v,name,lo=0,hi=10000000):
        if type(v) not in (int,float) or not math.isfinite(v) or v<lo or v>hi: GameplayCompetition._fail("InvalidParameter",f"Invalid {name}")
        return int(v)
    def _write(self,uid,method,params,change):
        action=params.get("actionID") if isinstance(params,dict) else None
        key=f"{method}:{action}" if isinstance(action,(str,int)) else None
        def mut(p):
            result=change(p)
            return p,result
        answer,replayed=self.store.atomic_update(uid,mut,idempotency_key=key,request_payload=params if key else None)
        if not isinstance(answer,dict): self._fail("StorageError","Invalid competition transaction result")
        answer["replayed"]=bool(replayed)
        return answer
    def dispatch(self,uid,method,params):
        if method not in self.METHODS: self._fail("NotImplemented",f"Competition method not reconstructed: {method}")
        if not isinstance(params,dict): self._fail("InvalidParameter","Expected an object")
        if method=="user.get_rank_list": return self._rank_list(uid)
        if method=="user.refresh_pvp_opponents": return self._refresh_pvp_opponents(uid,params)
        if method=="user.get_fragment_users": return self._fragment_users(uid)
        if method=="user.get_battle_users": return self._battle_users(uid,params)
        if method=="user.get_my_fragments": return self._my_fragments(uid)
        if method=="user.pk_combat_pvp": return self._start_pvp(uid,params)
        if method=="user.pk_combat_fragment": return self._start_fragment(uid,params)
        if method=="user.battle_finish": return self._finish(uid,params)
        if method=="user.get_combat_playback": return self._get_combat_playback(uid,params)
        self._fail("NotImplemented",method)

    def pvp_message_rows(self,uid):
        """Return native ItemPVPMsg rows for this player's retained local battles."""
        p=self.store.profile_raw(uid)
        records=p.get("records",{}) if isinstance(p.get("records"),dict) else {}
        reports=records.get("local_pvp_battle_reports",[])
        rows=[]
        for report in reports if isinstance(reports,list) else []:
            if not isinstance(report,dict) or not isinstance(report.get("cpb_id"),str): continue
            created=report.get("created")
            if type(created) is not int: continue
            users=report.get("users",{})
            user_b=users.get("user_b",[]) if isinstance(users,dict) else []
            opponent=user_b[2] if isinstance(user_b,(list,tuple)) and len(user_b)>2 else "竞技对手"
            if not isinstance(opponent,str) or not opponent:
                opponent="竞技对手"
            rows.append({
                "time":datetime.datetime.fromtimestamp(created,datetime.timezone.utc).replace(tzinfo=None),
                # 90097/90098 are shared result labels used by the award
                # panel. Keep them unchanged and use PvP-report-specific
                # templates which receive the native object-map fields.
                # ItemPVPMsg adds `data.date = row.time` before asking
                # GlobalLanguageStr to replace @opponent and the Date-valued
                # @date (formatted by Tools.dateFormat on the client).
                "mtype":98154 if report.get("sign")==1 else 98155,
                "data":{"cpb_id":report["cpb_id"],"opponent":opponent[:16]},
            })
        return rows

    def _get_combat_playback(self,uid,params):
        cpb_id=params.get("cpb_id")
        if not isinstance(cpb_id,str) or not cpb_id or len(cpb_id)>128:
            self._fail("InvalidBattleReport","A valid cpb_id is required")
        p=self.store.profile_raw(uid)
        records=p.get("records",{}) if isinstance(p.get("records"),dict) else {}
        reports=records.get("local_pvp_battle_reports",[])
        report=next((r for r in reports if isinstance(r,dict) and r.get("cpb_id")==cpb_id and r.get("kind")=="pvp"),None) if isinstance(reports,list) else None
        if report is None:
            self._fail("UnknownBattleReport","This local battle report is unavailable")
        # Native Game.loadFight -> GameMap.loadFight -> reSend -> initByOrgin
        # consumes these initial snapshots and seed to re-run the real client
        # combat algorithm. No server-side result or reward is applied here.
        return {
            "fight_id":cpb_id,
            "fight_kind":"pvp",
            "seed":int(report["seed"]),
            "metadata":copy.deepcopy(report.get("metadata",{})),
            "cid":"V_000_0",
            "def_th":int(report.get("def_th",0)),
            "orgin_team_a":copy.deepcopy(report["orgin_team_a"]),
            "orgin_team_b":copy.deepcopy(report["orgin_team_b"]),
            "team1":[],"team2":[],"sign":0,
            "users":copy.deepcopy(report["users"]),
            "my_pr_power":int(report.get("my_pr_power",0)),
            "pr_power":int(report.get("pr_power",0)),
            # A replay is presentation-only. Keep the native three-card shape
            # structurally valid, with no reward keys or redeemable value.
            "poke_data":{"gift_list":[{},{},{}],"poke_gift_index":0,"user_gift":{}},
        }
    def _attr(self,profile,iid):
        from gameplay_roster import GameplayRosterEquipment
        return GameplayRosterEquipment(self.store,self.full_config).battle_attributes(profile,iid)
    def _own_team(self,p,params):
        try:
            return serialize_player_team(self.cfg,p,params.get("team_num",0),params.get("team",[]),self._attr)
        except GameplayFault: raise
        except Exception as exc: raise GameplayFault("InvalidFormation",str(exc)) from exc
    def _bot(self,uid,fragment=False,profile=None):
        if fragment:
            return next((b for b in self.fragment_bots if b.get("uid")==uid),None)
        if str(uid).startswith("n"):
            records=profile.get("records",{}) if isinstance(profile,dict) else {}
            batch=records.get("pvp_opponents",{}) if isinstance(records,dict) else {}
            bots=batch.get("bots",[]) if isinstance(batch,dict) else []
            return next((b for b in bots if isinstance(b,dict) and b.get("uid")==uid),None)
        if uid=="r999999999_6_0":
            # PanelCenterPVP hardcodes this id for the first-match robot.
            # Its visual/team data comes from pvp_robot group 6, row 0.
            robot=self.side.get("pvp_robot",{}).get("6",{}).get("robot",[])
            if robot and isinstance(robot[0],list):
                row=robot[0]; level=int(row[0]) if row else 1
                team=[]
                for unit in row[1:]:
                    if isinstance(unit,list) and len(unit)>=10:
                        team.append([unit[0],int(unit[1]),int(unit[2]),int(unit[7]),float(unit[8]),1 if unit[9] else 0])
                if team:
                    return {"uid":uid,"rank":100,"name":"新手竞技试炼","lv":level,"group":999999999,"index":6,"team":team,"target_power":4000}
        bits=str(uid).split("_")
        if len(bits)<3 or not bits[0].startswith("r"): return None
        try: group,index=int(bits[1]),int(bits[2])
        except ValueError: return None
        return next((b for b in self.pvp_bots if int(b.get("group",-1))==group and int(b.get("index",-1))==index),None)
    def _bot_units(self,bot, *, fragment=False):
        fragment = fragment or any(row.get("uid") == (bot or {}).get("uid") for row in self.fragment_bots)
        if bot and isinstance(bot.get("units"),list):
            if mod_runtime(self.cfg):
                channel = "appearance.fragment_enemy" if fragment else "appearance.arena_enemy"
                for unit in bot["units"]:
                    if not channel_enabled(self.cfg, unit.get("base_aid", unit.get("aid")), channel):
                        self._fail("ModOpponentUnavailable", "缓存对手已被当前 Mod 策略排除，请重新生成对手")
            return copy.deepcopy(bot["units"])
        team=bot.get("team",[]) if bot else []
        if mod_runtime(self.cfg) and (bot or {}).get("mod_policy_digest") != effective_digest(self.cfg):
            filtered = self._filtered_bots([bot] if bot else [], "appearance.fragment_enemy" if fragment else "appearance.arena_enemy")
            if not filtered:
                self._fail("ModPoolEmpty", "对手没有足够的合法英雄")
            team = filtered[0]["team"]
        units=arena_equipment(self.full_config,bot or {},serialize_stage_team(self.cfg,team,team=2,scope="pveEnemy" if fragment else "arenaEnemy"))
        if not str((bot or {}).get("uid","")).startswith("r"):
            return units
        # Stable per-NPC traits keep preview, battle start and replay identical.
        phase_config=self.simple.get("phase_config",[])
        for index,unit in enumerate(units):
            aid=unit.get("aid","")
            try: star=int(aid.rsplit("_",1)[-1])
            except (TypeError,ValueError): continue
            if not aid.startswith("A_1") or star not in (5,6):
                continue
            digest=hashlib.sha256(f'{bot["uid"]}:progression:{index}'.encode()).digest()
            row=self.heroes.get(aid,{})
            pl=row.get("pl",[])
            if digest[2]<38:
                unit["limit_break"]=1
                # Strong arena bands can draw an actual post-breakthrough
                # level. The same stable NPC snapshot is used by the list,
                # battle start and retained replay.
                if int(bot.get("rank",999999))<=20 and len(pl)>=8:
                    old_level=int(unit["lv"])
                    new_level=max(old_level,100+digest[3]%26)
                    for key,slope in zip(("hp","ap","de_ph","de_ma"),(1,3,5,7)):
                        unit[key]=max(1,int(unit[key])+int(float(pl[slope])*(new_level-old_level)))
                    unit["hp_max"]=unit["hp"]
                    unit["lv"]=new_level
            phase=1+digest[1]%2 if digest[0]<64 else 0
            if phase:
                if len(pl)>=8:
                    if star==6:
                        bonus=[int((float(pl[i])+float(pl[i+1])*(int(unit["lv"])-1))*(1.12**phase-1)) for i in (0,2,4,6)]
                    else:
                        table=phase_config[0] if isinstance(phase_config,list) and phase_config else {}
                        spec=table.get(str(star),[]) if isinstance(table,dict) else []
                        extra_levels=int(spec[2])*phase if isinstance(spec,list) and len(spec)>2 else 0
                        bonus=[int(float(pl[i+1])*extra_levels) for i in (0,2,4,6)]
                    for key,extra in zip(("hp","ap","de_ph","de_ma"),bonus):
                        unit[key]=max(1,int(unit[key])+extra)
                    unit["hp_max"]=unit["hp"]
                    unit["phase"]=phase
        return units
    @staticmethod
    def _compact(units):
        return [[u.get("aid"),int(u.get("lv",1)),int(u.get("slv",1)),int(u.get("hp",0)),int(u.get("ap",0)),int(u.get("de_ph",0)),int(u.get("de_ma",0)),int(u.get("phase",0)),int(u.get("line",0)),float(u.get("pos",0)),u.get("talent"),int(u.get("morph",0)),int(u.get("limit_break",0))] for u in units]
    def _team_power(self, units):
        """Compute the finite battle-power value consumed by DoorLayer.

        Native DoorLayer reads ``my_pr_power``/``pr_power`` from the battle
        start response and passes both directly to number formatting. Reuse
        Avatar.getPower's documented stat weighting on the exact serialized
        team snapshots, including native power constants and skill factors.
        Talent uses the native additive term after the first floor, including
        both five-decimal rounding stages. The result also decides turn order;
        combat results remain client-authoritative.
        """
        power_cfg=self.simple.get("power",[]) if isinstance(self.simple,dict) else []
        if not isinstance(power_cfg,list) or len(power_cfg)<13:
            power_cfg=[1e-8,0.5,2,0.625,0.625,1000,0.1,0.1,0.5,0.01,2,0.1,0.1]
        def skill_factor(skill,super_skill=False,book=False,level=1):
            if not isinstance(skill,dict): return 0.0
            sid=skill.get("skid")
            if not isinstance(sid,str): return 0.0
            try: star=max(1,int(sid.split("_")[-1]))
            except (ValueError,IndexError): star=1
            lv=max(1,int(skill.get("slv",level) or level))
            if book:
                row=self.cfg.get("skill",{}).get(sid,{})
                actions=row.get("skill",[]) if isinstance(row,dict) else []
                if actions and isinstance(actions[0],(list,tuple)) and actions[0] and actions[0][0]=="equipup": return 0.0
                return star*float(power_cfg[11])+lv*float(power_cfg[12])
            if super_skill: return star*0.5
            return star*0.1+lv*0.1
        def talent_factor(talent):
            if isinstance(talent,dict): talent=talent.get("id")
            if not isinstance(talent,str) or talent not in self.cfg.get("talent",{}): return 0.0
            # TalentData.getStar reads the ID suffix, not its combat effect
            # percentage. Talent.getPower indexes talent_power[star - 2].
            try: index=int(talent.rsplit("_",1)[-1])-2
            except ValueError: return 0.0
            weights=self.simple.get("talent_power",[])
            if not isinstance(weights,list) or not 0<=index<len(weights): return 0.0
            try: factor=float(weights[index])
            except (TypeError,ValueError): return 0.0
            return factor if math.isfinite(factor) and factor >= 0 else 0.0
        def native_floor(value):
            rounded=Decimal(str(value)).quantize(Decimal("0.00001"),rounding=ROUND_HALF_UP)
            return math.floor(rounded)
        def finite_number(value):
            try:
                number = float(value)
                return number if math.isfinite(number) else 0.0
            except (TypeError, ValueError):
                return 0.0
        # These auras are added by Avatar's live getters rather than baked
        # into new_4attrs. Include the same initial living-team maximum in
        # the power projection without duplicating it in combat snapshots.
        team_bonus = {key: 0.0 for key in ('hit', 'flee', 'crit', 'tough')}
        for unit in units if isinstance(units, list) else []:
            if not isinstance(unit, dict) or finite_number(unit.get('hp', unit.get('hp_max', 0))) <= 0:
                continue
            tid = unit.get('talent')
            tid = tid.get('id') if isinstance(tid, dict) else tid
            talent = self.cfg.get('talent', {}).get(tid, {}) if isinstance(tid, str) else {}
            effect = str(talent.get('growth_effect') or '')
            if effect.startswith('team_') and effect[5:] in team_bonus:
                team_bonus[effect[5:]] = max(team_bonus[effect[5:]], finite_number(talent.get('growth_value', 0)))
        total=0
        for unit in units if isinstance(units,list) else []:
            if not isinstance(unit,dict): continue
            def number(value,default=0):
                try:
                    result=float(value)
                    return result if math.isfinite(result) else float(default)
                except (TypeError,ValueError): return float(default)
            hp=number(unit.get("hp_max",unit.get("hp")))
            ap=number(unit.get("ap")); de_ph=number(unit.get("de_ph")); de_ma=number(unit.get("de_ma"))
            tpl=unit.get("tpl",[]); tpl=tpl if isinstance(tpl,list) else []
            speed=number(tpl[3]) if len(tpl)>3 else 0
            reach=number(tpl[4]) if len(tpl)>4 else 0
            attrs=unit.get("new_4attrs",{}); attrs=attrs if isinstance(attrs,dict) else {}
            substats=sum(number(attrs.get(k)) + team_bonus[k] for k in ("hit","flee","crit","tough"))
            slv=max(1,int(unit.get("slv",1) or 1))
            book=unit.get("book_skill")
            multiplier=1.0+skill_factor(unit.get("skill"),level=slv)+skill_factor(unit.get("leader_skill"),True)+skill_factor(book,book=True,level=book.get("slv",1) if isinstance(book,dict) else 1)+skill_factor(unit.get("skillB"))
            weighted=hp*float(power_cfg[1])+ap*float(power_cfg[2])+de_ph*float(power_cfg[3])+de_ma*float(power_cfg[4])
            stat_multiplier=1.0+math.pow(max(0.0,substats),1.0/float(power_cfg[10]))*float(power_cfg[9]) if float(power_cfg[10])>0 else 1.0
            value=(weighted**2)*multiplier*(float(power_cfg[5])+speed+reach)*stat_multiplier*float(power_cfg[0])
            if math.isfinite(value) and value>0:
                value=native_floor(value)+value*talent_factor(unit.get("talent"))
                if math.isfinite(value) and value>0: total+=native_floor(value)
        return int(total)
    @staticmethod
    def _pvp_def_th(my_power, enemy_power):
        # Native GameMapRuntime uses def_th 0/1 as explicit team overrides.
        # Any other value invokes its native power comparison (>= favors team 1).
        if my_power == enemy_power:
            return 2
        return 1 if my_power > enemy_power else 0
    def _own_compact(self,p):
        index=max(0,min(int(p.get("attrs",{}).get("team_num",0)),len(p.get("team",[]))-1))
        ids=p.get("team",[[]])[index] if p.get("team") else []
        out=[]
        for slot,iid in enumerate(ids):
            if not iid or iid not in p.get("avatars",{}): continue
            raw=self._attr(p,iid); hero=p["avatars"][iid]
            out.append([raw["aid"],raw["lv"],raw["slv"],raw["hp"],raw["ap"],raw["de_ph"],raw["de_ma"],raw["phase"],slot%3,slot/6,raw["talent"],raw["morph"],int(hero.get("limit_break",0) or 0)])
        return out
    def _rank(self,p):
        attrs=p.setdefault("attrs",{}); records=p.setdefault("records",{})
        return max(1,int(records.get("current_rank",attrs.get("pvp_rank",self.rules.get("pvp_initial_rank",100)))))
    def _daily_rank_cfg(self):
        ploy=(self.cfg.get("ploy_system_simple") or {}) if isinstance(self.cfg,dict) else {}
        config=ploy.get("pvp_rank") if isinstance(ploy,dict) else None
        return config if isinstance(config,dict) else {}
    def _daily_rank_gifts(self,rank):
        bands=self._daily_rank_cfg().get("lv_range_gift",{})
        if not isinstance(bands,dict): return None
        for label,gifts in bands.items():
            parts=str(label).split("-",1)
            if len(parts)!=2: continue
            try: low,high=int(parts[0]),int(parts[1])
            except ValueError: continue
            if low<=rank<=high:
                if not isinstance(gifts,dict) or not gifts:
                    raise GameplayFault("InvalidRankReward",f"Empty local arena reward band {label}")
                allowed={"gold","coin","score","medal","mark","dust","dn_stone","box_key","culture_book","sp"}
                if any(k not in allowed or type(v) is not int or v<=0 for k,v in gifts.items()):
                    raise GameplayFault("InvalidRankReward",f"Invalid native mail gifts for rank band {label}")
                return {**gifts,"mark":self.DAILY_RANK_MARK}
        return None
    @staticmethod
    def _rank_day_marker(records,day):
        marker=records.get("local_pvp_rank_settled_days",[])
        if isinstance(marker,dict): return bool(marker.get(day))
        return isinstance(marker,list) and day in marker
    @staticmethod
    def _record_rank_day(records,day):
        marker=records.get("local_pvp_rank_settled_days",[])
        if not isinstance(marker,list): marker=list(marker) if isinstance(marker,dict) else []
        if day not in marker: marker.append(day)
        # Only yesterday can be settled, but retain a bounded audit trail.
        records["local_pvp_rank_settled_days"]=marker[-90:]
    def settle_daily_rank(self,uid,today_shanghai):
        """Mail yesterday's local NPC arena rank reward once on first login.

        The participation record is written only by a consumed local PvP
        battle. A mail request key closes the crash window between durable
        mail insertion and the profile settlement marker.
        """
        try:
            today=datetime.date.fromisoformat(str(today_shanghai))
            if today.isoformat()!=str(today_shanghai): raise ValueError
        except (TypeError,ValueError):
            raise GameplayFault("InvalidDate","today_shanghai must be YYYY-MM-DD")
        day=(today-datetime.timedelta(days=1)).isoformat()
        with self.store.lock:
            profile=self.store.profile_raw(uid)
            records=profile.setdefault("records",{})
            if not isinstance(records,dict): raise GameplayFault("InvalidProfile","records must be an object")
            if self._rank_day_marker(records,day):
                daily=records.get("local_pvp_rank_days",{})
                prior=daily.get(day) if isinstance(daily,dict) else None
                participated=isinstance(prior,dict) and prior.get("played") is True
                return {"settled_day":day,"participated":participated,"mail_id":None,"already_settled":True}
            daily=records.get("local_pvp_rank_days",{})
            entry=daily.get(day) if isinstance(daily,dict) else None
            if not isinstance(entry,dict) or entry.get("played") is not True:
                def mark_unplayed(p):
                    rec=p.setdefault("records",{}); self._record_rank_day(rec,day)
                    return p,{"settled_day":day,"participated":False,"mail_id":None,"already_settled":False}
                return self.store.atomic_update(uid,mark_unplayed)[0]
            rank=entry.get("rank")
            if type(rank) is not int or rank<1:
                raise GameplayFault("InvalidRankRecord","Stored local PvP rank is invalid")
            gifts=self._daily_rank_gifts(rank)
            if gifts is None:
                # Keep a real participation pending if no authored band covers
                # this rank; do not silently consume the reward opportunity.
                return {"settled_day":day,"participated":True,"rank":rank,"mail_id":None,"pending_config":True}
            account_row=self.store.db.execute("SELECT account FROM players WHERE uid=?",(str(uid),)).fetchone()
            if not account_row: raise GameplayFault("UnknownPlayer","Player does not exist")
            mail_id=self.store.send_mail(account_row[0],"本地竞技昨日排名奖励",gifts,f"local-pvp-rank:{uid}:{day}")
            def mark_settled(p):
                rec=p.setdefault("records",{}); self._record_rank_day(rec,day)
                return p,{"settled_day":day,"participated":True,"rank":rank,"mail_id":mail_id,"already_settled":False}
            return self.store.atomic_update(uid,mark_settled)[0]
    def _current_arena_team(self,profile):
        teams=profile.get("team",[])
        team_num=max(0,min(int(profile.get("attrs",{}).get("team_num",0)),len(teams)-1)) if teams else 0
        saved=teams[team_num] if teams else []
        submitted=[[iid,slot%3,.2 if slot<3 else .1] if iid else None
                   for slot,iid in enumerate(saved[:6])]
        return self._own_team(profile,{"team_num":team_num,"team":submitted})
    def _ensure_opponents(self,profile,uid,*,refresh=False):
        records=profile.setdefault("records",{})
        batch=records.get("pvp_opponents")
        combat_signature=combat_config_signature(self.cfg)
        if (not refresh and isinstance(batch,dict) and batch.get("player_rank")==self._rank(profile)
                and batch.get("power_order_schema")==POWER_ORDER_SCHEMA
                and batch.get("combat_config_sha256")==combat_signature
                and isinstance(batch.get("bots"),list) and len(batch["bots"])==9):
            return batch
        old_generation=max(0,int(records.get("pvp_opponent_generation",0) or 0))
        generation=old_generation+1 if refresh or old_generation else 1
        own=self._current_arena_team(profile)
        batch=generate_opponents(self.cfg,str(uid),generation,self._rank(profile),own,self._team_power,
                                 combat_signature=combat_signature)
        records["pvp_opponents"]=batch
        records["pvp_opponent_generation"]=generation
        return batch
    def _rank_list(self,uid):
        def change(profile):
            self._ensure_opponents(profile,uid)
            return profile,self._rank_payload(uid,profile)
        return self.store.atomic_update(uid,change)[0]
    def _rank_payload(self,uid,p):
        rank=self._rank(p)
        mark=p.get("mark",0)
        try: mark=max(0,int(mark))
        except (TypeError,ValueError): mark=0
        # Keep the native five fields and append this account's actual score;
        # ItemPVP uses its rank formula only for reconstructed NPC rows.
        selfrow=[rank,uid,p.get("name","玩家"),self._own_compact(p),p.get("lv",1),self.DAILY_RANK_MARK]
        bots=p.get("records",{}).get("pvp_opponents",{}).get("bots",[])
        rows=[]
        shown_uids={str(uid)}
        shown_ranks={rank}
        def append_bot(b):
            try:
                br=int(b.get("rank",0)); bid=str(b.get("uid",""))
                if br<1 or not bid or bid in shown_uids or br in shown_ranks:
                    return False
                units=self._bot_units(b)
                if not units:
                    return False
                compact=self._compact(units)
                if not compact:
                    return False
                rows.append([br,bid,str(b.get("name") or "竞技对手"),compact,b.get("lv",1),self.DAILY_RANK_MARK])
                shown_uids.add(bid); shown_ranks.add(br)
                return True
            except (GameplayFault,KeyError,IndexError,TypeError,ValueError):
                # A malformed local NPC has no valid rank-list entry or battle
                # target. Skip that row instead of rendering it as a duplicate.
                return False
        for b in bots:
            append_bot(b)
        records=p.get("records",{})
        # PanelCenterPVP.addList/getListData reads history entries as
        # [rank, uid, name] arrays. Older reconstructed profiles may contain
        # object rows, so normalize at the RPC boundary without losing them.
        history_uids=set(shown_uids)
        def history_rows(values):
            out=[]
            for row in values if isinstance(values,list) else []:
                if isinstance(row,(list,tuple)) and len(row)>=3:
                    try: hist_rank=int(row[0])
                    except (TypeError,ValueError): continue
                    hist_uid=str(row[1]); hist_name=str(row[2])
                    compact=row[3] if len(row)>3 and isinstance(row[3],list) else None
                    hist_lv=row[4] if len(row)>4 else None
                elif isinstance(row,dict) and row.get("uid") is not None:
                    try: hist_rank=int(row.get("rank",rank))
                    except (TypeError,ValueError): continue
                    hist_uid=str(row["uid"]); hist_name=str(row.get("name","竞技对手"))
                    compact=row.get("data") if isinstance(row.get("data"),list) else None
                    hist_lv=row.get("lv")
                else:
                    continue
                if hist_rank<1 or hist_uid in history_uids:
                    continue
                if compact is None:
                    bot=self._bot(hist_uid,profile=p)
                    if not bot: continue
                    try: compact=self._compact(self._bot_units(bot))
                    except (GameplayFault,KeyError,IndexError,TypeError,ValueError): continue
                    hist_lv=bot.get("lv",1)
                if not compact: continue
                out.append([hist_rank,hist_uid,hist_name,compact,hist_lv or 1,self.DAILY_RANK_MARK])
                history_uids.add(hist_uid)
            return sorted(out,key=lambda item:(item[0],item[1]))
        wins=history_rows(records.get("pvp_history_win",[])); losses=history_rows(records.get("pvp_history_loss",[]))
        today=game_day(self.store.clock.now())
        day_entry=records.get("local_pvp_rank_days",{}).get(today,{}) if isinstance(records.get("local_pvp_rank_days",{}),dict) else {}
        today_count=int(day_entry.get("count",0)) if isinstance(day_entry,dict) else 0
        return [rank,[selfrow],rows,wins,losses,int(p.get("mark",0)),today_count]
    def _refresh_pvp_opponents(self,uid,params):
        def change(profile):
            self._ensure_opponents(profile,uid,refresh=True)
            return {"rank_list":self._rank_payload(uid,profile)}
        return self._write(uid,"user.refresh_pvp_opponents",params,change)["rank_list"]
    def _fragment_state(self,p):
        frag=p.setdefault("fragment",{}).setdefault("equips",{})
        blocked=equipment_exclusive_ids(self.full_config)
        for eid in self.side.get("fragment_eids",[]):
            if eid not in blocked:
                frag.setdefault(eid,[0]*int(eid.rsplit("_",1)[-1]))
        return frag
    def _my_fragments(self,uid):
        p=self.store.profile_raw(uid)
        def mut(profile):
            fragments=self._fragment_state(profile)
            # Preserve any pre-policy balances in storage, but don't advertise
            # mail-only IDs as a new gameplay acquisition route.
            visible={eid:value for eid,value in fragments.items()
                     if eid not in equipment_exclusive_ids(self.full_config)}
            return profile,[{"equips":copy.deepcopy(visible)},{}]
        data,_=self.store.atomic_update(uid,mut)
        return data
    def _fragment_users(self,uid):
        p=self.store.profile_raw(uid); out=[]
        if mod_runtime(self.cfg) and not self.fragment_bots:
            self._fail("ModPoolEmpty", "掠夺敌人候选不足")
        for b in self.fragment_bots:
            out.append([b["uid"],b["name"],int(b["lv"]),int(b.get("vip_lv",0)),self._compact(self._bot_units(b, fragment=True))])
        return out
    def _battle_users(self,uid,params):
        users=params.get("users",[])
        if not isinstance(users,list) or len(users)>50: self._fail("InvalidParameter","users must be a short list")
        out={}
        p=self.store.profile_raw(uid)
        for row in users:
            if not isinstance(row,(list,tuple)) or not row or not isinstance(row[0],str): continue
            target=row[0]
            if target==uid:
                out[target]={"data":self._own_compact(p),"as_equips":p.get("as_equips",[]),"my_equips":p.get("my_equips",{})}
            else:
                bot=self._bot(target,profile=p) or self._bot(target,True)
                if bot:
                    out[target]={"data":self._compact(self._bot_units(bot)),"as_equips":[],"my_equips":{}}
                    continue
                histories=p.get("records",{})
                for key in ("pvp_history_win","pvp_history_loss"):
                    history=histories.get(key,[]) if isinstance(histories,dict) else []
                    found=next((entry for entry in history if isinstance(entry,list) and len(entry)>3
                                and entry[1]==target and isinstance(entry[3],list)),None)
                    if found:
                        out[target]={"data":copy.deepcopy(found[3]),"as_equips":[],"my_equips":{}}
                        break
        return out
    def _start(self,uid,params,kind):
        def mutate(profile):
            own=self._own_team(profile,params)
            if kind=="pvp":
                # Never enter a fight with persisted NPC skills from an older
                # client configuration. Existing intents replay from the
                # idempotency ledger before this mutator is invoked.
                self._ensure_opponents(profile,uid)
            target_uid=str(params.get("uid",""))
            bot=self._bot(target_uid,kind=="fragment",profile=profile)
            if not bot: self._fail("UnknownOpponent","Opponent is unavailable")
            if kind=="fragment":
                eid=str(params.get("eid","")); idx=self._num(params.get("fragment_index"),"fragment_index",0,63)
                if eid not in self.equipment: self._fail("UnknownEquipment","Fragment equipment is unavailable")
                if eid in equipment_exclusive_ids(self.full_config):
                    self._fail("ExclusiveEquipmentRestricted","This equipment is available only through authorized mail")
                frag=self._fragment_state(profile); values=frag.get(eid,[0]*max(1,int(eid.rsplit("_",1)[-1])))
                if not isinstance(values,list) or idx>=len(values): self._fail("InvalidFragment","Fragment index is outside the equipment piece set")
                if values[idx]>0: self._fail("FragmentOwned","You already have this fragment")
                if self._fragment_energy(profile)["energy"]<1:
                    self._fail("InsufficientFragmentEnergy","Not enough fragment raid energy")
                metadata={"uid":target_uid,"target_uid":target_uid,"eid":eid,"fragment_index":idx,
                          "team_num":self._num(params.get("team_num",0),"team_num",0,2)}
            else:
                requested_rank=self._num(params.get("rank",0),"rank",0,2_000_000_000)
                if target_uid=="r999999999_6_0":
                    first_rank=max(1,self._rank(profile)-1)
                    if (int(profile.get("attrs",{}).get("pvp_count",0))!=0
                            or requested_rank not in (0,first_rank,int(bot.get("rank",-1)))):
                        self._fail("InvalidOpponent","First-match robot is only available for the first arena battle")
                elif requested_rank==0 or requested_rank!=int(bot.get("rank",-1)):
                    self._fail("InvalidOpponent","Opponent rank does not match the selected robot")
                metadata={"uid":target_uid,"target_uid":target_uid,"rank":requested_rank,
                          "team_num":self._num(params.get("team_num",0),"team_num",0,2),
                          "opponent_name":str(bot.get("name") or "竞技对手"),"opponent_lv":int(bot.get("lv",1))}
            enemy=self._bot_units(bot, fragment=kind=="fragment")
            # GameMapManager takes the native lane count from pvp_line or
            # frag_line. Validate the exact snapshots persisted in the intent.
            map_rows=self.simple.get("frag_line" if kind=="fragment" else "pvp_line",[])
            map_row=map_rows[0] if isinstance(map_rows,list) and map_rows else None
            backgrounds=map_row[1] if isinstance(map_row,list) and len(map_row)>1 else None
            lane_count=len(backgrounds) if isinstance(backgrounds,list) else 0
            try:
                validate_team_lane_coverage(own,lane_count,"player formation")
            except ValueError as exc:
                raise GameplayFault("InvalidFormation",f"Every route needs a hero; this map requires at least {lane_count} heroes") from exc
            try:
                validate_team_lane_coverage(enemy,lane_count,"NPC formation")
            except ValueError as exc:
                raise GameplayFault("InvalidOpponent","NPC formation must cover every native route") from exc
            my_power=self._team_power(own)
            enemy_power=self._team_power(enemy)
            def_th=self._pvp_def_th(my_power,enemy_power) if kind=="pvp" else 0
            if kind=="fragment":
                self._spend_fragment_energy(profile)
            token=create_intent(profile,kind,metadata,own,enemy,int(self.rules.get("intent_ttl",3600)),now=self.store.clock.now(),config=self.cfg)
            if kind=="pvp":
                intent=profile["pending_battles"][kind][token["fight_id"]]
                intent["arena_my_pr_power"]=my_power
                intent["arena_pr_power"]=enemy_power
                intent["arena_def_th"]=def_th
            poke_currency="gold" if kind=="pvp" else "coin"
            poke_data={"gift_list":[{poke_currency:0},{poke_currency:0},{poke_currency:0}],"poke_gift_index":0,"user_gift":{poke_currency:0}}
            data={"fight_kind":kind,"fight_id":token["fight_id"],"seed":token["seed"],"metadata":metadata,"cid":"V_000_0" if kind=="pvp" else "V_001_0","def_th":def_th,"orgin_team_a":own,"orgin_team_b":enemy,"team1":[],"team2":[],"poke_data":poke_data,"sign":0,"my_pr_power":my_power,"pr_power":enemy_power,"attr_fragment_energy":profile.get("attrs",{}).get("fragment_energy"),"attr_fragment_energy_extra":profile.get("attrs",{}).get("fragment_energy_extra",0)}
            return profile,data
        answer,_=self.store.atomic_update(uid,mutate,idempotency_key=self._key("user.pk_combat_"+kind,params),request_payload=params if params.get("actionID") else None)
        return answer
    def _start_pvp(self,uid,params): return self._start(uid,params,"pvp")
    def _start_fragment(self,uid,params): return self._start(uid,params,"fragment")
    @staticmethod
    def _key(method,params):
        action=params.get("actionID")
        return f"{method}:{action}" if isinstance(action,(str,int)) else None
    def _date_seconds(self,value,default):
        if isinstance(value,dict): return int(value.get("$date",default))
        if isinstance(value,(int,float)): return int(value)
        return int(default)
    def _fragment_energy(self,p,now=None):
        now=int(self.store.clock.now() if now is None else now); attrs=p.setdefault("attrs",{})
        cap=int(self.simple.get("capacity_config",[self.rules.get("fragment_energy_cap",12),self.rules.get("fragment_regen_minutes",30)])[0]); minutes=int(self.simple.get("capacity_config",[12,30])[1])
        interval=max(60,minutes*60); last=self._date_seconds(attrs.get("fragment_energy"),now-cap*interval)
        count=max(0,(now-last)//interval)
        extra=max(0,int(attrs.get("fragment_energy_extra",0)))
        energy=min(count,cap)+extra if count>=cap else count
        return {"energy":int(energy),"cap":cap,"interval":interval,"last":last,"extra":extra,"now":now}
    def _spend_fragment_energy(self,p,now=None):
        state=self._fragment_energy(p,now); attrs=p.setdefault("attrs",{})
        if state["energy"]<1: self._fail("InsufficientFragmentEnergy","Not enough fragment raid energy")
        if state["energy"]>state["cap"] and state["extra"]:
            attrs["fragment_energy_extra"]=state["extra"]-1
        else:
            attrs["fragment_energy"]={"$date":state["last"]+state["interval"]}
    def _finish(self,uid,params):
        kind=params.get("fight_kind")
        if kind not in ("pvp","fragment"): self._fail("InvalidBattle","Unsupported competition battle kind")
        def change(p):
            intent=consume_intent(p,kind,params,metadata_keys=("target_uid","rank","eid","fragment_index","team_num"),now=self.store.clock.now(),config=self.cfg)
            sign=intent["sign"]; metadata=intent["metadata"]; now=self.store.clock.now()
            records=p.setdefault("records",{}); attrs=p.setdefault("attrs",{})
            if kind=="pvp":
                rank=self._rank(p); old_count=int(attrs.get("pvp_count",0)); win=sign==1
                if win:
                    target=int(metadata.get("rank",0))
                    if old_count == 0 or target == 0:
                        newrank=int(self.rules.get("pvp_first_win_rank", max(1,rank-50)))
                    else:
                        newrank=max(1,min(rank,target))
                else: newrank=rank
                attrs["pvp_count"]=old_count+1; attrs["pvp_rank"]=newrank; records["current_rank"]=newrank
                rank_days=records.setdefault("local_pvp_rank_days",{})
                if not isinstance(rank_days,dict): rank_days={}; records["local_pvp_rank_days"]=rank_days
                played_day=game_day(now)
                prior=rank_days.get(played_day,{})
                count=int(prior.get("count",0))+1 if isinstance(prior,dict) else 1
                rank_days[played_day]={"played":True,"rank":newrank,"count":count}
                cutoff=(datetime.date.fromisoformat(played_day)-datetime.timedelta(days=90)).isoformat()
                records["local_pvp_rank_days"]={d:v for d,v in rank_days.items() if isinstance(d,str) and d>=cutoff}
                key="pvp_history_win" if win else "pvp_history_loss"
                bot=self._bot(str(metadata["target_uid"]),profile=p)
                opponent_name=str(metadata.get("opponent_name") or
                                  (bot.get("name") if bot else "竞技对手"))
                opponent_lv=int(metadata.get("opponent_lv") or (bot.get("lv",1) if bot else 1))
                history_row=[max(1,int(metadata.get("rank",0))),str(metadata["target_uid"]),
                             opponent_name,self._compact(intent["team_b"]),opponent_lv]
                records[key]=([history_row]+list(records.get(key,[])))[:20]
                # Keep only the initial, server-issued intent snapshots. The
                # submitted ending snapshots are validation diagnostics and
                # must never become a replay's starting team.
                if kind=="pvp":
                    opening_keys=("arena_my_pr_power","arena_pr_power","arena_def_th")
                    has_opening=all(key in intent for key in opening_keys)
                    any_opening=any(key in intent for key in opening_keys)
                    if has_opening:
                        report_my_power=intent["arena_my_pr_power"]
                        report_enemy_power=intent["arena_pr_power"]
                        report_def_th=intent["arena_def_th"]
                        if any(type(value) is not int or value<0 for value in (report_my_power,report_enemy_power)) or type(report_def_th) is not int or report_def_th not in (0,1,2):
                            self._fail("InvalidBattleIntent","Stored PvP opening metadata is invalid")
                    elif any_opening:
                        self._fail("InvalidBattleIntent","Stored PvP opening metadata is incomplete")
                    else:
                        # Earlier intents started with def_th=0, which
                        # forced the opponent first; do not reinterpret them.
                        report_my_power=self._team_power(intent["team_a"])
                        report_enemy_power=self._team_power(intent["team_b"])
                        report_def_th=0
                    report={
                        "cpb_id":intent["fight_id"],"kind":"pvp","created":now,
                        "seed":int(intent["seed"]),"sign":sign,
                        "metadata":copy.deepcopy(metadata),
                        "orgin_team_a":copy.deepcopy(intent["team_a"]),
                        "orgin_team_b":copy.deepcopy(intent["team_b"]),
                        "users":{"user_a":[str(uid),int(rank),str(p.get("name","玩家"))],
                                 "user_b":[str(metadata["target_uid"]),int(metadata.get("rank",0)),opponent_name]},
                        "my_pr_power":report_my_power,
                        "pr_power":report_enemy_power,
                        "def_th":report_def_th,
                    }
                    reports=records.setdefault("local_pvp_battle_reports",[])
                    if not isinstance(reports,list): reports=[]
                    records["local_pvp_battle_reports"]=[report]+[r for r in reports if isinstance(r,dict) and r.get("cpb_id")!=report["cpb_id"]][:19]
                rewards=self.rules
                # The daily fight allowance is independent of yesterday's
                # rank mail. Every consumed fight counts, including a loss;
                # repeated or extra fights cannot mint more than 60,000 mark
                # in one Shanghai calendar day.
                mark=self.DAILY_BATTLE_MARK if count<=self.DAILY_PAID_BATTLES else 0
                gold=int(rewards.get("pvp_gold_win",100) if win else rewards.get("pvp_gold_loss",20)); exp=int(rewards.get("pvp_exp_win",10) if win else rewards.get("pvp_exp_loss",5))
                grant_reward(p,{"mark":mark,"gold":gold,"exp":exp},self.full_config)
                poke_data={"gift_list":[{"gold":gold},{"gold":gold},{"gold":gold}],"poke_gift_index":0,"user_gift":{"gold":gold}}
                data={"sign":sign,"fight_kind":kind,"records":records,"attrs":attrs,"gold":p.get("gold",0),"coin":p.get("coin",0),"score":p.get("score",0),"mark":p.get("mark",0),"medal":p.get("medal",0),"exp":p.get("exp",0),"lv":p.get("lv",1),"poke_data":poke_data,"get_avatars":{},"get_equips":{},"win_gift":{},"current_rank":newrank}
            else:
                win=sign==1; eid=metadata["eid"]; idx=int(metadata["fragment_index"]); frag=self._fragment_state(p); slots=frag.setdefault(eid,[0]*max(1,int(eid.rsplit("_",1)[-1])))
                get_fragment=bool(win and eid not in equipment_exclusive_ids(self.full_config) and slots[idx]<=0)
                if get_fragment: slots[idx]=1
                base=int(self.rules.get("fragment_exp_base",5))*max(1,int(p.get("lv",1)))
                exp=max(0,int(base*(1 if win else 0.5)))
                coin=int(self.rules.get("fragment_win_coin",25) if win else self.rules.get("fragment_loss_coin",5))
                grant_reward(p,{"coin":coin,"exp":exp},self.full_config)
                state=self._fragment_energy(p,now)
                poke_data={"gift_list":[{"coin":coin},{"coin":coin},{"coin":coin}],"poke_gift_index":0,"user_gift":{"coin":coin}}
                data={"sign":sign,"fight_kind":kind,"get_fragment":get_fragment,"the_fragment":slots,"fragment":{"equips":frag},"get_fragments":{"fragment":{eid:slots},"fragment_index":idx},"attr_fragment_energy":attrs.get("fragment_energy",{"$date":state["last"]}),"attr_fragment_energy_extra":attrs.get("fragment_energy_extra",0),"culture_book":attrs.get("culture_book",0),"coin":p.get("coin",0),"exp":p.get("exp",0),"lv":p.get("lv",1),"gold":p.get("gold",0),"score":p.get("score",0),"medal":p.get("medal",0),"mark":p.get("mark",0),"attrs":attrs,"records":records,"get_avatars":{},"get_equips":{},"energy":p.get("energy",{"$date":now}),"attr_energy_extra":attrs.get("energy_extra",0),"fragment_energy":attrs.get("fragment_energy",{"$date":state["last"]}),"fragment_energy_extra":attrs.get("fragment_energy_extra",0),"poke_data":poke_data}
            return p,data
        action=params.get("actionID"); key=f"user.battle_finish:{action}" if isinstance(action,(str,int)) else None
        result,replayed=self.store.atomic_update(uid,change,idempotency_key=key,request_payload=params if key else None)
        result.setdefault("fight_id",str(params.get("fight_id","")))
        result["replayed"]=bool(replayed)
        return result
