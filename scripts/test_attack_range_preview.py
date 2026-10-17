"""Execute the native Avatar range-preview methods with a small Starling stub."""

import json
import subprocess
import unittest

from test_avatar_passive import NODE, ROOT, method_body


HARNESS = r'''
const fs = require('node:fs');
const vm = require('node:vm');
const input = JSON.parse(fs.readFileSync(0, 'utf8'));
const scheduled = [];
function Sprite() { this.children=[]; this.parent=null; this.visible=true; }
Sprite.prototype.addChild = function(child) { child.parent=this; this.children.push(child); return child; };
Sprite.prototype.addChildAt = function(child,index) { child.parent=this; this.children.splice(index,0,child); return child; };
Sprite.prototype.getChildAt = function(index) { return this.children[index]; };
Sprite.prototype.removeFromParent = function() {
  if(this.parent) this.parent.children.splice(this.parent.children.indexOf(this),1);
  this.parent=null;
};
function Quad(width,height,color) { Sprite.call(this);Object.assign(this,{width,height,color}); }
Quad.prototype=Object.create(Sprite.prototype);
function Rectangle(x,y,width,height) { Object.assign(this,{x,y,width,height}); }
const layer={effectLayer:new Sprite(),lineLayerList:[1,2,3],getLineX(){return 350;},
  delayCall(method,time,...args){scheduled.push({method,time,args});}};
const GameMap={actionDelay:1,currentMap:{isFight:true,getShowLine(line){return line;}}};
const context=vm.createContext({GameMap,GameMapLayer:{gl:layer},GameMapConfig:{
  LINE_POS:3000,FIGHT_WIDTH:900,posToPixel(pos){return 100+pos/5;}
},Sprite,Quad,Rectangle,Math,Number});
const avatar={team:1,line:1,pos:1500,hp:100,m_fightRes:{parent:{}},m_fightRange:null,
  fightRes:{rotation:0,scaleX:1,scaleY:1},rangeMoveEndsAt:1.3,
  rangePreviewQueued:false,getRange(){return 500;},getScale(){return 1;},
  hideRange(){if(this.m_fightRange)this.m_fightRange.visible=false;},
  findAimList(){return [{}];},attackAimList(){this.hits=(this.hits||0)+1;},
  currentAbilityAttack(){return input.ability ? {kind:'active'} : null;}};
GameMap.currentAvatar=avatar;
function install(name,params){avatar[name]=vm.runInContext(
  '(function('+params+'){with(this){'+input.methods[name]+'\n}})',context);}
for(const [name,params] of Object.entries(input.params))install(name,params);
if(input.mode==='visual'){
  avatar.showRange(1,1500,500);
  const frame=avatar.m_fightRange;
  process.stdout.write(JSON.stringify({name:frame.name,frame:{x:frame.x,y:frame.y,alpha:frame.alpha},
    children:frame.children.map(q=>({x:q.x||0,y:q.y||0,width:q.width,height:q.height,color:q.color})),
    bounds:avatar.rangePreviewBounds(1500,500,3,350)}));
}else{
  avatar.checkAllAttack([],null,-1,false,input.damageType);
  avatar.checkAllAttack([],null,-1,false,input.damageType);
  process.stdout.write(JSON.stringify({hits:avatar.hits||0,queued:avatar.rangePreviewQueued,
    calls:scheduled.map(x=>({name:x.method.name,time:x.time,args:x.args})),
    actionDelay:GameMap.actionDelay}));
}
'''


@unittest.skipUnless(NODE, "Node is needed for the native ActionScript method harness")
class AttackRangePreviewTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        source = (ROOT / "client/src/stages/137_Avatar.as").read_text(encoding="utf-8")
        cls.methods = {name: method_body(source, name) for name in (
            "showRange", "rangePreviewBounds", "rangePreviewSchedule",
            "queueRangePreview", "checkAllAttack")}
        cls.params = {
            "showRange": "param1,param2,param3",
            "rangePreviewBounds": "param1,param2,param3,param4",
            "rangePreviewSchedule": "param1,param2",
            "queueRangePreview": "",
            "checkAllAttack": "param1,param2,param3=-1,param4=false,param5=-1,param6=1,param7=0,param8=null,param9=null,param10=1",
        }
        cls.attack_body = method_body(source, "attackAimList")

    def run_native(self, mode, ability=False, damage_type=-1):
        result = subprocess.run([NODE, "-e", HARNESS],
                                input=json.dumps({"mode": mode, "ability": ability,
                                                  "damageType": damage_type,
                                                  "methods": self.methods, "params": self.params}),
                                capture_output=True, text=True, encoding="utf-8", timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout)

    def test_range_is_a_visible_outline_without_a_filled_blue_square(self):
        result = self.run_native("visual")
        bounds = result["bounds"]
        self.assertEqual(result["name"], "attackRangeOutline")
        self.assertEqual(len(result["children"]), 4)
        self.assertEqual((result["frame"]["x"], result["frame"]["y"]),
                         (bounds["x"], bounds["y"]))
        self.assertTrue(all(q["width"] <= 3 or q["height"] <= 3
                            for q in result["children"]))
        self.assertFalse(any(q["width"] == bounds["width"] and q["height"] == bounds["height"]
                             for q in result["children"]))

    def test_normal_attack_previews_once_before_hit(self):
        result = self.run_native("attack")
        self.assertEqual(result["hits"], 2)
        self.assertTrue(result["queued"])
        self.assertEqual([x["time"] for x in result["calls"]], [1.3, 1.5])
        self.assertEqual(result["actionDelay"], 1.5)

    def test_skill_and_followup_damage_do_not_preview_basic_range(self):
        self.assertNotIn("queueRangePreview", self.attack_body)
        for ability, damage_type in ((True, -1), (False, 1)):
            with self.subTest(ability=ability, damage_type=damage_type):
                result = self.run_native("attack", ability, damage_type)
                self.assertEqual(result["hits"], 2)
                self.assertEqual(result["calls"], [])
                self.assertFalse(result["queued"])


if __name__ == "__main__":
    unittest.main()
