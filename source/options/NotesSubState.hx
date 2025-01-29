package options;

import FlxUIDropDownMenuCustom;
import flixel.ui.FlxButton;
import flixel.addons.ui.FlxInputText;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.shapes.FlxShapeCircle;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.math.FlxPoint;
import lime.system.Clipboard;
import flixel.util.FlxGradient;
import flixel.text.FlxText;
import flixel.group.FlxGroup.FlxTypedGroup;
import RGBPalette.RGBShaderReference;
import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.FlxSprite;

using StringTools;

class NotesSubState extends MusicBeatSubstate
{
	var onModeColumn:Bool = true;
	var curSelectedMode:Int = 0;
	var curSelectedNote:Int = 0;
	var dataArray:Array<Array<FlxColor>>;

	var hexTypeLine:FlxSprite;
	var hexTypeNum:Int = -1;
	var hexTypeVisibleTimer:Float = 0;

	var copyButton:FlxSprite;
	var pasteButton:FlxSprite;

	var colorGradient:FlxSprite;
	var colorGradientSelector:FlxSprite;
	var colorPalette:FlxSprite;
	var colorWheel:FlxSprite;
	var colorWheelSelector:FlxSprite;

	var alphabetR:Alphabet;
	var alphabetG:Alphabet;
	var alphabetB:Alphabet;
	var alphabetHex:Alphabet;

	var modeBG:FlxSprite;
	var notesBG:FlxSprite;
	public function new() {
		super();

		if (FlxG.save.data.presetsList == null || FlxG.save.data.presetsList == []) {
			FlxG.save.data.presetsList = defaultPresetList;
			FlxG.save.flush();
		}
		
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFEA71FD;
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		modeBG = new FlxSprite(215, 85).makeGraphic(315, 115, FlxColor.BLACK);
		modeBG.visible = false;
		modeBG.alpha = 0.4;
		add(modeBG);

		notesBG = new FlxSprite(140, 190).makeGraphic(480, 125, FlxColor.BLACK);
		notesBG.visible = false;
		notesBG.alpha = 0.4;
		add(notesBG);

		modeNotes = new FlxTypedGroup<FlxSprite>();
		add(modeNotes);

		myNotes = new FlxTypedGroup<StrumNote>();
		add(myNotes);

		var bg:FlxSprite = new FlxSprite(720).makeGraphic(FlxG.width - 720, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.25;
		add(bg);
		var bg:FlxSprite = new FlxSprite(750, 160).makeGraphic(FlxG.width - 780, 540, FlxColor.BLACK);
		bg.alpha = 0.25;
		add(bg);

		copyButton = new FlxSprite(760, 50).loadGraphic(Paths.image('noteColorMenu/copy'));
		copyButton.alpha = 0.6;
		add(copyButton);

		pasteButton = new FlxSprite(1180, 50).loadGraphic(Paths.image('noteColorMenu/paste'));
		pasteButton.alpha = 0.6;
		add(pasteButton);

		colorGradient = FlxGradient.createGradientFlxSprite(60, 360, [FlxColor.WHITE, FlxColor.BLACK]);
		colorGradient.setPosition(780, 200);
		add(colorGradient);

		colorGradientSelector = new FlxSprite(770, 200).makeGraphic(80, 10, FlxColor.WHITE);
		colorGradientSelector.offset.y = 5;
		add(colorGradientSelector);

		colorPalette = new FlxSprite(820, 580).loadGraphic(Paths.image('noteColorMenu/palette'));
		colorPalette.scale.set(20, 20);
		colorPalette.updateHitbox();
		colorPalette.antialiasing = false;
		add(colorPalette);
		
		colorWheel = new FlxSprite(860, 200).loadGraphic(Paths.image('noteColorMenu/colorWheel'));
		colorWheel.setGraphicSize(360, 360);
		colorWheel.updateHitbox();
		add(colorWheel);

		colorWheelSelector = new FlxShapeCircle(0, 0, 8, {thickness: 0}, FlxColor.WHITE);
		colorWheelSelector.offset.set(8, 8);
		colorWheelSelector.alpha = 0.6;
		add(colorWheelSelector);

		var txtX = 980;
		var txtY = 90;
		alphabetR = makeColorBadAlphabet(txtX - 100, txtY);
		add(alphabetR);
		alphabetG = makeColorBadAlphabet(txtX, txtY);
		add(alphabetG);
		alphabetB = makeColorBadAlphabet(txtX + 100, txtY);
		add(alphabetB);
		alphabetHex = makeColorBadAlphabet(txtX, txtY - 55);
		add(alphabetHex);
		hexTypeLine = new FlxSprite(0, 20).makeGraphic(5, 62, FlxColor.WHITE);
		hexTypeLine.visible = false;
		add(hexTypeLine);

		spawnNotes();
		updateNotes(true);
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);

		presetName = new FlxInputText(10, 0, 250, "", 16);
		presetName.y = FlxG.height - (10 + presetName.height);
		add(presetName);
		
		var presetSelect:FlxUIDropDownMenuCustom = null;
		var buttonSave = new FlxButton(presetName.x + presetName.width + 20, presetName.y, "Save preset", () -> {
			if (presetName.text.trim() == "" || presetName.text.trim() == "Default") return;

			presets.set(presetName.text, [
				[dataArray[0][0], dataArray[0][1], dataArray[0][2]],
				[dataArray[1][0], dataArray[1][1], dataArray[1][2]],
				[dataArray[2][0], dataArray[2][1], dataArray[2][2]],
				[dataArray[3][0], dataArray[3][1], dataArray[3][2]]
			]);
			if (!presetList.contains(presetName.text)) presetList.push(presetName.text);

			FlxG.save.data.presetsList = presets;
			FlxG.save.flush();

			presetSelect.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(presetList, true));
		});
		add(buttonSave);

