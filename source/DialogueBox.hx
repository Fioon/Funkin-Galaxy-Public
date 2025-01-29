 package;

import flixel.system.FlxSound;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.text.FlxTypeText;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup;
import flixel.input.FlxKeyManager;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import openfl.display.BitmapData;
import openfl.media.Sound;

using StringTools;

class DialogueBox extends FlxSpriteGroup
{
	var box:FlxSprite;

	var curCharacter:String = '';
	var curAnim:String = '';

	//var dialogue:Alphabet;
	var dialogueList:Array<String> = [];

	var skipText:FlxText;
	var noTextText:FlxText;


	// SECOND DIALOGUE FOR THE PIXEL SHIT INSTEAD???
	var swagDialogue:FlxTypeText;

	var dropText:FlxText;
	var cutsceneImage:FlxSprite;
	var fadeImage:FlxSprite;
	var sound:FlxSound;

	public var finishThing:Void->Void;
	private var curSong:String = "";

	var icons:FlxSprite;

	var blackShit:FlxSprite;

	public function new(talkingRight:Bool = true, ?dialogueList:Array<String>)
	{
		super();

		switch (Paths.formatToSongPath(curSong))
		{
			case 'senpai':
				FlxG.sound.playMusic(Paths.music('Lunchbox'), 0);
				FlxG.sound.music.fadeIn(1, 0, 0.8);
			case 'thorns':
				FlxG.sound.playMusic(Paths.music('LunchboxScary'), 0);
		}

		blackShit = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
			-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
		blackShit.scrollFactor.set();
		add(blackShit);

		cutsceneImage = new FlxSprite(0, 0);
		cutsceneImage.visible = false;
		add(cutsceneImage);

		fadeImage = new FlxSprite(0, 0);
		fadeImage.visible = false;
		add(fadeImage);

		box = new FlxSprite(-20, 45);
		
		box.frames = Paths.getSparrowAtlas('dialogue/dialoguebox', 'shared');
		box.animation.addByPrefix('normalOpen', 'Speech Bubble Middle Open', 24, false);
		box.animation.addByPrefix('normal', 'speech bubble middle', 24, false);
		//box.setGraphicSize(Std.int(box.width * 6));
		box.y += 330;

		this.dialogueList = dialogueList;

		box.animation.play('normalOpen');
		box.updateHitbox();
		box.screenCenter(X);
		box.alpha = 0.8;
		add(box);

		icons = new HealthIcon('bf', false);
		add(icons);
		icons.visible = false;


		if (!talkingRight)
		{
			// box.flipX = true;
		}

		skipText = new FlxText(5, 695, 640, "Press SPACE to skip.\n", 40);
		skipText.scrollFactor.set(0, 0);
		skipText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		skipText.borderSize = 2;
		skipText.borderQuality = 1;
		add(skipText);

		noTextText = new FlxText(640, 695, 640, "Press ENTER to continue.\n", 40);
		noTextText.scrollFactor.set(0, 0);
		noTextText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, FlxTextAlign.RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		noTextText.borderSize = 2;
		noTextText.borderQuality = 1;
		noTextText.alpha = 0;
		add(noTextText);

		dropText = new FlxText(282, 502, Std.int(FlxG.width * 0.6), "", 32);
		dropText.font = 'Delfino';
		dropText.color = 0xFF3c3c3c;
		dropText.alpha = 0.5;
		add(dropText);

		swagDialogue = new FlxTypeText(280, 500, Std.int(FlxG.width * 0.6), "", 32);
		swagDialogue.font = 'Delfino';
		swagDialogue.color = 0xFF3c3c3c;
		//swagDialogue.sounds = [FlxG.sound.load(Paths.sound('pixelText'), 0.6)];
		add(swagDialogue);

		//dialogue = new Alphabet(0, 80, "", false, true);
		// dialogue.x = 90;
		// add(dialogue);
	}

	var dialogueOpened:Bool = false;
	var dialogueStarted:Bool = false;

	var shake:Bool = false;

