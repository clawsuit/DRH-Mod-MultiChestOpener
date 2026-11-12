package mods.multi_chest_opener;

import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFormatAlign;

/** A flat button drawn as the panel is; it swallows its click so nothing under it fires. */
class Btn {
	public var root(default, null):Sprite;

	public var label(default, null):TextField;

	public var enabled:Bool = true;

	var action:Null<Void->Void>;

	var width:Float;

	var height:Float;

	var accent:Bool;

	var over:Bool = false;

	public function new(text:String, width:Float, height:Float, accent:Bool, action:Void->Void) {
		this.width = width;
		this.height = height;
		this.accent = accent;
		this.action = action;
		root = new Sprite();
		root.buttonMode = true;
		label = Ui.text(accent ? 18 : 16, accent ? Ui.INK : Ui.TEXT, width, TextFormatAlign.CENTER);
		label.y = (height - label.height) / 2 + 1;
		root.addChild(label);
		root.addEventListener(MouseEvent.MOUSE_DOWN, swallow);
		root.addEventListener(MouseEvent.CLICK, click);
		root.addEventListener(MouseEvent.ROLL_OVER, enter);
		root.addEventListener(MouseEvent.ROLL_OUT, leave);
		setText(text);
		paint();
	}

	static function swallow(event:MouseEvent):Void {
		event.stopImmediatePropagation();
	}

	function enter(event:MouseEvent):Void {
		over = true;
		paint();
	}

	function leave(event:MouseEvent):Void {
		over = false;
		paint();
	}

	function click(event:MouseEvent):Void {
		event.stopImmediatePropagation();
		if (enabled && action != null)
			action();
	}

	public function setText(value:String):Void {
		Ui.set(label, value);
	}

	public function setEnabled(value:Bool):Void {
		if (enabled == value)
			return;
		enabled = value;
		root.buttonMode = value;
		label.textColor = value ? (accent ? Ui.INK : Ui.TEXT) : Ui.DIM;
		paint();
	}

	function paint():Void {
		var g = root.graphics;
		g.clear();
		g.lineStyle(2, enabled ? Ui.GOLD : Ui.GOLD_DARK, 0.9);
		g.beginFill(fill(), 1);
		g.drawRoundRect(0, 0, width, height, 8, 8);
		g.endFill();
	}

	function fill():Int {
		if (!enabled)
			return 0x2A1C10;
		if (accent)
			return over ? 0xFFDC8C : 0xE8B23B;
		return over ? 0x5A3A1A : Ui.PARCHMENT;
	}
}
