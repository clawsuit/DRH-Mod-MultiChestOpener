package mods.multi_chest_opener;

import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFormatAlign;

/**
 * The chest window, drawn in the game's browns and golds: the amount to open, the run's progress, and
 * the loot as a grid of the items' own icons. Its words come from `Strings`, in the player's language.
 */
class Panel {
	static inline final W = 640.0;

	static inline final H = 460.0;

	/** The loot grid: cells of a slot with its icon, and its name under it. */
	static inline final COLS = 4;

	static inline final ROWS = 3;

	static inline final CELL_W = 104.0;

	static inline final CELL_H = 96.0;

	static inline final GAP = 6.0;

	static inline final SLOT = 70.0;

	/** The card shown when the cursor rests on a loot cell. */
	static inline final TIP_W = 256.0;

	public var onOpen:Null<Int->Void>;

	public var onGold:Null<Bool->Void>;

	public var onClose:Null<Void->Void>;

	public var onStop:Null<Void->Void>;

	var settings:Settings;

	var holder:Sprite;

	var backdrop:Sprite;

	var window:Sprite;

	var title:TextField;

	var langBg:Shape;

	var langLabel:TextField;

	var pick:Sprite;

	var busy:Sprite;

	var lootView:Sprite;

	var chestName:TextField;

	var info:TextField;

	var caption:TextField;

	var minLabel:TextField;

	var maxLabel:TextField;

	var slider:Slider;

	var cost:TextField;

	var note:TextField;

	var goldBtn:Btn;

	var cancelBtn:Btn;

	var openBtn:Btn;

	var busyLabel:TextField;

	var busyCount:TextField;

	var busyInfo:TextField;

	var bar:Sprite;

	var stopBtn:Btn;

	var lootInfo:TextField;

	var pageLabel:TextField;

	var grid:Sprite;

	var prev:Btn;

	var next:Btn;

	var okBtn:Btn;

	var cells:Array<Sprite> = [];

	var tip:Sprite;

	var loot:Array<Loot> = [];

	var page:Int = 0;

	var pages:Int = 1;

	/** 0 the picker, 1 the run, 2 the loot. */
	var mode:Int = 0;

	var pName:String = "";

	var pColor:Int = 0xFFFFFF;

	var pAvailable:Int = 0;

	var pKeys:Int = 0;

	var pGold:Float = 0;

	var pPrice:Float = 0;

	var pMax:Int = 1;

	var pValue:Int = 1;

	var pPayGold:Bool = true;

	var bOpened:Int = 0;

	var bTotal:Int = 0;

	var bKeys:Int = 0;

	var bGold:Float = 0;

	var lOpened:Int = 0;

	var lMessage:String;

	var lOk:Bool = true;

	var scale:Float = 1;

	var viewWidth:Float = 0;

	var viewHeight:Float = 0;

	var shown:Bool = false;

	public function new(overlay:Sprite, width:Float, height:Float, settings:Settings) {
		this.settings = settings;
		viewWidth = width;
		viewHeight = height;

		scale = 1.0;
		var fitX = width * 0.92 / W;
		var fitY = height * 0.92 / H;
		if (fitX < scale)
			scale = fitX;
		if (fitY < scale)
			scale = fitY;
		if (scale < 0.6)
			scale = 0.6;

		holder = new Sprite();
		backdrop = new Sprite();
		backdrop.graphics.beginFill(0x000000, 0.58);
		backdrop.graphics.drawRect(0, 0, width, height);
		backdrop.graphics.endFill();
		holder.addChild(backdrop);

		window = newWindow();
		buildWindow();

		holder.addEventListener(MouseEvent.MOUSE_DOWN, swallow);
		holder.addEventListener(MouseEvent.CLICK, swallow);
		backdrop.addEventListener(MouseEvent.MOUSE_DOWN, swallow);
		backdrop.addEventListener(MouseEvent.CLICK, swallow);

		overlay.addChild(holder);
		shown = true;
		show(pick);
	}

	public function isShown():Bool {
		return shown;
	}

