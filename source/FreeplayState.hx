package;

import flixel.FlxSubState;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import haxe.Json;
import flixel.input.keyboard.FlxKey;
#if desktop
import Discord.DiscordClient;
#end
import editors.ChartingState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import WeekData;
import flixel.addons.transition.FlxTransitionableState;

using StringTools;

class FreeplayState extends MusicBeatSubstate
{
	var songs:Array<SongMetadata> = [];

	var selector:FlxText;
	private static var curSelected:Int = 0;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = '';

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var grpIcons:FlxTypedGroup<HealthIcon>;
	private var curPlaying:Bool = false;

	var player:MusicPlayer;
	var starshroom = new FlxSprite();

	var weeks:Array<String> = [];
	var hasRandom:Bool = false;

	override public function new(newWeek:Null<String>)
	{
		if (newWeek != null)
			weeks = [newWeek];
		super();
	}

	override function create()
	{
		//Paths.clearStoredMemory();
		PlayState.isStoryMode = false;

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		FlxG.mouse.visible = true;

		addSong("Random", -1, "");
		var songsLength = 0;
		for (i in 0...weeks.length) {
			if(weekIsLocked(weeks[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(weeks[i]);
			var leSongs:Array<String> = [];
			var leChars:Array<String> = [];

			for (j in 0...leWeek.songs.length)
			{
				leSongs.push(leWeek.songs[j][0]);
				leChars.push(leWeek.songs[j][1]);
			}

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs)
			{
				addSong(song[0], i, song[1]);
				songsLength++;
			}
		}
		hasRandom = songsLength > 1;
		WeekData.loadTheFirstEnabledMod();

		top = new FlxSprite().loadGraphic(Paths.image('freeplay/topbar'));
		top.scale.set(1,0.7);
		top.updateHitbox();
		top.antialiasing = ClientPrefs.globalAntialiasing;
		top.y = -top.height;

		circleLooking = new FlxSprite().loadGraphic(Paths.image('freeplay/songbackdrop'));
		circleLooking.setGraphicSize(-1, Std.int(FlxG.height - (top.height - 24)));
		circleLooking.antialiasing = ClientPrefs.globalAntialiasing;
		circleLooking.updateHitbox();
		circleLooking.x = FlxG.width;
		circleLooking.y = top.height - 16;
		add(circleLooking);

		grpSongs = new FlxTypedGroup<Alphabet>();
		grpIcons = new FlxTypedGroup<HealthIcon>();

		add(top);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(90, 320, songs[i].songName, true);
			songText.isMenuItem = false;
			songText.targetY = i - curSelected;
			grpSongs.add(songText);

			var maxWidth = 550;
			var daScale = 0.75;
			if (songText.width > maxWidth)
			{
				songText.scaleX = (maxWidth / songText.width) * daScale;
			} else {
				songText.scaleX = daScale;
			}
			songText.scaleY = daScale;
			songText.snapToPosition();

			Paths.currentModDirectory = songs[i].folder;
			if (songs[i].songCharacter != "")
			{
				var icon:HealthIcon = new HealthIcon(songs[i].songCharacter, daScale);

				icon.data.alphabet = songText;

				// using a FlxGroup is too much fuss! //well fuck you i still did
				grpIcons.add(icon);
				icon.updateHitbox();
			}

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}
		if (!hasRandom)
			grpSongs.members[0].visible = false;
		WeekData.setDirectoryFromWeek();

		starshroom.frames = Paths.getSparrowAtlas('freeplay/starshroom');
		starshroom.animation.addByPrefix("starshroomidle", "starshroomidle", 24, true);
		starshroom.animation.play("starshroomidle", true);
		starshroom.scale.set(0.9,0.9);
		starshroom.updateHitbox();
		starshroom.antialiasing = ClientPrefs.globalAntialiasing;
		starshroom.x = -starshroom.width;
		starshroom.screenCenter(Y);
		starshroom.y += 150;
		starshroom.angle = -5;
		add(starshroom);

		add(grpSongs);
		add(grpIcons);

		arrow = new FlxSprite();
		arrow.frames = Paths.getSparrowAtlas('freeplay/marker');
		arrow.animation.addByPrefix("idle", "markeridle", 24, true);
		arrow.animation.addByPrefix("enter", "markerenter", 24, false);
		arrow.animation.addByPrefix("confirm", "markerconfirm", 24, false);
		arrow.updateHitbox();
		arrow.antialiasing = ClientPrefs.globalAntialiasing;
		arrow.x = -starshroom.width;
		arrow.screenCenter(Y);
		arrow.y += 70;
		add(arrow);

		arrow.animation.play("enter", true);
		arrow.offset.set(520, 15);
		FlxTween.tween(arrow, {x: FlxG.width - (circleLooking.width + 210)}, 1, {ease: FlxEase.circOut, onComplete: function(_)
		{
			arrow.animation.play("idle", true);
			arrow.offset.set(0, 0);
		}});
		FlxTween.tween(starshroom, {x: 20}, 1, {ease: FlxEase.circOut});
		starshroomtwn[0] = FlxTween.tween(starshroom, {y: starshroom.y + 120}, 10, {ease: FlxEase.sineInOut, type: PINGPONG, startDelay: 0.25});
		doStarshroomAngleLoop(starshroom);

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		scoreText.alpha = 0;

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 50, 0xFF000000);
		scoreBG.alpha = 0;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.alpha = 0;
		diffText.font = scoreText.font;
		// add(diffText); only one difficulty rn

		add(scoreText);

		if(curSelected >= songs.length) curSelected = 1;

		if(lastDifficultyName == '')
		{
			lastDifficultyName = CoolUtil.defaultDifficulty;
		}
		curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(lastDifficultyName)));

		if (curSelected == 0) {
			curSelected = 1;
			changeSelection(0, false, true);
		}

		changeSelection(0, false, true);
		changeDiff(0, true);

		for (item in grpSongs.members)
			item.snapToPosition();

		textBG = new FlxSprite(0, FlxG.height).makeGraphic(FlxG.width, 26, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);
		var leText:String = Language.getString("freeplay.infoText");
		if (ClientPrefs.keyBinds.get("reset")[0] != FlxKey.NONE && ClientPrefs.keyBinds.get("reset")[1] != FlxKey.NONE)
		{
			leText = Language.getString("freeplay.infoTextReset2");
			leText = StringTools.replace(leText, "{RESET2}", ClientPrefs.keyBinds.get("reset")[1].toString());
		}
		if (ClientPrefs.keyBinds.get("reset")[0] != FlxKey.NONE && ClientPrefs.keyBinds.get("reset")[1] != FlxKey.NONE)
		{
			leText = Language.getString("freeplay.infoTextReset");
			leText = StringTools.replace(leText, "{RESET1}", ClientPrefs.keyBinds.get("reset")[1].toString());
		}
		leText = StringTools.replace(leText, "{RESET1}", ClientPrefs.keyBinds.get("reset")[0].toString());
		bottomString = leText;
		var size:Int = 17;

		bottomText = new FlxText(textBG.x, FlxG.height + 4, FlxG.width, leText, size);
		bottomText.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, CENTER);
		bottomText.scrollFactor.set();
		add(bottomText);

		player = new MusicPlayer(this);
		add(player);
		super.create();

		new FlxTimer().start(0.2, function(_)
		{
			FlxTween.tween(top, {y: 0}, 0.3, {ease: FlxEase.circOut});
			FlxTween.tween(circleLooking, {x: FlxG.width - circleLooking.width}, 1, {ease: FlxEase.circOut});
			FlxTween.tween(this, {alphOffsetX: 0}, 1, {ease: FlxEase.circOut});
			FlxTween.tween(textBG, {y: FlxG.height - 26}, 0.3, {ease: FlxEase.circOut});
			FlxTween.tween(bottomText, {y: FlxG.height - 22}, 0.3, {ease: FlxEase.circOut});
			FlxTween.tween(scoreText, {alpha: 1}, 1, {ease: FlxEase.circOut});
			FlxTween.tween(diffText, {alpha: 1}, 1, {ease: FlxEase.circOut});
			FlxTween.tween(scoreBG, {alpha: 0.6}, 1, {ease: FlxEase.circOut});
			new FlxTimer().start(1, function(_) {
				instantAlph = false;
				canMove = true;
			});
		});
		#if android
                addVirtualPad(FULL, A_B_X_Y);
                #end
	}

	var instantAlph = true;
	var alphOffsetX:Float = 700;

	var arrow:FlxSprite;
	var bottomText:FlxText;
	var bottomString:String;
	var starshroomtwn:Array<FlxTween> = [];
	var textBG:FlxSprite;
	var top:FlxSprite;
	var circleLooking:FlxSprite;

	function doStarshroomAngleLoop(starshroom:FlxSprite)
	{
		starshroomtwn[1] = FlxTween.tween(starshroom, {angle: FlxG.random.float(-10, 10)}, FlxG.random.float(5, 10), {ease: FlxEase.quadInOut, onComplete: function(_) {
			doStarshroomAngleLoop(starshroom);
		}});
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter));
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	var instPlaying:Int = -1;
	var holdTime:Float = 0;
	var canMove:Bool = false;
	override function update(elapsed:Float)
	{
		Conductor.songPosition = FlxG.sound.music.time;
		if (FlxG.sound.music.volume < 0.7 && canMove)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 24, 0, 1)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, CoolUtil.boundTo(elapsed * 12, 0, 1));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(Highscore.floorDecimal(lerpRating * 100, 2)).split('.');
		if(ratingSplit.length < 2) { //No decimals, add an empty space
			ratingSplit.push('');
		}

		while(ratingSplit[1].length < 2) { //Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';
		}

		scoreText.text = 'PERSONAL BEST: ' + lerpScore + ' (' + ratingSplit.join('.') + '%)';
		positionHighscore();
		var accepted = controls.ACCEPT && canMove;
		var space = _virtualpad.buttonY.justPressed && canMove;
		var ctrl = _virtualpad.buttonX.justPressed && canMove;

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT && canMove) shiftMult = 3;

		if (!player.playingMusic)
		{
			if(songs.length > 1 && canMove)
			{
				if(FlxG.keys.justPressed.HOME)
				{
					curSelected = 1;
					changeSelection();
					holdTime = 0;
				}
				else if(FlxG.keys.justPressed.END)
				{
					curSelected = songs.length - 1;
					changeSelection();
					holdTime = 0;
				}
				else if (controls.UI_UP_P)
				{
					changeSelection(-shiftMult);
					holdTime = 0;
				}
				if (controls.UI_DOWN_P)
				{
					changeSelection(shiftMult);
					holdTime = 0;
				}

				if(controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
				}

				if(FlxG.mouse.wheel != 0)
				{
					changeSelection(-shiftMult * FlxG.mouse.wheel);
					changeDiff();
				}
			}

			if (canMove)
			{
				if (controls.UI_LEFT_P)
					changeDiff(-1);
				else if (controls.UI_RIGHT_P)
					changeDiff(1);
				else if (controls.UI_UP_P || controls.UI_DOWN_P) changeDiff();
			}
		}

		if (controls.BACK && canMove)
		{
			if (player.playingMusic)
			{
				FlxG.sound.music.stop();
				FlxG.sound.music.volume = 0;
				instPlaying = -1;

				player.playingMusic = false;
				player.switchPlayMusic();

				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				var titleJSON = Json.parse(Paths.getTextFromFile('images/title/data.json'));
				Conductor.changeBPM(titleJSON.bpm);
			} else {
				canMove = false;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				if (wasOnRandom) {
					wasOnRandom = false;
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
					var titleJSON = Json.parse(Paths.getTextFromFile('images/title/data.json'));
					Conductor.changeBPM(titleJSON.bpm);
				}
				new FlxTimer().start(0.2, function(_)
				{
					instantAlph = true;
					canMove = false;
					FlxTween.tween(top, {y: -top.height}, 0.7, {ease: FlxEase.circIn});
					FlxTween.tween(circleLooking, {x: FlxG.width}, 0.3, {ease: FlxEase.circIn});
					FlxTween.tween(this, {alphOffsetX: 700}, 0.3, {ease: FlxEase.circIn});
					FlxTween.tween(textBG, {y: FlxG.height + 1}, 0.7, {ease: FlxEase.circIn});
					FlxTween.tween(bottomText, {y: FlxG.height}, 0.7, {ease: FlxEase.circIn});
					FlxTween.tween(scoreText, {alpha: 0}, 0.7, {ease: FlxEase.circIn});
					FlxTween.tween(diffText, {alpha: 0}, 0.7, {ease: FlxEase.circIn});
					FlxTween.tween(scoreBG, {alpha: 0}, 0.7, {ease: FlxEase.circIn});
					FlxTween.tween(starshroom, {x: -starshroom.width}, 0.7, {ease: FlxEase.circIn});
					FlxTween.tween(arrow, {x: -arrow.width}, 0.5, {ease: FlxEase.circIn});
					new FlxTimer().start(0.7, function(_) {
						#if android
			                        FlxTransitionableState.skipNextTransOut = true;
			                        FlxG.resetState();
			                        #else
			                        close();
						#end
					});
				});
			}
		}

		if(ctrl && canMove && !player.playingMusic)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate(songs[curSelected].songName.toLowerCase()));
		}
		else if(space && curSelected != 0)
		{
			if(instPlaying != curSelected && !player.playingMusic)
			{
				FlxG.sound.music.volume = 0;
				Paths.currentModDirectory = songs[curSelected].folder;
				var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
				PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());

				Conductor.mapBPMChanges(PlayState.SONG);
				Conductor.changeBPM(PlayState.SONG.bpm);

				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.8);
				instPlaying = curSelected;

				player.playingMusic = true;
				player.curTime = 0;
				player.switchPlayMusic();
			}
			else if (instPlaying == curSelected && player.playingMusic)
			{
				player.pauseOrResume(player.paused);
			}
		}

		else if (accepted && !player.playingMusic)
		{
			if (curSelected == 0)
			{
				curSelected = FlxG.random.int(1, songs.length - 1);
				changeSelection(0, true);
				canMove = false;
				wasOnRandom = false;
				new flixel.util.FlxTimer().start(0.85, function(_)
				{
					selectSong();
				});
			} else {
				selectSong();
			}
		}
		else if(controls.RESET && canMove && curSelected != 0)
		{
			if (!player.playingMusic) {
				persistentUpdate = false;
				openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
		}
		FlxG.camera.zoom = FlxMath.lerp(1, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * (player.playingMusic ? FlxG.sound.music.pitch : 1)), 0, 1));

		var lerpVal = instantAlph ? 1 : CoolUtil.boundTo(elapsed * 9.6, 0, 1);
		for (item in grpSongs.members)
		{
			var i = grpSongs.members.indexOf(item);
			var j = item.targetY;
			if (j < 0)
				j = item.targetY * -1;
			var wantedX = 900 + (125 * calculateX(j)) + (50 * (item.scaleX != 0.75 ? (item.scaleX / 1.25) : 0));
			if (i == 0)
				wantedX -= 100;
			wantedX += alphOffsetX;
			var wantedY =  ((FlxG.height / 1.4) - (item.height / 2)) + (((i - curSelected) * ((item.height * 1.6) + 20)));
			var wantedAlpha:Float = calculateAlpha(j);
			if (wantedAlpha < 0)
				wantedAlpha = 0;
            item.x = FlxMath.lerp(item.x, wantedX, lerpVal);
            item.y = FlxMath.lerp(item.y, wantedY, lerpVal);
            item.alpha = FlxMath.lerp(item.alpha, wantedAlpha, lerpVal);
		}

		for (item in grpIcons.members)
		{
			if (item.timeScale != (player.playingMusic ? FlxG.sound.music.pitch : 1)) //check if need to change
				item.timeScale = (player.playingMusic ? FlxG.sound.music.pitch : 1);

			var alph = item.data.alphabet;
			var j = alph.targetY;
			if (j < 0)
				j = alph.targetY * -1;
			var wantedX = 750 + (125 * calculateX(j));
            item.x = FlxMath.lerp(item.x, wantedX, lerpVal) + item.toAdd.x + alphOffsetX;
			item.y = (alph.y - 125) + item.toAdd.y;
			item.alpha = alph.alpha;
		}
		super.update(elapsed);
	}

	static function calculateAlpha(index:Int):Float {
        return Math.pow(0.15, index); //calculate the alpha based on whenever or not you are close to the selected item
	}
	static function calculateX(index:Int):Float {
        return -(Math.pow(0.3, index) * 1.2); //calculate the x based on whenever or not you are close to the selected item
	}

	override function openSubState(SubState:FlxSubState)
	{
		for (twn in starshroomtwn)
			twn.active = false;
		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		for (twn in starshroomtwn)
			twn.active = true;
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
	}

	override function beatHit() {
		if (wasOnRandom)
		{
			FlxG.camera.zoom += 0.03;
		} else if (player.playingMusic && !player.paused)
		{
			grpIcons.members[curSelected - 1].bump();
			if (curBeat % 4 == 0)
				FlxG.camera.zoom += 0.03;
		}

		super.beatHit();
	}

	var lastFlash:Int = 0;

	function selectSong()
	{
		arrow.animation.play("confirm");
		new flixel.util.FlxTimer().start(0.85, function(_) {
			persistentUpdate = false;
			var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
			var poop:String = Highscore.formatSong(songLowercase, curDifficulty);

			PlayState.SONG = Song.loadFromJson(poop, songLowercase);
			PlayState.isStoryMode = false;
			PlayState.freeplayWeek = weeks[0];
			PlayState.storyDifficulty = curDifficulty;
			if (PlayState.SONG.song == "Gusty Garden Old")
				PlayState.keMode = true;
			else
				PlayState.keMode = false;

			var newState:MusicBeatState = new PlayState();
			if (FlxG.keys.pressed.SHIFT){
				newState = new ChartingState();
			}
			LoadingState.loadAndSwitchState(newState, false, this);

			FlxG.sound.music.fadeOut(0.07);
		});
	}

	function changeDiff(change:Int = 0, force:Bool = false)
	{
		var willDoIt = canMove;
		if (force == true)
			willDoIt = true;
		if (!willDoIt) return;
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = CoolUtil.difficulties.length-1;
		if (curDifficulty >= CoolUtil.difficulties.length)
			curDifficulty = 0;

		lastDifficultyName = CoolUtil.difficulties[curDifficulty];

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);

		intendedScore = (ClientPrefs.scoreMode == "Rounded Accurate" ? Math.round(intendedScore / 10) * 10 : intendedScore);
		#end

		PlayState.storyDifficulty = curDifficulty;
		diffText.text = (CoolUtil.difficulties.length > 1 ? '< ${CoolUtil.difficultyString()} >' : CoolUtil.difficultyString());
		positionHighscore();
	}

	var wasOnRandom:Bool = false;

	function changeSelection(change:Int = 0, playSound:Bool = true, force:Bool = false)
	{
		var willDoIt = canMove;
		if (force == true)
			willDoIt = true;
		if (!willDoIt) return;

		curSelected += change;

		if (curSelected < (hasRandom ? 0 : 1)) {
			curSelected = hasRandom ? 0 : 1;
			playSound = false;
		}
		if (curSelected >= songs.length) {
			curSelected = songs.length - 1;
			playSound = false;
		}

		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		if (curSelected == 0 && !wasOnRandom)
		{
			FlxG.sound.playMusic(Paths.music('freeplayRandom'));
			instPlaying = 0;
			wasOnRandom = true;
			Conductor.changeBPM(144);
			lastFlash = 0;
		} else if (curSelected != 0 && (change != 0 && wasOnRandom)) {
			wasOnRandom = false;
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			var titleJSON = Json.parse(Paths.getTextFromFile('images/title/data.json'));
			Conductor.changeBPM(titleJSON.bpm);
		}

		// selector.y = (70 * curSelected) + 30;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		var bullShit:Int = 0;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;
		}

		Paths.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;

		if (songs[curSelected].week != -1)
		{
			CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
			var diffStr:String = WeekData.getCurrentWeek().difficulties;
			if(diffStr != null) diffStr = diffStr.trim(); //Fuck you HTML5

			if(diffStr != null && diffStr.length > 0)
			{
				var diffs:Array<String> = diffStr.split(',');
				var i:Int = diffs.length - 1;
				while (i > 0)
				{
					if(diffs[i] != null)
					{
						diffs[i] = diffs[i].trim();
						if(diffs[i].length < 1) diffs.remove(diffs[i]);
					}
					--i;
				}

				if(diffs.length > 0 && diffs[0].length > 0)
				{
					CoolUtil.difficulties = diffs;
				}
			}

			if(CoolUtil.difficulties.contains(CoolUtil.defaultDifficulty))
			{
				curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(CoolUtil.defaultDifficulty)));
			}
			else
			{
				curDifficulty = 0;
			}

			var newPos:Int = CoolUtil.difficulties.indexOf(lastDifficultyName);
			//trace('Pos of ' + lastDifficultyName + ' is ' + newPos);
			if(newPos > -1)
			{
				curDifficulty = newPos;
			}
		}
	}

	private function positionHighscore() {
		scoreText.x = FlxG.width - scoreText.width - 6;

		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var folder:String = "";

	public function new(song:String, week:Int, songCharacter:String)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.folder = Paths.currentModDirectory;
		if(this.folder == null) this.folder = '';
	}
}
