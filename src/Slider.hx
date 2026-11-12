package mods.multi_chest_opener;

import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.geom.Point;

/** A slider from 0 to `max`: dragging the knob or clicking the bar picks a value. */
class Slider {
	static inline final HEIGHT = 12.0;

	static inline final KNOB = 22.0;

	public var root(default, null):Sprite;

	public var value:Int = 1;

	public var max:Int = 1;

	public var onChange:Null<Void->Void>;

	var width:Float;

	var rail:Shape;

	var knob:Shape;

	var hit:Sprite;

	var dragging:Bool = false;

	public function new(x:Float, y:Float, width:Float) {
		this.width = width;
		root = new Sprite();
		root.x = x;
		root.y = y;

		rail = new Shape();
		root.addChild(rail);

		hit = new Sprite();
		hit.graphics.beginFill(0x000000, 0.01);
		hit.graphics.drawRect(-6, -12, width + 12, HEIGHT + 24);
		hit.graphics.endFill();
		root.addChild(hit);
		hit.addEventListener(MouseEvent.MOUSE_DOWN, begin);

		knob = new Shape();
		root.addChild(knob);

		draw();
	}

	public function setMax(limit:Int):Void {
		max = limit < 0 ? 0 : limit;
		if (max < 1)
			value = 0;
		else if (value < 1)
			value = 1;
		else if (value > max)
			value = max;
		draw();
	}

	public function setValue(amount:Int):Void {
		var wanted = amount;
		if (max < 1)
			wanted = 0;
		else if (wanted < 1)
			wanted = 1;
		else if (wanted > max)
			wanted = max;
		if (wanted == value)
			return;
		value = wanted;
		draw();
		if (onChange != null)
			onChange();
	}

	function begin(event:MouseEvent):Void {
		event.stopImmediatePropagation();
		if (max < 1)
			return;
		var stage = root.stage;
		dragging = true;
		if (stage != null) {
			stage.addEventListener(MouseEvent.MOUSE_MOVE, move);
			stage.addEventListener(MouseEvent.MOUSE_UP, end);
		}
		pick(event.stageX, event.stageY);
	}

	function move(event:MouseEvent):Void {
		if (dragging)
			pick(event.stageX, event.stageY);
	}

	function end(event:MouseEvent):Void {
		dragging = false;
		var stage = root.stage;
		if (stage != null) {
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, move);
			stage.removeEventListener(MouseEvent.MOUSE_UP, end);
		}
	}

	function pick(stageX:Float, stageY:Float):Void {
		var stage = root.stage;
		if (stage == null)
			return;
		var point = root.globalToLocal(new Point(stageX, stageY));
		var ratio = point.x / width;
		if (ratio < 0)
			ratio = 0;
		if (ratio > 1)
			ratio = 1;
		var wanted = max <= 1 ? 1 : 1 + Std.int(Math.round(ratio * (max - 1)));
		if (wanted == value)
			return;
		value = wanted;
		draw();
		if (onChange != null)
			onChange();
	}

	function draw():Void {
		var g = rail.graphics;
		g.clear();
		g.lineStyle(2, Ui.GOLD_DARK, 1);
		g.beginFill(0x150C06, 0.96);
		g.drawRoundRect(0, 0, width, HEIGHT, HEIGHT / 2, HEIGHT / 2);
		g.endFill();

		var ratio = max <= 1 ? 0 : (value - 1) / (max - 1);
		if (max < 1)
			ratio = 0;
		var knobX = width * ratio;

		var k = knob.graphics;
		k.clear();
		k.lineStyle(3, Ui.INK, 1);
		k.beginFill(max < 1 ? Ui.GOLD_DARK : Ui.GOLD, 1);
		k.drawCircle(0, HEIGHT / 2, KNOB / 2);
		k.endFill();
		knob.x = knobX;
	}
}
