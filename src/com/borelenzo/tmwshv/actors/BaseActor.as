package com.borelenzo.tmwshv.actors {

	import com.borelenzo.tmwshv.Constants;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	
	/**
	 * The Class BaseActor.
	 * Represents a basic actor, with a position, a velocity a dimension and a texture
	 * @author Enzo Borel
	 */
	public class BaseActor extends Bitmap{
		
		protected var _frameNumber:int 	= 0; //the frame index of the animation
		protected var _frameTimer:int	= 0; //the animation timer
		protected var _frameMax:int		= 0; //the last frame of the animation
		
		protected var _originX:int			= 0; 		//the position on X axis where the actor was placed at the beginning
		protected var _originY:int			= 0; 		//the position on Y axis where the actor was placed at the beginning
		protected var _speedX:Number		= 0.0;		//the velocity on X axis
		protected var _speedY:Number		= 0.0;		//the velocity on Y axis
		protected var _goingToRight:Boolean	= true;		//the direction. We used this flag in addition speed, because sometimes we need to know
														//in which direction the actor is looking
		
		
		/**
		 * The constructor of the class BaseActor
		 * @param	x position on X axis
		 * @param	y position on Y axis
		 * @param	speedY velocity on X axis
		 * @param	speedX velocity on Y axis
		 * @param	bitmapData
		 */
		public function BaseActor(x:int, y:int, speedY:Number, speedX:Number, bitmapData:BitmapData){
			super(bitmapData);
			this.x = x;
			this.y = y;
			_originX = x;
			_originY = y;
			_speedX = speedX;
			_speedY = speedY;
		}

		/**
		 * Updates the character if is in screen bounds
		 * @param	cameraX the position of the camera, which has a focus only on a part of the stage
		 */
		public function update(cameraX:int = 0):void{
			if (_speedY != 0){
				y += _speedY;
				if (y > Constants.APP_HEIGHT){
					reset();
				}
			}
			if (_speedX != 0){
				x += _speedX 
				if (x + width < cameraX || x > cameraX + Constants.APP_WIDTH){
					reset();
				}
			}
		}
		
		/**
		 * Checks if two hitboxes overlap
		 * @param	otherActor the second actor
		 * @return 	true if actors overlap
		 */
		public function overlaps(otherActor:BaseActor):Boolean{
			return x < otherActor.x + otherActor.width &&
			x + width > otherActor.x &&
			y < otherActor.y + otherActor.height &&
			y + height > otherActor.y;
		}
		
		/**
		 * Resets the animation and sets a new maximum.
		 * @param	frameMax the new maximum
		 */
		public function resetAnimation(frameMax:uint):void{
			this._frameMax = frameMax;
			_frameNumber = 0;
			_frameTimer = 0;
		}
		
		/**
		 * @return true if the actor's position doesn't match with its original position
		 */
		public function hasMoved():Boolean{
			return x != _originX ||  y != _originY;
		}
		
		/**
		 * Replaces the actors at its original position.
		 */
		public function reset():void{
			x = _originX;
			y = _originY;
		}
		
		/**
		 * Removes the listener attached to the the actors
		 * @param	event
		 */
		public function onAddedToStage(event:Event):void{
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}
			
		
		/**
		 * Getters and setters
		 */
		public function get originX():int {
			return _originX;
		}
		
		
		public function get originY():int {
			return _originY;
		}
		
		public function set originY(value:int):void {
			_originY = value;
		}
		
		public function get speedX():Number {
			return _speedX;
		}
		
		public function set speedX(value:Number):void {
			_speedX = value;
		}
		
		public function get speedY():Number {
			return _speedY;
		}
		
		public function set speedY(value:Number):void {
			_speedY = value;
		}
		
		public function get goingToRight():Boolean {
			return _goingToRight;
		}
		
		public function set goingToRight(value:Boolean):void {
			_goingToRight = value;
		}
		
		
		public function set originX(value:int):void {
			_originX = value;
		}
	}

}