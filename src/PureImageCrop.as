/*
 * PureImageCrop
 *
*/

package
{

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.FullScreenEvent;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.system.Security;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.clearInterval;
	import flash.utils.clearTimeout;
	import flash.utils.flash_proxy;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;
	
	[SWF(width=744, height=433)]
	public class PureImageCrop extends Sprite
	{	
		// 默认处理尺寸
		private var defaultSize:Size = new Size(200, 200);
		
		// 操作遮罩
		private var controlMaskDiv:Sprite;
		
		// 文件引用
		private var fileRef:FileReference;
		// 原始图片
		private var origImage:Bitmap;
		// 操作区域图片容器
		private var handleImageDiv:Sprite;
		
		// 提示信息
		private var infoTip:Sprite;
		// 上传按钮
		private var uploadBtn:Sprite;
		// 左转按钮
		private var leftRotateBtn:Sprite;
		// 右转按钮
		private var rightRotateBtn:Sprite;
		// 保存按钮
		private var saveImageBtn:Sprite;
		
		// 操作区域
		private var handleDiv:Sprite;
		// 操作区域尺寸
		private var handleSize:Size;
		// 操作区域图片缩放比例
		private var handleZoomScale:Number = 1;
		
		// 结果区域
		private var retDiv:Sprite;
		// 结果区域尺寸
		private var retDivSize:Size;				
		// 结果图片
		private var retImage:Bitmap;
		
		// 結果區域_中
		private var retMidDiv:Sprite;
		// 結果區域尺寸_中 
		private var retMidDivSize:Size = new Size(50,50);
		// 結果圖片_中
		private var retMidImage:Bitmap;
		// 結果區域_小
		private var retSmallDiv:Sprite;
		// 結果區域尺寸_小
		private var retSmallDivSize:Size = new Size(30,30);
		// 結果圖片_小
		private var retSmallImage:Bitmap;
		
		// 遮罩层
		private var maskDiv:MaskDiv;
		private var maskDivSize:Size = new Size();
		
		// 剪切层
		private var cutDiv:CutDiv;
		// 剪切层位置
		private var cutDivPos:Point = new Point();
		// 剪切层大小
		private var cutDivInitSize:Size;
		private var cutDivSize:Size = new Size();
		// 剪切层大小最小值
		private var cutDivMinSize:Size;
		
		// 剪切层缩放层
		private var cutZoomDiv:Sprite;
		private var cutZoomDivSize:Size = new Size(10, 10);
		private var cutZoomDivX:Number = 0;
		private var cutZoomDivY:Number = 0;
		
		// 颜色枚举
		private var Colors:Object = {
			divBorderColor : 0xCCCCCC,
			divBgColor : 0xf9f9f9,
			maskBgColor : 0xdc473c
		};
		
		// 上传地址
		private var uploadUrl:String = "";
		// 成功回调
		private var cbSuccess:String = "";
		// 失败回调
		private var cbError:String = "";
		// 用戶ID
		private var uid:String;
		private var showRatation:Boolean;
		public function PureImageCrop()
		{			
			parseParams();
			buildStage();
			initImageLoad();
		}
	
		// 设定尺寸
		private function setSize(initSize:Size):void
		{
			var maxLen:Number = Math.max(initSize.width, initSize.height);
			handleSize = new Size(maxLen + 100, maxLen + 100);
			
			retDivSize = new Size(initSize.width, initSize.height);
			cutDivInitSize = new Size(initSize.width/2, initSize.height/2);
			cutDivMinSize = new Size(initSize.width/100, initSize.height/100);
		}
		
		// 处理js传过来的参数
		private function parseParams():void
		{
			var params:Object = stage.loaderInfo.parameters;
		
			if (params["uploadUrl"]) uploadUrl = params["uploadUrl"];
			if (params["cbSuccess"]) cbSuccess = params["cbSuccess"];
			if (params["cbError"]) cbError = params["cbError"];
			if (params["uid"]) uid = params["uid"];
			
			if (params["showRotation"] == "true") showRatation = true;
			// 跨域策略文件
			if (params["crossDomainFiles"]){
				Security.allowDomain("*");
				var files:Array = String(params["crossDomainFiles"]).split(",");
				for (var i:Number = 0; i<files.length; i++){
					Security.loadPolicyFile(Tool.trim(String(files[i])));
				}
			}
			
			// 处理尺寸
			if (params["imageSize"]){
				var sizeInfo:Array = params["imageSize"].split(",");
				var width:Number = Number(sizeInfo[0]) || defaultSize.width;
				var height:Number = Number(sizeInfo[1]) || defaultSize.height;
				
				defaultSize = new Size(width, height);
			}
			
			
			setSize(defaultSize);
		}
		
		// 初始化图片加载
		private function initImageLoad():void
		{	
			var params:Object = stage.loaderInfo.parameters;
			if (params["initImage"] && String(params["initImage"]).length > 10){
				Tool.downloadImage(params["initImage"], 
					function(e:Event):void{
						var loaderInfo:LoaderInfo = e.target as LoaderInfo
						showHandleImage(loaderInfo.content);
					}, 
					function(msg:String):void{
						if(ExternalInterface.available)
						{
							try
							{
								ExternalInterface.call(cbError, msg);	
							} 
							catch(error:Error) 
							{
								
							}							
						}						
					}
				);
			}
		}
		
		//构建舞台
		private function buildStage():void
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			infoTip = Tool.createInfoTip();
			infoTip.x = 50;
			infoTip.y = 30;
			parent.addChild(infoTip);
			
			if(showRatation)
			{
				// 左转按钮
				leftRotateBtn = Tool.createBtn(50, 378, Colors["divBorderColor"], Colors["divBgColor"], "左转");
				leftRotateBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void{
					if(origImage == null) return;
					origImage.bitmapData = Tool.rotateLeft(origImage.bitmapData);
					showHandleImage(origImage);
				});
				parent.addChild(leftRotateBtn);
				
				
				// 右转按钮
				rightRotateBtn = Tool.createBtn(150, 378, Colors["divBorderColor"], Colors["divBgColor"], "右转");
				rightRotateBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void{
					if(origImage == null) return;
					origImage.bitmapData = Tool.rotateRight(origImage.bitmapData);
					showHandleImage(origImage);
				});
				parent.addChild(rightRotateBtn);
			}	
			
			

			handleDiv = Tool.createDiv(50, 50, handleSize.width, handleSize.height, 1, Colors["divBorderColor"], Colors["divBgColor"], 1);
			
			var operTip:TextField = new TextField();
			operTip.autoSize = TextFieldAutoSize.LEFT;
			operTip.textColor = 0x57636A;
			operTip.text = "拖拽,缩放左边图片,生成满意的图片";
			operTip.x = 430;
			operTip.y = 60;
			parent.addChild(operTip);
			
			retDiv = Tool.createDiv(430, 85, 200, 200, 1, Colors["divBorderColor"], Colors["divBgColor"], 0.5);
			var retTip:Sprite = Tool.createBtnWithoutBorder(500,290,"裁剪图");			
			parent.addChild(retTip);
			
			retMidDiv = Tool.createDiv(663,110,50,50,1, Colors["divBorderColor"], Colors["divBgColor"], 0.5);			
			var retMidTip:Sprite = Tool.createBtnWithoutBorder(650,160,"中尺寸图片");
			parent.addChild(retMidTip);
			
			retSmallDiv = Tool.createDiv(675,210,30,30,1, Colors["divBorderColor"], Colors["divBgColor"], 0.5);
			var retSmallTip:Sprite = Tool.createBtnWithoutBorder(650,240,"小尺寸图片");			
			parent.addChild(retSmallTip);
			
			parent.addChild(handleDiv);
			parent.addChild(retDiv);
			parent.addChild(retMidDiv);
			parent.addChild(retSmallDiv);
			
			
			uploadBtn = Tool.createSelectBtn();
			uploadBtn.x = 269;
			uploadBtn.y = 378;
			uploadBtn.addEventListener(MouseEvent.CLICK, uploadBtnClickHandler);
			parent.addChild(uploadBtn);
			
			saveImageBtn = Tool.createSaveBtn();
			saveImageBtn.x = 430;
			saveImageBtn.y = 378
			saveImageBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void{
				if(retImage == null) return;
				
				controlMaskDiv.visible = true;
				var variables:Dictionary = new Dictionary();
				variables["image.jpg"] = origImage.bitmapData;
				variables["image_big.jpg"] = retImage.bitmapData;
				variables["image_mid.jpg"] = retMidImage.bitmapData;
				variables["image_small.jpg"] = retSmallImage.bitmapData;				
				variables["uid"] = uid;
				
				Tool.uploadImage(uploadUrl, 
					variables, 
					function(result:String):void{
						trace("result:"+result);
						if(ExternalInterface.available)
						{
							try
							{
								ExternalInterface.call(cbSuccess, result);		
							} 
							catch(error:Error) 
							{
								
							}
						}
						
						controlMaskDiv.visible = false;
					},
					function():void{
						if(ExternalInterface.available)
						{
							try
							{
								ExternalInterface.call(cbError, "上传图片失败!");		
							} 
							catch(error:Error) 
							{
								
							}
						}						
					});
			});
			parent.addChild(saveImageBtn);

			// 操作遮罩
			createControlMask();
			
		}
		
		// 操作按钮遮罩层
		private function createControlMask():void
		{
			controlMaskDiv = Tool.createDiv(200, 200, handleSize.width, 50, 1, Colors["divBorderColor"], Colors["divBgColor"],1);
			var tip:TextField = new TextField();
			tip.text = "正在上传中...";
			tip.x = (handleSize.width - tip.width)/2;
			tip.y = 20;
			controlMaskDiv.addChild(tip);
			controlMaskDiv.visible = false;
			
			parent.addChild(controlMaskDiv);
		}
		
		// 上传按钮点击事件
		private function uploadBtnClickHandler(e:MouseEvent):void
		{			
			var filter:FileFilter = new FileFilter("Images: (*.jpeg, *.jpg, *.gif, *.png)", "*.jpeg; *.jpg; *.gif; *.png");
			fileRef = new FileReference();
			fileRef.addEventListener(Event.SELECT, selectHandler);
			fileRef.browse([filter]);
		}
		// 文件选择事件
		private function selectHandler(e:Event):void
		{
			fileRef.removeEventListener(Event.SELECT, selectHandler);
			fileRef.addEventListener(Event.COMPLETE, loadCompleteHandler);
			if(fileRef.size > 1024 * 1024)
			{
				
				twinkleInfo();
			}
			else{
				fileRef.load();	
			}
		}
		
		private var timeoutID:uint;
		private function twinkleInfo():void
		{
			var intervalID:uint = setInterval(function():void{
				infoTip.visible = !infoTip.visible;
			},500);
			
			if(timeoutID)
			{
				clearTimeout(timeoutID);
			}	
			timeoutID=setTimeout(function():void{
				if(intervalID)
				{
					clearInterval(intervalID);
					infoTip.visible = true;
				}
			},5*1000);
		}	
		// 文件加载成功事件
		private function loadCompleteHandler(e:Event):void
		{
			fileRef.removeEventListener(Event.COMPLETE, loadCompleteHandler);
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadBytesHandler);
			loader.loadBytes(fileRef.data, new LoaderContext(false, ApplicationDomain.currentDomain));
		}
		
		private function loadBytesHandler(e:Event):void
		{			
			var loaderInfo:LoaderInfo = e.target as LoaderInfo;
			loaderInfo.removeEventListener(Event.COMPLETE, loadBytesHandler);
			
			try{
				showHandleImage(loaderInfo.content);
			}
			catch(err:Error){
				trace(err.message);
			}
		}
		
		// 显示图片到操作区域
		private function showHandleImage(data:DisplayObject):void
		{			
			// 保存原图
			origImage = data as Bitmap;
			
			// 把得到的缩略图进行渲染
			handleZoomScale = Tool.getZoomScale(handleSize.width, handleSize.height, origImage.width, origImage.height);
			var bit:Bitmap = new Bitmap(Tool.zoomImage(origImage.bitmapData, handleZoomScale, handleZoomScale));
			
			handleImageDiv = new Sprite();
			handleImageDiv.addChild(bit);
			
			var width:Number = bit.width;
			var height:Number = bit.height;
			
			if (width < handleSize.width)
			{
				handleImageDiv.x = (handleSize.width - width) / 2;
			}
			
			if (height < handleSize.height)
			{
				handleImageDiv.y = (handleSize.height - height) / 2;
			}
			
			// 清空画布
			handleDiv.removeChildren();
			// 将原始操作图片添加到画布
			handleDiv.addChild(handleImageDiv);
			// 创建遮罩层
			createMask();
		}
		
		private function createMask():void
		{	
			// 添加遮罩曾
			maskDiv = new MaskDiv( handleImageDiv.width,handleImageDiv.height );
			maskDiv.x = handleImageDiv.x;
			maskDiv.y = handleImageDiv.y;
		
			maskDivSize.width = maskDiv.width;
			maskDivSize.height = maskDiv.height;
			
			maskDiv.blendMode = BlendMode.LAYER;
			handleDiv.addChild(maskDiv);
			
			// 创建剪切层
			createCut();
		}
		
		private function createCut():void
		{							
			cutDivSize.width = cutDivInitSize.width;
			cutDivSize.height = cutDivInitSize.height;
			
			// 如果宽度高于遮罩层宽
			if (cutDivSize.width > maskDivSize.width){
				cutDivSize.width = maskDivSize.width;
				cutDivSize.height = cutDivSize.width * (cutDivInitSize.height/cutDivInitSize.width);
			}
			
			// 如果高度高于遮罩层高
			if (cutDivSize.height > maskDivSize.height){
				cutDivSize.height = maskDivSize.height;
				cutDivSize.width = cutDivSize.height * (cutDivInitSize.width/cutDivInitSize.height);
			}
			
			cutDivPos.x = (maskDiv.width - cutDivSize.width) / 2;
			cutDivPos.y = (maskDiv.height - cutDivSize.height) /2;
					
			cutDiv = new CutDiv(0xFFFFFF,0,1,0xFF0000,1);
			cutDiv.x = cutDivPos.x;
			cutDiv.y = cutDivPos.y;
			cutDiv.setSize( cutDivSize.width, cutDivSize.height);
			
			maskDiv.cutDiv = cutDiv;
			maskDiv.addChild(cutDiv);
			
			// 初始化显示			
			setRetImage();
			
			var mouseX:Number = 0;
			var mouseY:Number = 0;						
			
			var cutOverHandler:Function = function(e:MouseEvent):void{
				Mouse.cursor = MouseCursor.HAND;
			};
			var cutOutHandler:Function = function(e:MouseEvent):void{
				Mouse.cursor = MouseCursor.AUTO;
				cutDiv.removeEventListener(MouseEvent.MOUSE_MOVE, cutMoveHandler);
			};			
			var cutDownHandler:Function = function(e:MouseEvent):void{
				mouseX = e.stageX;
				mouseY = e.stageY;
				
				parent.addEventListener(MouseEvent.MOUSE_MOVE, cutMoveHandler);
			};
			var cutUpHandler:Function = function(e:MouseEvent):void{
				parent.removeEventListener(MouseEvent.MOUSE_MOVE, cutMoveHandler);
			};
			var cutMoveHandler:Function = function(e:MouseEvent):void{
				var mx:Number = e.stageX;
				var my:Number = e.stageY;
				
				var x:Number = cutDiv.x + (mx - mouseX);
				var y:Number = cutDiv.y + (my - mouseY);
				
				setCutPosition(Math.max(0, Math.min(x, maskDivSize.width - Math.floor(cutDivSize.width) + 1)), Math.max(0, Math.min(y, maskDivSize.height - Math.floor(cutDivSize.height) + 1)));
				
				mouseX = mx;
				mouseY = my;				
				
				setRetImage();
			};
			
			cutDiv.addEventListener(MouseEvent.MOUSE_OVER, cutOverHandler);			
			cutDiv.addEventListener(MouseEvent.MOUSE_OUT, cutOutHandler);
			cutDiv.addEventListener(MouseEvent.MOUSE_DOWN, cutDownHandler);
			parent.addEventListener(MouseEvent.MOUSE_UP, cutUpHandler);
			
			// 创建剪切层缩放
			createCutZoom();
		}
		
		private function createCutZoom():void
		{
			cutZoomDiv = Tool.createDiv(0, 0, cutZoomDivSize.width, cutZoomDivSize.height, 1, 0xFF0000, Colors["bgColor"], 0);
			setCutPosition(cutDiv.x, cutDiv.y);
			maskDiv.addChild(cutZoomDiv);
			
			var mouseX:Number = 0;
			var mouseY:Number = 0;
			
			var onMouseDown:Function = function(e:MouseEvent):void
			{
				mouseX = e.stageX;
				mouseY = e.stageY;
				parent.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			};
			var onMouseUp:Function = function(e:MouseEvent):void
			{
				parent.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			};
			var onMouseMove:Function = function(e:MouseEvent):void
			{
				var mx:Number = e.stageX;
				var my:Number = e.stageY;
				
				// x轴位移
				var walkX:Number = mx - mouseX;
				// y轴位移
				var walkY:Number = my - mouseY;
						
				// 如果x轴移动的多
				if (Math.abs(walkX) > Math.abs(walkY))
				{
					setCutSize(cutDiv.width + walkX, cutDiv.height + walkX * retDivSize.height/retDivSize.width);
				}
				else	
				{
					setCutSize(cutDiv.width + walkY * retDivSize.width/retDivSize.height, cutDiv.height + walkY);
				}
				
				mouseX = mx;
				mouseY = my;
				
				setCutPosition(cutDiv.x, cutDiv.y);
				setRetImage();
			};
			
			cutZoomDiv.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void{
				Mouse.cursor = MouseCursor.BUTTON;
			});
			cutZoomDiv.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):void{
				Mouse.cursor = MouseCursor.AUTO;
			});
			cutZoomDiv.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			parent.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		}
		
		// 设置剪切层大小
		private function setCutSize(width:Number, height:Number):void
		{
			// 尺寸检查
			var width:Number = Math.min(handleImageDiv.width - cutDiv.x, Math.max(cutDivMinSize.width, width));
			var height:Number = Math.min(handleImageDiv.height - cutDiv.y, Math.max(cutDivMinSize.height, height));
			
			// 如果宽度已经最大，则高度按照宽度算
			if (width + cutDiv.x == handleImageDiv.width)
			{
				height = width * cutDivInitSize.height/cutDivInitSize.width;
			}
			// 如果高度已经最大，则宽度按照高度算
			if (height + cutDiv.y == handleImageDiv.height)
			{
				width = height * cutDivInitSize.width/cutDivInitSize.height;
			}
			
			cutDiv.width = cutDivSize.width = width;
			cutDiv.height = cutDivSize.height = height;
			
		}
		
		// 设置剪切层位置
		private function setCutPosition(x:Number, y:Number):void
		{
			cutDiv.x = x;
			cutDiv.y = y;
			
			if(cutZoomDiv)
			{
				cutZoomDiv.x = cutDiv.x + cutDiv.width  - cutZoomDiv.width/2 -1;
				cutZoomDiv.y = cutDiv.y + cutDiv.height - cutZoomDiv.height/2 -1;
			}
			
			maskDiv.cutDiv = cutDiv;
		}
		
		private function setRetImage():void
		{			
			var bitData:BitmapData = origImage.bitmapData;
			var rect:Rectangle = new Rectangle(cutDiv.x, cutDiv.y, cutDivSize.width, cutDivSize.height);
			
			// 根据缩放比率得到rect在原图上的位置
			var origRect:Rectangle = new Rectangle(rect.left/handleZoomScale, rect.top/handleZoomScale, rect.width/handleZoomScale, rect.height/handleZoomScale);
			
			try
			{
				if(retImage && retDiv.contains(retImage))
				{
					retDiv.removeChild(retImage);
				}
				
				if(retMidImage && retMidDiv.contains(retMidImage))
				{
					retMidDiv.removeChild(retMidImage);
				}
				
				if(retSmallImage && retSmallDiv.contains(retSmallImage))
				{
					retSmallDiv.removeChild(retSmallImage);	
				}
				
				var retBitData:BitmapData = Tool.cropImage(bitData, origRect);
				retImage = new Bitmap(Tool.zoomImage(retBitData, retDivSize.width/retBitData.width, retDivSize.height/retBitData.height));
				
				retMidImage = new Bitmap(Tool.zoomImage(retBitData,retMidDivSize.width/retBitData.width,retMidDivSize.height/retBitData.height));
				
				retSmallImage = new Bitmap(Tool.zoomImage(retBitData,retSmallDivSize.width/retBitData.width,retSmallDivSize.height/retBitData.height));
									
				retDiv.addChildAt(retImage,0);
				retMidDiv.addChildAt(retMidImage,0);
				retSmallDiv.addChildAt(retSmallImage,0);
			}
			catch(err:Error)
			{
				trace(err.message);
			}
			
		}
	}
}

class Size
{
	public var width:Number = 0;
	public var height:Number = 0;
	
	public function Size(w:Number = 0, h:Number = 0)
	{
		width = w;
		height = h;
	}
}