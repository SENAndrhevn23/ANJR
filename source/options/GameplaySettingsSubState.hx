package options;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;

import backend.ClientPrefs;
import backend.Paths;

class GameplaySettingsSubState extends FlxSubState
{
	var options:Array<String> = [
		'downScroll',
		'middleScroll',
		'opponentStrums',
		'ghostTapping',
		'autoPause',
		'noReset',
		'guitarHeroSustains',
		'hitsoundVolume'
	];

	var names:Array<String> = [
		'Downscroll',
		'Middlescroll',
		'Opponent Notes',
		'Ghost Tapping',
		'Auto Pause',
		'Disable Reset',
		'Sustains as One Note',
		'Hitsound Volume'
	];

	var types:Array<String> = [
		'bool',
		'bool',
		'bool',
		'bool',
		'bool',
		'bool',
		'bool',
		'int'
	];

	var desc:Array<String> = [
		'Notes go downward instead of upward.',
		'Centers the note lanes.',
		'Hides opponent notes.',
		'Prevents accidental misses from key tapping.',
		'Automatically pauses game when unfocused.',
		'Disables reset button.',
		'Sustains behave as single hits.',
		'Controls hitsound volume.'
	];

	var grp:FlxTypedGroup<FlxSprite>;
	var txt:FlxTypedGroup<FlxText>;

	var curSelected:Int = 0;

	var title:FlxText;
	var hint:FlxText;

	public function new()
	{
		super();
	}

	override function create()
	{
		super.create();

		add(new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF11151D));

		title = new FlxText(50, 30, 600, "GAMEPLAY SETTINGS", 24);
		title.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE);
		add(title);

		hint = new FlxText(50, 80, 800, "", 16);
		hint.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE);
		add(hint);

		grp = new FlxTypedGroup<FlxSprite>();
		txt = new FlxTypedGroup<FlxText>();
		add(grp);
		add(txt);

		var startY = 130;
		var spacing = 55;

		for (i in 0...options.length)
		{
			var box = new FlxSprite(320, startY + i * spacing)
				.makeGraphic(650, 45, 0xFF232A38);
			box.ID = i;
			grp.add(box);

			var t = new FlxText(330, startY + i * spacing + 12, 650, "", 18);
			t.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE);
			txt.add(t);
		}

		updateUI();
	}

	function isBool(i:Int):Bool
	{
		return types[i] == "bool";
	}

	function getValue(i:Int):String
	{
		var key = options[i];

		if (isBool(i))
		{
			var val:Bool = Reflect.field(ClientPrefs.data, key);
			return names[i].toUpperCase() + " : " + (val ? "ON" : "OFF");
		}
		else
		{
			var val:Float = Reflect.field(ClientPrefs.data, key);
			return names[i].toUpperCase() + " : " + val;
		}
	}

	function toggle()
	{
		var key = options[curSelected];

		if (isBool(curSelected))
		{
			var val:Bool = Reflect.field(ClientPrefs.data, key);
			Reflect.setField(ClientPrefs.data, key, !val);
		}
		else
		{
			var val:Float = Reflect.field(ClientPrefs.data, key);
			Reflect.setField(ClientPrefs.data, key, val + 1);
		}

		applySetting(key);
		ClientPrefs.saveSettings();
		updateUI();
	}

	function applySetting(key:String)
	{
		switch (key)
		{
			case "autoPause":
				FlxG.autoPause = ClientPrefs.data.autoPause;

			case "hitsoundVolume":
				FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.data.hitsoundVolume);

			default:
		}
	}

	function updateUI()
	{
		for (i in 0...grp.length)
		{
			var box = grp.members[i];
			var t = txt.members[i];

			if (box == null || t == null) continue;

			t.text = getValue(i);

			if (i == curSelected)
			{
				box.color = 0xFF6D7A9A;
				t.alpha = 1;
				hint.text = desc[i];
			}
			else
			{
				box.color = 0xFF232A38;
				t.alpha = 0.6;
			}
		}
	}

	function changeSelection(dir:Int)
	{
		curSelected = FlxMath.wrap(curSelected + dir, 0, options.length - 1);
		updateUI();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.UP)
			changeSelection(-1);

		if (FlxG.keys.justPressed.DOWN)
			changeSelection(1);

		if (FlxG.keys.justPressed.ENTER)
			toggle();

		if (FlxG.keys.justPressed.ESCAPE)
			close();
	}
}