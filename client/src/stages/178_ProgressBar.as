package com.meng52.game.ui.element
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.ui.effect.DisplayTools;
   import com.meng52.game.ui.map.GameMapLayer;
   import com.meng52.utils.Tools;
   import com.meng52.utils.LocalStore;
   import flash.geom.Rectangle;
   import starling.animation.Tween;
   import starling.core.Starling;
   import starling.display.Image;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.text.TextField;

   public class ProgressBar extends Sprite
   {

      public static const HP_LINE:int = 1000;

      public static const HP_HIDE_LINE:int = 10000;

      public static const HP_HIDE_BIG:int = 50000;

      public static const HP_HIDE_GOD:int = 250000;

      private var m_bottom:Image;

      private var m_middle:Image;

      private var m_middleSpr:Sprite;

      private var m_top:Image;

      private var m_topSpr:Sprite;

      private var m_allSpr:Sprite;

      private var m_shieldSpr:Sprite;

      private var m_shieldRate:Number = 0;

      private var m_quarterSpr:Sprite;

      private var m_quarterMarks104:Array = [];

      private static const HEALTH_VALUES_KEY104:String = "lal_battle_health_values_104";
      private static const HEALTH_VALUES_EVENT104:String = "battle_health_values_changed_104";
      private static var healthValuesLoaded104:Boolean = false;
      private static var healthValuesVisible104:Boolean = false;
      private var m_healthValue104:Number = 0;
      private var m_healthMaximum104:Number = 0;
      private var m_healthLabel104:TextField;

      public static function showHealthValues104() : Boolean
      {
         if(!healthValuesLoaded104)
         {
            healthValuesVisible104 = LocalStore.getItemObj(HEALTH_VALUES_KEY104) === true;
            healthValuesLoaded104 = true;
         }
         return healthValuesVisible104;
      }

      public static function setHealthValuesVisible104(enabled:Boolean) : void
      {
         LocalStore.setItemObj(HEALTH_VALUES_KEY104,enabled);
         healthValuesVisible104 = enabled;
         healthValuesLoaded104 = true;
         GlobalData.$mEventDispatcher.dispatchEventWith(HEALTH_VALUES_EVENT104);
      }

      protected var m_per:Number;

      public function ProgressBar(param1:int, param2:Number = 1, param3:Number = 0)
      {
         super();
         this.touchable = false;
         if(!m_allSpr)
         {
            m_allSpr = new Sprite();
            this.addChild(m_allSpr);
         }
         m_bottom = DisplayTools.newImg("aFrame" + param1);
         m_allSpr.addChild(m_bottom);
         m_middleSpr = new Sprite();
         var _loc7_:String = "aHp" + param1;
         m_middle = DisplayTools.newImg(_loc7_);
         m_middle.y = -1;
         m_middleSpr.addChild(m_middle);
         m_allSpr.addChild(m_middleSpr);
         m_topSpr = new Sprite();
         m_top = DisplayTools.newImg("aHp3");
         m_top.x = 2;
         m_top.y = 1;
         m_topSpr.visible = false;
         m_topSpr.addChild(m_top);
         m_allSpr.addChild(m_topSpr);
         // Share the native HP slot; its frame and empty background stay intact.
         m_shieldSpr = new Sprite();
         // Recolored native aHp2 art keeps its highlight, shading and alpha edge.
         var shieldFill:Image = DisplayTools.newImg("aShield104");
         shieldFill.x = m_middle.x;
         shieldFill.y = m_middle.y;
         m_shieldSpr.addChild(shieldFill);
         m_shieldSpr.visible = false;
         m_allSpr.addChild(m_shieldSpr);
         m_per = param2;
         if(param2 != 1)
         {
            refresh(param2,true);
         }
         refreshQuarterMarks104(Math.max(1,m_per+m_shieldRate));
         setHealthValues104(param2*param3,param3);
         addEventListener("addedToStage",onHealthBarAdded104);
         addEventListener("removedFromStage",onHealthBarRemoved104);
      }

      public function setHealthValues104(health:Number, maximum:Number) : void
      {
         m_healthValue104 = isFinite(health) ? Math.max(0,Math.round(health)) : 0;
         m_healthMaximum104 = isFinite(maximum) ? Math.max(0,Math.round(maximum)) : 0;
         updateHealthLabel104();
      }

      private function updateHealthLabel104(event:Event = null) : void
      {
         if(!showHealthValues104())
         {
            if(m_healthLabel104) m_healthLabel104.visible = false;
            return;
         }
         if(!m_healthLabel104)
         {
            m_healthLabel104 = GlobalTextStyle.getTextField("",13,0xFFFFFF,"center",m_middle.width,m_middle.height);
            m_healthLabel104.bold = true;
            m_healthLabel104.vAlign = "center";
            m_healthLabel104.x = m_middle.x-m_middle.pivotX;
            m_healthLabel104.y = m_middle.y-m_middle.pivotY;
            // Keep the label above HP, quarter marks and the purple shield.
            m_allSpr.addChild(m_healthLabel104);
         }
         m_healthLabel104.text = String(m_healthValue104)+"/"+String(m_healthMaximum104);
         m_healthLabel104.visible = true;
      }

      private function onHealthBarAdded104(event:Event) : void
      {
         GlobalData.$mEventDispatcher.addEventListener(HEALTH_VALUES_EVENT104,updateHealthLabel104);
         updateHealthLabel104();
      }

      private function onHealthBarRemoved104(event:Event) : void
      {
         GlobalData.$mEventDispatcher.removeEventListener(HEALTH_VALUES_EVENT104,updateHealthLabel104);
      }

      override public function dispose() : void
      {
         GlobalData.$mEventDispatcher.removeEventListener(HEALTH_VALUES_EVENT104,updateHealthLabel104);
         super.dispose();
      }

      private function refreshQuarterMarks104(capacity:Number) : void
      {
         if(!m_quarterSpr)
         {
            m_quarterSpr = new Sprite();
            m_allSpr.addChild(m_quarterSpr);
         }
         // One continuous max-HP grid crosses HP and shield: 5% HP + 30%
         // shield places the first 25% mark 20% of max HP into the shield.
         var spacing:Number = m_middle.width/capacity/4;
         // Coalesce marks only when multiple quarters would overlap at this
         // pixel width. Every visible mark still lies on an exact 25% boundary.
         var stride:Number = Math.max(1,Math.ceil(3/spacing));
         var filled:Number = m_middle.width*(m_per/capacity+m_shieldRate/capacity);
         var left:Number = m_middle.x-m_middle.pivotX;
         var count:int = 0;
         var position:Number = spacing*stride;
         var mark:Quad;
         while(position<filled-0.00001)
         {
            if(count>=m_quarterMarks104.length)
            {
               mark = Tools.newQuad(2,m_middle.height-3,0,0,0x111111);
               m_quarterMarks104.push(mark);
               m_quarterSpr.addChild(mark);
            }
            mark = m_quarterMarks104[count];
            mark.visible = true;
            mark.width = Math.max(1,2/capacity);
            mark.x = left+position-mark.width/2;
            mark.y = m_middle.y-m_middle.pivotY+1;
            count++;
            position = spacing*stride*(count+1);
         }
         for(var index:int=count;index<m_quarterMarks104.length;index++)
            m_quarterMarks104[index].visible = false;
         m_quarterSpr.clipRect = new Rectangle(left,m_middle.y-m_middle.pivotY,Math.round(filled),m_middle.height);
         m_quarterSpr.flatten();
      }

      public function refresh(param1:Number, param2:Boolean = false, shieldRate:Number = 0) : void
      {
         var _hpSide:int;
         var _hpSlotWidth:int;
         var _tween:Tween;
         var _topMaskWidth:int;
         var _x:Number;
         var _x0:Number;
         var _y0:Number;
         var _per:Number = isFinite(param1) ? Math.max(0,Math.min(1,param1)) : 0;
         shieldRate = isFinite(shieldRate) && _per>0 ? Math.max(0,shieldRate) : 0;
         var capacity:Number = Math.max(1,_per+shieldRate);
         var _isForce:Boolean = param2;
         if(!_isForce && m_per == _per && m_shieldRate == shieldRate)
         {
            return;
         }
         _hpSide = 0;
         _hpSlotWidth = m_middle.width - _hpSide * 2;
         _topMaskWidth = Math.round((m_per - _per) / capacity * _hpSlotWidth);
         _x = Math.round(_per / capacity * _hpSlotWidth);
         _x0 = Math.round(-_hpSlotWidth / 2);
         _y0 = Math.round(-m_top.height / 2);
         if(GameMapLayer.isFastest)
         {
            m_topSpr.visible = false;
         }
         else
         {
            m_topSpr.clipRect = null;
            Starling.juggler.removeTweens(m_topSpr);
            m_top.color = 16777215;
            if(_topMaskWidth >= 0)
            {
               m_top.color = 16776960;
            }
            else
            {
               m_top.color = 6475106;
            }
            m_topSpr.clipRect = new Rectangle(_x0 + _x,_y0,_topMaskWidth,m_top.height);
            m_topSpr.visible = true;
            m_topSpr.alpha = 1;
            m_topSpr.flatten();
         }
         _tween = new Tween(m_topSpr,1,"easeInOut");
         _tween.fadeTo(0);
         _tween.onComplete = function():void
         {
            m_topSpr.visible = false;
         };
         Starling.juggler.add(_tween);
         m_middleSpr.clipRect = null;
         m_per = _per;
         m_shieldRate = shieldRate;
         if(m_per <= 0)
         {
            _topMaskWidth = 0;
         }
         else
         {
            _topMaskWidth = _x;
         }
         if(_topMaskWidth == 1 && shieldRate == 0)
         {
            _topMaskWidth = 2;
         }
         // Compress HP when HP + shield exceeds max HP. The shared quarter
         // grid uses this same capacity for both colored sections.
         m_middleSpr.scaleX = 1 / capacity;
         m_middleSpr.x = _x0 * (1 - 1 / capacity);
         m_middleSpr.clipRect = new Rectangle(_x0,_y0,_topMaskWidth*capacity,m_middle.height);
         m_middleSpr.flatten();
         var shieldEnd:Number = Math.round((_per+shieldRate)/capacity*_hpSlotWidth);
         m_shieldSpr.clipRect = new Rectangle(_x0+_x,m_middle.y-m_middle.pivotY,Math.max(0,shieldEnd-_x),m_middle.height);
         m_shieldSpr.visible = shieldEnd > _x;
         refreshQuarterMarks104(capacity);
      }

      public function get perRate() : Number
      {
         return m_per;
      }
   }
}
