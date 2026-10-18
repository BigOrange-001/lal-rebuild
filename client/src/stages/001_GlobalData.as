package com.meng52.game.global
{
   import com.meng52.game.Game;
   import com.meng52.game.module.skill.SkillSet;
   import com.meng52.game.ui.element.ItemExplorationSelectTeam;
   import com.meng52.game.ui.element.ItemPVPBattleOfThePeak;
   import com.meng52.game.ui.element.ItemPVPBattleOfThePeakDefense;
   import com.meng52.game.ui.element.ItemTeamEmbattle;
   import com.meng52.global.GlobalStaticConst;
   import com.meng52.utils.StageWebViewBase;
   import feathers.controls.SimpleScrollBar;
   import feathers.display.Scale3Image;
   import feathers.textures.Scale3Textures;
   import flash.display.MovieClip;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.Loader;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.events.SecurityErrorEvent;
   import flash.media.Sound;
   import flash.net.URLLoader;
   import flash.net.URLLoaderDataFormat;
   import flash.net.URLRequest;
   import flash.system.LoaderContext;
   import flash.text.TextFormat;
   import flash.utils.ByteArray;
   import flash.utils.setTimeout;
   import flash.utils.clearTimeout;
   import flash.geom.Rectangle;
   import flash.utils.Dictionary;
   import starling.core.Starling;
   import starling.events.EventDispatcher;
   import starling.utils.AssetManager;
   import starling.textures.Texture;
   
   public class GlobalData
   {
      
      public static var First_Get_5Star_Avatar:String = "first_get_5star_avatar";
      
      public static var First_Get_6Star_Avatar:String = "first_get_6star_avatar";
      
      public static var skillB:SkillSet;
      
      public static var skillBoo:Boolean;
      
      public static var sensitiveWords:String;
      
      public static var $notificationsIOS_token:String = "";
      
      public static var $gameLanguage:String = "";
      
      public static const $service_area_star:int = 999;
      
      public static var $pfUserInfo:Object;
      
      public static var $fullScreenWidth:Number = 0;
      
      public static var $fullScreenHeight:Number = 0;
      
      public static var $isNotFullScreen:Boolean = false;
      
      public static var $isNotFullScreenX:Number = 0;
      
      public static var $mConfigIcon:XML;
      
      public static var $mConfigInitLoader:XML;
      
      public static var $mConfigInitWord:XML;
      
      public static var $mStarlingStageWidth:Number = 0;
      
      public static var $mStarlingStageHeight:Number = 0;
      
      public static var $mStage$Starling_w:Number = 0;
      
      public static var $mStage$Starling_h:Number = 0;
      
      public static var $mStageWidth:Number = 0;
      
      public static var $mStageHeight:Number = 0;
      
      public static var $logStr:String = "";
      
      public static var $assetManager:AssetManager;
      
      public static var $mStarling:Starling;
      
      public static var $mEventDispatcher:EventDispatcher;
      
      public static var $mGameClassObject:Game;
      
      public static var $pf_init:Boolean = false;
      
      public static var $sound_lol_theme_end:Boolean = false;
      
      public static var $fragment_data:Object = null;
      
      public static var $tempKFbattle:Boolean = false;
      
      public static var $extreme_groupIndex:int = 0;
      
      public static var isShow_ShareBtn:Boolean = true;
      
      public static var $mUI_loading_clip_:MovieClip = null;
      
      public static var $center_height_curr:uint = 0;
      
      public static var $verticalScrollBarThumbSkinTextures:Scale3Textures;
      
      public static var $_scrollBar:SimpleScrollBar;
      
      public static var $center_height:uint = 0;
      
      public static var $isFightReplay:Boolean = false;
      
      public static var $isFightAwardIndex:int = -1;
      
      public static var $mConfig:Object = null;

      public static var $modRuntime:Object = {};
      public static var $modUid:String = "";
      public static var $modRevision:Number = -1;
      public static var $modDigest:String = "";
      public static var $modReady:Boolean = true;
      public static var $modError:String = "";
      private static var $modGeneration:uint = 0;
      private static var $modAssets:Array = [];
      private static var $modBitmaps:Array = [];

      // Aliases belong to the logged-in save. Nothing from the previous save
      // is allowed to satisfy the next save's resource manifest.
      public static function resetModResources() : uint
      {
         $modGeneration++;
         for each(var asset:Object in $modAssets)
         {
            if(asset.kind == "sound") $assetManager.removeSound(String(asset.alias));
            else $assetManager.removeTexture(String(asset.alias),true);
         }
         for each(var bitmap:BitmapData in $modBitmaps) bitmap.dispose();
         $modAssets = [];
         $modBitmaps = [];
         $modRuntime = {};
         $modUid = "";
         $modRevision = -1;
         $modDigest = "";
         $modReady = false;
         $modError = "";
         return $modGeneration;
      }

      public static function resolveModTexture(name:String) : String
      {
         var aliases:Object = $modRuntime == null ? null : $modRuntime.textureAliases;
         var seen:Object = {};
         for(var i:int = 0; i < 8 && aliases != null && aliases[name] != null; i++)
         {
            if(seen[name]) return "__modMissingHero";
            seen[name] = true;
            name = String(aliases[name]);
         }
         return name;
      }

      public static function modCardFrame(name:String) : Array
      {
         name = resolveModTexture(name);
         var assets:Array = $modRuntime == null ? null : $modRuntime.assets as Array;
         if(assets) for each(var asset:Object in assets)
         {
            if(asset.alias != name || !(asset.cardFrame is Array)) continue;
            var f:Array = asset.cardFrame;
            if(f.length != 4) return null;
            for(var i:int = 0; i < 4; i++) if(typeof f[i] != "number" || !isFinite(Number(f[i]))) return null;
            if(f[0] < 0 || f[1] < 0 || f[2] < 8 || f[3] < 8 || f[0]+f[2] > asset.width || f[1]+f[3] > asset.height) return null;
            return f;
         }
         return null;
      }

      public static function isMissingModHero(id:String) : Boolean
      {
         var base:String = id == null ? "" : id.split("|")[0].split("-")[0];
         var heroes:Object = $modRuntime == null ? null : $modRuntime.heroes;
         return heroes != null && heroes[base] != null && heroes[base].available === false;
      }

      public static function baseModHeroId(id:String) : String
      {
         var base:String = id == null ? "" : id.split("|")[0].split("-")[0];
         var aliases:Object = $modRuntime == null ? null : $modRuntime.aliasBaseIds;
         return aliases != null && aliases[base] != null ? String(aliases[base]) : base;
      }

      public static function modDefinitionId(id:String, scope:String) : String
      {
         var base:String = baseModHeroId(id);
         var scopes:Object = $modRuntime == null ? null : $modRuntime.scopedAvatarIds;
         return scopes != null && scopes[scope] != null && scopes[scope][base] != null ? String(scopes[scope][base]) : base;
      }

      public static function modChannelAllowed(id:String, channel:String) : Boolean
      {
         var heroes:Object = $modRuntime == null ? null : $modRuntime.heroes;
         var metadata:Object = heroes == null ? null : heroes[baseModHeroId(id)];
         return metadata == null || metadata.available !== false && (metadata.channels == null || metadata.channels[channel] !== false);
      }

      public static function canonicalModInstanceId(id:String) : String
      {
         if(id == null) return null;
         var base:String = id.split("|")[0].split("-")[0];
         return baseModHeroId(base) + id.substr(base.length);
      }

      // Adobe as3corelib SHA256/IntUtil byte hashing implementation (BSD-3-Clause).
      // Source: https://github.com/mikechambers/as3corelib
      // Full copyright, license and adaptation notes ship in assets/licenses/as3corelib-SHA256.txt.
      public static function modAssetSha256(bytes:ByteArray) : String
      {
         var position:uint = bytes.position;
         var result:String = "";
         try
         {
            var hash:ByteArray = modShaBlocks(modShaCreateBlocks(bytes));
            for(var i:int = 0; i < hash.length; i++) result += ("0" + hash[i].toString(16)).substr(-2);
         }
         finally { bytes.position = position; }
         return result;
      }

      private static function modShaBlocks( blocks:Array ):ByteArray {
               var h0:int = 0x6a09e667;
               var h1:int = 0xbb67ae85;
               var h2:int = 0x3c6ef372;
               var h3:int = 0xa54ff53a;
               var h4:int = 0x510e527f;
               var h5:int = 0x9b05688c;
               var h6:int = 0x1f83d9ab;
               var h7:int = 0x5be0cd19;

               var k:Array = new Array(0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da, 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070, 0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2);

               var len:int = blocks.length;
               var w:Array = new Array( 64 );

               // loop over all of the blocks
               for ( var i:int = 0; i < len; i += 16 ) {

                  var a:int = h0;
                  var b:int = h1;
                  var c:int = h2;
                  var d:int = h3;
                  var e:int = h4;
                  var f:int = h5;
                  var g:int = h6;
                  var h:int = h7;

                  for(var t:int = 0; t < 64; t++) {

                     if ( t < 16 ) {
                        w[t] = blocks[ i + t ];
                        if(isNaN(w[t])) { w[t] = 0; }
                     } else {
                        var ws0:int = modShaRor(w[t-15], 7) ^ modShaRor(w[t-15], 18) ^ (w[t-15] >>> 3);
                        var ws1:int = modShaRor(w[t-2], 17) ^ modShaRor(w[t-2], 19) ^ (w[t-2] >>> 10);
                        w[t] = w[t-16] + ws0 + w[t-7] + ws1;
                     }

                     var s0:int = modShaRor(a, 2) ^ modShaRor(a, 13) ^ modShaRor(a, 22);
                     var maj:int = (a & b) ^ (a & c) ^ (b & c);
                     var t2:int = s0 + maj;
                     var s1:int = modShaRor(e, 6) ^ modShaRor(e, 11) ^ modShaRor(e, 25);
                     var ch:int = (e & f) ^ ((~e) & g);
                     var t1:int = h + s1 + ch + k[t] + w[t];

                     h = g;
                     g = f;
                     f = e;
                     e = d + t1;
                     d = c;
                     c = b;
                     b = a;
                     a = t1 + t2;
                  }

                  //Add this chunk's hash to result so far:
                  h0 += a;
                  h1 += b;
                  h2 += c;
                  h3 += d;
                  h4 += e;
                  h5 += f;
                  h6 += g;
                  h7 += h;
               }

               var byteArray:ByteArray = new ByteArray();
               byteArray.writeInt(h0);
               byteArray.writeInt(h1);
               byteArray.writeInt(h2);
               byteArray.writeInt(h3);
               byteArray.writeInt(h4);
               byteArray.writeInt(h5);
               byteArray.writeInt(h6);
               byteArray.writeInt(h7);
               byteArray.position = 0;
               return byteArray;
            }

      private static function modShaCreateBlocks( data:ByteArray ):Array
            {
               var oldPosition:int = data.position;
               data.position = 0;

               var blocks:Array = new Array();
               var len:int = data.length * 8;
               var mask:int = 0xFF; // ignore hi byte of characters > 0xFF
               for( var i:int = 0; i < len; i += 8 )
               {
                  blocks[ i >> 5 ] |= ( data.readByte() & mask ) << ( 24 - i % 32 );
               }

               // append padding and length
               blocks[ len >> 5 ] |= 0x80 << ( 24 - len % 32 );
               blocks[ ( ( ( len + 64 ) >> 9 ) << 4 ) + 15 ] = len;

               data.position = oldPosition;

               return blocks;
            }

      private static function modShaRor ( x:int, n:int ):uint {
               var nn:int = 32 - n;
               return ( x << nn ) | ( x >>> ( 32 - nn ) );
            }

      public static function modAssetMatches(bytes:ByteArray, row:Object) : Boolean
      {
         if(bytes == null || row == null || typeof row.bytes != "number" || Number(row.bytes) != bytes.length ||
            typeof row.sha256 != "string" || !/^[a-f0-9]{64}$/.test(String(row.sha256))) return false;
         return modAssetSha256(bytes) == String(row.sha256);
      }

      public static function loadModResources(envelope:Object, done:Function) : void
      {
         var generation:uint = resetModResources();
         if(envelope == null || envelope.uid == null || envelope.cfg == null || envelope.digest == null)
         {
            $modError = "存档 Mod 配置不完整，请重新登录。";
            done(false);
            return;
         }
         $modUid = String(envelope.uid);
         $modRevision = Number(envelope.revision);
         $modDigest = String(envelope.digest);
         $modRuntime = envelope.mod_runtime == null ? {} : envelope.mod_runtime;
         var queue:Array = $modRuntime.assets is Array ? $modRuntime.assets.concat() : [];
         var completed:Boolean = false;
         var timeout:uint = 0;
         var decodedBytes:Number = 0;
         var fail:Function = function(message:String):void
         {
            if(generation != $modGeneration || completed) return;
            completed = true;
            clearTimeout(timeout);
            $modError = message;
            $modReady = false;
            done(false);
         };
         var next:Function = function():void
         {
            if(generation != $modGeneration || completed) return;
            clearTimeout(timeout);
            if(queue.length == 0)
            {
               $modReady = true;
               completed = true;
               done(true);
               return;
            }
            var row:Object = queue.shift();
            timeout = setTimeout(function():void { fail("读取 Mod 资源超时，请检查英雄包后重新登录。"); },20000);
            var path:String = String(row.path);
            var digest:String = String(row.contentDigest);
            if(!/^[a-f0-9]{64}$/.test(digest) || path.length == 0 || path.indexOf("..") >= 0 || path.charAt(0) == "/" || path.indexOf("\\") >= 0 || String(row.alias).indexOf("MOD_") != 0)
            {
               fail("Mod 资源索引无效：" + path);
               return;
            }
            var segments:Array = path.split("/");
            for(var i:int = 0; i < segments.length; i++) segments[i] = encodeURIComponent(String(segments[i]));
            var request:URLRequest = new URLRequest(MainConfig.$SERVER_ADDRESS.replace(/\/$/,"") + "/mods/assets/" + digest + "/" + segments.join("/"));
            var reader:URLLoader = new URLLoader();
            reader.dataFormat = URLLoaderDataFormat.BINARY;
            var error:Function = function(event:Object):void { fail("无法读取 Mod 资源：" + path); };
            reader.addEventListener(IOErrorEvent.IO_ERROR,error);
            reader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,error);
            reader.addEventListener(flash.events.Event.COMPLETE,function(event:flash.events.Event):void
            {
               if(generation != $modGeneration || completed) return;
               var bytes:ByteArray = reader.data as ByteArray;
               if(bytes == null || bytes.length == 0 || bytes.length > 33554432)
               {
                  fail("Mod 资源大小无效：" + path);
                  return;
               }
               try
               {
                  if(!modAssetMatches(bytes,row))
                  {
                     fail("Mod 资源大小或 SHA-256 校验失败：" + path);
                     return;
                  }
               }
               catch(integrityError:Error)
               {
                  fail("无法校验 Mod 资源完整性，请重新登录：" + path);
                  return;
               }
               // Hashing is synchronous in this SWF33-compatible implementation.
               // Give decoding its own budget after a verified download, even
               // when hashing ran past the original network deadline.
               clearTimeout(timeout);
               timeout = setTimeout(function():void { fail("解码 Mod 资源超时，请检查英雄包后重新登录。"); },20000);
               if(row.kind == "sound")
               {
                  try
                  {
                     var sound:Sound = new Sound();
                     sound.loadCompressedDataFromByteArray(bytes,bytes.length);
                     $assetManager.addSound(String(row.alias),sound);
                     $modAssets.push(row);
                     next();
                  }
                  catch(soundError:Error) { fail("Mod 音频解码失败：" + path); }
                  return;
               }
               // loadBytes cannot execute a SWF, including one disguised as an
               // image: reject its signature before touching the decoder.
               if(row.kind != "image" || bytes.length < 4 || !((bytes[0] == 137 && bytes[1] == 80 && bytes[2] == 78 && bytes[3] == 71) || (bytes[0] == 255 && bytes[1] == 216)))
               {
                  fail("Mod 图像格式不受支持：" + path);
                  return;
               }
               var loader:Loader = new Loader();
               loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,error);
               loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR,error);
               loader.contentLoaderInfo.addEventListener(flash.events.Event.COMPLETE,function(loaded:flash.events.Event):void
               {
                  if(generation != $modGeneration || completed) { loader.unloadAndStop(true); return; }
                  var content:Bitmap = loader.content as Bitmap;
                  if(content == null || content.bitmapData.width > 4096 || content.bitmapData.height > 4096 || decodedBytes + content.bitmapData.width * content.bitmapData.height * 4 > 134217728)
                  {
                     loader.unloadAndStop(true);
                     fail("Mod 图像尺寸或类型无效：" + path);
                     return;
                  }
                  try
                  {
                     var bitmap:BitmapData = content.bitmapData.clone();
                     $modBitmaps.push(bitmap);
                     var texture:Texture = Texture.fromBitmapData(bitmap,false,false);
                     texture.root.onRestore = function():void { texture.root.uploadBitmapData(bitmap); };
                     decodedBytes += bitmap.width * bitmap.height * 4;
                     $assetManager.addTexture(String(row.alias),texture);
                     $modAssets.push(row);
                     loader.unloadAndStop(true);
                     next();
                  }
                  catch(textureError:Error)
                  {
                     loader.unloadAndStop(true);
                     fail("Mod 图像上传失败，请减少素材大小或数量：" + path);
                  }
               });
               var context:LoaderContext = new LoaderContext();
               context.allowCodeImport = false;
               try { loader.loadBytes(bytes,context); }
               catch(imageError:Error) { fail("Mod 图像解码失败：" + path); }
            });
            try { reader.load(request); }
            catch(requestError:Error) { fail("无法读取 Mod 资源：" + path); }
         };
         next();
      }

      public static function missingModTexture() : Texture
      {
         var texture:Texture = $assetManager.getTexture("__modMissingHero");
         if(texture == null)
         {
            var bitmap:BitmapData = new BitmapData(160,160,false,0x403846);
            var label:flash.text.TextField = new flash.text.TextField();
            label.defaultTextFormat = new TextFormat("Arial",94,0xDDC8D8,true,null,null,null,null,"center");
            label.width = 160;
            label.height = 145;
            label.text = "?";
            bitmap.draw(label);
            texture = Texture.fromBitmapData(bitmap,false,false);
            texture.root.onRestore = function():void { texture.root.uploadBitmapData(bitmap); };
            $assetManager.addTexture("__modMissingHero",texture);
         }
         return texture;
      }
      
      public static var $mConfig_simple:Object = null;
      
      public static var $mConfig_ploy_system_simple:Object = null;
      
      public static var $mConfig_dn:Object = null;
      
      public static var $mConfig_pvp_robot:Object = null;
      
      public static var $mConfig_exchange:Object = null;
      
      public static var $mConfig_festival:Object = null;
      
      public static var $mConfig_wager_festival:Object = null;
      
      public static var $mConfig_ploy_cycle:Object = null;
      
      public static var $mConfig_zones:Object = null;
      
      public static var $mConfig_skill:Object = null;
      
      public static var $mConfig_book_skill:Object = null;
      
      public static var $mConfig_avatar:Object = null;
      
      public static var $mConfig_talent:Object = null;
      
      public static var $mConfig_equip:Object = null;
      
      public static var $mConfig_destiny:Object = null;
      
      public static var $mConfig_effect:Object = null;
      
      public static var $mConfig_guide:Object = null;
      
      public static var $mConfig_guide_new:Object = null;
      
      public static var $mConfig_msg:Object = null;
      
      public static var $mConfig_vip:Object = null;
      
      public static var $mConfig_pay:Object = null;
      
      public static var $mConfig_client:Object = null;
      
      public static var $lastLoginZone:Array;
      
      public static var $recommendLoginZone:String;
      
      public static var $mGuild_simple:Object = null;
      
      public static var $m15v15FightData:Object = null;
      
      public static var $config_pvp_robot:Array = null;
      
      public static var $config_pvp_title:Array = null;
      
      public static var $pvp_rival:Object = null;
      
      public static var $gameIsOut:Boolean = false;
      
      public static var $gameGetTimer:int = 0;
      
      public static var $gambleReportTimer:int = 0;
      
      public static var $gambleReportStr:String = "";
      
      public static var $gConfig_battle_main:Object = null;
      
      public static var $gConfig_combat_main:Object = null;
      
      public static var $mConfig_battle_main:Object = null;
      
      public static var $mConfig_combat_main:Object = null;
      
      public static var $mConfig_battle_association:Object = null;
      
      public static var $mConfig_combat_association:Object = null;
      
      public static var $mConfig_battle_ploy:Object = null;
      
      public static var $mConfig_combat_ploy:Object = null;
      
      public static var $mConfig_check_in:Object = null;
      
      public static var $stageWebViewBase:StageWebViewBase;
      
      public static var $weiboType:String = "";
      
      public static var $weiboBinding:Boolean = false;
      
      public static var $currentGuide:String = null;
      
      public static var $reLoginGame:Boolean = false;
      
      public static var $gUserData:Object = null;
      
      public static var $mUserData:Object = null;
      
      public static var $mUserExtremeData:Object = null;
      
      public static var $gUserData_avatarNum:int = 0;
      
      public static var $mUserData_avatarNum:int = 0;
      
      public static var $mConfigVersion:String = "1";
      
      public static var $mServiceID:String = "";
      
      public static var $mServiceID_obj:Object = null;
      
      public static var $mInitAvatarID:String = "";
      
      public static var $mUserName:String = "";
      
      public static var $isAssets:Boolean = false;
      
      public static var $isService:Boolean = false;
      
      public static var $isGameing:Boolean = false;
      
      public static var $tempTeamID:int = 0;
      
      public static var $tempTeam:Array;
      
      public static var $tempTeamSelect:Object;
      
      public static var $tempChangeAvatarTitle:String;
      
      public static var $tempEditTeamSelect:Object = null;
      
      public static var $tempTeamSelectLS:Number = 0;
      
      public static var $tempTeamPower:Number = 0;
      
      public static var $tempTeamPowerTemp:Number = 0;
      
      public static var $tempUserLS:Number = 0;
      
      public static var $tempTeamSelect_member:Object;
      
      public static var $tempTeamID_Other:int = 0;
      
      public static var $tempTeamSelect_Other:Object;
      
      public static var $isUpdateMazeTeam:Boolean = false;
      
      public static var $isUpdateTeamEquip:Boolean = false;
      
      public static var $isUpdateTeamInfo:Boolean = false;
      
      public static var $tempMazeSelect:String;
      
      public static var $tempPVE_battleID:String = "";
      
      public static var $tempPVE_battleID_normal:String = "";
      
      public static var $tempPVE_battleID_hard:String = "";
      
      public static var $tempPVE_battleID_ACTIVITIES:String = "";
      
      public static var $tempPVE_battleID_GUILD:String = "";
      
      public static var $tempPVE_battleID_isFirstWin:Boolean = false;
      
      public static var $tempPVE_battleStyle:int = 0;
      
      public static var $tempPVE_combatID:String = "";
      
      public static var $tempPVE_type:String = "";
      
      public static var $tempPVE_type_id:int = 0;
      
      public static var $tempPVP_Elite_award_tab_id:int = 0;
      
      public static var $tempPVP_Elite_fans_tab_id:int = 0;
      
      public static var $tempPVE_drag:ItemTeamEmbattle;
      
      public static var $tempSocial_friend:Object;
      
      public static var $tempExpeditionDnStone:int = -1;
      
      public static var $tempMorphItem:Object = null;
      
      public static var $tempEquipFragment:Array = null;
      
      public static var $tempAvatarFragment:Array = null;
      
      public static var $tempAvatarBetter:Object;
      
      public static var $tempAvatarStarUp:Object;
      
      public static var $tempLockItem:Object = null;
      
      public static var $tempItemTeamEmbattle:Object = null;
      
      public static var $tempFriend:Array = null;
      
      public static var $tempFriendRequest:Array = null;
      
      public static var $tempOnline:Array = null;
      
      public static var $tempHelpAvatar:Object = null;
      
      public static var $isNoFriendToPVE:Boolean = false;
      
      public static var $tempCasinoResult:Object;
      
      public static var $typeCasinoResult:String = "";
      
      public static var $traceRollInfoB:Boolean = true;
      
      public static var $isGameEndAward:Boolean = false;
      
      public static var $test:*;
      
      public static var $load2Status:int = 0;
      
      public static var $mEnqueue_isLoading:Boolean = false;
      
      public static var $msg_new_num:int = 0;
      
      public static var $friendReques_new_num:int = 0;
      
      public static var $shopAppleGetList:Boolean = false;
      
      public static var $localService:String = "";
      
      public static var $localUID:String = "";
      
      public static var $localUID_lastLogin:String = "";
      
      public static var $searchTypeFun:Function = null;
      
      public static var $gameEndAwardObj:Object = null;
      
      public static var $avatarStoreObj:Object = null;
      
      public static var $panelCasinoClipB:Boolean = false;
      
      public static var $avatarsTypeNumArr:Array;
      
      public static var $tempEquipIndex:int = 0;
      
      public static var $tempEquipFunId:int = 0;
      
      public static var $tempAlchemyIndex:int = 0;
      
      public static var $tempAlchemyFunId:int = 0;
      
      public static var $tempEquipChangeIndex:int = 0;
      
      public static var $tempEquipChangeId:String;
      
      public static var $tempEquipCurrSelected:String = "";
      
      public static var $tempAvatarCurrSeleted:String = "";
      
      private static var $combatType:int = 0;
      
      public static var $PVPupClip:Boolean = false;
      
      public static var $shopType:int = 0;
      
      public static var $shopInByMain:Boolean = false;
      
      public static var $vipGiftData:Object;
      
      public static var $tempChatRoomIndex:int = 0;
      
      public static var $pro_send_time_server:Number = 0;
      
      public static var $pro_send_time_world:Number = 0;
      
      public static var $pro_send_time_private:Number = 0;
      
      public static var $pro_send_time_guild:Number = 0;
      
      public static var $mPrivateChatUserData:Object;
      
      public static var $chatBtnTouchable:Boolean = true;
      
      public static var $hasChatWords:Boolean = false;
      
      public static var $InfoLookFromChat:Boolean = false;
      
      public static var $BattleOfThePeakTeamSelect:int;
      
      public static var $BattleOfThePeakTeam:Dictionary;
      
      public static var $BattleOfThePeakItem:ItemPVPBattleOfThePeak;
      
      public static var $BattleOfThePeakTure:Boolean = false;
      
      public static var $BattleOfThePeakDefenseSelect:int;
      
      public static var $BattleOfThePeakDefenseTeam:Dictionary;
      
      public static var $BattleOfThePeakDefenseItem:ItemPVPBattleOfThePeakDefense;
      
      public static var $exploration_data:Object;
      // Transient formation selection flags belong to the client, not the
      // server-owned exploration snapshot which is replaced on state_sync.
      public static var $explorationArmyTeam:Object = {};
      
      public static var $exploration_select_avatar:Object;
      
      public static var $exploration_drag:ItemExplorationSelectTeam;
      
      public static var $exploration_team_avatar:Array;
      
      public static var $exploration_team_avtId_arr:Array;
      
      public static var $poke_Data:Object;
      
      public static var $maze_BattleId:String = "";
      
      public static var $maze_CombatId:String = "";
      
      public static var $pvp_Embattle:String = "";
      
      public static var $tempExtremeBetLevel:int = -1;
      
      public static var $tempIsApplyorChangeTeam:Boolean = false;
      
      public static var $tempScreenToFans:String;
      
      public static var backFromExploration:Boolean = false;
      
      public static const $iconRec:Rectangle = new Rectangle(0,0,90,90);
      
      public static const $iconRec90:Rectangle = new Rectangle(0,0,90,90);
      
      public static const $iconRec92:Rectangle = new Rectangle(0,0,92,92);
      
      public static const $VIPWidth:Rectangle = new Rectangle(0,0,640,90);
      
      public static var $gambleReportArr:Array = [];
      
      public static var $tempSell:Array = [];
      
      public static var $tempSellItem:Object = {};
      
      public static var $tempAvatarBetterArr:Array = [];
      
      public static var $tempAvatarBetterItem:Object = {};
      
      public static var $tempFoodForBook:Array = [];
      
      public static var $tempObjectFoodForBook:Object = {};
      
      public static var $tempExpeditionArr:Array = [];
      
      public static var $tempExpeditionItem:Object = {};
      
      public static var $tempExpeditionElements:Object = {};
      
      public static var $tempEquipSellArr:Array = [];
      
      public static var $tempEquipSellItem:Object = {};
      
      public static var $tempBetterElements:Object = {};
      
      public static var $tempAvatarChoose:Array = [];
      
      public static var $tempAvatarLock:Object = {};
      
      public static var $localUser:Object = {
         "uid":"",
         "sessionid":"",
         "avatarLock":{}
      };
      
      public static var $localMusic:Object = {
         "music":1,
         "sound":1
      };
      
      public static var $searchType:Array = [0,0,0];
      
      public static var $mSYS:Object = {
         "uid":"sys",
         "name":"",
         "lv":1,
         "login_time":new Date()
      };
      
      public static var $tempExtremeBetTeam:Array = [];
      
      public static var $tempExtremeBetTeamDate:Object = {};
      
      public static var $tempExtremeBetUser:Array = [];
      
      public static var $tempExtreme32Users:Array = [];
      
      public static var $panelSortArr:Array = [];
      
      public static var $userGuild:Object = {};
      
      public function GlobalData()
      {
         super();
      }
      
      public static function get $config_battle_main() : Object
      {
         if($currentGuide == "A")
         {
            return $gConfig_battle_main;
         }
         return $mConfig_battle_main;
      }
      
      public static function get $config_combat_main() : Object
      {
         if($currentGuide == "A")
         {
            return $gConfig_combat_main;
         }
         return $mConfig_combat_main;
      }
      
      public static function get $config_battle_association() : Object
      {
         return $mConfig_battle_association;
      }
      
      public static function get $config_combat_association() : Object
      {
         return $mConfig_combat_association;
      }
      
      public static function get $isForceGuide() : Boolean
      {
         return $currentGuide == "A" || $currentGuide == "B";
      }
      
      public static function set $userData(param1:Object) : void
      {
         if($currentGuide == "A")
         {
            $gUserData = param1;
         }
         else
         {
            $mUserData = param1;
         }
      }
      
      public static function get $userData() : Object
      {
         if($currentGuide == "A")
         {
            return $gUserData;
         }
         return $mUserData;
      }

      private static var $profileSyncUid:String = "";
      private static var $profileSyncRevision:Number = -1;
      private static var $profileSyncAppliedEnvelope:Object = null;

      public static function isValidProfileSyncEnvelope(param1:Object, param2:String = null) : Boolean
      {
         var _profile:Object = param1 == null ? null : param1.profile;
         var _revisionValue:Object = param1 == null ? null : param1.revision;
         var _revision:Number = param1 == null ? NaN : Number(param1.revision);
         var _expectedUid:String = param2;
         var _required:Array = ["uid","name","exploration","cid","hid","lv","exp","gold","coin","score","medal","mark","vip_lv","vip_exp","vip_time","catena","energy","fragment_energy","attrs","records","avatars","my_equips","avatar_soul","equip_soul","team","fragment","pf_info","login_time","create_time","add_time","friends","combat_main","combat_score","ploy_cids","tasks","association","check_in","title","zone"];
         if(_expectedUid == null)
         {
            if($userData == null || $userData.uid == null)
            {
               return false;
            }
            _expectedUid = String($userData.uid);
         }
         if(param1 == null || param1.uid == null || _profile == null || _profile.uid == null
            || String(param1.uid) != _expectedUid || String(_profile.uid) != String(param1.uid)
            || (!(_revisionValue is int) && !(_revisionValue is uint) && !(_revisionValue is Number))
            || isNaN(_revision) || !isFinite(_revision) || _revision < 0 || _revision != Math.floor(_revision))
         {
            return false;
         }
         for each(var _field:String in _required)
         {
            if(!_profile.hasOwnProperty(_field))
            {
               return false;
            }
         }
         return true;
      }
      
      public static function seedProfileSync(param1:Object) : void
      {
         $profileSyncAppliedEnvelope = null;
         // Login may switch accounts (or re-enter the same account). Never
         // carry a previous user's temporary exploration formation selection.
         $explorationArmyTeam = {};
         if(!isValidProfileSyncEnvelope(param1))
         {
            $profileSyncUid = "";
            $profileSyncRevision = -1;
            return;
         }
         $profileSyncUid = String(param1.uid);
         $profileSyncRevision = -1;
         applyProfileSnapshot(param1);
      }

      public static function applyProfileSnapshot(param1:Object) : Boolean
      {
         var _profile:Object = param1 == null ? null : param1.profile;
         var _revision:Number = param1 == null ? NaN : Number(param1.revision);
         var _data:Object = $userData;
         if(_data == null || String(param1 == null ? "" : param1.uid) != $profileSyncUid
            || !isValidProfileSyncEnvelope(param1) || isNaN(_revision) || _revision <= $profileSyncRevision)
         {
            return false;
         }

         // This is the explicit persisted-profile projection. Do not replace
         // $userData: keys owned by the client (for example GameMap/BMtype),
         // mail counters, sessionid, and panel temp state are not in this list.
         _data.uid = _profile.uid;
         _data.name = _profile.name;
         _data.exploration = _profile.exploration;
         _data.cid = _profile.cid;
         _data.hid = _profile.hid;
         _data.lv = _profile.lv;
         _data.exp = _profile.exp;
         _data.gold = _profile.gold;
         _data.coin = _profile.coin;
         if(_profile.hasOwnProperty("mod_state")) _data.mod_state = _profile.mod_state;
         else delete _data.mod_state;
         if(_profile.hasOwnProperty("spending"))
         {
            _data.spending = _profile.spending;
         }
         else
         {
            delete _data.spending;
         }
         _data.score = _profile.score;
         _data.medal = _profile.medal;
         _data.mark = _profile.mark;
         _data.vip_lv = _profile.vip_lv;
         _data.vip_exp = _profile.vip_exp;
         _data.vip_time = _profile.vip_time;
         _data.catena = _profile.catena;
         _data.energy = _profile.energy;
         _data.fragment_energy = _profile.fragment_energy;
         _data.attrs = _profile.attrs;
         _data.records = _profile.records;
         _data.avatars = _profile.avatars;
         _data.my_equips = _profile.my_equips;
         if(_profile.hasOwnProperty("as_equips"))
         {
            _data.as_equips = _profile.as_equips;
         }
         else
         {
            delete _data.as_equips;
         }
         _data.avatar_soul = _profile.avatar_soul;
         _data.equip_soul = _profile.equip_soul;
         _data.team = _profile.team;
         _data.fragment = _profile.fragment;
         if(_profile.hasOwnProperty("pending_pve"))
         {
            _data.pending_pve = _profile.pending_pve;
         }
         else
         {
            delete _data.pending_pve;
         }
         if(_profile.hasOwnProperty("pending_limit_break"))
         {
            _data.pending_limit_break = _profile.pending_limit_break;
         }
         else
         {
            delete _data.pending_limit_break;
         }
         _data.pf_info = _profile.pf_info;
         _data.login_time = _profile.login_time;
         _data.create_time = _profile.create_time;
         _data.add_time = _profile.add_time;
         _data.friends = _profile.friends;
         _data.combat_main = _profile.combat_main;
         _data.combat_score = _profile.combat_score;
         _data.ploy_cids = _profile.ploy_cids;
         _data.tasks = _profile.tasks;
         if(_profile.hasOwnProperty("task"))
         {
            _data.task = _profile.task;
         }
         else
         {
            delete _data.task;
         }
         _data.association = _profile.association;
         if(_profile.hasOwnProperty("boss_state"))
         {
            _data.boss_state = _profile.boss_state;
         }
         else
         {
            delete _data.boss_state;
         }
         _data.check_in = _profile.check_in;
         _data.title = _profile.title;
         _data.zone = _profile.zone;
         $profileSyncRevision = _revision;
         $profileSyncAppliedEnvelope = param1;
         return true;
      }

      public static function isCurrentProfileSyncEnvelope(param1:Object) : Boolean
      {
         return isValidProfileSyncEnvelope(param1) && String(param1.uid) == $profileSyncUid
            && Number(param1.revision) == $profileSyncRevision;
      }

      public static function wasProfileSyncApplied(param1:Object) : Boolean
      {
         return param1 != null && param1 === $profileSyncAppliedEnvelope;
      }
      
      public static function set $userData_avatarNum(param1:int) : void
      {
         if($currentGuide == "A")
         {
            $gUserData_avatarNum = param1;
         }
         else
         {
            $mUserData_avatarNum = param1;
         }
      }
      
      public static function get $userData_avatarNum() : int
      {
         if($currentGuide == "A")
         {
            return $gUserData_avatarNum;
         }
         return $mUserData_avatarNum;
      }
      
      public static function set $useExtreme(param1:Object) : void
      {
         $mUserExtremeData = param1;
      }
      
      public static function get $useExtreme() : Object
      {
         return $mUserExtremeData;
      }
      
      public static function get $diff() : int
      {
         if($tempPVE_type == "status_pve_hard")
         {
            return 1;
         }
         return 0;
      }
      
      public static function get $isPVE() : Boolean
      {
         return $combatType == 0;
      }
      
      public static function $setPVE() : void
      {
         $combatType = 0;
      }
      
      public static function get $isPVP() : Boolean
      {
         return $combatType == 1;
      }
      
      public static function $setPVP() : void
      {
         $combatType = 1;
      }
      
      public static function get $isFragment() : Boolean
      {
         return $combatType == 2;
      }
      
      public static function $setFragment() : void
      {
         $combatType = 2;
      }
      
      public static function get $isExtreme() : Boolean
      {
         return $combatType == 3;
      }
      
      public static function $setExtreme() : void
      {
         $combatType = 3;
      }
      
      public static function get $isExploration() : Boolean
      {
         return $combatType == 4;
      }
      
      public static function $setExploration() : void
      {
         $combatType = 4;
      }
      
      public static function get $isBattleOfThePeak() : Boolean
      {
         return $combatType == 5;
      }
      
      public static function $setBattleOfThePeak() : void
      {
         $combatType = 5;
      }
      
      public static function formatVScaleY_center(param1:Number) : int
      {
         return int(param1 / 850 * GlobalData.$center_height_curr);
      }
      
      public static function formatVScaleY(param1:Number) : int
      {
         return int(param1 / 960 * GlobalData.$mStageHeight);
      }
      
      public static function formatVScaleY_centerB(param1:Number, param2:Number = 200) : int
      {
         return int(param1 / (960 - 121 - 110 - param2) * (centerRealHeight() - param2));
      }
      
      public static function centerRealHeight() : int
      {
         return GlobalData.$mStageHeight - 121 - 110 - 10;
      }
      
      public static function getUI_ICON_BOTTOM_Name(param1:int) : String
      {
         return "UI_icon_bottom_" + param1 + "_0000";
      }
      
      public static function verticalScrollBarFactory() : SimpleScrollBar
      {
         var _loc1_:SimpleScrollBar = null;
         var _loc2_:Scale3Image = null;
         if($verticalScrollBarThumbSkinTextures == null)
         {
            $verticalScrollBarThumbSkinTextures = new Scale3Textures($assetManager.getTexture("UI_bar_0_0000"),5,10,"vertical");
         }
         if(_loc1_ == null)
         {
            _loc1_ = new SimpleScrollBar();
            _loc1_.direction = "vertical";
            _loc2_ = new Scale3Image($verticalScrollBarThumbSkinTextures,GlobalStaticConst.$scaleFactor);
            _loc2_.height = 10 * GlobalStaticConst.$scaleFactor;
            _loc1_.thumbProperties.defaultSkin = _loc2_;
            _loc1_.paddingTop = _loc1_.paddingRight = _loc1_.paddingBottom = 4 * GlobalStaticConst.$scaleFactor;
         }
         return _loc1_;
      }
   }
}
