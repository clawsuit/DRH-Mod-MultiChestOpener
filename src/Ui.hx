package mods.multi_chest_opener;

import openfl.filters.GlowFilter;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

/** The colours and the labels the panel is drawn with. */
class Ui {
	public static inline final GOLD = 0xF2C14E;

	public static inline final GOLD_DARK = 0x8C6A2A;

	public static inline final PARCHMENT = 0x3A2412;

	public static inline final PANEL = 0x241408;

	public static inline final INK = 0x120A04;

	public static inline final TEXT = 0xFFF1D0;

	public static inline final DIM = 0xC4A87C;

	public static inline final GREEN = 0x8CE05E;

	public static inline final RED = 0xE8704A;

	/** A label in a bold font, outlined as the game's texts are. */
	public static function text(size:Int, color:Int, width:Float, align:TextFormatAlign, wrap:Bool = false):TextField {
		var field = new TextField();
		field.width = width;
		field.height = size * (wrap ? 3.0 : 2.0);
		field.selectable = false;
		field.mouseEnabled = false;
		field.multiline = wrap;
		field.wordWrap = wrap;
		field.defaultTextFormat = new TextFormat("_sans", size, color, true, null, null, null, null, align);
		field.filters = [new GlowFilter(INK, 1, 4, 4, 4)];
		return field;
	}

	public static function set(field:TextField, value:String):Void {
		if (field != null && field.text != value)
			field.text = value;
	}

	/** A rarity colour, or a pale one when it is too dark to read over the panel. */
	public static function readable(color:Int):Int {
		var red = (color >> 16) & 0xFF;
		var green = (color >> 8) & 0xFF;
		var blue = color & 0xFF;
		if (red + green + blue < 0x180)
			return TEXT;
		return color;
	}

	/** 12345 as "12.345". */
	public static function number(value:Float):String {
		var whole = Std.string(Std.int(value));
		var negative = whole.charAt(0) == "-";
		if (negative)
			whole = whole.substr(1);
		var out = "";
		var digits = 0;
		var i = whole.length - 1;
		while (i >= 0) {
			out = whole.charAt(i) + out;
			digits++;
			if (digits == 3 && i > 0) {
				out = "." + out;
				digits = 0;
			}
			i--;
		}
		return (negative ? "-" : "") + out;
	}
}
