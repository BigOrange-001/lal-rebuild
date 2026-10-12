package com.meng52.net
{
   import flash.events.AsyncErrorEvent;
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import flash.events.NetStatusEvent;
   import flash.events.SecurityErrorEvent;
   import flash.net.NetConnection;
   import flash.events.UncaughtErrorEvent;
   import flash.utils.setTimeout;
   import starling.core.Starling;
   import flash.net.Responder;
   import flash.net.URLLoader;
   import flash.net.URLRequest;
   import flash.events.IOErrorEvent;
   
   public class RemotingConnect extends EventDispatcher
   {
      
      public static const NET_ERROR:String = "NET_ERROR";
      
      private var netConnect:NetConnection = null;
      
      private var url:String = "";
      
      private var mainFunName:String = "";
      
      public function RemotingConnect(param1:String, param2:String)
      {
         super();
         var self:RemotingConnect = this;
         setTimeout(function():void {
            Starling.current.nativeStage.getChildAt(0).loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR,function(event:UncaughtErrorEvent):void {
               self.reportDiagnostic(String(event.error) + "\n" + (event.error is Error ? (event.error as Error).getStackTrace() : ""));
            });
         },5000);
         this.mainFunName = param2;
         this.url = param1;
         this.netConnect = new NetConnection();
         this.netConnect.objectEncoding = 3;
         this.netConnect.connect(param1);
         this.netConnect.addEventListener("netStatus",this.onNET_STATUS);
         this.netConnect.addEventListener("securityError",this.securityErrorHandler);
         this.netConnect.addEventListener("asyncError",this.onASYNC_ERROR);
      }
      
      public function call_service(param1:Responder, param2:Object) : void
      {
         try
         {
            this.netConnect.call(this.mainFunName,param1,param2);
         }
         catch(e:Error)
         {
         }
      }
      
      public function reportDiagnostic(message:String):void
      {
         var request:URLRequest = new URLRequest("http://127.0.0.1:8080/debug/client-error");
         request.method = "POST"; request.data = message;
         var loader:URLLoader = new URLLoader();
         loader.addEventListener(IOErrorEvent.IO_ERROR,function(e:IOErrorEvent):void {});
         loader.load(request);
      }
      public function closeNet() : void
      {
         this.netConnect.close();
         this.netConnect = null;
      }
      
      private function onNET_STATUS(param1:NetStatusEvent) : void
      {
         reportDiagnostic(String(param1));
         dispatchEvent(new Event("NET_ERROR"));
         try
         {
         }
         catch(e:Error)
         {
         }
      }
      
      private function securityErrorHandler(param1:SecurityErrorEvent) : void
      {
         reportDiagnostic(String(param1));
         dispatchEvent(new Event("NET_ERROR"));
         try
         {
         }
         catch(e:Error)
         {
         }
      }
      
      private function onASYNC_ERROR(param1:AsyncErrorEvent) : void
      {
         reportDiagnostic(String(param1.error) + "\n" + param1.error.getStackTrace());
         reportDiagnostic(String(param1));
         dispatchEvent(new Event("NET_ERROR"));
         try
         {
         }
         catch(e:Error)
         {
         }
      }
   }
}

