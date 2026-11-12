package mods.multi_chest_opener;

import account.ItemInfo;
import facade.DBFacade;
import facade.GameMasterLocale;
import gameMasterDictionary.GMNpc;
import gameMasterDictionary.GMOffer;
import gameMasterDictionary.GMRarity;
import gameMasterDictionary.GMStackable;
import openfl.Vector;

/** One thing a chest gave: its name, its colour and the icon the game draws it with. */
class Loot {
	public var name:String;

	public var color:Int;

	public var count:Int = 1;

	/** The icon's SWF and class, and the rarity background's, when it has one. */
	public var swf:String;

	public var icon:String;

	public var backgroundSwf:String;

	public var backgroundIcon:String;

	/** What the card shown on hover reads, for a weapon. */
	public var kind:String = "";

	public var level:Int = 0;

	public var power:Int = 0;

	public var typeName:String = "";

	public var modNames:Array<String> = [];

	public var legendary:Bool = false;

	public function new(name:String, color:Int) {
		this.name = name;
		this.color = color;
	}

	/** The loot in an `OpenChest` answer, or null when it names nothing this knows. */
	public static function of(facade:DBFacade, details:Dynamic):Loot {
		if (facade == null || details == null)
			return null;
		try {
			var result:Dynamic = details;
			var custom:Dynamic = Reflect.field(details, "customResult");
			if (custom != null) {
				var purchased:Dynamic = Reflect.field(custom, "purchasedChestResults");
				if (purchased != null)
					result = purchased;
			}
			var offerId:Int = field(result, "OfferId");
			var weaponId:Int = field(result, "WeaponId");
			var offer:GMOffer = offerId == 0 ? null : cast facade.gameMaster.offerById.itemFor(offerId);
			if (offer == null)
				return weapon(facade, weaponId);
			return fromOffer(facade, offer);
		} catch (error:Dynamic) {
			return null;
		}
	}

	static function weapon(facade:DBFacade, weaponId:Int):Loot {
		if (weaponId == 0)
			return null;
		var item:ItemInfo = cast facade.dbAccountInfo.inventoryInfo.items.itemFor(weaponId);
		if (item == null || item.gmWeaponItem == null)
			return null;
		var aesthetic = item.gmWeaponItem.getWeaponAesthetic(item.requiredLevel, item.legendaryModifier > 0);
		var name = GameMasterLocale.getGameMasterSubString("WEAPON_AESTHETIC_NAME", aesthetic.Constant);
		var modifiers = item.modifiers;
		var prefix = "";
		var i = 0;
		while (i < modifiers.length) {
			prefix += GameMasterLocale.getGameMasterSubString("MODIFIER_NAME", modifiers[i].Constant) + " ";
			i++;
		}
		var loot = new Loot(prefix + name, Std.int(item.getTextColor()));
		loot.swf = item.uiSwfFilepath;
		loot.icon = item.iconName;
		if (item.hasColoredBackground) {
			loot.backgroundSwf = item.backgroundSwfPath;
			loot.backgroundIcon = item.backgroundIconName;
		}
		loot.kind = "kind_weapon";
		loot.level = Std.int(item.requiredLevel);
		loot.power = Std.int(item.power);
		loot.legendary = item.legendaryModifier > 0;
		try {
			var typeName = GameMasterLocale.getGameMasterSubString("WEAPON_ITEM_NAME", item.gmWeaponItem.Constant);
			if (typeName != null)
				loot.typeName = typeName.toUpperCase();
		} catch (error:Dynamic) {}
		var j = 0;
		while (j < modifiers.length) {
			var modName = GameMasterLocale.getGameMasterSubString("MODIFIER_NAME", modifiers[j].Constant);
			if (modName != null)
				loot.modNames.push(modName.toUpperCase());
			j++;
		}
		return loot;
	}

	static function fromOffer(facade:DBFacade, offer:GMOffer):Loot {
		var name:String = null;
		var swf:String = null;
		var icon:String = null;
		var kind = "kind_item";
		if (offer.IsBundle) {
			name = GameMasterLocale.getGameMasterSubString("BUNDLE_OFFER_NAME", Std.string(offer.Id));
			swf = offer.BundleSwfFilepath;
			icon = offer.BundleIcon;
			kind = "kind_bundle";
		} else if (offer.Details != null) {
			var details = offer.Details;
			var i = 0;
			while (i < details.length && name == null) {
				var detail = details[i];
				if (detail.StackableId != 0) {
					var stackable:GMStackable = cast facade.gameMaster.stackableById.itemFor(detail.StackableId);
					if (stackable != null) {
						name = GameMasterLocale.getGameMasterSubString("STACKABLE_NAME", stackable.Constant);
						swf = stackable.UISwfFilepath;
						icon = stackable.IconName;
						kind = "kind_consumable";
					}
				} else if (detail.PetId != 0) {
					var pet:GMNpc = cast facade.gameMaster.npcById.itemFor(detail.PetId);
					if (pet != null) {
						name = GameMasterLocale.getGameMasterSubString("PET_NAME", pet.Constant);
						swf = pet.IconSwfFilepath;
						icon = pet.IconName;
						kind = "kind_pet";
					}
				}
				i++;
			}
		}
		if (name == null)
			name = offer.getDisplayName(facade.gameMaster, "Botin");
		var color = 0xFFF1D0;
		var rarity:GMRarity = cast facade.gameMaster.rarityByConstant.itemFor(offer.Rarity);
		if (rarity != null && Std.int(rarity.TextColor) != 0)
			color = Std.int(rarity.TextColor);
		var loot = new Loot(name, color);
		loot.swf = swf;
		loot.icon = icon;
		loot.kind = kind;
		return loot;
	}

	static function field(source:Dynamic, key:String):Int {
		if (source == null)
			return 0;
		var value:Dynamic = null;
		try {
			value = Reflect.field(source, key);
		} catch (error:Dynamic) {
			return 0;
		}
		if (value == null)
			return 0;
		return Std.int(value);
	}
}