	/** The picker: the chest, what the account holds, and where the slider starts. */
	public function ask(name:String, color:Int, available:Int, keys:Int, gold:Float, price:Float, max:Int, value:Int, payGold:Bool):Void {
		pName = name;
		pColor = color;
		pAvailable = available;
		pKeys = keys;
		pGold = gold;
		pPrice = price;
		pMax = max;
		pValue = value;
		pPayGold = payGold;
		mode = 0;
		show(pick);
		slider.setMax(max);
		slider.setValue(value);
		renderPick();
	}

	/** The picker's numbers, after a change of gold spending and of the range it allows. */
	public function numbers(available:Int, keys:Int, gold:Float, price:Float, max:Int, payGold:Bool):Void {
		pAvailable = available;
		pKeys = keys;
		pGold = gold;
		pPrice = price;
		pMax = max;
		pPayGold = payGold;
		if (mode == 0)
			renderPick();
	}

	public function running(amount:Int):Void {
		mode = 1;
		bOpened = 0;
		bTotal = amount;
		bKeys = pKeys;
		bGold = pGold;
		show(busy);
		renderBusy();
	}

	public function progress(opened:Int, total:Int, keys:Int, gold:Float):Void {
		bOpened = opened;
		bTotal = total;
		bKeys = keys;
		bGold = gold;
		if (mode == 1)
			renderBusy();
	}

	/** The loot, as a grid of the items' icons; `message` is a `Strings` key, or null. */
	public function result(opened:Int, loot:Array<Loot>, message:String, ok:Bool):Void {
		mode = 2;
		lOpened = opened;
		lMessage = message;
		lOk = ok;
		this.loot = loot == null ? [] : loot;
		page = 0;
		show(lootView);
		renderLoot();
	}

	/** Opens, as the button does. */
	public function confirm():Void {
		if (!shown || !pick.visible || !openBtn.enabled)
			return;
		if (onOpen != null)
			onOpen(slider.value);
	}

	/** Takes the panel away; closing is the caller's business. */
	public function close():Void {
		if (!shown)
			return;
		shown = false;
		hideTip();
		if (holder.parent != null)
			holder.parent.removeChild(holder);
		cells = [];
	}

	function newWindow():Sprite {
		var frame = new Sprite();
		frame.scaleX = frame.scaleY = scale;
		frame.x = (viewWidth - W * scale) / 2;
		frame.y = (viewHeight - H * scale) / 2;
		return frame;
	}

	function buildWindow():Void {
		holder.addChild(window);
		drawWindow();
		drawLanguage();
		buildPages();
		renderMode();
	}

	/** Redraws the whole window, for the language button: the texts are built from `Strings`. */
	function rebuild():Void {
		hideTip();
		cells = [];
		if (window.parent != null)
			window.parent.removeChild(window);
		window = newWindow();
		buildWindow();
	}

	function renderMode():Void {
		if (mode == 1) {
			show(busy);
			renderBusy();
		} else if (mode == 2) {
			show(lootView);
			renderLoot();
		} else {
			show(pick);
			renderPick();
		}
	}

	function renderPick():Void {
		Ui.set(title, Strings.t("pick_title"));
		Ui.set(chestName, pName == null ? "" : pName.toUpperCase());
		chestName.textColor = Ui.readable(pColor);
		Ui.set(info, Strings.t("chests") + " " + pAvailable + "        " + Strings.t("keys") + " " + pKeys + "        " + Strings.t("gold") + " "
			+ Ui.number(pGold));
		Ui.set(caption, Strings.f("max", Std.string(pMax)));
		Ui.set(maxLabel, Std.string(pMax));
		slider.setMax(pMax);
		slider.setValue(pValue);
		goldBtn.setText(pPayGold ? Strings.t("pay_yes") : Strings.t("pay_no"));
		goldBtn.setEnabled(pPrice > 0 && pKeys < pAvailable);
		openBtn.setEnabled(pMax > 0);
		renderCost();
	}

