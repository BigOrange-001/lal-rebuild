"""Tower-earned skin fragments can be exchanged without opening other pools."""
import json
import sqlite3
import sys
import unittest
from pathlib import Path

sys.path.insert(0,str(Path(__file__).resolve().parent))
from player_store import PlayerStore,GameplayFault
from gameplay_roster import GameplayRosterEquipment


class TowerSkinExchangeTest(unittest.TestCase):
    def test_earned_credit_is_spent_once_and_other_acquisition_stays_blocked(self):
        config=json.loads((Path(__file__).resolve().parents[1]/'config/reconstruction/full-config.json').read_text(encoding='utf-8'))
        skin=next(aid for aid in config['cfg']['system_simple']['skin_acquisition_blocked_heroes'] if aid.endswith('_6'))
        need=int(config['cfg']['system_simple']['soul_exchange']['avatar']['6'])
        database=sqlite3.connect(':memory:',check_same_thread=False)
        self.addCleanup(database.close)
        store=PlayerStore(database,config)
        uid=store.login('tower-skin-test')['uid']
        roster=GameplayRosterEquipment(store,config)
        def seed(profile):
            profile['avatar_soul'][skin]=need*2
            return profile,{}
        store.atomic_update(uid,seed)
        before=store.profile_raw(uid)
        with self.assertRaises(GameplayFault) as error:
            roster.dispatch(uid,'user.soul_exchange_avatar',{'aid':skin,'num':1,'actionID':'no-credit'})
        self.assertEqual(error.exception.code,'SkinAcquisitionRestricted')
        self.assertEqual(store.profile_raw(uid),before)
        def credit(profile):
            profile['attrs']['tower_skin_soul_credit']={skin:need}
            return profile,{}
        store.atomic_update(uid,credit)
        result=roster.dispatch(uid,'user.soul_exchange_avatar',{'aid':skin,'num':1,'actionID':'earned-credit'})
        self.assertEqual(len(result['new_avatars']),1)
        after=store.profile_raw(uid)
        self.assertEqual((after['avatar_soul'][skin],after['attrs']['tower_skin_soul_credit'][skin]),(need,0))
        self.assertEqual(len(after['avatars']),len(before['avatars'])+1)
        replay=roster.dispatch(uid,'user.soul_exchange_avatar',{'aid':skin,'num':1,'actionID':'earned-credit'})
        self.assertEqual(replay['new_avatars'],result['new_avatars'])
        self.assertEqual(store.profile_raw(uid),after)
        with self.assertRaises(GameplayFault):
            roster._new_hero(after,skin)


if __name__=='__main__':
    unittest.main()
