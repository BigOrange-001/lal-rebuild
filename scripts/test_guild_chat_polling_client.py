"""Exercise the chat panel's asynchronous polling and removal lifecycle."""
import json
import subprocess
import unittest
from pathlib import Path

from test_avatar_passive import NODE, method_body

ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(NODE, "Node is required for the ActionScript behavior harness")
class GuildChatPollingClientTests(unittest.TestCase):
    def test_async_replies_are_fetched_while_open_and_stale_replies_are_ignored(self):
        source = (ROOT / "client/src/stages/018_PanelChatRoom.as").read_text("utf-8")
        script = r'''
const assert=require('assert');
let pending=[],delivered=[];
const TimerEvent={TIMER:'timer'};
function Timer(delay){
  this.delay=delay;this.running=false;this.listener=null;
  this.addEventListener=(type,fn)=>this.listener=fn;
  this.removeEventListener=()=>this.listener=null;
  this.start=()=>this.running=true;this.stop=()=>this.running=false;
  this.tick=()=>{if(this.running&&this.listener)this.listener(null);};
}
const SendServiceAMFFun={send_user_chat_record(fn,params){
  assert.equal(params.channel,'guild');pending.push(fn);
}};
const unit={stage:{},mTabBar:{selectedIndex:3},guildChatTimer105:null,
  guildChatBusy105:false,guildChatGeneration105:0,
  guild_record_backFun:reply=>delivered.push(reply)};
'''
        for name, params in (("startGuildChatPolling105", ""), ("stopGuildChatPolling105", ""),
                             ("pollGuildChat105", "event=null")):
            body = method_body(source, name)
            body = body.replace("function(reply:Object)", "function(reply)")
            script += f"unit.{name}=function({params}){{with(unit){{{body}\n}}}};\n"
        script += r'''
unit.startGuildChatPolling105();
const timer=unit.guildChatTimer105;
assert.equal(timer.delay,3000);assert.equal(pending.length,1);
timer.tick();assert.equal(pending.length,1); // no overlapping requests
pending.shift()({data:{record:[]}});
// The AI response completes after the initial send/history response.
timer.tick();assert.equal(pending.length,1);
pending.shift()({data:{record:[{s:'AI reply'}]}});
assert.equal(delivered[1].data.record[0].s,'AI reply');
unit.mTabBar.selectedIndex=0;timer.tick();assert.equal(pending.length,0);
unit.mTabBar.selectedIndex=3;timer.tick();assert.equal(pending.length,1);
unit.stopGuildChatPolling105();unit.stage=null;
pending.shift()({data:{record:[{s:'stale'}]}});
assert.equal(delivered.length,2);assert.equal(timer.running,false);
assert.equal(timer.listener,null);assert.equal(unit.guildChatTimer105,null);
timer.tick();assert.equal(pending.length,0);
console.log(JSON.stringify({ok:true}));
'''
        run = subprocess.run([NODE, "-e", script], encoding="utf-8", capture_output=True, timeout=20)
        self.assertEqual(run.returncode, 0, run.stderr)
        self.assertTrue(json.loads(run.stdout)["ok"])
        self.assertIn("startGuildChatPolling105();", method_body(source, "initializeHandler"))
        self.assertIn("stopGuildChatPolling105();", method_body(source, "onREMOVED_FROM_STAGE"))
