package states;

import flixel.FlxObject;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import states.editors.MasterEditorMenu;
import options.OptionsState;

enum MainMenuColumn {
	LEFT;
	CENTER;
	RIGHT;
}

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '1.0.4'; // This is also used for Discord RPC
	public static var curSelected:Int = 0;
	public static var curColumn:MainMenuColumn = CENTER;
	var allowMouse:Bool = true; //Turn this off to block mouse movement in menus

	var menuItems:FlxTypedGroup<FlxSprite>;
	var leftItem:FlxSprite;
	var rightItem:FlxSprite;

	// Centered/Text options - Achievements and Options have been moved here
	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		#if MODS_ALLOWED 'mods', #end
		'credits',
		#if ACHIEVEMENTS_ALLOWED 'achievements', #end
		'options'
	];

	// Side options are now nullified since they are in the main list
	var leftOption:String = null;
	var rightOption:String = null;

	var magenta:FlxSprite;
	var camFollow:FlxObject;
	var buttonLabels:Map<FlxSprite, FlxText> = new Map();
	var menuTitle:FlxText;
	var menuHint:FlxText;

	static var showOutdatedWarning:Bool = true;
	override function create()
	{
		super.create();

		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end


		persistentUpdate = persistentDraw = true;

		var darkBg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF11151D);
		darkBg.scrollFactor.set();
		add(darkBg);

		var gridBg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF151A24);
		gridBg.scrollFactor.set();
		gridBg.alpha = 0.88;
		add(gridBg);

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

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		magenta = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0x55FF4E9B);
		magenta.antialiasing = ClientPrefs.data.antialiasing;
		magenta.scrollFactor.set();
		magenta.visible = false;
		add(magenta);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		menuTitle = new FlxText(56, 36, 420, "MAIN MENU", 24);
		menuTitle.scrollFactor.set();
		menuTitle.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT);
		add(menuTitle);

		menuHint = new FlxText(56, 92, 210, "", 16);
		menuHint.scrollFactor.set();
		menuHint.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		add(menuHint);

		var fileLabel:FlxText = new FlxText(1000, 36, 160, "File / Edit / View", 16);
		fileLabel.scrollFactor.set();
		fileLabel.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		add(fileLabel);

		var menuStartY:Float = 132;
		var menuSpacing:Float = 68;
		for (num => option in optionShit)
		{
			var item:FlxSprite = createMenuItem(option, 330, menuStartY + (num * menuSpacing), 'main');
			item.scrollFactor.set();
		}

		if (leftOption != null)
			leftItem = createMenuItem(leftOption, 56, 430, 'side');
		if (rightOption != null)
			rightItem = createMenuItem(rightOption, 176, 430, 'side');

		var psychVer:FlxText = new FlxText(56, 500, 0, "Psych Engine v" + psychEngineVersion, 12);
		psychVer.scrollFactor.set();
		psychVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(psychVer);
		var fnfVer:FlxText = new FlxText(56, 520, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		fnfVer.scrollFactor.set();
		fnfVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(fnfVer);

		var footerHint:FlxText = new FlxText(320, 551, 840, "Arrows / Enter to navigate, Esc to leave", 16);
		footerHint.scrollFactor.set();
		footerHint.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		add(footerHint);

		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		// Unlocks "Freaky on a Friday Night" achievement if it's a Friday and between 18:00 PM and 23:59 PM
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
			Achievements.unlock('friday_night_play');

		#if MODS_ALLOWED
		Achievements.reloadList();
		#end
		#end

		#if CHECK_FOR_UPDATES
		if (showOutdatedWarning && ClientPrefs.data.checkForUpdates && substates.OutdatedSubState.updateVersion != psychEngineVersion) {
			persistentUpdate = false;
			showOutdatedWarning = false;
			openSubState(new substates.OutdatedSubState());
		}
		#end

		FlxG.camera.follow(camFollow, null, 0.15);
	}


	function createMenuItem(name:String, x:Float, y:Float, ?mode:String = 'main'):FlxSprite
	{
		var isSide:Bool = mode == 'side';
		var buttonW:Int = isSide ? 104 : 560;
		var buttonH:Int = isSide ? 38 : 54;

		var menuItem:FlxSprite = new FlxSprite(x, y).makeGraphic(buttonW, buttonH, 0xFF232A38);
		menuItem.scrollFactor.set();
		menuItem.antialiasing = ClientPrefs.data.antialiasing;
		menuItem.alpha = 0.92;
		menuItem.ID = menuItems.length;
		menuItems.add(menuItem);

		var label:FlxText = new FlxText(x + 12, y + (isSide ? 8 : 15), buttonW - 24, formatMenuName(name), 16);
		label.scrollFactor.set();
		label.setFormat(Paths.font("vcr.ttf"), isSide ? 16 : 20, FlxColor.WHITE, LEFT);
		add(label);
		buttonLabels.set(menuItem, label);

		return menuItem;
	}

	function formatMenuName(name:String):String
	{
		var nice:String = name.split('_').join(' ');
		return nice.toUpperCase();
	}

	function getMenuHint(option:String):String
	{
		return switch(option)
		{
			case 'story_mode': 'Play through the story weeks.';
			case 'freeplay': 'Jump straight into any song.';
			#if MODS_ALLOWED
			case 'mods': 'Manage installed mods.';
			#end
			#if ACHIEVEMENTS_ALLOWED
			case 'achievements': 'Check unlocked achievements.';
			#end
			case 'credits': 'See who made the game.';
			case 'options': 'Open gameplay and visual settings.';
			default: 'Select an option to continue.';
		}
	}

	function styleButton(button:FlxSprite, active:Bool)
	{
		if(button == null) return;
		button.color = active ? 0xFF36415A : 0xFF232A38;
		button.alpha = active ? 1 : 0.92;

		var label:FlxText = buttonLabels.get(button);
		if(label != null)
		{
			label.alpha = active ? 1 : 0.78;
		}
	}

	var selectedSomethin:Bool = false;

	var timeNotMoving:Float = 0;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume = Math.min(FlxG.sound.music.volume + 0.5 * elapsed, 0.8);

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
				changeItem(-1);

			if (controls.UI_DOWN_P)
				changeItem(1);

			var allowMouse:Bool = allowMouse;
			if (allowMouse && ((FlxG.mouse.deltaScreenX != 0 && FlxG.mouse.deltaScreenY != 0) || FlxG.mouse.justPressed))
			{
				allowMouse = false;
				FlxG.mouse.visible = true;
				timeNotMoving = 0;

				var selectedItem:FlxSprite;
				switch(curColumn)
				{
					case CENTER:
						selectedItem = menuItems.members[curSelected];
					case LEFT:
						selectedItem = leftItem;
					case RIGHT:
						selectedItem = rightItem;
				}

				if(leftItem != null && FlxG.mouse.overlaps(leftItem))
				{
					allowMouse = true;
					if(selectedItem != leftItem)
					{
						curColumn = LEFT;
						changeItem();
					}
				}
				else if(rightItem != null && FlxG.mouse.overlaps(rightItem))
				{
					allowMouse = true;
					if(selectedItem != rightItem)
					{
						curColumn = RIGHT;
						changeItem();
					}
				}
				else
				{
					var dist:Float = -1;
					var distItem:Int = -1;
					for (i in 0...optionShit.length)
					{
						var memb:FlxSprite = menuItems.members[i];
						if(FlxG.mouse.overlaps(memb))
						{
							var distance:Float = Math.sqrt(Math.pow(memb.getGraphicMidpoint().x - FlxG.mouse.screenX, 2) + Math.pow(memb.getGraphicMidpoint().y - FlxG.mouse.screenY, 2));
							if (dist < 0 || distance < dist)
							{
								dist = distance;
								distItem = i;
								allowMouse = true;
							}
						}
					}

					if(distItem != -1 && selectedItem != menuItems.members[distItem])
					{
						curColumn = CENTER;
						curSelected = distItem;
						changeItem();
					}
				}
			}
			else
			{
				timeNotMoving += elapsed;
				if(timeNotMoving > 2) FlxG.mouse.visible = false;
			}

			switch(curColumn)
			{
				case CENTER:
					if(controls.UI_LEFT_P && leftOption != null)
					{
						curColumn = LEFT;
						changeItem();
					}
					else if(controls.UI_RIGHT_P && rightOption != null)
					{
						curColumn = RIGHT;
						changeItem();
					}

				case LEFT:
					if(controls.UI_RIGHT_P)
					{
						curColumn = CENTER;
						changeItem();
					}

				case RIGHT:
					if(controls.UI_LEFT_P)
					{
						curColumn = CENTER;
						changeItem();
					}
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.mouse.visible = false;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT || (FlxG.mouse.justPressed && allowMouse))
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				selectedSomethin = true;
				FlxG.mouse.visible = false;

				if (ClientPrefs.data.flashing)
					FlxFlicker.flicker(magenta, 1.0, 0.15, false);

				var item:FlxSprite;
				var option:String;
				switch(curColumn)
				{
					case CENTER:
						option = optionShit[curSelected];
						item = menuItems.members[curSelected];
					case LEFT:
						option = leftOption;
						item = leftItem;
					case RIGHT:
						option = rightOption;
						item = rightItem;
				}

				FlxFlicker.flicker(item, 0.9, 0.05, false, false, function(flick:FlxFlicker)
				{
					switch (option)
					{
						case 'story_mode':
							MusicBeatState.switchState(new StoryMenuState());
						case 'freeplay':
							MusicBeatState.switchState(new FreeplayState());

						#if MODS_ALLOWED
						case 'mods':
							MusicBeatState.switchState(new ModsMenuState());
						#end

						#if ACHIEVEMENTS_ALLOWED
						case 'achievements':
							MusicBeatState.switchState(new AchievementsMenuState());
						#end

						case 'credits':
							MusicBeatState.switchState(new CreditsState());
						case 'options':
							MusicBeatState.switchState(new OptionsState());
							OptionsState.onPlayState = false;
							if (PlayState.SONG != null)
							{
								PlayState.SONG.arrowSkin = null;
								PlayState.SONG.splashSkin = null;
								PlayState.stageUI = 'normal';
							}
						default:
							trace('Menu Item ${option} doesn\'t do anything');
							selectedSomethin = false;
					}
				});
			}

			#if desktop
			if (controls.justPressed('debug_1'))
			{
				selectedSomethin = true;
				FlxG.mouse.visible = false;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		super.update(elapsed);
	}


	function changeItem(change:Int = 0)
	{
		if(change != 0) curColumn = CENTER;
		curSelected = FlxMath.wrap(curSelected + change, 0, optionShit.length - 1);
		FlxG.sound.play(Paths.sound('scrollMenu'));

		for (item in menuItems)
		{
			styleButton(item, false);
		}
		styleButton(leftItem, false);
		styleButton(rightItem, false);

		var selectedItem:FlxSprite;
		var selectedOption:String;
		switch(curColumn)
		{
			case CENTER:
				selectedItem = menuItems.members[curSelected];
				selectedOption = optionShit[curSelected];
			case LEFT:
				selectedItem = leftItem;
				selectedOption = leftOption;
			case RIGHT:
				selectedItem = rightItem;
				selectedOption = rightOption;
		}

		styleButton(selectedItem, true);
		menuHint.text = selectedOption == null ? 'Select an option to continue.' : getMenuHint(selectedOption);

		camFollow.setPosition(selectedItem.x + selectedItem.width * 0.5, selectedItem.y + selectedItem.height * 0.5);
	}
}