package elke.res;

import h2d.Tile;
import elke.graphics.Animation;
import elke.graphics.AsepriteResource;
import elke.graphics.Sprite;
import elke.graphics.Sprite3D;

typedef Frame = {
	offsetX:Int,
	offsetY:Int,
	tile : h2d.Tile,
	duration:Int,
	?slices: Map<String, AseBound>,
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

typedef Slice = {
	name: String,
	keys :	Array<{
		frame: Int,
		bounds: AseBound,
	}>
}

typedef TileSheetConfig = {
	events : Array<TileSheetEvent>,
}

typedef AnimationId = String;

class TileSheetRes extends hxd.res.Resource {

	static var ENABLE_AUTO_WATCH = true;

	var loaded = false;
	public var frames : Array<Frame>;
	public var animations:Map<AnimationId, AnimationData>;
	
	public var slices: Map<String, Slice>;

	public var width(default, null) : Int;
	public var height(default, null) : Int;

	public var totalLength : Int;

	/**
	 * Full tile of the tilesheet
	 */
	public var tile(default, set): Tile;

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

	var data: AseFile;
    function loadData() : TileSheetRes {
		if (!loaded) {
			if(ENABLE_AUTO_WATCH)
				watch(watchCallb);
		}

		this.animations = new Map<AnimationId, AnimationData>();
		this.slices = new Map<String, Slice>();

		data = haxe.Json.parse(entry.getText());
		var basePath = entry.path.substr(0, entry.path.length - ".tilesheet".length);

		if (hxd.res.Loader.currentInstance.exists(basePath + ".json")) {
			var config = hxd.res.Loader.currentInstance.load(basePath + ".json").toText();
			if (config != null) {
				var events : TileSheetConfig = haxe.Json.parse(config);
				this.events = events.events;
			}
		}

		var tile = hxd.res.Loader.currentInstance.load(basePath + ".png").toTile();
		this.tile = tile;

		if (data.meta.slices != null) {
			for (s in data.meta.slices) {
				slices[s.name] = {
					name: s.name,
					keys: s.keys,
				}
			}
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

		generateFrames(tile);

		loaded = true;

		return this;
	}

	function getSlicesForFrame(frame: Int) {
		var slices = new Map<String, AseBound>();
		var empty = true;
		for (name => slice in this.slices) {
			for (s in slice.keys) {
				if (s.frame == frame) {
					slices[name] = s.bounds;
					empty = false;
					break;
				}
			}
		}

		if (empty) {
			return null;
		}

		return slices;
	}
	
	function generateFrames(tile: Tile) {
		width = data.frames[0].sourceSize.w;
		height = data.frames[0].sourceSize.h;

		frames = [];

		var frameIndex = 0;
		for (f in data.frames) {
			var dx = f.spriteSourceSize.x;
			var dy = f.spriteSourceSize.y;

			frames.push({
				tile: tile.sub(f.frame.x, f.frame.y, f.frame.w, f.frame.h, dx, dy),
				duration: f.duration,
				offsetX: dx,
				offsetY: dy,
				slices: getSlicesForFrame(frameIndex),
			});

			frameIndex ++;
		}

		totalLength = 0;
		var l = 0;

		for (f in frames) {
			l = f.duration;
			totalLength += f.duration;
		}

		return tile;
	}

	function set_tile(tile: Tile) {
		generateFrames(tile);
		return this.tile = tile;
	}

	public function toAnimation() : Animation {
		if (!loaded) { 
			loadData();
		}

		return new Animation(this);
	}

	public function toTileSheet(): TileSheetRes {
		if (!loaded) {
			loadData();
		}

		return this;
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
