package mods.multi_chest_opener;

import brain.assetRepository.AssetLoadingComponent;
import brain.assetRepository.SwfAsset;
import brain.uI.UIObject;
import facade.DBFacade;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;

/** Loads one of the game's icons into a container, centred and scaled to fit. */
class Icon {
	static var facade:DBFacade = null;

	static var loader:AssetLoadingComponent = null;

	public static function start(facade:DBFacade):Void {
		if (facade == null || loader != null)
			return;
		Icon.facade = facade;
		loader = new AssetLoadingComponent(facade);
	}

	public static function load(swf:String, name:String, size:Float, into:DisplayObjectContainer, behind:Bool = false):Void {
		if (loader == null || into == null || swf == null || swf == "" || name == null || name == "")
			return;
		try {
			loader.getSwfAsset(DBFacade.buildFullDownloadPath(swf), function(asset:SwfAsset) {
				if (asset == null)
					return;
				var type:Dynamic = asset.getClass(name);
				if (type == null)
					return;
				var clip:DisplayObject = cast ASCompat.createInstance(type, []);
				UIObject.scaleToFit(clip, size);
				if (behind && into.numChildren > 0)
					into.addChildAt(clip, 0);
				else
					into.addChild(clip);
			});
		} catch (error:Dynamic) {}
	}

	public static function destroy():Void {
		if (loader != null) {
			loader.destroy();
			loader = null;
		}
		facade = null;
	}
}
