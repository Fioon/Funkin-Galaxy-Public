package;

import flixel.util.FlxTimer;
#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import WeekData;
#if MODS_ALLOWED
import sys.FileSystem;
#end

using StringTools;

class FreeplaySelectState extends MusicBeatState
{
	var songs:Array<Select> = [];
	var weeks:Array<WeekData> = [];

	private static var curSelected:Int = 0;

	private var grpSongs:FlxTypedGroup<Alphabet>;

	var intendedColor:Int;
	var colorTween:FlxTween;
	var weekToOpen:String = null;

	override public function new(?weekToSelect:Null<String>)
	{
		if (weekToSelect != null)
			weekToOpen = weekToSelect;
		super();
	}

	override function create()
	{
		// Paths.clearStoredMemory();

		persistentUpdate = true;
		PlayState.isStoryMode = false;

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Freeplay Selection Menu", null);
		#end

		WeekData.clearWeeks();
		WeekData.reloadWeekFiles(false);
		for (i in 0...WeekData.weeksList.length)
		{
			if (weekIsLocked(WeekData.weeksList[i]))
				continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);

			if (leWeek.hideFreeplay)
				continue;
			weeks.push(leWeek);
			WeekData.setDirectoryFromWeek(leWeek);
			addWeek(WeekData.weeksList[i], leWeek.freeplayName != null ? leWeek.freeplayName : WeekData.weeksList[i]);
			if (WeekData.weeksList[i] == weekToOpen)
				curSelected = i;
		}
		WeekData.loadTheFirstEnabledMod();

		var bg = new FlxSprite().loadGraphic(Paths.image('freeplay/spacebg'));
		bg.screenCenter();
		bg.scale.set(1.1, 1.1);
		bg.x = -300;
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(90, 320, songs[i].displayWeek, true);
			songText.isMenuItem = true;
			songText.targetY = i - curSelected;
			grpSongs.add(songText);

			var maxWidth = 980;
			if (songText.width > maxWidth)
			{
				songText.scaleX = maxWidth / songText.width;
			}
			songText.snapToPosition();

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}
		WeekData.setDirectoryFromWeek();

		if (curSelected >= songs.length)
			curSelected = 0;

		changeSelection();
		#if android
		addVirtualPad(UP_DOWN, A_B);
		#end
		super.create();
	}

	override function closeSubState()
	{
		changeSelection(0, false);
		persistentUpdate = true;
		addVirtualPad(UP_DOWN, A_B);
		super.closeSubState();
	}

	public function addWeek(weekName:String, display:String)
	{
		songs.push(new Select(weekName, display));
	}

	function weekIsLocked(name:String):Bool
	{
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked
			&& leWeek.weekBefore.length > 0
			&& (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	public static var curChar:String = "bf";

	var holdTime:Float = 0;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT || weekToOpen != null;

		var shiftMult:Int = 1;
		if (FlxG.keys.pressed.SHIFT)
			shiftMult = 3;

		if (songs.length > 1 && canMove)
		{
			if (upP)
			{
				changeSelection(-shiftMult);
				holdTime = 0;
			}
			if (downP)
			{
				changeSelection(shiftMult);
				holdTime = 0;
			}

			if (controls.UI_DOWN || controls.UI_UP)
			{
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

				if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
				{
					changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
				}
			}

			if (FlxG.mouse.wheel != 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
				changeSelection(-shiftMult * FlxG.mouse.wheel, false);
			}
		}

		if (controls.BACK && canMove)
		{
			canMove = false;
			if (colorTween != null)
			{
				colorTween.cancel();
			}
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}

		if (accepted && canMove)
		{
			#if android
		        removeVirtualPad();
		        #end
			var freeplay:FreeplayState = new FreeplayState(songs[curSelected].weekName);
			freeplay.openCallback = function()
			{
				new FlxTimer().start(0.1, function(_)
				{
					for (item in grpSongs.members)
					{
						if (weekToOpen != null)
						{
							item.startPosition.x = -1000;
							item.snapToPosition();
						}
						else
						{
							FlxTween.tween(item.startPosition, {x: -1000}, 0.3, {ease: FlxEase.quadIn});
						}
					}
				});
				weekToOpen = null;
				canMove = false;
			}
			freeplay.closeCallback = function()
			{
				canMove = true;
				new FlxTimer().start(0.1, function(_)
				{
					for (item in grpSongs.members)
						FlxTween.tween(item.startPosition, {x: 90}, 0.3, {ease: FlxEase.quadOut});
				});
			}
			openSubState(freeplay);
			if (stickerSubState != null)
				freeplay.openSubState(stickerSubState);
		}
		super.update(elapsed);
	}

	var canMove = true;

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (playSound)
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		if (!canMove)
			return;

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
				item.alpha = 1;
		}
	}
}

class Select
{
	public var displayWeek:String = "";
	public var weekName:String = "";

	public function new(song:String, display:String)
	{
		this.weekName = song;
		this.displayWeek = display;
	}
}
