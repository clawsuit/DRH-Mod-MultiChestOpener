package mods.multi_chest_opener;

import sys.io.File;

/** What the mod did, kept in its data folder so a click that does nothing can be explained. Buffered. */
class Log {
	static inline final LIMIT = 16000;

	static inline final WRITES_PER_FLUSH = 12;

	static var path:String = null;

	static var buffer:String = "";

	static var writes:Int = 0;

	public static function start(folder:String):Void {
		path = folder + "/last.log";
		buffer = "";
		writes = 0;
		write("start");
		flush();
	}

	public static function write(message:String):Void {
		buffer += message + "\n";
		if (buffer.length > LIMIT)
			buffer = buffer.substr(buffer.length - Std.int(LIMIT / 2));
		writes++;
		if (writes >= WRITES_PER_FLUSH)
			flush();
	}

	public static function flush():Void {
		writes = 0;
		if (path == null)
			return;
		try {
			File.saveContent(path, buffer);
		} catch (error:Dynamic) {}
	}
}