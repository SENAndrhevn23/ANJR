package options;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;

import backend.ClientPrefs;
import backend.Paths;

class VisualsSettingsSubState extends flixel.FlxSubState
{
	var options:Array<String> = [
		'Hide HUD',
		'Flashing Lights',
		'Camera Zooms',
		'Score Zoom',
		'FPS Counter',
		'Combo Stacking'
	];

	var vars:Array<String> = [
		'hideHud',
		'flashing',
		'camZooms',
		'scoreZoom',
		'showFPS',
		'comboStacking'
	];

	var descriptions:Array<String> = [
		'Hides most HUD elements.',
		'Disables flashing light effects.',
		'Camera zooms on beat hits.',
		'Score text grows when hitting notes.',
		'Shows FPS counter.',
		'Stacks combo and ratings for cleaner UI.'
	];

	var grp:FlxTypedGroup<FlxSprite>;
	var txts:FlxTypedGroup<FlxText>;

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

		// background
		add(new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF11151D));

		title = new FlxText(50, 30, 600, "VISUALS SETTINGS", 24);
		title.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE);
		add(title);

		hint = new FlxText(50, 80, 900, "", 16);
		hint.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE);
		add(hint);

		grp = new FlxTypedGroup<FlxSprite>();
		txts = new FlxTypedGroup<FlxText>();

		add(grp);
		add(txts);

		var startY = 130;
		var spacing = 55;

		for (i in 0...options.length)
		{
			var bg = new FlxSprite(320, startY + i * spacing)
				.makeGraphic(600, 45, 0xFF232A38);
			bg.ID = i;
			grp.add(bg);

			var t = new FlxText(330, startY + i * spacing + 12, 600, "", 18);
			t.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE);
			txts.add(t);
		}

		updateUI();
	}

	function getBool(i:Int):Bool
	{
		return Reflect.field(ClientPrefs.data, vars[i]);
	}

	function setBool(i:Int, value:Bool)
	{
		Reflect.setField(ClientPrefs.data, vars[i], value);
	}

	function getText(i:Int):String
	{
		return options[i].toUpperCase() + " : " + (getBool(i) ? "ON" : "OFF");
	}

	function toggle()
	{
		var newVal = !getBool(curSelected);
		setBool(curSelected, newVal);

		applySetting(vars[curSelected]);
		ClientPrefs.saveSettings();

		updateUI();
	}

	function applySetting(key:String)
	{
		switch (key)
		{
			case "showFPS":
				if (Main.fpsVar != null)
					Main.fpsVar.visible = ClientPrefs.data.showFPS;

			case "camZooms":
				// handled automatically by engine in most builds

			default:
				// nothing
		}
	}

	function updateUI()
	{
		for (i in 0...grp.length)
		{
			var bg = grp.members[i];
			var t = txts.members[i];

			if (bg == null || t == null) continue;

			t.text = getText(i);

			if (i == curSelected)
			{
				bg.color = 0xFF6D7A9A;
				t.alpha = 1;
				hint.text = descriptions[i];
			}
			else
			{
				bg.color = 0xFF232A38;
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