	function renderCost():Void {
		var wanted = slider.value;
		pValue = wanted;
		if (wanted < 1) {
			Ui.set(cost, Strings.t("no_currency"));
			cost.textColor = Ui.RED;
			openBtn.setText(Strings.t("open"));
			return;
		}
		var fromKeys = wanted < pKeys ? wanted : pKeys;
		var bought = wanted - fromKeys;
		var spend = bought * pPrice;
		var text:String;
		if (bought <= 0)
			text = wanted == 1 ? Strings.t("cost_one") : Strings.f("cost_keys", Std.string(wanted));
		else
			text = Strings.f("cost_mixed", Std.string(fromKeys), Std.string(bought), Ui.number(spend));
		Ui.set(cost, text);
		cost.textColor = spend > pGold ? Ui.RED : Ui.TEXT;
		openBtn.setText(wanted == 1 ? Strings.t("open_one") : Strings.f("open_many", Std.string(wanted)));
	}

	function renderBusy():Void {
		Ui.set(title, Strings.t("busy_title"));
		var current = bOpened + 1;
		Ui.set(busyLabel, Strings.f("busy_chest", Std.string(current > bTotal ? bTotal : current), Std.string(bTotal)));
		Ui.set(busyCount, bOpened + " / " + bTotal);
		Ui.set(busyInfo, Strings.f("busy_info", Std.string(bKeys), Ui.number(bGold)));
		drawBar(bOpened, bTotal);
	}

	function renderLoot():Void {
		Ui.set(title, Strings.t("loot_title"));
		if (lMessage == null)
			Ui.set(lootInfo, Strings.f("loot_opened", Std.string(lOpened)));
		else
			Ui.set(lootInfo, Strings.f("loot_stopped", Strings.t(lMessage), Std.string(lOpened)));
		lootInfo.textColor = lOk ? Ui.TEXT : Ui.RED;
		pages = Math.ceil(loot.length / (COLS * ROWS));
		if (pages < 1)
			pages = 1;
		refreshPage();
	}

	function drawWindow():Void {
		var g = window.graphics;
		g.beginFill(0x000000, 0.4);
		g.drawRoundRect(6, 8, W, H, 20, 20);
		g.endFill();
		g.beginFill(Ui.PANEL, 0.97);
		g.drawRoundRect(0, 0, W, H, 16, 16);
		g.endFill();
		g.lineStyle(3, Ui.GOLD, 1);
		g.drawRoundRect(1.5, 1.5, W - 3, H - 3, 15, 15);
		g.lineStyle(1, Ui.GOLD_DARK, 0.9);
		g.drawRoundRect(8, 8, W - 16, H - 16, 10, 10);
		g.lineStyle(1, Ui.GOLD_DARK, 0.7);
		g.moveTo(20, 54);
		g.lineTo(W - 20, 54);

		title = Ui.text(22, Ui.GOLD, W, TextFormatAlign.CENTER);
		title.y = 14;
		window.addChild(title);
	}

	/** The EN/ES button, so both languages are always a click away. */
	function drawLanguage():Void {
		var button = new Sprite();
		button.x = 18;
		button.y = 12;
		button.buttonMode = true;
		window.addChild(button);

		langBg = new Shape();
		button.addChild(langBg);
		paintLang(false);

		langLabel = Ui.text(13, Ui.GOLD, 46, TextFormatAlign.CENTER);
		langLabel.y = 5;
		button.addChild(langLabel);
		Ui.set(langLabel, Strings.lang == "es" ? "ES" : "EN");

		var hit = new Sprite();
		hit.graphics.beginFill(0x000000, 0.01);
		hit.graphics.drawRect(0, 0, 46, 28);
		hit.graphics.endFill();
		button.addChild(hit);

		hit.addEventListener(MouseEvent.MOUSE_DOWN, swallow);
		hit.addEventListener(MouseEvent.CLICK, function(event:MouseEvent) {
			event.stopImmediatePropagation();
			toggleLanguage();
		});
		hit.addEventListener(MouseEvent.ROLL_OVER, function(event:MouseEvent) paintLang(true));
		hit.addEventListener(MouseEvent.ROLL_OUT, function(event:MouseEvent) paintLang(false));
	}

	function paintLang(over:Bool):Void {
		var g = langBg.graphics;
		g.clear();
		g.lineStyle(2, over ? Ui.GOLD : Ui.GOLD_DARK, 1);
		g.beginFill(over ? 0x4A2E12 : 0x2A1708, 1);
		g.drawRoundRect(0, 0, 46, 28, 6, 6);
		g.endFill();
	}

