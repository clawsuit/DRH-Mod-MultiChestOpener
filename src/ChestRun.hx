package mods.multi_chest_opener;

import account.DBInventoryInfo;
import account.KeyInfo;
import account.StoreServices;
import facade.DBFacade;
import gameMasterDictionary.GMOffer;
import haxe.Timer;

/**
 * Opens chests of one kind, one request at a time, so the account the server answers is read whole
 * between two. A key comes from the keys owned, or from gold when none is left and `payGold` is on.
 */
class ChestRun {
	/** Seconds a request may take before the run gives up. */
	static inline final TIMEOUT = 20.0;

	/** How many are to be opened, and how many were. */
	public var total:Int = 0;

	public var opened:Int = 0;

	public var loot:Array<Loot> = [];

	/** Why the run stopped before its end: null while it goes and when it went through. */
	public var failed:String;

	public var busy(default, null):Bool = false;

	public var stoppedByPlayer(default, null):Bool = false;

	var facade:DBFacade;

	var gmId:Int;

	var payGold:Bool;

	/** The chest rows left to open, by database id. */
	var rows:Array<UInt> = [];

	var waitingSince:Float = 0;

	/** How many keys were bought for this run, so a key that never arrives cannot be bought twice. */
	var bought:Int = 0;

	/** The hero the game opens them for: the one picked in the inventory. */
	var heroId:UInt = 0;

	var heroSkin:UInt = 0;

	/** Rows the game already had a request in flight for, so the run did not add another. */
	var skipped:Int = 0;

	var finished:Bool = false;

	var onDone:Void->Void;

	public function new(facade:DBFacade, gmId:Int, payGold:Bool, onDone:Void->Void) {
		this.facade = facade;
		this.gmId = gmId;
		this.payGold = payGold;
		this.onDone = onDone;
	}

	/** How many chests of the kind the account holds, the dungeon summary's left out. */
	public static function count(info:DBInventoryInfo, gmId:Int):Int {
		var found = 0;
		var chests = info.chests;
		var i = 0;
		while (i < chests.length) {
			var chest = chests[i];
			if (chest != null && Std.int(chest.gmId) == gmId && !chest.isFromDungeonSummary())
				found += Std.int(chest.count);
			i++;
		}
		return found;
	}

	/** Every chest row of the kind, the dungeon summary's left out, in the order the account sends them. */
	public static function rowsOf(info:DBInventoryInfo, gmId:Int):Array<UInt> {
		var out:Array<UInt> = [];
		var chests = info.chests;
		var i = 0;
		while (i < chests.length) {
			var chest = chests[i];
			if (chest != null && Std.int(chest.gmId) == gmId && !chest.isFromDungeonSummary()) {
				var ids = chest.databaseIds;
				var j = 0;
				while (j < ids.length) {
					out.push(ids[j]);
					j++;
				}
			}
			i++;
		}
		return out;
	}

	public function start(amount:Int, heroId:UInt, heroSkin:UInt):Void {
		this.heroId = heroId;
		this.heroSkin = heroSkin;
		rows = rowsOf(facade.dbAccountInfo.inventoryInfo, gmId);
		total = amount < rows.length ? amount : rows.length;
		if (total < 0)
			total = 0;
		next();
	}

	public function stop():Void {
		if (finished)
			return;
		stoppedByPlayer = true;
		if (busy)
			return;
		finish();
	}

	public function update():Void {
		if (!busy || finished)
			return;
		if (Timer.stamp() - waitingSince > TIMEOUT) {
			busy = false;
			failed = "TIMEOUT";
			finish();
		}
	}

	public function keysLeft():Int {
		var key = keyOf();
		return key == null ? 0 : Std.int(key.count);
	}

	public function goldLeft():Float {
		return facade.dbAccountInfo.basicCurrency;
	}

	/** What stopped the run, in the panel's words; null when it went through. */
	public function message():String {
		if (stoppedByPlayer)
			return "run_stopped";
		if (failed == null)
			return null;
		if (failed == "NO_KEYS")
			return "run_no_keys";
		if (failed == "BUY_FAILED")
			return "run_buy_failed";
		if (failed == "REJECTED")
			return "run_refused";
		if (failed == "TIMEOUT")
			return "run_timeout";
		if (failed == "BUSY")
			return "run_busy";
		return "run_stopped";
	}

	function step():Void {
		if (finished)
			return;
		if (opened >= total || stoppedByPlayer || failed != null || rows.length == 0) {
			finish();
			return;
		}
		if (keysLeft() <= 0) {
			if (payGold && bought < total && goldCanBuy() && goldLeft() >= price()) {
				buyKey();
				return;
			}
			failed = "NO_KEYS";
			finish();
			return;
		}
		openNext();
	}

