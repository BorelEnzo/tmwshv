package com.borelenzo.tmwshv.actors {
	import com.borelenzo.tmwshv.Constants;
	import com.borelenzo.tmwshv.Main;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * The Class Hero.
	 * Manages the main character of the Game.
	 * @author Enzo Borel
	 */
	
	public class Hero extends BaseActor {
		
		private var _jumping:Boolean 		= false;	//flag used to know if it's the first or the second jump
		private var _wasGrounded:Boolean 	= false;	//flag used to know if the hero was grounded before the checking of collisions
		private var _grounded:Boolean		= false;	//flag used to know the actual state of the actor
		private var _wasOnSlope:int			= 0;		//flag used to know if the hero was on a slope previously
		private var _state:int				= Constants.CHARACTER_IDLE; //the state is one of the constant values (IDLE/WALK/JUMP_1/JUMP_2/DEAD/VICTORY)
		private var _recoveryTimer:int		= 0;		//as the hero gets a bonus (blue boxes) he becomes invincible during a few seconds and flashes
		private var _deathTimer:int			= 0;		//as the hero dies, wait a few seconds before restart
		private var _victoryTimer:int		= 0;		//as the hero winds, wait a few seconds before quit
		private var _exSpeedX:Number		= 0;		//used to store velocity before checking of collisions
		private var _exSpeedY:Number		= 0;		//the same here
		private var _exX:int				= 0;		//the same here for the position
		private var _exY:int				= 0;		//the same
		
		private var animVector:Vector.<Vector.<BitmapData>> = new Vector.<Vector.<BitmapData>>(6, true);
		/**
		 * The vector above is used as follows:
		 * v[0] = [F1][F2]...[Fn][rF1][rF2][rFn] -> vector containing pictures for the animation associated with the state 1
		 * v[1] = [F1][F2]...[Fn][rF1][rF2][rFn] -> vector containing pictures for the animation associated with the state 2
		 * ...
		 * v[6] = [F1][F2]...[Fn][rF1][rF2][rFn] -> vector containing pictures for the animation associated with the state 6
		 * 
		 * There is a vector associated with each possible state (6).
		 * Fx means the first picture of the animation stored in the vector, and rFx means the flipped version of the picture Fx.
		 * Left side of the vector: used when the hero is looking to right
		 * Right side : the reverse version of each picture, used when the hero is looking to left
		 * 
		 * In the main picture, subpictures are organised as follows:
		 * I1 I2 I3 I4				-> Idle state 1 rank 0
		 * W1 W2 W3 W4 W5 W6 W7 W8	-> Walk state 2 rank 1
		 * J1 J2 J3 J4				-> Jump 1 state 3 rank 2
		 * J1 J2 J3 J4				-> Jump 2 state 4 rank 3
		 * D1						-> Dead state 5 rank 4
		 * Wi1 Wi2 Wi3 Wi4 Wi5 Wi6	-> Win state 6 rank rank 5
		 */
		
		/**
		 * The constructor of the Hero
		 */
		public function Hero() {
			super( -Constants.UNIT, -40, 0, 0, Main.getHeroBitmapData()); //we want to hide the hero out of screen bounds whil he is not added to the stage
			animVector[Constants.CHARACTER_IDLE] = new Vector.<BitmapData>(Constants.IDLE_FRAMES * 2, true);//at the first place of the main vector, we store the animation
			//associated with the state IDLE, which is animated with 2 frames. In order to have the reverse one, we calculate the size by multiplying by 2
			animVector[Constants.CHARACTER_WALK] = new Vector.<BitmapData>(Constants.WALK_FRAMES* 2, true);
			animVector[Constants.CHARACTER_JUMP_1] = new Vector.<BitmapData>(Constants.JUMP_1_FRAMES * 2, true);
			animVector[Constants.CHARACTER_JUMP_2] = new Vector.<BitmapData>(Constants.JUMP_2_FRAMES * 2, true);
			animVector[Constants.CHARACTER_DEAD] = new Vector.<BitmapData>(Constants.DEAD_FRAMES * 2, true);
			animVector[Constants.CHARACTER_VICTORY] = new Vector.<BitmapData>(Constants.VICTORY_FRAMES * 2, true);
			reset();
		}
		
		/**
		 * Getters and setters
		 */
		
		public function get jumping():Boolean {
			return _jumping;
		}
		
		public function get state():int {
			return _state;
		}
		
		public function get victoryTimer():int {
			return _victoryTimer;
		}
		
		public function get deathTimer():int {
			return _deathTimer;
		}
		
		public function get wasGrounded():Boolean {
			return _wasGrounded;
		}
		
		public function get exX():int {
			return _exX;
		}
		
		public function get exY():int {
			return _exY;
		}
		
		public function get exSpeedX():Number {
			return _exSpeedX;
		}
		
		public function get exSpeedY():Number {
			return _exSpeedY;
		}
		
		public function get wasOnSlope():int {
			return _wasOnSlope;
		}
		
		public function set wasOnSlope(value:int):void {
			_wasOnSlope = value;
		}
		
		public function get recoveryTimer():int {
			return _recoveryTimer;
		}
		
		public function set recoveryTimer(value:int):void {
			_recoveryTimer = value;
		}
		
		public function set deathTimer(value:int):void {
			_deathTimer = value;
		}
		
		public function set victoryTimer(value:int):void {
			_victoryTimer = value;
		}
		
		public function set jumping(value:Boolean):void {
			_jumping = value;
		}
		
		public function set state(value:int):void {
			_state = value;
		}
		
		public function set exSpeedX(value:Number):void {
			_exSpeedX = value;
		}
		
		public function set exSpeedY(value:Number):void {
			_exSpeedY = value;
		}
		
		public function set wasGrounded(value:Boolean):void {
			_wasGrounded = value;
		}
		
		public function set exX(value:int):void {
			_exX = value;
		}
		
		public function set exY(value:int):void {
			_exY = value;
		}
		
		
		public function get grounded():Boolean {
			return _grounded;
		}
		
		public function set grounded(value:Boolean):void {
			_grounded = value;
		}

		/**
		 * Updates the hero's animation
		 * @param	cameraX 
		 */
		override public function update(cameraX:int = 0):void {
			//Calculate the frame number
			if (_frameTimer <= 0) {
				_frameTimer = Constants.ANIM_TIME;
				_frameNumber = _frameNumber + 1 >= _frameMax ? 0 : _frameNumber + 1;
			}
			else {
				_frameTimer--;
			}
			//if the recovery timer is greater than 0(is the hero is invincible), draw only one time in two
			if (_recoveryTimer > 0){
				_recoveryTimer--;
				if (_frameNumber % 2 == 0){
					visible = true;
					bitmapData = animVector[_state][_goingToRight ? _frameNumber : _frameMax + _frameNumber];
					//the previous logic gets the right vector (index _state) and the right picture (is the hero is looking to right, use the
					//first pictures of the vector, else use the last pictures, as it was explained previously
				}
				else{
					visible = false;
				}
			}
			else{
				bitmapData = animVector[_state][_goingToRight ? _frameNumber : _frameMax + _frameNumber];
			}
		}
		
		/**
		 * Called as the Hero is added in a Stage.
		 * Prepares the animation
		 * @param	event
		 */
		override public function onAddedToStage(event:Event):void {
			super.onAddedToStage(event);	
			
			//x and y of the rectangle will change because this rectangle is
			//used to take only a part of the main bitmap. Dimensions don't change because it matches with hero's dimensions
			const rect:Rectangle = new Rectangle(0, 0, Constants.UNIT, 40);
			
			//canvas is the buffer where pixels are placed before putting them in the vector
			const canvas:BitmapData = new BitmapData(rect.width, rect.height, true, 0xFFFFFF);
			
			//the point ise used to indicate where copy pixels in the bitmapdata object
			const point:Point = new Point();
			
			//the matrix is used to get the reverse version of each picture
			const matrix:Matrix = new Matrix( -1, 0, 0, 1, rect.width, 0);
			
			var max:int = 0; //the number of frame in each animation, which is the half of the vector's length
			
			//put bitmapdatas in the vector (normal and flipped one).
			for (var state:int = 0; state < 6; state++){
				rect.y = rect.height * state;//places the focus rectangle at the right place. 
				max = animVector[state].length / 2;
				for (var pic:int = 0; pic < max; pic++){
					rect.x = pic * rect.width;
					canvas.copyPixels(bitmapData, rect, point);
					animVector[state][pic] = canvas.clone();//clone the data in the vector
					animVector[state][max + pic] = new BitmapData(rect.width, rect.height, true, 0xFFFFFF);//add a new bitmapdata
					animVector[state][max + pic].draw(animVector[state][pic], matrix, null, null, null, true);//and draw the reverse version in this bitmapdata
				}	
			}
			canvas.dispose();
			bitmapData = animVector[Constants.CHARACTER_IDLE][0]; //set the first frame to draw
			//Set dimensions
			width = bitmapData.width;
			height = bitmapData.height;
		}
	
		/**
		 * Resets the character. Replaces it a the right place and sets  an idle state
		 */
		override public function reset():void{
			super.reset();
			_deathTimer = _victoryTimer = _recoveryTimer = 0;
			_state = Constants.CHARACTER_IDLE;
			resetAnimation(Constants.IDLE_FRAMES);
			_jumping = false;
			_speedX = _speedY = 0.0;
			_grounded = false;
			_goingToRight = true;
		}
		
		/**
		 * Makes the hero dying, if he's not already dead
		 */
		public function die():void{
			if( state != Constants.CHARACTER_DEAD){
				_state = Constants.CHARACTER_DEAD;
				resetAnimation(Constants.DEAD_FRAMES);
				_deathTimer = 90;	
			}
		}
		
		/**
		 * Makes the hero victorious, if he's not already
		 */
		public function win():void{
			if(_state != Constants.CHARACTER_VICTORY){
				_state = Constants.CHARACTER_VICTORY;
				_originX = _originY = 0;
				_recoveryTimer = 0;
				_victoryTimer = 180;
				recoveryTimer = 0;
				_deathTimer = 0;
				resetAnimation(Constants.VICTORY_FRAMES);
			}
		}
		
		/**
		 * Sets the hero in an idle state, if he's not
		 */
		public function rest():void{
			if (_state != Constants.CHARACTER_IDLE){
				_state = Constants.CHARACTER_IDLE;
				resetAnimation(Constants.IDLE_FRAMES);
			}
		}
		
		/**
		 * Makes the hero walking
		 * @param toRight true if hero goes right
		 */
		public function walk(toRight:Boolean):void{
			_goingToRight = toRight;
			_speedX = _goingToRight ? 4 : -4;
			if (_state != Constants.CHARACTER_WALK && _grounded){
				_state = Constants.CHARACTER_WALK;
				resetAnimation(Constants.WALK_FRAMES);
			}
		}
		
		/**
		 * Makes the hero jumping.
		 * Applies a impulse by incrementing the value speedY
		 */
		public function jump():void{
			if (_grounded){
				//first jump
				_speedY = -10;
				_grounded = false;
				_jumping = true;
			}
			else if (_jumping){
				//double jump
				_speedY = -10;
				_jumping = false;
			}
		}
		
	}
	
	
}