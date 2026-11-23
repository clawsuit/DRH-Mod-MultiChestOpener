package mods.multi_chest_opener;

import account.AvatarInfo;
import account.ChestInfo;
import account.DBInventoryInfo;
import account.KeyInfo;
import brain.stateMachine.State;
import brain.stateMachine.StateMachine;
import facade.DBFacade;
import facade.GameMasterLocale;
import gameMasterDictionary.GMOffer;
import gameMasterDictionary.GMRarity;
import haxe.ds.ObjectMap;
import mods.api.Context;
import mods.api.Mod;
import openfl.events.Event;
import town.InventoryTownSubState;
import uI.inventory.UIInventory;
import uI.inventory.chests.ChestInfoCard;

/**
 * Many chests at once from the town's inventory: UNLOCK opens a panel to open a number of them, and
 * ABANDON opens the same panel to discard a number of them. Both runs go one request at a time.
 *
 * It wraps the chest cards' open and abandon callbacks (never replaces them outright), so the game's
 * own window is always one button away and any other mod that wrapped a callback first keeps its turn.
 */
@:privateAccess
class Main extends Mod {
	static inline final ESCAPE:UInt = 27;

	static inline final ENTER:UInt = 13;

	var ctx:Context;

	var settings:Settings;

	var town:InventoryTownSubState;

	/** The cards whose callbacks are wrapped, so each is wrapped once while its inventory lasts. */
	var hooked:Array<Dynamic> = [];

	/** The wrappers set on each card. */
	var wrappers:ObjectMap<Dynamic, Dynamic> = new ObjectMap();

	var wrappersAbandon:ObjectMap<Dynamic, Dynamic> = new ObjectMap();

	/** What each card had before, to hand a click back to the game. */
	var previous:ObjectMap<Dynamic, Dynamic> = new ObjectMap();

	var previousAbandon:ObjectMap<Dynamic, Dynamic> = new ObjectMap();

	/** The inventory last seen: a new town visit builds a new one, with new cards and callbacks. */
	var inventorySeen:UIInventory;

	var panel:Panel;

	var run:ChestRun;

	var dropRun:AbandonRun;

	/** The kind of chest the panel is about. */
	var gmId:Int = 0;

	/** The number of opened chests the panel shows last, -1 before a run. */
	var shownOpened:Int = -1;

	/** The number of abandoned chests the panel shows last, -1 before a run. */
	var shownDropped:Int = -1;

	var panelChest:ChestInfo;

	var panelPrevious:Dynamic;

	var panelAbandon:Bool = false;

	/** The mod was disposed or hit a structural error: stop touching the game. */
	var closed:Bool = false;

	var failed:Bool = false;

	override public function init(context:Context):Void {
		ctx = context;
		try {
			Log.start(ctx.data);
		} catch (error:Dynamic) {}
		settings = new Settings(ctx.data, ctx.log);
		Strings.lang = settings.language;
		ctx.core.onStateEnter(function(_:StateMachine, state:State) {
			if (Std.isOfType(state, InventoryTownSubState))
				town = cast state;
		});
		ctx.core.onStateExit(function(_:StateMachine, state:State) {
			if (state == town)
				leaveTown();
		});
		ctx.onKeyDown(onKey);
		ctx.overlay.addEventListener(Event.EXIT_FRAME, tick);
		Log.write("init");
	}

	override public function ready(context:Context):Void {
		var facade = ctx.core.facade;
		if (facade != null) {
			try {
				Icon.start(facade);
			} catch (error:Dynamic) {
				Log.write("icon start failed: " + Std.string(error));
			}
		}
		Log.write("ready view=" + ctx.viewWidth + "x" + ctx.viewHeight);
	}

	override public function dispose():Void {
		closed = true;
		if (ctx != null && ctx.overlay != null)
			ctx.overlay.removeEventListener(Event.EXIT_FRAME, tick);
		closePanel();
		restoreHooks();
		Icon.destroy();
		Log.flush();
	}

	/** Puts the cards' original callbacks back where nothing else wrapped the mod's wrapper. */
	function restoreHooks():Void {
		for (card in hooked) {
			var open = wrappers.get(card);
			if (open != null && Reflect.compareMethods(card.mOpenChestCallback, open))
				card.mOpenChestCallback = previous.get(card);
			var abandon = wrappersAbandon.get(card);
			if (abandon != null && Reflect.compareMethods(card.mAbandonChestCallback, abandon))
				card.mAbandonChestCallback = previousAbandon.get(card);
		}
		hooked = [];
		wrappers = new ObjectMap();
		wrappersAbandon = new ObjectMap();
		previous = new ObjectMap();
		previousAbandon = new ObjectMap();
	}

