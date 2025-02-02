package;

import flixel.graphics.FlxGraphic;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;
import lime.app.Application;
#if desktop
import Discord.DiscordClient;
#end
// crash handler stuff
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;

using StringTools;

class Main extends Sprite
{
	var game = {
		width: 1280, // WINDOW width
		height: 720, // WINDOW height
		initialState: TitleState, // initial game state
		zoom: -1.0, // game state bounds
		framerate: 60, // default framerate
		skipSplash: true, // if the default flixel splash screen should be skipped
		// #if debug //ivan code
		// skipSplash: false, // if the default flixel splash screen should be skipped
		// #end
		// vomit fullscreen
		startFullscreen: false // fullscreen sucks booty //extremely common ivan L
	};

	public static var noLeaksMode:Bool = true;
	public static var fpsVar:FPS;
	public static var fpsText(default, set):String = "FPS";
	public static var memoryText(default, set):String = "Memory";
	static var oldFpsText:String = "FPS";
	static var oldMemoryText:String = "Memory";

	public static function set_fpsText(v:String):String
	{
		oldFpsText = fpsText;
		fpsText = v;
		return v;
	}

	public static function set_memoryText(v:String):String
	{
		oldMemoryText = memoryText;
		memoryText = v;
		return v;
	}

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void
	{
		WindowsAPI.setDarkMode(true);

		BetterLogs.init();
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	private function setupGame():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (game.zoom == -1.0)
		{
			var ratioX:Float = stageWidth / game.width;
			var ratioY:Float = stageHeight / game.height;
			game.zoom = Math.min(ratioX, ratioY);
			game.width = Math.ceil(stageWidth / game.zoom);
			game.height = Math.ceil(stageHeight / game.zoom);
		}

		#if android
		game.width = 1280;
		game.height = 720;
		game.zoom = 1;
		#end
			
		SUtil.doTheCheck();
		
		hxvlc.util.Handle.init();
		ClientPrefs.loadDefaultKeys();
		//Application.current.window.alert('Test', '01');
		var game = new FlxGame(game.width, game.height, game.initialState, #if (flixel < "5.0.0") game.zoom, #end game.framerate, game.framerate, game.skipSplash, game.startFullscreen);
		//addChild(new FlxGame(game.width, game.height, game.initialState, #if (flixel < "5.0.0") game.zoom, #end game.framerate, game.framerate, game.skipSplash, game.startFullscreen));

		@:privateAccess
		game._customSoundTray = FunkinSoundTray;

		addChild(game);
		//Application.current.window.alert('Test', '02');

		//lime.utils.Log.throwErrors = false; // prevent shader crash erros jumpscare (i can see you FlxDrawQuadsItem)

		#if mobile
		fpsVar = new FPS(5, 3, 0xFFFFFF);
		addChild(fpsVar);
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		if (fpsVar != null)
		{
			fpsVar.visible = ClientPrefs.showFPS;
		}
		#end
		//Application.current.window.alert('Test', '03');

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end

		SUtil.gameCrashCheck();
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);

		#if android
		FlxG.android.preventDefaultKeys = [BACK]; 
		#end
			
		#if DISCORD_ALLOWED
		DiscordClient.prepare();
		#end

		// shader coords fix
		FlxG.signals.gameResized.add(function(w, h)
		{
			if (FlxG.cameras != null)
			{
				for (cam in FlxG.cameras.list)
					@:privateAccess {
					if (cam != null && cam._filters != null)
						resetSpriteCache(cam.flashSprite);
				}
			}
			if (FlxG.game != null)
				resetSpriteCache(FlxG.game);
			if (FlxG.stage != null)
				resetSpriteCache(FlxG.stage);
		});
	
		//Application.current.window.alert('Test', '04');
	}

	static function resetSpriteCache(sprite:Dynamic):Void
	{
		@:privateAccess {
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}

	// Code was entirely made by sqirra-rng for their fnf engine named "Izzy Engine", big props to them!!!
	// very cool person for real they don't get enough credit for their work
	function onCrash(e:UncaughtErrorEvent):Void
	{
		var errMsg:String = "";
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		dateNow = dateNow.replace(" ", "_");
		dateNow = dateNow.replace(":", "'");

		path = SUtil.getPath() + "crash/" + "PsychEngine_" + dateNow + ".txt";

		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += file + " (line " + line + ")\n";
				default:
					Sys.println(stackItem);
			}
		}

		errMsg += "\nUncaught Error: "
			+ e.error
			+ "\nPlease report this error to the GitHub page: https://github.com/ShadowMario/FNF-PsychEngine\n\n> Crash Handler written by: sqirra-rng";

		if (!FileSystem.exists(SUtil.getPath() + "crash/"))
			FileSystem.createDirectory(SUtil.getPath() + "crash/");

		File.saveContent(path, errMsg + "\n");

		Sys.println(errMsg);
		Sys.println("Crash dump saved in " + Path.normalize(path));

		Application.current.window.alert(errMsg, "Error!");
		#if desktop
		DiscordClient.shutdown();
		#end
		Sys.exit(1);
	}
}
