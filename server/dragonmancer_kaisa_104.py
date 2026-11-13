"""Dragonmancer Kai'Sa: authored orange skin and final (unscaled) kit."""
from __future__ import annotations
import copy,hashlib,json
from pathlib import Path
AID="A_1801_6"
NORMAL="S_98618010_6"
CAPTAIN="S_98618011_6"
PASSIVE="S_98618013_6"
ROOT=Path(__file__).resolve().parents[1]
MEDIA=ROOT/"config/reconstruction/dragonmancer-kaisa-media"

def apply_dragonmancer_kaisa(document):
    cfg=document.get("cfg",document)
    if cfg.get("dragonmancer_kaisa_104"):return document
    if AID in cfg["avatar"]:raise ValueError("Kai'Sa identity already exists")
    # A current orange skin marksman, after all existing panel overlays.
    hero=copy.deepcopy(cfg["avatar"]["A_1206_6"])
    hero.update(id=AID,name="神龙尊者卡莎",res="MOD_DRAGON_KAISA104",
                stat_profile=1,hero_category_104="skin",dragonmancerKaisa104=True,skill_diff=0)
    hero["tl"][0]=1
    hero["tl"][8]=[]
    hero["tl"][9]=1+max(h["tl"][9] for k,h in cfg["avatar"].items() if k.startswith("A_1"))
    hero["pl"][10:14]=[NORMAL,CAPTAIN,hero["pl"][12],PASSIVE]
    hero["pl"][9]=850
    hero.pop("skin_revision_v2_104",None)
    hero["voiceDisabled104"]=True
    cfg["avatar"][AID]=hero
    # Kai'Sa supplies her own curved dragon missile; no legacy red projectile.
    cfg["effect"]["FX_KAISA_MISSILE104"]={}
    def row(sid,name,kind,warmup,cooldown,info,coefficient=None):
        action=["manual_ability",kind,1,"FX60_MAGIC"]
        if coefficient is not None:action.append(coefficient)
        return dict(id=sid,name=name,res="S_9004_6",pl=[warmup,cooldown,3001,0,0,0],
                    skill=[action],skillUp=None,info=info,rankInfoTemplate=info,
                    actionTargetPolicies=["ally_self"],actionTargetMaxTargets=[1],
                    dragonmancerKaisa104=True,calibration_104=True)
    q=row(NORMAL,"艾卡西亚暴雨","dragon_kaisa_n",0,1,
          "发射3发弹体，按前排到后排轮流分配给本路所有敌方单位，每发造成{rank:0:4}攻击力魔法伤害。每次施放后，之后的每次施放永久增加2发弹体，战斗内无叠加上限。每发独立索敌并结算死亡。",1)
    q["skillUp"]=[[0,4,1/9]]
    q['skill'][0][3]='FX_KAISA_MISSILE104'
    c=row(CAPTAIN,"狩猎本能","dragon_kaisa_c",0,3,
          "被动触发：其他路有敌方英雄处于眩晕且技能就绪时，在原位置留下继承自身100%实时面板的分身，持续7回合。仅剩一条未结束分路时，允许本路眩晕触发。先为自身与所有存活的自身分身附加净化及各自最大生命值60%的护盾，均持续3回合，再飞至目标路敌方最前排前方500距离处，额外施放一次艾卡西亚暴雨，不改变小技能冷却。分身具有同等级小技能和被动，导弹数独立叠加，不能触发队长技能。")
    p=row(PASSIVE,"引爆电浆","dragon_kaisa_p",0,0,
          "普通攻击与艾卡西亚暴雨每次命中，为目标叠加1层电浆。本体与自己的分身共享层数；达到5层时消耗5层电浆，对目标施加诅咒，造成目标最大生命值20%的真实伤害。每次引爆回复触发者自身最大生命值5%的生命。电浆引爆不再叠加电浆。")
    for skill in (q,c,p):cfg["skill"][skill["id"]]=skill
    skins=cfg["system_simple"].setdefault("skin_hero_ids",[])
    if AID not in skins:skins.append(AID)
    normal=cfg.get("summon_calibration",{}).get("normalization",{})
    normal["skin_hero_ids"]=sorted(set(normal.get("skin_hero_ids",[])+[AID]))
    for pool in ("advanced","vip"):
        cards=cfg["summon_calibration"]["pools"][pool]["qualities"]["orange"]["cards"]
        reference=next(x for x in cards if x["id"]=="A_1206_6")
        cards.append(dict(reference,id=AID,name=hero["name"]))
    media=json.loads((MEDIA/"manifest.json").read_text("utf-8"))
    cfg["builtin_assets_104"]["assets"].extend(copy.deepcopy(media["assets"]))
    cfg.setdefault("mod_runtime",{}).setdefault("assets",[]).extend(copy.deepcopy(media["assets"]))
    cfg["dragonmancer_kaisa_104"]={"id":AID,"panelSource":"A_1206_6",
        "skills":[NORMAL,CAPTAIN,PASSIVE],"media":media,"finalCoefficients":True}
    return document

def builtin_asset(cfg,digest,path):
    manifest=cfg.get("dragonmancer_kaisa_104",{}).get("media",{})
    if digest!=manifest.get("digest"):return None
    entry=next((e for e in manifest["assets"] if e["path"]==path),None)
    if not entry:raise ValueError("Unknown Kai'Sa asset")
    file=(MEDIA/path).resolve()
    if not file.is_relative_to(MEDIA.resolve()):raise ValueError("Invalid Kai'Sa media path")
    data=file.read_bytes()
    if hashlib.sha256(data).hexdigest()!=entry["sha256"]:raise ValueError("Kai'Sa media hash mismatch")
    return data,"image/png"
