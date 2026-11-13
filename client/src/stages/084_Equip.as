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
   import flash.display.BitmapData;
   import flash.geom.Rectangle;
   import starling.display.Image;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.textures.Texture;
   
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

      public var magicStage5:int = 0;

      public var runeLv:int = 0;
      
      public var mDestiny:Object;
      
      public var my_data:Object;
      
      public var _Properties_rate:Number = 1;
      
      public function Equip(param1:String, param2:Object = null)
      {
         var _loc5_:Object = null;
         var _loc3_:Array = null;
         var _loc4_:String = null;
         super();
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
         my_data = param2;
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
         var result:Sprite = param1 == null ? new Sprite() : param1;
         var previous:Sprite = result.getChildByName("alchemyFrame104") as Sprite;
         if(previous) previous.removeFromParent(true);
         var icon:Image = GlobalFunction.getEquipUI(equipData.res);
         icon.scaleX = icon.scaleY = param2;
         result.addChild(icon);
         var frame:Sprite = getAdvancedFrame104();
         if(frame)
         {
            frame.name = "alchemyFrame104";
            frame.touchable = false;
            frame.scaleX = frame.scaleY = param2;
            result.addChild(frame);
         }
         if(symp >= 0)
         {
            var badge:Image = GlobalFunction.getSympUI(symp,false);
            var halfWidth:Number = int(badge.width * 0.5);
            var halfHeight:Number = int(badge.height * 0.5);
            badge.name = "sympClip";
            result.addChild(badge);
            badge.x = 90 - halfWidth;
            badge.y = halfHeight;
         }
         return result;
      }

      private function getAdvancedFrame104() : Sprite
      {
         var star:int = getStar();
         if(star<2 || star<7 && star<=getProStar()) return null;
         var frame:Sprite = new Sprite();
         if(star>=7)
         {
            if(star==7)
            {
               frame.addChild(GlobalFunction.createImage("UI_equip_box_0005"));
            }
            else
            {
               addRainbowFrame104(frame);
            }
            var alchemy:Array = my_data ? my_data.alchemy as Array : null;
            var phase:int = alchemy && alchemy.length>0 ? Math.max(0,Math.min(2,int(alchemy[0]))) : 0;
            if(star==7 && phase>0) addAlchemyCorners104(frame,phase,92);
            return frame;
         }
         // The native quality icons also change the weapon artwork. Copy only
         // their border, keeping this equipment's original illustration intact.
         var texture:Texture = GlobalFunction.getTexture("EQ_1001_"+star+"0000");
         var w:Number = texture.width;
         var h:Number = texture.height;
         var areas:Array = [new Rectangle(0,0,8,8),new Rectangle(w-8,0,8,8),
            new Rectangle(0,h-8,8,8),new Rectangle(w-8,h-8,8,8),
            new Rectangle(8,0,w-16,3),new Rectangle(8,h-3,w-16,3),
            new Rectangle(0,8,3,h-16),new Rectangle(w-3,8,3,h-16)];
         for each(var area:Rectangle in areas)
         {
            var edge:Image = new Image(Texture.fromTexture(texture,area));
            edge.x = area.x;
            edge.y = area.y;
            frame.addChild(edge);
         }
         return frame;
      }

      private function addRainbowFrame104(frame:Sprite) : void
      {
         // Tint only the neutral native border. Its bevel, footprint and alpha
         // stay native, with no extra bitmap, glow or change to the illustration.
         var texture:Texture = GlobalFunction.getTexture("EQ_1001_20000");
         var w:Number = texture.width;
         var h:Number = texture.height;
         var midX:Number = Math.floor(w/2);
         var midY:Number = Math.floor(h/2);
         var red:uint = 0xFF586B;
         var orange:uint = 0xFFC267;
         var yellow:uint = 0xE8F16C;
         var green:uint = 0x66E08D;
         var cyan:uint = 0x67DEFF;
         var blue:uint = 0x7598FF;
         var purple:uint = 0xC17BFF;
         var pink:uint = 0xFF78C6;
         // Each piece stores its rectangle and TL/TR/BL/BR vertex colors.
         var pieces:Array = [
            [14,0,midX-14,3,red,orange,red,orange],
            [midX,0,w-midX-14,3,orange,yellow,orange,yellow],
            [14,h-3,midX-14,3,purple,blue,purple,blue],
            [midX,h-3,w-midX-14,3,blue,cyan,blue,cyan],
            [0,14,3,midY-14,red,red,pink,pink],
            [0,midY,3,h-midY-14,pink,pink,purple,purple],
            [w-3,14,3,midY-14,yellow,yellow,green,green],
            [w-3,midY,3,h-midY-14,green,green,cyan,cyan]];
         for each(var piece:Array in pieces)
         {
            var edge:Image = new Image(Texture.fromTexture(texture,new Rectangle(piece[0],piece[1],piece[2],piece[3])));
            edge.x = piece[0];
            edge.y = piece[1];
            for(var vertex:int=0;vertex<4;vertex++) edge.setVertexColor(vertex,uint(piece[4+vertex]));
            frame.addChild(edge);
            if(piece[2]>8 || piece[3]>8)
            {
               // A restrained one-pixel keyline lifts the native metal edge
               // without widening the frame or adding an external glow.
               var horizontal:Boolean = piece[2]>8;
               var keyline:Quad = new Quad(horizontal ? piece[2] : 1,horizontal ? 1 : piece[3]);
               keyline.x = piece[0]+(horizontal ? 0 : 1);
               keyline.y = piece[1]+(horizontal ? 1 : 0);
               keyline.alpha = 0.28;
               for(vertex=0;vertex<4;vertex++) keyline.setVertexColor(vertex,uint(piece[4+vertex]));
               frame.addChild(keyline);
            }
         }
         // Use the complete native corner relief: connected rim, metal socket,
         // faceted stone and inset shadow, rather than floating flat diamonds.
         var cornerTexture:Texture = getRainbowCornerTexture104();
         var positions:Array = [[0,0,0,0],[w-14,0,14,0],[w-14,h-14,14,14],[0,h-14,0,14]];
         var colors:Array = [red,yellow,cyan,purple];
         for(var i:int=0;i<positions.length;i++)
         {
            var position:Array = positions[i];
            var mount:Image = new Image(Texture.fromTexture(cornerTexture,new Rectangle(position[2],position[3],14,14)));
            mount.name = "rainbowCornerMount104";
            mount.x = position[0];
            mount.y = position[1];
            for(vertex=0;vertex<4;vertex++) mount.setVertexColor(vertex,uint(colors[i]));
            frame.addChild(mount);
            var gem:Image = new Image(Texture.fromTexture(cornerTexture,new Rectangle(position[2]+3,position[3]+3,8,8)));
            gem.name = "rainbowCornerGem104";
            gem.x = mount.x+3;
            gem.y = mount.y+3;
            for(vertex=0;vertex<4;vertex++) gem.setVertexColor(vertex,uint(colors[(vertex+i)%4]));
            frame.addChild(gem);
         }
      }

      private function getRainbowCornerTexture104() : Texture
      {
         var texture:Texture = GlobalData.$assetManager.getTexture("__equipRainbowCorners104");
         if(texture) return texture;
         // Exact native UI_equip_box_0003 14px corners, with color removed.
         // Each AALL pair preserves native alpha and relief brightness; the
         // four stones receive rainbow vertex colors separately from the rim.
         var rows:Array = [
            "2615cd27ff27ff27ff27ff16ff16ff16ff16ff0dff0dff0dff0dff0dff0dff0dff0dff23ff23ff23ff23ff23ff23ff23ff23bc05733d0000",
            "ff0bffc7ffc7ffc7ffc7ffb6ffb6ffb6ffb6ffe1ffe1ffe1ffe1ffe1ffe1ffe1ffe1ffc3ffc3ffc3ffc3ffc3ffc3ffc3ffc3ffa5fe3d732e",
            "ff15ffd5ff87ff5dff5dff4cff4cff4cff4cff3cff3cff73ff73ff4bff51ff51ff6eff50ff50ff50ff50ff1aff1aff1aff63ffa5ff3dfb1a",
            "ff21ffd5ff5dffd5ffd5ffc4ffc4ffc4ff9aff90ff73ff90ff3cff00ff1aff37ff6effc8ffc8ffc8ffc8ffa5ffa5ffa5ffa5ff6dff3dfb08",
            "ff19ffb3ff3bffffffffffe7ffe7ffe7ffe7ffffff9aff72ff38e502e502ff2eff44fff5ffffffe7ffe7ffcdffcdfffffffeff44ff38ff08",
            "ff19ffb3ff3bffffffffffffffffffffffffffdcff9aff72ff38e502e502ff2eff44ffc5fffffffffffffffffffffffffffeff44ff22ff02",
            "ff19ffb3ff3bffcdffffffffffffffffffceff9aff9aff72ff38e502e502ff2eff44ffc5fff5ffffffffffffffffffbcffbcff44ff2eff02",
            "ff19ffb3ff3bff84ffcdffceffffffffff85ff9aff9aff5eff38e502e502ff22ff44ff8dff8dffafffffffffff84ffbcffbcff44ff2eff02",
            "ff19ffb3ff3bffa3ffd3ffffffdcffffffffffabff87ff87ff45e40bd50cff3dff3dffb2ffdcfffffffffff5ffffffc5ffc5ff34ff34ff02",
            "ff19ff89ff3bffd3ffffffdcffb2ffb2ffffffd5ff87ff87ff45e40bd516ff3dff6dffb2ffffffdcffb2ffc5fff5fff5ffc5ff76ff34ff02",
            "ff19ffb3ff65ffa3ffa3ff90ff90ff90ff90ff87ff5dff87ff45cb15d516ff3dff6dff77ff99ff8dff8dff91ff91ff91ff6bff76ff34ff02",
            "ff19ff3bffb3ffa3ffa3ff8aff8aff8aff80ff87ffabffd0fd459321ab22fd3dffa5ff99ff83ff83ff8dff91ff91ff91ff91ffbfff34ff02",
            "ff10ff15ff15ff15ff15ff12ff08ff08ff0efa13fa13fa13c21d63055905b719ff0dff16ff16ff10ff10ff00ff0dff11ff27ffd8ff38ff02",
            "ff0afffbfffbff15c815ae0eae12ae12ae12921d921d921d5a0757005900590059199a209a1a9a1a9a1ab30db30dd01dff33ffd8ff38ff02",
            "ff25ff83ff83ff08c808ab0eab12ab12ab12921d92135a075a075a005a00560056006b16a31aa31aa31ab310b310d01dff1dff90ff3cff02",
            "ff25ff8dff77ff02ff02ff12ff08ff08ff0efa13fa13fa13921d5a005a009819e10dff16ff16ff10ff10ff06ff10ff13ff1dff73ff3cff02",
            "ff21ff72ff72ff9aff9aff88ff88ff88ff7cffa3ffa3ffa5fd3d87198722fd45ffd0ffa1ff84ff84ff84ff88ff88ff88ff88ff5dff26ff02",
            "ff21ff72ff4cff9aff9aff72ff72ff66ff66ff6bff6bff6dff3dd519d516ff45ff87ff6aff84ff84ff6aff66ff66ff66ff66ff40ff26ff00",
            "ff21ff72ff38ffdcffffffdeffdeffdeffdeffd3ffd3ff6dff3dd50dd516ff45ff87ffb2ffffffdcffdcffdeffdeffdeffdeff26ff26ff02",
            "ff0bff4cff38ffdcffffffffffffffffffffffffffd3ff3dff3dd50dd50cff45ff87ffb2ffffffffffffffffffffffffffdeff26ff26ff02",
            "ff15ff23ff23fff6fff6fffffffffffffffffff6ffd9ff44ff22e606de02ff37ff6effbcffe6fffffffffffffffffff6ffd9ff2bff27ff0a",
            "ff15ff23ff23ffa2ffd9ffdeffffffffff95ffa2ffbfff44ff2ee600de02ff37ff6eff6effbcffcdffffffffffdeffa2ffa2ff2bff21ff0a",
            "ff21ffaeff65ffa2ffa2ffdcffffffffffffffbfffbfff44ff2eef06de02ff37ff6eff6eff98ff84ffffffdeffffffa2ffa2ff2bff21ff06",
            "ff21ff65ff23ffbffff6ffffffb2ffb2fffffff6ffbfff44ff2eff0aff02ff37ff6eff98ffe6ffffffcdff95ffdefff6ffbfff2bff27ff0a",
            "ea25ff98ff56ff98ffe1ffa9ffa9ffa9ffa9ffa1ff84ff84ff4dff00ff00ff45ff87ff67fff2ffa9ffa9ffb2ffb2ffb2ff95ff2eff2eff14",
            "ea0bff56ff56ff56ff56ff67ff67ff67ff67ff4dff4dffa1ffa1ffa6ff87ff87ff87ff67ff67ff67ff67ff5eff5eff5eff5eff2eff2eea2e",
            "c80bff26ff40ff40ff40ff2bff2bff2bff2bff29ff29ff29ff29ff29ff29ff29ff29ff29ff29ff29ff29ff33ff27ff33ff27ff32ff0c4846",
            "00428540ff09ff09ff09ff05ff05ff05ff05ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff11ff11ff11ff11ff3248460032"];
         var bitmap:BitmapData = new BitmapData(28,28,true,0);
         for(var y:int=0;y<28;y++)
         {
            for(var x:int=0;x<28;x++)
            {
               var value:uint = uint(parseInt(String(rows[y]).substr(x*4,4),16));
               var light:uint = value & 255;
               bitmap.setPixel32(x,y,uint(((value>>>8)<<24)|(light*0x010101)));
            }
         }
         texture = Texture.fromBitmapData(bitmap,false,false);
         texture.root.onRestore = function():void { texture.root.uploadBitmapData(bitmap); };
         GlobalData.$assetManager.addTexture("__equipRainbowCorners104",texture);
         return texture;
      }

      private function addAlchemyCorners104(frame:Sprite,phase:int,height:Number) : void
      {
         // Keep the original +1 gold / +2 ruby corner ornaments, independently
         // of the seven-star red border and of the eligibility threshold.
         // Eight stars is terminal and always keeps the plain rainbow frame.
         var texture:Texture = GlobalFunction.getTexture(phase==1 ? "UI_equip_box_0003" : "UI_equip_box_0004");
         var areas:Array = [new Rectangle(0,0,8,8),new Rectangle(84,0,8,8),
            new Rectangle(0,84,8,8),new Rectangle(84,84,8,8)];
         for each(var area:Rectangle in areas)
         {
            var corner:Image = new Image(Texture.fromTexture(texture,area));
            corner.x = area.x;
            corner.y = area.y==0 ? 0 : height-8;
            frame.addChild(corner);
         }
      }

      public function getAlchemyColor104() : uint
      {
         var colors:Array = [0xAAAAAA,0xFFFFFF,0x6BFF87,0x65BFFF,0xDA79FF,0xFFCC66,0xFF586B,0xE6BDFF];
         return uint(colors[Math.max(0,Math.min(7,getStar()-1))]);
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
         var curve:Object = GlobalData.$mConfig_simple.wash_halo_curve;
         var itemLevel:int = curve ? Math.max(1,int(curve.reference_item_level || 100)) : Math.max(1,lv);
         var attempts:int = Math.ceil(Number(GlobalData.$mConfig_simple.equip_config[3]) * itemLevel / Math.max(5,int(itemLevel / 10)));
         if(curve && curve.schema == "weighted-five-rank-v1")
         {
            var totalExp:Number = attempts * Number(curve.wash_multiplier) * Number(curve.exp_per_wash);
            var weights:Array = curve.rank_weights as Array;
            var weightSum:Number = 0;
            var weightBefore:Number = 0;
            var weightAfter:Number = 0;
            var rank:int = 0;
            for(rank = 0; rank < weights.length; rank++)
            {
               weightSum += Number(weights[rank]);
               if(rank < haloLv) weightBefore += Number(weights[rank]);
               if(rank <= haloLv) weightAfter += Number(weights[rank]);
            }
            return Math.max(1,Math.ceil(totalExp * weightAfter / weightSum) - Math.ceil(totalExp * weightBefore / weightSum));
         }
         if(GlobalData.$mConfig_simple.wash_halo_sync)
         {
            return Math.max(1,Math.ceil(attempts / Math.max(1,int(GlobalData.$mConfig_simple.equipwash[5]))));
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
         var _loc1_:Array = my_data ? my_data.alchemy as Array : null;
         var _loc2_:int = 0;
         if(_loc1_ && _loc1_.length>1)
         {
            _loc2_ = int(_loc1_[1]);
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
            _loc1_ = Math.min(8,int(GlobalData.$mConfig_simple.equip_alchemy.star_lv));
            if(int(_loc3_[1]) + getProStar() < _loc1_)
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
         var result:Array = [0,0,0,0];
         var offset:int = getStar() - 3;
         var kind:int = getType();
         var rowIndex:int = kind == 1 ? 0 : kind - 2;
         var tear:Array = GlobalData.$mConfig_simple.dust.tear as Array;
         var row:Array = tear != null && rowIndex >= 0 && rowIndex < tear.length ? tear[rowIndex] as Array : null;
         if(row != null && offset >= 0 && offset < row.length)
         {
            if(offset < 4)
            {
               result[offset] = int(row[offset]);
            }
            else
            {
               var bonus:Array = row[offset] as Array;
               if(bonus != null && bonus.length > 0) result[2] = int(bonus[0]);
               if(bonus != null && bonus.length > 1) result[3] = int(bonus[1]);
            }
         }
         for(var index:int = 0; index < 4; index++)
         {
            if(magic != null && index < magic.length)
            {
               result[index] += Math.ceil(magic[index] * GlobalData.$mConfig_simple.dust["return"]);
            }
         }
         return result;
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
         return Math.max(0,int(getPoteMax(param1) - (getHit(param1) + getFlee(param1) + getCrit(param1) + getTough(param1))));
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
         var prices:Array = GlobalData.$mConfig_simple.equip_rise_cost as Array;
         return prices && param1 > 0 && param1 < prices.length ? int(prices[param1]) : 0;
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
         return (hit + flee + crit + tough) / GlobalData.$mConfig_simple.equip_config[10] * getStar() * GlobalData.$mConfig_simple.equip_config[7];
      }
      
      public function getWashMark(param1:int = -1, param2:int = 1) : int
      {
         var price:Number = Number(GlobalData.$mConfig_simple.equip_wash_mark_cost);
         if(!isFinite(price) || price <= 0) price = 1000;
         return int(price * param2);
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

      public function getMagicStage() : int
      {
         var _stage:int = 0;
         if(magic == null)
         {
            return 0;
         }
         for(var _i:int = 0; _i < 4; _i++)
         {
            if(_i >= magic.length || int(magic[_i]) <= 0)
            {
               break;
            }
            _stage++;
         }
         return _stage == 4 && magicStage5 == 1 ? 5 : _stage;
      }

      public function getMagicMainStatRate() : Number
      {
         var _rules:Object = GlobalData.$mConfig_simple.equipment_magic;
         return 1 + getMagicStage() * (_rules == null || _rules.stage_main_stat_step == undefined ? 0 : Number(_rules.stage_main_stat_step));
      }

      public function getRuneBonus(param1:int) : int
      {
         if(symp != param1 || runeLv <= 0)
         {
            return 0;
         }
         var _rules:Object = GlobalData.$mConfig_simple.equipment_magic;
         var _gains:Array = _rules == null ? null : _rules.rune_stat_per_level as Array;
         return _gains == null || param1 >= _gains.length ? 0 : runeLv * Math.max(0,int(_gains[param1]));
      }

      public function getHpMax(param1:int = -1, param2:Boolean = false) : int
      {
         if(param1 < 0)
         {
            param1 = lv;
         }
         var _loc3_:EquipData = equipData;
         var _loc4_:int = Tools.toInt(getNativeStatGrowth(param1) * _loc3_.hp0 * getPersistedStatRollRate() * getHaloUpAttrs() * _Properties_rate * getMagicMainStatRate());
         if(param2)
         {
            _loc4_ += getMagicBonus(0) + getMagicBonus(2);
         }
         return _loc4_ + getRuneBonus(0);
      }
      
      public function getDamage(param1:int = -1, param2:Boolean = false) : int
      {
         if(param1 < 0)
         {
            param1 = lv;
         }
         var _loc3_:EquipData = equipData;
         var _loc4_:int = Tools.toInt(getNativeStatGrowth(param1) * _loc3_.ap0 * getPersistedStatRollRate() * getHaloUpAttrs() * _Properties_rate * getMagicMainStatRate());
         if(param2)
         {
            _loc4_ += getMagicBonus(1) + getMagicBonus(3);
         }
         return _loc4_ + getRuneBonus(1);
      }
      
      public function getDePh(param1:int = -1) : int
      {
         if(param1 < 0)
         {
            param1 = lv;
         }
         var _loc2_:EquipData = equipData;
         return Tools.toInt(getNativeStatGrowth(param1) * _loc2_.d10 * getPersistedStatRollRate() * getHaloUpAttrs() * _Properties_rate * getMagicMainStatRate()) + getRuneBonus(2);
      }
      
      public function getDeMa(param1:int = -1) : int
      {
         if(param1 < 0)
         {
            param1 = lv;
         }
         var _loc2_:EquipData = equipData;
         return Tools.toInt(getNativeStatGrowth(param1) * _loc2_.d20 * getPersistedStatRollRate() * getHaloUpAttrs() * _Properties_rate * getMagicMainStatRate()) + getRuneBonus(3);
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
            magicStage5 = param1.magic_stage5 == 1 ? 1 : 0;
            runeLv = param1.rune_lv == undefined ? 0 : Math.max(0,int(param1.rune_lv));
         }
         else
         {
            lv = 1;
            slv = 1;
            sexp = 0;
            symp = -1;
            magic = [0,0,0,0];
            magicStage5 = 0;
            runeLv = 0;
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

