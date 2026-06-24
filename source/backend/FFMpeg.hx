#if desktop
package backend;

import lime.math.Rectangle;
import haxe.io.Bytes;
import lime.graphics.Image;
import flixel.FlxG;
import states.PlayState;
import lime.ui.Window;
import sys.FileSystem;
import sys.io.Process;
import sys.thread.Thread;

class FFMpeg {

    var x:Int;
    var y:Int;
    var window:Window;
    var buffer:Rectangle;

    public var target = "render_video";
    public var fileName = "";
    public var fileExts = ".mp4";
    public var process:Process;

    public var renderFPS:Int = 60;
    public var songName:String = "";

    public function configure(song:String, fps:Int):Void
    {
        songName = song;
        renderFPS = Std.int(Math.max(1, fps));
    }

    // REQUIRED BY YOUR ENGINE
    public var wentPreview:String = null;

    private var workerThread:Thread;
    private var isRecording:Bool = false;

    // frame control (prevents Linux stutter)
    private var frameQueue:Array<Bytes> = [];
    private var maxQueue:Int = 2;

    public static var instance:FFMpeg;

public static final codecMap:Map<String, String> = [
    'H.264' => 'libx264',
    'H.264 QSV' => 'h264_qsv',
    'H.264 NVENC' => 'h264_nvenc',
    'H.264 AMF' => 'h264_amf',
    'H.264 VAAPI' => 'h264_vaapi',
    'H.265' => 'libx265',
    'H.265 QSV' => 'hevc_qsv',
    'H.265 NVENC' => 'hevc_nvenc',
    'H.265 AMF' => 'hevc_amf',
    'H.265 VAAPI' => 'hevc_vaapi',
    'VP8' => 'libvpx',
    'VP8 VAAPI' => 'libvpx_vaapi',
    'VP9' => 'libvp9',
    'VP9 VAAPI' => 'libvp9_vaapi',
    'AV1' => 'libsvtav1',
    'AV1 NVENC' => 'av1_nvenc'
];


    public function new() {}

    public function init() {

        if (!FileSystem.exists(target)) {
            FileSystem.createDirectory(target);
        } else if (!FileSystem.isDirectory(target)) {
            FileSystem.deleteFile(target);
            FileSystem.createDirectory(target);
        }

        window = FlxG.stage.application.window;
        x = window.width;
        y = window.height;

        buffer = new Rectangle(0, 0, x, y);
    }

    // =========================
    // SETUP (COMPATIBLE)
    // =========================
    public function setup(testMode:Bool = false) {

        var executable:String = #if windows "ffmpeg.exe" #else "ffmpeg" #end;

        if (!FileSystem.exists(executable)) {
            if (testMode) throw "ffmpeg not found";

            ClientPrefs.data.previewRender = true;
            wentPreview = executable + " was not found";
            FlxG.sound.play(Paths.sound("cancelMenu"), ClientPrefs.data.sfxVolume);
            return;
        }

        var curCodec:String = ClientPrefs.data.codec;

        var songName:String = testMode
            ? "test"
            : (this.songName != "" ? this.songName : (PlayState.SONG != null ? PlayState.SONG.song : "unknown"));

        var outFPS:Int = renderFPS > 0 ? renderFPS : Std.int(Math.max(1, ClientPrefs.data.targetFPS));
        fileName = target + "/" + Paths.formatToSongPath(songName);

        var args:Array<String> = [

            "-v","quiet",
            "-y",

            // Linux stability flags
            "-fflags","nobuffer",
            "-flags","low_delay",

            "-f","rawvideo",
            "-pix_fmt","rgba",

            "-s", x + "x" + y,

            // Output FPS from in-game settings
            "-r", Std.string(outFPS),
            "-i","-",

            "-threads","0",
            "-preset","ultrafast",

            "-c:v", (codecMap.exists(curCodec) ? codecMap[curCodec] : "libx264")
        ];

        switch (ClientPrefs.data.encodeMode) {

            case "CRF/CQP":
                args.push("-b:v"); args.push("0");
                args.push("-crf");
                args.push(Std.string(ClientPrefs.data.constantQuality));

            case "VBR", "CBR":
                var bitrate = Std.string(ClientPrefs.data.bitrate * 1_000_000);

                args.push("-b:v"); args.push(bitrate);

                if (ClientPrefs.data.encodeMode == "CBR") {
                    args.push("-maxrate"); args.push(bitrate);
                    args.push("-minrate"); args.push(bitrate);
                }
        }

        args.push(fileName + fileExts);

        process = new Process(executable, args);

        isRecording = true;
        workerThread = Thread.create(worker);

        FlxG.autoPause = false;
        FlxG.sound.play(Paths.sound("confirmMenu"), ClientPrefs.data.sfxVolume);
    }

    // =========================
    // THREAD WRITER
    // =========================
    private function worker():Void {

        while (isRecording) {

            var bytes:Bytes = Thread.readMessage(true);
            if (bytes == null) break;

            try {
                process.stdin.write(bytes);
                process.stdin.flush();
            } catch (e:Dynamic) {
                trace("FFMPEG PIPE ERROR: " + e);
            }

            if (frameQueue.length > 0)
                frameQueue.shift();
        }
    }

    // =========================
    // FRAME PIPE (STABLE 60 FPS)
    // =========================
    public function pipeFrame():Void {

        if (ClientPrefs.data.previewRender) return;

        // prevent FFmpeg overload (Linux fix)
        if (frameQueue.length >= maxQueue) return;

        var image:Image = window.readPixels(buffer);
        if (image == null) return;

        // ❌ DO NOT CALL dispose() — Lime handles GC

        var bytes:Bytes = image.getPixels(buffer);

        frameQueue.push(bytes);

        if (workerThread != null)
            workerThread.sendMessage(bytes);
    }

    // =========================
    // CLEAN SHUTDOWN
    // ========================
    public function destroy():Void {

        isRecording = false;

        if (workerThread != null)
            workerThread.sendMessage(null);

        try {
            if (process != null) {

                if (process.stdin != null) {
                    process.stdin.flush();
                    process.stdin.close();
                }

                process.close();
                process.kill();
            }
        } catch (e:Dynamic) {}

        frameQueue = [];
        wentPreview = null;

        FlxG.autoPause = ClientPrefs.data.autoPause;
    }
}
#end
