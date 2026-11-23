package
{
   import flash.desktop.NativeApplication;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.BlendMode;
   import flash.display.Loader;
   import flash.display.PNGEncoderOptions;
   import flash.display.Graphics;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.InvokeEvent;
   import flash.filesystem.File;
   import flash.filesystem.FileMode;
   import flash.filesystem.FileStream;
   import flash.filters.BlurFilter;
   import flash.filters.GlowFilter;
   import flash.geom.ColorTransform;
   import flash.geom.Matrix;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.net.URLRequest;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import flash.utils.ByteArray;

   // Renders the Demonblade effect core (pasted below by demonblade_fx_preview.py)
   // into PNG frames with the same sprite list the game hands to Starling.
   public class DemonFxHarness extends Sprite
   {
/*CORE*/
      private static const W:int = 480;
      private static const H:int = 720;
      private static const FPS:int = 30;
      private var outDir:File;
      private var arts:Object = {};
      private var textures:Object = {};
      private var pending:int = 0;
      private var scenes:Array;

      public function DemonFxHarness()
      {
         NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE,onInvoke);
      }
      private function onInvoke(event:InvokeEvent) : void
      {
         outDir=new File(String(event.arguments[0]));
         scenes=JSON.parse(String(event.arguments[2])) as Array;
         var artDir:File=new File(String(event.arguments[1]));
         var names:Object={};
         for each(var scene:Object in scenes) for each(var unit:Object in scene.units) names[unit.art]=true;
         for(var name:String in names)
         {
            var file:File=artDir.resolvePath(name+".png");
            if(!file.exists) continue;
            ++pending;
            loadArt(name,file);
         }
         if(!pending) renderAll();
      }
      private function loadArt(name:String, file:File) : void
      {
         var loader:Loader=new Loader();
         loader.contentLoaderInfo.addEventListener(Event.COMPLETE,function(e:Event):void
         {
            arts[name]=Bitmap(loader.content).bitmapData;
            if(--pending==0) renderAll();
         });
         loader.load(new URLRequest(file.url));
      }
      private function texture(id:String) : BitmapData
      {
         if(!textures[id]) textures[id]=demonFxPaint105(id);
         return textures[id];
      }
      private function renderAll() : void
      {
         // A sheet of every texture, for review.
         var sheet:BitmapData=new BitmapData(1500,300,false,0x101418);
         var x:Number=10;
         for each(var id:String in ["glow","ember","spark","slash","ring","sigil","flame","shard","smoke","blade"])
         {
            var tex:BitmapData=texture(id);
            var m:Matrix=new Matrix();m.translate(x,150-tex.height/2);
            sheet.draw(tex,m,null,id=="smoke" ? BlendMode.NORMAL : BlendMode.ADD,null,true);
            x+=tex.width+10;
         }
         save(sheet,outDir.resolvePath("textures.png"));
         for each(var scene:Object in scenes) renderScene(scene);
         NativeApplication.nativeApplication.exit(0);
      }
      private function save(bmp:BitmapData, file:File) : void
      {
         var bytes:ByteArray=bmp.encode(bmp.rect,new PNGEncoderOptions(true));
         var stream:FileStream=new FileStream();stream.open(file,FileMode.WRITE);stream.writeBytes(bytes);stream.close();
      }
      private function background() : BitmapData
      {
         var shape:Shape=new Shape();
         var m:Matrix=new Matrix();m.createGradientBox(W,H,Math.PI/2);
         shape.graphics.beginGradientFill("linear",[0x18231f,0x24332b,0x18231f],[1,1,1],[0,128,255],m);
         shape.graphics.drawRect(0,0,W,H);shape.graphics.endFill();
         shape.graphics.beginFill(0x2f4237,.65);shape.graphics.drawRect(130,0,220,H);shape.graphics.endFill();
         for(var y:int=0;y<H;y+=64)
         {
            shape.graphics.beginFill(0x3a5042,.35);shape.graphics.drawRect(134,y+2,212,58);shape.graphics.endFill();
         }
         shape.graphics.lineStyle(2,0x111a16,.8);shape.graphics.moveTo(130,0);shape.graphics.lineTo(130,H);shape.graphics.moveTo(350,0);shape.graphics.lineTo(350,H);
         var bmp:BitmapData=new BitmapData(W,H,false,0);bmp.draw(shape);
         return bmp;
      }
      private function ease(p:Number) : Number
      {
         p=Math.max(0,Math.min(1,p));return 1-(1-p)*(1-p)*(1-p);
      }
      private function unitAt(scene:Object, index:int, t:Number) : Array
      {
         var unit:Object=scene.units[index];var x:Number=unit.x;var y:Number=unit.y;
         for each(var move:Object in scene.moves || [])
         {
            if(move.unit!=index || t<move.at) continue;
            var p:Number=ease((t-move.at)/move.len);
            x+=(move.x-x)*p;y+=(move.y-y)*p;
         }
         return [x,y];
      }
      private function valueAt(scene:Object, key:String, index:int, t:Number) : Number
      {
         var value:Number=Number(scene.units[index][key]);
         for each(var change:Object in scene[key] || [])
            if(change.unit==index && t>=change.at) value=change.value;
         return value;
      }
      private function drawUnit(canvas:BitmapData, scene:Object, index:int, t:Number) : void
      {
         var unit:Object=scene.units[index];var at:Array=unitAt(scene,index,t);
         var shape:Shape=new Shape();var g:*=shape.graphics;
         var frame:uint=unit.team==1 ? 0x4d8fe0 : 0xd8503c;
         g.beginFill(0x000000,.35);g.drawEllipse(-40,36,80,18);g.endFill();
         g.beginFill(0x1b1f26,1);g.drawRoundRect(-45,-45,90,90,16,16);g.endFill();
         var m:Matrix=new Matrix();
         canvas.draw(shape,new Matrix(1,0,0,1,at[0],at[1]));
         var art:BitmapData=arts[unit.art];
         if(art)
         {
            // The chibi art sits in the middle of a wide canvas.
            var scale:Number=86/(art.height*.82);
            m.translate(-art.width/2,-art.height*.52);m.scale(scale,scale);m.translate(at[0],at[1]);
            canvas.draw(art,m,null,null,new Rectangle(at[0]-43,at[1]-43,86,86),true);
         }
         shape=new Shape();g=shape.graphics;
         g.lineStyle(4,frame,1);g.drawRoundRect(-45,-45,90,90,16,16);
         var hp:Number=valueAt(scene,"hp",index,t);
         g.lineStyle();g.beginFill(0x111111,1);g.drawRect(-40,-58,80,8);g.endFill();
         g.beginFill(unit.team==1 ? 0x4fd06a : 0xe04a3a,1);g.drawRect(-39,-57,78*hp,6);g.endFill();
         if(unit.rage!=undefined)
         {
            g.beginFill(0x111111,1);g.drawRect(-40,-50,80,5);g.endFill();
            g.beginFill(0xff8a1e,1);g.drawRect(-39,-49,78*valueAt(scene,"rage",index,t),3);g.endFill();
         }
         canvas.draw(shape,new Matrix(1,0,0,1,at[0],at[1]));
         if(unit.label) drawText(canvas,String(unit.label),0xFF6A84,at[0],at[1]+56,1,14);
      }
      private function drawText(canvas:BitmapData, text:String, color:uint, x:Number, y:Number, alpha:Number, size:int) : void
      {
         var field:TextField=new TextField();field.autoSize=TextFieldAutoSize.LEFT;
         field.defaultTextFormat=new TextFormat("Microsoft YaHei",size,color,true);field.text=text;
         var holder:Sprite=new Sprite();holder.addChild(field);
         field.filters=[new GlowFilter(0x000000,1,4,4,6,2)];
         canvas.draw(holder,new Matrix(1,0,0,1,x-field.width/2,y-field.height/2),new ColorTransform(1,1,1,alpha),null,null,true);
      }
      private function renderScene(scene:Object) : void
      {
         var dir:File=outDir.resolvePath(String(scene.id));
         if(dir.exists) dir.deleteDirectory(true);
         dir.createDirectory();
         var bg:BitmapData=background();
         var canvas:BitmapData=new BitmapData(W,H,false,0);
         var frames:int=int(Math.ceil(Number(scene.dur)*FPS));
         var sprites:Array=[];
         for(var f:int=0;f<frames;f++)
         {
            var t:Number=f/FPS;
            canvas.copyPixels(bg,bg.rect,new flash.geom.Point(0,0));
            for(var u:int=0;u<scene.units.length;u++) drawUnit(canvas,scene,u,t);
            for each(var fx:Object in scene.fx)
            {
               var age:Number=t-Number(fx.at);
               if(age<0) continue;
               var life:Number=demonFxLife105(fx.kind);
               var fade:Number=1;
               if(fx.stop!=undefined && t>Number(fx.stop)) fade=1-(t-Number(fx.stop))/.35;
               if(fade<=0 || (life>=0 && age>=life)) continue;
               // Looping and self effects follow the caster, the rest the target, as in the game.
               var src:Array=unitAt(scene,fx.src,fx.frozen ? Number(fx.at) : t);
               var dst:Array=unitAt(scene,fx.tgt!=undefined ? fx.tgt : fx.src,t);
               sprites.length=0;
               demonFxSprites105(fx.kind,age,src[0],src[1],dst[0],dst[1],int(fx.seed || 1),sprites);
               for each(var part:Object in sprites)
               {
                  var tex:BitmapData=texture(part.k);
                  var m:Matrix=new Matrix();
                  m.translate(-tex.width/2,-tex.height/2);m.scale(part.sx,part.sy);m.rotate(part.r);m.scale(1,part.fy);m.translate(part.x,part.y);
                  var c:uint=part.c;
                  var tint:ColorTransform=new ColorTransform(((c>>16)&255)/255,((c>>8)&255)/255,(c&255)/255,Math.max(0,Math.min(1,part.a*fade)));
                  canvas.draw(tex,m,tint,part.add ? BlendMode.ADD : BlendMode.NORMAL,null,true);
               }
            }
            for each(var pop:Object in scene.texts || [])
            {
               var p:Number=(t-Number(pop.at))/1.1;
               if(p<0 || p>1) continue;
               var at:Array=unitAt(scene,pop.unit,t);
               drawText(canvas,pop.text,uint(pop.color),at[0],at[1]-70-30*ease(p),p<.75 ? 1 : 1-(p-.75)/.25,int(pop.size || 22));
            }
            drawText(canvas,String(scene.title),0xFFE7B0,W/2,26,1,20);
            save(canvas,dir.resolvePath(("000"+f).substr(-4)+".png"));
         }
      }
   }
}
