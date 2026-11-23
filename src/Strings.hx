package mods.multi_chest_opener;

/** The panel's words in English and Spanish; `lang` is "en" or "es". */
class Strings {
	public static var lang:String = "en";

	static var en:Map<String, String> = [
		"pick_title" => "OPEN CHESTS",
		"busy_title" => "OPENING CHESTS",
		"loot_title" => "LOOT",
		"chests" => "Chests",
		"keys" => "Keys",
		"gold" => "Gold",
		"max" => "MAX #1",
		"cost_one" => "Cost: 1 key",
		"cost_keys" => "Cost: #1 keys",
		"cost_mixed" => "Cost: #1 keys + #2 with gold (#3)",
		"pay_yes" => "PAY KEYS WITH GOLD: YES",
		"pay_no" => "PAY KEYS WITH GOLD: NO",
		"note" => "Opened one after the other, without a window per chest",
		"cancel" => "CANCEL",
		"open_one" => "OPEN 1 CHEST",
		"open_many" => "OPEN #1 CHESTS",
		"open" => "OPEN",
		"stop" => "STOP",
		"game_window" => "GAME WINDOW",
		"one_by_one" => "ONE BY ONE",
		"confirm_gold" => "CONFIRM #1 GOLD",
		"abandon_title" => "ABANDON CHESTS",
		"abandon_busy_title" => "ABANDONING CHESTS",
		"abandon_busy_chest" => "CHEST #1 OF #2",
		"abandon_busy_info" => "THESE CHESTS WILL BE LOST",
		"abandon_cost_one" => "1 chest will be lost",
		"abandon_cost" => "#1 chests will be lost",
		"abandon_one" => "ABANDON 1 CHEST",
		"abandon_many" => "ABANDON #1 CHESTS",
		"confirm_abandon" => "CONFIRM ABANDON #1",
		"abandon_note" => "This cannot be undone.",
		"abandoned_title" => "ABANDONED",
		"abandoned" => "#1 CHESTS ABANDONED",
		"abandoned_stopped" => "#1 - #2 ABANDONED",
		"busy_chest" => "CHEST #1 OF #2",
		"busy_info" => "KEYS x#1        GOLD #2",
		"loot_opened" => "#1 CHESTS OPENED",
		"loot_stopped" => "#1 - #2 OPENED",
		"page" => "PAGE #1 / #2",
		"ok" => "OK",
		"no_currency" => "NO KEYS AND NO GOLD",
		"no_keys_gold_off" => "NO KEYS - PAY WITH GOLD IS OFF",
		"no_keys_gold_short" => "NO KEYS AND NOT ENOUGH GOLD",
		"level" => "LEVEL : #1",
		"power" => "POWER #1",
		"modifiers" => "MODIFIERS",
		"none" => "NONE",
		"legendary" => "LEGENDARY",
		"kind_weapon" => "WEAPON",
		"kind_consumable" => "CONSUMABLE",
		"kind_pet" => "PET",
		"kind_bundle" => "BUNDLE",
		"kind_item" => "ITEM",
		"run_stopped" => "STOPPED",
		"run_no_keys" => "NO KEYS LEFT",
		"run_buy_failed" => "COULD NOT BUY A KEY",
		"run_refused" => "THE SERVER REFUSED A CHEST",
		"run_timeout" => "THE SERVER DID NOT ANSWER",
		"run_busy" => "THE STORAGE WAS BUSY, TRY AGAIN",
		"run_storage_full" => "STORAGE IS FULL",
		"run_partial" => "SOME CHESTS WERE BUSY"
	];

	static var es:Map<String, String> = [
		"pick_title" => "ABRIR COFRES",
		"busy_title" => "ABRIENDO...",
		"loot_title" => "BOTIN",
		"chests" => "Cofres",
		"keys" => "Llaves",
		"gold" => "Oro",
		"max" => "MAX #1",
		"cost_one" => "Coste: 1 llave",
		"cost_keys" => "Coste: #1 llaves",
		"cost_mixed" => "Coste: #1 llaves + #2 con oro (#3)",
		"pay_yes" => "PAGAR LLAVES CON ORO: SI",
		"pay_no" => "PAGAR LLAVES CON ORO: NO",
		"note" => "Se abren seguidos, sin ventana por cofre",
		"cancel" => "CANCELAR",
		"open_one" => "ABRIR 1 COFRE",
		"open_many" => "ABRIR #1 COFRES",
		"open" => "ABRIR",
		"stop" => "PARAR",
		"game_window" => "VENTANA DEL JUEGO",
		"one_by_one" => "DE UNO EN UNO",
		"confirm_gold" => "CONFIRMAR #1 ORO",
		"abandon_title" => "ABANDONAR COFRES",
		"abandon_busy_title" => "ABANDONANDO...",
		"abandon_busy_chest" => "COFRE #1 DE #2",
		"abandon_busy_info" => "ESTOS COFRES SE PERDERAN",
		"abandon_cost_one" => "Se perdera 1 cofre",
		"abandon_cost" => "Se perderan #1 cofres",
		"abandon_one" => "ABANDONAR 1 COFRE",
		"abandon_many" => "ABANDONAR #1 COFRES",
		"confirm_abandon" => "CONFIRMAR ABANDONAR #1",
		"abandon_note" => "No se puede deshacer.",
		"abandoned_title" => "ABANDONADOS",
		"abandoned" => "#1 COFRES ABANDONADOS",
		"abandoned_stopped" => "#1 - #2 ABANDONADOS",
		"busy_chest" => "COFRE #1 DE #2",
		"busy_info" => "LLAVES x#1        ORO #2",
		"loot_opened" => "#1 COFRES ABIERTOS",
		"loot_stopped" => "#1 - #2 ABIERTOS",
		"page" => "PAG #1 / #2",
		"ok" => "VALE",
		"no_currency" => "SIN LLAVES NI ORO",
		"no_keys_gold_off" => "SIN LLAVES - EL PAGO CON ORO ESTA APAGADO",
		"no_keys_gold_short" => "SIN LLAVES Y ORO INSUFICIENTE",
		"level" => "NIVEL : #1",
		"power" => "PODER #1",
		"modifiers" => "MODIFICADORES",
		"none" => "NINGUNO",
		"legendary" => "LEGENDARIA",
		"kind_weapon" => "ARMA",
		"kind_consumable" => "CONSUMIBLE",
		"kind_pet" => "MASCOTA",
		"kind_bundle" => "LOTE",
		"kind_item" => "OBJETO",
		"run_stopped" => "DETENIDO",
		"run_no_keys" => "SIN LLAVES",
		"run_buy_failed" => "NO SE PUDO COMPRAR LA LLAVE",
		"run_refused" => "EL SERVIDOR RECHAZO UN COFRE",
		"run_timeout" => "EL SERVIDOR NO RESPONDIO",
		"run_busy" => "EL INVENTARIO ESTABA OCUPADO, INTENTA OTRA VEZ",
		"run_storage_full" => "EL ALMACEN ESTA LLENO",
		"run_partial" => "ALGUNOS COFRES ESTABAN OCUPADOS"
	];

	public static function t(key:String):String {
		var table = lang == "es" ? es : en;
		var value = table.get(key);
		if (value == null)
			value = en.get(key);
		return value == null ? key : value;
	}

	/** A phrase with #1, #2 and #3 filled in. */
	public static function f(key:String, a:String, b:String = null, c:String = null):String {
		var text = t(key);
		text = StringTools.replace(text, "#1", a);
		if (b != null)
			text = StringTools.replace(text, "#2", b);
		if (c != null)
			text = StringTools.replace(text, "#3", c);
		return text;
	}
}