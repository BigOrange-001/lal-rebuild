"""Run VIP pack reward callbacks against the runtime configuration."""
import json
import subprocess
import sys
import unittest
from pathlib import Path

from test_avatar_passive import NODE, method_body

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "server"))
from gateway import load_game_config


@unittest.skipUnless(NODE, "Node is required for the ActionScript behavior harness")
class VipPackRewardsClientTests(unittest.TestCase):
    def test_free_and_paid_packs_render_every_reward_and_refresh_the_list(self):
        cfg = load_game_config(ROOT / "config/reconstruction/full-config.json")["cfg"]
        packs = [cfg["vip"][str(level)][kind]["data"]
                 for level in range(1, 16) for kind in ("gift_buy", "gift_coin_buy")]
        body = method_body((ROOT / "client/src/stages/100_ItemVIPShopping.as").read_text("utf-8"),
                           "sendAward")
        script = r'''
const packs=JSON.parse(require('fs').readFileSync(0,'utf8'));
const Tools={clone:value=>JSON.parse(JSON.stringify(value))};
let calls=[],events=[];
const GlobalFunction={
  getAwardByType(type,value){
    if(!['coin','gold','culture_book','dn_stone','dust','avatar','equip'].includes(type))
      throw new Error('Unsupported reward type: '+type);
    return {msg:type};
  },
  popAward(type,message,value){calls.push({type,value});}
};
const GlobalLanguageStr={getLanguageStr:(id,msg)=>msg};
const GlobalData={$mEventDispatcher:{dispatchEventWith:event=>events.push(event)}};
const sendAward=function(param1){BODY};
const rows=packs.map(pack=>{
  calls=[];events=[];
  const before=JSON.stringify(pack);
  sendAward(pack);
  return {calls,events,unchanged:before===JSON.stringify(pack)};
});
console.log(JSON.stringify(rows));
'''.replace("BODY", body)
        run = subprocess.run([NODE, "-e", script], input=json.dumps(packs),
                             encoding="utf-8", capture_output=True, timeout=20)
        self.assertEqual(run.returncode, 0, run.stderr)
        results = json.loads(run.stdout)
        self.assertEqual(len(results), 30)
        for index, (pack, result) in enumerate(zip(packs, results)):
            with self.subTest(vip=index // 2 + 1, paid=bool(index % 2)):
                expected = {key: value for key, value in pack.items() if key != "attrs"}
                expected.update(pack.get("attrs", {}))
                actual = {row["type"]: row["value"] for row in result["calls"]}
                self.assertEqual(actual, expected)
                self.assertEqual(result["events"], ["update_vip_gift"])
                self.assertTrue(result["unchanged"])


if __name__ == "__main__":
    unittest.main()
