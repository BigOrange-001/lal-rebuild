package feathers.core
{
   import feathers.controls.text.BitmapFontTextRenderer;
   import feathers.controls.text.StageTextTextEditor;
   import feathers.layout.ILayoutData;
   import feathers.layout.ILayoutDisplayObject;
   import feathers.skins.IStyleProvider;
   import feathers.utils.display.getDisplayObjectDepthFromStage;
   import flash.errors.IllegalOperationError;
   import flash.geom.Matrix;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import starling.core.Starling;
   import starling.display.DisplayObject;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.utils.MatrixUtil;
   
   public class FeathersControl extends Sprite implements IFeathersControl, ILayoutDisplayObject
   {
      
      public static const INVALIDATION_FLAG_ALL:String = "all";
      
      public static const INVALIDATION_FLAG_STATE:String = "state";
      
      public static const INVALIDATION_FLAG_SIZE:String = "size";
      
      public static const INVALIDATION_FLAG_STYLES:String = "styles";
      
      public static const INVALIDATION_FLAG_SKIN:String = "skin";
      
      public static const INVALIDATION_FLAG_LAYOUT:String = "layout";
      
      public static const INVALIDATION_FLAG_DATA:String = "data";
      
      public static const INVALIDATION_FLAG_SCROLL:String = "scroll";
      
      public static const INVALIDATION_FLAG_SELECTED:String = "selected";
      
      public static const INVALIDATION_FLAG_FOCUS:String = "focus";
      
      protected static const INVALIDATION_FLAG_TEXT_RENDERER:String = "textRenderer";
      
      protected static const INVALIDATION_FLAG_TEXT_EDITOR:String = "textEditor";
      
      protected static const ILLEGAL_WIDTH_ERROR:String = "A component\'s width cannot be NaN.";
      
      protected static const ILLEGAL_HEIGHT_ERROR:String = "A component\'s height cannot be NaN.";
      
      protected static const ABSTRACT_CLASS_ERROR:String = "FeathersControl is an abstract class. For a lightweight Feathers wrapper, use feathers.controls.LayoutGroup.";
      
      private static const HELPER_MATRIX:Matrix = new Matrix();
      
      private static const HELPER_POINT:Point = new Point();
      
      public static var defaultTextRendererFactory:Function = createDefaultTextRenderer;
      public static var defaultTextEditorFactory:Function = createDefaultTextEditor;

      private static function createDefaultTextRenderer():ITextRenderer
      {
         return new BitmapFontTextRenderer();
      }

      private static function createDefaultTextEditor():ITextEditor
      {
         return new StageTextTextEditor();
      }
      protected var _validationQueue:ValidationQueue;
      
      protected var _styleNameList:TokenList = new TokenList();
      
      protected var _styleProvider:IStyleProvider;
      
      protected var _isQuickHitAreaEnabled:Boolean = false;
      
      protected var _hitArea:Rectangle = new Rectangle();
      
      protected var _isInitializing:Boolean = false;
      
      protected var _isInitialized:Boolean = false;
      
      protected var _isAllInvalid:Boolean = false;
      
      protected var _invalidationFlags:Object = {};
      
      protected var _delayedInvalidationFlags:Object = {};
      
      protected var _isEnabled:Boolean = true;
      
      protected var explicitWidth:Number = NaN;
      
      protected var actualWidth:Number = 0;
      
      protected var scaledActualWidth:Number = 0;
      
      protected var explicitHeight:Number = NaN;
      
      protected var actualHeight:Number = 0;
      
      protected var scaledActualHeight:Number = 0;
      
      protected var _minTouchWidth:Number = 0;
      
      protected var _minTouchHeight:Number = 0;
      
      protected var _minWidth:Number = 0;
      
      protected var _minHeight:Number = 0;
      
      protected var _maxWidth:Number = Infinity;
      
      protected var _maxHeight:Number = Infinity;
      
      protected var _includeInLayout:Boolean = true;
      
      protected var _layoutData:ILayoutData;
      
      protected var _focusManager:IFocusManager;
      
      protected var _focusOwner:IFocusDisplayObject;
      
      protected var _isFocusEnabled:Boolean = true;
      
      protected var _nextTabFocus:IFocusDisplayObject;
      
      protected var _previousTabFocus:IFocusDisplayObject;
      
      protected var _focusIndicatorSkin:DisplayObject;
      
      protected var _focusPaddingTop:Number = 0;
      
      protected var _focusPaddingRight:Number = 0;
      
      protected var _focusPaddingBottom:Number = 0;
      
      protected var _focusPaddingLeft:Number = 0;
      
      protected var _hasFocus:Boolean = false;
      
      protected var _showFocus:Boolean = false;
      
      protected var _isValidating:Boolean = false;
      
      protected var _hasValidated:Boolean = false;
      
      protected var _depth:int = -1;
      
      protected var _invalidateCount:int = 0;
      
      protected var _isDisposed:Boolean = false;
      
      public function FeathersControl()
      {
         super();
         if(Object(this).constructor == FeathersControl)
         {
            throw new Error("FeathersControl is an abstract class. For a lightweight Feathers wrapper, use feathers.controls.LayoutGroup.");
         }
         this._styleProvider = this.defaultStyleProvider;
         this.addEventListener("addedToStage",feathersControl_addedToStageHandler);
         this.addEventListener("removedFromStage",feathersControl_removedFromStageHandler);
         this.addEventListener("flatten",feathersControl_flattenHandler);
      }
      
      public function get styleName() : String
      {
         return this._styleNameList.value;
      }
      
      public function set styleName(param1:String) : void
      {
         this._styleNameList.value = param1;
      }
      
      public function get styleNameList() : TokenList
      {
         return this._styleNameList;
      }
      
      public function get nameList() : TokenList
      {
         return this._styleNameList;
      }
      
      public function get styleProvider() : IStyleProvider
      {
         return this._styleProvider;
      }
      
      public function set styleProvider(param1:IStyleProvider) : void
      {
         this._styleProvider = param1;
         if(this._styleProvider && this.isInitialized)
         {
            this._styleProvider.applyStyles(this);
         }
      }
      
      protected function get defaultStyleProvider() : IStyleProvider
      {
         return null;
      }
      
      public function get isQuickHitAreaEnabled() : Boolean
      {
         return this._isQuickHitAreaEnabled;
      }
      
      public function set isQuickHitAreaEnabled(param1:Boolean) : void
      {
         this._isQuickHitAreaEnabled = param1;
      }
      
      public function get isInitialized() : Boolean
      {
         return this._isInitialized;
      }
      
      public function get isEnabled() : Boolean
      {
         return _isEnabled;
      }
      
      public function set isEnabled(param1:Boolean) : void
      {
         if(this._isEnabled == param1)
         {
            return;
         }
         this._isEnabled = param1;
         this.invalidate("state");
      }
      
      override public function get width() : Number
      {
         return this.scaledActualWidth;
      }
      
      override public function set width(param1:Number) : void
      {
         if(this.explicitWidth == param1)
         {
            return;
         }
         var _loc2_:Boolean = param1 !== param1;
         if(_loc2_ && this.explicitWidth !== this.explicitWidth)
         {
            return;
         }
         this.explicitWidth = param1;
         if(_loc2_)
         {
            this.actualWidth = this.scaledActualWidth = 0;
            this.invalidate("size");
         }
         else
         {
            this.setSizeInternal(param1,this.actualHeight,true);
         }
      }
      
      override public function get height() : Number
      {
         return this.scaledActualHeight;
      }
      
      override public function set height(param1:Number) : void
      {
         if(this.explicitHeight == param1)
         {
            return;
         }
         var _loc2_:Boolean = param1 !== param1;
         if(_loc2_ && this.explicitHeight !== this.explicitHeight)
         {
            return;
         }
         this.explicitHeight = param1;
         if(_loc2_)
         {
            this.actualHeight = this.scaledActualHeight = 0;
            this.invalidate("size");
         }
         else
         {
            this.setSizeInternal(this.actualWidth,param1,true);
         }
      }
      
      public function get minTouchWidth() : Number
      {
         return this._minTouchWidth;
      }
      
      public function set minTouchWidth(param1:Number) : void
      {
         if(this._minTouchWidth == param1)
         {
            return;
         }
         this._minTouchWidth = param1;
         this.refreshHitAreaX();
      }
      
      public function get minTouchHeight() : Number
      {
         return this._minTouchHeight;
      }
      
      public function set minTouchHeight(param1:Number) : void
      {
         if(this._minTouchHeight == param1)
         {
            return;
         }
         this._minTouchHeight = param1;
         this.refreshHitAreaY();
      }
      
      public function get minWidth() : Number
      {
         return this._minWidth;
      }
      
      public function set minWidth(param1:Number) : void
      {
         if(this._minWidth == param1)
         {
            return;
         }
         if(param1 !== param1)
         {
            throw new ArgumentError("minWidth cannot be NaN");
         }
         this._minWidth = param1;
         this.invalidate("size");
      }
      
      public function get minHeight() : Number
      {
         return this._minHeight;
      }
      
      public function set minHeight(param1:Number) : void
      {
         if(this._minHeight == param1)
         {
            return;
         }
         if(param1 !== param1)
         {
            throw new ArgumentError("minHeight cannot be NaN");
         }
         this._minHeight = param1;
         this.invalidate("size");
      }
      
      public function get maxWidth() : Number
      {
         return this._maxWidth;
      }
      
      public function set maxWidth(param1:Number) : void
      {
         if(this._maxWidth == param1)
         {
            return;
         }
         if(param1 !== param1)
         {
            throw new ArgumentError("maxWidth cannot be NaN");
         }
         this._maxWidth = param1;
         this.invalidate("size");
      }
      
      public function get maxHeight() : Number
      {
         return this._maxHeight;
      }
      
      public function set maxHeight(param1:Number) : void
      {
         if(this._maxHeight == param1)
         {
            return;
         }
         if(param1 !== param1)
         {
            throw new ArgumentError("maxHeight cannot be NaN");
         }
         this._maxHeight = param1;
         this.invalidate("size");
      }
      
      override public function set scaleX(param1:Number) : void
      {
         super.scaleX = param1;
         this.setSizeInternal(this.actualWidth,this.actualHeight,false);
      }
      
      override public function set scaleY(param1:Number) : void
      {
         super.scaleY = param1;
         this.setSizeInternal(this.actualWidth,this.actualHeight,false);
      }
      
      public function get includeInLayout() : Boolean
      {
         return this._includeInLayout;
      }
      
      public function set includeInLayout(param1:Boolean) : void
      {
         if(this._includeInLayout == param1)
         {
            return;
         }
         this._includeInLayout = param1;
         this.dispatchEventWith("layoutDataChange");
      }
      
      public function get layoutData() : ILayoutData
      {
         return this._layoutData;
      }
      
      public function set layoutData(param1:ILayoutData) : void
      {
         if(this._layoutData == param1)
         {
            return;
         }
         if(this._layoutData)
         {
            this._layoutData.removeEventListener("change",layoutData_changeHandler);
         }
         this._layoutData = param1;
         if(this._layoutData)
         {
            this._layoutData.addEventListener("change",layoutData_changeHandler);
         }
         this.dispatchEventWith("layoutDataChange");
      }
      
      public function get focusManager() : IFocusManager
      {
         return this._focusManager;
      }
      
      public function set focusManager(param1:IFocusManager) : void
      {
         if(!(this is IFocusDisplayObject))
         {
            throw new IllegalOperationError("Cannot pass a focus manager to a component that does not implement feathers.core.IFocusDisplayObject");
         }
         if(this._focusManager == param1)
         {
            return;
         }
         this._focusManager = param1;
         if(this._focusManager)
         {
            this.addEventListener("focusIn",focusInHandler);
            this.addEventListener("focusOut",focusOutHandler);
         }
         else
         {
            this.removeEventListener("focusIn",focusInHandler);
            this.removeEventListener("focusOut",focusOutHandler);
         }
      }
      
      public function get focusOwner() : IFocusDisplayObject
      {
         return this._focusOwner;
      }
      
      public function set focusOwner(param1:IFocusDisplayObject) : void
      {
         this._focusOwner = param1;
      }
      
      public function get isFocusEnabled() : Boolean
      {
         return this._isEnabled && this._isFocusEnabled;
      }
      
      public function set isFocusEnabled(param1:Boolean) : void
      {
         if(!(this is IFocusDisplayObject))
         {
            throw new IllegalOperationError("Cannot enable focus on a component that does not implement feathers.core.IFocusDisplayObject");
         }
         if(this._isFocusEnabled == param1)
         {
            return;
         }
         this._isFocusEnabled = param1;
      }
      
      public function get nextTabFocus() : IFocusDisplayObject
      {
         return this._nextTabFocus;
      }
      
      public function set nextTabFocus(param1:IFocusDisplayObject) : void
      {
         if(!(this is IFocusDisplayObject))
         {
            throw new IllegalOperationError("Cannot set next tab focus on a component that does not implement feathers.core.IFocusDisplayObject");
         }
         this._nextTabFocus = param1;
      }
      
      public function get previousTabFocus() : IFocusDisplayObject
      {
         return this._previousTabFocus;
      }
      
      public function set previousTabFocus(param1:IFocusDisplayObject) : void
      {
         if(!(this is IFocusDisplayObject))
         {
            throw new IllegalOperationError("Cannot set previous tab focus on a component that does not implement feathers.core.IFocusDisplayObject");
         }
         this._previousTabFocus = param1;
      }
      
      public function get focusIndicatorSkin() : DisplayObject
      {
         return this._focusIndicatorSkin;
      }
      
      public function set focusIndicatorSkin(param1:DisplayObject) : void
      {
         if(!(this is IFocusDisplayObject))
         {
            throw new IllegalOperationError("Cannot set focus indicator skin on a component that does not implement feathers.core.IFocusDisplayObject");
         }
         if(this._focusIndicatorSkin == param1)
         {
            return;
         }
         if(this._focusIndicatorSkin && this._focusIndicatorSkin.parent == this)
         {
            this._focusIndicatorSkin.removeFromParent(false);
         }
         this._focusIndicatorSkin = param1;
         if(this._focusIndicatorSkin)
         {
            this._focusIndicatorSkin.touchable = false;
         }
         if(this._focusManager && this._focusManager.focus == this)
         {
            this.invalidate("styles");
         }
      }
      
      public function get focusPadding() : Number
      {
         return this._focusPaddingTop;
      }
      
      public function set focusPadding(param1:Number) : void
      {
         this.focusPaddingTop = param1;
         this.focusPaddingRight = param1;
         this.focusPaddingBottom = param1;
         this.focusPaddingLeft = param1;
      }
      
      public function get focusPaddingTop() : Number
      {
         return this._focusPaddingTop;
      }
      
      public function set focusPaddingTop(param1:Number) : void
      {
         if(this._focusPaddingTop == param1)
         {
            return;
         }
         this._focusPaddingTop = param1;
         this.invalidate("focus");
      }
      
      public function get focusPaddingRight() : Number
      {
         return this._focusPaddingRight;
      }
      
      public function set focusPaddingRight(param1:Number) : void
      {
         if(this._focusPaddingRight == param1)
         {
            return;
         }
         this._focusPaddingRight = param1;
         this.invalidate("focus");
      }
      
      public function get focusPaddingBottom() : Number
      {
         return this._focusPaddingBottom;
      }
      
      public function set focusPaddingBottom(param1:Number) : void
      {
         if(this._focusPaddingBottom == param1)
         {
            return;
         }
         this._focusPaddingBottom = param1;
         this.invalidate("focus");
      }
      
      public function get focusPaddingLeft() : Number
      {
         return this._focusPaddingLeft;
      }
      
      public function set focusPaddingLeft(param1:Number) : void
      {
         if(this._focusPaddingLeft == param1)
         {
            return;
         }
         this._focusPaddingLeft = param1;
         this.invalidate("focus");
      }
      
      public function get isCreated() : Boolean
      {
         return this._hasValidated;
      }
      
      public function get depth() : int
      {
         return this._depth;
      }
      
      override public function getBounds(param1:DisplayObject, param2:Rectangle = null) : Rectangle
      {
         if(!param2)
         {
            param2 = new Rectangle();
         }
         var _loc5_:Number = 1.7976931348623157e+308;
         var _loc4_:Number = -1.7976931348623157e+308;
         var _loc6_:Number = 1.7976931348623157e+308;
         var _loc3_:Number = -1.7976931348623157e+308;
         if(param1 == this)
         {
            _loc5_ = 0;
            _loc6_ = 0;
            _loc4_ = this.actualWidth;
            _loc3_ = this.actualHeight;
         }
         else
         {
            this.getTransformationMatrix(param1,HELPER_MATRIX);
            MatrixUtil.transformCoords(HELPER_MATRIX,0,0,HELPER_POINT);
            _loc5_ = _loc5_ < HELPER_POINT.x ? _loc5_ : HELPER_POINT.x;
            _loc4_ = _loc4_ > HELPER_POINT.x ? _loc4_ : HELPER_POINT.x;
            _loc6_ = _loc6_ < HELPER_POINT.y ? _loc6_ : HELPER_POINT.y;
            _loc3_ = _loc3_ > HELPER_POINT.y ? _loc3_ : HELPER_POINT.y;
            MatrixUtil.transformCoords(HELPER_MATRIX,0,this.actualHeight,HELPER_POINT);
            _loc5_ = _loc5_ < HELPER_POINT.x ? _loc5_ : HELPER_POINT.x;
            _loc4_ = _loc4_ > HELPER_POINT.x ? _loc4_ : HELPER_POINT.x;
            _loc6_ = _loc6_ < HELPER_POINT.y ? _loc6_ : HELPER_POINT.y;
            _loc3_ = _loc3_ > HELPER_POINT.y ? _loc3_ : HELPER_POINT.y;
            MatrixUtil.transformCoords(HELPER_MATRIX,this.actualWidth,0,HELPER_POINT);
            _loc5_ = _loc5_ < HELPER_POINT.x ? _loc5_ : HELPER_POINT.x;
            _loc4_ = _loc4_ > HELPER_POINT.x ? _loc4_ : HELPER_POINT.x;
            _loc6_ = _loc6_ < HELPER_POINT.y ? _loc6_ : HELPER_POINT.y;
            _loc3_ = _loc3_ > HELPER_POINT.y ? _loc3_ : HELPER_POINT.y;
            MatrixUtil.transformCoords(HELPER_MATRIX,this.actualWidth,this.actualHeight,HELPER_POINT);
            _loc5_ = _loc5_ < HELPER_POINT.x ? _loc5_ : HELPER_POINT.x;
            _loc4_ = _loc4_ > HELPER_POINT.x ? _loc4_ : HELPER_POINT.x;
            _loc6_ = _loc6_ < HELPER_POINT.y ? _loc6_ : HELPER_POINT.y;
            _loc3_ = _loc3_ > HELPER_POINT.y ? _loc3_ : HELPER_POINT.y;
         }
         param2.x = _loc5_;
         param2.y = _loc6_;
         param2.width = _loc4_ - _loc5_;
         param2.height = _loc3_ - _loc6_;
         return param2;
      }
      
      override public function hitTest(param1:Point, param2:Boolean = false) : DisplayObject
      {
         var _loc3_:Rectangle = null;
         if(this._isQuickHitAreaEnabled)
         {
            if(param2 && (!this.visible || !this.touchable))
            {
               return null;
            }
            _loc3_ = this.clipRect;
            if(_loc3_ && !_loc3_.containsPoint(param1))
            {
               return null;
            }
            return this._hitArea.containsPoint(param1) ? this : null;
         }
         return super.hitTest(param1,param2);
      }
      
      override public function dispose() : void
      {
         this._isDisposed = true;
         this._validationQueue = null;
         super.dispose();
      }
      
      public function invalidate(param1:String = "all") : void
      {
         var _loc4_:Boolean = this.isInvalid();
         var _loc2_:Boolean = false;
         if(this._isValidating)
         {
            var _loc6_:int = 0;
            var _loc5_:Object = this._delayedInvalidationFlags;
            for(var _loc3_:String in _loc5_)
            {
               _loc2_ = true;
            }
         }
         if(!param1 || param1 == "all")
         {
            if(this._isValidating)
            {
               this._delayedInvalidationFlags["all"] = true;
            }
            else
            {
               this._isAllInvalid = true;
            }
         }
         else if(this._isValidating)
         {
            this._delayedInvalidationFlags[param1] = true;
         }
         else if(param1 != "all" && !this._invalidationFlags.hasOwnProperty(param1))
         {
            this._invalidationFlags[param1] = true;
         }
         if(!this._validationQueue || !this._isInitialized)
         {
            return;
         }
         if(this._isValidating)
         {
            if(_loc2_)
            {
               return;
            }
            this._invalidateCount++;
            this._validationQueue.addControl(this,this._invalidateCount >= 10);
            return;
         }
         if(_loc4_)
         {
            return;
         }
         this._invalidateCount = 0;
         this._validationQueue.addControl(this,false);
      }
      
      public function validate() : void
      {
         if(this._isDisposed)
         {
            return;
         }
         if(!this._isInitialized)
         {
            if(this._isInitializing)
            {
               return;
            }
            this.initializeInternal();
         }
         if(!this.isInvalid())
         {
            return;
         }
         if(this._isValidating)
         {
            if(this._validationQueue)
            {
               this._validationQueue.addControl(this,true);
            }
            return;
         }
         this._isValidating = true;
         try
         {
         this.draw();
         for(var _loc1_:String in this._invalidationFlags)
         {
            delete this._invalidationFlags[_loc1_];
         }
         this._isAllInvalid = false;
         for(_loc1_ in this._delayedInvalidationFlags)
         {
            if(_loc1_ == "all")
            {
               this._isAllInvalid = true;
            }
            else
            {
               this._invalidationFlags[_loc1_] = true;
            }
            delete this._delayedInvalidationFlags[_loc1_];
         }
         }
         finally
         {
            this._isValidating = false;
         }
         if(!this._hasValidated)
         {
            this._hasValidated = true;
            this.dispatchEventWith("creationComplete");
         }
      }
      
      public function isInvalid(param1:String = null) : Boolean
      {
         if(this._isAllInvalid)
         {
            return true;
         }
         if(!param1)
         {
            var _loc3_:int = 0;
            var _loc2_:Object = this._invalidationFlags;
            for(param1 in _loc2_)
            {
               return true;
            }
            return false;
         }
         return this._invalidationFlags[param1];
      }
      
      public function setSize(param1:Number, param2:Number) : void
      {
         this.explicitWidth = param1;
         var _loc4_:Boolean = param1 != param1;
         if(_loc4_)
         {
            this.actualWidth = this.scaledActualWidth = 0;
         }
         this.explicitHeight = param2;
         var _loc3_:Boolean = param2 != param2;
         if(_loc3_)
         {
            this.actualHeight = this.scaledActualHeight = 0;
         }
         if(_loc4_ || _loc3_)
         {
            this.invalidate("size");
         }
         else
         {
            this.setSizeInternal(param1,param2,true);
         }
      }
      
      public function move(param1:Number, param2:Number) : void
      {
         this.x = param1;
         this.y = param2;
      }
      
      public function showFocus() : void
      {
         if(!this._hasFocus || !this._focusIndicatorSkin)
         {
            return;
         }
         this._showFocus = true;
         this.invalidate("focus");
      }
      
      public function hideFocus() : void
      {
         if(!this._hasFocus || !this._focusIndicatorSkin)
         {
            return;
         }
         this._showFocus = false;
         this.invalidate("focus");
      }
      
      protected function setSizeInternal(param1:Number, param2:Number, param3:Boolean) : Boolean
      {
         if(this.explicitWidth === this.explicitWidth)
         {
            param1 = this.explicitWidth;
         }
         else if(param1 < this._minWidth)
         {
            param1 = this._minWidth;
         }
         else if(param1 > this._maxWidth)
         {
            param1 = this._maxWidth;
         }
         if(this.explicitHeight === this.explicitHeight)
         {
            param2 = this.explicitHeight;
         }
         else if(param2 < this._minHeight)
         {
            param2 = this._minHeight;
         }
         else if(param2 > this._maxHeight)
         {
            param2 = this._maxHeight;
         }
         if(param1 !== param1)
         {
            throw new ArgumentError("A component\'s width cannot be NaN.");
         }
         if(param2 !== param2)
         {
            throw new ArgumentError("A component\'s height cannot be NaN.");
         }
         var _loc4_:Boolean = false;
         if(this.actualWidth != param1)
         {
            this.actualWidth = param1;
            this.refreshHitAreaX();
            _loc4_ = true;
         }
         if(this.actualHeight != param2)
         {
            this.actualHeight = param2;
            this.refreshHitAreaY();
            _loc4_ = true;
         }
         param1 = this.scaledActualWidth;
         param2 = this.scaledActualHeight;
         this.scaledActualWidth = this.actualWidth * Math.abs(this.scaleX);
         this.scaledActualHeight = this.actualHeight * Math.abs(this.scaleY);
         if(param1 != this.scaledActualWidth || param2 != this.scaledActualHeight)
         {
            _loc4_ = true;
         }
         if(_loc4_)
         {
            if(param3)
            {
               this.invalidate("size");
            }
            this.dispatchEventWith("resize");
         }
         return _loc4_;
      }
      
      protected function initialize() : void
      {
      }
      
      protected function draw() : void
      {
      }
      
      protected function setInvalidationFlag(param1:String) : void
      {
         if(this._invalidationFlags.hasOwnProperty(param1))
         {
            return;
         }
         this._invalidationFlags[param1] = true;
      }
      
      protected function clearInvalidationFlag(param1:String) : void
      {
         delete this._invalidationFlags[param1];
      }
      
      protected function refreshFocusIndicator() : void
      {
         if(this._focusIndicatorSkin)
         {
            if(this._hasFocus && this._showFocus)
            {
               if(this._focusIndicatorSkin.parent != this)
               {
                  this.addChild(this._focusIndicatorSkin);
               }
               else
               {
                  this.setChildIndex(this._focusIndicatorSkin,this.numChildren - 1);
               }
            }
            else if(this._focusIndicatorSkin.parent)
            {
               this._focusIndicatorSkin.removeFromParent(false);
            }
            this._focusIndicatorSkin.x = this._focusPaddingLeft;
            this._focusIndicatorSkin.y = this._focusPaddingTop;
            this._focusIndicatorSkin.width = this.actualWidth - this._focusPaddingLeft - this._focusPaddingRight;
            this._focusIndicatorSkin.height = this.actualHeight - this._focusPaddingTop - this._focusPaddingBottom;
         }
      }
      
      protected function refreshHitAreaX() : void
      {
         if(this.actualWidth < this._minTouchWidth)
         {
            this._hitArea.width = this._minTouchWidth;
         }
         else
         {
            this._hitArea.width = this.actualWidth;
         }
         var _loc1_:Number = (this.actualWidth - this._hitArea.width) / 2;
         if(_loc1_ !== _loc1_)
         {
            this._hitArea.x = 0;
         }
         else
         {
            this._hitArea.x = _loc1_;
         }
      }
      
      protected function refreshHitAreaY() : void
      {
         if(this.actualHeight < this._minTouchHeight)
         {
            this._hitArea.height = this._minTouchHeight;
         }
         else
         {
            this._hitArea.height = this.actualHeight;
         }
         var _loc1_:Number = (this.actualHeight - this._hitArea.height) / 2;
         if(_loc1_ !== _loc1_)
         {
            this._hitArea.y = 0;
         }
         else
         {
            this._hitArea.y = _loc1_;
         }
      }
      
      protected function initializeInternal() : void
      {
         if(this._isInitialized || this._isInitializing)
         {
            return;
         }
         this._isInitializing = true;
         this.initialize();
         this.invalidate();
         this._isInitializing = false;
         this._isInitialized = true;
         this.dispatchEventWith("initialize");
         if(this._styleProvider)
         {
            this._styleProvider.applyStyles(this);
         }
         this._styleNameList.addEventListener("change",styleNameList_changeHandler);
      }
      
      protected function focusInHandler(param1:Event) : void
      {
         this._hasFocus = true;
         this.invalidate("focus");
      }
      
      protected function focusOutHandler(param1:Event) : void
      {
         this._hasFocus = false;
         this._showFocus = false;
         this.invalidate("focus");
      }
      
      protected function feathersControl_flattenHandler(param1:Event) : void
      {
         this.validate();
      }
      
      protected function feathersControl_addedToStageHandler(param1:Event) : void
      {
         this._depth = getDisplayObjectDepthFromStage(this);
         this._validationQueue = ValidationQueue.forStarling(Starling.current);
         if(!this._isInitialized)
         {
            this.initializeInternal();
         }
         if(this.isInvalid())
         {
            this._invalidateCount = 0;
            this._validationQueue.addControl(this,false);
         }
      }
      
      protected function feathersControl_removedFromStageHandler(param1:Event) : void
      {
         this._depth = -1;
         this._validationQueue = null;
      }
      
      protected function layoutData_changeHandler(param1:Event) : void
      {
         this.dispatchEventWith("layoutDataChange");
      }
      
      protected function styleNameList_changeHandler(param1:Event) : void
      {
         if(!this._styleProvider)
         {
            return;
         }
         this._styleProvider.applyStyles(this);
      }
   }
}

