package feathers.core
{
   import flash.utils.Dictionary;
   import starling.animation.IAnimatable;
   import starling.core.Starling;
   
   public final class ValidationQueue implements IAnimatable
   {
      
      private static const STARLING_TO_VALIDATION_QUEUE:Dictionary = new Dictionary(true);
      
      private var _starling:Starling;
      
      private var _isValidating:Boolean = false;
      
      private var _delayedQueue:Vector.<IValidating> = new Vector.<IValidating>(0);
      
      private var _queue:Vector.<IValidating> = new Vector.<IValidating>(0);
      
      public function ValidationQueue(param1:Starling)
      {
         super();
         this._starling = param1;
      }
      
      public static function forStarling(param1:Starling) : ValidationQueue
      {
         if(!param1)
         {
            return null;
         }
         var _loc2_:ValidationQueue = STARLING_TO_VALIDATION_QUEUE[param1];
         if(!_loc2_)
         {
            STARLING_TO_VALIDATION_QUEUE[param1] = _loc2_ = new ValidationQueue(param1);
         }
         return _loc2_;
      }
      
      public function get isValidating() : Boolean
      {
         return this._isValidating;
      }
      
      public function dispose() : void
      {
         if(this._starling)
         {
            this._starling.juggler.remove(this);
            this._starling = null;
         }
      }
      
      public function addControl(param1:IValidating, param2:Boolean) : void
      {
         var _loc7_:int = 0;
         var _loc8_:int = 0;
         var _loc6_:IValidating = null;
         var _loc3_:int = 0;
         if(!this._starling.juggler.contains(this))
         {
            this._starling.juggler.add(this);
         }
         var _loc5_:Vector.<IValidating> = this._isValidating && param2 ? this._delayedQueue : this._queue;
         if(_loc5_.indexOf(param1) >= 0)
         {
            return;
         }
         var _loc4_:int = int(_loc5_.length);
         if(this._isValidating && _loc5_ == this._queue)
         {
            _loc7_ = param1.depth;
            _loc8_ = _loc4_ - 1;
            while(_loc8_ >= 0)
            {
               _loc6_ = IValidating(_loc5_[_loc8_]);
               _loc3_ = _loc6_.depth;
               if(_loc7_ >= _loc3_)
               {
                  break;
               }
               _loc8_--;
            }
            if(++_loc8_ == _loc4_)
            {
               _loc5_[_loc4_] = param1;
            }
            else
            {
               _loc5_.splice(_loc8_,0,param1);
            }
         }
         else
         {
            _loc5_[_loc4_] = param1;
         }
      }
      
      public function advanceTime(param1:Number) : void
      {
         var _loc2_:IValidating = null;
         if(this._isValidating)
         {
            return;
         }
         var _loc3_:int = int(this._queue.length);
         if(_loc3_ == 0)
         {
            return;
         }
         this._isValidating = true;
         try
         {
         this._queue = this._queue.sort(queueSortFunction);
         while(this._queue.length > 0)
         {
            _loc2_ = this._queue.shift();
            if(_loc2_.depth >= 0)
            {
               _loc2_.validate();
            }
         }
         var _loc4_:Vector.<IValidating> = this._queue;
         this._queue = this._delayedQueue;
         this._delayedQueue = _loc4_;
         }
         finally
         {
            this._isValidating = false;
         }
      }
      
      protected function queueSortFunction(param1:IValidating, param2:IValidating) : int
      {
         var _loc3_:int = param2.depth - param1.depth;
         if(_loc3_ > 0)
         {
            return -1;
         }
         if(_loc3_ < 0)
         {
            return 1;
         }
         return 0;
      }
   }
}

