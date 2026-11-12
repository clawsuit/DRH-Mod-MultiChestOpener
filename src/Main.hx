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
import mods.api.Context;
import mods.api.Mod;
import openfl.events.Event;
import town.InventoryTownSubState;
import uI.inventory.UIInventory;
import uI.inventory.chests.ChestInfoCard;

/**
 * Many chests at once from the town's inventory: UNLOCK opens a panel with a slider, from 1 to what
 * the keys owned and the gold to buy more allow. The run opens them one after the other, keeping the
 * loot for the panel's grid of icons.
 *
 * It takes the chest cards' open callback, as `full_inventory` does.
 */
@:privateAccess
class Main extends Mod {
	static inline final ESCAPE:UInt = 27;

	static inline final ENTER:UInt = 13;

	var ctx:Context;

	var settings:Settings;

	var town:InventoryTownSubState;

	/** The cards whose callback is taken, so each is taken once while its inventory lasts. */
	var hooked:Array<Dynamic> = [];

	/** What the cards are given instead of the game's open: kept, as Dynamic, for the field they sit in. */
	var handler:Dynamic;

	/** The callback the cards had before, to hand a click back to the game. */
	var passThrough:Dynamic;

	var panel:Panel;

	var run:ChestRun;

	/** The kind of chest the panel is about. */
	var gmId:Int = 0;

	/** The number of opened chests the panel shows last, -1 before a run. */
	var shownOpened:Int = -1;

	override public function init(context:Context):Void {
		ctx = context;
		try {
			Log.start(ctx.data);
		} catch (error:Dynamic) {}
		settings = new Settings(ctx.data, ctx.log);
		handler = onUnlock;
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
		closePanel();
		Icon.destroy();
	}

	/** A frame after the game's own work: take the cards' callback and move the run along. */
	function tick(_:Event):Void {
		if (town == null)
			return;
		var inventory:UIInventory = town.mUIInventory;
		if (inventory == null)
			return;
		hook(inventory);
		if (run != null) {
			run.update();
			if (panel != null && run.opened != shownOpened) {
				shownOpened = run.opened;
				panel.progress(run.opened, run.total, run.keysLeft(), run.goldLeft());
			}
		}
	}

	/** Takes the open callback of both chest cards of an inventory, once each. */
	function hook(inventory:UIInventory):Void {
		take(inventory.mChestCard);
		take(inventory.mConsumableChestCard);
	}

	function take(card:ChestInfoCard):Void {
		if (card == null || hooked.indexOf(card) >= 0)
			return;
		if (passThrough == null)
			passThrough = card.mOpenChestCallback;
		card.mOpenChestCallback = handler;
		hooked.push(card);
		Log.write("hook: card taken");
	}

	/** UNLOCK: the panel, or the game's own popup when nothing can be opened. */
	function onUnlock(info:Dynamic):Void {
		var chest:ChestInfo = info;
		var facade = ctx.core.facade;
		Log.write("click " + (chest == null ? "null" : Std.string(chest.gmId)));
		if (chest == null || facade == null) {
			pass(chest);
			return;
		}
		var inventoryInfo = facade.dbAccountInfo.inventoryInfo;
		if (inventoryInfo == null || chest.isFromDungeonSummary()) {
			pass(chest);
			return;
		}
		var kind = Std.int(chest.gmId);
		var available = ChestRun.count(inventoryInfo, kind);
		var max = maxFor(facade, inventoryInfo, kind, available);
		Log.write("available=" + available + " max=" + max + " keys=" + keyCount(inventoryInfo, kind));
		if (available <= 0 || max <= 0) {
			pass(chest);
			return;
		}
		try {
			openPanel(facade, chest, inventoryInfo, available, max);
			Log.write("panel=" + (panel != null && panel.isShown()));
		} catch (error:Dynamic) {
			Log.write("PANEL FAILED: " + Std.string(error));
			closePanel();
			pass(chest);
		}
	}

	/** Hands a click back to the game's own open, such as its buy-keys popup. */
	function pass(chest:ChestInfo):Void {
		Log.write("pass=" + (passThrough != null));
		if (passThrough == null || chest == null)
			return;
		try {
			passThrough(chest);
		} catch (error:Dynamic) {
			// The inventory that owned that callback is gone: a new town visit builds another.
			Log.write("pass failed: " + Std.string(error));
			passThrough = null;
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

	function openPanel(facade:DBFacade, chest:ChestInfo, inventoryInfo:DBInventoryInfo, available:Int, max:Int):Void {
		closePanel();
		gmId = Std.int(chest.gmId);
		panel = new Panel(ctx.overlay, ctx.viewWidth, ctx.viewHeight, settings);
		panel.onOpen = startRun;
		panel.onGold = setGold;
		panel.onClose = closePanel;
		panel.onStop = stopRun;
		shownOpened = -1;
		var wanted = settings.amount;
		if (wanted > max)
			wanted = max;
		if (wanted < 1)
			wanted = 1;
		panel.ask(chestName(chest), chestColor(facade, chest), available, keyCount(inventoryInfo, gmId), facade.dbAccountInfo.basicCurrency,
			priceFor(inventoryInfo, gmId), max, wanted, settings.payGold);
	}

	/** The gold toggle of the panel: the range it allows changes with it. */
	function setGold(value:Bool):Void {
		settings.payGold = value;
		settings.save();
		var facade = ctx.core.facade;
		if (panel == null || facade == null)
			return;
		var inventoryInfo = facade.dbAccountInfo.inventoryInfo;
		var available = ChestRun.count(inventoryInfo, gmId);
		var max = maxFor(facade, inventoryInfo, gmId, available);
		panel.numbers(available, keyCount(inventoryInfo, gmId), facade.dbAccountInfo.basicCurrency, priceFor(inventoryInfo, gmId), max, value);
	}

	function startRun(amount:Int):Void {
		var facade = ctx.core.facade;
		if (panel == null || facade == null)
			return;
		settings.amount = amount;
		settings.save();
		shownOpened = 0;
		panel.running(amount);
		keepCardOnThisChest();
		var avatar = heroSelected(facade);
		var heroId:UInt = avatar == null ? 0 : avatar.id;
		var heroSkin:UInt = avatar == null ? 0 : avatar.skinId;
		Log.write("run start amount=" + amount + " hero=" + heroId + " skin=" + heroSkin);
		var opening = new ChestRun(facade, gmId, settings.payGold, finishRun);
		run = opening;
		opening.start(amount, heroId, heroSkin);
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
	}

	function stopRun():Void {
		if (run != null)
			run.stop();
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
	}

	function leaveTown():Void {
		town = null;
		hooked = [];
		// The callback belongs to the inventory the game destroys on leaving: a new town visit
		// builds another one, and calling the old one throws.
		passThrough = null;
		closePanel();
	}

	/** The panel keeps every key while it shows: Escape closes it, Enter opens the amount picked. */
	function onKey(key:UInt):Bool {
		if (panel == null || !panel.isShown())
			return false;
		if (key == ENTER) {
			panel.confirm();
			return true;
		}
		if (key == ESCAPE) {
			if (run == null)
				closePanel();
			return true;
		}
		return true;
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