	function toggleLanguage():Void {
		Strings.lang = Strings.lang == "es" ? "en" : "es";
		if (settings != null) {
			settings.language = Strings.lang;
			settings.save();
		}
		rebuild();
	}

	function buildPages():Void {
		pick = new Sprite();
		busy = new Sprite();
		lootView = new Sprite();
		window.addChild(pick);
		window.addChild(busy);
		window.addChild(lootView);

		buildPick();
		buildBusy();
		buildLoot();
	}

	function buildPick():Void {
		chestName = Ui.text(18, Ui.TEXT, W - 80, TextFormatAlign.CENTER, true);
		chestName.x = 40;
		chestName.y = 58;
		chestName.height = 44;
		pick.addChild(chestName);

		info = Ui.text(14, Ui.DIM, W - 80, TextFormatAlign.CENTER);
		info.x = 40;
		info.y = 110;
		pick.addChild(info);

		caption = Ui.text(13, Ui.GOLD, W - 80, TextFormatAlign.CENTER);
		caption.x = 40;
		caption.y = 140;
		pick.addChild(caption);

		slider = new Slider(70, 170, 500);
		slider.onChange = renderCost;
		pick.addChild(slider.root);

		minLabel = Ui.text(12, Ui.DIM, 60, TextFormatAlign.LEFT);
		minLabel.x = 64;
		minLabel.y = 184;
		Ui.set(minLabel, "1");
		pick.addChild(minLabel);

		maxLabel = Ui.text(12, Ui.DIM, 60, TextFormatAlign.RIGHT);
		maxLabel.x = W - 64 - 60;
		maxLabel.y = 184;
		pick.addChild(maxLabel);

		cost = Ui.text(14, Ui.TEXT, W - 80, TextFormatAlign.CENTER);
		cost.x = 40;
		cost.y = 212;
		pick.addChild(cost);

		goldBtn = new Btn(Strings.t("pay_yes"), 360, 38, false, toggleGold);
		goldBtn.root.x = (W - 360) / 2;
		goldBtn.root.y = 246;
		pick.addChild(goldBtn.root);

		note = Ui.text(12, Ui.DIM, W - 80, TextFormatAlign.CENTER, true);
		note.x = 40;
		note.y = 306;
		note.height = 28;
		Ui.set(note, Strings.t("note"));
		pick.addChild(note);

		cancelBtn = new Btn(Strings.t("cancel"), 190, 48, false, requestClose);
		cancelBtn.root.x = 150 - 95;
		cancelBtn.root.y = 396;
		pick.addChild(cancelBtn.root);

		openBtn = new Btn(Strings.t("open"), 230, 48, true, confirm);
		openBtn.root.x = 500 - 115;
		openBtn.root.y = 396;
		pick.addChild(openBtn.root);
	}

	function buildBusy():Void {
		busyLabel = Ui.text(18, Ui.GOLD, W - 60, TextFormatAlign.CENTER);
		busyLabel.x = 30;
		busyLabel.y = 100;
		busy.addChild(busyLabel);

		busyCount = Ui.text(46, Ui.TEXT, W - 60, TextFormatAlign.CENTER);
		busyCount.x = 30;
		busyCount.y = 140;
		busy.addChild(busyCount);

		bar = new Sprite();
		bar.x = (W - 360) / 2;
		bar.y = 250;
		busy.addChild(bar);

		busyInfo = Ui.text(14, Ui.DIM, W - 60, TextFormatAlign.CENTER);
		busyInfo.x = 30;
		busyInfo.y = 286;
		busy.addChild(busyInfo);

		stopBtn = new Btn(Strings.t("stop"), 200, 46, false, requestStop);
		stopBtn.root.x = W / 2 - 100;
		stopBtn.root.y = 380;
		busy.addChild(stopBtn.root);
	}