	/** A frame after the game's own work: wrap the cards' callbacks and move the runs along. */
	function tick(_:Event):Void {
		if (closed || failed || town == null)
			return;
		try {
			var inventory:UIInventory = town.mUIInventory;
			if (inventory == null)
				return;
			hook(inventory);
			if (run != null) {
				run.update();
				if (run != null && panel != null && run.opened != shownOpened) {
					shownOpened = run.opened;
					panel.progress(run.opened, run.total, run.keysLeft(), run.goldLeft());
				}
			}
			if (dropRun != null) {
				dropRun.update();
				if (dropRun != null && panel != null && dropRun.done != shownDropped) {
					shownDropped = dropRun.done;
					panel.progressAbandon(dropRun.done, dropRun.total);
				}
			}
		} catch (error:Dynamic) {
			fail("tick: " + Std.string(error));
		}
	}

	/** Wraps the open and abandon callbacks of both chest cards of an inventory, once each. */
	function hook(inventory:UIInventory):Void {
		if (inventory != inventorySeen) {
			inventorySeen = inventory;
			hooked = [];
			wrappers = new ObjectMap();
			wrappersAbandon = new ObjectMap();
			previous = new ObjectMap();
			previousAbandon = new ObjectMap();
		}
		take(inventory.mChestCard);
		take(inventory.mConsumableChestCard);
	}

	function take(card:ChestInfoCard):Void {
		if (card == null)
			return;
		var wrapped = false;
		if (wrappers.get(card) == null) {
			var originalOpen:Dynamic = card.mOpenChestCallback;
			if (originalOpen != null) {
				previous.set(card, originalOpen);
				var openWrapper:Dynamic = function(info:Dynamic) onUnlock(info, card, originalOpen);
				wrappers.set(card, openWrapper);
				card.mOpenChestCallback = openWrapper;
				wrapped = true;
			}
		}
		if (wrappersAbandon.get(card) == null) {
			var originalAbandon:Dynamic = card.mAbandonChestCallback;
			if (originalAbandon != null) {
				previousAbandon.set(card, originalAbandon);
				var abandonWrapper:Dynamic = function(info:Dynamic) onAbandon(info, card, originalAbandon);
				wrappersAbandon.set(card, abandonWrapper);
				card.mAbandonChestCallback = abandonWrapper;
				wrapped = true;
			}
		}
		if (wrapped && hooked.indexOf(card) < 0)
			hooked.push(card);
		if (wrapped)
			Log.write("hook");
	}

	/** UNLOCK: the panel, or the game's own popup when nothing can be opened. */
	function onUnlock(info:Dynamic, card:ChestInfoCard, original:Dynamic):Void {
		if (closed || failed) {
			pass(original, info);
			return;
		}
		var chest:ChestInfo = cast info;
		var facade = ctx.core.facade;
		if (chest == null || facade == null) {
			pass(original, chest);
			return;
		}
		var inventoryInfo = facade.dbAccountInfo.inventoryInfo;
		if (inventoryInfo == null || chest.isFromDungeonSummary()) {
			pass(original, chest);
			return;
		}
		var kind = Std.int(chest.gmId);
		var available = ChestRun.count(inventoryInfo, kind);
		var max = maxFor(facade, inventoryInfo, kind, available);
		Log.write("click kind=" + kind + " available=" + available + " max=" + max + " keys=" + keyCount(inventoryInfo, kind));
		if (available <= 0 || max <= 0) {
			// Nothing the mod can do: let the game show its own window, gem purchases included.
			pass(original, chest);
			return;
		}
		try {
			openPanel(facade, chest, inventoryInfo, available, max, original, false);
			Log.write("panel=" + (panel != null && panel.isShown()));
		} catch (error:Dynamic) {
			Log.write("PANEL FAILED: " + Std.string(error));
			closePanel();
			pass(original, chest);
		}
	}

	/** ABANDON: the same panel, in discard mode. */
	function onAbandon(info:Dynamic, card:ChestInfoCard, original:Dynamic):Void {
		if (closed || failed) {
			pass(original, info);
			return;
		}
		var chest:ChestInfo = cast info;
		var facade = ctx.core.facade;
		if (chest == null || facade == null) {
			pass(original, chest);
			return;
		}
		var inventoryInfo = facade.dbAccountInfo.inventoryInfo;
		if (inventoryInfo == null || chest.isFromDungeonSummary()) {
			pass(original, chest);
			return;
		}
		var kind = Std.int(chest.gmId);
		var available = ChestRun.count(inventoryInfo, kind);
		Log.write("abandon click kind=" + kind + " available=" + available);
		if (available <= 0) {
			pass(original, chest);
			return;
		}
		try {
			openPanel(facade, chest, inventoryInfo, available, available, original, true);
		} catch (error:Dynamic) {
			Log.write("ABANDON PANEL FAILED: " + Std.string(error));
			closePanel();
			pass(original, chest);
		}
	}

