package elke.graphics;

import h2d.Drawable;
import h2d.Object;
import h2d.Bitmap;
import h3d.mat.Texture;
import h2d.RenderContext;
import h2d.TileGroup;
import h2d.Tile;

class TextureAtlas {

	final maxWidth = 1024 << 1;
	final maxHeight = 1024 << 1;

	var atlas: Texture;
	public var atlasTile: Tile;

	var namedTiles: Map<String, Tile> = new Map();
	
	var tileList: Array<Tile> = [];

	public function new() {
		resetTexture();
	}

	function resetTexture() {
		if (atlas != null) {
			atlas.dispose();
			atlas = null;
		}

		atlas = new Texture(maxWidth, maxHeight, [Target], RGBA);
		atlas.clear(0x000000, 0.0);
		atlasTile = Tile.fromTexture(atlas);
	}

	var cx = 0;
	var cy = 0;
	var rowHeight = 0;

	public function addObject(o: Object) {
		var b = o.getBounds();
		if (cx + b.width > maxWidth) {
			cx = 0;
			cy += rowHeight;
			rowHeight = 0;
		}

		if (b.height > rowHeight) rowHeight = Std.int(b.height);

		o.x = cx;
		o.y = cy;
		o.drawTo(atlas);

		var res = atlasTile.sub(cx, cy, b.width, b.height);

		cx += Std.int(b.width);

		return res;
	}

	/**
	 * skips to the next row in the packing
	 */
	public function nextRow() {
		cx = 0;
		cy += rowHeight;
		rowHeight = 0;
	}

	public function getNamedTile(name) {
		return namedTiles[name];
	}

	public function addNamedTile(tile:Tile, name){
		if (namedTiles.exists(name)) {
			return namedTiles[name];
		}

		var t = addObject(new Bitmap(tile));
		namedTiles[name] = t;

		return t;
	}
}