	function buildLoot():Void {
		lootInfo = Ui.text(14, Ui.TEXT, 420, TextFormatAlign.LEFT);
		lootInfo.x = 40;
		lootInfo.y = 64;
		lootView.addChild(lootInfo);

		pageLabel = Ui.text(13, Ui.GOLD, 160, TextFormatAlign.RIGHT);
		pageLabel.x = W - 40 - 160;
		pageLabel.y = 64;
		lootView.addChild(pageLabel);

		grid = new Sprite();
		grid.x = (W - (COLS * CELL_W + (COLS - 1) * GAP)) / 2;
		grid.y = 90;
		lootView.addChild(grid);

		prev = new Btn("<", 52, 42, false, previousPage);
		prev.root.x = 30;
		prev.root.y = 210;
		lootView.addChild(prev.root);

		next = new Btn(">", 52, 42, false, nextPage);
		next.root.x = W - 30 - 52;
		next.root.y = 210;
		lootView.addChild(next.root);

		okBtn = new Btn(Strings.t("ok"), 200, 46, true, requestClose);
		okBtn.root.x = W / 2 - 100;
		okBtn.root.y = 398;
		lootView.addChild(okBtn.root);
	}

	function drawBar(done:Int, total:Int):Void {
		var g = bar.graphics;
		g.clear();
		g.lineStyle(2, Ui.GOLD_DARK, 1);
		g.beginFill(0x150C06, 0.95);
		g.drawRoundRect(0, 0, 360, 20, 10, 10);
		g.endFill();
		var ratio = total <= 0 ? 0 : done / total;
		if (ratio > 1)
			ratio = 1;
		var filled = 360 * ratio;
		if (filled > 4) {
			g.beginFill(Ui.GOLD, 1);
			g.drawRoundRect(3, 3, filled - 6, 14, 7, 7);
			g.endFill();
		}
	}

	function refreshPage():Void {
		hideTip();
		for (cell in cells)
			if (cell.parent != null)
				cell.parent.removeChild(cell);
		cells = [];
		var size = COLS * ROWS;
		var start = page * size;
		var i = 0;
		while (i < size && start + i < loot.length) {
			var cell = cellFor(loot[start + i]);
			cell.x = (i % COLS) * (CELL_W + GAP);
			cell.y = Std.int(i / COLS) * (CELL_H + GAP);
			grid.addChild(cell);
			cells.push(cell);
			i++;
		}
		Ui.set(pageLabel, pages > 1 ? Strings.f("page", Std.string(page + 1), Std.string(pages)) : "");
		prev.setEnabled(page > 0);
		next.setEnabled(page < pages - 1);
	}

	/** One cell: the item's icon over its rarity colour, its count, and its name under it. */
	function cellFor(item:Loot):Sprite {
		var cell = new Sprite();
		cell.mouseChildren = false;
		var g = cell.graphics;
		g.lineStyle(2, Ui.GOLD_DARK, 0.6);
		g.beginFill(0x2A1A0C, 0.5);
		g.drawRoundRect(0, 0, CELL_W, SLOT, 8, 8);
		g.endFill();

		var holder = new Sprite();
		holder.x = CELL_W / 2;
		holder.y = SLOT / 2;
		cell.addChild(holder);
		Icon.load(item.backgroundSwf, item.backgroundIcon, SLOT - 2, holder, true);
		Icon.load(item.swf, item.icon, SLOT - 14, holder);

		if (item.count > 1) {
			var count = Ui.text(12, Ui.GOLD, 44, TextFormatAlign.RIGHT);
			count.x = CELL_W - 46;
			count.y = SLOT - 20;
			Ui.set(count, "x" + item.count);
			cell.addChild(count);
		}

		var label = Ui.text(10, Ui.readable(item.color), CELL_W - 2, TextFormatAlign.CENTER, true);
		label.x = 1;
		label.y = SLOT + 2;
		label.height = CELL_H - SLOT - 4;
		Ui.set(label, item.name == null ? "" : item.name.toUpperCase());
		cell.addChild(label);

		cell.addEventListener(MouseEvent.MOUSE_OVER, function(event:MouseEvent) showTip(item, cell));
		cell.addEventListener(MouseEvent.MOUSE_OUT, function(event:MouseEvent) hideTip());
		return cell;
	}

