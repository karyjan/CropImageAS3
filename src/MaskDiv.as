package
{
	import flash.display.Sprite;
	import flash.geom.Point;
	
	public class MaskDiv extends Sprite
	{
		// 剪切层
		private var _cutDiv:CutDiv;
		
		private var leftTop:Point = new Point() ;
		private var leftBottom:Point = new Point();
		private var rightTop:Point = new Point();
		private var rightBottom:Point = new Point();
		
		private var _width:Number;
		private var _height:Number;
		
		public function MaskDiv(width:Number,height:Number)
		{
			super();
			_width = width;
			_height = height;
			graphics.beginFill(0xFFFFFF,0.5);
			graphics.drawRect(0,0,_width,_height);
			graphics.endFill();
		}
		
		
		
		public function draw():void
		{
			leftTop.x = _cutDiv.x;
			leftTop.y = _cutDiv.y;
			
			leftBottom.x = _cutDiv.x;
			leftBottom.y = _cutDiv.height + _cutDiv.y;
			
			rightTop.x = _cutDiv.x + _cutDiv.width;
			rightTop.y = _cutDiv.y;
			
			rightBottom.x = _cutDiv.x + _cutDiv.width;
			rightBottom.y = _cutDiv.y + _cutDiv.height;
			
			graphics.clear();
			graphics.beginFill(0xFFFFFF,0.5);
			
			//draw lefttop rect
			graphics.drawRect(0,0,leftTop.x,leftTop.y);
			//draw top rect
			graphics.drawRect(leftTop.x,0,_cutDiv.width,leftTop.y);
			//draw righttop rect
			graphics.drawRect(rightTop.x,0,_width-rightTop.x,rightTop.y);
			//draw left rect
			graphics.drawRect(0,leftTop.y,leftTop.x,_cutDiv.height);
			//draw right rect
			graphics.drawRect(rightTop.x,rightTop.y,_width-rightTop.x,_cutDiv.height);
			//draw leftbottom rect
			graphics.drawRect(0,leftBottom.y,leftBottom.x,_height-leftBottom.y);
			//draw bottom rect;
			graphics.drawRect(leftBottom.x,leftBottom.y,_cutDiv.width,_height-leftBottom.y);
			//draw rightbottom rect;
			graphics.drawRect(rightBottom.x,rightBottom.y,_width-rightBottom.x,_height-rightBottom.y);
			
			graphics.endFill();
			
		}

		public function set cutDiv(value:CutDiv):void
		{
			_cutDiv = value;
			draw();
		}

	}
	
}