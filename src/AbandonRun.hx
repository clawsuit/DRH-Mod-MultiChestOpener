package mods.multi_chest_opener;

import account.DBInventoryInfo;
import facade.DBFacade;
import haxe.Timer;

/**
 * Abandons chests of one kind, one request at a time, with the game's own ABANDON call. There is no
 * key, gold or storage check: the only thing it needs is the chest rows.
 */
class AbandonRun {
	/** Seconds a request may take before the run gives up. */
	static inline final TIMEOUT = 20.0;

	/** Seconds to wait before retrying the chests the server was still busy with. */
	static inline final RETRY_DELAY = 1.2;

	public var total:Int = 0;

	public var done:Int = 0;

	/** Why the run stopped before its end: null while it goes and when it went through. */
	public var failed:String;

	public var busy(default, null):Bool = false;

	public var stoppedByPlayer(default, null):Bool = false;

	var facade:DBFacade;

	var gmId:Int;

	var rows:Array<UInt> = [];

	var pendingRows:Array<UInt> = [];

	var retried:Bool = false;

	var retryAt:Float = -1;

	var waitingSince:Float = 0;

	var finished:Bool = false;

	var onDone:Void->Void;

	public function new(facade:DBFacade, gmId:Int, onDone:Void->Void) {
		this.facade = facade;
		this.gmId = gmId;
		this.onDone = onDone;
	}

	public function start(amount:Int):Void {
		rows = ChestRun.rowsOf(facade.dbAccountInfo.inventoryInfo, gmId);
		total = amount < rows.length ? amount : rows.length;
		if (total < 0)
			total = 0;
		step();
	}

	public function stop():Void {
		if (finished)
			return;
		stoppedByPlayer = true;
		if (busy)
			return;
		retryAt = 0;
		finish();
	}

	public function update():Void {
		if (finished)
			return;
		var now = Timer.stamp();
		if (retryAt > 0) {
			if (!busy && now >= retryAt) {
				retryAt = 0;
				next();
			}
			return;
		}
		if (!busy)
			return;
		if (now - waitingSince > TIMEOUT) {
			busy = false;
			failed = "TIMEOUT";
			finish();
		}
	}

	/** What stopped the run, in the panel's words; null when it went through. */
	public function message():String {
		if (stoppedByPlayer)
			return "run_stopped";
		if (failed == null)
			return null;
		if (failed == "REJECTED")
			return "run_refused";
		if (failed == "TIMEOUT")
			return "run_timeout";
		if (failed == "BUSY")
			return "run_busy";
		if (failed == "PARTIAL")
			return "run_partial";
		return "run_stopped";
	}

	function step():Void {
		if (finished)
			return;
		if (stoppedByPlayer || done >= total) {
			finish();
			return;
		}
		if (rows.length == 0 && pendingRows.length > 0 && retryAt < 0) {
			dropNext();
			return;
		}
		dropNext();
	}

	function dropNext():Void {
		if (finished)
			return;
		var info = facade.dbAccountInfo.inventoryInfo;
		while (rows.length > 0) {
			if (done >= total || stoppedByPlayer || failed != null) {
				finish();
				return;
			}
			var row:UInt = rows.shift();
			if (isPending(info, row)) {
				pendingRows.push(row);
				Log.write("abandon busy row " + row);
				continue;
			}
			// The player or another mod may have removed it while this run was going.
			if (!rowExists(info, row)) {
				Log.write("abandon row gone " + row);
				continue;
			}
			busy = true;
			waitingSince = Timer.stamp();
			try {
				var ok:Dynamic = onDropped;
				var bad:Dynamic = onFailed;
				info.dropChest(row, ok, bad);
			} catch (error:Dynamic) {
				busy = false;
				failed = "REJECTED";
				finish();
			}
			return;
		}
		if (done == 0 && pendingRows.length > 0) {
			failed = "BUSY";
			finish();
			return;
		}
		if (!retried && pendingRows.length > 0 && done < total && !stoppedByPlayer && failed == null) {
			retried = true;
			var retryRows = pendingRows;
			pendingRows = [];
			rows = retryRows;
			retryAt = Timer.stamp() + RETRY_DELAY;
			Log.write("abandon retry rows " + rows.length);
			return;
		}
		if (done < total && failed == null)
			failed = "PARTIAL";
		finish();
	}

	static function isPending(info:DBInventoryInfo, row:UInt):Bool {
		try {
			return info.isChestRequestPending(row);
		} catch (error:Dynamic) {
			return false;
		}
	}

	static function rowExists(info:DBInventoryInfo, row:UInt):Bool {
		var chests = info.chests;
		var i = 0;
		while (i < chests.length) {
			var chest = chests[i];
			if (chest != null && chest.containsDatabaseId(row))
				return true;
			i++;
		}
		return false;
	}

	function onDropped(row:Dynamic, details:Dynamic):Void {
		busy = false;
		done++;
		next();
	}

	function onFailed():Void {
		busy = false;
		failed = "REJECTED";
		finish();
	}

	function next():Void {
		try {
			step();
		} catch (error:Dynamic) {
			busy = false;
			failed = "REJECTED";
			finish();
		}
	}

	function finish():Void {
		if (finished)
			return;
		finished = true;
		busy = false;
		retryAt = 0;
		Log.flush();
		if (onDone != null)
			onDone();
	}
}