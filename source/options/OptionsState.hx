package options;

#if desktop
import Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.FlxSubState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSave;
import haxe.Json;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import Controls;

using StringTools;

class OptionsState extends MusicBeatState
{
	var options:Array<String> = ['Note Colors', 'Controls', 'Adjust Delay and Combo', 'Visuals and UI', 'Preferences', "Change Save Data"];
	var preferences:Array<String> = ['Gameplay', "Graphics", "Back"];
	var preferencesMode:Bool = false;
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;

	override public function new(preferencesMode:Bool = false, fromPref:Bool = false) {
		this.preferencesMode = preferencesMode;
		if (fromPref && !preferencesMode)
			curSelected = options.indexOf("Preferences");
		super();
	}

	function openSelectedSubstate(label:String) {
		#if android
		removeVirtualPad();
		#end
		switch(label) {
			case 'Note Colors':
				openSubState(new options.NotesSubState());
			case 'Controls':
				openSubState(new options.ControlsSubState());
			case 'Graphics':
				openSubState(new options.GraphicsSettingsSubState());
			case 'Visuals and UI':
				openSubState(new options.VisualsUISubState());
			case 'Gameplay':
				openSubState(new options.GameplaySettingsSubState());
			case 'Adjust Delay and Combo':
				LoadingState.loadAndSwitchState(new options.NoteOffsetState());
			case "Change Save Data":
				MusicBeatState.switchState(new SaveSelectState(false, 0xff71f8fd, true));
			case "Back":
				MusicBeatState.switchState(new OptionsState(false, true));
		}
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	override function create() {
		#if desktop
		DiscordClient.changePresence("Options Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFea71fd;
		bg.updateHitbox();

		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		if (preferencesMode) options = preferences;

		for (i in 0...options.length)
		{
			var optionText:Alphabet = new Alphabet(0, 0, options[i], true);
			optionText.screenCenter();
			optionText.ID = i;
			optionText.y += (100 * (i - (options.length / 2))) + 50;
			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(0, 0, '>', true);
		add(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<', true);
		add(selectorRight);

		changeSelection();
		ClientPrefs.saveSettings();

		if(PauseSubState.isInPause == true) FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.7);

		#if android
		addVirtualPad(UP_DOWN, A_B_E);
		#end
			
		super.create();
	}

	override function closeSubState() {
		super.closeSubState();
		removeVirtualPad();
		addVirtualPad(UP_DOWN, A_B_C);
		ClientPrefs.saveSettings();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (controls.UI_UP_P)
			changeSelection(-1);

		if (controls.UI_DOWN_P)
			changeSelection(1);

		if (controls.BACK) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			
			if(PauseSubState.isInPause == false) MusicBeatState.switchState(preferencesMode ? new OptionsState(false, true) : new MainMenuState());
			else{
				PauseSubState.isInPause = false;
				LoadingState.loadAndSwitchState(new PlayState());
			}
		}

		if (controls.ACCEPT) {
			if (curSelected == options.indexOf("Preferences"))
				MusicBeatState.switchState(new OptionsState(true, false));
			else
				openSelectedSubstate(options[curSelected]);
		}
		
		if (_virtualpad.buttonE.justPressed){
			MusicBeatState.switchState(new android.AndroidControlsMenu());
	        }
	}
	
	function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0) {
				item.alpha = 1;
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
}