		//CoolUtil.runCodeInOtherThread(() -> {
			presets = FlxG.save.data.presetsList;
			if (presets == null)
				presets = defaultPresetList;
		//});

		presetList = [];
		for (key => value in presets) {
			presetList.push(key);
		}

		presetList.sort(function(a, b) {
			if (a == "Default") return -1;
			if (b == "Default") return 1;
			return (a < b) ? -1 : 1;
		});

		presetSelect = new FlxUIDropDownMenuCustom(buttonSave.x + buttonSave.width + 20, buttonSave.y, FlxUIDropDownMenuCustom.makeStrIdLabelArray(presetList, true), (selectID:String) -> {
			selectedPreset = presetList[Std.parseInt(selectID)];
		});
		add(presetSelect);
		presetSelect.dropDirection = FlxUIDropDownMenuDropDirection.Up;
		presetSelect.selectedLabel = "Default";

		var buttonRemove = new FlxButton(presetSelect.x + presetSelect.width + 20, presetSelect.y, "Remove preset", () -> {
			if (selectedPreset == "Default") return;
			presets.remove(selectedPreset);
			presetList.remove(selectedPreset);

			FlxG.save.data.presetsList = presets;
			FlxG.save.flush();

			presetSelect.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(presetList, true));
		});
		add(buttonRemove);

		var buttonLoad = new FlxButton(buttonRemove.x + buttonRemove.width + 20, buttonRemove.y, "Load preset", () -> {
			applyPreset(selectedPreset);
		});
		add(buttonLoad);
		addVirtualPad(FULL, A_B);
	}

	var presetName:FlxInputText;
	var selectedPreset = "";
	var presetList:Array<String> = ["Default"];
	static var presets:Map<String, Array<Array<FlxColor>>> = [
		"Default" => ClientPrefs.defaultArrowRGB,
	];

	static var defaultPresetList = presets;

	function applyPreset(preset:String)
	{
		var oldMode = curSelectedMode;
		var oldNote = curSelectedNote;
		var colors = presets.exists(preset) ? presets.get(preset) : presets.get("Default");
		for (note in 0...4) {
			for (mode in 0...3) {
				var color = colors[note][mode];
				setShaderColor(color, note, mode);
				changeSelectionMode(mode, true, false, true, false);
				changeSelectionNote(note, true, false, true, false);
				updateColors();
			}
		}
		changeSelectionMode(oldMode, true, false, true, false);
		changeSelectionNote(oldNote, true, false, true, false);
	}
	
	var _storedColor:FlxColor;
	var changingNote:Bool = false;
	var holdingOnObj:FlxSprite;
	var allowedTypeKeys:Map<FlxKey, String> = [
		ZERO => '0', ONE => '1', TWO => '2', THREE => '3', FOUR => '4', FIVE => '5', SIX => '6', SEVEN => '7', EIGHT => '8', NINE => '9',
		NUMPADZERO => '0', NUMPADONE => '1', NUMPADTWO => '2', NUMPADTHREE => '3', NUMPADFOUR => '4', NUMPADFIVE => '5', NUMPADSIX => '6',
		NUMPADSEVEN => '7', NUMPADEIGHT => '8', NUMPADNINE => '9', A => 'A', B => 'B', C => 'C', D => 'D', E => 'E', F => 'F'];

	override function update(elapsed:Float) {
		if (controls.BACK || FlxG.keys.pressed.BACKSPACE) {
			if (FlxG.keys.pressed.BACKSPACE || FlxG.keys.pressed.ESCAPE) {
				if (presetName.hasFocus)
					return;
				else {
					FlxG.sound.play(Paths.sound('cancelMenu'));
					close();
					return;
				}
			}
		}

		super.update(elapsed);

		if(hexTypeNum > -1 && !presetName.hasFocus)
		{
			var keyPressed:FlxKey = cast (FlxG.keys.firstJustPressed(), FlxKey);
			hexTypeVisibleTimer += elapsed;
			var changed:Bool = false;
			if(changed = FlxG.keys.justPressed.LEFT)
				hexTypeNum--;
			else if(changed = FlxG.keys.justPressed.RIGHT)
				hexTypeNum++;
			else if(allowedTypeKeys.exists(keyPressed))
			{
				//trace('keyPressed: $keyPressed, lil str: ' + allowedTypeKeys.get(keyPressed));
				var curColor:String = alphabetHex.text;
				var newColor:String = curColor.substring(0, hexTypeNum) + allowedTypeKeys.get(keyPressed) + curColor.substring(hexTypeNum + 1);

				var colorHex:FlxColor = FlxColor.fromString('#' + newColor);
				setShaderColor(colorHex);
				_storedColor = getShaderColor();
				updateColors();
				
				// move you to next letter
				hexTypeNum++;
				changed = true;
			}
			else if(FlxG.keys.justPressed.ENTER)
				hexTypeNum = -1;
			
			var end:Bool = false;
			if(changed)
			{
				if (hexTypeNum > 5) //Typed last letter
				{
					hexTypeNum = -1;
					end = true;
					hexTypeLine.visible = false;
				}
				else
				{
					if(hexTypeNum < 0) hexTypeNum = 0;
					else if(hexTypeNum > 5) hexTypeNum = 5;
					centerHexTypeLine();
					hexTypeLine.visible = true;
				}
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
			}
			if(!end) hexTypeLine.visible = Math.floor(hexTypeVisibleTimer * 2) % 2 == 0;
		}
		else
		{
			var add:Int = 0;
			if((controls.UI_LEFT_P || controls.UI_RIGHT_P) && !presetName.hasFocus) add = (controls.UI_LEFT_P ? -1 : 1);

			if((controls.UI_UP_P || controls.UI_DOWN_P) && !presetName.hasFocus)
			{
				onModeColumn = !onModeColumn;
				modeBG.visible = onModeColumn;
				notesBG.visible = !onModeColumn;
			}
	
			if(add != 0 && !presetName.hasFocus)
			{
				if(onModeColumn) changeSelectionMode(add);
				else changeSelectionNote(add);
			}
			hexTypeLine.visible = false;
		}

		// Copy/Paste buttons
		var generalMoved:Bool = (FlxG.mouse.justMoved);
		var generalPressed:Bool = (FlxG.mouse.justPressed);
		if(generalMoved && !presetName.hasFocus)
		{
			copyButton.alpha = 0.6;
			pasteButton.alpha = 0.6;
		}

		if(pointerOverlaps(copyButton) && !presetName.hasFocus)
		{
			copyButton.alpha = 1;
			if(generalPressed)
			{
				Clipboard.text = getShaderColor().toHexString(false, false);
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
				trace('copied: ' + Clipboard.text);
			}
			hexTypeNum = -1;
		}
		else if (pointerOverlaps(pasteButton) && !presetName.hasFocus)
		{
			pasteButton.alpha = 1;
			if(generalPressed)
			{
				var formattedText = Clipboard.text.trim().toUpperCase().replace('#', '').replace('0x', '');
				var newColor:Null<FlxColor> = FlxColor.fromString('#' + formattedText);
				//trace('#${Clipboard.text.trim().toUpperCase()}');
				if(newColor != null && formattedText.length == 6)
				{
					setShaderColor(newColor);
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
					_storedColor = getShaderColor();
					updateColors();
				}
				else //errored
					FlxG.sound.play(Paths.sound('cancelMenu'), 0.6);
			}
			hexTypeNum = -1;
		}

		// Click
		if(generalPressed && !presetName.hasFocus)
		{
			hexTypeNum = -1;
			if (pointerOverlaps(modeNotes))
			{
				modeNotes.forEachAlive(function(note:FlxSprite) {
					if (curSelectedMode != note.ID && pointerOverlaps(note))
					{
						modeBG.visible = notesBG.visible = false;
						curSelectedMode = note.ID;
						onModeColumn = true;
						updateNotes();
						FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
					}
				});
			}
			else if (pointerOverlaps(myNotes))
			{
				myNotes.forEachAlive(function(note:StrumNote) {
					if (curSelectedNote != note.ID && pointerOverlaps(note))
					{
						modeBG.visible = notesBG.visible = false;
						curSelectedNote = note.ID;
						onModeColumn = false;
						bigNote.rgbShader.parent = Note.globalRgbShaders[note.ID];
						bigNote.shader = Note.globalRgbShaders[note.ID].shader;
						updateNotes();
						FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
					}
				});
			}
			else if (pointerOverlaps(colorWheel)) {
				_storedColor = getShaderColor();
				holdingOnObj = colorWheel;
			}
			else if (pointerOverlaps(colorGradient)) {
				_storedColor = getShaderColor();
				holdingOnObj = colorGradient;
			}
			else if (pointerOverlaps(colorPalette)) {
				setShaderColor(colorPalette.pixels.getPixel32(
					Std.int((pointerX() - colorPalette.x) / colorPalette.scale.x), 
					Std.int((pointerY() - colorPalette.y) / colorPalette.scale.y)));
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
				updateColors();
			}
			else if(pointerY() >= hexTypeLine.y && pointerY() < hexTypeLine.y + hexTypeLine.height &&
					Math.abs(pointerX() - 1000) <= 84)
			{
				hexTypeNum = 0;
				for (letter in alphabetHex.letters)
				{
					if(letter.x - letter.offset.x + letter.width <= pointerX()) hexTypeNum++;
					else break;
				}
				if(hexTypeNum > 5) hexTypeNum = 5;
				hexTypeLine.visible = true;
				centerHexTypeLine();
			}
			else holdingOnObj = null;
		}
		// holding
		if(holdingOnObj != null && !presetName.hasFocus)
		{
			if (FlxG.mouse.justReleased)
			{
				holdingOnObj = null;
				_storedColor = getShaderColor();
				updateColors();
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
			}
			else if (generalMoved || generalPressed)
			{
				if (holdingOnObj == colorGradient)
				{
					var newBrightness = 1 - FlxMath.bound((pointerY() - colorGradient.y) / colorGradient.height, 0, 1);
					_storedColor.alpha = 1;
					if(_storedColor.brightness == 0) //prevent bug
						setShaderColor(FlxColor.fromRGBFloat(newBrightness, newBrightness, newBrightness));
					else
						setShaderColor(FlxColor.fromHSB(_storedColor.hue, _storedColor.saturation, newBrightness));
					updateColors(_storedColor);
				}
				else if (holdingOnObj == colorWheel)
				{
					var center:FlxPoint = new FlxPoint(colorWheel.x + colorWheel.width/2, colorWheel.y + colorWheel.height/2);
					var mouse:FlxPoint = pointerFlxPoint();
					var hue:Float = FlxMath.wrap(FlxMath.wrap(Std.int(mouse.degreesTo(center)), 0, 360) - 90, 0, 360);
					var sat:Float = FlxMath.bound(mouse.dist(center) / colorWheel.width*2, 0, 1);
					//trace('$hue, $sat');
					if(sat != 0) setShaderColor(FlxColor.fromHSB(hue, sat, _storedColor.brightness));
					else setShaderColor(FlxColor.fromRGBFloat(_storedColor.brightness, _storedColor.brightness, _storedColor.brightness));
					updateColors();
				}
			} 
		}
		else if((controls.RESET && hexTypeNum < 0) && !presetName.hasFocus)
		{
			if(FlxG.keys.pressed.SHIFT || FlxG.gamepads.anyJustPressed(LEFT_SHOULDER))
			{
				for (i in 0...3)
				{
					var strumRGB:RGBShaderReference = myNotes.members[curSelectedNote].rgbShader;
					var color:FlxColor = ClientPrefs.defaultArrowRGB[curSelectedNote][i];
					switch(i)
					{
						case 0:
							getShader().r = strumRGB.r = color;
						case 1:
							getShader().g = strumRGB.g = color;
						case 2:
							getShader().b = strumRGB.b = color;
					}
					dataArray[curSelectedNote][i] = color;
				}
			}
			setShaderColor(ClientPrefs.defaultArrowRGB[curSelectedNote][curSelectedMode]);
			FlxG.sound.play(Paths.sound('cancelMenu'), 0.6);
			updateColors();
		}
	}

	function pointerOverlaps(obj:Dynamic)
	{
		return FlxG.mouse.overlaps(obj);
	}

	function pointerX():Float
	{
		return FlxG.mouse.x;
	}
	function pointerY():Float
	{
		return FlxG.mouse.y;
	}
	function pointerFlxPoint():FlxPoint
	{
		return FlxG.mouse.getScreenPosition();
	}

	function centerHexTypeLine()
	{
		//trace(hexTypeNum);
		if(hexTypeNum > 0)
		{
			var letter = alphabetHex.letters[hexTypeNum-1];
			hexTypeLine.x = letter.x - letter.offset.x + letter.width;
		}
		else
		{
			var letter = alphabetHex.letters[0];
			hexTypeLine.x = letter.x - letter.offset.x;
		}
		hexTypeLine.x += hexTypeLine.width;
		hexTypeVisibleTimer = 0;
	}
	function changeSelectionMode(change:Int = 0, set:Bool = false, sound:Bool = true, instant:Bool = false, changeModeBG:Bool = true) {
		if (set)
			curSelectedMode = change;
		else
			curSelectedMode += change;

		if (curSelectedMode < 0)
			curSelectedMode = 2;
		if (curSelectedMode >= 3)
			curSelectedMode = 0;

		if (changeModeBG) {
			modeBG.visible = true;
			notesBG.visible = false;
		}
		updateNotes(instant);
		if (sound) FlxG.sound.play(Paths.sound('scrollMenu'));
	}
	function changeSelectionNote(change:Int = 0, set:Bool = false, sound:Bool = true, instant:Bool = false, changeModeBG:Bool = true) {
		if (set)
			curSelectedNote = change;
		else
			curSelectedNote += change;
		if (curSelectedNote < 0)
			curSelectedNote = dataArray.length-1;
		if (curSelectedNote >= dataArray.length)
			curSelectedNote = 0;
		
		if (changeModeBG) {
			modeBG.visible = false;
			notesBG.visible = true;
		}
		bigNote.rgbShader.parent = Note.globalRgbShaders[curSelectedNote];
		bigNote.shader = Note.globalRgbShaders[curSelectedNote].shader;
		updateNotes(instant);
		if (sound) FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	// alphabets
	function makeColorBadAlphabet(x:Float = 0, y:Float = 0):Alphabet
	{
		var text:Alphabet = new Alphabet(x, y, '', true);
		text.alignment = CENTERED;
		text.setScale(0.6);
		add(text);
		return text;
	}

	// notes sprites functions
	var modeNotes:FlxTypedGroup<FlxSprite>;
	var myNotes:FlxTypedGroup<StrumNote>;
	var bigNote:Note;
	public function spawnNotes()
	{
		dataArray = ClientPrefs.arrowRGB;

		// clear groups
		modeNotes.forEachAlive(function(note:FlxSprite) {
			note.kill();
			note.destroy();
		});
		myNotes.forEachAlive(function(note:StrumNote) {
			note.kill();
			note.destroy();
		});
		modeNotes.clear();
		myNotes.clear();

		if(bigNote != null)
		{
			remove(bigNote);
			bigNote.destroy();
		}

		var res:Int = 160;
		for (i in 0...3)
		{
			var newNote:FlxSprite = new FlxSprite(230 + (100 * i), 100).loadGraphic(Paths.image('noteColorMenu/note'), true, res, res);
			newNote.antialiasing = ClientPrefs.globalAntialiasing;
			newNote.setGraphicSize(85);
			newNote.updateHitbox();
			newNote.animation.add('anim', [i], 24, true);
			newNote.animation.play('anim', true);
			newNote.ID = i;
			newNote.antialiasing = false;
			modeNotes.add(newNote);
		}

		Note.globalRgbShaders = [];
		for (i in 0...dataArray.length)
		{
			Note.initializeGlobalRGBShader(i);
			var newNote:StrumNote = new StrumNote(150 + (480 / dataArray.length * i), 200, i, 0);
			newNote.setGraphicSize(102);
			newNote.updateHitbox();
			newNote.ID = i;
			myNotes.add(newNote);
		}

		bigNote = new Note(0, 0, false, true);
		bigNote.setPosition(250, 325);
		bigNote.setGraphicSize(250);
		bigNote.updateHitbox();
		bigNote.rgbShader.parent = Note.globalRgbShaders[curSelectedNote];
		bigNote.shader = Note.globalRgbShaders[curSelectedNote].shader;
		for (i in 0...Note.colArray.length)
		{
			/*if(!onPixel) */bigNote.animation.addByPrefix('note$i', Note.colArray[i] + '0', 24, true);
			//else bigNote.animation.add('note$i', [i + 4], 24, true);
		}
		insert(members.indexOf(myNotes) + 1, bigNote);
		_storedColor = getShaderColor();
	}

	function updateNotes(?instant:Bool = false)
	{
		for (note in modeNotes)
			note.alpha = (curSelectedMode == note.ID) ? 1 : 0.6;

		for (note in myNotes)
		{
			var newAnim:String = curSelectedNote == note.ID ? 'confirm' : 'pressed';
			note.alpha = (curSelectedNote == note.ID) ? 1 : 0.6;
			if(note.animation.curAnim == null || note.animation.curAnim.name != newAnim) note.playAnim(newAnim, true);
			if(instant) note.animation.curAnim.finish();
		}
		bigNote.animation.play('note$curSelectedNote', true);
		updateColors();
	}

	function updateColors(specific:Null<FlxColor> = null, curNote:Int = null, curMode:Int = null)
	{
		var settingAnOtherNote = curNote != null ? (curNote != curSelectedNote) : false;
		if (curNote == null) curNote = curSelectedNote;
		if (curMode == null) curMode = curSelectedMode;

		var color:FlxColor = getShaderColor(curNote, curMode);
		if (!settingAnOtherNote)
		{
			var wheelColor:FlxColor = specific == null ? getShaderColor() : specific;
			alphabetR.text = Std.string(color.red);
			alphabetG.text = Std.string(color.green);
			alphabetB.text = Std.string(color.blue);
			alphabetHex.text = color.toHexString(false, false);
			for (letter in alphabetHex.letters) letter.color = color;

			colorWheel.color = FlxColor.fromHSB(0, 0, color.brightness);
			colorWheelSelector.setPosition(colorWheel.x + colorWheel.width/2, colorWheel.y + colorWheel.height/2);
			if(wheelColor.brightness != 0)
			{
				var hueWrap:Float = wheelColor.hue * Math.PI / 180;
				colorWheelSelector.x += Math.sin(hueWrap) * colorWheel.width/2 * wheelColor.saturation;
				colorWheelSelector.y -= Math.cos(hueWrap) * colorWheel.height/2 * wheelColor.saturation;
			}
			colorGradientSelector.y = colorGradient.y + colorGradient.height * (1 - color.brightness);
		}

		var strumRGB:RGBShaderReference = myNotes.members[curNote].rgbShader;
		switch(curMode)
		{
			case 0:
				getShader().r = strumRGB.r = color;
			case 1:
				getShader().g = strumRGB.g = color;
			case 2:
				getShader().b = strumRGB.b = color;
		}
	}

	function setShaderColor(value:FlxColor, curNote:Int = null, curMode:Int = null)
	{
		if (curNote == null) curNote = curSelectedNote;
		if (curMode == null) curMode = curSelectedMode;
		dataArray[curNote][curMode] = value;
	}
	function getShaderColor(curNote:Int = null, curMode:Int = null)
	{
		if (curNote == null) curNote = curSelectedNote;
		if (curMode == null) curMode = curSelectedMode;
		return dataArray[curNote][curMode];
	}
	function getShader(curNote:Int = null)
	{
		if (curNote == null) curNote = curSelectedNote;
		return Note.globalRgbShaders[curNote];
	}
}
