package elke.res;

import elke.graphics.Animation;
import elke.graphics.AsepriteResource;
import elke.graphics.Sprite;
import elke.graphics.Sprite3D;

typedef Frame = {
	offsetX:Int,
	offsetY:Int,
	tile : h2d.Tile,
	duration:Int,
}

typedef AnimationData = {
	name:String,
	from:Int,
	to:Int,
	totalLength:Int,
	looping:Bool,
	linearSpeed:Bool,
	frameDuration:Int
}

typedef TileSheetEvent = {
	frame : Int,
	type : String,
	name : String,
}

typedef TileSheetConfig = {
	events : Array<TileSheetEvent>,
}

typedef AnimationId = String;

class TileSheetRes extends hxd.res.Resource {

	static var ENABLE_AUTO_WATCH = true;

	var loaded = false;
	public var image : h2d.Tile;
	public var frames : Array<Frame>;
	public var animations:Map<AnimationId, AnimationData>;

	public var width(default, null) : Int;
	public var height(default, null) : Int;

	public var totalLength : Int;

	var tiles : Array<h2d.Tile>;

	public var events : Array<TileSheetEvent>;

	function new(entry) {
		super(entry);
		if (entry != null) {
			loadData();
		}
	}

	public inline function getAnimation(?animation:AnimationId) {
		if (animations[animation] == null) {
			return null;
		}

		return animations[animation];
	}

	function watchCallb() {
		loadData();
	}

    function loadData() : TileSheetRes {
		if (!loaded) {
			if(ENABLE_AUTO_WATCH)
				watch(watchCallb);
		}

		this.frames = [];
		this.tiles = [];
		this.animations = new Map<AnimationId, AnimationData>();
		var data : AseFile = haxe.Json.parse(entry.getText());
		var basePath = entry.path.substr(0, entry.path.length - ".tilesheet".length);

		if (hxd.res.Loader.currentInstance.exists(basePath + ".json")) {
			var config = hxd.res.Loader.currentInstance.load(basePath + ".json").toText();
			if (config != null) {
				var events : TileSheetConfig = haxe.Json.parse(config);
				this.events = events.events;
			}
		}

		var tile = hxd.res.Loader.currentInstance.load(basePath + ".png").toTile();
		image = tile;
		width = data.frames[0].sourceSize.w;
		height = data.frames[0].sourceSize.h;

		for (f in data.frames) {
			var dx = f.spriteSourceSize.x;
			var dy = f.spriteSourceSize.y;

			frames.push({
				tile: tile.sub(f.frame.x, f.frame.y, f.frame.w, f.frame.h, dx, dy),
				duration: f.duration,
				offsetX: dx,
				offsetY: dy,
			});
		}

		if (data.meta.frameTags != null) {
			for (s in data.meta.frameTags) {
				animations[s.name] = s;

				var frameCount = s.to - s.from;
				s.totalLength = 0;

				s.looping = true;
				var l:Int = -1;

				s.linearSpeed = true;

				for (i in 0...frameCount + 1) {
					if (l == -1) {
						l = frames[i + s.from].duration;
						s.frameDuration = l;
					} else if (l != frames[i + s.from].duration) {
						s.linearSpeed = false;
						s.frameDuration = -1;
					}

					s.totalLength += frames[i + s.from].duration;
				}
			}
		}

		totalLength = 0;
		var l = 0;

		for (f in frames) {
			l = f.duration;
			totalLength += f.duration;
		}

		loaded = true;

		return this;
	}

	public function toAnimation() : Animation {
		if (!loaded) { 
			loadData();
		}

		return new Animation(this);
	}

	public function toSprite3D(?parent) : Sprite3D {
		var anim = toAnimation();
		return new Sprite3D(anim, parent);
	}

	public function toSprite2D(?parent) : Sprite {
		var anim = toAnimation();
		return new Sprite(anim, parent);
	}
}
