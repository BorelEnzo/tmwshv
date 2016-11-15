package com.borelenzo.tmwshv.actors {
	import com.borelenzo.tmwshv.Constants;
	import com.borelenzo.tmwshv.Main;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * The Class Shuriken.
	 * The shuriken is a moveable actor, which can move vertically or horizontally, but can't move in both directions
	 * 
	 * Explanations for 'update' and 'onAddedToStage' can be found in class Hero, because the principle is the same
	 * @author Enzo Borel
	 */
	public class Shuriken extends BaseActor{
		
		private var _vertical:Boolean; //flag which indicates the direction
		private const animVector:Vector.<BitmapData> = new Vector.<BitmapData>(9, true); //vector which contains animation's frames 
		
		/**
		 * The constructor of Shuriken
		 * Actually this version doesn't allow to create different versions of Shuriken, because we need only 2 in this game, but
		 * it's easy to improve this class in order to have different types of Shuriken
		 * @param	vertical the direction of the Shuriken.
		 */
		public function Shuriken(vertical:Boolean) {
			super(-Constants.UNIT, -Constants.UNIT, 0, 0, Main.getShurikenBitmapData());
			reset();
			_vertical = vertical;
			//set the appropriate velocity
			if (vertical){
				_speedY = 15;
			}
			else{
				_speedX = 7;
				_goingToRight = false;
			}
		}
		
		/**
		 * Resets the shuriken's position and animation
		 */
		override public function reset():void{
			super.reset();
			resetAnimation(9);
		}
		
		/**
		 * Updates the position on axis according to the direction
		 * @param	cameraX 
		 */
		override public function update(cameraX:int = 0):void{
			if (!_vertical){
				x -= _speedX;
				if (x + width < cameraX){
					reset();
				}
			}
			else{
				y += _speedY;
				if (y > Constants.APP_HEIGHT){
					reset();
				}
			}
			if (_frameTimer <= 0){
				_frameTimer = 0;
				_frameNumber = _frameNumber + 1 >= _frameMax ? 0 : _frameNumber + 1;
			}
			else{
				_frameTimer--;
			}
			bitmapData = animVector[_frameMax - 1 - _frameNumber];
		}
		
		/**
		 * Called when the actor is added to stage
		 * @param	event
		 */
		override public function onAddedToStage(event:Event):void{
			super.onAddedToStage(event);
			var rect:Rectangle = new Rectangle(0, 0, Constants.UNIT, Constants.UNIT);
			const canvas:BitmapData = new BitmapData(rect.width, rect.height, true, 0xFFFFFF);		
			var point:Point = new Point();
			for (var i:int = 0; i < _frameMax; i++){
				rect.x = i * rect.width;
				canvas.copyPixels(bitmapData, rect, point);
				animVector[i] = canvas.clone();
			}
			canvas.dispose();
			bitmapData = animVector[0];
			width = height = bitmapData.width;
			point = null;
			rect = null;
		}
	}

}