package com.borelenzo.tmwshv {
	
	/**
	 * The interface KeyListener. Used to start or stop the game from the Main class
	 * @author Enzo Borel
	 */
	public interface KeyListener {
		
		/**
		 * Called as the key Enter is pressed. Implemented by the Main class, called from InputManager
		 */
		function onEnterPressed():void;
		
		/**
		 * Called as the key Esc is pressed. Implemented by the Main class, called from InputManager
		 */
		function onEscapePressed():void;
		
	}

}