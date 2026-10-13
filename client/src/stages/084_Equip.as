package com.meng52.game.module.equip
{
   import com.meng52.game.command.equip.EquipData;
   import com.meng52.game.command.equip.EquipManager;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.module.BaseDisplayModule;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.module.skill.SkillSet;
   import com.meng52.game.ui.screen.PanelCenterDNTeam;
   import com.meng52.utils.Tools;
   import starling.display.Image;
   import starling.display.Sprite;
   
   public class Equip extends BaseDisplayModule
   {
      
      public static const haloColor:Array = [14869218,944934,1384860,7015559,15329540];
      
      public var id:String;
      
      public var lv:int = 0;
      
      public var slv:int = 0;
      
      public var sexp:Number = 0;
      
      public var hit:int;
      
      public var flee:int = 0;
      
      public var crit:int = 0;
      
      public var tough:int = 0;
      
      public var haloLv:int;
      
      public var haloExp:int;
      
      public var skill:SkillSet;
      
      public var symp:int;
      
      public var magic:Array;
      
      public var mDestiny:Object;
      
      public var my_data:Object;
      
      public var _Properties_rate:Number = 1;
      
      public function Equip(param1:String, param2:Object = null)
      {
         var _loc5_:Object = null;
         var _loc3_:Array = null;
         var _loc4_:String = null;
         super();
         my_data = param2;
         if(param1.indexOf("_") >= 0)
         {
            m_data = EquipManager.getOnlyExample().getData(param1);
         }
         else
         {
            if(!param2)
            {
               param2 = getMyEquipData(param1);
            }
            id = param1;
            m_data = EquipManager.getOnlyExample().getData(param2.eid);
         }
         if(my_data != null && my_data.hasOwnProperty("alchemy"))
         {
            _loc5_ = GlobalData.$mConfig_simple.equip_alchemy;
            _loc3_ = (my_data.eid as String).split("_");
            _loc4_ = (int(_loc3_[_loc3_.length - 1]) + int(my_data.alchemy[1])).toString() + "_" + int(my_data.alchemy[0]).toString();
            if((_loc5_.phase as Object).hasOwnProperty(_loc4_))
            {
               _Properties_rate = getEquipAlchemyRate(my_data,0);
            }
            else
            {
               _Properties_rate = 1;
            }
         }
         else
         {
            _Properties_rate = 1;
         }
         init(param2);
      }
      
      public function getEquipAlchemyRate(param1:Object, param2:int) : Number
      {
         var _loc4_:int = param2;
         var _loc7_:Array = (param1.eid as String).split("_");
         var _loc5_:Number = 1;
         var _loc10_:Object = GlobalData.$mConfig_simple.equip_alchemy;
         var _loc3_:String = _loc7_[_loc7_.length - 1] + "_0";
         var _loc8_:String = (int(_loc7_[_loc7_.length - 1]) + int(param1["alchemy"][1])).toString() + "_" + param1["alchemy"][0];
         var _loc6_:Object = _loc10_.phase;
         for(var _loc9_:String in _loc6_)
         {
            if(_loc9_ > _loc3_ && _loc9_ <= _loc8_)
            {
               _loc5_ *= Number(_loc6_[_loc9_][_loc4_]);
            }
         }
         return _loc5_;
      }
      
      public function setDestinyAndDN() : void
      {
         mDestiny = PanelCenterDNTeam.getDestinyByEquip(this.baseData.id);
      }
      
      public function getSympStr() : String
      {
         var _loc1_:String = MainConfig.$magic_two;
         var _loc2_:Array = _loc1_.split(",");
         return GlobalLanguageStr.getLanguageStr(_loc2_[symp + 1]);
      }
      
      public function getSympTypeStr() : String
      {
         var _loc1_:Array = [0,20283,20284,20285,20286];
         return GlobalLanguageStr.getLanguageStr(_loc1_[symp + 1]);
      }
      
      public function getSympColor() : uint
      {
         var _loc1_:Array = [11184810,49152,16728064,12623936,4243711];
         return _loc1_[symp + 1];
      }
      
      public function getRes(param1:Sprite = null, param2:Number = 1) : Sprite
      {
         var _loc3_:Sprite = null;
         var _loc4_:Object = null;
         var _loc5_:Array = null;
         var _loc9_:Array = null;
         var _loc8_:int = 0;
         var _loc11_:String = null;
         var _loc14_:String = null;
         var _loc13_:Image = null;
         var _loc7_:Image = null;
         var _loc12_:Number = NaN;
         var _loc10_:Number = NaN;
         if(param1 == null)
         {
            _loc3_ = new Sprite();
         }
         else
         {
            _loc3_ = param1;
         }
         var _loc6_:Image = GlobalFunction.getEquipUI(equipData.res);
         _loc6_.scaleX = _loc6_.scaleY = param2;
         _loc3_.addChild(_loc6_);
         if(my_data && my_data.hasOwnProperty("alchemy"))
         {
            _loc4_ = GlobalData.$mConfig_simple.equip_alchemy;
            _loc5_ = my_data["alchemy"];
            _loc9_ = (my_data.eid as String).split("_");
            _loc8_ = int(_loc9_[_loc9_.length - 1]) - int(_loc4_.equip_al);
            _loc11_ = (int(_loc5_[0]) + (int(_loc5_[1]) + _loc8_) * 3 - 1).toString();
            if((int(_loc11_)) >= 0)
            {
               _loc14_ = "UI_equip_box_000" + _loc11_;
               _loc13_ = GlobalFunction.createImage(_loc14_);
               _loc13_.scaleX = _loc13_.scaleY = param2;
               _loc3_.addChild(_loc13_);
            }
         }
         if(symp >= 0)
         {
            _loc7_ = GlobalFunction.getSympUI(symp,false);
            _loc12_ = int(_loc7_.width * 0.5);
            _loc10_ = int(_loc7_.height * 0.5);
            _loc7_.name = "sympClip";
            _loc3_.addChild(_loc7_);
            _loc7_.x = 90 - _loc12_;
            _loc7_.y = _loc10_;
         }
         return _loc3_;
      }
      
      public function getBookSkill(param1:Avatar = null) : SkillSet
      {
         if(!skill)
         {
            if(equipData.skill && equipData.skill != "")
            {
               skill = new SkillSet(equipData.skill,param1,slv);
            }
         }
         return skill;
      }
      
      public function getBookUpGold() : int
      {
         var _loc1_:Array = equipData.id.split("_");
         return slv * _loc1_[2] * GlobalData.$mConfig_simple.skill_book_exp[5];
      }
      
      public function getMyEquipData(param1:String) : *
      {
         var _loc2_:Object = GlobalData.$userData;
         var _loc3_:* = _loc2_.my_equips;
         return _loc3_[param1];
      }
      
      public function get equipData() : EquipData
      {
         return m_data as EquipData;
      }
      
      public function getHaloExpMax() : int
      {
         var _loc1_:Array = GlobalData.$mConfig_simple.equipwash;
         if(haloLv >= _loc1_[5])
         {
            return -1;
         }
         return _loc1_[0] * Math.pow(_loc1_[1],haloLv) * getStar();
      }
      
      public function getHaloUpAttrs() : Number
      {
         var _loc1_:Array = GlobalData.$mConfig_simple.equipwash;
         return 1 + _loc1_[4] * haloLv;
      }
      
      public function wash(param1:int, param2:Boolean) : void
      {
         var _loc4_:int = 0;
         var _loc3_:Array = GlobalData.$mConfig_simple.equipwash;
         if(!param2)
         {
            _loc4_ = _loc3_[2] * param1;
         }
         else
         {
            _loc4_ = _loc3_[3] * param1;
         }
         addHaloExp(_loc4_);
      }
      
      public function addHaloExp(param1:int) : void
      {
         var _loc2_:Array = GlobalData.$mConfig_simple.equipwash;
         if(haloLv >= _loc2_[5])
         {
            haloLv = _loc2_[5];
            haloExp = 0;
            return;
         }
         haloExp += param1;
         while(haloExp >= getHaloExpMax())
         {
            haloExp -= getHaloExpMax();
            haloLv += 1;
            if(haloLv >= _loc2_[5])
            {
               haloLv = _loc2_[5];
               haloExp = 0;
               return;
            }
         }
      }
      
      public function getStar() : int
      {
         return int(int(equipData.id.split("_")[2]) + getAddStar());
      }
      
      public function getAddStar() : int
      {
         var _loc1_:Array = null;
         var _loc2_:int = 0;
         if(my_data && my_data.hasOwnProperty("alchemy"))
         {
            _loc1_ = my_data["alchemy"];
            _loc2_ = int(_loc1_[_loc1_.length - 1]);
         }
         return _loc2_;
      }
      
      public function getProStar() : int
      {
         return int(equipData.id.split("_")[2]);
      }
      
      public function getStep() : int
      {
         var _loc3_:Array = null;
         var _loc1_:int = 0;
         var _loc2_:int = -1;
         if(my_data && my_data.hasOwnProperty("alchemy"))
         {
            _loc3_ = my_data["alchemy"];
            _loc1_ = int(GlobalData.$mConfig_simple.equip_alchemy.star_lv);
            if(int(_loc3_[1]) + getProStar() != _loc1_)
            {
               _loc2_ = int(_loc3_[0]);
            }
         }
         return _loc2_;
      }
      
      public function getType() : int
      {
         return int(equipData.id.slice(2,3));
      }
      
      public function getIdValue() : Number
      {
         return 0.001 * equipData.id.split("_")[1];
      }
      
      public function getBookValue() : Number
      {
         var _loc1_:Number = NaN;
         if(getType() != 6)
         {
            return -1;
         }
         var _loc2_:int = getStar();
         _loc1_ = 90000;
         _loc1_ -= _loc2_ * 20000;
         _loc1_ -= (slv - 1) * 15000;
         if(GlobalFunction.checkEquipHasUsed(id) >= 0)
         {
            _loc1_ -= 10000000;
         }
         return _loc1_ + getIdValue();
      }
      
      public function getSellValue() : Number
      {
         var _loc3_:Number = 0;
         var _loc4_:int = magic[0] + magic[1] + magic[2] + magic[3];
         var _loc2_:int = getSellMark();
         var _loc5_:int = getSellGold();
         var _loc6_:int = getStar();
         var _loc1_:int = getType();
         _loc3_ = Math.pow(_loc5_,0.5) + 450000;
         if(_loc1_ == 6)
         {
            _loc3_ -= 4000000;
         }
         else if(_loc1_ == 4)
         {
            _loc3_ -= 3000000 + (slv - 1) * 10000;
         }
         if(_loc6_ >= 5)
         {
            _loc3_ -= 10000000;
         }
         _loc3_ -= _loc1_ * 10;
         _loc3_ -= _loc6_ * 100000;
         _loc3_ -= Math.pow(lv - 1,2) * 500;
         if(_loc2_)
         {
            _loc3_ -= 60000 + _loc2_ * 10;
         }
         if(_loc4_)
         {
            _loc3_ -= 120000 + _loc4_ * 40;
         }
         if(GlobalFunction.checkEquipHasUsed(id) != -1)
         {
            _loc3_ -= 40000000;
         }
         return _loc3_ + getIdValue();
      }
      
      public function getSellDust() : Array
      {
         var _loc3_:Array = null;
         var _loc5_:int = 0;
         var _loc2_:Array = [0,0,0,0];
         var _loc4_:int = getStar() - 3;
         var _loc1_:int = getType();
         if(_loc1_ == 1)
         {
            _loc1_ = 0;
         }
         else
         {
            _loc1_ -= 2;
         }
         if(_loc4_ >= 0 && _loc4_ < 4)
         {
            var _loc6_:* = _loc4_;
            var _loc7_:* = _loc2_[_loc6_] + GlobalData.$mConfig_simple.dust.tear[_loc1_][_loc4_];
            _loc2_[_loc6_] = _loc7_;
         }
         else if(_loc4_ >= 4)
         {
            _loc3_ = GlobalData.$mConfig_simple.dust.tear[_loc1_][_loc4_];
            _loc2_ = [0,0,_loc3_[0],_loc3_[1]];
         }
         _loc5_ = 0;
         while(_loc5_ < 4)
         {
            _loc7_ = _loc5_;
            _loc6_ = _loc2_[_loc7_] + Math.ceil(magic[_loc5_] * GlobalData.$mConfig_simple.dust["return"]);
            _loc2_[_loc7_] = _loc6_;
            _loc5_++;
         }
         return _loc2_;
      }
      
      public function getPoint(param1:int = -1) : int
      {
         if(param1 < 0)
         {
            param1 = lv;
         }
         return int(GlobalData.$mConfig_simple.equip_config[2] * getStar() * param1);
      }
      
      public function getPoteMax(param1:int = -1) : int
      {
         if(param1 < 0)
         {
            param1 = lv;
         }
         return int((GlobalData.$mConfig_simple.equip_config[2] * 4 + GlobalData.$mConfig_simple.equip_config[3]) * getStar() * param1);
      }
      
      public function getPoteNow(param1:int = -1) : int
      {
         return int(getPoteMax(param1) - (getHit(param1) + getFlee(param1) + getCrit(param1) + getTough(param1)));
      }
      
      public function getHit(param1:int = -1, param2:Boolean = false) : int
      {
         if(param2 && !hasHit())
         {
            return 0;
         }
         return int(hit + getPoint(param1));
      }
      
      public function getFlee(param1:int = -1, param2:Boolean = false) : int
      {
         if(param2 && !hasFlee())
         {
            return 0;
         }
         return int(flee + getPoint(param1));
      }
      
      public function getCrit(param1:int = -1, param2:Boolean = false) : int
      {
         if(param2 && !hasCrit())
         {
            return 0;
         }
         return int(crit + getPoint(param1));
      }
      
      public function getTough(param1:int = -1, param2:Boolean = false) : int
      {
         if(param2 && !hasTough())
         {
            return 0;
         }
         return int(tough + getPoint(param1));
      }
      
      public function getfalseNum(param1:int = -1) : int
      {
         var _loc2_:int = 0;
         if(hasHit())
         {
            _loc2_ += this.getHit(param1);
         }
         if(hasFlee())
         {
            _loc2_ += this.getFlee(param1);
         }
         if(hasCrit())
         {
            _loc2_ += this.getCrit(param1);
         }
         if(hasTough())
         {
            _loc2_ += this.getTough(param1);
         }
         return _loc2_;
      }
      
      public function hasHit() : Boolean
      {
         return equipData.hasAttr("hit");
      }
      
      public function hasFlee() : Boolean
      {
         return equipData.hasAttr("flee");
      }
      
      public function hasCrit() : Boolean
      {
         return equipData.hasAttr("crit");
      }
      
      public function hasTough() : Boolean
      {
         return equipData.hasAttr("tough");
      }
      
      public function getRiseGold(param1:int = -1) : int
      {
         if(param1 < 0)
         {
            param1 = lv;
         }
         var _loc4_:Object = GlobalData.$mConfig_simple.equip_alchemy.phase;
         var _loc2_:Number = 1;
         if(my_data && my_data.hasOwnProperty("alchemy"))
         {
            _loc2_ = getEquipAlchemyRate(my_data,2);
         }
         var _loc6_:Number = Number(GlobalData.$mConfig_simple.equip_config[4]);
         var _loc5_:Number = Number(GlobalData.$mConfig_simple.equip_config[5]);
         var _loc7_:Number = Number(GlobalData.$mConfig_simple.equipstar_gold[getStar() - 1]);
         var _loc3_:Object = {
            "a1":0,
            "a2":0,
            "a3":1,
            "a4":2,
            "a5":3
         };
         var _loc8_:Number = Number(GlobalData.$mConfig_simple.equipspace_gold[_loc3_["a" + getType()]]);
         _loc3_ = null;
         return Tools.toInt((_loc5_ + _loc6_ * param1 * param1 * param1) * _loc7_ * _loc8_ * _loc2_);
      }
      
      public function getAlchemyGold(param1:String) : int
      {
         var _loc4_:Object = GlobalData.$mConfig_simple.equip_alchemy.phase;
         var _loc3_:Number = Number(_loc4_[param1][2]);
         var _loc2_:Object = {
            "a1":0,
            "a2":0,
            "a3":1,
            "a4":2,
            "a5":3
         };
         var _loc5_:Number = Number(GlobalData.$mConfig_simple.equipspace_gold[_loc2_["a" + getType()]]);
         _loc2_ = null;
         return _loc3_ * _loc5_;
      }
      
      public function getSellGold(param1:int = -1) : int
      {
         var _loc2_:Number = NaN;
         var _loc5_:Number = NaN;
         var _loc3_:Number = NaN;
         var _loc4_:Number = NaN;
         var _loc11_:Number = NaN;
         var _loc12_:int = 0;
         var _loc8_:int = 0;
         var _loc6_:int = 0;
         var _loc9_:Number = NaN;
         var _loc10_:Boolean = GlobalFunction.checkEquipIsBook(equipData.id);
         var _loc7_:Number = 0;
         if(_loc10_)
         {
            _loc2_ = equipData.d0;
            _loc5_ = Number(GlobalData.$mConfig_simple.skill_book_exp[0]);
            _loc3_ = Number(GlobalData.$mConfig_simple.skill_book_exp[1]);
            _loc4_ = Number(GlobalData.$mConfig_simple.skill_book_exp[2]);
            _loc11_ = _loc2_ * (_loc5_ / 3 * Math.pow(slv,3) + (_loc3_ - _loc5_) / 2 * Math.pow(slv,2) + (_loc5_ / 6 - _loc3_ / 2 + _loc4_) * slv - _loc4_);
            _loc7_ = (_loc11_ + sexp) * GlobalData.$mConfig_simple.skill_book_exp[6] + equipData.offerGold;
         }
         else
         {
            _loc12_ = 0;
            _loc8_ = lv - 1;
            _loc6_ = 0;
            _loc9_ = Number(GlobalData.$mConfig_simple.equip_config[6]);
            _loc12_ = _loc8_;
            while(_loc12_ > 0)
            {
               _loc6_ += getRiseGold(_loc12_);
               _loc12_--;
            }
            _loc6_ *= _loc9_;
            _loc7_ = _loc6_ + baseData.dataObj.gold;
         }
         return _loc7_;
      }
      
      public function getSellMark(param1:int = -1) : int
      {
         return (hit + flee + crit + tough) / GlobalData.$mConfig_simple.equip_config[10] * getWashMark();
      }
      
      public function getWashMark(param1:int = -1, param2:int = 1) : int
      {
         return getStar() * GlobalData.$mConfig_simple.equip_config[7] * param2;
      }
      
      public function getWashCoin(param1:int = -1, param2:int = 1) : int
      {
         return (GlobalData.$mConfig_simple.equip_config[8] + GlobalData.$mConfig_simple.equip_config[9] * getStar()) * param2;
      }
      
      private function getNativeStatGrowth(param1:int) : Number
      {
         var _loc2_:Array = GlobalData.$mConfig_simple.equip_growth_curve_ppm as Array;
         if(param1 < 1)
         {
            param1 = 1;
         }
         if(param1 > 200)
         {
            param1 = 200;
         }
         if(_loc2_ != null && _loc2_.length >= 200 && Number(_loc2_[param1 - 1]) > 0)
         {
            return Number(_loc2_[param1 - 1]) / 1000000;
         }
         return 1 + GlobalData.$mConfig_simple.equip_config[1] * (param1 - 1);
      }

      private function getPersistedStatRollRate() : Number
      {
         var _loc1_:Number = 1000000;
         if(my_data != null && my_data.hasOwnProperty("stat_roll_ppm"))
         {
            _loc1_ = Number(my_data.stat_roll_ppm);
            if(isNaN(_loc1_))
            {
               _loc1_ = 1000000;
            }
         }
         _loc1_ = Math.max(850000,Math.min(1200000,_loc1_));
         return _loc1_ / 1000000;
      }

      public function getMagicBonus(param1:int) : int
      {
         if(param1 < 0 || param1 >= 4 || magic == null || param1 >= magic.length)
         {
            return 0;
         }
         var _loc1_:int = Math.max(0,int(magic[param1]));
         var _loc2_:Object = GlobalData.$mConfig_simple.equipment_magic;
         var _loc3_:Array = _loc2_ == null ? null : _loc2_.stat_per_level as Array;
         var _loc4_:int = _loc3_ == null || param1 >= _loc3_.length ? 1 : Math.max(0,int(_loc3_[param1]));
         return _loc1_ * _loc4_;
      }

      public function getHpMax(param1:int = -1, param2:Boolean = false) : int
      {
         if(param1 < 0)
         {
            param1 = lv;
         }
         var _loc3_:EquipData = equipData;
         var _loc4_:int = Tools.toInt(getNativeStatGrowth(param1) * _loc3_.hp0 * getPersistedStatRollRate() * getHaloUpAttrs() * _Properties_rate);
         if(param2)
         {
            _loc4_ += getMagicBonus(0) + getMagicBonus(2);
         }
         return _loc4_;
      }
      
      public function getDamage(param1:int = -1, param2:Boolean = false) : int
      {
         if(param1 < 0)
         {
            param1 = lv;
         }
         var _loc3_:EquipData = equipData;
         var _loc4_:int = Tools.toInt(getNativeStatGrowth(param1) * _loc3_.ap0 * getPersistedStatRollRate() * getHaloUpAttrs() * _Properties_rate);
         if(param2)
         {
            _loc4_ += getMagicBonus(1) + getMagicBonus(3);
         }
         return _loc4_;
      }
      
      public function getDePh(param1:int = -1) : int
      {
         if(param1 < 0)
         {
            param1 = lv;
         }
         var _loc2_:EquipData = equipData;
         return Tools.toInt(getNativeStatGrowth(param1) * _loc2_.d10 * getPersistedStatRollRate() * getHaloUpAttrs() * _Properties_rate);
      }
      
      public function getDeMa(param1:int = -1) : int
      {
         if(param1 < 0)
         {
            param1 = lv;
         }
         var _loc2_:EquipData = equipData;
         return Tools.toInt(getNativeStatGrowth(param1) * _loc2_.d20 * getPersistedStatRollRate() * getHaloUpAttrs() * _Properties_rate);
      }
      
      public function getSpeed() : int
      {
         return Tools.toInt(equipData.speed * getHaloUpAttrs());
      }
      
      public function getRange() : int
      {
         return Tools.toInt(equipData.range * getHaloUpAttrs());
      }
      
      public function init(param1:Object) : void
      {
         if(param1)
         {
            lv = param1.lv;
            slv = param1.slv ? param1.slv : 1;
            sexp = param1.sexp ? param1.sexp : 0;
            if(param1.new_4attrs)
            {
               hit = param1.new_4attrs.hit;
               flee = param1.new_4attrs.flee;
               crit = param1.new_4attrs.crit;
               tough = param1.new_4attrs.tough;
            }
            if(param1.halo)
            {
               haloLv = param1.halo.lv;
               haloExp = param1.halo.exp;
            }
            symp = param1.symp == undefined ? -1 : param1.symp;
            magic = param1.magic == undefined ? [0,0,0,0] : param1.magic;
         }
         else
         {
            lv = 1;
            slv = 1;
            sexp = 0;
            symp = -1;
            magic = [0,0,0,0];
         }
         if(lv <= 0)
         {
            lv = 1;
         }
      }
      
      public function clear() : void
      {
         this.deleteResourceObj();
      }
   }
}

