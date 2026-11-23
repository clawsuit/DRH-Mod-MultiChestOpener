package mods.multi_chest_opener;

import haxe.Json;
import sys.FileSystem;
import sys.io.File;

/**
 * The mod's own settings, kept in its data folder: the panel's language and gold switch. Nothing here
 * is shown in the game's settings menu.
 */
class Settings {
	static inline final FILE = "settings.json";

	public var language:String = "en";

	public var payGold:Bool = true;

	var path:String;

	var log:String->Void;

	public function new(folder:String, log:String->Void) {
		path = folder + "/" + FILE;
		this.log = log;
		load();
	}

	public function save():Void {
		try {
			File.saveContent(path, Json.stringify({language: language, payGold: payGold}, null, "\t"));
		} catch (error:Dynamic) {
			log("could not save " + FILE + ": " + error);
		}
	}

	function load():Void {
		if (!FileSystem.exists(path))
			return;
		try {
			var content = File.getContent(path);
			if (content.length > 0 && content.charCodeAt(0) == 0xFEFF)
				content = content.substr(1);
			var data:Dynamic = Json.parse(content);
			if (data == null)
				return;
			// The API wrote {options, keys}; older versions wrote the values at the top.
			var source:Dynamic = data.options != null ? data.options : data;
			if (source.language != null)
				language = Std.string(source.language) == "es" ? "es" : "en";
			if (source.payGold != null)
				payGold = source.payGold == true;
		} catch (error:Dynamic) {
			log("could not read " + FILE + ", the defaults apply: " + error);
		}
	}
}