	/** One open, whatever the key list says: it is the server that has the last word. */
	function openNext():Void {
		if (finished)
			return;
		var info = facade.dbAccountInfo.inventoryInfo;
		while (rows.length > 0) {
			if (opened >= total || stoppedByPlayer || failed != null) {
				finish();
				return;
			}
			var row:UInt = rows.shift();
			// The game's own open returns without calling back while that row has a request in
			// flight, which would leave the run waiting for its timeout: take the next row.
			if (isPending(info, row)) {
				skipped++;
				Log.write("skip row " + row + ": a request is pending");
				continue;
			}
			busy = true;
			waitingSince = Timer.stamp();
			try {
				var done:Dynamic = onOpened;
				var failedCallback:Dynamic = onOpenFailed;
				info.openChest(row, heroId, heroSkin, done, failedCallback);
			} catch (error:Dynamic) {
				busy = false;
				failed = "REJECTED";
				finish();
			}
			return;
		}
		if (opened == 0 && skipped > 0)
			failed = "BUSY";
		finish();
	}

	static function isPending(info:DBInventoryInfo, row:UInt):Bool {
		try {
			return info.isChestRequestPending(row);
		} catch (error:Dynamic) {
			return false;
		}
	}

	function buyKey():Void {
		var offer = keyOffer();
		if (offer == null) {
			Log.write("buy: no key offer");
			failed = "NO_KEYS";
			finish();
			return;
		}
		Log.write("buy: offer=" + offer.Id + " price=" + offer.Price + " currency=" + offer.CurrencyType + " gold=" + Std.int(goldLeft())
			+ " keys=" + keysLeft());
		busy = true;
		waitingSince = Timer.stamp();
		try {
			var accepted:Dynamic = onBought;
			var refused:Dynamic = onBuyFailed;
			StoreServices.purchaseOffer(facade, offer.Id, accepted, refused, 0, false);
		} catch (error:Dynamic) {
			Log.write("buy threw: " + Std.string(error));
			busy = false;
			failed = "BUY_FAILED";
			finish();
		}
	}

	/** The server accepted an open: its answer is already read into the account, so the next one goes. */
	function onOpened(row:Dynamic, details:Dynamic):Void {
		busy = false;
		opened++;
		try {
			add(Loot.of(facade, details));
			facade.dbAccountInfo.inventoryInfo.removeChestRow(cast Std.int(row));
		} catch (error:Dynamic) {}
		next();
	}

	function onOpenFailed():Void {
		busy = false;
		failed = "REJECTED";
		finish();
	}

	/**
	 * The purchase was accepted. The game opens the chest right after buying its key without reading
	 * the key list again, and so does this: some offers, the item boxes among them, do not carry their
	 * key back in the account answer.
	 */
	function onBought(details:Dynamic):Void {
		busy = false;
		bought++;
		var keys = keysLeft();
		Log.write("bought: keys=" + keys + " opened=" + opened + " bought=" + bought);
		if (keys > 0)
			next();
		else
			openNext();
	}

	/** A step from a server answer: a throw there would reach the game's own callback. */
	function next():Void {
		try {
			step();
		} catch (error:Dynamic) {
			busy = false;
			failed = "REJECTED";
			finish();
		}
	}

	/** The purchase failed: the RPC hands the fault over, as its error callback. */
	function onBuyFailed(fault:Dynamic):Void {
		busy = false;
		var text = "?";
		try {
			text = Std.string(fault);
		} catch (error:Dynamic) {}
		Log.write("buy failed: " + text);
		failed = "BUY_FAILED";
		finish();
	}

	function add(item:Loot):Void {
		if (item == null || item.name == null)
			return;
		var i = 0;
		while (i < loot.length) {
			var existing = loot[i];
			if (existing.name == item.name) {
				existing.count = existing.count + 1;
				return;
			}
			i++;
		}
		loot.push(item);
	}

	function finish():Void {
		if (finished)
			return;
		finished = true;
		busy = false;
		if (onDone != null)
			onDone();
	}

	/** The key that opens this kind of chest, null when the account has none of its kind. */
	function keyOf():KeyInfo {
		var keys = facade.dbAccountInfo.inventoryInfo.keys;
		var i = 0;
		while (i < keys.length) {
			var key = keys[i];
			if (key != null && key.gmKey != null && Std.int(key.gmKey.ChestId) == gmId)
				return key;
			i++;
		}
		return null;
	}

	function keyOffer():GMOffer {
		var key = keyOf();
		return key == null ? null : key.gmKeyOffer;
	}

	function price():Float {
		var offer = keyOffer();
		return offer == null ? 0 : offer.Price;
	}

	/** Whether the key's offer is paid in gold, the only currency its popup's coin button spends. */
	function goldCanBuy():Bool {
		var offer = keyOffer();
		return offer != null && offer.Price > 0 && offer.CurrencyType == GMOffer.BASIC_CURRENCY;
	}
}


