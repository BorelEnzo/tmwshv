package com.borelenzo.tmwshv.engine {
	
	/**
	 * The class KeyPressed.
	 * Represents a state of a key (jumping, direction or suicide to restart)
	 * @author Enzo Borel
	 */
	public class KeyPressed {
		
		//states of keys
		private var _left:Boolean; 		//left arrow 
		private var _right:Boolean;		//right arrow
		private var _jump:Boolean;		//up arrow
		private var _suicide:Boolean;	//S key
		
		public function KeyPressed() {}
		
		/**
		 * All getters and setters
		 */
		
		public function get left():Boolean {
			return _left;
		}
		
		public function set left(value:Boolean):void {
			_left = value;
		}
		
		public function get right():Boolean {
			return _right;
		}
		
		public function set right(value:Boolean):void {
			_right = value;
		}
		
		public function get jump():Boolean {
			return _jump;
		}
		
		public function set jump(value:Boolean):void {
			_jump = value;
		}
		
		public function get suicide():Boolean {
			return _suicide;
		}
		
		public function set suicide(value:Boolean):void {
			_suicide = value;
		}
		
	
	}

}