	/** The card that tells what an item is: its level, its type, its power and its modifiers. */
	function showTip(item:Loot, cell:Sprite):Void {
		if (item == null || !lootView.visible)
			return;
		hideTip();

		var lines:Array<Dynamic> = [];
		if (item.kind == "kind_weapon") {
			lines.push({ text: Strings.f("level", Std.string(item.level)), color: 0xFFFFFF, size: 11 });
			if (item.typeName != "")
				lines.push({ text: item.typeName, color: Ui.GOLD, size: 11 });
			lines.push({ text: Strings.f("power", Std.string(item.power)), color: Ui.GOLD, size: 14 });
			lines.push({ text: Strings.t("modifiers"), color: Ui.GOLD, size: 10 });
			if (item.modNames.length == 0)
				lines.push({ text: Strings.t("none"), color: Ui.DIM, size: 10 });
			else
				for (mod in item.modNames)
					lines.push({ text: mod, color: 0xFFFFFF, size: 10 });
			if (item.legendary)
				lines.push({ text: Strings.t("legendary"), color: 0xFFB43C, size: 10 });
		} else {
			lines.push({ text: Strings.t(item.kind), color: Ui.DIM, size: 10 });
		}

		var heights:Array<Float> = [];
		var total = 10.0;
		var titleHeight = 30.0;
		total += titleHeight + 4;
		for (line in lines) {
			var size:Int = line.size;
			var height = size * 1.7;
			heights.push(height);
			total += height;
		}
		total += 10;

		tip = new Sprite();
		var g = tip.graphics;
		g.beginFill(0x000000, 0.35);
		g.drawRoundRect(3, 4, TIP_W, total, 8, 8);
		g.endFill();
		g.beginFill(0x1B0F06, 0.98);
		g.drawRoundRect(0, 0, TIP_W, total, 8, 8);
		g.endFill();
		g.lineStyle(2, Ui.GOLD, 1);
		g.drawRoundRect(0, 0, TIP_W, total, 8, 8);
		window.addChild(tip);

		var head = Ui.text(13, Ui.readable(item.color), TIP_W - 16, TextFormatAlign.LEFT, true);
		head.x = 8;
		head.y = 8;
		head.height = titleHeight;
		Ui.set(head, item.name == null ? "" : item.name.toUpperCase());
		tip.addChild(head);

		var y = 8 + titleHeight + 4;
		var i = 0;
		while (i < lines.length) {
			var spec = lines[i];
			var size:Int = spec.size;
			var label = Ui.text(size, spec.color, TIP_W - 16, TextFormatAlign.LEFT);
			label.x = 8;
			label.y = y;
			label.height = heights[i];
			Ui.set(label, spec.text);
			tip.addChild(label);
			y += heights[i];
			i++;
		}

		var cellX = grid.x + cell.x + CELL_W / 2;
		var x = cellX - TIP_W / 2;
		if (x < 8)
			x = 8;
		if (x > W - TIP_W - 8)
			x = W - TIP_W - 8;
		var above = grid.y + cell.y - total - 8;
		if (above < 60)
			above = grid.y + cell.y + CELL_H + 8;
		tip.x = x;
		tip.y = above;
		tip.mouseChildren = false;
		tip.mouseEnabled = false;
	}

	function hideTip():Void {
		if (tip != null) {
			if (tip.parent != null)
				tip.parent.removeChild(tip);
			tip = null;
		}
	}

	function previousPage():Void {
		if (page <= 0)
			return;
		page--;
		refreshPage();
	}

	function nextPage():Void {
		if (page >= pages - 1)
			return;
		page++;
		refreshPage();
	}

	function show(group:Sprite):Void {
		pick.visible = group == pick;
		busy.visible = group == busy;
		lootView.visible = group == lootView;
	}

	function toggleGold():Void {
		if (onGold != null)
			onGold(!pPayGold);
	}

	function requestClose():Void {
		if (onClose != null)
			onClose();
	}

	function requestStop():Void {
		if (onStop != null)
			onStop();
	}

	static function swallow(event:MouseEvent):Void {
		event.stopImmediatePropagation();
	}
}

