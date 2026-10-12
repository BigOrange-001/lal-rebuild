package feathers.controls
{
   import feathers.core.FeathersControl;
   import feathers.core.PropertyProxy;
   import feathers.core.ToggleGroup;
   import feathers.data.ListCollection;
   import feathers.layout.HorizontalLayout;
   import feathers.layout.LayoutBoundsResult;
   import feathers.layout.VerticalLayout;
   import feathers.layout.ViewPortBounds;
   import feathers.skins.IStyleProvider;
   import starling.display.DisplayObject;
   import starling.events.Event;
   
   public class TabBar extends FeathersControl
   {
      
      protected static const INVALIDATION_FLAG_TAB_FACTORY:String = "tabFactory";
      
      public static const DIRECTION_HORIZONTAL:String = "horizontal";
      
      public static const DIRECTION_VERTICAL:String = "vertical";
      
      public static const HORIZONTAL_ALIGN_LEFT:String = "left";
      
      public static const HORIZONTAL_ALIGN_CENTER:String = "center";
      
      public static const HORIZONTAL_ALIGN_RIGHT:String = "right";
      
      public static const HORIZONTAL_ALIGN_JUSTIFY:String = "justify";
      
      public static const VERTICAL_ALIGN_TOP:String = "top";
      
      public static const VERTICAL_ALIGN_MIDDLE:String = "middle";
      
      public static const VERTICAL_ALIGN_BOTTOM:String = "bottom";
      
      public static const VERTICAL_ALIGN_JUSTIFY:String = "justify";
      
      public static const DEFAULT_CHILD_STYLE_NAME_TAB:String = "feathers-tab-bar-tab";
      
      public static const DEFAULT_CHILD_NAME_TAB:String = "feathers-tab-bar-tab";
      
      public static var globalStyleProvider:IStyleProvider;
      
      private static const DEFAULT_TAB_FIELDS:Vector.<String> = new <String>["defaultIcon","upIcon","downIcon","hoverIcon","disabledIcon","defaultSelectedIcon","selectedUpIcon","selectedDownIcon","selectedHoverIcon","selectedDisabledIcon"];
      
      protected var tabStyleName:String = "feathers-tab-bar-tab";
      
      protected var firstTabStyleName:String = "feathers-tab-bar-tab";
      
      protected var lastTabStyleName:String = "feathers-tab-bar-tab";
      
      protected var toggleGroup:ToggleGroup;
      
      protected var activeFirstTab:ToggleButton;
      
      protected var inactiveFirstTab:ToggleButton;
      
      protected var activeLastTab:ToggleButton;
      
      protected var inactiveLastTab:ToggleButton;
      
      protected var _layoutItems:Vector.<DisplayObject> = new Vector.<DisplayObject>(0);
      
      protected var activeTabs:Vector.<ToggleButton> = new Vector.<ToggleButton>(0);
      
      protected var inactiveTabs:Vector.<ToggleButton> = new Vector.<ToggleButton>(0);
      
      protected var _dataProvider:ListCollection;
      
      protected var verticalLayout:VerticalLayout;
      
      protected var horizontalLayout:HorizontalLayout;
      
      protected var _viewPortBounds:ViewPortBounds = new ViewPortBounds();
      
      protected var _layoutResult:LayoutBoundsResult = new LayoutBoundsResult();
      
      protected var _direction:String = "horizontal";
      
      protected var _horizontalAlign:String = "justify";
      
      protected var _verticalAlign:String = "justify";
      
      protected var _distributeTabSizes:Boolean = true;
      
      protected var _gap:Number = 0;
      
      protected var _firstGap:Number = NaN;
      
      protected var _lastGap:Number = NaN;
      
      protected var _paddingTop:Number = 0;
      
      protected var _paddingRight:Number = 0;
      
      protected var _paddingBottom:Number = 0;
      
      protected var _paddingLeft:Number = 0;
      
      protected var _tabFactory:Function = defaultTabFactory;
      
      protected var _firstTabFactory:Function;
      
      protected var _lastTabFactory:Function;
      
      protected var _tabInitializer:Function;
      
      protected var _ignoreSelectionChanges:Boolean = false;
      
      protected var _selectedIndex:int = -1;
      
      protected var _customTabStyleName:String;
      
      protected var _customFirstTabStyleName:String;
      
      protected var _customLastTabStyleName:String;
      
      protected var _tabProperties:PropertyProxy;
      
      public function TabBar()
      {
         _tabInitializer = defaultTabInitializer;
         super();
      }
      
      protected static function defaultTabFactory() : ToggleButton
      {
         return new ToggleButton();
      }
      
      protected function get tabName() : String
      {
         return this.tabStyleName;
      }
      
      protected function set tabName(param1:String) : void
      {
         this.tabStyleName = param1;
      }
      
      protected function get firstTabName() : String
      {
         return this.firstTabStyleName;
      }
      
      protected function set firstTabName(param1:String) : void
      {
         this.firstTabStyleName = param1;
      }
      
      protected function get lastTabName() : String
      {
         return this.lastTabStyleName;
      }
      
      protected function set lastTabName(param1:String) : void
      {
         this.lastTabStyleName = param1;
      }
      
      override protected function get defaultStyleProvider() : IStyleProvider
      {
         return TabBar.globalStyleProvider;
      }
      
      public function get dataProvider() : ListCollection
      {
         return this._dataProvider;
      }
      
      public function set dataProvider(param1:ListCollection) : void
      {
         if(this._dataProvider == param1)
         {
            return;
         }
         var _loc3_:int = this.selectedIndex;
         var _loc2_:Object = this.selectedItem;
         if(this._dataProvider)
         {
            this._dataProvider.removeEventListener("addItem",dataProvider_addItemHandler);
            this._dataProvider.removeEventListener("removeItem",dataProvider_removeItemHandler);
            this._dataProvider.removeEventListener("replaceItem",dataProvider_replaceItemHandler);
            this._dataProvider.removeEventListener("updateItem",dataProvider_updateItemHandler);
            this._dataProvider.removeEventListener("reset",dataProvider_resetHandler);
         }
         this._dataProvider = param1;
         if(this._dataProvider)
         {
            this._dataProvider.addEventListener("addItem",dataProvider_addItemHandler);
            this._dataProvider.addEventListener("removeItem",dataProvider_removeItemHandler);
            this._dataProvider.addEventListener("replaceItem",dataProvider_replaceItemHandler);
            this._dataProvider.addEventListener("updateItem",dataProvider_updateItemHandler);
            this._dataProvider.addEventListener("reset",dataProvider_resetHandler);
         }
         if(!this._dataProvider || this._dataProvider.length == 0)
         {
            this.selectedIndex = -1;
         }
         else
         {
            this.selectedIndex = 0;
         }
         if(this.selectedIndex == _loc3_ && this.selectedItem != _loc2_)
         {
            this.dispatchEventWith("change");
         }
         this.invalidate("data");
      }
      
      public function get direction() : String
      {
         return this._direction;
      }
      
      public function set direction(param1:String) : void
      {
         if(this._direction == param1)
         {
            return;
         }
         this._direction = param1;
         this.invalidate("styles");
      }
      
      public function get horizontalAlign() : String
      {
         return this._horizontalAlign;
      }
      
      public function set horizontalAlign(param1:String) : void
      {
         if(this._horizontalAlign == param1)
         {
            return;
         }
         this._horizontalAlign = param1;
         this.invalidate("styles");
      }
      
      public function get verticalAlign() : String
      {
         return this._verticalAlign;
      }
      
      public function set verticalAlign(param1:String) : void
      {
         if(this._verticalAlign == param1)
         {
            return;
         }
         this._verticalAlign = param1;
         this.invalidate("styles");
      }
      
      public function get distributeTabSizes() : Boolean
      {
         return this._distributeTabSizes;
      }
      
      public function set distributeTabSizes(param1:Boolean) : void
      {
         if(this._distributeTabSizes == param1)
         {
            return;
         }
         this._distributeTabSizes = param1;
         this.invalidate("styles");
      }
      
      public function get gap() : Number
      {
         return this._gap;
      }
      
      public function set gap(param1:Number) : void
      {
         if(this._gap == param1)
         {
            return;
         }
         this._gap = param1;
         this.invalidate("styles");
      }
      
      public function get firstGap() : Number
      {
         return this._firstGap;
      }
      
      public function set firstGap(param1:Number) : void
      {
         if(this._firstGap == param1)
         {
            return;
         }
         this._firstGap = param1;
         this.invalidate("styles");
      }
      
      public function get lastGap() : Number
      {
         return this._lastGap;
      }
      
      public function set lastGap(param1:Number) : void
      {
         if(this._lastGap == param1)
         {
            return;
         }
         this._lastGap = param1;
         this.invalidate("styles");
      }
      
      public function get padding() : Number
      {
         return this._paddingTop;
      }
      
      public function set padding(param1:Number) : void
      {
         this.paddingTop = param1;
         this.paddingRight = param1;
         this.paddingBottom = param1;
         this.paddingLeft = param1;
      }
      
      public function get paddingTop() : Number
      {
         return this._paddingTop;
      }
      
      public function set paddingTop(param1:Number) : void
      {
         if(this._paddingTop == param1)
         {
            return;
         }
         this._paddingTop = param1;
         this.invalidate("styles");
      }
      
      public function get paddingRight() : Number
      {
         return this._paddingRight;
      }
      
      public function set paddingRight(param1:Number) : void
      {
         if(this._paddingRight == param1)
         {
            return;
         }
         this._paddingRight = param1;
         this.invalidate("styles");
      }
      
      public function get paddingBottom() : Number
      {
         return this._paddingBottom;
      }
      
      public function set paddingBottom(param1:Number) : void
      {
         if(this._paddingBottom == param1)
         {
            return;
         }
         this._paddingBottom = param1;
         this.invalidate("styles");
      }
      
      public function get paddingLeft() : Number
      {
         return this._paddingLeft;
      }
      
      public function set paddingLeft(param1:Number) : void
      {
         if(this._paddingLeft == param1)
         {
            return;
         }
         this._paddingLeft = param1;
         this.invalidate("styles");
      }
      
      public function get tabFactory() : Function
      {
         return this._tabFactory;
      }
      
      public function set tabFactory(param1:Function) : void
      {
         if(this._tabFactory == param1)
         {
            return;
         }
         this._tabFactory = param1;
         this.invalidate("tabFactory");
      }
      
      public function get firstTabFactory() : Function
      {
         return this._firstTabFactory;
      }
      
      public function set firstTabFactory(param1:Function) : void
      {
         if(this._firstTabFactory == param1)
         {
            return;
         }
         this._firstTabFactory = param1;
         this.invalidate("tabFactory");
      }
      
      public function get lastTabFactory() : Function
      {
         return this._lastTabFactory;
      }
      
      public function set lastTabFactory(param1:Function) : void
      {
         if(this._lastTabFactory == param1)
         {
            return;
         }
         this._lastTabFactory = param1;
         this.invalidate("tabFactory");
      }
      
      public function get tabInitializer() : Function
      {
         return this._tabInitializer;
      }
      
      public function set tabInitializer(param1:Function) : void
      {
         if(this._tabInitializer == param1)
         {
            return;
         }
         this._tabInitializer = param1;
         this.invalidate("data");
      }
      
      public function get selectedIndex() : int
      {
         trace(this._selectedIndex);
         return this._selectedIndex;
      }
      
      public function set selectedIndex(param1:int) : void
      {
         trace(this._selectedIndex);
         if(this._selectedIndex == param1)
         {
            return;
         }
         this._selectedIndex = param1;
         this.invalidate("selected");
         this.dispatchEventWith("change");
      }
      
      public function get selectedItem() : Object
      {
         var _loc1_:int = this.selectedIndex;
         if(!this._dataProvider || _loc1_ < 0 || _loc1_ >= this._dataProvider.length)
         {
            return null;
         }
         return this._dataProvider.getItemAt(_loc1_);
      }
      
      public function set selectedItem(param1:Object) : void
      {
         if(!this._dataProvider)
         {
            this.selectedIndex = -1;
            return;
         }
         this.selectedIndex = this._dataProvider.getItemIndex(param1);
      }
      
      public function get customTabStyleName() : String
      {
         return this._customTabStyleName;
      }
      
      public function set customTabStyleName(param1:String) : void
      {
         if(this._customTabStyleName == param1)
         {
            return;
         }
         this._customTabStyleName = param1;
         this.invalidate("tabFactory");
      }
      
      public function get customTabName() : String
      {
         return this.customTabStyleName;
      }
      
      public function set customTabName(param1:String) : void
      {
         this.customTabStyleName = param1;
      }
      
      public function get customFirstTabStyleName() : String
      {
         return this._customFirstTabStyleName;
      }
      
      public function set customFirstTabStyleName(param1:String) : void
      {
         if(this._customFirstTabStyleName == param1)
         {
            return;
         }
         this._customFirstTabStyleName = param1;
         this.invalidate("tabFactory");
      }
      
      public function get customFirstTabName() : String
      {
         return this.customFirstTabStyleName;
      }
      
      public function set customFirstTabName(param1:String) : void
      {
         this.customFirstTabStyleName = param1;
      }
      
      public function get customLastTabStyleName() : String
      {
         return this._customLastTabStyleName;
      }
      
      public function set customLastTabStyleName(param1:String) : void
      {
         if(this._customLastTabStyleName == param1)
         {
            return;
         }
         this._customLastTabStyleName = param1;
         this.invalidate("tabFactory");
      }
      
      public function get customLastTabName() : String
      {
         return this.customLastTabStyleName;
      }
      
      public function set customLastTabName(param1:String) : void
      {
         this.customLastTabStyleName = param1;
      }
      
      public function get tabProperties() : Object
      {
         if(!this._tabProperties)
         {
            this._tabProperties = new PropertyProxy(childProperties_onChange);
         }
         return this._tabProperties;
      }
      
      public function set tabProperties(param1:Object) : void
      {
         var _loc3_:PropertyProxy = null;
         if(this._tabProperties == param1)
         {
            return;
         }
         if(!param1)
         {
            param1 = new PropertyProxy();
         }
         if(!(param1 is PropertyProxy))
         {
            _loc3_ = new PropertyProxy();
            for(var _loc2_:String in param1)
            {
               _loc3_[_loc2_] = param1[_loc2_];
            }
            param1 = _loc3_;
         }
         if(this._tabProperties)
         {
            this._tabProperties.removeOnChangeCallback(childProperties_onChange);
         }
         this._tabProperties = PropertyProxy(param1);
         if(this._tabProperties)
         {
            this._tabProperties.addOnChangeCallback(childProperties_onChange);
         }
         this.invalidate("styles");
      }
      
      override public function dispose() : void
      {
         this._selectedIndex = -1;
         this.dataProvider = null;
         super.dispose();
      }
      
      override protected function initialize() : void
      {
         this.toggleGroup = new ToggleGroup();
         this.toggleGroup.isSelectionRequired = true;
         this.toggleGroup.addEventListener("change",toggleGroup_changeHandler);
      }
      
      override protected function draw() : void
      {
         var _loc4_:Boolean = this.isInvalid("data");
         var _loc6_:Boolean = this.isInvalid("styles");
         var _loc5_:Boolean = this.isInvalid("state");
         var _loc2_:Boolean = this.isInvalid("selected");
         var _loc1_:Boolean = this.isInvalid("tabFactory");
         var _loc3_:Boolean = this.isInvalid("size");
         if(_loc4_ || _loc1_)
         {
            this.refreshTabs(_loc1_);
         }
         if(_loc4_ || _loc1_ || _loc6_)
         {
            this.refreshTabStyles();
         }
         if(_loc4_ || _loc1_ || _loc2_)
         {
            this.commitSelection();
         }
         if(_loc4_ || _loc1_ || _loc5_)
         {
            this.commitEnabled();
         }
         if(_loc6_)
         {
            this.refreshLayoutStyles();
         }
         this.layoutTabs();
      }
      
      protected function commitSelection() : void
      {
         var count:int = this.activeTabs.length;
         if(count == 0)
         {
            this._selectedIndex = -1;
            this.toggleGroup.selectedIndex = -1;
            return;
         }
           if(this._selectedIndex < -1)
         {
            this._selectedIndex = 0;
         }
         else if(this._selectedIndex >= count)
         {
            this._selectedIndex = count - 1;
         }
         this.toggleGroup.selectedIndex = this._selectedIndex;
      }
      
      protected function commitEnabled() : void
      {
         for each(var _loc1_:ToggleButton in this.activeTabs)
         {
            _loc1_.isEnabled = this._isEnabled;
         }
      }
      
      protected function refreshTabStyles() : void
      {
         var _loc2_:Object = null;
         for(var _loc1_:String in this._tabProperties)
         {
            _loc2_ = this._tabProperties[_loc1_];
            for each(var _loc3_:ToggleButton in this.activeTabs)
            {
               _loc3_[_loc1_] = _loc2_;
            }
         }
      }
      
      protected function refreshLayoutStyles() : void
      {
         if(this._direction == "vertical")
         {
            if(this.horizontalLayout)
            {
               this.horizontalLayout = null;
            }
            if(!this.verticalLayout)
            {
               this.verticalLayout = new VerticalLayout();
               this.verticalLayout.useVirtualLayout = false;
            }
            this.verticalLayout.distributeHeights = this._distributeTabSizes;
            this.verticalLayout.horizontalAlign = this._horizontalAlign;
            this.verticalLayout.verticalAlign = this._verticalAlign == "justify" ? "top" : this._verticalAlign;
            this.verticalLayout.gap = this._gap;
            this.verticalLayout.firstGap = this._firstGap;
            this.verticalLayout.lastGap = this._lastGap;
            this.verticalLayout.paddingTop = this._paddingTop;
            this.verticalLayout.paddingRight = this._paddingRight;
            this.verticalLayout.paddingBottom = this._paddingBottom;
            this.verticalLayout.paddingLeft = this._paddingLeft;
         }
         else
         {
            if(this.verticalLayout)
            {
               this.verticalLayout = null;
            }
            if(!this.horizontalLayout)
            {
               this.horizontalLayout = new HorizontalLayout();
               this.horizontalLayout.useVirtualLayout = false;
            }
            this.horizontalLayout.distributeWidths = this._distributeTabSizes;
            this.horizontalLayout.horizontalAlign = this._horizontalAlign == "justify" ? "left" : this._horizontalAlign;
            this.horizontalLayout.verticalAlign = this._verticalAlign;
            this.horizontalLayout.gap = this._gap;
            this.horizontalLayout.firstGap = this._firstGap;
            this.horizontalLayout.lastGap = this._lastGap;
            this.horizontalLayout.paddingTop = this._paddingTop;
            this.horizontalLayout.paddingRight = this._paddingRight;
            this.horizontalLayout.paddingBottom = this._paddingBottom;
            this.horizontalLayout.paddingLeft = this._paddingLeft;
         }
      }
      
      protected function defaultTabInitializer(param1:ToggleButton, param2:Object) : void
      {
         if(param2 is Object)
         {
            if(param2.hasOwnProperty("label"))
            {
               param1.label = param2.label;
            }
            else
            {
               param1.label = param2.toString();
            }
            for each(var _loc3_:String in DEFAULT_TAB_FIELDS)
            {
               if(param2.hasOwnProperty(_loc3_))
               {
                  param1[_loc3_] = param2[_loc3_];
               }
            }
         }
         else
         {
            param1.label = "";
         }
      }
      
      protected function refreshTabs(param1:Boolean) : void
      {
         var _loc10_:int = 0;
         var _loc6_:Object = null;
         var _loc7_:ToggleButton = null;
         var _loc3_:int = 0;
         var _loc11_:Boolean = this._ignoreSelectionChanges;
         this._ignoreSelectionChanges = true;
         var _loc5_:int = this.toggleGroup.selectedIndex;
         this.toggleGroup.removeAllItems();
         var _loc8_:Vector.<ToggleButton> = this.inactiveTabs;
         this.inactiveTabs = this.activeTabs;
         this.activeTabs = _loc8_;
         this.activeTabs.length = 0;
         this._layoutItems.length = 0;
         _loc8_ = null;
         if(param1)
         {
            this.clearInactiveTabs();
         }
         else
         {
            if(this.activeFirstTab)
            {
               this.inactiveTabs.shift();
            }
            this.inactiveFirstTab = this.activeFirstTab;
            if(this.activeLastTab)
            {
               this.inactiveTabs.pop();
            }
            this.inactiveLastTab = this.activeLastTab;
         }
         this.activeFirstTab = null;
         this.activeLastTab = null;
         var _loc4_:int = 0;
         var _loc9_:int = int(this._dataProvider ? this._dataProvider.length : 0);
         var _loc2_:int = _loc9_ - 1;
         _loc10_ = 0;
         while(_loc10_ < _loc9_)
         {
            _loc6_ = this._dataProvider.getItemAt(_loc10_);
            if(_loc10_ == 0)
            {
               _loc7_ = this.activeFirstTab = this.createFirstTab(_loc6_);
            }
            else if(_loc10_ == _loc2_)
            {
               _loc7_ = this.activeLastTab = this.createLastTab(_loc6_);
            }
            else
            {
               _loc7_ = this.createTab(_loc6_);
            }
            this.toggleGroup.addItem(_loc7_);
            this.activeTabs[_loc4_] = _loc7_;
            this._layoutItems[_loc4_] = _loc7_;
            _loc4_++;
            _loc10_++;
         }
         this.clearInactiveTabs();
         this._ignoreSelectionChanges = _loc11_;
         if(_loc5_ >= 0)
         {
            _loc3_ = this.activeTabs.length - 1;
            if(_loc5_ < _loc3_)
            {
               _loc3_ = _loc5_;
            }
            this._ignoreSelectionChanges = _loc5_ == _loc3_;
            this.toggleGroup.selectedIndex = _loc3_;
            this._ignoreSelectionChanges = _loc11_;
         }
      }
      
      protected function clearInactiveTabs() : void
      {
         var _loc3_:int = 0;
         var _loc1_:ToggleButton = null;
         var _loc2_:int = int(this.inactiveTabs.length);
         _loc3_ = 0;
         while(_loc3_ < _loc2_)
         {
            _loc1_ = this.inactiveTabs.shift();
            this.destroyTab(_loc1_);
            _loc3_++;
         }
         if(this.inactiveFirstTab)
         {
            this.destroyTab(this.inactiveFirstTab);
            this.inactiveFirstTab = null;
         }
         if(this.inactiveLastTab)
         {
            this.destroyTab(this.inactiveLastTab);
            this.inactiveLastTab = null;
         }
      }
      
      protected function createFirstTab(param1:Object) : ToggleButton
      {
         var _loc2_:ToggleButton = null;
         var _loc3_:Function = null;
         if(this.inactiveFirstTab)
         {
            _loc2_ = this.inactiveFirstTab;
            this.inactiveFirstTab = null;
         }
         else
         {
            _loc3_ = this._firstTabFactory != null ? this._firstTabFactory : this._tabFactory;
            _loc2_ = ToggleButton(_loc3_());
            if(this._customFirstTabStyleName)
            {
               _loc2_.styleNameList.add(this._customFirstTabStyleName);
            }
            else if(this._customTabStyleName)
            {
               _loc2_.styleNameList.add(this._customTabStyleName);
            }
            else
            {
               _loc2_.styleNameList.add(this.firstTabStyleName);
            }
            _loc2_.isToggle = true;
            this.addChild(_loc2_);
         }
         this._tabInitializer(_loc2_,param1);
         return _loc2_;
      }
      
      protected function createLastTab(param1:Object) : ToggleButton
      {
         var _loc2_:ToggleButton = null;
         var _loc3_:Function = null;
         if(this.inactiveLastTab)
         {
            _loc2_ = this.inactiveLastTab;
            this.inactiveLastTab = null;
         }
         else
         {
            _loc3_ = this._lastTabFactory != null ? this._lastTabFactory : this._tabFactory;
            _loc2_ = ToggleButton(_loc3_());
            if(this._customLastTabStyleName)
            {
               _loc2_.styleNameList.add(this._customLastTabStyleName);
            }
            else if(this._customTabStyleName)
            {
               _loc2_.styleNameList.add(this._customTabStyleName);
            }
            else
            {
               _loc2_.styleNameList.add(this.lastTabStyleName);
            }
            _loc2_.isToggle = true;
            this.addChild(_loc2_);
         }
         this._tabInitializer(_loc2_,param1);
         return _loc2_;
      }
      
      protected function createTab(param1:Object) : ToggleButton
      {
         var _loc2_:ToggleButton = null;
         if(this.inactiveTabs.length == 0)
         {
            _loc2_ = this._tabFactory();
            if(this._customTabStyleName)
            {
               _loc2_.styleNameList.add(this._customTabStyleName);
            }
            else
            {
               _loc2_.styleNameList.add(this.tabStyleName);
            }
            _loc2_.isToggle = true;
            this.addChild(_loc2_);
         }
         else
         {
            _loc2_ = this.inactiveTabs.shift();
         }
         this._tabInitializer(_loc2_,param1);
         return _loc2_;
      }
      
      protected function destroyTab(param1:ToggleButton) : void
      {
         this.toggleGroup.removeItem(param1);
         this.removeChild(param1,true);
      }
      
      protected function layoutTabs() : void
      {
         this._viewPortBounds.x = 0;
         this._viewPortBounds.y = 0;
         this._viewPortBounds.scrollX = 0;
         this._viewPortBounds.scrollY = 0;
         this._viewPortBounds.explicitWidth = this.explicitWidth;
         this._viewPortBounds.explicitHeight = this.explicitHeight;
         this._viewPortBounds.minWidth = this._minWidth;
         this._viewPortBounds.minHeight = this._minHeight;
         this._viewPortBounds.maxWidth = this._maxWidth;
         this._viewPortBounds.maxHeight = this._maxHeight;
         if(this.verticalLayout)
         {
            this.verticalLayout.layout(this._layoutItems,this._viewPortBounds,this._layoutResult);
         }
         else if(this.horizontalLayout)
         {
            this.horizontalLayout.layout(this._layoutItems,this._viewPortBounds,this._layoutResult);
         }
         this.setSizeInternal(this._layoutResult.contentWidth,this._layoutResult.contentHeight,false);
         for each(var _loc1_:ToggleButton in this.activeTabs)
         {
            _loc1_.validate();
         }
      }
      
      protected function childProperties_onChange(param1:PropertyProxy, param2:String) : void
      {
         this.invalidate("styles");
      }
      
      protected function toggleGroup_changeHandler(param1:Event) : void
      {
         if(this._ignoreSelectionChanges)
         {
            return;
         }
         this.selectedIndex = this.toggleGroup.selectedIndex;
      }
      
      protected function dataProvider_addItemHandler(param1:Event, param2:int) : void
      {
         if(this._selectedIndex >= param2)
         {
            this.selectedIndex += 1;
            this.invalidate("selected");
         }
         this.invalidate("data");
      }
      
      protected function dataProvider_removeItemHandler(param1:Event, param2:int) : void
      {
         var _loc3_:int = 0;
         var _loc5_:int = 0;
         var _loc4_:int = 0;
         if(this._selectedIndex > param2)
         {
            this.selectedIndex -= 1;
         }
         else if(this._selectedIndex == param2)
         {
            _loc3_ = this._selectedIndex;
            _loc5_ = _loc3_;
            _loc4_ = this._dataProvider.length - 1;
            if(_loc5_ > _loc4_)
            {
               _loc5_ = _loc4_;
            }
            if(_loc3_ == _loc5_)
            {
               this.invalidate("selected");
               this.dispatchEventWith("change");
            }
            else
            {
               this.selectedIndex = _loc5_;
            }
         }
         this.invalidate("data");
      }
      
      protected function dataProvider_resetHandler(param1:Event) : void
      {
         if(this._dataProvider.length > 0)
         {
            if(this._selectedIndex != 0)
            {
               this.selectedIndex = 0;
            }
            else
            {
               this.invalidate("selected");
               this.dispatchEventWith("change");
            }
         }
         else if(this._selectedIndex >= 0)
         {
            this.selectedIndex = -1;
         }
         this.invalidate("data");
      }
      
      protected function dataProvider_replaceItemHandler(param1:Event, param2:int) : void
      {
         if(this._selectedIndex == param2)
         {
            this.invalidate("selected");
            this.dispatchEventWith("change");
         }
         this.invalidate("data");
      }
      
      protected function dataProvider_updateItemHandler(param1:Event, param2:int) : void
      {
         this.invalidate("data");
      }
   }
}

