import flixel.addons.transition.FlxTransitionableState;
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
import flixel.effects.FlxFlicker;
import Controls;

using StringTools;

class SaveSelectState extends MusicBeatState
{
	public static var numberOfSaveSlots:Int = 6; //CHANGE THIS TO CHANGE SAVE NUMBER
	var options:Array<Array<String>> = [];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var curSelected(default, set):Int = 0;
	private function set_curSelected(v:Int) {
		if (curSelected != v)
			FlxG.sound.play(Paths.sound('scrollMenu'));
		if (!selectedSmth)
		{
			curSelected = v;
			changeSelection();
		}
		return v;
	}
	public static var menuBG:FlxSprite;

	function selectSaveData() {
        FlxTransitionableState.skipNextTransIn = false;
        FlxTransitionableState.skipNextTransOut = false;
		
		ClientPrefs.changeSaveData(curSelected + 1);
		Highscore.load();
		MusicBeatState.switchState((!fromOptionsMenu ? new MainMenuState() : new options.OptionsState()));
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	var fromDeleteMenu:Bool = false;
	var currentBgColor:FlxColor;
	var fromOptionsMenu:Bool = false;

	override public function new(fromDeleteMenu:Bool = false, currentBgColor:FlxColor = 0xff71f8fd, fromOptionsMenu:Bool = false) {
		this.fromDeleteMenu = fromDeleteMenu;
		this.currentBgColor = currentBgColor;
		this.fromOptionsMenu = fromOptionsMenu;
		super();
	}

	var centerPos:Array<Dynamic> = [];

	var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
	override function create() {
		MouseCursors.loadCursor("nintendo_normal");
		for (i in 1...numberOfSaveSlots + 1)
			options.push(['Save Data $i', Language.getString("saveData") + ' $i']);
		options.push(["Reset Save Data", Language.getString("resetData")]);
		#if desktop
		DiscordClient.changePresence("Save Select", null);
		#end

		if (fromDeleteMenu)
			FlxTween.color(bg, 0.2, currentBgColor, 0xff71f8fd, {ease: FlxEase.smootherStepOut});
		else
			bg.color = 0xff71f8fd;
		bg.updateHitbox();

		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (i in 0...options.length)
		{
			var optionText:Alphabet = new Alphabet(0, 0, options[i][1], true);
			optionText.screenCenter();
			centerPos.push([optionText.x, optionText.y]);
            optionText.ID = i;
			optionText.y += (100 * (i - (options.length / 2))) + 50;
			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(0, 0, '>', true);
		add(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<', true);
		add(selectorRight);

		changeSelection();

		if (!fromDeleteMenu && !fromOptionsMenu) FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.7);

		#if android
                addVirtualPad(NONE, B);
                #end
		super.create();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		for (alph in grpOptions.members)
		{
			if (CoolUtil.mouseOverlaps(alph, true, false, 0, 0, alph.camera) && !selectedSmth)
				curSelected = alph.ID;
		}

		if (fromOptionsMenu && (controls.BACK && !selectedSmth))
		{
			MusicBeatState.switchState(new options.OptionsState());
		}

		if (FlxG.mouse.justPressed && !selectedSmth) {
            selectedSmth = true;
			if (options[curSelected][0] == "Reset Save Data")
            {
                FlxTransitionableState.skipNextTransIn = true;
                FlxTransitionableState.skipNextTransOut = true;
				FlxTween.cancelTweensOf(bg);
                MusicBeatState.switchState(new SaveDeleteState(bg.color, fromOptionsMenu));
            } else {
				FlxG.sound.play(Paths.sound('confirmMenu'));
				FlxTween.tween(selectorLeft, {alpha: 0}, 0.2, {ease: FlxEase.quadOut, onComplete: function(twn:FlxTween) {
					selectorLeft.kill();
				}});
				FlxTween.tween(selectorRight, {alpha: 0}, 0.2, {ease: FlxEase.quadOut, onComplete: function(twn:FlxTween) {
					selectorRight.kill();
				}});
                grpOptions.forEach(function(spr:Alphabet){
                   if (spr.ID == curSelected) {
						FlxTween.tween(FlxG.camera, {zoom: 1.3}, 0.3, {ease: FlxEase.expoInOut, startDelay: 0.3});
						FlxTween.tween(spr, {x: centerPos[curSelected][0], y: centerPos[curSelected][1]}, 0.6, {ease: FlxEase.expoInOut});
                    	FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
                   		{
			       	    	selectSaveData();
                		});
                   	} else {
						FlxTween.tween(spr, {alpha: 0}, 0.2, {
							ease: FlxEase.quadOut,
							onComplete: function(twn:FlxTween)
							{
								spr.kill();
							}
						});
					}
                });
            }
		}
	}
	
    var selectedSmth:Bool = false;

	function changeSelection() {
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
	}
}

class SaveDeleteState extends MusicBeatState
{
	var options:Array<Array<String>> = [];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var curSelected(default, set):Int = 0;
	private function set_curSelected(v:Int) {
		if (curSelected != v)
			FlxG.sound.play(Paths.sound('scrollMenu'));
		if (!selectedSmth)
		{
			curSelected = v;
			changeSelection();
		}
		return v;
	}
	public static var menuBG:FlxSprite;

