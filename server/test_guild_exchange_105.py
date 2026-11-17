"""Native guild shop hero rewards use the authoritative guild wallet."""
import unittest
import test_shop_balance_105 as fixtures
from gameplay_guild_boss import GameplayGuildBoss
from player_store import GameplayFault


class GuildExchangeTests(unittest.TestCase):
    setUpClass=fixtures.ShopBalanceTest.__dict__['setUpClass']

    def setUp(self):
        fixtures.ShopBalanceTest.setUp(self)
        self.guild=GameplayGuildBoss(self.store,self.doc)
        def join(p):
            self.guild._guild(p,create=True)
            p['attrs']['association_gold']=10000
            return p,{}
        self.store.atomic_update(self.uid,join)

    def test_prices_and_repeatable_purchases_with_replay(self):
        config=self.cfg['association_simple']['guild_shop']
        rows=config['guild_shop']['gift_info']['guild_1']
        offers=[(key,rows[key][0]) for key in config['hero_exchange_ids_105']]
        skins=set(self.cfg['system_simple']['skin_hero_ids'])
        for _,row in offers:
            aid=next(iter(row[0]['avatar']))
            self.assertEqual(row[1],{'guild_currency':2000 if aid in skins else 1000})
        normal=next(key for key,row in offers if row[1]['guild_currency']==1000)
        skin=next(key for key,row in offers if row[1]['guild_currency']==2000)
        before=len(self.store.profile_raw(self.uid)['avatars'])
        params={'index':normal,'actionID':'one'}
        self.guild.dispatch(self.uid,'user.assocication_guild_shop_buy',params)
        saved=self.store.profile_raw(self.uid)
        self.guild.dispatch(self.uid,'user.assocication_guild_shop_buy',params)
        self.assertEqual(saved,self.store.profile_raw(self.uid))
        self.guild.dispatch(self.uid,'user.assocication_guild_shop_buy',{'index':normal,'actionID':'two'})
        self.guild.dispatch(self.uid,'user.assocication_guild_shop_buy',{'index':skin,'actionID':'skin'})
        after=self.store.profile_raw(self.uid)
        self.assertEqual(after['attrs']['association_gold'],6000)
        self.assertEqual(len(after['avatars']),before+3)

    def test_low_currency_and_full_inventory_roll_back(self):
        index=self.cfg['association_simple']['guild_shop']['hero_exchange_ids_105'][0]
        for full in (False,True):
            def seed(p):
                p['attrs']['association_gold']=10000 if full else 999
                if full:p['attrs']['avatar_len']=len(p['avatars'])
                return p,{}
            self.store.atomic_update(self.uid,seed)
            before=self.store.profile_raw(self.uid)
            with self.assertRaises(GameplayFault):self.guild.dispatch(self.uid,'user.assocication_guild_shop_buy',{'index':index,'actionID':f'bad-{full}'})
            self.assertEqual(before,self.store.profile_raw(self.uid))
