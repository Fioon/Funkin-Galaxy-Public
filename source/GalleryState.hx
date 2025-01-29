package;

import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.group.FlxGroup.FlxTypedGroup;

import flixel.math.FlxMath;
import flixel.tweens.FlxTween;

import flixel.addons.display.FlxRuntimeShader;
import flixel.addons.display.FlxBackdrop;
import sys.io.File;
import openfl.filters.ShaderFilter;
import haxe.Json;

class GalleryState extends MusicBeatState
{
    // DATA STUFF
    var itemGroup:FlxTypedGroup<GalleryImage>;

    var imagePaths:Array<String>;
    var imageDescriptions:Array<String>;
    var imageTitle:Array<String>;
    var linkOpen:Array<String>;
    var descriptionText:FlxText;
    var tvShader:FlxRuntimeShader;

    var currentIndex:Int = 0;
    var allowInputs:Bool = true;

    // UI STUFF
    var imageSprite:FlxSprite;
    var background:FlxSprite;
    var titleText:FlxText;
    var bars:FlxSprite;
    var bg:FlxSprite;
    var cityDesat:FlxSprite;
    

    var check:FlxBackdrop;
    // Customize the image path here
    var imagePath:String = "gallery/";

    override public function create():Void
    {   
        FlxG.sound.playMusic(Paths.music("TownNightGallery"));

        var jsonData:String = File.getContent(SUtil.getPath() + "assets/images/gallery/gallery.json");
        var imageData:Array<Dynamic> = haxe.Json.parse(jsonData);

        // Set up background
        background = new FlxSprite(10, 50).loadGraphic(Paths.image("menuBG"));
        background.setGraphicSize(Std.int(background.width * 1));
        background.screenCenter();
        add(background);

        check = new FlxBackdrop(Paths.image('check'), 0, 0);
		check.scrollFactor.set(0, 0.1);
		check.y -= 80;
		check.color = 0xFF3A4262;
		add(check);
		check.velocity.x = 20;

        //Setup the bars
        background = new FlxSprite(10, 50).loadGraphic(Paths.image("gallery/ui/bars"));
        background.setGraphicSize(Std.int(background.width * 1));
        background.screenCenter();
        add(background);
    
        imagePaths = [];
        imageDescriptions = [];
        imageTitle = [];
        linkOpen = [];
        
        for (data in imageData) {
            imagePaths.push(data.path);
            imageDescriptions.push(data.description);
            imageTitle.push(data.title);
            linkOpen.push(data.link);
        }
    
        itemGroup = new FlxTypedGroup<GalleryImage>();
    
        for (i in 0...imagePaths.length) {
            var newItem = new GalleryImage(Paths.image(imagePath + imagePaths[i]));
            newItem.screenCenter();
            newItem.ID = i;
            itemGroup.add(newItem);
        }
    
        add(itemGroup);
    
        descriptionText = new FlxText(50, -100, FlxG.width - 100, imageDescriptions[currentIndex]);
        descriptionText.setFormat(null, 25, 0xffffff, "center");
        descriptionText.screenCenter();
        descriptionText.y += 270;
        descriptionText.setFormat(Paths.font("Delfino.ttf"), 32, FlxColor.WHITE, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        descriptionText.borderSize = 2;
        add(descriptionText);

        titleText = new FlxText(50, 60, FlxG.width - 100, imageTitle[currentIndex]);
        titleText.screenCenter(X);
        titleText.setFormat(null, 40, 0xffffff, "center");
        titleText.setFormat(Paths.font("MarioWii.ttf"), 42, FlxColor.WHITE, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        titleText.borderSize = 2;
        add(titleText);
    
        persistentUpdate = true;
        changeSelection();
        #if android
        addVirtualPad(FULL, A_B);
        #end
        super.create();
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

       check.x += .5*(elapsed/(1/120)); 
        check.y -= 0 / (ClientPrefs.framerate / 100);

        if ((controls.UI_LEFT_P || controls.UI_RIGHT_P) && allowInputs) {
            changeSelection(controls.UI_LEFT_P ? -1 : 1);
            FlxG.sound.play(Paths.sound("scrollMenu"));
        }
    
        if (controls.BACK && allowInputs)
        {
            allowInputs = false;
            FlxG.sound.play(Paths.sound('cancelMenu'));
            MusicBeatState.switchState(new MainMenuState());
            FlxG.sound.playMusic(Paths.music("freakyMenu"));
        }
    
        if (controls.ACCEPT && allowInputs)
            CoolUtil.browserLoad(linkOpen[currentIndex]);
    }
    
    private function changeSelection(i:Int = 0)
    {
        currentIndex = FlxMath.wrap(currentIndex + i, 0, imageTitle.length - 1);
    
        descriptionText.text = imageDescriptions[currentIndex];
        titleText.text = imageTitle[currentIndex]; 

        var change = 0;
        for (item in itemGroup) {
            item.posX = change++ - currentIndex;
            item.selected =  (item.ID == currentIndex);
            item.alpha = item.selected ? 1 : 0.6;
        }
    }
}

class GalleryImage extends FlxSprite {
    public var posX:Float = 0;
    public var selected:Bool = false;

    static var unselectedScale = 0.75;
    static var selectedScale = 1;
    static var lerpSpeed:Float = 6;

    override public function new(image:flixel.graphics.FlxGraphic) {
        super();
        loadGraphic(image);
    }
    
    override function update(elapsed:Float) {
        super.update(elapsed);
        x = FlxMath.lerp(x, (FlxG.width - width) / 2 + posX * 760, CoolUtil.boundTo(elapsed * lerpSpeed, 0, 1));
        scale.x = scale.y = FlxMath.lerp(scale.x, selected ? selectedScale : unselectedScale, CoolUtil.boundTo(elapsed * lerpSpeed, 0, 1));
    }
}