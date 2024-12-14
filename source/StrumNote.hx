package;

import flixel.FlxCamera;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

import RGBPalette.RGBShaderReference;

using StringTools;

class StrumNote extends FlxSprite
{
	public var rgbShader:RGBShaderReference;
	public var resetAnim:Float = 0;
	private var noteData:Int = 0;
	public var direction:Float = 90;//plan on doing scroll directions soon -bb
	public var downScroll:Bool = false;//plan on doing scroll directions soon -bb
	public var sustainReduce:Bool = true;
	
	private var player:Int;
	
	public var texture(default, set):String = null;
	private function set_texture(value:String):String {
		if(texture != value) {
			texture = value;
			reloadNote();
		}
		return value;
	}

	public var defaultRGB:Array<Array<FlxColor>> = ClientPrefs.arrowRGB;

	public var cover:FlxSprite;
	public var heldNote:Note = null;
	public var opponentArrow:Bool = false;
	
	public var useRGBShader:Bool = true;
	public function new(x:Float, y:Float, leData:Int, player:Int) {
		rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(leData));
		rgbShader.enabled = false;

		var arr:Array<FlxColor> = ClientPrefs.arrowRGB[leData];
		
		if(leData <= arr.length)
		{
			@:bypassAccessor
			{
				rgbShader.r = arr[0];
				rgbShader.g = arr[1];
				rgbShader.b = arr[2];
			}
		}

		noteData = leData;
		this.player = player;
		this.noteData = leData;
		super(x, y);

		var skin:String = 'NOTE_assets';
		if (Type.getClass(FlxG.state) == PlayState) if(PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) skin = PlayState.SONG.arrowSkin;
		texture = skin; //Load texture and anims

