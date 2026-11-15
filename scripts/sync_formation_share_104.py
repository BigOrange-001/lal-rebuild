"""Integrate the formation library into existing native arena components."""
from pathlib import Path
import hashlib
import json
import subprocess

ROOT=Path(__file__).resolve().parents[1]

def read(name): return (ROOT/name).read_text('utf-8-sig')
def write(name,text):
    try: original=subprocess.check_output(['git','show','HEAD:'+name],cwd=ROOT,stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError: original=b''
    if b'\r\n' in original: text=text.replace('\r\n','\n').replace('\n','\r\n')
    (ROOT/name).write_bytes(text.encode('utf-8'))
def once(text,before,after):
    if after in text:return text
    if before not in text:raise ValueError('Missing integration anchor: '+before[:100])
    return text.replace(before,after,1)
def methods(text,part,tag):
    begin='      // BEGIN '+tag+'\n';end='      // END '+tag+'\n'
    block=begin+read(part).rstrip()+'\n'+end
    if begin in text:
        a=text.index(begin);b=text.index(end,a)+len(end);text=text[:a]+text[b:]
    # Some decompiled files also contain package-external helper classes.
    # Their final closing brace must not receive methods of the public class.
    at=text.index('\n   }\n}',text.index('public class '))
    if at<0:raise ValueError('Missing class close')
    return text[:at].rstrip()+'\n'+block+text[at:]

p='client/src/stages/001_GlobalData.as';s=read(p)
s=once(s,'   public class GlobalData\n   {','   public class GlobalData\n   {\n      public static var $formationShare104:Object = {};')
write(p,s)

p='client/src/stages/046_PanelCenterPVP.as';s=read(p)
s=once(s,'   import feathers.controls.List;','   import feathers.controls.List;\n   import feathers.controls.TextInput;\n   import flash.system.System;\n   import flash.desktop.Clipboard;\n   import flash.desktop.ClipboardFormats;\n   import starling.display.Quad;')
s=once(s,'      public static var $tabBarSelectedIndex:int = 0;','''      public static var $tabBarSelectedIndex:int = 0;
      private var formationRows104:Array = [];
      private var shareExport104:LOL_Scale9Button;
      private var shareImport104:LOL_Scale9Button;
      private var shareModal104:Sprite;
      private var shareInput104:TextInput;''')
s=once(s,'GlobalData.$mEventDispatcher.addEventListener("update_signup",afterSignUpdate);','GlobalData.$mEventDispatcher.addEventListener("update_signup",afterSignUpdate);\n         GlobalData.$mEventDispatcher.addEventListener("formation_library_changed",loadFormations104);')
s=once(s,'"indexID":3\n         }],tabBar_changeHandler,tabBar_CREATION_COMPLETE,MainConfig.$isEnglish ? 155 : 135,55);','"indexID":3\n         },{"label":"阵容挑战","indexID":4}],tabBar_changeHandler,tabBar_CREATION_COMPLETE,Math.min(MainConfig.$isEnglish ? 155 : 135,(GlobalData.$mStageWidth-40)/5),55);')
s=once(s,'      override public function update() : void\n      {','''      override public function update() : void
      {
         if(this.mTabBar.selectedIndex==4)
         {
            $tabBarSelectedIndex=4;mFun_status=false;
            delTimer_Extreme();delPVPList();delPVP_elite();delPVP_fragment();delPVP_BattleOfThePeak();
            setPVPList();return;
         }''')
s=once(s,'            if(_loc4_)\n            {\n               update();','            if(this.mTabBar.selectedIndex==4) _loc4_=true;\n            if(_loc4_)\n            {\n               update();')
s=once(s,'      private function delPVPList() : void\n      {','''      private function delPVPList() : void
      {
         if(shareExport104) shareExport104.removeFromParent(true);
         if(shareImport104) shareImport104.removeFromParent(true);
         shareExport104=null;shareImport104=null;''')
s=once(s,'      override public function onREMOVED_FROM_STAGE(param1:Event) : void\n      {','''      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         closeFormationCode104();
         GlobalData.$mEventDispatcher.removeEventListener("formation_library_changed",loadFormations104);''')
anchor='''         if(mFun_status)
         {
            selectMsg();
         }
         else
         {
            selectList(true);
         }
         checkGuide();'''
s=once(s,anchor,'''         addFormationControls104();
         if(mTabBar.selectedIndex==4)
         {
            mBtn_re.visible=false;if(mBtn_change) mBtn_change.visible=false;
            pvpRule.visible=false;headImg.visible=false;
            mTxt_pkTimes.text="已保存阵容：加载中";
            formationRows104=[];setList();loadFormations104();
         }
         else
         {
            if(mFun_status) selectMsg();else selectList(true);
            checkGuide();
         }
         consumeFormationCode104();''')
s=once(s,'else if(this.mTabBar.selectedIndex == 3)\n         {\n            setPVPList_listData();','else if(this.mTabBar.selectedIndex == 3 || this.mTabBar.selectedIndex == 4)\n         {\n            setPVPList_listData();')
s=once(s,'         if(mTabBar.selectedIndex == 1)\n         {\n            i = 0;','''         if(mTabBar.selectedIndex==4)
         {
            delTips();
            if(formationRows104.length==0) setTips("还没有敌方阵容，点击“导入敌阵”保存阵容代码。");
            else this.setListTimer(mList,formationRows104,ItemPVP,false);
            if(shareModal104) addChild(shareModal104);
            return;
         }
         if(mTabBar.selectedIndex == 1)
         {
            i = 0;''')
s=once(s,'if(mTxt_pkTimes && mPVP_list.length > 6)','if(mTxt_pkTimes && mPVP_list.length > 6 && mTabBar.selectedIndex==1)')
s=once(s,'if(mBtn_change) mBtn_change.visible = !mFun_status;','if(mBtn_change) mBtn_change.visible = !mFun_status;\n         if(shareExport104) shareExport104.visible=!mFun_status;\n         if(shareImport104) shareImport104.visible=!mFun_status;')
s=once(s,'if(mTabBar.selectedIndex != 0)\n         {\n            this.setList();\n            this.addList();','if(mTabBar.selectedIndex == 1)\n         {\n            this.setList();\n            this.addList();\n            if(shareModal104) addChild(shareModal104);')
s=methods(s,'client/src/formation_share_104.aspart','FORMATION PANEL 104');write(p,s)

p='client/src/stages/047_ItemPVP.as';s=read(p)
s=once(s,'   import feathers.controls.renderers.IListItemRenderer;','   import feathers.controls.renderers.IListItemRenderer;\n   import com.meng52.net.SendAndSelect;')
s=once(s,'      protected var mBtn_pk:LOL_Scale9Button;','      protected var mBtn_pk:LOL_Scale9Button;\n      private var formationDelete104:LOL_Scale9Button;')
s=once(s,'      override public function onREMOVED_FROM_STAGE(param1:Event) : void\n      {','      override public function onREMOVED_FROM_STAGE(param1:Event) : void\n      {\n         if(formationDelete104) formationDelete104.removeFromParent(true);\n         formationDelete104=null;')
s=once(s,'_loc33_ = GlobalFunction.checkIsFirstPVP();','_loc33_ = param1["formation_id"] ? false : GlobalFunction.checkIsFirstPVP();')
s=once(s,'mBtn_pk.addEventListener("triggered",onTRIGGERED_btns);','''mBtn_pk.addEventListener("triggered",onTRIGGERED_btns);
            if(param1["formation_id"])
            {
               _loc27_.text="战力 "+String(param1["formation_power"]);_loc27_.fontSize=23;
               _loc18_.visible=false;
               mBtn_pk.text=param1["compatible"]?"挑战":"不兼容";mBtn_pk.y=4;mBtn_pk.height=50;
               formationDelete104=new LOL_Scale9Button("删除",85,38,"UI_btn_normalFun_0000");
               formationDelete104.fontSize=20;formationDelete104.x=mBtn_pk.x;formationDelete104.y=66;
               formationDelete104.addEventListener("triggered",deleteFormation104);addChild(formationDelete104);
            }''')
s=once(s,'         if(mBtn_pk.alpha < 1)','''         if(_data["formation_id"])
         {
            if(!_data["compatible"]) {GlobalFunction.popError("阵容与当前战斗规则不兼容，请导入同版本代码。");return;}
            GlobalData.$formationShare104={mode:"challenge",id:_data["formation_id"]};
            GlobalData.$pvp_rival=data;GlobalData.$pvp_Embattle=_data["name"];
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp_embattle",false,true);return;
         }
         GlobalData.$formationShare104={};
         if(mBtn_pk.alpha < 1)''')
part='''      private function deleteFormation104(event:Event) : void
      {
         var id:String=String(_data["formation_id"]);
         GlobalFunction.popAlert("删除阵容","删除这份敌阵？之后仍可重新导入代码。",{
            ok:function():void
            {
               SendAndSelect.sendAndSelectService("user.delete_formation",{formation_id:id,actionID:"formation-delete-"+new Date().time+"-"+Math.random()},function(reply:Object):void
               {
                  if(reply && reply.return_code==0) GlobalData.$mEventDispatcher.dispatchEventWith("formation_library_changed");
               });
            },okUI:"删除",no:function():void{},noUI:"取消"});
      }
'''
if '// BEGIN FORMATION DELETE 104' not in s:
    at=s.rfind('\n   }\n}');s=s[:at]+'\n      // BEGIN FORMATION DELETE 104\n'+part+s[at:]
write(p,s)

p='client/src/stages/175_GameMap.as';s=read(p)
s=once(s,'SendServiceAMFFun.send_user_pk_combat_pvp(reSend,_obj);','''if(GlobalData.$formationShare104 && GlobalData.$formationShare104.mode=="challenge")
            {
               _obj.formation_id=GlobalData.$formationShare104.id;
               SendAndSelect.sendAndSelectService("user.pk_combat_formation",_obj,reSend);
            }
            else SendServiceAMFFun.send_user_pk_combat_pvp(reSend,_obj);''')
s=once(s,'re.data.fight_kind == "pvp" || re.data.fight_kind == "fragment")','re.data.fight_kind == "pvp" || re.data.fight_kind == "fragment" || re.data.fight_kind == "formation")')
s=methods(s,'client/src/formation_map_104.aspart','FORMATION MAP 104');write(p,s)

p='client/src/stages/163_UiLayer.as';s=read(p)
s=once(s,'   import com.meng52.game.ui.effect.BaseLayer;','   import com.meng52.game.ui.effect.BaseLayer;\n   import com.meng52.game.ui.screen.PanelCenterPVP;')
s=once(s,'         if(GameMap.isLoadFile && (GameMap.lastCid == "pvp" || GameMap.lastCid == "extreme"))','''         if(GameMap.currentMap && GameMap.currentMap.re && GameMap.currentMap.re.data.fight_kind=="formation")
         {
            GlobalData.$formationShare104={};PanelCenterPVP.$tabBarSelectedIndex=4;
            GlobalData.$mGameClassObject.mLayoutUICenter.mCurrPanel="center_pvp";
            GlobalData.$mEventDispatcher.dispatchEventWith("stage_ui");return;
         }
         if(GameMap.isLoadFile && (GameMap.lastCid == "pvp" || GameMap.lastCid == "extreme"))''')
write(p,s)

p='client/src/stages/180_PanelPVEembattle.as'
if not (ROOT/p).exists():
    write(p,read('build/formation-share/decompiled/scripts/com/meng52/game/ui/panel/PanelPVEembattle.as'))
s=read(p)
s=once(s,'this.mBtn_play.name = "btn_name_play";','this.mBtn_play.name = "btn_name_play";\n         if(GlobalData.$formationShare104 && GlobalData.$formationShare104.mode=="export") this.mBtn_play.text="导出";')
s=once(s,'         else if(_loc10_.name == "btn_name_play")\n         {','''         else if(_loc10_.name == "btn_name_play")
         {
            if(GlobalData.$formationShare104 && GlobalData.$formationShare104.mode=="export")
            {
               if(!GameMap.currentMap.checkStart()) popLaneCoverageError();
               else GameMap.currentMap.exportFormation104();
               return;
            }''')
s=once(s,'      override public function onTRIGGERED(param1:Event) : void\n      {','''      override public function onTRIGGERED(param1:Event) : void
      {
         if(GlobalData.$formationShare104 && GlobalData.$formationShare104.mode)
         {
            GlobalData.$formationShare104={};
            com.meng52.game.ui.screen.PanelCenterPVP.$tabBarSelectedIndex=4;
            GlobalData.$mGameClassObject.closePopForPanel();
            GlobalData.$mGameClassObject.mLayoutUICenter.mCurrPanel="";
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp");return;
         }''')
write(p,s)

manifest=ROOT/'client/build.json';cfg=json.loads(manifest.read_text('utf-8'))
if not any(row['source']==p for row in cfg['stages']):
    cfg['stages'].append(dict(index=len(cfg['stages'])+1,source=p,**{'class':'com.meng52.game.ui.panel.PanelPVEembattle'}))
cfg['stage_count']=len(cfg['stages']);cfg['unique_class_count']=len({r['class'] for r in cfg['stages']})
for row in cfg['stages']:row['source_sha256']=hashlib.sha256((ROOT/row['source']).read_bytes()).hexdigest()
manifest.write_text(json.dumps(cfg,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Formation UI integrated:',cfg['stage_count'],'client stages')
