"""Concrete hero offers for the native guild-currency exchange."""
from recruit_exchange import daily_orange_pool

ORDINARY_PRICE=1000
SKIN_PRICE=2*ORDINARY_PRICE


def apply_guild_exchange(document):
    cfg=document.get('cfg',document)
    from mod_policy import candidate_ids
    channel='acquisition.shop.guild'
    ordinary=daily_orange_pool(cfg,channel=channel,minimum=0)
    skins=candidate_ids(cfg,[aid for aid in cfg.get('system_simple',{}).get('skin_hero_ids',[])
                            if aid.endswith('_6') and aid in cfg.get('avatar',{})],channel)
    shop=cfg.setdefault('association_simple',{}).setdefault('guild_shop',{})
    shop.update(open_status=1,need_guild_lv=1)
    local=shop.setdefault('guild_shop',{})
    local['open']=1
    rows=local.setdefault('gift_info',{}).setdefault('guild_1',{})
    offer_ids=[]
    # Stable numeric IDs work with the native numeric sort and purchase API.
    for aid in ordinary+sorted(skins):
        index='10'+aid.split('_')[1]
        rows[index]=[[{'avatar':{aid:1}},{'guild_currency':SKIN_PRICE if aid in skins else ORDINARY_PRICE},1]]
        offer_ids.append(index)
    shop['hero_exchange_ids_105']=offer_ids
    return document
