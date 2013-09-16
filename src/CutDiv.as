package
{
	import flash.display.BlendMode;
	import flash.display.Sprite;
	
	public class CutDiv extends Sprite
	{
		private var strokeThickness:Number;
		private var strokeColor:uint;
		private var strokeAlpha:Number;
		
		private var backgroundColor:uint;
		private var backgroundAlpha:Number;
		
		private var _width:Number;
		private var _height:Number;
		public function CutDiv(bgColor:uint,bgAlpha:Number,lineWidth:Number,lineColor:uint,lineAlpha:Number)
		{
			super();
			backgroundColor = bgColor;
			backgroundAlpha = bgAlpha;
			
			strokeThickness = lineWidth;
			strokeColor     = lineColor;
			strokeAlpha 	= lineAlpha;
			
		//	this.blendMode = BlendMode.ALPHA;
		}
		
		public function setSize(width:Number,height:Number):void
		{
			_width = width;
			_height = height;				
			draw();
		}	
		
		private function draw():void
		{
			graphics.clear();			
			graphics.beginFill(backgroundColor,backgroundAlpha);
			graphics.drawRect(0,0,_width,_height);
			graphics.endFill();
			
			if (strokeThickness > 0){
				var x_1:Number = strokeThickness/2;
				var x_2:Number = width - strokeThickness/2;
				var y_1:Number = strokeThickness/2;
				var y_2:Number = height - strokeThickness/2;
				
				graphics.lineStyle(strokeThickness, strokeColor, strokeAlpha);
				graphics.moveTo(x_1, y_1);
				
				graphics.lineTo(x_2, y_1);
				graphics.lineTo(x_2, y_2);
				graphics.lineTo(x_1, y_2);
				graphics.lineTo(x_1, y_1);
			}			
		}
	}
}