package com.meng52.net
{
   import flash.net.Responder;
   import flash.net.URLLoader;
   import flash.net.URLRequest;
   import flash.utils.setTimeout;
   
   public class RpcStaticCall
   {
      
      public static var $remoting:RemotingConnect = null;
      
      public static var JSON_TAG:String = "false";
      
      private static var $URLLoader:URLLoader;
      
      private static var $URLRe:URLRequest;
      
      public function RpcStaticCall()
      {
         super();
      }
      
      public static function connectNet(param1:String, param2:String) : void
      {
         if($remoting != null)
         {
            $remoting.closeNet();
            $remoting = null;
         }
         $remoting = new RemotingConnect(param1,param2);
      }
      
      public static function toNet(param1:String) : void
      {
         if($URLRe == null)
         {
            $URLRe = new URLRequest(param1);
         }
         if($URLLoader == null)
         {
            $URLLoader = new URLLoader();
         }
         $URLLoader.load($URLRe);
      }
      
      public static function callService(param1:Object, param2:Function = null, param3:Function = null) : void
      {
         try
         {
         $remoting.call_service(new Responder(function(result:Object):void {
            try { if(param2 != null) param2(result); }
            catch(error:Error) { $remoting.reportDiagnostic(String(error) + "\n" + error.getStackTrace()); throw error; }
         },function(status:Object):void { $remoting.reportDiagnostic("AMF status " + status.code); if(param3 != null) param3(status); }),param1);
         }
         catch(error:Error)
         {
            // Deliver transport faults after SendAndSelect has registered its
            // loading state and retry timer, just like an asynchronous fault.
            if(param3 != null) setTimeout(param3,1,{"code":"NetConnection.Call.Failed","description":String(error)});
         }
      }
   }
}

