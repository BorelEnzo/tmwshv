package com.borelenzo.tmwshv {
	
	/**
	 * The interface GameListener.
	 * Used to stop the game from the inside (as the hero wins)
	 * @author Enzo
	 */
	
	public interface GameListener {
		
		/**
		 * Called as the key Enter is pressed. Implemented by the Main class, called from Game
		 */
		function onGameEnd():void;		
		
	}

}