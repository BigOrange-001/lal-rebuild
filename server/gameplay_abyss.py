"""Transactional Abyss RPCs. All mode state is server-owned."""
import copy
import secrets

from battle_intents import create_intent, consume_intent
from hero_workshop import has_test_hero_units
from player_store import GameplayFault
from roguelite_abyss import (rules, normalize_account, unlocked_pool, hero_record,
    rng_for, generate_map, generate_enemies, generate_enemy_preview, is_skin,
    standard_team, candidates, public_run)


class GameplayAbyss:
    METHODS = {'user.abyss_'+name for name in
               ('query','start','route','combat','finish','choose','skip','rest','abandon',
                'refresh','relics','relic_equip','relic_unequip','relic_reroll')}

    def __init__(self, store, config):
        self.store, self.config = store, config
        self.cfg = config.get('cfg', config)

    def response(self, profile):
        from abyss_relics import relic_response
        account = normalize_account(profile, self.cfg)
        purple, orange, standalone = unlocked_pool(profile, self.cfg)
        return {**relic_response(profile),'abyss_account':copy.deepcopy(account),
                'abyss_run':public_run(profile.get('abyss_run'),profile,self.cfg),
                'unlocked':{'purple':purple,'orange':orange,'standalone_orange':standalone}}

    def dispatch(self, uid, method, params):
        if method == 'user.battle_finish' and params.get('fight_kind')=='abyss':
            method = 'user.abyss_finish'
        if method not in self.METHODS:
            raise GameplayFault('NotImplemented', '未知深渊回廊请求。')
        if not rules(self.cfg):
            raise GameplayFault('AbyssUnavailable', '深渊回廊配置暂不可用。')
        action = params.get('actionID')
        if not isinstance(action,str) or not 1<=len(action)<=180:
            raise GameplayFault('InvalidRequestKey', '请求编号无效。')
        def mutate(profile):
            normalize_account(profile, self.cfg)
            extra = self._mutate(profile, method, params)
            return profile, {**self.response(profile), **extra}
        data,replayed = self.store.atomic_update(uid,mutate,method+':'+action,params)
        return {**data, 'replayed':replayed}

    def _mutate(self, p, method, x):
        run = p.get('abyss_run')
        if isinstance(run,dict) and run.get('status') == 'active':
            battle=run.get('battle')
            if battle and battle.get('expires',0)<self.store.clock.now():
                p.setdefault('pending_battles',{}).setdefault('abyss',{}).pop(battle['fight_id'],None)
                run['battle']=None
            budget = rules(self.cfg)['difficulties'][run['difficulty']-1]['enemy_refreshes']
            run.setdefault('enemy_refresh_total',budget)
            run.setdefault('enemy_refreshes',budget)
            for node in run['map']:
                if not node['completed'] and not (run.get('battle') and node['id']==run['current_node']):
                    self._update_enemy_rules(run,node)
            run['rules_schema']=rules(self.cfg)['schema']
        if method.startswith('user.abyss_relic'):
            from abyss_relics import mutate_relic
            return mutate_relic(p,method,x,self.cfg)
        if method == 'user.abyss_query':
            return {}
        if method == 'user.abyss_start':
            if p.get('abyss_run',{}).get('status')=='active':
                raise GameplayFault('AbyssRunActive', '请先完成或放弃当前一局。')
            difficulty, deck = x.get('difficulty'), x.get('deck')
            if type(difficulty) is not int or not 1<=difficulty<=p['abyss_account']['max_difficulty']:
                raise GameplayFault('AbyssDifficultyLocked', '尚未解锁该难度。')
            if not isinstance(deck,str) or deck not in p['abyss_account']['decks']:
                raise GameplayFault('AbyssDeckLocked', '尚未解锁该起始卡组。')
            seed = x.get('seed', secrets.randbelow(2**31))
            if type(seed) is not int or not 0<=seed<2**31:
                raise GameplayFault('AbyssInvalidSeed', '地图种子无效。')
            plan = rules(self.cfg)
            aids = plan['decks'][deck]['members'][:]
            if deck == 'star':
                rng = rng_for(seed, 'star')
                if not plan['skin_purple']:
                    raise GameplayFault('AbyssUnavailable', '星裔卡组暂无可用英雄。')
                aids = [rng.choice(plan['skin_purple'])] + rng.sample(plan['initial_purple'],4)
            pool = {a.rsplit('_',1)[0]:hero_record(a,deck=='star' and i==0,cfg=self.cfg) for i,a in enumerate(aids)}
            nodes = generate_map(seed,difficulty,self.cfg)
            p['abyss_run'] = {'id':secrets.token_hex(12),'status':'active','seed':seed,
                'rules_schema':plan['schema'],'map_version':plan.get('map_version',1),
                'difficulty':difficulty,'deck':deck,'map':nodes,'current_node':None,
                'available_nodes':[n['id'] for n in nodes if n['act']==1 and n['layer']==1],
                'pool':pool,'retries':plan['difficulties'][difficulty-1]['retries'],
                'pending_choice':None,'battle':None,'rewards':[], 'attempt':0,
                'enemy_refresh_total':plan['difficulties'][difficulty-1]['enemy_refreshes'],
                'enemy_refreshes':plan['difficulties'][difficulty-1]['enemy_refreshes']}
            p.setdefault('pending_battles', {}).pop('abyss',None)
            return {}
        run = p.get('abyss_run')
        if not run or run.get('status')!='active':
            raise GameplayFault('AbyssNoRun', '当前没有进行中的深渊回廊。')
        if method=='user.abyss_abandon':
            run.update(status='abandoned',battle=None,pending_choice=None)
            p.setdefault('pending_battles',{}).pop('abyss',None)
            return {}
        if method=='user.abyss_finish':
            return self.finish(p,run,x)
        if method in ('user.abyss_choose','user.abyss_skip'):
            choice = run['pending_choice']
            if not choice:
                raise GameplayFault('AbyssNoChoice', '当前没有待选英雄。')
            selected = x.get('heroes')
            if method=='user.abyss_skip':
                pass  # Every offer, weak 6-pick-up-to-3 included, may be skipped.
            else:
                options = {hero['id']:hero for hero in choice['options']}
                if (not isinstance(selected,list) or not 1<=len(selected)<=choice['count'] or
                    any(not isinstance(a,str) or a not in options for a in selected) or
                    len(set(selected))!=len(selected) or len(run['pool'])+len(selected)>20):
                    raise GameplayFault('AbyssInvalidChoice', f"请选择1至{choice['count']}名不同的候选英雄。")
                for hid in selected: run['pool'][hid] = copy.deepcopy(options[hid])
            run['pending_choice'] = None
            return {}
        if run['pending_choice']:
            raise GameplayFault('AbyssChoicePending', '请先完成本次选人。')
        node = next((n for n in run['map'] if n['id']==run['current_node']),None)
        if method=='user.abyss_route':
            node_id = x.get('node_id')
            if run['battle'] or (node and not node['completed']):
                raise GameplayFault('AbyssNodePending', '请先完成当前节点。')
            if not isinstance(node_id,str) or node_id not in run['available_nodes']:
                raise GameplayFault('AbyssInvalidRoute', '不能前往该节点。')
            run['current_node'] = node_id
            run['available_nodes'] = []
            return {}
        if not node or node['completed']:
            raise GameplayFault('AbyssInvalidNode', '请先选择一个未完成节点。')
        if method=='user.abyss_refresh':
            if node['type']=='rest' or x.get('node_id')!=node['id']:
                raise GameplayFault('AbyssInvalidNode','只能刷新当前战斗节点的敌人。')
            if run['battle']:
                raise GameplayFault('AbyssBattlePending','请先结算已开始的战斗。')
            if run['enemy_refreshes']<=0:
                raise GameplayFault('AbyssRefreshEmpty','本局敌方刷新次数已用完。')
            previous = [u['aid'] for u in node['enemy_preview']]
            start = node.get('enemy_roll',0)+1
            for roll in range(start,start+32):
                node['enemy_roll']=roll
                preview=generate_enemy_preview(run['seed'],run['difficulty'],node,self.cfg)
                if [u['aid'] for u in preview]!=previous: break
            else:
                raise GameplayFault('AbyssRefreshUnavailable','当前敌人没有其他可用阵容。')
            node['enemy_preview']=preview
            node.pop('enemies',None)
            run['enemy_refreshes']-=1
            return {}
        if method=='user.abyss_rest':
            if node['type']!='rest':
                raise GameplayFault('AbyssInvalidNode', '当前节点不是休息处。')
            if x.get('option')=='leave':
                node['completed']=True
                run['available_nodes']=node['next'][:]
                return {}
            hid, option = x.get('hero_id'), x.get('option')
            hero = run['pool'].get(hid) if isinstance(hid,str) else None
            if not hero:
                raise GameplayFault('AbyssUnknownHero', '该英雄不在本局阵容池中。')
            skin = is_skin(hero['aid'],self.cfg)
            base_skill = rules(self.cfg)['skin_skill_level'] if skin else 5
            max_skill = rules(self.cfg)['skin_skill_level_max'] if skin else 10
            if option=='skill' and hero['slv']==base_skill:
                hero['slv'] = max_skill
            elif (option=='orange' and hero['quality']==5 and
                  hero['aid'][:-1]+'6' in unlocked_pool(p,self.cfg)[1]):
                hero.update(aid=hero['aid'][:-1]+'6',quality=6)
            else:
                raise GameplayFault('AbyssRestUnavailable', '该英雄不能进行此项提升。')
            node['completed'] = True
            run['available_nodes'] = node['next'][:]
            return {}
        if method=='user.abyss_combat':
            if node['type']=='rest':
                raise GameplayFault('AbyssInvalidNode', '休息处不能开战。')
            if run['battle']:
                pending = p.get('pending_battles',{}).get('abyss',{}).get(run['battle']['fight_id'])
                if pending and pending['expires']>=self.store.clock.now():
                    raise GameplayFault('AbyssBattlePending', '请先结算当前战斗或继续已保存战斗。')
                p.setdefault('pending_battles',{}).pop('abyss',None)
                run['battle']=None
                self._update_enemy_rules(run,node)
            formation = x.get('team')
            if not isinstance(formation,list) or not 1<=len(formation)<=5:
                raise GameplayFault('InvalidFormation', '请选择1至5名英雄并覆盖三路。')
            own = standard_team(self.cfg,run['pool'],formation)
            limit=rules(self.cfg)['player_skin_limits'][node['act']-1]
            if sum(is_skin(unit['aid'],self.cfg) for unit in own)>limit:
                raise GameplayFault('AbyssSkinLimit',f"第{node['act']}幕最多上阵{limit}名皮肤英雄。")
            if 'enemies' not in node:
                node['enemies']=generate_enemies(run['seed'],run['difficulty'],node,self.cfg)
            metadata = {'run_id':run['id'],'node_id':node['id']}
            intent = create_intent(p,'abyss',metadata,own,node['enemies'],now=self.store.clock.now(),config=self.config)
            # Combat RNG is deterministic per attempt; map/enemies/candidates
            # remain fixed independently of combat rolls.
            intent['seed'] = rng_for(run['seed'],'combat',node['id'],run['attempt']).randrange(1,2**31)
            p['pending_battles']['abyss'][intent['fight_id']]['seed'] = intent['seed']
            run['battle'] = {**intent, 'fight_kind':'abyss','metadata':metadata,
                'orgin_team_a':own,'orgin_team_b':copy.deepcopy(node['enemies']),
                'line':[3,1,1], 'is_pve':False, 'round_max':0,
                'expires':p['pending_battles']['abyss'][intent['fight_id']]['expires']}
            return copy.deepcopy(run['battle'])
        raise GameplayFault('NotImplemented','未知深渊回廊请求。')

    def _update_enemy_rules(self,run,node):
        schema=rules(self.cfg)['schema']
        if (node.get('enemy_rules_schema')!=schema
                or has_test_hero_units(self.cfg, node.get('enemy_preview', []))
                or has_test_hero_units(self.cfg, node.get('enemies', []))):
            node['enemy_preview']=(generate_enemy_preview(run['seed'],run['difficulty'],node,self.cfg)
                                   if node['type']!='rest' else [])
            node.pop('enemies',None)
            node['enemy_rules_schema']=schema

    def finish(self,p,run,x):
        # Older clients submit every historical summon, including dead/replaced
        # plants, soldiers and clones. These diagnostics are not a formation:
        # a long fight can legitimately exceed 30 entries on either side.
        # Keep a bounded legacy allowance; new clients send only the original
        # combatants. Every submitted health value still goes through validation.
        intent = consume_intent(p,'abyss',x,metadata_keys=('run_id','node_id'),
                                now=self.store.clock.now(),config=self.config,max_snapshot_units=4096)
        if (not run['battle'] or intent['fight_id']!=run['battle']['fight_id'] or
            intent['metadata']!={'run_id':run['id'],'node_id':run['current_node']}):
            raise GameplayFault('AbyssStaleBattle', '战斗与当前节点不匹配。')
        appeared = set(p['abyss_account']['appeared'])
        appeared.update(u['aid'] for u in intent['team_a'] if u['aid'].endswith('_5'))
        p['abyss_account']['appeared'] = sorted(appeared)
        run['battle'] = None
        run['attempt'] += 1
        if intent['sign']==2:
            if run['retries']>0: run['retries'] -= 1
            else: run['status'] = 'failed'
        else:
            node = next(n for n in run['map'] if n['id']==run['current_node'])
            node['completed'] = True
            run['available_nodes'] = node['next'][:]
            if node['type']=='boss':
                self.boss_rewards(p,run,node)
                if node['act']==3:
                    run['status'] = 'cleared'
                    cleared = p['abyss_account']['cleared']
                    p['abyss_account']['cleared'] = sorted(set(cleared+[run['difficulty']]))
                    normalize_account(p,self.cfg)
                else:
                    run['pending_choice']=candidates(p,run,node,self.cfg)
            else:
                run['pending_choice'] = candidates(p,run,node,self.cfg)
        return {'sign':intent['sign'],'fight_id':intent['fight_id'],'fight_kind':'abyss'}

    def boss_rewards(self,p,run,node):
        # The reward module is introduced in phase 2. Keep this explicit hook
        # so phase 1 has no placeholder items pretending to be usable relics.
        from abyss_relics import grant_boss_rewards
        grant_boss_rewards(p,run,node,self.cfg)
