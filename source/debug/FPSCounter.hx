package debug;

import flixel.FlxG;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.filters.DropShadowFilter;
import openfl.system.System;
import backend.Paths;

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project, updated to match the new UI.
**/
class FPSCounter extends TextField
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int;

	/**
		The current memory usage
	**/
	public var memoryMegas(get, never):Float;

	@:noCompletion private var times:Array<Float>;

	public function new(x:Float = 15, y:Float = 15, color:Int = 0xFFFFFF)
	{
		super();

		this.x = x;
		this.y = y;

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		
		// Use the custom VCR font asset to lock down the UI theme matching
		var fontName:String = Paths.font("vcr.ttf");
		if (fontName == null || fontName == "") fontName = "_sans"; // Fallback safety
		
		defaultTextFormat = new TextFormat(fontName, 14, color);
		autoSize = LEFT;
		multiline = true;
		
		// Optional styling: Adds a sharp 1px drop shadow to make text pop against dark panels
		this.filters = [new DropShadowFilter(1, 45, 0x000000, 0.8, 1, 1, 1)];

		text = "FPS: ";
		times = [];
	}

	var deltaTimeout:Float = 0.0;

	// Event Handlers
	private override function __enterFrame(deltaTime:Float):Void
	{
		final now:Float = haxe.Timer.stamp() * 1000;
		times.push(now);
		while (times[0] < now - 1000) times.shift();
		
		if (deltaTimeout < 50) {
			deltaTimeout += deltaTime;
			return;
		}

		currentFPS = times.length < FlxG.updateFramerate ? times.length : FlxG.updateFramerate;		
		updateText();
		deltaTimeout = 0.0;
	}

	public dynamic function updateText():Void 
	{
		// Clean uppercase formatting matching your system layouts
		text = 'FPS: ${currentFPS}'
		+ '\nMEM: ${flixel.util.FlxStringUtil.formatBytes(memoryMegas).toUpperCase()}';

		// Dynamically alerts with the UI accent red if performance drops below half target
		if (currentFPS < FlxG.drawFramerate * 0.5)
			textColor = 0xFFFF4444;
		else
			textColor = 0xFF6D7A9A; // Styled to match your accentLine tint (0xFF6D7A9A)
	}

	inline function get_memoryMegas():Float
		return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);
}