package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

class FlashingState extends MusicBeatState
{
	public static var leftState:Bool = false;

	var warnText:FlxText;
	override function create()
	{
		super.create();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg); //what does this even do //it adds the bg like it says

		warnText = new FlxText(0, 0, FlxG.width,
			"Safety First!\n
			This mod contains flashing lights!\n
			This may effect users who are photosensitive.\n
			Press Enter/Return to disable flashing lights,\n
			and Escape to dismiss this message.",
			32);
		//			Allow adequate room around you during gameplay.",
		warnText.setFormat("Delfino", 32, FlxColor.WHITE, CENTER);
		warnText.screenCenter(Y);
		add(warnText);
		
		//Ivan, please, never code again https://cdn.discordapp.com/attachments/1045997810077671495/1108360738738798662/image.png
		//I fixed your code and it STILL DIDNT DO ANYTHING
		//var bg1:FlxSprite = new FlxSprite(0, FlxG.height * 0.52).loadGraphic(Paths.image('screens/TITLEPIC1'));
		//bg1.scale.x = 0.67;
		//bg1.scale.y = 0.67;
		//bg1.updateHitbox();
		//bg1.screenCenter();
		//bg1.antialiasing = ClientPrefs.globalAntialiasing;
		//add(bg1);

		//var black:FlxSprite = new FlxSprite(0, FlxG.height * 0.52).loadGraphic(Paths.image('screens/TITLEPIC1'));
		//black.scale.x = 0.67;
		//black.scale.y = 0.67;
		//black.updateHitbox();
		//black.screenCenter();
		//black.alpha = 0;
		//sprite.color = 0x000000;
		//add(black);
		
		//    bg1 = new FlxSprite(243, 2).loadGraphic(Paths.image('screens/TITLEPIC1'));
		//bg1.scale.x = 0.67;
		//bg1.scale.y = 0.67;
		//bg1.updateHitbox();
		//bg1.screenCenter();
    
		//bg2 = new FlxSprite(243, 2).loadGraphic(Paths.image('screens/TITLEPIC2'));
		//bg2.scale.x = 0.67;
		//bg2.scale.y = 0.67;
		//bg2.updateHitbox();
		//bg2.screenCenter();
		
		//unused code that might work but i didnt wanna risk it
		//bro I will fucking smite you
		//too bad
		
		#if android
		addVirtualPad(NONE, A_B);
		#end
	}
	
	override function update(elapsed:Float)
	{
		if(!leftState) {
			var back:Bool = controls.BACK;
			if (controls.ACCEPT || back) {
				leftState = true;
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				if(!back) {
					ClientPrefs.flashing = false;
					ClientPrefs.saveSettings();
					FlxG.sound.play(Paths.sound('confirmMenu'));
					FlxFlicker.flicker(warnText, 1, 0.1, false, true, function(flk:FlxFlicker) { //old //BRO YOU UNCOMMENTED A { I WILL FUCKING SMITE YOU
					
					//FlxTween.color(bg1, 1, FlxColor.RED, FlxColor.CYAN, //planned but too hard for me to use -SIG7
					//{type: FlxTweenType.ONESHOT, ease: FlxEase.sineInOut});
					
					        //FlxTween.tween(black, {alpha: 1}, 0); //this was painful to code

						new FlxTimer().start(0.5, function (tmr:FlxTimer) {
							MusicBeatState.switchState(new TitleState());
						});
					});
				} else {
					FlxG.sound.play(Paths.sound('cancelMenu'));
					FlxTween.tween(warnText, {alpha: 0}, 1, {
						onComplete: function (twn:FlxTween) {
							MusicBeatState.switchState(new TitleState());
						}
					});
				}
			}
		}
		super.update(elapsed);
	}
}