	/** Hands a click back to the game's own open or abandon. */
	function pass(original:Dynamic, info:Dynamic):Void {
		if (original == null || info == null)
			return;
		try {
			original(info);
		} catch (error:Dynamic) {
			Log.write("pass failed: " + Std.string(error));
		}
	}

	/** How many the keys owned and the gold to buy more allow, up to the chests held. */
	function maxFor(facade:DBFacade, inventoryInfo:DBInventoryInfo, gmId:Int, available:Int):Int {
		var key = keyOf(inventoryInfo, gmId);
		var keys = key == null ? 0 : Std.int(key.count);
		var offer:GMOffer = key == null ? null : key.gmKeyOffer;
		var buyable = 0;
		if (settings.payGold && offer != null && offer.Price > 0 && offer.CurrencyType == GMOffer.BASIC_CURRENCY)
			buyable = Std.int(Math.floor(facade.dbAccountInfo.basicCurrency / offer.Price));
		var max = keys + buyable;
		return max > available ? available : max;
	}

	function openPanel(facade:DBFacade, chest:ChestInfo, inventoryInfo:DBInventoryInfo, available:Int, max:Int, original:Dynamic,
			abandon:Bool):Void {
		closePanel();
		gmId = Std.int(chest.gmId);
		panelChest = chest;
		panelPrevious = original;
		panelAbandon = abandon;
		panel = new Panel(ctx.overlay, ctx.viewWidth, ctx.viewHeight);
		panel.onOpen = startRun;
		panel.onAbandon = startAbandon;
		panel.onGold = setGold;
		panel.onClose = closePanel;
		panel.onStop = stopRun;
		panel.onGame = useGameWindow;
		panel.onLanguage = toggleLanguage;
		shownOpened = -1;
		shownDropped = -1;
		var wanted = 1;
		if (wanted > max)
			wanted = max;
		if (wanted < 1)
			wanted = 1;
		panel.ask(chestName(chest), chestColor(facade, chest), available, abandon ? 0 : keyCount(inventoryInfo, gmId),
			abandon ? 0 : facade.dbAccountInfo.basicCurrency, abandon ? 0 : priceFor(inventoryInfo, gmId), abandon ? available : max, wanted,
			settings.payGold, abandon);
	}

	/** The gold toggle of the panel: the range it allows changes with it. */
	function setGold(value:Bool):Void {
		if (panel == null || panelAbandon)
			return;
		settings.payGold = value;
		settings.save();
		refreshNumbers();
	}

	function refreshNumbers():Void {
		var facade = ctx.core.facade;
		if (panel == null || panelAbandon || facade == null)
			return;
		var inventoryInfo = facade.dbAccountInfo.inventoryInfo;
		if (inventoryInfo == null)
			return;
		var available = ChestRun.count(inventoryInfo, gmId);
		var max = maxFor(facade, inventoryInfo, gmId, available);
		panel.numbers(available, keyCount(inventoryInfo, gmId), facade.dbAccountInfo.basicCurrency, priceFor(inventoryInfo, gmId), max,
			settings.payGold);
	}

	function toggleLanguage():Void {
		settings.language = Strings.lang == "es" ? "en" : "es";
		settings.save();
		Strings.lang = settings.language;
		if (panel != null)
			panel.rebuild();
	}

	/** The game's own chest window, for buying keys with gems or the normal one-by-one flow. */
	function useGameWindow():Void {
		var chest = panelChest;
		var original = panelPrevious;
		Log.write("game window abandon=" + panelAbandon);
		closePanel();
		pass(original, chest);
	}

	function startRun(amount:Int):Void {
		var facade = ctx.core.facade;
		if (panel == null || facade == null)
			return;
		shownOpened = 0;
		panel.running(amount, false);
		keepCardOnThisChest();
		var avatar = heroSelected(facade);
		var heroId:UInt = avatar == null ? 0 : avatar.id;
		var heroSkin:UInt = avatar == null ? 0 : avatar.skinId;
		var fullInventory = ctx.isActive("full_inventory");
		Log.write("run start amount=" + amount + " hero=" + heroId + " skin=" + heroSkin + " fullInventory=" + fullInventory
			+ " payGold=" + settings.payGold);
		var opening = new ChestRun(facade, gmId, settings.payGold, fullInventory, finishRun);
		run = opening;
		opening.start(amount, heroId, heroSkin);
	}

	function startAbandon(amount:Int):Void {
		var facade = ctx.core.facade;
		if (panel == null || facade == null)
			return;
		shownDropped = 0;
		panel.running(amount, true);
		keepCardOnThisChest();
		Log.write("abandon start amount=" + amount);
		var dropping = new AbandonRun(facade, gmId, finishAbandon);
		dropRun = dropping;
		dropping.start(amount);
	}

