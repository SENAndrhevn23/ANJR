package options;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;

import backend.ClientPrefs;
import backend.Language;
import backend.Paths;

class GraphicsSettingsSubState extends FlxSubState
{
	var options:Array<String> = [
		'lowQuality',
		'antialiasing',
		'shaders',
		'cacheOnGPU',
		'framerate'
	];

	var optionNames:Array<String> = [
		'Low Quality',
		'Anti-Aliasing',
		'Shaders',
		'GPU Caching',
		'Framerate'
	];

	var optionTypes:Array<String> = [
		'bool',
		'bool',
		'bool',
		'bool',
		'int'
	];

	var optionDescriptions:Array<String> = [
		'Reduces visual effects for better performance.',
		'Smooths edges of graphics.',
		'Enables visual effects.',
		'Uses GPU memory for caching textures.',
		'Controls FPS limit.'
	];

	var grpOptions:FlxTypedGroup<FlxSprite>;
	var labels:FlxTypedGroup<FlxText>;

	var curSelected:Int = 0;

	var menuTitle:FlxText;
	var menuHint:FlxText;

	public function new()
	{
		super();
	}

	override function create()
	{
		super.create();

		// background
		var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF11151D);
		add(bg);

		var panel = new FlxSprite(300, 70).makeGraphic(900, 460, 0xFF1D2433);
		add(panel);

		menuTitle = new FlxText(50, 30, 400, "GRAPHICS SETTINGS", 24);
		menuTitle.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT);
		add(menuTitle);

		menuHint = new FlxText(50, 90, 500, "", 16);
		menuHint.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		add(menuHint);

		grpOptions = new FlxTypedGroup<FlxSprite>();
		add(grpOptions);

		labels = new FlxTypedGroup<FlxText>();
		add(labels);

		var startY:Float = 130;
		var spacing:Float = 55;

		for (i in 0...options.length)
		{
			var box = new FlxSprite(320, startY + i * spacing).makeGraphic(600, 45, 0xFF232A38);
			box.ID = i;
			grpOptions.add(box);

			var text = new FlxText(330, startY + i * spacing + 12, 600, "", 18);
			text.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, LEFT);
			labels.add(text);
		}

		changeSelection();
	}

	function getValueText(i:Int):String
	{
		var varName = options[i];

		if (optionTypes[i] == "bool")
		{
			var val:Bool = Reflect.field(ClientPrefs.data, varName);
			return optionNames[i].toUpperCase() + " : " + (val ? "ON" : "OFF");
		}
		else
		{
			var val:Int = Reflect.field(ClientPrefs.data, varName);
			return optionNames[i].toUpperCase() + " : < " + val + " >";
		}
	}

	function changeSelection(change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);

		for (i in 0...grpOptions.length)
		{
			var box = grpOptions.members[i];
			var text = labels.members[i];

			text.text = getValueText(i);

			if (i == curSelected)
			{
				box.color = 0xFF6D7A9A;
				text.color = FlxColor.WHITE;
				menuHint.text = optionDescriptions[i];
			}
			else
			{
				box.color = 0xFF232A38;
				text.color = 0xFFAAAAAA;
			}
		}
	}

	function toggleCurrent()
	{
		var varName = options[curSelected];

		if (optionTypes[curSelected] == "bool")
		{
			var current:Bool = Reflect.field(ClientPrefs.data, varName);
			Reflect.setField(ClientPrefs.data, varName, !current);
		}
		else
		{
			var current:Int = Reflect.field(ClientPrefs.data, varName);
			Reflect.setField(ClientPrefs.data, varName, current + 1);
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.UP)
			changeSelection(-1);

		if (FlxG.keys.justPressed.DOWN)
			changeSelection(1);

		if (FlxG.keys.justPressed.ENTER)
		{
			toggleCurrent();
			changeSelection();
		}

		if (FlxG.keys.justPressed.ESCAPE)
			close();
	}
}