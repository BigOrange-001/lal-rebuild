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
      private var shareInput104:TextInput;
      private var shareNameInput104:TextInput;
      private var formationHeader104:Sprite;
      private var formationEmpty104:Sprite;
      private var formationStrip104:TextField;''')
s=once(s,'GlobalData.$mEventDispatcher.addEventListener("update_signup",afterSignUpdate);','GlobalData.$mEventDispatcher.addEventListener("update_signup",afterSignUpdate);\n         GlobalData.$mEventDispatcher.addEventListener("formation_library_changed",loadFormations104);\n         GlobalData.$mEventDispatcher.addEventListener("formation_action",onFormationAction104);')
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
         clearFormationControls104();''')
s=once(s,'      override public function onREMOVED_FROM_STAGE(param1:Event) : void\n      {','''      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         closeFormationCode104();clearFormationControls104();
         GlobalData.$mEventDispatcher.removeEventListener("formation_library_changed",loadFormations104);
         GlobalData.$mEventDispatcher.removeEventListener("formation_action",onFormationAction104);''')
anchor='''         if(mFun_status)
         {
            selectMsg();
         }
         else
         {
            selectList(true);
         }
         checkGuide();'''
s=once(s,anchor,'''         if(mTabBar.selectedIndex==4)
         {
            addFormationControls104();
            formationRows104=[];setList();loadFormations104();
            consumeFormationCode104();
         }
         else
         {
            if(mFun_status) selectMsg();else selectList(true);
            checkGuide();
         }''')
s=once(s,'else if(this.mTabBar.selectedIndex == 3)\n         {\n            setPVPList_listData();','else if(this.mTabBar.selectedIndex == 3 || this.mTabBar.selectedIndex == 4)\n         {\n            setPVPList_listData();')
s=once(s,'         if(mTabBar.selectedIndex == 1)\n         {\n            i = 0;','''         if(mTabBar.selectedIndex==4)
         {
            delTips();showFormationList104();
            return;
         }
         if(mTabBar.selectedIndex == 1)
         {
            i = 0;''')
s=once(s,'if(mTxt_pkTimes && mPVP_list.length > 6)','if(mTxt_pkTimes && mPVP_list.length > 6 && mTabBar.selectedIndex==1)')
s=once(s,'if(mTabBar.selectedIndex != 0)\n         {\n            this.setList();\n            this.addList();','if(mTabBar.selectedIndex == 1)\n         {\n            this.setList();\n            this.addList();\n            if(shareModal104) addChild(shareModal104);')
s=methods(s,'client/src/formation_share_104.aspart','FORMATION PANEL 104');write(p,s)

p='client/src/stages/047_ItemPVP.as';s=read(p)
s=once(s,'   import feathers.controls.renderers.IListItemRenderer;','   import feathers.controls.renderers.IListItemRenderer;\n   import com.meng52.net.SendAndSelect;')
s=once(s,'      protected var mBtn_pk:LOL_Scale9Button;','      protected var mBtn_pk:LOL_Scale9Button;\n      private var formationButtons104:Array;')
s=once(s,'      override public function onREMOVED_FROM_STAGE(param1:Event) : void\n      {','      override public function onREMOVED_FROM_STAGE(param1:Event) : void\n      {\n         for each(var formationButton104:LOL_Scale9Button in formationButtons104) formationButton104.removeFromParent(true);\n         formationButtons104=null;')
s=once(s,'      override public function init(param1:Object) : void\n      {','      override public function init(param1:Object) : void\n      {\n         if(param1["formation_id"])\n         {\n            initFormation104(param1);\n            return;\n         }')
s=once(s,'         if(mBtn_pk.alpha < 1)','         GlobalData.$formationShare104={};\n         if(mBtn_pk.alpha < 1)')
s=methods(s,'client/src/formation_item_104.aspart','FORMATION ITEM 104')
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
s=once(s,'this.mBtn_play.name = "btn_name_play";','this.mBtn_play.name = "btn_name_play";\n         if(GlobalData.$formationShare104 && GlobalData.$formationShare104.mode=="export") this.mBtn_play.text="导出阵容";')
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