	/**
	 * The hero the game opens them for: the one picked in the inventory, as `UIInventory.openChest`
	 * does, and the account's active hero only when that picker is not there.
	 */
	function heroSelected(facade:DBFacade):AvatarInfo {
		try {
			var inventory:UIInventory = town == null ? null : town.mUIInventory;
			if (inventory != null && inventory.mHeroWithEquipPicker != null) {
				var heroType:UInt = inventory.mHeroWithEquipPicker.currentlySelectedHero.Id;
				var avatar:AvatarInfo = facade.dbAccountInfo.inventoryInfo.getAvatarInfoForHeroType(heroType);
				if (avatar != null)
					return avatar;
			}
		} catch (error:Dynamic) {
			Log.write("hero lookup failed: " + Std.string(error));
		}
		return facade.dbAccountInfo.activeAvatarInfo;
	}

	/**
	 * The game refreshes the inventory on every answer of the server: pointing it at this chest has the
	 * card follow its live stack, and hide once the chests are gone.
	 */
	function keepCardOnThisChest():Void {
		if (town == null)
			return;
		try {
			var inventory:UIInventory = town.mUIInventory;
			if (inventory != null)
				inventory.mLastActedChestGmId = cast gmId;
		} catch (error:Dynamic) {}
	}

	function finishRun():Void {
		if (run == null || panel == null)
			return;
		var done = run;
		run = null;
		Log.write("run end opened=" + done.opened + " failed=" + done.failed);
		panel.result(done.opened, done.loot, done.message(), done.failed == null && !done.stoppedByPlayer);
		Log.flush();
	}

	function finishAbandon():Void {
		if (dropRun == null || panel == null)
			return;
		var done = dropRun;
		dropRun = null;
		Log.write("abandon end done=" + done.done + " failed=" + done.failed);
		panel.abandoned(done.done, done.message(), done.failed == null && !done.stoppedByPlayer);
		Log.flush();
	}

	function stopRun():Void {
		if (run != null)
			run.stop();
		if (dropRun != null)
			dropRun.stop();
	}

	function closePanel():Void {
		if (panel != null) {
			panel.close();
			panel = null;
		}
		if (run != null) {
			run.stop();
			run = null;
		}
		if (dropRun != null) {
			dropRun.stop();
			dropRun = null;
		}
		panelChest = null;
		panelPrevious = null;
		panelAbandon = false;
	}

	function leaveTown():Void {
		town = null;
		closePanel();
		inventorySeen = null;
		hooked = [];
		wrappers = new ObjectMap();
		wrappersAbandon = new ObjectMap();
		previous = new ObjectMap();
		previousAbandon = new ObjectMap();
	}

	/** The panel keeps every key while it shows: Escape stops or closes, Enter confirms. */
	function onKey(key:UInt):Bool {
		if (panel == null || !panel.isShown())
			return false;
		if (key == ENTER) {
			panel.confirm();
			return true;
		}
		if (key == ESCAPE) {
			if (run != null || dropRun != null)
				stopRun();
			else
				closePanel();
			return true;
		}
		return true;
	}

	function fail(reason:String):Void {
		if (failed)
			return;
		failed = true;
		Log.write("FAILED: " + reason);
		Log.flush();
		closePanel();
	}

	function chestName(chest:ChestInfo):String {
		try {
			if (chest.gmChestInfo != null) {
				var name = GameMasterLocale.getGameMasterSubString("CHEST_NAME", chest.gmChestInfo.Rarity);
				if (name != null)
					return name;
			}
		} catch (error:Dynamic) {}
		return "Cofre";
	}

	function chestColor(facade:DBFacade, chest:ChestInfo):Int {
		try {
			var rarity:GMRarity = cast facade.gameMaster.rarityByConstant.itemFor(chest.gmChestInfo.Rarity);
			if (rarity != null && Std.int(rarity.TextColor) != 0)
				return Std.int(rarity.TextColor);
		} catch (error:Dynamic) {}
		return Ui.TEXT;
	}

	static function keyOf(inventoryInfo:DBInventoryInfo, gmId:Int):KeyInfo {
		var keys = inventoryInfo.keys;
		var i = 0;
		while (i < keys.length) {
			var key = keys[i];
			if (key != null && key.gmKey != null && Std.int(key.gmKey.ChestId) == gmId)
				return key;
			i++;
		}
		return null;
	}

	function keyCount(inventoryInfo:DBInventoryInfo, gmId:Int):Int {
		var key = keyOf(inventoryInfo, gmId);
		return key == null ? 0 : Std.int(key.count);
	}

	function priceFor(inventoryInfo:DBInventoryInfo, gmId:Int):Float {
		var key = keyOf(inventoryInfo, gmId);
		if (key == null || key.gmKeyOffer == null)
			return 0;
		return key.gmKeyOffer.Price;
	}
}