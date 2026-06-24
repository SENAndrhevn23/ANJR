package options;

class OptimizeSettingsSubState extends BaseOptionsMenu
{
	var limitCount:Option;

	public static final SORT_PATTERN:Array<String> = [
		'Never',
		'After Note Spawned',
		'After Note Processed',
		'After Note Finalized',
		'Reversed',
		'Chaotic',
		'Random',
		'Shuffle',
	];

	public function new()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Optimizations Menu", null);
		#end

		title = 'Optimizations';
		rpcTitle = 'Optimization Settings Menu';

		var opt:Option;

		opt = new Option('Work in Progress',
			"Make changes at your own risk.",
			'openDoor',
			STRING,
			['!']);
		addOption(opt);

		opt = new Option('Show Notes',
			"If unchecked, appearTime is set to 0.\nAll notes will be processed as skipped notes.\nBotplay is forced on.",
			'showNotes',
			BOOL);
		addOption(opt);

		opt = new Option('Show Notes again after Skip',
			"If checked, it tries to prevent notes from showing only halfway through.",
			'showAfter',
			BOOL);
		addOption(opt);

		opt = new Option('Keep Notes in Screen',
			"If checked, notes will display from top to bottom, even if they are skippable.\nIf unchecked, it improves performance, especially if a lot of notes are displayed.",
			'keepNotes',
			BOOL);
		addOption(opt);

		opt = new Option('Note Sorting:',
			"If not set to 'Never', the notes array is sorted every frame when notes are added.\nUsing 'Never' improves performance, especially if a lot of notes are displayed.\nDefault: \"After Note Finalized\"",
			'sortNotes',
			STRING,
			SORT_PATTERN);
		addOption(opt);

		opt = new Option('Faster Sort',
			"If checked, only visible notes will be sorted.",
			'fastSort',
			BOOL);
		addOption(opt);

		opt = new Option('Better Recycling',
			"If checked, the game will use NoteGroup's recycle system.\nIt boosts game performance massively.",
			'betterRecycle',
			BOOL);
		addOption(opt);

		limitCount = new Option('Max Notes Shown:',
			"What should be the max amount of notes rendered onscreen? To remove this limit, set the value to 0.",
			'limitNotes',
			INT);
		limitCount.scrollSpeed = 30;
		limitCount.minValue = 0;
		limitCount.maxValue = 99999;
		limitCount.changeValue = 1;
		limitCount.decimals = 0;
		addOption(limitCount);

		opt = new Option('Overlapped Threshold:',
			"How many notes can overlap before the game starts hiding older notes? Lower values improve performance.",
			'hideOverlapped',
			FLOAT);
		opt.scrollSpeed = 1;
		opt.minValue = 0;
		opt.maxValue = 9999;
		opt.changeValue = 0.05;
		opt.decimals = 2;
		addOption(opt);

		opt = new Option('Process Notes before Spawning',
			"If checked, the game will process upcoming notes earlier. This can reduce spikes in heavy charts.",
			'processFirst',
			BOOL);
		addOption(opt);

		opt = new Option('Note Skipping',
			"If checked, the game can skip notes.\nIt boosts game performance massively, but only in specific scenarios.\nIf you don't understand, enable this.",
			'skipSpawnNote',
			BOOL);
		addOption(opt);

		opt = new Option('Bulk Skipping',
			"If checked, enables bulk skipping.\nIt boosts game performance a lot, especially when handling millions of NPS.\nIf you don't understand, enable this.",
			'bulkSkip',
			BOOL);
		addOption(opt);

		opt = new Option('Spawning Time Limit',
			"If checked, the note spawn loop cancels if the time limit is exceeded.\nIt may boost performance on some scenarios.",
			'breakTimeLimit',
			BOOL);
		addOption(opt);

		opt = new Option('Insta-Check Spawned Notes',
			"If checked, it judges whether or not to do hit logic\nimmediately after a note is spawned. It boosts game performance massively,\nbut only in specific scenarios. If you don't understand, enable this.",
			'optimizeSpawnNote',
			BOOL);
		addOption(opt);

		opt = new Option('noteHitPreEvents',
			"If unchecked, the game will not send any noteHitPreEvent on Lua/HScript.",
			'noteHitPreEvent',
			BOOL);
		addOption(opt);

		opt = new Option('noteHitEvents',
			"If unchecked, the game will not send any noteHitEvent on Lua/HScript.\nNot recommended to disable this option.",
			'noteHitEvent',
			BOOL);
		addOption(opt);

		opt = new Option('spawnNoteEvents',
			"If unchecked, the game will not send spawn event\non Lua/HScript for spawned notes. Improves performance.",
			'spawnNoteEvent',
			BOOL);
		addOption(opt);

		opt = new Option('noteHitEvents for stages',
			"If unchecked, the game will not send any noteHitEvent on stage.\nNot recommended to disable this option for vanilla stages.",
			'noteHitStage',
			BOOL);
		addOption(opt);

		opt = new Option('noteHitEvents for Skipped Notes',
			"If unchecked, the game will not send any hit event\non Lua/HScript for skipped notes. Improves performance.",
			'skipNoteEvent',
			BOOL);
		addOption(opt);

		opt = new Option('Disable Garbage Collector',
			"If checked, you can play the main game without GC lag.\nIt only works on loading/playing charts.",
			'disableGC',
			BOOL);
		addOption(opt);

		super();
	}


	function interpolate(min:Float, max:Float, ratio:Float, power:Float = 1):Float
	{
		var t:Float = ratio;
		if (t < 0) t = 0;
		if (t > 1) t = 1;
		if (power != 1) t = Math.pow(t, power);
		return min + (max - min) * t;
	}
	function onChangeLimitCount()
	{
		if (limitCount != null)
			limitCount.scrollSpeed = interpolate(30, 50000, (holdTime - 0.5) / 10, 3);
	}
}

class OptimizationsSubState extends OptimizeSettingsSubState
{
	public function new()
	{
		super();
	}
}
