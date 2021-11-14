package elke.graphics;

import h2d.RenderContext;
import h2d.Tile;
import h2d.Bitmap;
import h3d.mat.Texture;
import elke.res.TileSheetRes;
import h2d.TileGroup;

class SpriteGroupTileSheet {
	var x = 0;
	var y = 0;
	var name: String;
	public var tiles: Array<Tile>;
	public var res: TileSheetRes;
	public function new(x, y, res:TileSheetRes, rootTile: Tile) {
		this.x = x;
		this.y = y;
		this.name = res.name;
		this.res = res;
		this.tiles = [];
		for (frame in res.frames) {
			var tile = frame.tile;
			var t = rootTile.sub(tile.ix + x, tile.iy + y, tile.width, tile.height);
			tiles.push(t);
		}
	}
}

class SpriteGroup extends TileGroup {
	var sheetMap: Map<String, SpriteGroupTileSheet>;
	var sprites: Array<SpriteGroupSprite> = [];
	//static var debugAtlas: Bitmap;

	var atlas: Texture;
	var rootTile: Tile;

	public function new(?tilesheets: Array<TileSheetRes>, ?p) {
		super(null, p);

		if (tilesheets != null) {
			compile(tilesheets);
		}
	}

	override function sync(ctx:RenderContext) {
		super.sync(ctx);
		clear();
		for (s in sprites) {
			if (s.visible && s.tile != null) {
				curColor.a = s.alpha;
				addTransform(
					s.x,
					s.y,
					s.scaleX,
					s.scaleY,
					s.rotation,
					s.tile
				);
			}
		}
	}

	override function onRemove() {
		super.onRemove();
		if (atlas != null) {
			atlas.dispose();
		}
	}

	public function addSprite(name: String) {
		var s = sheetMap[name];
		if (s == null) {
			return null;
		}

		var anim = new Animation(s.res);
		var s = new SpriteGroupSprite(anim, s, this);

		sprites.push(s);

		return s;
	}

	public function removeSprite(sprite: SpriteGroupSprite) {
		sprites.remove(sprite);
	}

	public function clearGroup() {
		sprites = [];
	}

	function compile(sheets: Array<TileSheetRes>) {
		//debugAtlas = new Bitmap(null, Game.instance.s2d);
		sheetMap = new Map();

		if (sheetMap != null) {
			sheetMap.clear();
		}

		final maxWidth = 1024;
		final maxHeight = 1024;
		if (atlas != null) {
			atlas.dispose();
			atlas = null;
		}

		atlas = new Texture(maxWidth, maxHeight, [Target], RGBA);
		atlas.clear(0x000000, 0.0);

		sheets.sort((a, b) -> Std.int(a.tile.height - b.tile.height));

		var x = 0;
		var y = 0;
		var rowH = 0;

		var bm = new Bitmap();
		rootTile = Tile.fromTexture(atlas);
		for (sheet in sheets) {
			var t = sheet.tile;
			bm.tile = t;
			if (x + t.width > maxWidth) {
				x = 0;
				y += rowH;
				rowH = 0;
			}
			if (rowH < t.height) {
				rowH = Std.int(t.height);
			}
			bm.x = x;
			bm.y = y;
			bm.drawTo(atlas);
			sheetMap.set(sheet.name, new SpriteGroupTileSheet(x, y, sheet, rootTile));
			x += Std.int(t.width);
		}

		//var resBm = new Bitmap(rootTile, this);
		//debugAtlas.tile = rootTile;
	}

	public var sortY = true;

	public function update(dt: Float) {
		if (sortY) {
			sprites.sort((a, b) -> Std.int((a.y + a.offsetY) - (b.y + b.offsetY)));
		}

		for (s in sprites) {
			s.update(dt);
		}
	}
}