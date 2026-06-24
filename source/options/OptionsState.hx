package options;

import states.MainMenuState;
import backend.StageData;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.effects.FlxFlicker;
import backend.ClientPrefs;
import backend.Language;

class OptionsState extends MusicBeatState
{
	var options:Array<String> = [
		'Note Colors',
		'Controls',
		'Adjust Delay and Combo',
		'Graphics',
		'Visuals',
		'Gameplay'
		#if TRANSLATIONS_ALLOWED , 'Language' #end
	];
	
	private var grpOptions:FlxTypedGroup<FlxSprite>;
	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;
	public static var onPlayState:Bool = false;

	var buttonLabels:Map<FlxSprite, FlxText> = new Map();
	var menuTitle:FlxText;
	var menuHint:FlxText;
	var selectedSomethin:Bool = false;

	function openSelectedSubstate(label:String) {
		switch(label)
		{
			case 'Note Colors':
				openSubState(new options.NotesColorSubState());
			case 'Controls':
				openSubState(new options.ControlsSubState());
			case 'Graphics':
				openSubState(new options.GraphicsSettingsSubState());
			case 'Visuals':
				openSubState(new options.VisualsSettingsSubState());
			case 'Gameplay':
				openSubState(new options.GameplaySettingsSubState());
			case 'Adjust Delay and Combo':
				MusicBeatState.switchState(new options.NoteOffsetState());
			case 'Language':
				openSubState(new options.LanguageSubState());
		}
	}

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end

		persistentUpdate = persistentDraw = true;

		// --- Backgrounds ---
		var darkBg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF11151D);
		darkBg.scrollFactor.set();
		add(darkBg);

		var gridBg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF151A24);
		gridBg.scrollFactor.set();
		gridBg.alpha = 0.88;
		add(gridBg);

		// --- Panel Containers ---
		var sidebar:FlxSprite = new FlxSprite(36, 72).makeGraphic(252, 458, 0xFF1A2030);
		sidebar.scrollFactor.set();
		add(sidebar);

		var mainPanel:FlxSprite = new FlxSprite(304, 72).makeGraphic(880, 458, 0xFF1D2433);
		mainPanel.scrollFactor.set();
		add(mainPanel);

		var topBar:FlxSprite = new FlxSprite(36, 28).makeGraphic(1148, 34, 0xFF202738);
		topBar.scrollFactor.set();
		add(topBar);

		var footerBar:FlxSprite = new FlxSprite(36, 542).makeGraphic(1148, 38, 0xFF171B25);
		footerBar.scrollFactor.set();
		add(footerBar);

		var accentLine:FlxSprite = new FlxSprite(36, 65).makeGraphic(1148, 3, 0xFF6D7A9A);
		accentLine.scrollFactor.set();
		add(accentLine);

		// --- Group Setup ---
		grpOptions = new FlxTypedGroup<FlxSprite>();
		add(grpOptions);

		// --- Headers and UI Text ---
		menuTitle = new FlxText(56, 36, 420, "OPTIONS MENU", 24);
		menuTitle.scrollFactor.set();
		menuTitle.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT);
		add(menuTitle);

		menuHint = new FlxText(56, 92, 210, "", 16);
		menuHint.scrollFactor.set();
		menuHint.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		add(menuHint);

		var systemLabel:FlxText = new FlxText(1000, 36, 160, "System Settings", 16);
		systemLabel.scrollFactor.set();
		systemLabel.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		add(systemLabel);

		var footerHint:FlxText = new FlxText(320, 551, 840, "Arrows to navigate, Enter to select, Esc to go back", 16);
		footerHint.scrollFactor.set();
		footerHint.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		add(footerHint);

		// --- Menu Item Creation ---
		var menuStartY:Float = 96;
		var menuSpacing:Float = 58; // Sized tightly to comfortably fit up to 7 localized items
		for (num => option in options)
		{
			createMenuItem(option, 330, menuStartY + (num * menuSpacing));
		}

		changeSelection();
		ClientPrefs.saveSettings();

		super.create();
	}

	function createMenuItem(name:String, x:Float, y:Float):FlxSprite
	{
		var buttonW:Int = 560;
		var buttonH:Int = 50;

		var menuItem:FlxSprite = new FlxSprite(x, y).makeGraphic(buttonW, buttonH, 0xFF232A38);
		menuItem.scrollFactor.set();
		menuItem.antialiasing = ClientPrefs.data.antialiasing;
		menuItem.alpha = 0.92;
		menuItem.ID = grpOptions.length;
		grpOptions.add(menuItem);

		var cleanName:String = Language.getPhrase('options_$name', name);
		var label:FlxText = new FlxText(x + 12, y + 14, buttonW - 24, cleanName.toUpperCase(), 16);
		label.scrollFactor.set();
		label.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, LEFT);
		add(label);
		buttonLabels.set(menuItem, label);

		return menuItem;
	}

	function getOptionHint(option:String):String
	{
		return switch(option)
		{
			case 'Note Colors': 'Customize the colors of your notes.';
			case 'Controls': 'Rebind your keyboard and controller inputs.';
			case 'Adjust Delay and Combo': 'Calibrate audio offset and gameplay UI elements.';
			case 'Graphics': 'Toggle performance modes and rendering engines.';
			case 'Visuals': 'Adjust flashing lights, camera zoom, and UI styles.';
			case 'Gameplay': 'Configure scoring mechanics, downscroll, and difficulty variables.';
			case 'Language': 'Switch game translation parameters.';
			default: 'Select a setting layout to continue.';
		};
	}

	function styleButton(button:FlxSprite, active:Bool)
	{
		if (button == null) return;
		button.color = active ? 0xFF36415A : 0xFF232A38;
		button.alpha = active ? 1 : 0.92;

		var label:FlxText = buttonLabels.get(button);
		if (label != null)
		{
			label.alpha = active ? 1 : 0.78;
		}
	}

	override function closeSubState()
	{
		super.closeSubState();
		ClientPrefs.saveSettings();
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end
		// Clear selection lock on substate exit
		selectedSomethin = false;
	}

	override function update(elapsed:Float) 
	{
		super.update(elapsed);

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
				changeSelection(-1);
			if (controls.UI_DOWN_P)
				changeSelection(1);

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				if(onPlayState)
				{
					StageData.loadDirectory(PlayState.SONG);
					LoadingState.loadAndSwitchState(new PlayState());
					FlxG.sound.music.volume = 0;
				}
				else MusicBeatState.switchState(new MainMenuState());
			}
			else if (controls.ACCEPT) 
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('confirmMenu'));
				
				var item:FlxSprite = grpOptions.members[curSelected];
				FlxFlicker.flicker(item, 0.5, 0.05, false, false, function(flick:FlxFlicker)
				{
					openSelectedSubstate(options[curSelected]);
				});
			}
		}
	}
	
	function changeSelection(change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);
		if (change != 0) FlxG.sound.play(Paths.sound('scrollMenu'));

		for (item in grpOptions)
		{
			styleButton(item, false);
		}

		var selectedItem:FlxSprite = grpOptions.members[curSelected];
		styleButton(selectedItem, true);

		var selectedName:String = options[curSelected];
		menuHint.text = getOptionHint(selectedName);
	}

	override function destroy()
	{
		ClientPrefs.loadPrefs();
		super.destroy();
	}
}