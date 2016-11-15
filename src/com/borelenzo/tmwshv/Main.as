package com.borelenzo.tmwshv{
	import com.borelenzo.tmwshv.engine.Game;
	import com.borelenzo.tmwshv.engine.InputManager;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	
	/**
	 * The Class Main, maisn entry point of the program
	 * At the beginning, load all graphical resources and as it's finished, display the screen.
	 * In order to start the game, wait for an Event from InputManager (the Enter key has to be pressed)
	 * @author Enzo Borel
	 */
	public class Main extends Sprite implements GameListener, KeyListener{
		
		[SWF(width = "1024", height = "512", backgroundColor = "#000000", frameRate = "60")]
		
		//var iables used to load pictures
		private var _counter:int = 0;
		private var _loader:Loader = new Loader();
		private var _imagesArray:Array = ["shuriken1.png", "background.png", "tilespack.png", "test.png", "fallingwall.png", "topground.png", "intro.png"];
		private static var _bitmapDataArray:Vector.<BitmapData> = new Vector.<BitmapData>(7, true);
		
		//children
		private var game:Game; //the game itself
		private var screen:Bitmap = new Bitmap(); //the "Welcome"/"End" screen
		
		private var _inputManager:InputManager = new InputManager(this as KeyListener);
		
		public function Main() {
			if (stage){
				init();
			}
			else{
				addEventListener(Event.ADDED_TO_STAGE, init);
			}
		}
		
		/**
		 * The callback function is called as an image loading is completed
		 * @param	event
		 */
		private function onLoadComplete(event:Event):void{
			_loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoadComplete);//remove the listener for the loading
			_bitmapDataArray[_counter] = event.target.content.bitmapData;//store the result in an array
			_counter++; //increment the counter to load the next one (if exists)
			if (_counter < _imagesArray.length){
				loadImage();
			}
			else{
				//as it's finished, prepare the introduction screen, and add it to the stage
				_loader = null;
				_imagesArray.splice(0);
				_imagesArray = null;
				screen.bitmapData = new BitmapData(Constants.APP_WIDTH, Constants.APP_HEIGHT, true, 0xFFFFFF);
				screen.bitmapData.copyPixels(_bitmapDataArray[6], new Rectangle(0, Constants.APP_HEIGHT, Constants.APP_WIDTH, Constants.APP_HEIGHT), new Point());
				addChild(screen);
			}
		}
		
		/**
		 * Loads a new bitmap and adds a listener on this loading process
		 */
		private function loadImage():void{
			_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadComplete);
			_loader.load(new URLRequest(("../res/img/" + _imagesArray[_counter]) as String));
		}
		
		/**
		 * Does the initialization of the game. Starts the images loading
		 * @param	e
		 */
		private function init(e:Event = null):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			//add listeners on the stage to handle inputs
			stage.addEventListener(KeyboardEvent.KEY_DOWN, _inputManager.keyDown, false, 0, true);
			stage.addEventListener(KeyboardEvent.KEY_UP, _inputManager.keyUp, false, 0, true);
			mouseEnabled = false;
			mouseChildren = false;
			loadImage();
		}
		
		/**
		 * Called ad the game in finished. Displays the "End" screen
		 */
		public function onGameEnd():void{
			screen.bitmapData.copyPixels(_bitmapDataArray[6], new Rectangle(0, 0, Constants.APP_WIDTH, Constants.APP_HEIGHT), new Point());
			removeChild(game);
			addChild(screen);
		}
		
		/**
		 * Called as the key "Enter" is pressed.
		 * The Enter key must be pressed if the player wants to start the game after the introduction screen
		 */
		public function onEnterPressed():void{
			if (screen.stage && game == null){
				//we have to do this checking because the keystroke event is fired while the key is pressed, and we want execute this 
				//code only once.
				removeChild(screen);
				addChild(game = new Game(this as GameListener, _inputManager));
				addEventListener(Event.ENTER_FRAME, game.update, false, 0, true);
			}
		}
		
		/**
		 * Called as the Esc key is pressed.
		 * The Esc key must be pressed if the player wants to quit the game
		 */
		public function onEscapePressed():void{
			//same behavior as a victory, but forced by the player
			if (screen.stage == null){
				onGameEnd();
			}
		}
		
		/**
		 * @return the bitmap data associated with { @link Shuriken}
		 */
		public static function getShurikenBitmapData():BitmapData{
			return _bitmapDataArray[0];
		}
		
		/**
		 * @return the bitmap data associated with the background
		 */
		public static function getBackgroundBitmapData():BitmapData{
			return _bitmapDataArray[1];
		}
		
		/**
		 * @return the bitmap data associated with the tile set of the game
		 */
		public static function getTileSetBitmapData():BitmapData{
			return _bitmapDataArray[2];
		}
		
		/**
		 * @return the bitmap data associated with { @link Hero}
		 */
		public static function getHeroBitmapData():BitmapData{
			return _bitmapDataArray[3];
		}
		
		/**
		 * @return the bitmap data associated with the falling wall
		 */
		public static function getFallingWallBitmapData():BitmapData{
			return _bitmapDataArray[4];
		}
		
		/**
		 * @return the bitmap data associated with the falling ground
		 */
		public static function getTopGroundBitmapData():BitmapData{
			return _bitmapDataArray[5];
		}
	}
	
}