	override function update(elapsed:Float)
	{
		if (shake == true)
			{
				cutsceneImage.x = FlxG.random.int(-20, 20);
				cutsceneImage.y = FlxG.random.int(-20, 20);
			}

		// HARD CODING CUZ IM STUPDI
		if (PlayState.SONG.song.toLowerCase() == 'roses')

		if (PlayState.SONG.song.toLowerCase() == 'thorns')
		{
			swagDialogue.color = FlxColor.WHITE;
			dropText.color = FlxColor.BLACK;
		}

		dropText.text = swagDialogue.text;

		if (box.animation.curAnim != null)
		{
			if (box.animation.curAnim.name == 'normalOpen' && box.animation.curAnim.finished)
			{
				box.animation.play('normal');
				dialogueOpened = true;
			}
		}

		if (dialogueOpened && !dialogueStarted)
		{
			startDialogue();
			dialogueStarted = true;
		}

		#if android
                var justTouched:Bool = false;

		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				justTouched = true;
			}
		}
		#end
			
		if(FlxG.android.justReleased.BACK && !isEnding){

			isEnding = true;
			endDialogue();

		}

		if (justTouched && dialogueStarted == true)
		{
			//remove(dialogue);
				
			FlxG.sound.play(Paths.sound('clickText'), 0.8);

			if (dialogueList[1] == null && dialogueList[0] != null)
			{
				if (!isEnding)
				{
					isEnding = true;
					endDialogue();
					
				}
			}
			else
			{
				dialogueList.remove(dialogueList[0]);
				startDialogue();
			}
		}
		
		super.update(elapsed);
	}

	var isEnding:Bool = false;
	var firstimage:Bool = true;

	function endDialogue()
	{
				if (this.sound != null) this.sound.stop();

				if (PlayState.endingcutscenefade == false)
					{
						FlxG.sound.music.fadeOut(2, 0);

				new FlxTimer().start(0.2, function(tmr:FlxTimer)
					{
						FlxTween.tween(box, {alpha: 0}, 2, {ease: FlxEase.circOut});
						FlxTween.tween(cutsceneImage, {alpha: 0}, 2, {ease: FlxEase.circOut});
						FlxTween.tween(swagDialogue, {alpha: 0}, 2, {ease: FlxEase.circOut});
						FlxTween.tween(icons, {alpha: 0}, 2, {ease: FlxEase.circOut});
						FlxTween.tween(dropText, {alpha: 0}, 2, {ease: FlxEase.circOut});
						FlxTween.tween(skipText, {alpha: 0}, 2, {ease: FlxEase.circOut});
						FlxTween.tween(blackShit, {alpha: 0}, 2, {ease: FlxEase.circOut});
					}, 5);
	
				new FlxTimer().start(2, function(tmr:FlxTimer)
				{
				finishThing();
				kill();
				FlxG.sound.music.stop();
				});
					}
				else
					{
						finishThing();
						kill();
						//FlxG.sound.music.stop();
					}
	}

	var whitehere = false;
	var white:FlxSprite;

	function startDialogue():Void
	{
		var setDialogue = false;
		var skipDialogue = false;
		cleanDialog();
		// var theDialog:Alphabet = new Alphabet(0, 70, dialogueList[0], false, true);
		// dialogue = theDialog;
		// add(theDialog);

		// swagDialogue.text = ;
		swagDialogue.resetText(dialogueList[0]);
		swagDialogue.start(0.04, true);

		switch (curCharacter)
		{
			case "bg":
				skipDialogue = true;

				if (whitehere == true)
				{
				whitehere = false;
				FlxTween.tween(white, {alpha: 0}, 1, {
				onComplete: function(twn:FlxTween)
				{
					remove(white);
				}
				});	
				}
				switch(curAnim){
					case "hide":
						cutsceneImage.visible = false;
						cutsceneImage.alpha = 0;
					case "white":
					white = new FlxSprite(0, 0).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.WHITE);
					white.scrollFactor.set();
					white.alpha = 0;
					remove(box);
				remove(swagDialogue);
				remove(dropText);
					add(white);	
					add(box);
					add(dropText);
				add(swagDialogue);
					whitehere = true;
					FlxTween.tween(white, {alpha: 1}, 1);
					case "flash":
						white = new FlxSprite(0, 0).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.WHITE);
					white.scrollFactor.set();
					add(white);	
					FlxTween.tween(white, {alpha: 0}, 0.5, {
				onComplete: function(twn:FlxTween)
				{
					remove(white);
				}
				});
					case "shake":
					cutsceneImage.width = 1.2;
					shake = true;
					new FlxTimer().start(0.25, function(tmr:FlxTimer)
					{
					shake = false;
					cutsceneImage.width = 1;
					cutsceneImage.x = 0;
					cutsceneImage.y = 0;
					}); 
					default:
					if (firstimage == true)
				{
					firstimage = false;
					cutsceneImage.visible = true;
					cutsceneImage.alpha = 0;
					cutsceneImage.loadGraphic(BitmapData.fromFile("assets/shared/images/dialogue/images/" + curAnim + ".png"));
					FlxTween.tween(cutsceneImage, {alpha: 1}, 1, {ease: FlxEase.circOut});
				}
				else
				{
					cutsceneImage.visible = true;
					cutsceneImage.loadGraphic(BitmapData.fromFile("assets/shared/images/dialogue/images/" + curAnim + ".png"));
					FlxTween.tween(cutsceneImage, {alpha: 1}, 1, {ease: FlxEase.circOut});
				}
				}

			case "fade":
				skipDialogue = true;
				fadeImage.visible = true;
				fadeImage.loadGraphic(BitmapData.fromFile("assets/shared/images/dialogue/images/" + curAnim + ".png"));
				FlxTween.tween(fadeImage, {alpha: 0}, 1, {
				onComplete: function(twn:FlxTween)
				{
					fadeImage.visible = false;
					fadeImage.alpha = 1;
				}
				});

			case "music":
				skipDialogue = true;
				switch(curAnim){
					case "stop":
						FlxG.sound.music.volume = 0;
					case "fadeIn":
						FlxG.sound.music.fadeIn(1, 0, 0.8);
					default:
						FlxG.sound.playMusic(Sound.fromFile("assets/shared/images/dialogue/music/" + curAnim + ".ogg"), Std.parseFloat(dialogueList[0]));
						FlxG.sound.music.volume = 0;
				}

			case "sound":
				skipDialogue = true;
				if (this.sound != null) this.sound.stop();
				sound = new FlxSound().loadEmbedded(Sound.fromFile("assets/shared/images/dialogue/sounds/" + curAnim + ".ogg"));
				sound.play();
				
			case "stopsound":
				skipDialogue = true;
				this.sound.stop();

			case "narrator":
				if (curAnim == 'default')
					{
						remove(icons);
						changeposition();
						changeSound('pixelText',0.6);
					}
				else
					{
						remove(icons);
						icons = new HealthIcon(curAnim, false);
						changeposition();
						add(icons);
						changeSound(curAnim + 'text',0.5);
					}

			case "hidetextbox":
				if (curAnim == 'true')
					{
						FlxTween.tween(box, {alpha: 0}, 0.3, {ease: FlxEase.circOut});
						FlxTween.tween(swagDialogue, {alpha: 0}, 0.3, {ease: FlxEase.circOut});
						FlxTween.tween(dropText, {alpha: 0}, 0.3, {ease: FlxEase.circOut});
						FlxTween.tween(noTextText, {alpha: 1}, 0.3, {ease: FlxEase.circOut});
						FlxTween.tween(icons, {alpha: 0}, 0.3, {ease: FlxEase.circOut});
					}
				else if (curAnim == 'false')
					{
						skipDialogue = true;
						FlxTween.tween(box, {alpha: 0.8}, 0.3, {ease: FlxEase.circOut});
						FlxTween.tween(swagDialogue, {alpha: 1}, 0.3, {ease: FlxEase.circOut});
						FlxTween.tween(dropText, {alpha: 0.5}, 0.3, {ease: FlxEase.circOut});
						FlxTween.tween(noTextText, {alpha: 0}, 0.3, {ease: FlxEase.circOut});
						FlxTween.tween(icons, {alpha: 1}, 0.3, {ease: FlxEase.circOut});
					}

				case "keeptexthidden":
			
			/* == ICON TALKING EXAMPLE ==
			case "[insert name of character head icon here]":
				remove(icons);
				icons = new HealthIcon('[insert name of character head icon here]', false);
				changeposition();
				add(icons);
				changeSound('[insert name of character text sound here. or use "pixelText"]',0.5);
				
				When you've done this, go to your dialogue and add in the name of the character. for example.

				:nameofcharacterhere:default:Text Here!
				*/
		}

		if(!skipDialogue){
			if(!setDialogue){
				swagDialogue.resetText(dialogueList[0]);
			}

			swagDialogue.start(0.04, true);
		}
		else{

			dialogueList.remove(dialogueList[0]);
			startDialogue();
			
		}
	}

	function changeposition():Void
	{
		remove(swagDialogue);
		remove(dropText);
		switch (curCharacter)
	{
		case "narrator":
		if (curAnim == 'default')
			{
				dropText = new FlxText(202, 502, Std.int(FlxG.width * 0.6), "", 32);
				dropText.font = 'Delfino';
				dropText.color = 0xFF3c3c3c;
				dropText.alpha = 0.5;
				add(dropText);

				swagDialogue = new FlxTypeText(200, 500, Std.int(FlxG.width * 0.6), "", 32);
				swagDialogue.font = 'Delfino';
				swagDialogue.color = 0xFF3c3c3c;
				swagDialogue.finishSounds = false;
				//swagDialogue.sounds = [FlxG.sound.load(Paths.sound('pixelText'), 0.6)];
				add(swagDialogue);
			}

		else
			{
				icons.x = 130;
				icons.y = 480;

				dropText = new FlxText(282, 502, Std.int(FlxG.width * 0.6), "", 32);
				dropText.font = 'Delfino';
				dropText.color = 0xFF3c3c3c;
				dropText.alpha = 0.5;
				add(dropText);

				swagDialogue = new FlxTypeText(280, 500, Std.int(FlxG.width * 0.6), "", 32);
				swagDialogue.font = 'Delfino';
				swagDialogue.color = 0xFF3c3c3c;
				swagDialogue.finishSounds = false;
				add(swagDialogue);	
			}
	}

	}

	function cleanDialog():Void
	{
		while(dialogueList[0] == ""){
			dialogueList.remove(dialogueList[0]);
		}

		var splitName:Array<String> = dialogueList[0].split(":");
		curCharacter = splitName[1];
		curAnim = splitName[2];
	
		dialogueList[0] = dialogueList[0].substr(splitName[1].length + splitName[2].length  + 3).trim();
		
		
	}

	function changeSound(sound:String, volume:Float){
	swagDialogue.sounds = [FlxG.sound.load(Paths.sound('dialogue/' + sound, 'shared'), volume)];
	}
}