	function selectSaveData() {
		ClientPrefs.resetSaveData(curSelected + 1);
        FlxTransitionableState.skipNextTransIn = true;
        FlxTransitionableState.skipNextTransOut = true;
        MusicBeatState.switchState(new SaveSelectState(true, bg.color));
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;
	var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));

	var currentBgColor:FlxColor;
	var fromOptionsMenu:Bool = false;

	override public function new(currentBgColor:FlxColor, fromOptionsMenu:Bool = false) {
		this.currentBgColor = currentBgColor;
		this.fromOptionsMenu = fromOptionsMenu;
		super();
	}

	override function create() {
		for (i in 1...SaveSelectState.numberOfSaveSlots + 1)
			options.push(['Reset Save Data $i', Language.getString("resetData") + ' $i']);
		options.push(["Back", Language.getString("back")]);
		FlxTween.color(bg, 0.2, currentBgColor, 0xfffd7171, {ease: FlxEase.smootherStepOut});
		bg.updateHitbox();

		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (i in 0...options.length)
		{
			var optionText:Alphabet = new Alphabet(0, 0, options[i][1], true);
			optionText.screenCenter();
            optionText.ID = i;
			optionText.y += (100 * (i - (options.length / 2))) + 50;
			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(0, 0, '>', true);
		add(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<', true);
		add(selectorRight);

		curSelected = SaveSelectState.numberOfSaveSlots;

		changeSelection();

		super.create();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		for (alph in grpOptions.members)
		{
			if (CoolUtil.mouseOverlaps(alph, true, false, 0, 0, alph.camera) && !selectedSmth)
				curSelected = alph.ID;
		}

		if (controls.BACK) {
			FlxTransitionableState.skipNextTransIn = true;
            FlxTransitionableState.skipNextTransOut = true;
			FlxTween.cancelTweensOf(bg);
        	MusicBeatState.switchState(new SaveSelectState(true, bg.color, fromOptionsMenu));
		}

		if (FlxG.mouse.justPressed && !selectedSmth) {
            selectedSmth = true;
            if (options[curSelected][0] == "Back")
            {
                FlxTransitionableState.skipNextTransIn = true;
                FlxTransitionableState.skipNextTransOut = true;
				FlxTween.cancelTweensOf(bg);
                MusicBeatState.switchState(new SaveSelectState(true, bg.color, fromOptionsMenu));
            } else {
                grpOptions.forEach(function(spr:Alphabet){
                   if (spr.ID == curSelected) {
                     FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
                     {
			              selectSaveData();
                       });
                   }
                });
            }
		}
	}
	
    var selectedSmth:Bool = false;

	function changeSelection() {
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
	}
}
