package mods.multi_chest_opener;

import haxe.Json;
import sys.FileSystem;
import sys.io.File;

/** What the player picked last, kept in the mod's data folder: the amount, the gold and the language. */
class Settings {
	static inline final FILE = "settings.json";

	static inline final MAX_AMOUNT = 999;

	public var amount:Int = 1;

	public var payGold:Bool = true;

	/** "en" or "es". */
	public var language:String = "en";

	var path:String;

	var log:String->Void;

	public function new(folder:String, log:String->Void) {
		path = folder + "/" + FILE;
		this.log = log;
		load();
		applyLanguage();
	}

	public function applyLanguage():Void {
		Strings.lang = language == "es" ? "es" : "en";
	}

	public function save():Void {
		var data = {
			amount: amount,
			payGold: payGold,
			language: language
		};
		try {
			File.saveContent(path, Json.stringify(data, null, "\t"));
		} catch (error:Dynamic) {
			log("could not save " + FILE + ": " + error);
		}
	}

	function load():Void {
		if (!FileSystem.exists(path))
			return;
		try {
			var data:Dynamic = Json.parse(File.getContent(path));
			if (data.amount != null) {
				var value = Std.int(data.amount);
				amount = value < 1 ? 1 : (value > MAX_AMOUNT ? MAX_AMOUNT : value);
			}
			if (data.payGold != null)
				payGold = data.payGold == true;
			if (data.language != null)
				language = Std.string(data.language) == "es" ? "es" : "en";
		} catch (error:Dynamic) {
			log("could not read " + FILE + ", the defaults apply: " + error);
		}
	}
}
