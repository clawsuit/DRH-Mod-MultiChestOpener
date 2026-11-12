package mods.multi_chest_opener;

/**
 * What the mod did, kept in its data folder so a click that does nothing can be explained. It is
 * small and only written on the events that matter: load, hook, click, panel, run.
 */
class Log {
	static inline final LIMIT = 16000;

	static var path:String = null;

	static var buffer:String = "";

	public static function start(folder:String):Void {
		path = folder + "/last.log";
		buffer = "";
		write("start");
	}

	public static function write(message:String):Void {
		buffer += message + "\n";
		if (buffer.length > LIMIT)
			buffer = buffer.substr(buffer.length - LIMIT / 2);
		flush();
	}

	static function flush():Void {
		if (path == null)
			return;
		try {
			sys.io.File.saveContent(path, buffer);
		} catch (error:Dynamic) {}
	}
}
