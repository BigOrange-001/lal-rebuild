"""Relic award extension point (data/equipment implementation follows in phase 2)."""


def grant_boss_rewards(profile, run, node, cfg):
    # Reserve the exact rolls at settlement; phase 2 materializes these once.
    from roguelite_abyss import rng_for
    rng = rng_for(run['seed'], 'boss_reward', node['id'])
    base = [.2,.3,.5][node['act']-1]
    chance = round(base*(1+(run['difficulty']-1)/9),4)
    count = int(rng.random()<chance) + int(node['act']==3)
    for index in range(count):
        run['rewards'].append({'node_id':node['id'],'index':index,'pending_relic':True})