		scrollFactor.set();
	}

	public function reloadNote()
	{
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;

		if(PlayState.isPixelStage)
		{
			loadGraphic(Paths.image('pixelUI/' + texture));
			width = width / 4;
			height = height / 5;
			loadGraphic(Paths.image('pixelUI/' + texture), true, Math.floor(width), Math.floor(height));

			antialiasing = false;
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));

			animation.add('green', [6]);
			animation.add('red', [7]);
			animation.add('blue', [5]);
			animation.add('purple', [4]);
			switch (Math.abs(noteData) % 4)
			{
				case 0:
					animation.add('static', [0]);
					animation.add('pressed', [4, 8], 12, false);
					animation.add('confirm', [12, 16], 24, false);
				case 1:
					animation.add('static', [1]);
					animation.add('pressed', [5, 9], 12, false);
					animation.add('confirm', [13, 17], 24, false);
				case 2:
					animation.add('static', [2]);
					animation.add('pressed', [6, 10], 12, false);
					animation.add('confirm', [14, 18], 12, false);
				case 3:
					animation.add('static', [3]);
					animation.add('pressed', [7, 11], 12, false);
					animation.add('confirm', [15, 19], 24, false);
			}
		}
		else
		{
			frames = Paths.getSparrowAtlas(texture);
			animation.addByPrefix('green', 'arrowUP');
			animation.addByPrefix('blue', 'arrowDOWN');
			animation.addByPrefix('purple', 'arrowLEFT');
			animation.addByPrefix('red', 'arrowRIGHT');

			antialiasing = ClientPrefs.globalAntialiasing;
			setGraphicSize(Std.int(width * 0.7));

			switch (Math.abs(noteData) % 4)
			{
				case 0:
					animation.addByPrefix('static', 'arrowLEFT');
					animation.addByPrefix('pressed', 'left press', 24, false);
					animation.addByPrefix('confirm', 'left confirm', 24, false);
				case 1:
					animation.addByPrefix('static', 'arrowDOWN');
					animation.addByPrefix('pressed', 'down press', 24, false);
					animation.addByPrefix('confirm', 'down confirm', 24, false);
				case 2:
					animation.addByPrefix('static', 'arrowUP');
					animation.addByPrefix('pressed', 'up press', 24, false);
					animation.addByPrefix('confirm', 'up confirm', 24, false);
				case 3:
					animation.addByPrefix('static', 'arrowRIGHT');
					animation.addByPrefix('pressed', 'right press', 24, false);
					animation.addByPrefix('confirm', 'right confirm', 24, false);
			}
		}
		updateHitbox();

		if(lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
	}

	public function postAddedToGroup() {
		playAnim('static');
		x += Note.swagWidth * noteData;
		x += 50;
		x += ((FlxG.width / 2) * player);
		ID = noteData;
	}

	public function finishedSetup() {
		if (!PlayState.isPixelStage && !PlayState.keMode) {
			cover = new FlxSprite(x, y);
			cover.frames = Paths.getSparrowAtlas('holdCover');
			cover.animation.addByPrefix('start', 'holdCoverStart', 24, false);
			cover.animation.addByPrefix('loop', 'holdCover0', 24, true);
			cover.animation.addByPrefix('end', 'holdCoverEnd', 24, false);
			cover.animation.play('loop', true);
			cover.offset.set(cover.width * .36, cover.height * .25);
			cover.visible = false;
			cover.shader = rgbShader.parent.shader;
			cover.cameras = PlayState.instance.camHUD != null ? [PlayState.instance.camHUD] : cameras;
			cover.antialiasing = antialiasing;
			FlxG.state.add(cover);
		}
	}

	override function set_x(NewX:Float):Float
	{
		if (cover != null)
			cover.x = NewX;
		return super.set_x(NewX);
	}
	override function set_y(NewY:Float):Float
	{
		if (cover != null)
			cover.y = NewY;
		return super.set_y(NewY);
	}
	override function set_cameras(NewCameras:Array<FlxCamera>):Array<FlxCamera>
	{
		if (cover != null)
			cover.cameras = NewCameras;
		return super.set_cameras(NewCameras);
	}
	override function set_visible(NewValue:Bool):Bool
	{
		if (cover != null && cover.visible == true)
			cover.visible = NewValue;
		return super.set_visible(NewValue);
	}
	override function set_alpha(NewAlpha:Float):Float
	{
		if (cover != null)
			cover.alpha = NewAlpha;
		return super.set_alpha(NewAlpha);
	}

	public function coverLogic(note:Note) {
		if (cover != null && note.isSustainNote) {
			cover.visible = visible;
			if (!cover.visible || cover.animation.curAnim.name == 'end') cover.animation.play('start');
			if (StringTools.endsWith(note.animation.curAnim.name, 'holdend')) {
				heldNote = null;
				cover.animation.play('end', true);
				if (!note.mustPress) {
					cover.visible = false;
				} else {
					playAnim('pressed');
				}
			}
		}
	}

	override function update(elapsed:Float) {
		if(resetAnim > 0) {
			resetAnim -= elapsed;
			if(resetAnim <= 0) {
				playAnim('static');
				resetAnim = 0;
			}
		}
		if (cover != null && cover.animation.curAnim.finished) {
			if (cover.animation.curAnim.name == 'end') cover.visible = false;
			else cover.animation.play('loop', true);
		}
		if ((animation.curAnim.finished && animation.curAnim.name == 'confirm') && heldNote == null && (player == 1 && (PlayState.instance == null ? true : !PlayState.instance.cpuControlled))) playAnim('pressed');
		//if(animation.curAnim != null){ //my bad i was upset
		if(animation.curAnim.name == 'confirm' && !PlayState.isPixelStage) {
			centerOrigin();
		//}
		}

		super.update(elapsed);
	}

	public function updateRgb(palette:Array<flixel.util.FlxColor>) {
		rgbShader.r = palette[0];
		rgbShader.g = palette[1];
		rgbShader.b = palette[2];
		if (cover != null)
			cover.shader = rgbShader.parent.shader;
	}

	public function playAnim(anim:String, ?force:Bool = false) {
		animation.play(anim, force);
		centerOffsets();
		centerOrigin();
		var animName = (animation.curAnim != null ? animation.curAnim.name : "");
		if (animName == "static") {
			updateRgb(defaultRGB[noteData]);
		}
		if(useRGBShader) rgbShader.enabled = animName != 'static';
	}
}
