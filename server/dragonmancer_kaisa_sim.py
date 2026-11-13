"""Kai'Sa's sequential missiles, reactive hunt and shared plasma in the study engine."""
from __future__ import annotations
import copy
from battle_engine import _to_int
from new_skin_bonds_104 import mechanic_value

class KaisaBattleMixin:
    def kaisa_is(self,unit):
        return bool(unit and self._config.get("avatar",{}).get(unit.get("aid"),{}).get("dragonmancerKaisa104"))

    def kaisa_lane(self,owner,lane):
        team=3-self._team_number(owner)
        units=[u for u in (self.a if team==1 else self.b) if u.get("hp",0)>0 and u.get("line")==lane]
        return sorted(units,key=lambda u:((u["pos"] if team==1 else -u["pos"]),self.state(u)["index"]))

    def kaisa_target(self,owner):
        if not self.kaisa_is(owner) or owner.get("_kaisa_clone") or not owner.get("leader") or not owner.get("skill") or owner.get("hp",0)<=0:return None
        open_lanes=self.kaisa_open_lanes()
        single=open_lanes=={owner.get('line')}
        return next((u for u in self.opponents(owner) if u.get('line') in open_lanes and (u.get("line")!=owner.get("line") or single)
                     and self.hero(u) and self._buff(u,"stun")),None)

    def kaisa_open_lanes(self):
        # The study engine has no GameMap.winnerList. Project completed lanes
        # from its contested starting lanes; native runtime reads winnerList.
        units=self.a+self.b
        for lane in {u.get('line') for u in units}:
            self._kaisa_lane_sides.setdefault(lane,{self._team_number(u) for u in units if u.get('line')==lane})
        active=set()
        for lane,sides in self._kaisa_lane_sides.items():
            live={self._team_number(u) for u in units if u.get('line')==lane and u.get('hp',0)>0}
            if sides=={1,2} and live!={1,2}:self._kaisa_closed_lanes.add(lane)
            if live and lane not in self._kaisa_closed_lanes:active.add(lane)
        return active

    def execute_kaisa(self,owner,kind,skill):
        if kind=="dragon_kaisa_p":return False
        if kind=="dragon_kaisa_c":return self.kaisa_hunt(owner)
        lane=owner["line"]
        if not self.kaisa_lane(owner,lane):return False
        count=3+2*owner.get("_kaisa_casts",0)
        owner["_kaisa_casts"]=owner.get("_kaisa_casts",0)+1
        coefficient=float(skill["skills"][0][4])
        visited=set()
        self._event("kaisa_volley",owner,missiles=count,lane=lane)
        for shot in range(count):
            if owner.get("hp",0)<=0:break
            live=self.kaisa_lane(owner,lane)
            if not live:break
            target=next((u for u in live if id(u) not in visited),None)
            if target is None:visited.clear();target=live[0]
            visited.add(id(target))
            # Independent contexts settle counters, kills and passive chains
            # before the next shot acquires its own current live target.
            with self.context(owner,"active",skill=skill):
                self._event("kaisa_missile",owner,target,index=shot)
                global_rate=float(self._config.get('system_simple',{}).get('hero_skill_output_rate_104',1))
                hit = self.hit(owner,target,coefficient/global_rate,2)
                sunder = mechanic_value(self._config, owner.get('_kaisa_root', owner), 'kaisa_q_sunder')
                if hit and owner.get('hp', 0)>0 and target.get('hp', 0)>0 and 0<sunder<1:
                    self.control(owner,target,'sunder',1,sunder/(1-sunder))
        return True

    def kaisa_hunt(self,owner):
        target=self.kaisa_target(owner)
        if target is None or owner.get("_kaisa_hunt_busy"):return False
        front=self.kaisa_lane(owner,target["line"])[0]
        old_line,old_pos=owner["line"],owner["pos"]
        owner["_kaisa_hunt_busy"]=True
        try:
            clone=self._spawn_summon(owner,owner["aid"],1,7,skill_level=owner.get("slv",1))
            if clone is None:raise ValueError("Kai'Sa clone could not be created")
            clone.update(_kaisa_clone=True,_kaisa_root=owner.get("_kaisa_root",owner),
                         _kaisa_casts=0,line=old_line,pos=old_pos,leader=False,
                         leader_skill=None,_skill_cd=0,range=owner.get("range",600),
                         speed=owner.get("speed",250))
            clone["skill"]=copy.deepcopy(owner.get("skill"))
            clone["skillB"]=copy.deepcopy(owner.get("skillB"))
            self.state(clone)
            for recipient in self.a+self.b:
                if recipient.get('hp',0)>0 and self._team_number(recipient)==self._team_number(owner) and (recipient is owner or recipient.get('_kaisa_root') is owner):
                    self._add_buff(recipient,'purify',3,source=owner)
                    self._add_buff(recipient,'shield',3,_to_int(recipient['hp_max']*.6),source=owner)
            destination=front["pos"]+(500 if self._team_number(owner)==1 else -500)
            self._reline(owner,target["line"],max(0,min(self._LINE_POS,destination)))
            self._event("kaisa_hunt",owner,target,clone=clone.get("_owner_token"),position=owner["pos"])
            self._apply_native_skill(owner,self.opponents(owner),"skill")
            return True
        finally:owner["_kaisa_hunt_busy"]=False

    def kaisa_try_hunt(self,owner):
        if self.kaisa_target(owner) is None or owner.get("_kaisa_hunt_busy"):return False
        skill=owner.get("leader_skill") or {}
        if not any(a[:2]==['manual_ability','dragon_kaisa_c'] for a in skill.get('skills',[])):return False
        if owner.get("_skill_cd_leader",(skill.get("pl") or [0])[0])>=0:return False
        return self._use_skill_slot(owner,self.opponents(owner),"leader_skill","_skill_cd_leader")

    def kaisa_stun(self,target):
        for owner in list(self.a+self.b):
            if owner is not target:self.kaisa_try_hunt(owner)

    def kaisa_event(self,owner,event,source,target):
        if event!="hit" or source is not owner or not self.kaisa_is(owner) or not target:return
        if not any(a[:2]==['manual_ability','dragon_kaisa_p'] for a in (owner.get('skillB') or {}).get('skills',[])):return
        ctx=self._context(owner)
        if not ctx or ctx["kind"] not in ("basic","active") or owner.get("_kaisa_plasma_busy"):return
        if target.get("hp",0)<=0 or self._team_number(owner)==self._team_number(target):return
        root=owner.get("_kaisa_root",owner)
        key=self.state(root)["index"]
        marks=target.setdefault("_kaisa_plasma",{})
        marks[key]=marks.get(key,0)+1
        self._event("kaisa_plasma",owner,target,stacks=marks[key])
        if marks[key]<5:return
        marks[key]-=5
        owner["_kaisa_plasma_busy"]=True
        try:
            self._add_buff(target,"curse",1,source=owner)
            # Fixed true damage enters after AP, armor, RPS and the old 0.3
            # true-AP coefficient; final mitigation, shields and revival apply.
            raw=_to_int(target["hp_max"]*.2)
            with self.context(owner,"passive"):
                self._event("kaisa_plasma_burst",owner,target,raw=raw)
                self._injured(target,self._final_direct_damage(raw,target,1),3,source=owner)
                if owner.get('hp',0)>0:self._injured(owner,_to_int(owner['hp_max']*.05),4,source=owner)
        finally:owner["_kaisa_plasma_busy"]=False
