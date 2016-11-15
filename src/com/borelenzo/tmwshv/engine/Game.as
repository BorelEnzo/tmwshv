package com.borelenzo.tmwshv.engine {

	import com.borelenzo.tmwshv.Constants;
	import com.borelenzo.tmwshv.GameListener;
	import com.borelenzo.tmwshv.Main;
	import com.borelenzo.tmwshv.actors.BaseActor;
	import com.borelenzo.tmwshv.actors.Hero;
	import com.borelenzo.tmwshv.actors.Shuriken;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	
	/**
	 * The Class Game.
	 * This class is the main engine of the game
	 * 
	 * The code is based on the code in C++ found here : http://www.meruvia.net/index.php/programmation/32-big-tuto-c-sfml-2-jeu-de-plateformes
	 * 
	 * @author Enzo Borel & meruvia studio
	 */
	public class Game extends Sprite{
		
		private var _mapTimer:int 		= 0; 					//animation timer
		private var _tileSetNumber:int	= 0; 					//tileset to draw
		private var _slowBreakable:int	= 0; 					//timer of breakable blocks
		private var _endMapX:int		= Constants.MAP_WIDTH;  //end of the tiled map
		private var _endMapY:int		= Constants.MAP_HEIGHT; //end of the tiled map
		private var _camera:Rectangle	= new Rectangle();
		
		//characters
		private var _hero:Hero 						= new Hero();					
		private var _horizontalShuriken:Shuriken	= new Shuriken(false);
		private var _verticalShuriken:Shuriken		= new Shuriken(true);
		private var _fallingWall:BaseActor 			= new BaseActor( -Constants.UNIT * 5, -3 * Constants.UNIT, 15, 0, Main.getFallingWallBitmapData());
		private var _fallingGround:BaseActor 		= new BaseActor( - Constants.UNIT * 4, -Constants.UNIT,5,0, Main.getTopGroundBitmapData()) ;
		
		//Testfield used to display messages
		private var _textField:TextField = new TextField();
		
		//Reusable objects
		private var _rectangle:Rectangle 	= new Rectangle();
		private var _point:Point 			= new Point();
		
		// _tileMap and _foregroundTileMap are temporary tiled maps (2 layers).
		//TILEMAP is the reference. It means that at the first time, the reference is loaded and should not change. As the level is reloaded,
		//_tilemap is updated by copying the content of TILEMAP without reading the external file
		//The foreground in decorative, so it should not change at all
		private var _tileMap:Vector.<Vector.<int>> 				= new Vector.<Vector.<int>>(Constants.MAP_HEIGHT, true);
		private var _foregroundTileMap:Vector.<Vector.<int>> 	= new Vector.<Vector.<int>>(Constants.MAP_HEIGHT, true);
		private var TILEMAP:Vector.<Vector.<int>> 				= new Vector.<Vector.<int>>(Constants.MAP_HEIGHT, true);
		
		//Bitmaps representing the tiled map
		private var _bmpMainTileMap1:Bitmap 		= new Bitmap(); //first child of the main layer
		private var _bmpMainTileMap2:Bitmap 		= new Bitmap(); //second child on the main layer
		private var _bmpForegroundTileMap1:Bitmap 	= new Bitmap(); //first child of the foreground layer
		private var _bmpForegroundTileMap2:Bitmap 	= new Bitmap(); //second child of the foreground layer
		
		private var _background:Bitmap; 	// scrolling background, and transition background
		private var _background2:Bitmap; 	//scrolling background
		
		//the listener used to communicate with the main class
		private var _gameListener:GameListener;
		
		private var _inputManager:InputManager;
		
				
		/**
		 * The constructor of the Game. Initializes all objects
		 * @param	gameListener reference to the main class
		 * @param 	inputManager
		 */
		public function Game(gameListener:GameListener, inputManager:InputManager) {
			this._gameListener = gameListener;
			this._inputManager = inputManager;
			
			//initialize maps
			for (var i:int = 0; i < _tileMap.length; i++){
				_tileMap[i] = new Vector.<int>(Constants.MAP_WIDTH, true);
				_foregroundTileMap[i] = new Vector.<int>(Constants.MAP_WIDTH, true);
				TILEMAP[i] = new Vector.<int>(Constants.MAP_WIDTH, true);
			}
			
			//Initialize bitmapdatas : blank picture
			var tileSetBitmapData:BitmapData = new BitmapData(3072, 512, true, 0xFFFFFF);
			_bmpForegroundTileMap1.bitmapData = tileSetBitmapData.clone();
			_bmpForegroundTileMap2.bitmapData = tileSetBitmapData.clone();
			_bmpMainTileMap1.bitmapData = tileSetBitmapData.clone();
			_bmpMainTileMap2.bitmapData = tileSetBitmapData.clone();
			tileSetBitmapData.dispose();
			
			//add the background
			addChild(_background = new Bitmap(Main.getBackgroundBitmapData()));
			addChild(_background2 = new Bitmap(Main.getBackgroundBitmapData()));
			_background2.x = _background.width;	
			
			//load the level, and build the level's world
			levelReset();
			
			//Add characters
			(addChild(new Sprite()) as Sprite).addChild(_bmpMainTileMap1);//first layer (main)
			addActor(_hero);
			(addChild(new Sprite()) as Sprite).addChild(_bmpForegroundTileMap1); //foreground layer
			addActor(_horizontalShuriken);
			addActor(_verticalShuriken);
			addActor(_fallingWall);
			addChild(_textField);
			addChild(_fallingGround);
			
			//set camera's values. Its dimension should not change
			_camera.width = Constants.APP_WIDTH;
			_camera.height = Constants.APP_HEIGHT;
			
			//Initialize the textfield
			_textField.textColor = 0xFFFFFF;
			_textField.height = Constants.UNIT;
			_textField.scaleX = 2;
			_textField.scaleY = 2;
		}	
		
		/**
		 * @param	y the coordinate of the tile in the tiled map on Y axis (row)
		 * @param	x the coordinate of the tile in the tiled map on X axis (column)
		 * @param 	mainMap if true, search in the main map, else, search in the foreground map
		 * @return 	the tile code if the coordinates are valid
		 */
		private function getTileCode(y:int, x:int, mainMap:Boolean = true):int{
			if (y >= 0 && y < Constants.MAP_HEIGHT && x >= 0 && x < Constants.MAP_WIDTH){
				return mainMap ? _tileMap[y][x] : _foregroundTileMap[y][x];
			}
			return -1;
		}
		
		/**
		 * @param	y the coordinate of the tile in the tiled map on Y axis (row)
		 * @param	x x the coordinate of the tile in the tiled map on X axis (column)
		 * @return  true is the tile is animated
		 */
		private function isTileAnimated(y:int, x:int):Boolean{
			var code:int = getTileCode(y, x);
			if (code != -1){
				return code == Constants.BONUS || code == Constants.MALUS_DEATH || code == Constants.MALUS_SHURIKEN ||
				code == Constants.TOP_LAVA || code == Constants.WATER_FALL || code == Constants.LAMP;
			}
			return false;
		}
		
		/**
		 * Adds actors to the Stage and sets a listener on this actor
		 * @param	actor the actor to add
		 */
		private function addActor(actor:BaseActor):void{
			actor.addEventListener(Event.ADDED_TO_STAGE, actor.onAddedToStage);
			addChild(actor);
		}
		
		/**
		 * Updates the level (position of actors, and checks collisions)
		 * @param	event
		 */
		public function update(event:Event):void{
			if (_hero.stage == null){
				return;
			}
			
			//animate the animated tiles
			if (_mapTimer <= 0){
				_tileSetNumber = _tileSetNumber < 2 ? _tileSetNumber + 1 : 0;
				_mapTimer = 20;
				var start:int = _camera.x / Constants.UNIT;
				var end:int = start + (Constants.APP_WIDTH / Constants.UNIT);
				for (var i:int = 0; i < Constants.MAP_HEIGHT; i++){
					for (var j:int = start; j <= end; j++){
						if (isTileAnimated(i, j)){
							redrawBlock(i, j, getTileCode(i, j));
						}
					}
				}
				
			}
			else{
				_mapTimer--;
			}
			
			//update the hero (visually)
			_hero.update();
			//if he's not dead (like a punk) and if he's not victorious (happy and glorious), update its position anf check collisions
			if (_hero.state != Constants.CHARACTER_DEAD && _hero.state != Constants.CHARACTER_VICTORY){
				
				//apply forces
				_hero.speedX = 0;
				_hero.speedY = _hero.speedY + 0.6 > 15 ? 15 : _hero.speedY + 0.6;
				
				//update the state according to inputs
				if (_inputManager.keyPressed.left){
					_hero.walk(false);
				}
				else if (_inputManager.keyPressed.right){
					_hero.walk(true);
				}
				else if (!_inputManager.keyPressed.right && !_inputManager.keyPressed.left && _hero.grounded){
					_hero.rest();
				}
				if (_inputManager.keyPressed.jump){
					_hero.jump();			
					_inputManager.activateKey(Keyboard.UP, false, true);
				}
				if (_inputManager.keyPressed.suicide){
					_hero.originX = -_hero.width;
					_hero.originY = -_hero.height;
					killHero();
				}
				if (_hero.grounded){
					_hero.jumping = true;
				}
				else{
					if (_hero.jumping){
						if (_hero.state != Constants.CHARACTER_JUMP_1){
							_hero.state = Constants.CHARACTER_JUMP_1;
							_hero.resetAnimation(Constants.JUMP_1_FRAMES);
						}
					}
					else{
						if (_hero.state != Constants.CHARACTER_JUMP_2){
							_hero.state = Constants.CHARACTER_JUMP_2;
							_hero.resetAnimation(Constants.JUMP_2_FRAMES);
						}
					}
				}
				//save the hero coordinates
				_hero.exSpeedX = _hero.speedX;
				_hero.wasGrounded = _hero.grounded;
				_hero.exSpeedY = _hero.speedY;
				_hero.exX = _hero.x;
				_hero.exY = _hero.y;
				
				//check collisions and update the hero's position
				checkCollisions();
				checkSlope();
				
				//apply forces effectively
				_hero.x += _hero.speedX;
				_hero.y += _hero.speedY;
				
				//if the hero is jumping, he should jump in front of the scenery, so swap positions (hero and foreground layer)
				if (_hero.grounded){
					if (getChildIndex(_hero) != 3){
						swapChildren(getChildAt(3), _hero);
					}
				}
				else{
					if (
						getChildIndex(_hero) == 3 &&
						(getTileCode((_hero.y + _hero.height) / Constants.UNIT, _hero.x / Constants.UNIT, false) == 0 || 
						getTileCode((_hero.y + _hero.height) / Constants.UNIT, (_hero.x + _hero.width / Constants.UNIT), false) == 0)){
							swapChildren(getChildAt(4), _hero);
					}

				}
				
				//if the hero is out screen bounds, replace it
				if (_hero.x < 0){
					_hero.x = 0;
				}
				else if (_hero.x + _hero.width > _endMapX){
					_hero.x = _endMapX - _hero.width;
				}
				if (_hero.y < 0){
					_hero.y = 0;
					_hero.speedY = 0;
				}
				else if (_hero.y > Constants.APP_HEIGHT){
					killHero();
				}
				
				//check if the hero wins
				if (_hero.x > 190 * Constants.UNIT && _hero.y < Constants.UNIT && _hero.grounded){
					_hero.win();
				}
			}
			
			//is the hero is dead or victorious, decrement counters
			else if (_hero.deathTimer > 0){
				_hero.deathTimer--;
				if (_hero.deathTimer == 0){
					levelReset();// after a death, reload the level
				}
			}
			else if (_hero.victoryTimer > 0){
				_hero.victoryTimer--;
				if (_hero.victoryTimer == 0){
					_gameListener.onGameEnd(); //or close the game and return to Main to display the "end" screen
				}
			}
			
			//update shurikens and falling wall, if they move
			//while they are moving in the stage, they are placed at their original position, out of screen bounds.
			// if hasMoved return stue, it means that they were replaced somewhere, and we should update their positions
			if (_horizontalShuriken.hasMoved()){
				_horizontalShuriken.update(_camera.x);
				if (_horizontalShuriken.overlaps(_hero)){
					killHero();
				}
			}
			if (_verticalShuriken.hasMoved()){
				_verticalShuriken.update();
				if (_verticalShuriken.overlaps(_hero)){
					killHero();
				}
			}
			if (_fallingWall.hasMoved()){
				_fallingWall.update();
				if (_fallingWall.overlaps(_hero)){
					killHero();
				}
			}
			if (_fallingGround.hasMoved()){
				_fallingGround.update();
			}
			
			//update the camera's position
			focusCamera();
			scrollRect = _camera;
			
			//if the camera's position on X axis is greater than the first picture, then add the second picture
			if (_camera.x + Constants.APP_WIDTH > _bmpMainTileMap1.x + _bmpMainTileMap1.width && (getChildAt(2) as Sprite).numChildren == 1){
				(getChildAt(2) as Sprite).addChild(_bmpMainTileMap2);
				if (getChildIndex(_hero) == 3){
					(getChildAt(4) as Sprite).addChild(_bmpForegroundTileMap2);
				}
				else{
					(getChildAt(3) as Sprite).addChild(_bmpForegroundTileMap2);
				}
			}
		}
		
		
		/**
		 * Sets the camera at the right place in order to have the focus on the hero
		 */
		private function focusCamera():void{
			const centerX:int = _hero.x + _hero.width / 2;
			const deltaCam:int = _camera.x;
			if (centerX < _camera.x){
				_camera.x -= 28;
			}
			else if (centerX < int(_camera.x + Constants.CAMERA_LIM_X)){
				_camera.x -= 4;
			}
			else if (centerX > int(_camera.x + Constants.APP_WIDTH)){
				_camera.x += 28;				
			}
			else if (centerX > int(_camera.x + Constants.CAMERA_LIM_X + Constants.CAMERA_LIM_WIDTH)){
				_camera.x += 4;
			}
			if (_camera.x <= 0){
				_camera.x = 0
			}
			else if (_camera.x + Constants.APP_WIDTH >= _endMapX){
				_camera.x = _endMapX - Constants.APP_WIDTH;
			}
			//move the background, which doesn't move with the same velocity
			var deltaX:int = (_camera.x - deltaCam);
			if (deltaX != 0){
				deltaX = deltaX > 0 ? deltaX-1: deltaX+1;
			}
			_background.x += deltaX;
			_background2.x = _background.x + _background.width;
			if (_background.x + _background.width < _camera.x){
				_background.x = _camera.x;
				_background2.x = _background.x + _background.width;
			}
			else if (_background.x > _camera.x){
				_background2.x = _camera.x;
				_background.x = _camera.x -_background.width;
			}
		}
		
		/**
		 * Kills the hero if he is not already dead
		 */
		private function killHero():void{
			if (_hero.recoveryTimer == 0){
				_hero.die();
			}
		}
		
		/**
		 * Checks if the hero hits a deadly object by walking. We consider that the hero dies if the object is below the hero's head
		 * @param	y the coordinate of the object in tiled map
		 * @return 	true if the hero hits
		 */
		private function hitByWalking(y:int):Boolean{
			if (y * Constants.UNIT > _hero.y){
				killHero();
				return true;
			}
			return false;
		}
		
		/**
		 * Checks if the hero hits a deadly object by jumping.
		 * @param	y coordinate of the object in tiled map
		 * @param	x coordinate of the object in tiled map
		 * @return 	true if the hero hits
		 */
		private function hitbyJumping(y:int, x:int):Boolean{
			if (_hero.goingToRight){
				if ((y + 1) * Constants.UNIT > _hero.y && _hero.x + 1 < (x + 1) * Constants.UNIT){
					killHero();
					return true;
				}
			}
			else{
				if ((y + 1) * Constants.UNIT > _hero.y && _hero.x +_hero.width > x * Constants.UNIT){
					killHero();
					return true;
				}
			}
			return false;
		}
		
		/**
		 * Checks if the hero hits a deadly object by falling on
		 * @param	y coordinate of the object in tiled map
		 * @param	x coordinate of the object in tiled map
		 * @return  true if the hero hits
		 */
		private function hitByFalling(y:int, x:int):Boolean {
			if (_hero.goingToRight){
				if (y * Constants.UNIT < _hero.y + _hero.height && _hero.x + 1 < (x + 1) * Constants.UNIT){
					killHero();
					return true;
				}
			}
			else{
				if (y * Constants.UNIT < _hero.y + _hero.height && _hero.x + _hero.width > x * Constants.UNIT){
					killHero();
					return true;
				}
			}
			return false;
		}
		
		/**
		 * As the Hero hits the ground, set it at the right position (on the top of the tile) ans set its y velocity to 0. 
		 * State : grounded. We have to check where he if its velocity allows him to be on the top, or if his curve inversion is done
		 * below the top
		 * @param	y the y position of the tile
		 */
		private function hitGround(y:int):void{
			if(_hero.y + _hero.height <= y * Constants.UNIT && _hero.y + _hero.height + _hero.speedY >= y * Constants.UNIT){
				_hero.y = (y * Constants.UNIT) - _hero.height;
				_hero.speedY = 0;
				_hero.grounded = true;
			}
		}
		
		/**
		 * As the hero hits a platform by jumping, set it a the right position, below this platform, and stop its jump.
		 * @param	y the coordinate of the tile in the tiled map
		 */
		private function hitFromTheBottom(y:int):void{
			_hero.y = (y + 1) * Constants.UNIT;
			_hero.speedY = 0;
		}
		
		/**
		 * As the hero goes through a checkpoint, we register its coordinates in order to put the hero at this place
		 * the next time he dies. Then, redraw the block
		 * @param	y the coordinate of the tile in the tiled map
		 * @param	x the coordinate of the tile in the tiled map
		 */
		private function checkPoint(y:int, x:int):void{
			_hero.originX = x * Constants.UNIT;
			_hero.originY = y * Constants.UNIT - _hero.height;
			redrawBlock(y, x, Constants.CHECKPOINT);
		}
		
		/**
		 * Makes the falling ground moving
		 * @param	y the coordinate of the tile in the tiled map
		 * @param	x the coordinate of the tile in the tiled map
		 */
		private function fallGround(y:int, x:int):void{
			var i:int;
			//we check if the tile above the falling ground is empty or not. It is the case, erase the ground
			//Else draw a ground texture
			if (getTileCode(y - 1, x) == 0){
				for ( i = x; i < x + 4; i++){
					for (var j:int = y; j < Constants.MAP_HEIGHT; j++){
						redrawBlock(j, i, 0);
					}
				}
			}
			else{
				for ( i = x; i < x + 4; i++){
					redrawBlock(y, i, Constants.GROUND);
				}
			}
		}
		
		
		/**
		 * Places the shuriken is the screen, and "launches" it on the hero
		 */
		private function launchHorizontalShuriken():void{
			if (!_horizontalShuriken.hasMoved()){
				_horizontalShuriken.y = _hero.y;
				_horizontalShuriken.x = Constants.APP_WIDTH + _camera.x;
			}
		}
		
		/**
		 * As the hero meets a NPC, the NPC tells something 
		 * @param	code of the NPC
		 */
		private function talkToNPC(y:int, x:int):void{
			_textField.text = "";
			_textField.visible = true;
			switch(getTileCode(y, x)){
				case Constants.NPC_GIRL_DRESS:
					_textField.width = Constants.UNIT * 5;
					_textField.text = "Hello I'm Jennifer, did you see \n my sister Nicole ?";
					break;
				case Constants.NPC_MAN_BLACK:
					_textField.width = Constants.UNIT * 4;
					_textField.text = "Agent J, what's going on ?";
					break;
				case Constants.NPC_MAN_BLOND:
					_textField.width = Constants.UNIT * 4;
					_textField.text = "You're gonna go far kid !";
					break;
				case Constants.NPC_PIG:
					_textField.width = Constants.UNIT * 6;
					_textField.text = "throw new IllegalOperationError \n (\"Gruik gruik\", Constants.PIG);";
					break;
				case Constants.NPC_W_BLUE:
					_textField.width = Constants.UNIT * 4;
					_textField.text = "I'm Emma Stone, did \n you see my portrait ?";
					break;
				case Constants.NPC_ZIGGY:
					_textField.width = Constants.UNIT * 5;
					_textField.text = "You're face to face with the \n man who sold the world";
					break;
				default:
					_textField.visible = false;
					return;
			}		
			_textField.x = x * Constants.UNIT - _textField.width / 2;
			_textField.y = y * Constants.UNIT - _textField.height;
		}
		
		/**
		 * Places the falling wall above the hero and launches it
		 * @param	x the position of the wall
		 */
		private function fallWall(x:int):void{
			_fallingWall.x = _hero.goingToRight ? _hero.x + _hero.width: _hero.x - (_fallingWall.width + Constants.UNIT);
			for (var i:int = 0; i < Constants.MAP_HEIGHT; i++){
				if (_tileMap[i][x] == Constants.FALL_WALL){
					redrawBlock(i, x, 0);
				}
			}
		}
		
		/**
		 * Checks collisions while the hero is walking
		 * @param	y the coordinate of the tile in the tiled map
		 * @param	x the coordinate of the tile in the tiled map
		 * @param	toRight the diection of the hero. If he goes to right, we check the next tile, else wh check the previous one
		 */
		private function checkWalk(y:int, x:int, toRight:Boolean):void{
			switch(_tileMap[y][x]){
				case Constants.BONUS:
				case Constants.BREAKABLE_1:
				case Constants.BROWN_BLOCK_1:
				case Constants.BREAKABLE_2:
				case Constants.BREAKABLE_3:
				case Constants.BREAKABLE_4:
				case Constants.BREAKABLE_5:	
				case Constants.MALUS_DEATH:
				case Constants.BLUE_BLOCK:
				case Constants.BROWN_BLOCK_2:
				case Constants.MALUS_SHURIKEN:
				case Constants.FLOATING_GREY:
				case Constants.SPIRAL_BLOCK:
					//stop the hero next to the tile
					_hero.x = toRight ? x * Constants.UNIT - (_hero.width + 1) : (x + 1) * Constants.UNIT;
					_hero.speedX = 0;
					break;
				case Constants.LEFT_LIM_GROUND:
				case Constants.LEFT_LIM_TOP_GROUND:
					//the same here, but not at the same place
					if (toRight){
						_hero.x = x * Constants.UNIT - (_hero.width + 1);
						_hero.speedX = 0;
					}
					else{
						if (_hero.x <= x * Constants.UNIT + 8){
							_hero.x = x * Constants.UNIT + 8;
							_hero.speedX = 0;
						}
					}
					break;
				case Constants.RIGHT_LIM_GROUND:
				case Constants.RIGHT_LIM_TOP_GROUND:
					//the same here but not at the same place
					if (!toRight){
						_hero.x = (x + 1) * Constants.UNIT;
						_hero.speedX = 0;
					}
					else{
						if (_hero.x + _hero.width +1 >= x * Constants.UNIT + 24){
							_hero.x = x * Constants.UNIT + 24 - (_hero.width + 1);
							_hero.speedX = 0;
						}
					}
					break;
				case Constants.CHEESE:
				case Constants.LIGHTNING:	
				case Constants.CHERRIES:
				case Constants.HEART:	
					//deadly objects
					if (hitByWalking(y)){
						redrawBlock(y, x, 0);
					}
					break;
				case Constants.SPIKE:
					hitByWalking(y);
					break;
				case Constants.REVERSE_SPIKES:
					if (y * Constants.UNIT < _hero.y){
						killHero(); //only if the spike points to bottom
					}
					break;
				case Constants.INVISIBLE:
					redrawBlock(y, x, Constants.FLOATING_GREY);
					hitGround(y);
					break;
				case Constants.DISABLE_CKPT:
					checkPoint(y, x);
					break;
				case Constants.ERASABLE:
					redrawBlock(y, x, 0);
					break;
				case Constants.SHURIKEN:
					launchHorizontalShuriken();
					break;
				case Constants.FALL_WALL:
					fallWall(x);
					break;
				case Constants.TRIGGER_SPIKE:
					//show the spike and remove triggers
					if (getTileCode(y, x - 1) == Constants.HIDDEN_SPIKE){
						redrawBlock(y, x - 2, 0);
						redrawBlock(y, x - 1, Constants.SPIKE);
						redrawBlock(y, x, 0);
					}
					else if (getTileCode(y, x + 1) == Constants.HIDDEN_SPIKE){
						redrawBlock(y, x + 2, 0);
						redrawBlock(y, x + 1, Constants.SPIKE);
						redrawBlock(y, x, 0);
					}
					break;
				case Constants.HIDDEN_SPIKE:
					//the same 
					redrawBlock(y, x - 1, 0);
					redrawBlock(y, x, Constants.SPIKE);
					redrawBlock(y, x + 1, 0);
					break;
				case Constants.NPC_W_BLUE:
				case Constants.NPC_ZIGGY:
				case Constants.NPC_PIG:
				case Constants.NPC_GIRL_DRESS:
				case Constants.NPC_MAN_BLACK:
				case Constants.NPC_MAN_BLOND:
					talkToNPC(y, x);
					break;
				default:
					_textField.visible = false;
			}
		}
		
		/**
		 * Checks collisions on hero's head
		 * @param	y the coordinate of the tile in the tiled map
		 * @param	x the coordinate of the tile in the tiled map
		 */
		private function checkJump(y:int, x:int): void{
			switch(_tileMap[y][x]){
				case Constants.BREAKABLE_1:
				case Constants.BREAKABLE_4:
				case Constants.BREAKABLE_5:
				case Constants.BROWN_BLOCK_1:
				case Constants.BREAKABLE_2:
				case Constants.BLUE_BLOCK:
				case Constants.BROWN_BLOCK_2:
				case Constants.BREAKABLE_3:
				case Constants.FLOATING_GREY:
				case Constants.ROOF_LEFT:
				case Constants.ROOF_MIDDLE:
				case Constants.ROOF_RIGHT:
					hitFromTheBottom(y);
					break;
				case Constants.TOP_LIM_GROUND:		
					if (_hero.y <= y * Constants.UNIT + 8){
						_hero.y = y * Constants.UNIT + 8;
						_hero.speedY = 0;
					}
				case Constants.LEFT_LIM_GROUND:
					if (_hero.x < x * Constants.UNIT + 8 && _hero.x + _hero.width > x  * Constants.UNIT){
						hitFromTheBottom(y);
					}
					break;
				case Constants.RIGHT_LIM_GROUND:
					if (_hero.x < (x + 1) * Constants.UNIT && _hero.x + _hero.width > x * Constants.UNIT + 24){
						hitFromTheBottom(y);
					}
					break;
				case Constants.BONUS:
					//becomes invicible
					redrawBlock(y, x, 0);
					_hero.recoveryTimer = 120;
					hitFromTheBottom(y);
					break;
				case Constants.INVISIBLE:
					redrawBlock(y, x, Constants.FLOATING_GREY);
					hitGround(y);
					break;
				case Constants.ERASABLE:
					redrawBlock(y, x, 0);
					break;
				case Constants.CHEESE:
				case Constants.CHERRIES:
				case Constants.HEART:
				case Constants.LIGHTNING:
					if (hitbyJumping(y, x)){
						redrawBlock(y, x, 0);
					}
					break;
				case Constants.SHURIKEN:
					launchHorizontalShuriken();
					break;
				case Constants.MALUS_DEATH:
					//deadly box!
					redrawBlock(y, x, 0);
					killHero();
					break;
				case Constants.REVERSE_SPIKES:
					hitbyJumping(y, x);
					break;
				case Constants.DISABLE_CKPT:
					checkPoint(y, x);
					break;
				case Constants.MALUS_SHURIKEN:
					//launched the vertical shuriken
					hitFromTheBottom(y);
					redrawBlock(y, x, 0);
					if (!_verticalShuriken.hasMoved()){
						_verticalShuriken.y = 0;
						_verticalShuriken.x = _hero.x + _hero.width / 2;
					}
					break;
				case Constants.FALL_WALL:
					fallWall(x);
					break;
			}
		}
		
		/**
		 * Checks all collisions when hero is Falling
		 * @param	y coord of the tile to check in the tiled map
		 * @param	x coord of the tile to check in the tiled map
		 */
		private function checkFall(y:int, x:int):void{
			switch(_tileMap[y][x]){
				case Constants.GATEWAY:
				case Constants.BONUS:
				case Constants.MIDDLE_CLOUD:
				case Constants.LADDER:
				case Constants.TOP_LIM_GROUND:
				case Constants.CORNER_TOP_RIGHT:
				case Constants.CORNER_TOP_LEFT:
				case Constants.BOX_EMMA:
				case Constants.FLOATING_GROUND_LEFT:
				case Constants.BROWN_BLOCK_1:
				case Constants.MALUS_DEATH:
				case Constants.RIGHT_CLOUD:
				case Constants.BRANCH_LEFT:
				case Constants.BLUE_BLOCK:
				case Constants.BROWN_BLOCK_2:
				case Constants.MALUS_SHURIKEN:
				case Constants.TOP_BEIGE_WALL:
				case Constants.BRANCH_RIGHT:
				case Constants.FLOATING_GREY:
				case Constants.FLOATING_GROUND_RIGHT:
				case Constants.TOP_BROWN_WALL:
				case Constants.LEFT_CLOUD:
				case Constants.SPIRAL_BLOCK:
				case Constants.RIGHT_LIM_TOP_GROUND:
				case Constants.LEFT_LIM_TOP_GROUND:
				case Constants.ROOF_MIDDLE:
					hitGround(y);
					break;
				break;
				case Constants.TOP_GROUND:
					if ((isTileSlope(y, x - 1) && _hero.goingToRight) || (isTileSlope(y, x+1) && !_hero.goingToRight)){
						_hero.y = (y * Constants.UNIT) - _hero.height;
						_hero.speedY = 0;
						_hero.grounded = true;	
						}
					else{
						hitGround(y);
					}
					break;
				case Constants.BREAKABLE_5:
				case Constants.BREAKABLE_4:
				case Constants.BREAKABLE_3:
				case Constants.BREAKABLE_2:
				case Constants.BREAKABLE_1:
					slowBreaking(y, x);
					break;
				case Constants.LEFT_LIM_GROUND:
				case Constants.CORNER_TOP_LEFT:
					if (_hero.x < (x * Constants.UNIT) + 8 && _hero.x + _hero.width > x  * Constants.UNIT){
						hitGround(y);
					}
					break;
				case Constants.RIGHT_LIM_GROUND:
				case Constants.CORNER_TOP_RIGHT:
					if (_hero.x < (x + 1) * Constants.UNIT && _hero.x + _hero.width > x * Constants.UNIT + 24){
						hitGround(y);
					}
					break;
				case Constants.HEART:
				case Constants.CHERRIES:
				case Constants.LIGHTNING:
				case Constants.CHEESE:
					if (hitByFalling(y, x)){
						redrawBlock(y, x, 0);
					}
					break;
				case Constants.SPIKE:
				case Constants.LAVA:
				case Constants.TOP_LAVA:
					hitByFalling(y, x);
					break;
				case Constants.SHURIKEN:
					launchHorizontalShuriken();
					break;
				case Constants.INVISIBLE:
					redrawBlock(y, x, Constants.FLOATING_GREY);
					hitGround(y);
					break;
				case Constants.DISABLE_CKPT:
					checkPoint(y, x);
					break;
				case Constants.ERASABLE:
					redrawBlock(y, x, 0);
					break;
				case Constants.FALL_WALL:
					fallWall(x);
					break;
				case Constants.TRIGGER_SPIKE:
					if (getTileCode(y, x - 1) == Constants.HIDDEN_SPIKE){
						redrawBlock(y, x - 2, 0);
						redrawBlock(y, x - 1, Constants.SPIKE);
						redrawBlock(y, x, 0);
					}
					else if (getTileCode(y, x + 1) == Constants.HIDDEN_SPIKE){
						redrawBlock(y, x + 2, 0);
						redrawBlock(y, x + 1, Constants.SPIKE);
						redrawBlock(y, x, 0);
					}
					break;
				case Constants.HIDDEN_SPIKE:
					redrawBlock(y, x - 1, 0);
					redrawBlock(y, x, Constants.SPIKE);
					redrawBlock(y, x + 1, 0);
					break;
				case Constants.TRIGGER_TOP_GROUND:
					if (getTileCode(y, x - 1) == Constants.FALL_TOP_GROUND){
						redrawBlock(y, x - 5, Constants.TOP_GROUND);
						redrawBlock(y, x, Constants.TOP_GROUND);
						_fallingGround.x = (x - 4) * Constants.UNIT;
						fallGround(y, x - 4);
					}
					else if (getTileCode(y, x + 1) == Constants.FALL_TOP_GROUND){
						redrawBlock(y, x + 5, Constants.TOP_GROUND);
						redrawBlock(y, x, Constants.TOP_GROUND);
						_fallingGround.x = (x + 1) * Constants.UNIT;
						fallGround(y, x +1);
					}
					_fallingGround.y = y * Constants.UNIT;
					hitGround(y);
					break;
				case Constants.FALL_TOP_GROUND:
					var start:int = x;
					while (getTileCode(y, start - 1) == Constants.FALL_TOP_GROUND){
						start--;
					}
					_fallingGround.x = start * Constants.UNIT;
					_fallingGround.y = y * Constants.UNIT;
					redrawBlock(y, start - 1, Constants.TOP_GROUND);
					redrawBlock(y, start + 4, Constants.TOP_GROUND);
					fallGround(y, start);
					break;
				case Constants.NPC_W_BLUE:
				case Constants.NPC_ZIGGY:
				case Constants.NPC_PIG:
				case Constants.NPC_MAN_BLOND:
				case Constants.NPC_GIRL_DRESS:
				case Constants.NPC_MAN_BLACK:
					talkToNPC(y, x);
					break;
				case Constants.MEGA_JUMP:
					break;
				default:
					_textField.visible = false;
			}
		}
		
		/**
		 * Breaks the breakables tiles slowly according to a timer and replace it with the next one (next state)
		 * @param	y
		 * @param	x
		 */
		private function slowBreaking(y:int, x:int):void{
			if (_slowBreakable == 10){
				switch(_tileMap[y][x]){
					case Constants.BREAKABLE_5:
						redrawBlock(y, x, Constants.BREAKABLE_4);
						break;
					case Constants.BREAKABLE_4:
						redrawBlock(y, x, Constants.BREAKABLE_3);
						break;
					case Constants.BREAKABLE_3:
						redrawBlock(y, x, Constants.BREAKABLE_2);
						break;
					case Constants.BREAKABLE_2:
						redrawBlock(y, x, Constants.BREAKABLE_1);
						break;
					case Constants.BREAKABLE_1:
						redrawBlock(y, x, 0);
						break;
				}
				_slowBreakable = 0;
			}
			else{
				_slowBreakable++;
			}
			hitGround(y);
		}
		
		/**
		 * Redraws a block in the sprite, and replaces the code in the tiled map
		 * @param	y coordinate of the block in the tiled map to redraw
		 * @param	x coordinate of the block in the tiled map to redraw
		 * @param	tileCode of the new block, 0 if empty
		 */
		private function redrawBlock(y:int, x:int, tileCode:int = 0):void{
			if (getTileCode(y, x) == -1){
				return;
			}
			_tileMap[y][x] = tileCode;
			_rectangle.x = _rectangle.y =  0;
			_rectangle.width = _rectangle.height = Constants.UNIT;
			if (tileCode == 0){
				//tileCode == 0 means that we want to erase the block
				_rectangle.y = y * Constants.UNIT;
				if (x < 96){
					_rectangle.x = x * Constants.UNIT;
					_bmpMainTileMap1.bitmapData.fillRect(_rectangle, 0x00FFFFFF);
				}
				else{
					_rectangle.x = (x - 96) * Constants.UNIT;
					_bmpMainTileMap2.bitmapData.fillRect(_rectangle, 0x00FFFFFF);
				}
			}
			else{
				//point indicates the coordinates of the new block to draw
				_point.x = 0;
				_point.y = y * Constants.UNIT;
				_rectangle.x = Constants.UNIT  * ((tileCode - 1) % 29);//the part of the tile set
				switch(_tileSetNumber){
					case 0:
						_rectangle.y = Constants.UNIT * int((tileCode - 1) / 29);
						break;
					case 1:
						_rectangle.y = (4 * Constants.UNIT) + (Constants.UNIT * int((tileCode - 1) / 29));
						break;
					case 2:
						_rectangle.y = (8 * Constants.UNIT) + (Constants.UNIT * int((tileCode - 1) / 29));
						break;
					default:
						_rectangle.y = Constants.UNIT * int((tileCode - 1) / 29);
						break;
				}
				//the bitmap to redraw depends of the x position
				if (x < 96){
					_point.x = x * Constants.UNIT;
					_bmpMainTileMap1.bitmapData.copyPixels(Main.getTileSetBitmapData(), _rectangle, _point);
				}
				else{
					_point.x = (x - 96) * Constants.UNIT;
					_bmpMainTileMap2.bitmapData.copyPixels( Main.getTileSetBitmapData(), _rectangle, _point);
				}
			}
		}
		
		/**
		 * Checks collisions with tiles (except slopes)
		 */
		private function checkCollisions():void	{
			var x1:int, x2:int, y1:int, y2:int;
			_hero.grounded = false;
			x1 = (_hero.x + _hero.speedX) / Constants.UNIT;
			x2 = x1 + 1;// (_hero.x + _hero.speedX + _hero.width - 1) / Constants.UNIT;
			y1 = _hero.y / Constants.UNIT;
			y2 = y1 + 1;// (_hero.y + _hero.height - 1) / Constants.UNIT;
			if (x1 >= 0 && x2 <= Constants.MAP_WIDTH && y1 >= 0 && y2 < Constants.MAP_HEIGHT){
				if (_hero.speedX > 0){
					if (x2 < Constants.MAP_WIDTH){
						checkWalk(y1, x2, true);
						checkWalk(y2, x2, true);
					}
				}
				else if (_hero.speedX < 0){
					checkWalk(y1, x1, false);
					checkWalk(y2, x1, false);
				}
			}
			x1 = _hero.x / Constants.UNIT;
			x2 = (_hero.x + _hero.width) / Constants.UNIT;
			y1 = (_hero.y + _hero.speedY) / Constants.UNIT;
			y2 = (_hero.y + _hero.speedY + _hero.height) / Constants.UNIT;
			if (x1 >= 0 && x2 <= Constants.MAP_WIDTH && y1 >= 0 && y2 < Constants.MAP_HEIGHT){
				if (_hero.speedY > 0){
					checkFall(y2, x1);
					if (x2 < Constants.MAP_WIDTH){
						checkFall(y2, x2);
					}
				}
				else if (_hero.speedY < 0){
					if (x2 < Constants.MAP_WIDTH){
						checkJump(y1, x2);
					}
					checkJump(y1, x1);
				}
			}
			
		}
		
		/**
		 * Loads the right level accordind to _level
		 * Reads file and fill the tile map with converted String (string to integer).
		 */
		private function loadLevel():void{
			const urlLoader:URLLoader = new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE, function onFileLoaded(event:Event):void{
				urlLoader.removeEventListener(Event.COMPLETE, onFileLoaded);
				_rectangle.x = _rectangle.y = 0;
				_rectangle.width = 4095;
				_rectangle.height = 512;
				
				//erase bitmaps
				_bmpForegroundTileMap1.bitmapData.fillRect(_rectangle, 0x00FFFFFF);
				_bmpForegroundTileMap2.bitmapData.fillRect(_rectangle, 0x00FFFFFF);
				_bmpMainTileMap1.bitmapData.fillRect(_rectangle, 0x00FFFFFF);
				_bmpMainTileMap2.bitmapData.fillRect(_rectangle, 0x00FFFFFF);
			
				//read the file
				var lines:Array = urlLoader.data.split(/\n/);
				_point.x = _point.y = 0;
				_rectangle.width = Constants.UNIT;
				_rectangle.height = Constants.UNIT;
				var i:int = 0, j:int = 0;
				//In the text file, the main tiled map is described first and then there is the content of the foreground map
				//fill the TILEMAP (reference)
				for (i = 0; i < lines.length; i++){
					lines[i] = lines[i].split(" ");
					if (i < Constants.MAP_HEIGHT){
						for (j = 0; j < Constants.MAP_WIDTH; j++){
							TILEMAP[i][j] = parseInt(lines[i][j]);
						}
					}
					else{
						//or directly fill the foreground tiled map and build the bitmap
						for (j = 0; j < Constants.MAP_WIDTH; j++){
							_foregroundTileMap[i - Constants.MAP_HEIGHT][j] = parseInt(lines[i][j]);
							if (_foregroundTileMap[i - Constants.MAP_HEIGHT][j] != 0){
								_point.y = (i - Constants.MAP_HEIGHT) * Constants.UNIT;
								_rectangle.x = Constants.UNIT * ((_foregroundTileMap[i - Constants.MAP_HEIGHT][j] - 1) % 29);
								_rectangle.y = Constants.UNIT * int((_foregroundTileMap[i - Constants.MAP_HEIGHT][j]-1) / 29);
								if (j < 96){
									_point.x = j * Constants.UNIT;
									_bmpForegroundTileMap1.bitmapData.copyPixels( Main.getTileSetBitmapData(), _rectangle, _point);
								}
								else{
									_point.x = (j - 96) * Constants.UNIT;
									_bmpForegroundTileMap2.bitmapData.copyPixels( Main.getTileSetBitmapData(), _rectangle, _point);
								}
							}
						}					
					}
				}
				//build the bitmap for the main tiled map
				for (i = 0; i < Constants.MAP_HEIGHT; i++){
					for (j = 0; j < Constants.MAP_WIDTH; j++){
						_tileMap[i][j] = TILEMAP[i][j];					
						if (_tileMap[i][j] != 0){
							_point.y = i * Constants.UNIT;
							_rectangle.x = Constants.UNIT  *((_tileMap[i][j]-1) % 29);
							_rectangle.y = Constants.UNIT * int((_tileMap[i][j]-1) / 29);
							if (j < 96){
								_point.x = j * Constants.UNIT;
								_bmpMainTileMap1.bitmapData.copyPixels( Main.getTileSetBitmapData(), _rectangle, _point);
							}
							else{
								_point.x = (j - 96) * Constants.UNIT;
								_bmpMainTileMap2.bitmapData.copyPixels( Main.getTileSetBitmapData(), _rectangle, _point);
							}
						}
					}
				}
				_bmpForegroundTileMap2.x = _bmpForegroundTileMap1.width;
				_bmpMainTileMap2.x = _bmpMainTileMap1.width;				
			});
			urlLoader.load(new URLRequest("../res/level1.txt"));
		}
		
		/**
		 * Resets the level and places the hero according to the level.
		 */
		private function levelReset():void{
			_endMapX = Constants.MAP_WIDTH;
			_endMapY = Constants.MAP_HEIGHT;
			_fallingGround.reset();
			_fallingWall.reset();
			_horizontalShuriken.reset();
			_verticalShuriken.reset();
						
			if (_hero.originX != -Constants.UNIT && _hero.originY != -40){				
				//read the map and if the cell has changed, reset it
				_rectangle.x = _rectangle.y = 0;
				_rectangle.width = _rectangle.height = Constants.UNIT;
				_point.x = _point.y = 0;
				for (var i:int = 0; i < TILEMAP.length; i++){
					for (var j:int = 0; j < TILEMAP[i].length; j++){
						if (_tileMap[i][j] != TILEMAP[i][j]){
							_tileMap[i][j] = TILEMAP[i][j];
							_point.y = i * Constants.UNIT;
							_rectangle.y = _point.y;
							if (j < 96){
								_point.x = j * Constants.UNIT;
								_rectangle.x = _point.x;
								_bmpMainTileMap1.bitmapData.fillRect(_rectangle, 0x00FFFFFF);
								_rectangle.x = Constants.UNIT  * ((_tileMap[i][j]-1) % 29);
								_rectangle.y = Constants.UNIT * int((_tileMap[i][j] - 1) / 29);
								_bmpMainTileMap1.bitmapData.copyPixels( Main.getTileSetBitmapData(), _rectangle, _point);

							}
							else{
								_point.x = (j - 96) * Constants.UNIT;
								_rectangle.x = _point.x;
								_bmpMainTileMap2.bitmapData.fillRect(_rectangle, 0x00FFFFFF);
								_rectangle.x = Constants.UNIT  *((_tileMap[i][j]-1) % 29);
								_rectangle.y = Constants.UNIT * int((_tileMap[i][j]-1) / 29);
								_bmpMainTileMap2.bitmapData.copyPixels( Main.getTileSetBitmapData(), _rectangle, _point);
								_bmpMainTileMap2.bitmapData.fillRect(_rectangle, 0x00FFFFFF);
							}							
						}
					}
				}
				//if hero is in screen bounds, replace it at the original place and reload the level
				_hero.x = _hero.originX;
				_hero.y = _hero.originY;
				_camera.x = _hero.x - Constants.CAMERA_LIM_WIDTH;
				
			}
			else{
				//if hero is out of screen bounds, it means that the level is loaded for the first time
				loadLevel();
				_hero.x = _hero.originX = Constants.UNIT;
				_hero.y = _hero.originY = 9 * Constants.UNIT;
				_camera.x = 0;
			}
			_hero.goingToRight = true;
			_hero.rest();
			_endMapX = Constants.MAP_WIDTH * Constants.UNIT;
			_endMapY = Constants.MAP_HEIGHT * Constants.UNIT;
		}
		
		
		/**
		 * The methods is an adaptation of a method written by Stephantasy (Meruvia)
		 * @param	aX x coord of the first point of the first segment
		 * @param	aY y coord of the first point of the first segment
		 * @param	bX x coord of the second point of the first segment
		 * @param	bY y coord of the second point of the first segment
		 * @param	cX x coord of the first point of the second segment
		 * @param	cY y coord of the first point of the second segment
		 * @param	dX x coord of the second point of the second segment
		 * @param	dY y coord of the second point of the second segment
		 * @return 	the intersection point or -1; -1 if there is no intersection
		 */
		private function getIntersection(aX:int, aY:int, bX:int, bY:int, cX:int, cY:int, dX:int, dY:int):Point{
			var interX:Number;
			var interY:Number;
			var inter:Point = new Point( -1, -1);
			if (aX == bX){
				if (cX == dX){
					return inter;
				}
				else{
					interX = aX;
					interY = ((((cY - dY) / (cX - dX)) * (aX - cX) + cY)as Number);
				}
			}
			else{
				if (cX == dX){
					interX = cX;
					interY = ((aY - bY) / (aX- bX))*(cX - aX) + aY;
				}
				else if ((aX == cX && aY == cY) || (aX == dX && aY == dY)){
					interX = aX;
					interY = aY;
				}
				else{
					var coeffCD:Number = (cY - dY) / (cX - dX);
					var coeffAB:Number = (aY - bY) / (aX - bX);
					var originCD:Number = cY - coeffCD * cX;
					interX = (((aY - coeffAB * aX)as Number) - originCD) / (coeffCD - coeffAB);
					interY = coeffCD * interX + originCD;
				}
			}
			if ((interX < aX && interX < bX) || (interX > aX && interX > bX) || (interX < cX && interX < dX) || (interX > cX && interX > dX) ||
				(interY < aY && interY < bY) || (interY > aY && interY > bY) || (interY < cY && interY < dY) || (interY > cY && interY > dY)){
					return inter;
			}
			inter.x = interX;
			inter.y = interY;
			return inter;
		}
		
		
		/**
		 * Returns the y coordinates of the start of the slope and its end
		 * @param	tileCode
		 * @return a Point with coordinates, null if it's not a slope
		 */
		private function getSlopeExtremities(tileCode:int):Point{
			switch(tileCode){
				case Constants.MOUNT_BOTTOM_LEFT:
					//from the bottom (0) to the middle of the tile (16)
					return new Point(0, 16);
				case Constants.MOUNT_BOTTOM_RIGHT:
					//from the middle (0) to the bottom of the tile (16)
					return new Point(16, 0);
				case Constants.MOUNT_LEFT_TOP:
					//etc.
					return new Point(16, 32);
				case Constants.MOUNT_TOP_RIGHT:
					return new Point(32, 16);
				case Constants.ROOF_LEFT:
					return new Point(0, 32);
				case Constants.ROOF_RIGHT:
					return new Point(32, 0);
				default:
					//if the code doesn't match, it's not a slope, so return null
					return null;
			}
		}
		
		/**
		 * The main algorithm for collisions with slopes
		 * Adaptation of the code found on meruvia.net
		 */
		private function checkSlope():void{
			
			var tileWhereIAm:int 	= 0; //the code of the tile where the hero is
			var tileWhereIGo:int 	= 0; //the code of the tile where the hero goes
			var tileAboveDest:int 	= 0; //the code of the tile which is just above the its destination
			var tileBelowDest:int 	= 0; //the code of the tile which is just above the its destination
			var diagOffset:int 		= 0; //with slopes, the hero has to go through the tile, but not entirely
			var yDest:int 			= 0;//where we will replace the hero finally
			var check:Boolean 		= true;
			var reset:Boolean 		= false;
			
			if (!_hero.wasGrounded){
				_hero.wasOnSlope = 0;
			}
			
			const iniX:int = _hero.exX + _hero.width / 2; 	//position of the hero on X axis
			const iniY:int = _hero.exY + _hero.height - 1; 	//position of the hero on Y axis
			const tileIniX:int = iniX / Constants.UNIT;		//the index of the tile on X axis
			const tileIniY:int = iniY / Constants.UNIT;		//the index of the tile on Y axis
			const destX:int = iniX + _hero.exSpeedX;		//the same thing with the destination
			const destY:int = iniY + 1 + _hero.exSpeedY;
			const tileDestX:int = destX / Constants.UNIT;
			const tileDestY:int = destY / Constants.UNIT;
			
			//We check if the hero is on a slope, if he goes to a slope, if there is a slope abode its destination or below its destination
			if (isTileSlope(tileIniY, tileIniX)){
				tileWhereIAm = _tileMap[tileIniY][tileIniX];
			}			
			if(isTileSlope(tileDestY, tileDestX)){
				tileWhereIGo = _tileMap[tileDestY][tileDestX];
			}
			if(isTileSlope(tileDestY - 1, tileDestX)){
				tileAboveDest = _tileMap[tileDestY - 1][tileDestX];
			}
			else if (isTileSlope(tileDestY + 1, tileDestX)){
				tileBelowDest = _tileMap[tileDestY + 1][tileDestX];
			}
			
			var p:Point;
			var yPos:int;
			if (tileWhereIGo > 0){
				if ((p = getSlopeExtremities(tileWhereIGo)) != null){
					//if it's a slope, calculate the offset
					yPos = ((p.y - p.x) / 32) * (destX - tileDestX * Constants.UNIT) + p.x;//yPos = f(x) = ax + b, 
					//where b is known and a is the variation between the start and the end of the tile divided by the tile's dimension
					diagOffset = Constants.UNIT - (yPos > 31 ? 31 : yPos);
					yDest = tileDestY;
					_hero.wasOnSlope = tileWhereIGo;
					check = false;
				}
				else{
					return;
				}
				
			}
			else if (tileAboveDest > 0){
				//same thing here
				if ((p = getSlopeExtremities(tileAboveDest)) != null){
					yPos = ((p.y - p.x) / 32) * (destX - tileDestX * Constants.UNIT) + p.x;
					diagOffset = Constants.UNIT - (yPos > 31 ? 31 : yPos);
					yDest = tileDestY - 1;
					_hero.wasOnSlope = tileAboveDest;
					check = false;
				}
				else{
					return;
				}
			}
			else if (tileWhereIAm > 0){
				//we have to make the difference between a grounded character or a jumping character
				if (!_hero.wasGrounded){
					//jumping. We search intersection to replace the hero
					if ((p = getSlopeExtremities(tileWhereIAm)) == null){
						_point.x = _point.y = 0;
					}
					else{
						_point.x = p.x;
						_point.y = p.y;
					}
					p = getIntersection(iniX, iniY, destX, destY, tileIniX * Constants.UNIT, 
						Constants.UNIT * (tileIniY + 1) - _point.x, (tileIniX + 1) * Constants.UNIT, (tileIniY + 1) * Constants.UNIT - _point.y);
					if (p.x <= -1){
						_hero.x = _hero.exX;
						_hero.speedX = _hero.exSpeedX;
						return;
					}
					_hero.x = p.x - _hero.width / 2;
					_hero.speedX = 0;
					_hero.y = p.y - _hero.height;
					if (_hero.speedY > 0){
						_hero.speedY = 0;
						_hero.grounded = true;
					}
					_hero.wasOnSlope = tileWhereIAm;
					return;
				}
				else{
					if (tileBelowDest > 0){
						//same thing than previously
						if ((p = getSlopeExtremities(tileBelowDest)) != null){
							var xPos:int = destX - tileIniX * Constants.UNIT;
							xPos = _hero.exSpeedX > 0 ? xPos - Constants.UNIT : xPos + Constants.UNIT;
							yPos = ((p.y - p.x) / 32) * xPos + p.x;
							diagOffset = Constants.UNIT - (yPos > 31 ? 31 : yPos);
							yDest = tileDestY + 1;
							_hero.wasOnSlope = tileWhereIAm;
							check = false;
						}
					}
				}
			}
			
			//finally, place the hero at the right place
			if (_hero.wasOnSlope > 0 && check){
				//place it on the tile where we are
				if ((_hero.exSpeedX > 0 && _hero.wasOnSlope == Constants.MOUNT_LEFT_TOP) || (_hero.exSpeedX < 0 && _hero.wasOnSlope == Constants.MOUNT_TOP_RIGHT) ||
				(_hero.exSpeedX > 0 && _hero.wasOnSlope == Constants.ROOF_LEFT) || (_hero.exSpeedX < 0 && _hero.wasOnSlope == Constants.ROOF_RIGHT)){
					yDest = tileIniY;
				}
				else{
					//or the tile below
					if ((_hero.exSpeedX > 0 && _hero.wasOnSlope == Constants.MOUNT_BOTTOM_RIGHT) || (_hero.exSpeedX < 0 && _hero.wasOnSlope == Constants.MOUNT_BOTTOM_LEFT) ||
					(_hero.exSpeedX > 0 && _hero.wasOnSlope == Constants.ROOF_RIGHT) || (_hero.exSpeedX < 0 && _hero.wasOnSlope == Constants.ROOF_LEFT)){
						yDest = tileIniY + 1;
					}
				}
				reset = true; // because he was on a slope and he's not right now
			}
			if (_hero.wasOnSlope > 0){
				if (!_hero.wasGrounded){
					//let him fall
					if (((yDest * Constants.UNIT + diagOffset) - iniY) > _hero.exSpeedY){
						_hero.y = _hero.exY;
						_hero.speedY = _hero.exSpeedY;
						_hero.grounded = false;
						return;
					}
				}
				//else place the hero and update its position and velocity
				_hero.x = _hero.exX;
				_hero.speedX = _hero.exSpeedX;
				_hero.y = yDest * Constants.UNIT + diagOffset - _hero.height;
				_hero.speedY = 0;
				_hero.grounded = true;
				if 	(reset){
					_hero.wasOnSlope = 0;
				}
			}
		}
		
		/**
		 * Checks if a tile is a slope
		 * @param	y coordinate of the tile in the tiled map
		 * @param	x coordinate of the tile in the tiled map
		 * @return true if y and x and valid coordinates [0, 15] and [0, 199] and if it's a slope
		 */
		private function isTileSlope(y:int, x:int):Boolean {
			return getTileCode(y, x) != -1 &&(_tileMap[y][x] == Constants.MOUNT_BOTTOM_LEFT || _tileMap[y][x] == Constants.MOUNT_BOTTOM_RIGHT ||
			_tileMap[y][x] == Constants.MOUNT_LEFT_TOP || _tileMap[y][x] == Constants.MOUNT_TOP_RIGHT || _tileMap[y][x] == Constants.ROOF_LEFT || _tileMap[y][x] == Constants.ROOF_RIGHT);
		}
	}
}