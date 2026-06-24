package states;

import backend.WeekData;
import backend.Highscore;
import backend.Song;

import objects.HealthIcon;
import objects.MusicPlayer;

import options.GameplayChangersSubstate;
import substates.ResetScoreSubState;

import flixel.FlxObject;
import flixel.effects.FlxFlicker;
import flixel.math.FlxMath;
import flixel.util.FlxDestroyUtil;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	private static var curSelected:Int = 0;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = Difficulty.getDefault();

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	private var iconArray:Array<HealthIcon> = [];

	var menuItems:FlxTypedGroup<FlxSprite>;
	var buttonLabels:Map<FlxSprite, FlxText> = new Map();
	var camFollow:FlxObject;

	var magenta:FlxSprite;
	var menuTitle:FlxText;
	var menuHint:FlxText;

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	var bottomString:String;
	var bottomText:FlxText;
	var holdTime:Float = 0;

	var player:MusicPlayer;

	var selectedSomethin:Bool = false;
	var timeNotMoving:Float = 0;
	var allowMouse:Bool = true;

	var instPlaying:Int = -1;
	public static var vocals:FlxSound = null;
	public static var opponentVocals:FlxSound = null;

	var stopMusicPlay:Bool = false;

	override function create()
	{
		super.create();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Menus", null);
		#end

		persistentUpdate = persistentDraw = true;

		// Modern UI
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

		menuTitle = new FlxText(56, 36, 420, "FREEPLAY", 24);
		menuTitle.scrollFactor.set();
		menuTitle.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT);
		add(menuTitle);

		menuHint = new FlxText(56, 92, 210, "", 16);
		menuHint.scrollFactor.set();
		menuHint.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		add(menuHint);

		var fileLabel:FlxText = new FlxText(1000, 36, 160, "Freeplay", 16);
		fileLabel.scrollFactor.set();
		fileLabel.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		add(fileLabel);

		WeekData.reloadWeekFiles(false);

		if (WeekData.weeksList.length < 1)
		{
			FlxTransitionableState.skipNextTransIn = true;
			persistentUpdate = false;
			MusicBeatState.switchState(new states.ErrorState("NO WEEKS ADDED FOR FREEPLAY\n\nPress ACCEPT to go to the Week Editor Menu.\nPress BACK to return to Main Menu.",
				function() MusicBeatState.switchState(new states.editors.WeekEditorState()),
				function() MusicBeatState.switchState(new states.MainMenuState())));
			return;
		}

		for (i in 0...WeekData.weeksList.length)
		{
			if (weekIsLocked(WeekData.weeksList[i])) continue;
			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			WeekData.setDirectoryFromWeek(leWeek);

			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song[2] != null && song[2].length >= 3 ? song[2] : [146, 113, 253];
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
		}
		Mods.loadTopMod();
		WeekData.setDirectoryFromWeek();

		var menuStartY:Float = 132;
		var menuSpacing:Float = 68;
		for (i in 0...songs.length)
			createSongItem(i, 330, menuStartY + (i * menuSpacing));

		// Score Panel
		scoreBG = new FlxSprite(775, 115).makeGraphic(390, 100, 0xFF2A3347);
		scoreBG.scrollFactor.set();
		add(scoreBG);

		scoreText = new FlxText(790, 125, 360, "", 28);
		scoreText.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, RIGHT);
		scoreText.scrollFactor.set();
		add(scoreText);

		diffText = new FlxText(790, 158, 360, "", 22);
		diffText.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.WHITE, RIGHT);
		diffText.scrollFactor.set();
		add(diffText);

		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);

		missingText = new FlxText(50, 220, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		// Keep these because MusicPlayer uses them
		bottomString = Language.getPhrase("freeplay_tip", "Press SPACE to listen to the Song / Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.");
		bottomText = new FlxText(0, FlxG.height - 22, FlxG.width, bottomString, 16);
		bottomText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
		bottomText.scrollFactor.set();
		add(bottomText);

		player = new MusicPlayer(this);
		add(player);

		if (curSelected >= songs.length) curSelected = 0;
		changeSelection();
		FlxG.camera.follow(camFollow, null, 0.25);

		super.create();
	}

	function createSongItem(idx:Int, x:Float, y:Float)
	{
		var item:FlxSprite = new FlxSprite(x, y).makeGraphic(560, 54, 0xFF232A38);
		item.scrollFactor.set(1, 1);
		item.antialiasing = ClientPrefs.data.antialiasing;
		item.alpha = 0.92;
		item.ID = idx;
		menuItems.add(item);

		var label:FlxText = new FlxText(x + 20, y + 15, 420, songs[idx].songName.toUpperCase(), 20);
		label.scrollFactor.set(1, 1);
		label.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT);
		add(label);
		buttonLabels.set(item, label);

		Mods.currentModDirectory = songs[idx].folder;
		var icon:HealthIcon = new HealthIcon(songs[idx].songCharacter);
		icon.setGraphicSize(0, 42);
		icon.updateHitbox();
		icon.x = x + 480;
		icon.y = y + 6;
		icon.scrollFactor.set(1, 1);
		add(icon);
		iconArray.push(icon);
	}

	function styleButton(button:FlxSprite, active:Bool)
	{
		if (button == null) return;
		button.color = active ? 0xFF36415A : 0xFF232A38;
		button.alpha = active ? 1 : 0.92;

		var label = buttonLabels.get(button);
		if (label != null) label.alpha = active ? 1 : 0.78;

		var idx = menuItems.members.indexOf(button);
		if (idx >= 0 && idx < iconArray.length)
			iconArray[idx].alpha = active ? 1 : 0.6;
	}

	function getMenuHint():String
	{
		return songs.length > 0 ? songs[curSelected].songName.toUpperCase() : "";
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
	}

	function weekIsLocked(name:String):Bool
	{
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 &&
			(!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	public static function destroyFreeplayVocals()
	{
		if (vocals != null) vocals.stop();
		vocals = FlxDestroyUtil.destroy(vocals);
		if (opponentVocals != null) opponentVocals.stop();
		opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
	}

	override function update(elapsed:Float)
	{
		if (WeekData.weeksList.length < 1) return;

		if (FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume = Math.min(FlxG.sound.music.volume + 0.5 * elapsed, 0.8);

		lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 24)));
		lerpRating = FlxMath.lerp(intendedRating, lerpRating, Math.exp(-elapsed * 12));

		if (!selectedSomethin)
		{
			if (!player.playingMusic)
			{
				scoreText.text = 'SCORE: ' + lerpScore;
			}

			if (controls.UI_UP_P) changeSelection(-1);
			if (controls.UI_DOWN_P) changeSelection(1);

			if (allowMouse && ((FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0) || FlxG.mouse.justPressed))
			{
				FlxG.mouse.visible = true;
				timeNotMoving = 0;
				for (i in 0...menuItems.members.length)
				{
					if (FlxG.mouse.overlaps(menuItems.members[i]))
					{
						if (curSelected != i)
						{
							curSelected = i;
							changeSelection();
						}
						break;
					}
				}
			}
			else
			{
				timeNotMoving += elapsed;
				if (timeNotMoving > 2) FlxG.mouse.visible = false;
			}

			if (controls.UI_LEFT_P) changeDiff(-1);
			if (controls.UI_RIGHT_P) changeDiff(1);

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.mouse.visible = false;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				if (player.playingMusic)
				{
					FlxG.sound.music.stop();
					destroyFreeplayVocals();
					player.playingMusic = false;
					player.switchPlayMusic();
					FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
					FlxTween.tween(FlxG.sound.music, {volume: 1}, 1);
				}
				MusicBeatState.switchState(new MainMenuState());
				return;
			}

			if ((controls.ACCEPT || (FlxG.mouse.justPressed && allowMouse)) && !player.playingMusic)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('confirmMenu'));
				FlxG.mouse.visible = false;

				if (ClientPrefs.data.flashing)
					FlxFlicker.flicker(magenta, 1.0, 0.15, false);

				var item = menuItems.members[curSelected];
				FlxFlicker.flicker(item, 0.9, 0.05, false, false, function(_) { loadSong(); });
			}

			if (FlxG.keys.justPressed.CONTROL && !player.playingMusic)
			{
				persistentUpdate = false;
				openSubState(new GameplayChangersSubstate());
			}

			if (controls.RESET && !player.playingMusic)
			{
				persistentUpdate = false;
				openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
			}
		}

		super.update(elapsed);
	}

	function loadSong()
	{
		var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
		var poop:String = Highscore.formatSong(songLowercase, curDifficulty);

		try
		{
			Song.loadFromJson(poop, songLowercase);
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = curDifficulty;
		}
		catch(e:haxe.Exception)
		{
			missingText.text = 'ERROR WHILE LOADING CHART:\n' + e.message;
			missingText.visible = missingTextBG.visible = true;
			selectedSomethin = false;
			return;
		}

		LoadingState.prepareToSong();
		LoadingState.loadAndSwitchState(new PlayState());
		destroyFreeplayVocals();
		stopMusicPlay = true;
	}

	function changeSelection(change:Int = 0)
	{
		if (player.playingMusic) return;

		curSelected = FlxMath.wrap(curSelected + change, 0, songs.length - 1);
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		for (item in menuItems) styleButton(item, false);
		styleButton(menuItems.members[curSelected], true);

		menuHint.text = getMenuHint();

		var sel = menuItems.members[curSelected];
		camFollow.setPosition(sel.x + sel.width * 0.5, sel.y + sel.height * 0.5);

		_updateSongLastDifficulty();
		changeDiff();
	}

	function changeDiff(change:Int = 0)
	{
		if (player.playingMusic) return;

		Difficulty.loadFromWeek();
		var maxDiff = Difficulty.list.length > 0 ? Difficulty.list.length - 1 : 0;
		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, maxDiff);

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		lastDifficultyName = Difficulty.getString(curDifficulty, false);
		var displayDiff:String = Difficulty.getString(curDifficulty);
		diffText.text = (Difficulty.list.length > 1) ? '< ' + displayDiff.toUpperCase() + ' >' : displayDiff.toUpperCase();

		positionHighscore();
		missingText.visible = missingTextBG.visible = false;
	}

	inline private function _updateSongLastDifficulty()
		if (songs.length > 0) songs[curSelected].lastDifficulty = Difficulty.getString(curDifficulty, false);

	private function positionHighscore(){}

	override function destroy():Void
	{
		super.destroy();
		if (!FlxG.sound.music.playing && !stopMusicPlay)
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var folder:String = "";
	public var lastDifficulty:String = null;

	public function new(song:String, week:Int, songCharacter:String, color:Int)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Mods.currentModDirectory ?? '';
	}
}