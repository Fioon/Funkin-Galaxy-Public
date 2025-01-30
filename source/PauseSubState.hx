package;

import Controls.Control;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxCamera;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;

class PauseSubState extends MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<FlxText>;
	var grpMenuShitOG:FlxTypedGroup<Alphabet>;
	var buttonGroup:FlxTypedGroup<FlxSprite>;
	var buttonGroupDup:FlxTypedGroup<FlxSprite>;
	public static var isInPause:Bool = false;
	var menuItems:Array<String> = [];
	var menuItemsOG:Array<String> = ['Resume', 'Restart Song', 'Change Difficulty', 'Exit to Menu', 'Options'];
	var difficultyChoices = [];
	var curSelected:Int = 0;
	var bg:FlxSprite;
	var pauseIntro:Bool = true;
	var pauseOutro:Bool = false;
	var coolAwesome:Bool;

	var bullShit:Int = 0;

	var levelInfo:FlxText;
	var creditsText:FlxText;
	var levelDifficulty:FlxText;
	var blueballedTxt:FlxText;
	var chartingText:FlxText;

	var buttonTween:FlxTween;
	var buttonTweenSel:FlxTween;
	var buttonTweenSelFade:FlxTween;
	var sex:FlxTween;
	// var sexColor:FlxTween;

	var pauseMusic:FlxSound;
	var practiceText:FlxText;
	var skipTimeText:FlxText;
	var skipTimeTracker:Alphabet;
	var curTime:Float = Math.max(0, Conductor.songPosition);
	//var botplayText:FlxText;

	public static var songName:String = '';

	public function new(x:Float, y:Float)
	{
		super();
		if(CoolUtil.difficulties.length < 2) menuItemsOG.remove('Change Difficulty'); //No need to change difficulty if there is only one!

		coolAwesome = !((PlayState.chartingMode) || (PlayState.SONG.song == "Gusty Garden Old")); //TEMPORARY

		pauseMusic = new FlxSound();
		if(songName != null) {
			pauseMusic.loadEmbedded(Paths.music(songName), true, true);
		} else if (songName != 'None') {
			pauseMusic.loadEmbedded(Paths.music(Paths.formatToSongPath(ClientPrefs.pauseMusic)), true, true);
		}
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));

		FlxG.sound.list.add(pauseMusic);

		if(coolAwesome) {bg = new FlxSprite().loadGraphic(Paths.image('pause/temporaryBG'));
		bg.screenCenter(XY);}
		else bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		creditsText = new FlxText(20, 15 + (32 * 2), 0, 'Composer: ${PlayState.SONG.songComposer}', 32);
		add(creditsText);

		levelInfo = new FlxText(20, 15 + (32 * 1), 0, PlayState.SONG.song, 32);
		add(levelInfo);

		levelDifficulty = new FlxText(20, 15 + (32 * 2), 0, "Difficulty: ", 32);
		levelDifficulty.text += CoolUtil.difficultyString();
		// add(levelDifficulty);

		blueballedTxt = new FlxText(20, 15 + (32 * 3), 0, "", 32);
		blueballedTxt.text = PlayState.deathCounter + " Blueballs";
		add(blueballedTxt);

		practiceText = new FlxText(20, 15 + 101, 0, "PRACTICE MODE", 32);
		practiceText.visible = PlayState.instance.practiceMode;
		add(practiceText);

		chartingText = new FlxText(20, 15 + 101, 0, "CHART EDITOR PREVIEW", 32);
		chartingText.y = FlxG.height - (chartingText.height + 20);
		chartingText.visible = PlayState.chartingMode;
		add(chartingText);

		for (daCoolText in [creditsText, levelInfo, levelDifficulty, blueballedTxt, practiceText, chartingText])
		{
			daCoolText.scrollFactor.set();
			daCoolText.setFormat(Paths.font("vcr.ttf"), 32);
			daCoolText.updateHitbox();
		}

		for (daCoolText in [creditsText, levelInfo, levelDifficulty, blueballedTxt, practiceText, chartingText]){
			if(coolAwesome) daCoolText.screenCenter(X);
			else daCoolText.x = FlxG.width - (daCoolText.width + 20);
		}

		var myTexts = [creditsText, levelInfo, levelDifficulty, blueballedTxt];

		if(coolAwesome){
			buttonGroup = new FlxTypedGroup<FlxSprite>();
			add(buttonGroup);
			buttonGroupDup = new FlxTypedGroup<FlxSprite>();
			add(buttonGroupDup);
			grpMenuShit = new FlxTypedGroup<FlxText>();
			add(grpMenuShit);
			FlxTween.tween(bg, {alpha: 0.9}, 0.4, {ease: FlxEase.linear});
		}
		else{
			menuItemsOG = ['Resume', 'Restart Song', 'Change Difficulty', 'Options', 'Exit to Menu'];
			grpMenuShitOG = new FlxTypedGroup<Alphabet>();
			add(grpMenuShitOG);
			FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});

			creditsText.y = 15 + (32*1);
			levelInfo.y = 15 + (32*0);
			blueballedTxt.y = 15+(32*2);

		}

		if(PlayState.chartingMode)
		{
			menuItemsOG.insert(2, 'Leave Charting Mode');

			var num:Int = 0;
			if(!PlayState.instance.startingSong)
			{
				num = 1;
				menuItemsOG.insert(3, 'Skip Time');
			}
			menuItemsOG.insert(3 + num, 'End Song');
			menuItemsOG.insert(4 + num, 'Toggle Practice Mode');
			menuItemsOG.insert(5 + num, 'Toggle Botplay');
		}
		menuItems = menuItemsOG;

		for (i in 0...CoolUtil.difficulties.length) {
			var diff:String = '' + CoolUtil.difficulties[i];
			difficultyChoices.push(diff);
		}
		difficultyChoices.push('BACK');

		for (i in 0...myTexts.length)
		{
			var text = myTexts[i];
			text.alpha = 0;
			text.y -= 5;
			FlxTween.tween(text, {alpha: 1, y: text.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.1 + (0.2 * i)});
		}

		FlxTween.tween(creditsText, {alpha: 1, y: creditsText.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(levelInfo, {alpha: 1, y: levelInfo.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.1});
		// FlxTween.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});
		FlxTween.tween(blueballedTxt, {alpha: 1, y: blueballedTxt.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});

		regenMenu();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		startModeTimer();

		#if android
		addVirtualPad(FULL, A);
		addPadCamera();
		#end
	}

	var holdTime:Float = 0;
	var cantUnpause:Float = 0.1;
	var countShit:Int = 0;
	override function update(elapsed:Float)
	{
		cantUnpause -= elapsed;
		if (pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;

		super.update(elapsed);
		updateSkipTextStuff();

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;

		if((pauseIntro==false) && (pauseOutro==false)){
			if (upP)
			{
				FlxG.mouse.visible = false;
				changeSelection(-1);
			}
			if (downP)
			{
				FlxG.mouse.visible = false;
				changeSelection(1);
			}
		}


		var daSelected:String = menuItems[curSelected];
		switch (daSelected)
		{
			case 'Skip Time':
				if (controls.UI_LEFT_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
					curTime -= 1000;
					holdTime = 0;
				}
				if (controls.UI_RIGHT_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
					curTime += 1000;
					holdTime = 0;
				}

				if(controls.UI_LEFT || controls.UI_RIGHT)
				{
					holdTime += elapsed;
					if(holdTime > 0.5)
					{
						curTime += 45000 * elapsed * (controls.UI_LEFT ? -1 : 1);
					}

					if(curTime >= FlxG.sound.music.length) curTime -= FlxG.sound.music.length;
					else if(curTime < 0) curTime += FlxG.sound.music.length;
					updateSkipTimeText();
				}
		}

                if(FlxG.mouse.justPressed){
			if(countShit < 2){
				countShit += 1;
			}else{
				if(controls.ACCEPT){
					countShit = 2;
				}else{
					countShit = 0;
				}
			}
		}

		if ((accepted || countShit == 2) && (pauseIntro==false) && (pauseOutro==false) && (cantUnpause <= 0 || !ClientPrefs.controllerMode))
		{
			if (menuItems == difficultyChoices)
			{
				if(menuItems.length - 1 != curSelected && difficultyChoices.contains(daSelected)) {
					var name:String = PlayState.SONG.song;
					var poop = Highscore.formatSong(name, curSelected);
					PlayState.SONG = Song.loadFromJson(poop, name);
					PlayState.storyDifficulty = curSelected;
					MusicBeatState.resetState();
					FlxG.sound.music.volume = 0;
					PlayState.changedDifficulty = true;
					PlayState.chartingMode = false;
					return;
				}

				menuItems = menuItemsOG;
				regenMenu();
			}


			FlxG.mouse.visible=true;

			/*grpMenuShit.forEach(function(txt:FlxText){
				if(txt.ID == curSelected){
					txt.color = 0xFF1A5568;
					FlxTween.color(txt, 0.2, txt.color, 0xFF000000,{ease: FlxEase.quartOut});
				}
			});
			buttonGroupDup.forEach(function(spr:FlxSprite){
				if(spr.ID == curSelected){
					spr.color = 0xFF3ACBFD;
					FlxTween.color(spr, 0.2, spr.color, 0xFFFFFFFF,{ease: FlxEase.quartOut});
				}
			});*/


			// var belch = new FlxTimer().start(0.5);

			if(coolAwesome){
				pauseOutro = true;
				FlxG.sound.play(Paths.sound('pauseOff'), 0.7);


				switch(daSelected){
					case "Exit to Menu":
						countShit = 0;
						PlayState.deathCounter = 0;
						PlayState.seenCutscene = false;
						isInPause = false;
						WeekData.loadTheFirstEnabledMod();
						PlayState.cancelMusicFadeTween();
						PlayState.changedDifficulty = false;
						PlayState.chartingMode = false;
						PlayState.exitSong();
				}

				buttonGroup.forEach(function(spr:FlxSprite){
					FlxTween.tween(spr, {alpha:0, x: spr.x - 100}, 0.3, {ease: FlxEase.quartOut});
				});
				buttonGroupDup.forEach(function(spr:FlxSprite){
					FlxTween.tween(spr, {alpha:0, x: spr.x - 100}, 0.3, {ease: FlxEase.quartOut});
				});
				grpMenuShit.forEach(function(txt:FlxText){
					FlxTween.tween(txt, {alpha:0, x: txt.x - 100}, 0.3, {ease: FlxEase.quartOut});
				});
				for (fade in [bg, creditsText, levelInfo, /*levelDifficulty, */blueballedTxt, practiceText, chartingText])
					FlxTween.tween(fade, {alpha: 0}, 0.4, {
						ease: FlxEase.quartInOut, onComplete: (_)->{
					switch(daSelected){
						case "Resume":
							MouseCursors.loadCursor("galaxy");
							countShit = 0;
							close();
						case "Restart Song":
							countShit = 0;
							restartSong();
						case "Options":
							countShit = 0;
							LoadingState.loadAndSwitchState(new options.OptionsState());
							isInPause = true;
						}
					}
				});

			}
			else{
				switch (daSelected)
				{
					case "Resume":
						close();
					case 'Change Difficulty':
						menuItems = difficultyChoices;
						deleteSkipTimeText();
						regenMenu();
					case 'Toggle Practice Mode':
						PlayState.instance.practiceMode = !PlayState.instance.practiceMode;
						PlayState.changedDifficulty = true;
						practiceText.visible = PlayState.instance.practiceMode;
					case "Restart Song":
						restartSong();
					case "Leave Charting Mode":
						restartSong();
						PlayState.chartingMode = false;
					case 'Skip Time':
						if(curTime < Conductor.songPosition)
						{
							PlayState.startOnTime = curTime;
							restartSong(true);
						}
						else
						{
							if (curTime != Conductor.songPosition)
							{
								PlayState.instance.clearNotesBefore(curTime, false);
								PlayState.instance.setSongTime(curTime);
							}
							close();
						}
					case "End Song":
						close();
						PlayState.instance.finishSong(true);
					case "Options":
						LoadingState.loadAndSwitchState(new options.OptionsState());
						isInPause = true;
					case 'Toggle Botplay':
						PlayState.instance.cpuControlled = !PlayState.instance.cpuControlled;
						PlayState.changedDifficulty = true;
						PlayState.instance.botplayTxt.visible = PlayState.instance.cpuControlled;
						PlayState.instance.botplayTxt.alpha = 1;
						PlayState.instance.botplaySine = 0;
					case "Exit to Menu":
						PlayState.deathCounter = 0;
						PlayState.seenCutscene = false;
						isInPause = false;
						WeekData.loadTheFirstEnabledMod();
						PlayState.cancelMusicFadeTween();
						PlayState.changedDifficulty = false;
						PlayState.chartingMode = false;
						PlayState.exitSong();
				}
			}
		}

		if(coolAwesome){
			if ((FlxG.mouse.getScreenPosition().x != oldPos.x || FlxG.mouse.getScreenPosition().y != oldPos.y) && (pauseOutro==false)){
				oldPos = FlxG.mouse.getScreenPosition();
				for (i in 0...menuItems.length) {
					var pos = oldPos;
					if (pos.y > i / menuItems.length * (FlxG.height/1) + 140 && pos.y < (i + 1) / menuItems.length * (FlxG.height/1) + 140 && curSelected != i) {
						curSelected = i;
						changeSelection();
						break;
					}
					// camFollow.setPosition(FlxG.width / 2, FlxG.mouse.getPositionInCameraView(FlxG.camera).y);
				}
				FlxG.mouse.visible = true;
			}
			buttonGroupDup.forEach(function(spr:FlxSprite){
				buttonGroup.forEach(function(real:FlxSprite){
					// spr.scale.set(real.scale.x,real.scale.y);
					spr.x = real.x;
					// spr.y = real.y;
				});
			});
			/*	buttonGroup.forEach(function(spr:FlxSprite)
				{
					if (FlxG.mouse.overlaps(spr)){
						curSelected = spr.ID;
						changeSelection();
						// break;
					}
				});
			*/
		}
	}
	public var oldPos = FlxG.mouse.getScreenPosition();

	function deleteSkipTimeText()
	{
		if(skipTimeText != null)
		{
			skipTimeText.kill();
			remove(skipTimeText);
			skipTimeText.destroy();
		}
		skipTimeText = null;
		skipTimeTracker = null;
	}

	public static function restartSong(noTrans:Bool = false)
	{
		PlayState.instance.paused = true; // For lua
		FlxG.sound.music.volume = 0;
		PlayState.instance.vocals.volume = 0;

		if(noTrans)
		{
			FlxTransitionableState.skipNextTransOut = true;
			FlxG.resetState();
		}
		else
		{
			MusicBeatState.resetState();
		}
	}

	override function destroy()
	{
		pauseMusic.destroy();

		super.destroy();
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length)
			curSelected = 0;

		var bullShit:Int = 0;

		if(coolAwesome){
			buttonGroup.forEach(function(spr:FlxSprite)
			{
			// item.y = bullShit - curSelected;
			// bullShit++;
			// if (buttonTween != null) buttonTween.cancel();

			buttonTween = FlxTween.tween(spr, {'scale.x': 0.9, 'scale.y':0.5},0.2,{ease: FlxEase.bounceOut});
			if(spr.ID == curSelected){
				buttonTween.cancel();
				buttonTween = FlxTween.tween(spr, {'scale.x': 1,'scale.y':0.6},0.2,{ease: FlxEase.quartOut});
			}
			});
			buttonGroupDup.forEach(function(spr:FlxSprite)
			{
				// if (buttonTweenSel != null)	buttonTweenSel.cancel();
				// if (buttonTweenSelFade != null)	buttonTweenSelFade.cancel();

				buttonTweenSelFade = FlxTween.tween(spr, {alpha: 0},0.2,{ease: FlxEase.quartOut});
				buttonTweenSel = FlxTween.tween(spr, {'scale.x': 0.9, 'scale.y':0.5},0.2,{ease: FlxEase.bounceOut});
				if(spr.ID == curSelected){
					buttonTweenSel.cancel();
					buttonTweenSelFade.cancel();
					buttonTweenSel = FlxTween.tween(spr, {'scale.x': 1,'scale.y':0.6},0.2,{ease: FlxEase.quartOut});
					buttonTweenSelFade = FlxTween.tween(spr, {alpha: 1},0.2,{ease: FlxEase.quartOut});
				}
			});
			grpMenuShit.forEach(function(txt:FlxText){
				// if (sex != null) sex.cancel();
				// if (sexColor != null) sexColor.cancel();

				sex = FlxTween.tween(txt, {'scale.x':1,'scale.y':1},0.2,{ease: FlxEase.bounceOut});
				// sexColor = FlxTween.color(txt, 0.2, txt.color, 0xFF505050,{ease: FlxEase.quartOut});
				if(txt.ID == curSelected){
					sex.cancel();
					// sexColor.cancel();
					// sexColor = FlxTween.color(txt, 0.4, txt.color, 0xFF000000,{ease: FlxEase.quartOut});
					sex = FlxTween.tween(txt, {'scale.x':1.1,'scale.y':1.1},0.4,{ease: FlxEase.quartOut});
				}
			});
		}
		else{
			for (item in grpMenuShitOG.members)
			{
				item.targetY = bullShit - curSelected;
				bullShit++;

				item.alpha = 0.6;
				// item.setGraphicSize(Std.int(item.width * 0.8));

				if (item.targetY == 0)
				{
					item.alpha = 1;
					// item.setGraphicSize(Std.int(item.width));

					if(item == skipTimeTracker)
					{
						curTime = Math.max(0, Conductor.songPosition);
						updateSkipTimeText();
					}
				}
			}
		}

	}

	function regenMenu():Void {
		if(coolAwesome){
			MouseCursors.loadCursor("nintendo_normal");
			FlxG.sound.play(Paths.sound('pauseOn'), 0.7);
			pauseIntro = true;
			pauseOutro = false;

			for (i in 0...grpMenuShit.members.length) {
				var obj = grpMenuShit.members[0];
				obj.kill();
				grpMenuShit.remove(obj, true);
				obj.destroy();
			}

			for (i in 0...menuItems.length) {
				var item:FlxText = new FlxText(0, 0, 0, menuItems[i], 40);
				item.setFormat("Delfino", 40, 0xFF505050);
				item.alpha = 0;
				item.ID = i;
				// item.isMenuItem = true;
				// item.targetY = i;

				item.screenCenter(X);
				var bleh = item.x;

				var button:FlxSprite = new FlxSprite(item.x, item.y).loadGraphic(Paths.image('buttonSmall'));
				button.scale.set(0.9,0.5);
				button.ID = i;
				button.screenCenter(X);
				var blehh = button.x;
				buttonGroup.add(button);

				if(i<3){
					item.x += 100;
					item.y = 245 + (115*i);

					button.x += 100;
					button.y = 175 + (115*i);
					//bullShit = Math.round(item.y);

					FlxTween.tween(item, {alpha: 1, x: bleh}, 0.3, {ease: FlxEase.quartOut});
					FlxTween.tween(button, {alpha: 1, x: blehh}, 0.3, {ease: FlxEase.quartOut});
				}
				else{
					// item.x = 180;
					item.x = bleh;
					item.y = 630;
					// button.x = item.x-170;
					button.x = blehh;
					button.y = item.y-70;

					FlxTween.tween(item, {alpha: 1}, 0.3, {ease: FlxEase.quartOut});
					FlxTween.tween(button, {alpha: 1}, 0.3, {ease: FlxEase.quartOut, onComplete: (_)->{
						curSelected = 0;
						pauseIntro = false;
						changeSelection();
					}});
				}

				var buttonDup:FlxSprite = new FlxSprite(button.x,button.y).loadGraphic(Paths.image('buttonSmallSelect'));
				buttonDup.alpha = 0;
				buttonDup.ID = i;
				buttonGroupDup.add(buttonDup);

				grpMenuShit.add(item);

				/*if(menuItems[i] == 'Skip Time')
				{
					skipTimeText = new FlxText(0, 0, 0, '', 64);
					skipTimeText.setFormat(Paths.font("vcr.ttf"), 64, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
					skipTimeText.scrollFactor.set();
					skipTimeText.borderSize = 2;
					skipTimeTracker = item;
					add(skipTimeText);

					updateSkipTextStuff();
					updateSkipTimeText();
				}*/
			}
		}
		else{
			pauseIntro = false;
			for (i in 0...grpMenuShitOG.members.length) {
				var obj = grpMenuShitOG.members[0];
				obj.kill();
				grpMenuShitOG.remove(obj, true);
				obj.destroy();
			}

			for (i in 0...menuItems.length) {
				var item = new Alphabet(90, 320, menuItems[i], true);
				item.isMenuItem = true;
				item.targetY = i;
				grpMenuShitOG.add(item);

				if(menuItems[i] == 'Skip Time')
				{
					skipTimeText = new FlxText(0, 0, 0, '', 64);
					skipTimeText.setFormat(Paths.font("vcr.ttf"), 64, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
					skipTimeText.scrollFactor.set();
					skipTimeText.borderSize = 2;
					skipTimeTracker = item;
					add(skipTimeText);

					updateSkipTextStuff();
					updateSkipTimeText();
				}
			}
			curSelected = 0;
			changeSelection();
		}
	}

	function updateSkipTextStuff()
	{
		if(skipTimeText == null || skipTimeTracker == null) return;

		skipTimeText.x = skipTimeTracker.x + skipTimeTracker.width + 60;
		skipTimeText.y = skipTimeTracker.y;
		skipTimeText.visible = (skipTimeTracker.alpha >= 1);
	}

	function updateSkipTimeText()
	{
		skipTimeText.text = FlxStringUtil.formatTime(Math.max(0, Math.floor(curTime / 1000)), false) + ' / ' + FlxStringUtil.formatTime(Math.max(0, Math.floor(FlxG.sound.music.length / 1000)), false);
	}

	var modeFadeTween:Null<FlxTween> = null;
	var mode:Int = 0;

	static final MODE_FADE_DELAY:Float = 5;
	static final MODE_FADE_DURATION:Float = 0.75;
	function startModeTimer():Void
	{
		modeFadeTween = FlxTween.tween(creditsText, {alpha: 0.0}, MODE_FADE_DURATION,
		{
			startDelay: MODE_FADE_DELAY,
			ease: FlxEase.quartOut,
			onComplete: (_) -> {
				mode++;
				var modeTexts = ['Composer: ${PlayState.SONG.songComposer}', 'Charter: ${PlayState.SONG.songCharter}', 'Artist: ${PlayState.SONG.songArtist}'];
				if (mode >= modeTexts.length)
					mode = 0;
				creditsText.text = modeTexts[mode];
				if (coolAwesome) creditsText.screenCenter(X);
				else creditsText.x = FlxG.width - (creditsText.width + 20);


				FlxTween.tween(creditsText, {alpha: 1.0}, MODE_FADE_DURATION,
				{
					ease: FlxEase.quartOut,
					onComplete: (_) -> {
				    	startModeTimer();
					}
				});
			}
		});
	}
}
