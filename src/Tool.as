package 
{	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.SecurityErrorEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.FileReference;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import ru.inspirit.net.MultipartURLLoader;
	import ru.inspirit.net.events.MultipartURLLoaderEvent;
	
	public class Tool
	{		
		[Embed(source="save_over.jpg")]
		public static var Save_Over:Class; 
		public static var save_over:Bitmap = new Save_Over() as Bitmap;
		[Embed(source="save_up.jpg")]
		public static var Save_Up:Class;
		public static var save_up:Bitmap = new Save_Up() as Bitmap;
		[Embed(source="select.jpg")]
		public static var Select:Class;
		public static var select:Bitmap = new Select() as Bitmap;
		[Embed(source="info.gif")]
		public static var Info:Class;
		public static var info:Bitmap = new Info() as Bitmap;
		
		public static function trim(str:String):String
		{
			return str.replace(/^\s+|\s+$/g, "");
		}
		
		// 得到等比缩放率
		public static function getZoomScale(contWidth:Number, contHeight:Number, imgWidth:Number, imgHeight:Number):Number
		{
			var zoom:Number = 1;
			
			if ( (contWidth / contHeight) <= (imgWidth / imgHeight) )
			{
				zoom = contWidth / imgWidth;
			}
			else
			{
				zoom = contHeight / imgHeight;
			}	
			
			return zoom;
		}
		
		// 缩放图片
		public static function zoomImage(bitData:BitmapData, scaleX:Number, scaleY:Number):BitmapData
		{
			var mc:Matrix = new Matrix();
			mc.scale(scaleX, scaleY);
			
			var retBitData:BitmapData = new BitmapData(Math.round(bitData.width * scaleX), Math.round(bitData.height * scaleY));
			retBitData.draw(bitData, mc, null, null, null, true);
			
			return retBitData;
		}
		
		// 截图
		public static function cropImage(bitData:BitmapData, rect:Rectangle):BitmapData
		{
			var retBitData:BitmapData = new BitmapData(rect.width, rect.height);
			retBitData.copyPixels(bitData, rect, new Point(0, 0));
			
			return retBitData;
		}
		
		// 得到一个区域
		public static function createDiv(x:Number, y:Number, width:Number, height:Number, borderWidth:Number, borderColor:uint, bgColor:uint, alpha:Number, borderAplpha:Number = 1):Sprite
		{	
			var div:Sprite = new Sprite();
			div.x = x;
			div.y = y;									
			
			// draw rect
			div.graphics.beginFill(bgColor, alpha);
			div.graphics.drawRect(0, 0, width, height);
			div.graphics.endFill();
			
			
			// draw border
			if (borderWidth > 0){
				var borders:Shape = new Shape();	
				var x_1:Number = borderWidth/2;
				var x_2:Number = width - borderWidth/2;
				var y_1:Number = borderWidth/2;
				var y_2:Number = height - borderWidth/2;
				
				borders.graphics.lineStyle(borderWidth, borderColor, borderAplpha);
				borders.graphics.moveTo(x_1, y_1);
				
				borders.graphics.lineTo(x_2, y_1);
				borders.graphics.lineTo(x_2, y_2);
				borders.graphics.lineTo(x_1, y_2);
				borders.graphics.lineTo(x_1, y_1);
				
				div.addChild(borders);
			}			
			return div;
		}
		
		// 得到一个按钮
		public static function createBtnWithoutBorder(x:Number, y:Number, text:String):Sprite
		{	
			var btnWidth:Number = 80;
			var btnHeight:Number = 20;
			
			var btn:Sprite = createDiv(x, y, btnWidth, btnHeight, 1, 0xFFFFFF, 0xFFFFFF, 0,0);
			var txt:TextField = new TextField();
			txt.text = text;
			txt.selectable = false;
			txt.width = btnWidth;
			txt.height = btnHeight;
			txt.autoSize = TextFieldAutoSize.CENTER;
			txt.y = 1;
			
			btn.addChild(txt);			
			return btn;
		}
		
		// 得到一个按钮
		public static function createBtn(x:Number, y:Number, borderColor:Number, bgColor:Number, text:String):Sprite
		{	
			var btnWidth:Number = 80;
			var btnHeight:Number = 20;
			
			var btn:Sprite = createDiv(x, y, btnWidth, btnHeight, 1, borderColor, bgColor, 1);
			var txt:TextField = new TextField();
			txt.text = text;
			
			txt.width = btnWidth;
			txt.height = btnHeight;
			txt.autoSize = TextFieldAutoSize.CENTER;
			txt.y = 1;
			
			btn.addChild(txt);
			btn.addEventListener(MouseEvent.MOUSE_OVER, function():void{
				Mouse.cursor = MouseCursor.BUTTON;
			});
			btn.addEventListener(MouseEvent.MOUSE_OUT, function():void{
				Mouse.cursor = MouseCursor.AUTO;
			});
			
			return btn;
		}
		
		//創建一個保存按鈕
		public static function createSaveBtn():Sprite
		{
			var btnWidth:Number = 80;
			var btnHeight:Number = 27;
			
			var btn:Sprite = new Sprite();
			btn.addChild(save_over);
			btn.addChild(save_up);
			var onOver:Function = function(event:MouseEvent):void
			{
				save_up.visible = false;
			};
			
			var onOut:Function = function (event:MouseEvent):void
			{
				save_up.visible = true;
			};
			btn.addEventListener(MouseEvent.MOUSE_OVER,onOver);
			btn.addEventListener(MouseEvent.MOUSE_OUT,onOut);
			return btn;
		}	
		
		public static function createSelectBtn():Sprite
		{
			var btnWidth:Number = 80;
			var btnHeight:Number = 27;
			
			var btn:Sprite = new Sprite();
			btn.addChild(select);
			return btn;
		}
		
		public static function createInfoTip():Sprite
		{
			var infoTip:Sprite = new Sprite();
			infoTip.addChild(info);
			
			var tip:TextField = new TextField();
			tip.width = 280;
			tip.height = 14;
			tip.autoSize = TextFieldAutoSize.LEFT;
			tip.textColor = 0x57636A;
			tip.text = "请上传JPG，GIF，PNG的图片，且文件小于1MB";
			tip.x = 20;
			tip.y = -3;
			infoTip.addChild(tip);
			
			return infoTip;
		}	
		// 右旋转90
		public static function rotateRight(bitData:BitmapData):BitmapData
		{
			var mc:Matrix = new Matrix();
			
			mc.rotate(Math.PI/2);
			mc.translate(bitData.height, 0);
			
			var retBitData:BitmapData = new BitmapData(bitData.height, bitData.width);
			retBitData.draw(bitData, mc);
			
			return retBitData;
		}
		
		// 左旋转90
		public static function rotateLeft(bitData:BitmapData):BitmapData
		{
			var mc:Matrix = new Matrix();
			
			mc.rotate(-Math.PI/2);
			mc.translate(0, bitData.width);
			
			var retBitData:BitmapData = new BitmapData(bitData.height, bitData.width);
			retBitData.draw(bitData, mc);
			
			return retBitData;
		}
		
		// 下载图片
		public static function downloadImage(url:String, cbSuccess:Function, cbError:Function):void
		{
			var fileLoader:Loader = new Loader();
			var fileRequest:URLRequest = new URLRequest(url);
			fileLoader.load(fileRequest);
	
			
			fileLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void{
				cbSuccess(e);
			});
			fileLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):void{
				cbError("下载文件失败!");
			});
		};
		
		// 上传图片
		public static function uploadImage(url:String,variables:Dictionary, cbSuccess:Function, cbError:Function):void
		{
//			var imgBytes:ByteArray = new JPGEncoder(80).encode(bitData);
//			var imgStr:String = Base64.encodeByteArray(imgBytes);
//			
//			url = encodeURI(url);
//			
//			var request:URLRequest = new URLRequest(url);
//			request.method = URLRequestMethod.POST;
//			//request.contentType = "text/xml";
//			
//			var urlvars:URLVariables = new URLVariables();
//			urlvars.cropImage = imgStr;
//			request.data = urlvars;
			
			if(variables == null)
			{
				return ;
			}	
			
			var onPrepareProgress:Function = function(event:MultipartURLLoaderEvent):void
			{
				trace(event.bytesWritten/event.bytesTotal);
			}
			
			var onPrepareComplete:Function = function(event:MultipartURLLoaderEvent):void
			{
				trace("prepare complete!");
			}
			
			var onError:Function = function(event:Event):void
			{
				if(cbError != null)
				{
					cbError();
				}
			}
				
			var multiLoader:MultipartURLLoader = new MultipartURLLoader();
			multiLoader.dataFormat = URLLoaderDataFormat.VARIABLES;
			
			multiLoader.addEventListener(Event.COMPLETE, function(event:Event):void{			
				var results:URLVariables = multiLoader.loader.data as URLVariables;				
				if (cbSuccess != null) cbSuccess(decodeURIComponent(results.toString()));
			});
			multiLoader.addEventListener(MultipartURLLoaderEvent.DATA_PREPARE_PROGRESS, onPrepareProgress);
			multiLoader.addEventListener(MultipartURLLoaderEvent.DATA_PREPARE_COMPLETE, onPrepareComplete);
			multiLoader.addEventListener(IOErrorEvent.IO_ERROR,onError);
			multiLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,onError);
			
			try
			{
				for(var key:String in variables)
				{
					if(key.indexOf(".jpg") != -1)
					{
						var imgBytes:ByteArray = new JPGEncoder(90).encode(variables[key] as BitmapData);
						multiLoader.addFile(imgBytes,key,"Filedata[]");
					}else
					{
						multiLoader.addVariable(key,variables[key]);		
					}
				}
				multiLoader.load(url);
			} 
			catch(error:Error) 
			{
				if(cbError != null)
				{
					cbError();
				}
			}				
		}
	}
}




