"""Local guild management, contribution loops, and guild/world boss events."""
from __future__ import annotations
import copy, secrets, time
from datetime import datetime, timedelta, timezone
from gameplay_common import grant_reward, game_day
from player_store import GameplayFault
from battle_intents import create_intent, consume_intent

class GameplayGuildBoss:
    METHODS={
      'user.association_is','user.get_association_list','user.add_association','user.find_association','user.join_association','user.exit_association','user.modify_association','user.over_association','user.association_setup','user.association_setup_content','user.get_guild_log','user.guild_contribute_exchange','user.guild_worship','user.member_worship','user.get_association_worship_gold_info','user.get_association_worship_gold','user.assocication_guild_shop_buy','user.guild_graduate_skill_append','user.guild_graduate_skill_up','user.guild_graduate_skill_change','user.get_associationboss','user.attack_associationboss','user.get_association_boss_ranks','user.association_reborn','user.get_zoneboss','user.enter_zoneboss','user.attack_zoneboss','user.reborn','user.super_reborn','user.buy_attack_number','user.inspire_association_race','user.assocication_sever_shop_info','user.assocication_sever_shop_buy','user.assocication_sever_shop_refresh','user.apply_member','user.calcel_member','user.get_apply_info','user.association_rank_index','user.show_war_data','user.get_war_rank','user.get_fight_result','user.get_reward_data'
    }
    def __init__(self,store,config):
        self.store=store; self.full=config if isinstance(config,dict) else {}; self.cfg=self.full.get('cfg',self.full)
        self.simple=self.cfg.get('association_simple',{}); self.rules=self.full.get('guild_boss_reconstruction',{})
    def dispatch(self,uid,method,params):
        if method not in self.METHODS: raise GameplayFault('NotImplemented','Method not reconstructed: '+method)
        if not isinstance(params,dict): raise GameplayFault('InvalidRequest','Guild request must be an object')
        fn=getattr(self,'_'+method.split('.',1)[1],None)
        if fn is None: raise GameplayFault('NotImplemented','Guild method not implemented: '+method)
        key=f'{method}:{params["actionID"]}' if isinstance(params.get('actionID'),str) and params['actionID'] else None
        data,_=self.store.atomic_update(uid,lambda p: fn(p,params),key,params)
        return data
    @staticmethod
    def _me(p): return {'uid':str(p.get('uid','local')),'zone':p.get('zone','1-01'),'name':p.get('name','测试玩家'),'lv':int(p.get('lv',1)),'vip_lv':int(p.get('vip_lv',0)),'vip_exp':int(p.get('vip_exp',0)),'power':0}
    def _guild(self,p,create=False):
        guild=p.setdefault('association',{})
        if create and not guild.get('id'):
            me=self._me(p); uid_text=str(me['uid']); uid_num=int(uid_text) if uid_text.isdigit() else sum(ord(ch) for ch in uid_text); gid=str(10000+(uid_num%80000))
            members=[]
            for i in range(6): members.append({'uid':f'npc-{gid}-{i+1}','zone':'local','name':['守望者','远征者','星火','小队长','旅人','影刃'][i],'lv':max(1,int(p.get('lv',1))-i),'vip_lv':0,'association_lv':3,'contribute':(6-i)*100,'power':10000*(6-i),'status':1,'worship_info':{'member_worship_count':0,'member_worship_user_list':[],'member_worship_day':game_day(self.store.clock.now())}})
            members.insert(0,{**me,'association_lv':0,'contribute':int(p.get('attrs',{}).get('guild_contribute',0)),'status':1,'worship_info':{'member_worship_count':0,'member_worship_user_list':[],'member_worship_day':game_day(self.store.clock.now())}})
            guild.update({'id':gid,'name':'本地守望者','icon':0,'level':1,'exp':0,'total_alive':0,'notice':'欢迎加入本地公会','created':int(self.store.clock.now()),'members':members,'guild_graduate_skill_list':[],'boss':{},'logs':[],'shop':{},'fund':0})
            attrs=p.setdefault('attrs',{}); attrs.setdefault('association_gold',0); attrs.setdefault('guild_graduate_skill',{}); attrs.update({'association_id':gid,'association_lv':0,'guild_contribute':int(attrs.get('guild_contribute',0))})
        return guild if guild.get('id') else None
    def _guild_response(self,p,flag=1,user_extra=None):
        g=self._guild(p); me=self._me(p); attrs=p.setdefault('attrs',{})
        if not g: return {'flag':0,'info':{'info':self._guild_suggestions(p)},'user':{**me,'association_gold':int(attrs.get('association_gold',0))}}
        self._update_guild_level(g)
        level_cfg=self.simple.get('guild_level',{}).get(f"level_{int(g.get('level',1))}",{})
        rec=self._day_record(p)
        leader=next((m for m in g.get('members',[]) if int(m.get('association_lv',3))==0),None)
        assoc={'id':g['id'],'name':g['name'],'icon':g['icon'],'level':g['level'],'exp':g['exp'],'total_alive':g['total_alive'],'notice':g['notice'],'content':g['notice'],'association_application':0,'guild_shop_level':int(level_cfg.get('guild_shop_level',1)),'guild_graduate_skill_list':g['guild_graduate_skill_list'],'create_time':{'$date':g['created']},'leader_uid':str((leader or (g.get('members') or [{}])[0]).get('uid',''))}
        members=self._guild_member_rows(g,p)
        # PanelGuildBase.addListGuildPanel replaces every member row's
        # worship_info with this user-level object. ItemGuildPanel then reads
        # member_worship_user_list to decide which member cards are already
        # worshipped by this player. Supply that native field, derived from
        # each member's persisted worshiper list.
        worshiped_members=[str(member['uid']) for member in members
            if isinstance(member.get('worship_info'),dict)
            and me['uid'] in member['worship_info'].get('member_worship_user_list',[])]
        user={'uid':me['uid'],'gold':p.get('gold',0),'coin':p.get('coin',0),'vip_lv':p.get('vip_lv',0),'vip_exp':p.get('vip_exp',0),'attrs':copy.deepcopy(attrs),'guild_contribute':attrs.get('guild_contribute',0),'association_gold':attrs.get('association_gold',0),'guild_contribute_exchange_normal_count':int(rec.get('normal_exchange_count',0)),'guild_contribute_exchange_expert_count':int(rec.get('expert_exchange_count',0)),'worship_info':{'guild_worship_count':self._daily_record(p,'guild_worship_count'),'guild_worship_free_count':self._daily_record(p,'guild_worship_free_count'),'member_worship_count':self._daily_record(p,'member_worship_count'),'member_worship_user_list':worshiped_members},'guild_worship_count':self._daily_record(p,'guild_worship_count'),'association_worship_gold':int(attrs.get('association_worship_gold',0)),'join_flag':False,'exit_flag':False}
        return {'flag':flag,'association_info':assoc,'member_list':members,'user':{**me,**user,**(user_extra or {})},'logs':copy.deepcopy(g.get('logs',[])),'guild_boss':copy.deepcopy(g.get('boss',{}))}
    def _guild_member_rows(self,g,p=None):
        """Return renderer-safe member rows and refresh the current user's snapshot."""
        today=game_day(self.store.clock.now()); rows=[]
        me=self._me(p) if isinstance(p,dict) else None
        attrs=p.get('attrs',{}) if isinstance(p,dict) else {}
        for source in g.get('members',[]):
            if not isinstance(source,dict):continue
            member=copy.deepcopy(source)
            if me and str(member.get('uid',''))==me['uid'] and str(member.get('zone',''))==me['zone']:
                # Guild membership is stored on the profile as a snapshot.
                # Keep the player's visible level/name/VIP current without
                # disturbing the guild role or other members' authored rows.
                member.update({key:me[key] for key in ('uid','zone','name','lv','vip_lv','vip_exp')})
                member['association_lv']=int(attrs.get('association_lv',member.get('association_lv',3)))
                member['contribute']=int(attrs.get('guild_contribute',member.get('contribute',0)))
            info=member.get('worship_info')
            if not isinstance(info,dict):info={}
            if info.get('member_worship_day')!=today:
                info.update({'member_worship_day':today,'member_worship_count':0,'member_worship_user_list':[]})
            count=info.get('member_worship_count',0)
            if type(count) is not int or count<0:count=0
            users=info.get('member_worship_user_list')
            if not isinstance(users,list):users=[]
            info.update({'member_worship_count':count,'member_worship_user_list':users})
            member['worship_info']=info
            rows.append(member)
        g['members']=rows
        return rows
    def _guild_suggestions(self, p=None):
        """NPC guild cards in the exact shape consumed by ItemGuild.

        join_type follows the native button branches: 0 is closed, 1 requires
        an application, and 2 is an open guild. These are local-only NPC guilds;
        no request is attributed to a fabricated player.
        """
        rows = []
        applications = (p or {}).get("records", {}).get("guild_applications", {})
        if not isinstance(applications, dict): applications = {}
        guild_levels = self.simple.get("guild_level", {})
        for i, name in enumerate(("晨星盟·本地NPC", "远征者·本地NPC", "青铜守卫·本地NPC")):
            guild_id = str(10001 + i)
            level = i + 1
            level_row = guild_levels.get(f"level_{level}", {}) if isinstance(guild_levels, dict) else {}
            join_type = (1, 2, 0)[i]
            application = applications.get(guild_id)
            rows.append({
                "id": guild_id,
                "name": name,
                "icon": i,
                "level": level,
                "member_count": 6 + i,
                "max_member": int(level_row.get("max_member_length", 22 + 2 * (level - 1))),
                "max_num": int(level_row.get("max_member_length", 22 + 2 * (level - 1))),
                "member_num": 6 + i,
                "total_alive": 10000 * (i + 1),
                "content": "本地单人模拟公会，由NPC成员组成",
                "notice": "本地单人模拟公会，由NPC成员组成",
                "join_level_limit": 1,
                "join_type": join_type,
                "flag": int(isinstance(application, dict) and application.get("status") == "pending"),
                "power": 100000 * (i + 1),
            })
        return rows
    @staticmethod
    def _daily_record(p,key):
        record=p.setdefault('records',{}).setdefault('guild_daily',{})
        if record.get('day')!=game_day(self.store.clock.now()): record.clear(); record['day']=game_day(self.store.clock.now())
        return int(record.get(key,0))
    def _update_guild_level(self,g):
        rows=self.simple.get('guild_level',{}); level=max(1,int(g.get('level',1)))
        for i in range(1,11):
            row=rows.get(f'level_{i}',{})
            if int(g.get('total_alive',0))>=int(row.get('flourishing',10**18)): level=i
        g['level']=level
        return level
    def _association_is(self,p,x): return p,self._guild_response(p,1 if self._guild(p) else 0)
    def _get_association_list(self,p,x): return p,{'info':self._guild_suggestions(p)}
    def _find_association(self,p,x):
        query=str(x.get('id','')); rows=[g for g in self._guild_suggestions(p) if g['id']==query]
        return p,{'info':rows}
    def _add_association(self,p,x):
        if self._guild(p): return p,{'res_code':-1,'user_dict':self._wallet(p)}
        name=str(x.get('name','')).strip(); flag=int(x.get('flag',0)); cost=int(self.simple.get('the_guild_info',{}).get('create_gold' if flag==0 else 'create_coin',1000 if flag==0 else 100))
        if not 2<=len(name)<=8 or any(c in name for c in '*\\/'): raise GameplayFault('InvalidGuildName','Guild name must contain 2 to 8 safe characters')
        resource='gold' if flag==0 else 'coin'
        if int(p.get(resource,0))<cost: raise GameplayFault('InsufficientResource','Not enough '+resource)
        p[resource]-=cost; g=self._guild(p,True); g['name']=name; g['icon']=int(x.get('icon',0))
        p.setdefault('records',{}).pop('guild_applications',None)
        return p,{'res_code':1,'user_dict':self._wallet(p)}
    def _join_association(self,p,x):
        # This RPC is the guild-manager action from ItemGuildApply (approve or
        # reject a specific applicant), not the player's join button. Local
        # NPC guilds do not synthesize incoming human applications, so an
        # unknown uid must never create a guild or produce a success response.
        guild=self._guild(p)
        uid=str(x.get('uid','')); zone=str(x.get('zone',''))
        applications=guild.get('applications',[]) if guild else []
        match=next((entry for entry in applications if isinstance(entry,dict)
                    and str(entry.get('uid',''))==uid
                    and str(entry.get('zone',''))==zone),None)
        if not guild or not uid or match is None:
            return p,{'res_code':-1}
        # No current local flow creates applications. Even if an imported
        # legacy/custom applicant exists, approval cannot mutate that other
        # account in this local-only server; report the native failure rather
        # than claiming the remote user was admitted.
        if int(x.get('flag',-1)) == 0:
            applications.remove(match)
            guild['applications']=applications
            return p,{'res_code':1,'association_info':{'association_application':len(applications)}}
        return p,{'res_code':-2}
    def _exit_association(self,p,x):
        p['association']={}; p.setdefault('attrs',{}).update({'association_id':'','association_lv':0})
        p.setdefault('records',{}).pop('guild_applications',None)
        # ItemGuildPanel only leaves its guild view on res_code == 1.
        return p,{'res_code':1,'flag':0,'user':self._wallet(p)}
    def _modify_association(self,p,x):
        g=self._guild(p)
        if not g: return p,{'res_code':-1}
        try: num=int(x.get('num',x.get('association_lv',-99)))
        except (TypeError,ValueError): return p,{'res_code':-2}
        if num not in (-1,0,1,3): return p,{'res_code':-2}
        uid=str(x.get('uid','')); zone=str(x.get('zone',''))
        me=self._me(p); attrs=p.setdefault('attrs',{})
        actor=next((m for m in g.get('members',[]) if str(m.get('uid'))==me['uid'] and str(m.get('zone',''))==str(me['zone'])),None)
        target=next((m for m in g.get('members',[]) if str(m.get('uid'))==uid and str(m.get('zone',''))==zone),None)
        if actor is None or target is None or actor is target or int(actor.get('association_lv',3))!=int(attrs.get('association_lv',3)):
            return p,{'res_code':-1}
        actor_rank=int(actor.get('association_lv',3)); target_rank=int(target.get('association_lv',3))
        if actor_rank not in (0,1): return p,{'res_code':-2}
        # The original UI permits a vice leader to remove a non-leader only;
        # all appointments, demotions and transfers are leader-only.
        if actor_rank==1 and num!=-1: return p,{'res_code':-2}
        if num==-1:
            if target_rank==0: return p,{'res_code':-2}
            g['members'].remove(target)
        elif num==0:
            if actor_rank!=0 or target_rank==0: return p,{'res_code':-2}
            actor['association_lv']=3
            target['association_lv']=0
            attrs['association_lv']=3
        elif num==1:
            if actor_rank!=0 or target_rank==1 or any(int(m.get('association_lv',3))==1 and m is not target for m in g['members']):
                return p,{'res_code':-2}
            target['association_lv']=1
        else:  # num == 3: remove an officer position, retaining ordinary membership.
            if actor_rank!=0 or target_rank==0: return p,{'res_code':-2}
            target['association_lv']=3
        response=self._guild_response(p)
        response.update({'res_code':1,'uid':uid,'zone':zone,'num':num,
                         'user_dict':self._wallet(p),'attrs':copy.deepcopy(attrs)})
        return p,response
    def _association_setup(self,p,x):
        g=self._guild(p)
        if not g: raise GameplayFault('NoGuild','Join a guild first')
        if 'icon' in x:g['icon']=int(x['icon'])
        if 'content' in x:g['notice']=str(x['content'])[:100]
        return p,self._guild_response(p)
    def _association_setup_content(self,p,x): return self._association_setup(p,x)
    def _over_association(self,p,x): return self._exit_association(p,x)
    def _get_guild_log(self,p,x):
        g=self._guild(p)
        if not g:return p,{'res_code':-1,'association_log':[],'logs':[],'info':[]}
        logs=copy.deepcopy(g.get('logs',[]))
        return p,{'res_code':1,'association_log':logs,'logs':copy.deepcopy(logs),'info':copy.deepcopy(logs)}
    def _append_guild_log(self,g,text):
        """Store one real guild action in the native [Date, text] log format."""
        logs=g.setdefault('logs',[])
        if not isinstance(logs,list):
            logs=[]
            g['logs']=logs
        logs.insert(0,[{'$date':int(self._now())},str(text)[:240]])
        del logs[100:]
    def _wallet(self,p): return {'gold':p.get('gold',0),'coin':p.get('coin',0),'vip_lv':p.get('vip_lv',0),'vip_exp':p.get('vip_exp',0),'attrs':p.get('attrs',{})}
    @staticmethod
    def _user_reward_fields(p):
        attrs=p.get('attrs',{}); fields={'new_avatars':{},'new_avatar_soul':{},'new_equips':{},'new_equip_soul':{},'new_fragments':{}}
        for key in ('box_key','dust','dn_stone','culture_book','sp','energy_extra','fragment_energy','fragment_energy_extra'):
            if key in attrs: fields[key]=attrs[key]
        for key in ('score','medal','mark','energy'):
            if key in p: fields[key]=p[key]
        return fields
    def _guild_contribute_exchange(self,p,x):
        g=self._guild(p)
        if not g: raise GameplayFault('NoGuild','Join a guild first')
        key=str(x.get('exchange_id','1')); row=self.simple.get('guild_contribute_info',{}).get('exchange_cost_info',{}).get(key)
        if not row: raise GameplayFault('InvalidExchange','Unknown contribution exchange')
        rec=self._day_record(p); expert=int(row.get('type',0))==1
        count_key='expert_exchange_count' if expert else 'normal_exchange_count'; client_key='expert' if expert else 'normal'
        limit=int(self.simple.get('guild_contribute_info',{}).get('exchange_count_info',{}).get(str(int(p.get('vip_lv',0))),{}).get(client_key,0))
        if int(rec.get(count_key,0))>=limit: raise GameplayFault('DailyLimit','Contribution exchange limit reached')
        cost=int(row['cost']); contrib=int(row['contribute']); currency='coin' if expert else 'gold'
        if int(p.get(currency,0))<cost: raise GameplayFault('InsufficientResource','Not enough '+currency)
        p[currency]-=cost; rec[count_key]=int(rec.get(count_key,0))+1
        p.setdefault('attrs',{})['guild_contribute']=int(p['attrs'].get('guild_contribute',0))+contrib
        g['members'][0]['contribute']=p['attrs']['guild_contribute']
        self._append_guild_log(g,f"{self._me(p)['name']}兑换公会贡献{contrib}")
        return p,{'res_code':1,'guild_contribute':p['attrs']['guild_contribute'],'gold':p['gold'],'coin':p.get('coin',0),'vip_exp':p.get('vip_exp',0),'vip_lv':p.get('vip_lv',0),'attrs':p['attrs'],'guild_contribute_exchange_normal_count':int(rec.get('normal_exchange_count',0)),'guild_contribute_exchange_expert_count':int(rec.get('expert_exchange_count',0)),'data':{'guild_contribute':p['attrs']['guild_contribute']}}
    def _guild_worship(self,p,x):
        g=self._guild(p)
        if not g: raise GameplayFault('NoGuild','Join a guild first')
        typ=max(0,min(2,int(x.get('type',0))))
        rec=self._day_record(p)
        count=int(rec.get('guild_worship_count',0)); limit=int(self.simple.get('guild_worship_times',3))
        if count>=limit: raise GameplayFault('DailyLimit','Guild worship limit reached')
        options=self.simple.get('guild_worship',[[0,5,'free'],[10,10,'coin'],[100,20,'coin']])
        option=options[typ] if typ<len(options) else options[0]
        cost=int(option[0]); amount=int(option[1]); currency=str(option[2]) if len(option)>2 else 'free'
        if typ==0 and int(rec.get('guild_worship_free_count',0))>=int(self.simple.get('guild_worship_free_daily_limit',1)):
            raise GameplayFault('DailyLimit','Free guild worship is already claimed today')
        if currency in ('coin','gold'):
            if int(p.get(currency,0))<cost: raise GameplayFault('InsufficientResource','Not enough '+currency)
            p[currency]=int(p.get(currency,0))-cost
        rec['guild_worship_count']=count+1
        currency_reward=(int(self.simple.get('guild_worship_currency_reward',option[3] if len(option)>3 else 0)) if typ==0 else 0)
        if currency_reward<0: raise GameplayFault('InvalidReward','Guild worship currency reward cannot be negative')
        if typ==0: rec['guild_worship_free_count']=int(rec.get('guild_worship_free_count',0))+1
        g['total_alive']+=amount
        attrs=p.setdefault('attrs',{}); attrs['guild_contribute']=int(attrs.get('guild_contribute',0))+amount*2
        attrs['association_worship_gold']=int(attrs.get('association_worship_gold',0))+amount*10
        if currency_reward:
            # The client wallet is attrs.association_gold. Keep one canonical
            # reward representation so the currency cannot be counted twice.
            grant_reward(p,{'attrs':{'association_gold':currency_reward}},self.full)
        self._append_guild_log(g,f"{self._me(p)['name']}完成公会供奉，增加活跃{amount}及公会币{currency_reward}")
        self._update_guild_level(g)
        data=self._guild_response(p)
        data['res_code']=1
        data['user'].update(self._wallet(p)); data['user']['worship_info']['guild_worship_count']=count+1
        data['user']['worship_info']['guild_worship_free_count']=int(rec.get('guild_worship_free_count',0))
        data['user']['guild_worship_count']=count+1
        data['user']['association_gold']=int(attrs.get('association_gold',0))
        data['user']['guild_currency_reward']=currency_reward
        data['association']={'level':g['level'],'total_alive':g['total_alive']}
        data['guild_currency_reward']=currency_reward
        return p,data
    def _member_worship(self,p,x):
        g=self._guild(p)
        if not g: raise GameplayFault('NoGuild','Join a guild first')
        target=str(x.get('target_uid',''))
        target_member=next((member for member in g['members'] if str(member.get('uid'))==target),None)
        if not target or target_member is None:
            raise GameplayFault('UnknownMember','Choose a current guild member')
        rec=self._day_record(p); count=int(rec.get('member_worship_count',0))
        if count>=int(self.simple.get('member_worship_times',5)):
            raise GameplayFault('DailyLimit','Member worship limit reached')
        typ=max(0,min(2,int(x.get('type',0))))
        options=self.simple.get('member_worship',[[5,0,'free'],[10,10,'gold'],[20,100,'coin']])
        option=options[typ] if typ<len(options) else options[0]
        cost=int(option[0]); amount=int(option[1]) if len(option)>1 else 0
        currency=str(option[2]) if len(option)>2 else ('gold' if typ==1 else 'coin')
        if currency in ('coin','gold'):
            if int(p.get(currency,0))<cost: raise GameplayFault('InsufficientResource','Not enough '+currency)
            p[currency]=int(p.get(currency,0))-cost
        rec['member_worship_count']=count+1
        target_info=target_member.get('worship_info')
        if not isinstance(target_info,dict):target_info={}
        today=game_day(self.store.clock.now())
        if target_info.get('member_worship_day')!=today:
            target_info.update({'member_worship_day':today,'member_worship_count':0,'member_worship_user_list':[]})
        worshipers=target_info.get('member_worship_user_list')
        if not isinstance(worshipers,list):worshipers=[]
        actor_uid=str(p.get('uid',''))
        if actor_uid in worshipers:
            raise GameplayFault('AlreadyWorshipped','You already worshipped this guild member today')
        worshipers.append(actor_uid)
        target_info['member_worship_count']=len(worshipers)
        target_info['member_worship_user_list']=worshipers
        target_member['worship_info']=target_info
        attrs=p.setdefault('attrs',{}); stamp=p.get('energy',{'$date':int(self.store.clock.now())}); stamp=int(stamp.get('$date',int(self.store.clock.now()))) if isinstance(stamp,dict) else int(self.store.clock.now())
        cfg=self.cfg.get('system_simple',{}).get('energy_config',[100,0,5,130])
        max_energy=min(int(cfg[3]) if len(cfg)>3 else int(cfg[0]),int(cfg[0])+int(p.get('lv',1)*cfg[1] if len(cfg)>1 else 0))+int(attrs.get('energy_extra',0))
        interval=max(1,int(cfg[2]) if len(cfg)>2 else 5)*60; now=int(self.store.clock.now())
        current=min(max_energy,max(0,(now-stamp)//interval)); gained=min(amount,max(0,max_energy-current))
        new_energy=current+gained; p['energy']={'$date':max(0,stamp-gained*interval)}
        self._append_guild_log(g,f"{self._me(p)['name']}供奉了公会成员{target}")
        user_dict={'energy':copy.deepcopy(p['energy']),'energy_extra':attrs.get('energy_extra',0),**self._wallet(p)}
        return p,{'res_code':1,'user_dict':user_dict,'target_uid':target}
    def _get_association_worship_gold_info(self,p,x):
        self._guild(p); attrs=p.setdefault('attrs',{})
        return p,{'res_code':1,'association_worship_gold':int(attrs.get('association_worship_gold',0)),'member_worship_count':self._daily_record(p,'member_worship_count')}
    def _get_association_worship_gold(self,p,x):
        attrs=p.setdefault('attrs',{}); amount=int(attrs.get('association_worship_gold',0))
        if amount<=0: raise GameplayFault('NoWorshipGold','There is no worship gold to collect')
        attrs['association_worship_gold']=0; p['gold']=int(p.get('gold',0))+amount
        return p,{'res_code':1,'association_worship_gold':0,'user':{'gold':p['gold']}}
    def _assocication_guild_shop_buy(self,p,x):
        g=self._guild(p)
        if not g: raise GameplayFault('NoGuild','Join a guild first')
        index=str(x.get('index',''))
        level=min(5,max(1,int(g.get('level',1))))
        shop=self.simple.get('guild_shop',{}).get('guild_shop',{}).get('gift_info',{})
        rowset=shop.get(f'guild_{level}',shop.get(str(level),{}))
        rows=rowset.get(index)
        if not rows and index.isdigit():
            for group in shop.values():
                if isinstance(group,dict) and index in group:
                    rows=group[index]; break
        if not isinstance(rows,list) or not rows or not isinstance(rows[0],list) or len(rows[0])<2:
            raise GameplayFault('InvalidShopItem','Unknown guild shop item')
        reward,pay=rows[0][0],rows[0][1]
        bought=int(g.setdefault('shop',{}).get(index,0))
        if bought>=1: raise GameplayFault('DailyLimit','This guild shop item has already been purchased')
        need_lv=int(rows[0][2]) if len(rows[0])>2 else 1
        if int(g.get('level',1))<need_lv: raise GameplayFault('GuildLevelRequired','Guild level too low')
        if not isinstance(reward,dict) or not isinstance(pay,dict) or len(pay)!=1:
            raise GameplayFault('InvalidShopItem','Malformed guild shop entry')
        currency,price=next(iter(pay.items())); price=int(price)
        if currency=='guild_currency':
            attrs=p.setdefault('attrs',{}); wallet=int(attrs.get('association_gold',0))
            if wallet<price: raise GameplayFault('InsufficientResource','Not enough guild currency')
            attrs['association_gold']=wallet-price
        elif currency in ('gold','coin'):
            if int(p.get(currency,0))<price: raise GameplayFault('InsufficientResource','Not enough '+currency)
            p[currency]=int(p.get(currency,0))-price
        else: raise GameplayFault('InvalidShopItem','Unsupported shop currency')
        grant_reward(p,reward,self.full); g['shop'][index]=bought+1
        self._append_guild_log(g,f"{self._me(p)['name']}购买了公会商店商品")
        return p,{'res_code':1,'association_gold':p.get('attrs',{}).get('association_gold',0),'gold':p.get('gold',0),'coin':p.get('coin',0),'lv':p.get('lv',1),'exp':p.get('exp',0),'vip_exp':p.get('vip_exp',0),'vip_lv':p.get('vip_lv',0),'attrs':p.get('attrs',{}),'avatars':p.get('avatars',{}),'my_equips':p.get('my_equips',{}),'guild_shop_info':[[str(k),v] for k,v in sorted(g.get('shop',{}).items())],**self._user_reward_fields(p)}
    def _guild_graduate_skill_append(self,p,x):
        g=self._guild(p)
        if not g: raise GameplayFault('NoGuild','Join a guild first')
        sid=str(x.get('skill_id','')); skills=self.simple.get('guild_graduate',{}).get('guild_graduate_skill',{})
        if sid not in skills: raise GameplayFault('UnknownSkill','Unknown guild research')
        if sid not in g['guild_graduate_skill_list']: g['guild_graduate_skill_list'].append(sid)
        self._append_guild_log(g,f"{self._me(p)['name']}完成公会技能研究")
        # ItemResearshSkill reads param1.data.guild_graduate_skill_list;
        # the RPC transport already wraps this returned dict as param1.data.
        rows=copy.deepcopy(g['guild_graduate_skill_list'])
        return p,{'res_code':1,'guild_graduate_skill_list':rows,'association_info':{'guild_graduate_skill_list':rows}}
    def _guild_graduate_skill_up(self,p,x):
        sid=str(x.get('skill_id','')); skills=self.simple.get('guild_graduate',{}).get('guild_graduate_skill',{})
        cfg=skills.get(sid)
        if not cfg: raise GameplayFault('UnknownSkill','Unknown guild research')
        if int(p.get('lv',1)) < 1: raise GameplayFault('LevelRequired','Player level too low')
        learned=p.setdefault('attrs',{}).setdefault('guild_graduate_skill',{}); current=int(learned.get(sid,0)); nxt=current+1
        level_cfg=cfg.get('level',{}).get(str(nxt))
        if not level_cfg: raise GameplayFault('SkillMaxLevel','Research is already at maximum level')
        cost=int(level_cfg.get('up_demand',0)); contrib=int(p['attrs'].get('guild_contribute',0))
        if contrib<cost: raise GameplayFault('InsufficientContribution','Not enough guild contribution')
        p['attrs']['guild_contribute']=contrib-cost; learned[sid]=nxt
        guild=self._guild(p)
        if guild:self._append_guild_log(guild,f"{self._me(p)['name']}提升了公会技能")
        user_data={'guild_graduate_skill':copy.deepcopy(learned),'guild_contribute':p['attrs']['guild_contribute']}
        return p,{'data':{'user_data':user_data},'attrs':p['attrs'],'user_data':user_data}
    def _guild_graduate_skill_change(self,p,x):
        # PanelGuildSkillReplace indexes change_skill_cost by source level.
        # Reconstructed local semantics: unchecked/type 0 replaces at one
        # level lower (level 1 is free); checked/type 1 keeps the level and
        # charges coin. The source confirms the two paths and the level index,
        # while exact production costs/level-loss were not recoverable.
        g=self._guild(p)
        if not g: raise GameplayFault('NoGuild','Join a guild first')
        old_id=str(x.get('skill_id_1','')); new_id=str(x.get('skill_id_2',''))
        try: kind=int(x.get('type',0))
        except (TypeError,ValueError): raise GameplayFault('InvalidRequest','Invalid replacement type')
        if kind not in (0,1): raise GameplayFault('InvalidRequest','Invalid replacement type')
        skills=self.simple.get('guild_graduate',{}).get('guild_graduate_skill',{})
        if old_id not in skills or new_id not in skills:
            raise GameplayFault('UnknownSkill','Unknown guild skill')
        if old_id==new_id:
            raise GameplayFault('InvalidSkillReplacement','Choose a different researched skill')
        attrs=p.setdefault('attrs',{})
        learned=attrs.setdefault('guild_graduate_skill',{})
        if not isinstance(learned,dict):
            raise GameplayFault('InvalidSkillState','Guild skill state is invalid')
        level=int(learned.get(old_id,0))
        if level<1:
            raise GameplayFault('UnknownLearnedSkill','The source skill is not learned')
        if new_id not in g.get('guild_graduate_skill_list',[]):
            raise GameplayFault('SkillNotResearched','Research the target skill first')
        price_cfg=self.simple.get('guild_graduate',{}).get('change_skill_cost',{})
        try: cost=int(price_cfg[str(level)])
        except (KeyError,TypeError,ValueError):
            raise GameplayFault('InvalidSkillCost','Skill replacement price is not configured for this level')
        if kind==0:
            if level>1:
                currency='guild_contribute'; wallet=int(attrs.get(currency,0))
            else:
                currency=None; wallet=0
            target_level=max(1,level-1)
        else:
            if level<=1:
                raise GameplayFault('InvalidSkillReplacement','Level 1 skill cannot use level-preserving replacement')
            currency='coin'; wallet=int(p.get(currency,0))
            target_level=level
        if str(target_level) not in skills[new_id].get('level',{}):
            raise GameplayFault('SkillMaxLevel','Target skill does not support the replacement level')
        if new_id in learned:
            # Never overwrite or silently lower an already learned target.
            raise GameplayFault('SkillAlreadyLearned','Target skill is already learned')
        if cost<0: raise GameplayFault('InvalidSkillCost','Skill replacement cost is invalid')
        if currency is not None:
            if wallet<cost:
                raise GameplayFault('InsufficientContribution' if kind==0 else 'InsufficientResource',
                                    'Not enough guild contribution' if kind==0 else 'Not enough coin')
            if kind==0: attrs[currency]=wallet-cost
            else: p[currency]=wallet-cost
        del learned[old_id]
        learned[new_id]=target_level
        self._append_guild_log(g,f"{self._me(p)['name']}调整了公会技能")
        user_data={'coin':int(p.get('coin',0)),'gold':int(p.get('gold',0)),
                   'vip_exp':int(p.get('vip_exp',0)),'vip_lv':int(p.get('vip_lv',0)),
                   'guild_graduate_skill':copy.deepcopy(learned),
                   'guild_contribute':int(attrs.get('guild_contribute',0))}
        return p,{'res_code':1,'user_data':user_data,'attrs':copy.deepcopy(attrs)}
    def _day_record(self,p):
        records=p.setdefault('records',{}).setdefault('guild_daily',{})
        today=game_day(self.store.clock.now())
        if records.get('day')!=today: records.clear(); records['day']=today
        return records
    def _assocication_sever_shop_info(self,p,x):
        g=self._guild(p)
        if not g: return p,{'res_code':-1}
        shop=self.simple.get('guild_shop',{}).get('sever_shop',{}).get('gift_info',{})
        purchased=g.setdefault('shop',{})
        entries=[]
        for group_id in map(str,range(5)):
            group=shop.get(group_id,{})
            if isinstance(group,dict) and group:
                item_id=sorted(group,key=lambda v:int(v) if str(v).isdigit() else str(v))[0]
                count=int(purchased.get(f'server:{group_id}:{item_id}',0))
                entries.append({'index':str(item_id),'total_count':1,'user_count':count,'can_buy':count<1})
        return p,{'res_code':1,'sever_shop_info':entries,'guild_shop_info':[[str(i),int(v)] for i,v in sorted(purchased.items()) if not str(i).startswith('server:')],'guild_shop_refresh_count':int(g.get('refresh_count',0))}
    def _assocication_sever_shop_buy(self,p,x):
        g=self._guild(p)
        if not g: raise GameplayFault('NoGuild','Join a guild first')
        group=str(x.get('index_1','')); item=str(x.get('index_2',''))
        row=self.simple.get('guild_shop',{}).get('sever_shop',{}).get('gift_info',{}).get(group,{}).get(item)
        if not row or not isinstance(row[0],list): raise GameplayFault('InvalidShopItem','Unknown guild server shop item')
        key=f'server:{group}:{item}'; bought=int(g.setdefault('shop',{}).get(key,0))
        if bought>=1: raise GameplayFault('DailyLimit','This server shop item has already been purchased')
        reward,pay=row[0][0],row[0][1]
        if not isinstance(pay,dict) or len(pay)!=1: raise GameplayFault('InvalidShopItem','Malformed shop payment')
        currency,price=next(iter(pay.items())); price=int(price)
        if currency=='guild_currency':
            attrs=p.setdefault('attrs',{}); current=int(attrs.get('association_gold',0))
            if current<price: raise GameplayFault('InsufficientResource','Not enough guild currency')
            attrs['association_gold']=current-price
        elif currency in ('gold','coin'):
            if int(p.get(currency,0))<price: raise GameplayFault('InsufficientResource','Not enough '+currency)
            p[currency]=int(p.get(currency,0))-price
        else: raise GameplayFault('InvalidShopItem','Unsupported shop currency')
        grant_reward(p,reward,self.full); g['shop'][key]=bought+1
        return p,{'res_code':1,'association_gold':p.get('attrs',{}).get('association_gold',0),'gold':p.get('gold',0),'coin':p.get('coin',0),'lv':p.get('lv',1),'exp':p.get('exp',0),'vip_exp':p.get('vip_exp',0),'vip_lv':p.get('vip_lv',0),'attrs':p.get('attrs',{}),'avatars':p.get('avatars',{}),'my_equips':p.get('my_equips',{}),'guild_shop_info':[[str(k),v] for k,v in sorted(g.get('shop',{}).items()) if not str(k).startswith('server:')],**self._user_reward_fields(p)}
    def _assocication_sever_shop_refresh(self,p,x):
        g=self._guild(p)
        if not g: raise GameplayFault('NoGuild','Join a guild first')
        count=int(g.get('refresh_count',0)); hand=self.simple.get('guild_shop',{}).get('sever_shop',{}).get('hand_renovate',[100,50])
        cost=int(hand[0])+int(hand[1])*count if len(hand)>1 else int(hand[0]); attrs=p.setdefault('attrs',{})
        current=int(attrs.get('association_gold',0))
        if current<cost: raise GameplayFault('InsufficientResource','Not enough guild currency')
        attrs['association_gold']=current-cost; g['refresh_count']=count+1
        for key in list(g.setdefault('shop',{})):
            if str(key).startswith('server:'): del g['shop'][key]
        return p,{'res_code':1,'association_gold':attrs['association_gold'],'guild_shop_refresh_count':g['refresh_count']}
    def _apply_member(self,p,x):
        guild_id=str(x.get('id',''))
        row=next((item for item in self._guild_suggestions(p) if item['id']==guild_id),None)
        if row is None: return p,{'res_code':-1,'user_dict':self._wallet(p)}
        if self._guild(p): return p,{'res_code':-1,'user_dict':self._wallet(p)}
        if row['join_type']==0: return p,{'res_code':-2,'user_dict':self._wallet(p)}
        if int(p.get('lv',1)) < int(row['join_level_limit']):
            return p,{'res_code':-3,'user_dict':self._wallet(p)}
        if int(row['member_count']) >= int(row['max_member']):
            return p,{'res_code':-4,'user_dict':self._wallet(p)}
        if row['join_type']==2:
            guild=self._guild(p,True)
            guild.update({'id':guild_id,'name':row['name'],'icon':row['icon'],'level':int(row['level']),'notice':row['content']})
            p.setdefault('attrs',{}).update({'association_id':guild_id,'association_lv':0})
            p.setdefault('records',{}).pop('guild_applications',None)
            return p,{'res_code':1,'join_flag':True,'user_dict':self._wallet(p),'association':copy.deepcopy(guild)}
        applications=p.setdefault('records',{}).setdefault('guild_applications',{})
        applications[guild_id]={'id':guild_id,'status':'pending','submitted_day':game_day(self.store.clock.now()),'npc':True}
        return p,{'res_code':1,'join_flag':False,'apply_list':copy.deepcopy(list(applications.values())),'user_dict':self._wallet(p)}
    def _calcel_member(self,p,x):
        guild_id=str(x.get('id',''))
        records=p.setdefault('records',{})
        applications=records.get('guild_applications',{})
        if not isinstance(applications,dict): applications={}
        application=applications.get(guild_id)
        if not isinstance(application,dict) or application.get('status')!='pending':
            return p,{'res_code':-1,'apply_list':copy.deepcopy(list(applications.values()))}
        applications.pop(guild_id,None)
        if not applications: records.pop('guild_applications',None)
        remaining=records.get('guild_applications',{})
        return p,{'res_code':1,'apply_list':copy.deepcopy(list(remaining.values())),'user_dict':self._wallet(p)}
    def _get_apply_info(self,p,x):
        guild=self._guild(p)
        if not guild:
            return p,{'res_code':-1}
        self._update_guild_level(guild)
        return p,{'res_code':1,'association_info':{'id':guild['id'],'name':guild['name'],'icon':guild['icon'],'level':guild['level'],'association_application':0},'num':0,'member':[],'apply_list':[],'info':[]}
    def _association_rank_index(self,p,x): return p,{'info':self._guild_suggestions(p),'rank_list':self._guild_suggestions(p)}
    def _show_war_data(self,p,x): return p,{'data':{'open_status':0,'info':[]}}
    def _get_war_rank(self,p,x): return p,{'rank_list':[],'info':[]}
    def _get_fight_result(self,p,x): return p,{'res_code':0,'fight_result':[]}
    def _get_reward_data(self,p,x): return p,{'res_code':0,'reward':[]}
    def _boss_template(self,kind,stage):
        table=self.rules.get(kind,{}) if isinstance(self.rules,dict) else {}; rows=table.get('bosses',[])
        return copy.deepcopy(rows[(max(1,int(stage))-1)%len(rows)]) if rows else {'id':1,'name':'模拟Boss','max_hp':1000000,'ap':1000,'defense':0,'reward':{'gold':1000}}
    def _now(self): return int(self.store.clock.now())
    def _boss_window_open(self,kind,now=None):
        """Use the same local-time, minute-based windows as the original panels."""
        if kind=='guild_boss':
            cfg=self.simple.get('guild_BOSS',{})
            duration=int(cfg.get('duration',0))
        else:
            cfg=self.cfg.get('system_simple',{}).get('zone_boss',{})
            duration=int(cfg.get('max_alive_time',0))
        if int(cfg.get('open_status',1))<=0 or duration<=0:
            return False
        windows=cfg.get('open_times',[])
        if not isinstance(windows,list) or not windows:
            return False
        now=self._now() if now is None else int(now)
        shanghai=timezone(timedelta(hours=8))
        local_now=datetime.fromtimestamp(now,shanghai)
        for offset in (-1,0):
            day=local_now.date()+timedelta(days=offset)
            for row in windows:
                if not isinstance(row,(list,tuple)) or len(row)<2:
                    continue
                try:
                    hour,minute=int(row[0]),int(row[1])
                    if not 0<=hour<=23 or not 0<=minute<=59:
                        continue
                    start=datetime(day.year,day.month,day.day,hour,minute,tzinfo=shanghai).timestamp()
                except (TypeError,ValueError,OverflowError):
                    continue
                if start<=now<start+duration*60:
                    return True
        return False
    def _require_boss_window(self,kind):
        if not self._boss_window_open(kind):
            raise GameplayFault('BossClosed','This boss event is outside its configured open time')
    def _boss_state(self,p,kind):
        state=p.setdefault('boss_state',{}).setdefault(kind,{})
        if state.get('day')!=game_day(self.store.clock.now()):
            stage=max(1,int(state.get('stage',1))); tpl=self._boss_template(kind,stage)
            state.update({'day':game_day(self.store.clock.now()),'boss':{'id':tpl['id'],'name':tpl['name'],'max_hp':tpl['max_hp'],'current_hp':tpl['max_hp'],'kill_num':stage-1,'is_end':False,'add_time':{'$date':int(self.store.clock.now())}},'attack_log':{'attack_num':0,'attack_hp':0,'next_attack_time':{'$date':0},'enhance':0,'gifts':{}},'free_num':int(self.rules.get(kind,{}).get('attack',{}).get('free_per_day',3)),'vip_free_num':0,'rank_list':[],'report_list':[],'damage':0,'stage':stage})
        # Same-day profiles may have been created by an earlier server version.
        # Normalize fields consumed unconditionally by the native Boss panels.
        boss=state.setdefault('boss',{})
        log=state.setdefault('attack_log',{})
        log.setdefault('enhance',0); log.setdefault('gifts',{})
        log.setdefault('next_attack_time',{'$date':0})
        return state
    @staticmethod
    def _boss_payload(state):
        rank=copy.deepcopy(state['rank_list'])
        uid=str(state.get('player_uid',''))
        mine=next((int(row.get('rank',i+1)) for i,row in enumerate(rank) if str(row.get('uid'))==uid),0)
        return {'boss':copy.deepcopy(state['boss']),'is_end':bool(state['boss'].get('is_end',False)),'attack_log':copy.deepcopy(state['attack_log']),'free_num':state['free_num'],'vip_free_num':state['vip_free_num'],'rank_list':rank,'report_list':copy.deepcopy(state['report_list']),'my_rank':mine}
    def _get_associationboss(self,p,x):
        state=self._boss_state(p,'guild_boss'); return p,self._boss_payload(state)
    def _get_association_boss_ranks(self,p,x):
        state=self._boss_state(p,'guild_boss'); return p,{'rank_list':copy.deepcopy(state['rank_list']),'data':copy.deepcopy(state['rank_list'])}
    def _attack_associationboss(self,p,x):
        state=self._boss_state(p,'guild_boss'); return p,self._attack_boss(p,state,'guild_boss',x)
    def _get_zoneboss(self,p,x):
        state=self._boss_state(p,'world_boss'); return p,self._boss_payload(state)
    def _enter_zoneboss(self,p,x):
        self._require_boss_window('world_boss')
        return self._get_zoneboss(p,x)
    def _attack_zoneboss(self,p,x):
        state=self._boss_state(p,'world_boss'); return p,self._attack_boss(p,state,'world_boss',x)
    def _guild_damage_gift(self,damage):
        gift=self.simple.get('guild_BOSS',{}).get('gift',{}).get('hurt_range_gift',{})
        matches=[]
        for span,reward in gift.items():
            try:
                lower,upper=(int(part) for part in str(span).split('-',1))
            except (TypeError,ValueError):
                continue
            if lower<=int(damage)<=upper and isinstance(reward,dict):
                matches.append((lower,upper,reward))
        if len(matches)!=1:
            raise GameplayFault('InvalidBossReward','Guild boss damage must match exactly one configured reward band')
        return copy.deepcopy(matches[0][2])
    @staticmethod
    def _guild_currency_reward(native_reward):
        """Translate the preview's guild_currency key to the native wallet attr."""
        reward=copy.deepcopy(native_reward) if isinstance(native_reward,dict) else {}
        currency=reward.pop('guild_currency',0)
        flourishing=reward.pop('flourishing',0)
        if type(currency) is not int or currency<0 or type(flourishing) is not int or flourishing<0:
            raise GameplayFault('InvalidBossReward','Guild boss currency and flourishing rewards must be nonnegative integers')
        if currency:
            attrs=reward.setdefault('attrs',{})
            if not isinstance(attrs,dict): raise GameplayFault('InvalidBossReward','Guild boss attrs reward is malformed')
            attrs['association_gold']=int(attrs.get('association_gold',0))+currency
        return reward,currency,flourishing
    @staticmethod
    def _merge_guild_display_rewards(target,source):
        for key,value in source.items():
            if type(value) is not int or value<0:
                raise GameplayFault('InvalidBossReward','Guild boss display rewards must be nonnegative integers')
            target[key]=int(target.get(key,0))+value
    def _attack_boss(self,p,state,kind,x):
        self._require_boss_window(kind)
        if kind=='guild_boss' and not self._guild(p):
            raise GameplayFault('NoGuild','Join a guild before attacking its boss')
        if state['boss'].get('is_end'):
            raise GameplayFault('BossDefeated','This boss has already been defeated for the current cycle')
        if state['free_num']<=0: raise GameplayFault('DailyLimit','No boss attacks remain today')
        now=int(self.store.clock.now()); ready=state['attack_log'].get('next_attack_time',{}).get('$date',0)
        if isinstance(ready,int) and ready>now: raise GameplayFault('BossCooldown','Boss attack is on cooldown')
        power=0
        from gameplay_roster import GameplayRosterEquipment
        roster=GameplayRosterEquipment(self.store,self.full)
        team=(p.get('team') or [[]])[0]
        for instance_id in team if isinstance(team,list) else []:
            if not instance_id: continue
            stats=roster.battle_attributes(p,str(instance_id))
            power+=int(stats.get('ap',0))
        rules=self.rules.get(kind,{ }).get('attack',{})
        raw_damage=max(1,int(rules.get('base_damage',1200)+power*rules.get('damage_per_power',.35)))
        enhance=max(0,int(state['attack_log'].get('enhance',0)))
        damage=max(1,min(int(rules.get('damage_cap',250000)),int(raw_damage*(100+enhance)/100)))
        damage=min(damage,int(state['boss']['current_hp'])); state['boss']['current_hp']-=damage; state['attack_log']['attack_num']=int(x.get('attack_num',state['attack_log']['attack_num']))+1
        state['attack_log']['attack_hp']=damage; state['attack_log']['next_attack_time']={'$date':now+int(rules.get('cooldown_seconds',30))}; state['free_num']-=1
        kill_gifts=None; guild_display_reward={}; guild_flourishing=0
        if kind=='guild_boss':
            damage_display=self._guild_damage_gift(damage)
            reward,currency,flourishing=self._guild_currency_reward(damage_display)
            grant_reward(p,reward,self.full)
            self._merge_guild_display_rewards(guild_display_reward,damage_display)
            guild_flourishing+=flourishing
        if state['boss']['current_hp']<=0:
            defeated_stage=int(state.get('stage',1)); defeated=self._boss_template(kind,defeated_stage)
            state['boss']['is_end']=True; state['boss']['kill_num']+=1; state['boss']['end_time']={'$date':now}; state['boss']['killed_by']=str(self._me(p)['uid']); state['boss']['kill_log']={k:self._me(p)[k] for k in ('uid','name','lv','vip_lv')}
            state['stage']=min(int(self.rules.get(kind,{}).get('max_stage',5)),defeated_stage+1)
            if kind=='guild_boss':
                # The guild-boss native preview is the authority for personal
                # rewards. Stage definitions control the boss encounter only;
                # do not also grant a second hidden stage reward.
                kill_display=copy.deepcopy(self.simple.get('guild_BOSS',{}).get('gift',{}).get('kill_gift',{}))
                reward,currency,guild_flourishing_kill=self._guild_currency_reward(kill_display)
                grant_reward(p,reward,self.full)
                self._merge_guild_display_rewards(guild_display_reward,kill_display)
                guild_flourishing+=guild_flourishing_kill
                guild=self._guild(p)
                if guild and guild_flourishing:
                    guild['total_alive']=int(guild.get('total_alive',0))+guild_flourishing
                    self._update_guild_level(guild)
                state['attack_log']['gifts']=copy.deepcopy(guild_display_reward)
            else:
                reward=copy.deepcopy(defeated.get('reward',{}))
                # Equipment drops are not granted by this implementation, so
                # never invent kill_log.eid (the native panel treats it as an Equip ID).
                state['attack_log']['gifts']={k:int(reward.get(k,0)) for k in ('gold','coin','mark','medal') if int(reward.get(k,0))>0}
                grant_reward(p,reward,self.full)
            kill_gifts={'medal':p.get('medal',0),'lv':p.get('lv',1),'exp':p.get('exp',0),'energy':copy.deepcopy(p.get('energy',{'$date':int(self.store.clock.now())})),'association_gold':p.get('attrs',{}).get('association_gold',0)}
        elif kind=='guild_boss':
            state['attack_log']['gifts']=copy.deepcopy(guild_display_reward)
        state['damage']=int(state.get('damage',0))+damage
        state['player_uid']=str(self._me(p)['uid'])
        state['rank_list']=[{'uid':self._me(p)['uid'],'name':self._me(p)['name'],'damage':state['damage'],'rank':1}]
        state['report_list'].insert(0,{'type':'zb_kill' if state['boss']['is_end'] else 'zb_attack','data':{'uid':self._me(p)['uid'],'attack_hp':damage,'name':self._me(p)['name']}}); state['report_list']=state['report_list'][:10]
        if kind=='guild_boss':
            guild=self._guild(p)
            if guild:self._append_guild_log(guild,f"{self._me(p)['name']}挑战公会Boss，造成{damage}点伤害")
        result={**self._boss_payload(state),'attack_hp':damage,'gold':p.get('gold',0),'coin':p.get('coin',0),'mark':p.get('mark',0),'attrs':p.get('attrs',{}),'association_gold':p.get('attrs',{}).get('association_gold',0),'boss':copy.deepcopy(state['boss']),'rank_list':state['rank_list'],'report_list':state['report_list'],'res_code':0}
        if kind=='guild_boss': result['guild_reward']=copy.deepcopy(guild_display_reward)
        if kill_gifts is not None: result['kill_gifts']=kill_gifts
        return result
    def _reborn(self,p,x): return self._revive(p,'world_boss',False)
    def _super_reborn(self,p,x): return self._revive(p,'world_boss',True)
    def _association_reborn(self,p,x): return self._revive(p,'guild_boss',False)
    def _revive(self,p,kind,super):
        self._require_boss_window(kind)
        state=self._boss_state(p,kind); rules=self.rules.get(kind,{}).get('revive',{}); cost=int(rules.get('super_coin_cost' if super else 'coin_cost',20))
        if state['boss'].get('is_end') or int(state['boss'].get('current_hp',0))<=0:
            raise GameplayFault('BossDefeated','A defeated boss cannot be revived')
        attack_log=state['attack_log']; stamp=attack_log.get('next_attack_time',{'$date':0})
        ready=int(stamp.get('$date',0)) if isinstance(stamp,dict) else 0
        if int(attack_log.get('attack_num',0))<=0 or ready<=int(self.store.clock.now()):
            raise GameplayFault('BossNotRecoverable','There is no active attack cooldown to recover')
        if p.get('coin',0)<cost: raise GameplayFault('InsufficientResource','Not enough coin')
        p['coin']-=cost
        attack_log['next_attack_time']={'$date':0}
        if super:
            bonus=float(rules.get('super_heal_ratio',rules.get('super_relive',0.5)))
            attack_log['enhance']=int(attack_log.get('enhance',0))+max(0,int(round(bonus*100)))
        return p,{**self._boss_payload(state),'is_end':False,'coin':p['coin'],'attack_log':state['attack_log'],'boss':state['boss']}
    def _buy_attack_number(self,p,x):
        self._require_boss_window('guild_boss')
        state=self._boss_state(p,'guild_boss'); rules=self.rules.get('guild_boss',{}).get('buy_attack',{}); cost=int(rules.get('coin_cost',10)); limit=int(rules.get('daily_limit',5)); rec=self._day_record(p); bought=int(rec.get('guild_boss_bought_attacks',0))
        if bought>=limit: raise GameplayFault('DailyLimit','Boss attack purchase limit reached')
        if int(p.get('coin',0))<cost: raise GameplayFault('InsufficientResource','Not enough coin')
        p['coin']=int(p.get('coin',0))-cost; state['free_num']+=1; rec['guild_boss_bought_attacks']=bought+1
        return p,{'association_free_num':state['free_num'],'association_vip_free_num':state['vip_free_num'],'coin':p['coin'],'vip_lv':p.get('vip_lv',0),'vip_exp':p.get('vip_exp',0)}
    def _inspire_association_race(self,p,x):
        raise GameplayFault('FeatureUnavailable','公会竞速鼓舞暂未开放。')
