package com.borelenzo.tmwshv.engine {
	import com.borelenzo.tmwshv.KeyListener;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	
	/**
	 * The Class InputManager
	 * Manages all keyboard inputs.
	 * @author Enzo Borel
	 */
	public class InputManager {
		
		private var _keyPressed:KeyPressed; //used to know the state of each key
		private var _wasJumpReleased:Boolean; //flag used in order to indicate if the key was released or not. We want to force the user to release
		//the key to do a double jump
		private var _keyListener:KeyListener; //interface to communicate with the Main class
		
		/**
		 * The constructor.
		 * Sets all values to "false", because the character is idle at the beginning.
		 */
		public function InputManager(keyListener:KeyListener) {
			this._keyListener = keyListener;
			_keyPressed = new KeyPressed();
			_keyPressed.left = _keyPressed.right = _keyPressed.jump = _keyPressed.suicide = false;
			_wasJumpReleased = true;
		}
		
		/**
		 * @return the key pressed in order to get its state
		 */
		public function get keyPressed():KeyPressed {
			return _keyPressed;
		}
		
		/**
		 * Sets a key enable or disable
		 * @param keyCode the key to manage
		 * @param enable the state (pressed or not)
		 * @param artificial. As the hero does a double jump, force the state of the key UP
		 */
		public function activateKey(keyCode:int, enable:Boolean, artificial:Boolean = false):void{
			switch(keyCode){
				case Keyboard.LEFT:
					_keyPressed.left = enable;
					break;
				case Keyboard.RIGHT:
					_keyPressed.right = enable;
					break;
				case Keyboard.UP:
					if (enable){
						_keyPressed.jump = _wasJumpReleased;
						if (_wasJumpReleased){
							_wasJumpReleased = false;
						}
					}
					else{
						_keyPressed.jump = false;
						_wasJumpReleased = !artificial;
					}
					break;
				case Keyboard.ENTER:
					_keyListener.onEnterPressed();
					break;
				case Keyboard.S:
					_keyPressed.suicide = enable;
					break;
				case Keyboard.ESCAPE:
					_keyListener.onEscapePressed();
					break;
			}
		}
		
		/**
		 * Manages the input as a key is pressed
		 * @param	event gives us many information about the key
		 */
		public function keyDown(event:KeyboardEvent):void{
			activateKey(event.keyCode, true); 
			event.stopPropagation();
		}
		
		/**
		 * Manages the input as a key is released
		 * @param	event gives un many informations about the key
		 */
		public function keyUp(event:KeyboardEvent):void{
			activateKey(event.keyCode, false);
			event.stopPropagation();
		}
	}
	
	

}