package com.meng52.game.module.talent
{
   import com.meng52.game.command.talent.TalentData;
   import com.meng52.game.command.talent.TalentManager;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.module.BaseDisplayModule;
   import starling.display.Sprite;

   public class Talent extends BaseDisplayModule
   {

      public var id:String;

      public var my_data:Object;

      public var my_HaloData:TalentData;

      public function Talent(param1:String)
      {
         super();
         id = param1;
         my_HaloData = TalentManager.getOnlyExample().getData(id);
         if(MainConfig.$gameLanguage == "tw")
         {
            my_HaloData.info = my_HaloData.dataObj.info_tw;
            my_HaloData.name = my_HaloData.dataObj.name_tw;
         }
         else
         {
            my_HaloData.info = my_HaloData.dataObj.info;
            my_HaloData.name = my_HaloData.dataObj.name;
         }
         trace("");
      }

      public static function getImage(param1:String) : Sprite
      {
         var row:Object = GlobalData.$mConfig_talent[param1];
         if(row && row.icon)
         {
            var result:Sprite = new Sprite();
            result.addChild(GlobalFunction.createImage("all000"+Math.max(0,Math.min(5,int(row.rank)-2))));
            result.addChild(GlobalFunction.createImage(String(row.icon)));
            return result;
         }
         var _loc2_:Sprite = new Sprite();
         var _loc4_:int = int(param1.split("_")[2]);
         var _loc5_:String = param1.split("_")[1];
         var _loc3_:String = param1.split("_")[0] + "_" + _loc5_.split("")[0] + _loc5_.split("")[1] + _loc5_.split("")[2] + "0000";
         _loc2_.addChild(GlobalFunction.createImage("all000" + (_loc4_ - 2)));
         _loc2_.addChild(GlobalFunction.createImage(_loc3_));
         return _loc2_;
      }

      public function clear() : void
      {
         this.deleteResourceObj();
      }

      public function getPower() : Number
      {
         var _loc1_:uint = uint(my_HaloData.getStar());
         var _loc2_:Array = GlobalData.$mConfig_simple.talent_power;
         return _loc2_[_loc1_ - 2];
      }
   }
}
