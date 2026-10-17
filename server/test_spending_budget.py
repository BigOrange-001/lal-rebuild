"""Gateway payment, tier and legacy-profile spending boundaries."""
import datetime
import hashlib
import json
import sqlite3
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))
from gateway import Backend, RpcFault
from spending_budget import normalize_spending


class SpendingGatewayTests(unittest.TestCase):
    def setUp(self):
        self.backend = Backend(":memory:")
        self.now = int(datetime.datetime(2026, 10, 17, 15, 59, 50,
                                         tzinfo=datetime.timezone.utc).timestamp())
        self.clock_patch = patch.object(self.backend.clock, "now", side_effect=lambda: self.now)
        self.clock_patch.start()
        self.addCleanup(self.clock_patch.stop)
        self.addCleanup(self.backend.db.close)

    def rpc(self, method, action, *, uid=None, token=None, **params):
        request = {"method": method, "params": {"actionID": action, **params}}
        if uid is not None:
            request.update(uid=uid, sessionid=token)
        return self.backend.call(request)

    def account(self, name, tier=None):
        registration = {"pf": "local", "session_key": name, "sessionid": "password"}
        if tier is not None:
            registration["spending_tier"] = tier
        self.assertEqual(self.rpc("user.register", "register-" + name, **registration)["return_code"], 0)
        login = self.rpc("user.login", "login-" + name,
                         pf="local", session_key=name, sessionid="password")
        self.assertEqual(login["return_code"], 0)
        return login["data"]["uid"], login["data"]["sessionid"]

    def test_small_limit_is_atomic_and_payment_alias_replay(self):
        uid, token = self.account("small")
        first = self.rpc("user.pay", "purchase-1", uid=uid, token=token,
                         pid="local_6480", order_id="order-1")
        self.assertEqual(first["data"]["granted_coin"], 12960)
        self.assertTrue(first["data"]["first_double"])
        replay = self.rpc("user.appstore_pay", "new-action-same-order", uid=uid, token=token,
                          pid="local_6480", order_id="order-1")
        self.assertTrue(replay["data"]["replayed"])
        before = self.backend.players.profile_raw(uid)
        denied = self.rpc("user.local_pay_test", "purchase-2", uid=uid, token=token, pid="local_60")
        self.assertEqual((denied["return_code"], denied["data"]["error_code"], denied["data"]["msg"]),
                         (1, "DailySpendingLimit", "今天没钱了 明天再来吧"))
        self.assertEqual(before, self.backend.players.profile_raw(uid))
        spending = self.rpc("user.spending_info", "info", uid=uid, token=token)["data"]
        self.assertEqual((spending["tier"], spending["spent_yuan"], spending["remaining_yuan"]),
                         ("small", 648, 0))
        self.assertEqual(first["state_sync"]["profile"]["spending"]["spent_yuan"], 648)
        conflict = self.rpc("user.pay", "different-action", uid=uid, token=token,
                            pid="local_60", order_id="order-1")
        self.assertEqual(conflict["data"]["error_code"], "RequestKeyConflict")

        fresh_uid, fresh_token = self.account("first-denied")
        original = self.backend.players.profile_raw(fresh_uid)
        self.assertEqual(self.rpc("user.pay", "too-large", uid=fresh_uid,
                                  token=fresh_token, pid="local_10000")["return_code"], 1)
        self.assertEqual(self.backend.players.profile_raw(fresh_uid), original)
        accepted = self.rpc("user.pay", "first-valid", uid=fresh_uid,
                            token=fresh_token, pid="local_60")
        self.assertTrue(accepted["data"]["first_double"])

    def test_switch_keeps_today_spend_and_shanghai_midnight_resets(self):
        uid, token = self.account("switch", "wealthy")
        self.assertEqual(self.rpc("user.pay", "p1", uid=uid, token=token, pid="local_10000")["return_code"], 0)
        lower = self.rpc("user.set_spending_tier", "lower", uid=uid, token=token,
                         spending_tier="small")["data"]
        self.assertEqual((lower["spent_yuan"], lower["remaining_yuan"]), (1000, 0))
        self.assertEqual(self.rpc("user.pay", "p2", uid=uid, token=token, pid="local_60")["return_code"], 1)
        self.now += 20  # 2026-10-18 00:00:10 in Shanghai.
        info = self.rpc("user.spending_info", "nextday", uid=uid, token=token)["data"]
        self.assertEqual((info["spent_yuan"], info["remaining_yuan"]), (0, 648))
        paid = self.rpc("user.pay", "p3", uid=uid, token=token, pid="local_60")
        self.assertEqual((paid["return_code"], paid["data"]["first_double"]), (0, False))
        self.assertEqual(paid["state_sync"]["profile"]["spending"]["spent_yuan"], 6)

    def test_gm_only_at_creation_and_legacy_defaults_preserve_wallet(self):
        gm_uid, gm_token = self.account("gm-account", "gm")
        for index in range(3):
            self.assertEqual(self.rpc("user.appstore_pay", "gm-pay-" + str(index),
                                      uid=gm_uid, token=gm_token, pid="local_10000")["return_code"], 0)
        gm = self.rpc("user.spending_info", "gm-info", uid=gm_uid, token=gm_token)["data"]
        self.assertEqual((gm["tier"], gm["spent_yuan"], gm["remaining_yuan"], gm["can_change"]),
                         ("gm", 3000, None, False))
        self.assertEqual(self.rpc("user.set_spending_tier", "gm-lower", uid=gm_uid,
                                  token=gm_token, spending_tier="wealthy")["return_code"], 1)
        ordinary_uid, ordinary_token = self.account("ordinary")
        forged_login = self.rpc("user.login", "forged-login", pf="local",
                                session_key="ordinary", sessionid="password", spending_tier="gm")
        self.assertEqual(forged_login["data"]["spending"]["tier"], "small")
        self.assertEqual(self.rpc("user.set_spending_tier", "upgrade-gm", uid=ordinary_uid,
                                  token=ordinary_token, spending_tier="gm")["return_code"], 1)
        with self.assertRaises(RpcFault):
            self.rpc("user.register", "retry-as-gm", pf="local", session_key="ordinary",
                     sessionid="password", spending_tier="gm")
        row = self.backend.players.profile_raw(ordinary_uid)
        row["coin"] = 123456
        row.pop("spending")
        self.backend.db.execute("UPDATE players SET profile=? WHERE uid=?",
                                (json.dumps(row, ensure_ascii=False), ordinary_uid))
        self.backend.db.commit()
        self.assertEqual(self.backend.players.profile(ordinary_uid)["coin"], 123456)
        self.assertEqual(self.backend.players.profile_raw(ordinary_uid)["spending"]["tier"], "small")

    def test_invalid_tier_and_product_types_are_business_faults_without_mutation(self):
        uid, token = self.account("bad-types")
        original = self.backend.players.profile_raw(uid)
        for index, invalid in enumerate(([], {}, None)):
            result = self.rpc("user.set_spending_tier", "bad-tier-" + str(index),
                              uid=uid, token=token, spending_tier=invalid)
            self.assertEqual((result["return_code"], result["data"]["error_code"]),
                             (1, "InvalidSpendingTier"))
            self.assertEqual(self.backend.players.profile_raw(uid), original)
            pay = self.rpc("user.pay", "bad-product-" + str(index),
                           uid=uid, token=token, pid=invalid)
            self.assertEqual((pay["return_code"], pay["data"]["error_code"]),
                             (1, "InvalidPayProduct"))
            self.assertEqual(self.backend.players.profile_raw(uid), original)
        malformed = {"spending": {"tier": [], "gm_eligible": False,
                                  "day": "2026-10-17", "spent_yuan": 6}}
        self.assertEqual(normalize_spending(malformed, self.now)["tier"], "small")

    def test_old_accounts_table_migrates_without_changing_credentials(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "legacy.sqlite3"
            salt = "ab" * 16
            digest = hashlib.pbkdf2_hmac("sha256", b"password", bytes.fromhex(salt), 100000).hex()
            db = sqlite3.connect(path)
            try:
                db.execute("CREATE TABLE accounts (name TEXT PRIMARY KEY,salt TEXT NOT NULL,password_hash TEXT NOT NULL)")
                db.execute("INSERT INTO accounts VALUES(?,?,?)", ("legacy", salt, digest))
                db.commit()
            finally:
                db.close()
            backend = Backend(path)
            try:
                self.assertEqual(backend.db.execute("SELECT spending_tier FROM accounts WHERE name='legacy'").fetchone()[0], "small")
                result = backend.call({"method": "user.login", "params": {
                    "actionID": "legacy-login", "pf": "local", "session_key": "legacy", "sessionid": "password"}})
                self.assertEqual((result["return_code"], result["data"]["spending"]["tier"]), (0, "small"))
            finally:
                backend.clock.close()
                backend.db.close()


if __name__ == "__main__":
    unittest.main()
