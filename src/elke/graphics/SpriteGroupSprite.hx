package elke.graphics;

import elke.graphics.SpriteGroup.SpriteGroupTileSheet;
import h2d.Tile;

@:access(h2d.Tile)
class SpriteGroupSprite {
	public var animation:Animation;

	var spriteGroupTileSheet: SpriteGroupTileSheet;
	var spriteGroup: SpriteGroup;

	public var x: Float = 0.;
	public var y: Float = 0.;
	public var scaleX = 1.0;
	public var scaleY = 1.0;
	public var flipX = false;
	public var rotation = 0.0;
	public var alpha = 1.0;

	public var offsetY = 0.;
	public var visible = true;

	var dirty = false;

	/**
	 *  Horizontal origin of sprite, in pixels.
	 *  0 = left, 1 = right
	 */
	public var originX(default, set):Int = 0;

	/**
	 *  Vertical origin of sprite, in pixels.
	 *  0 = top, 1 = bottom
	 */
	public var originY(default, set):Int = 0;

	var tiles:Array<h2d.Tile>;

	public var tile: Tile;
	var lastTile:h2d.Tile;

	public function new(anim, spriteGroupTileSheet:SpriteGroupTileSheet, spriteGroup: SpriteGroup) {
		animation = anim;
		this.spriteGroupTileSheet = spriteGroupTileSheet;
		this.spriteGroup = spriteGroup;
	}

	function refreshTile() {
		var frame = animation.getCurrentFrame();
		var t = spriteGroupTileSheet.tiles[animation.currentFrame];

		if (!dirty && t == lastTile) {
			return;
		}

		dirty = false;
		lastTile = t;

		this.tile = t;
		if (frame != null) {
			t.dx = frame.offsetX - originX;
			t.dy = frame.offsetY - originY;
		}
	}

	public function draw(?s: SpriteGroup) {
		if (tile == null) {
			return;
		}

		if (s != null) {
			s.add(x, y, tile);
		} else {
			this.spriteGroup.addTransform(x, y, scaleX, scaleY, rotation, tile);
		}
	}

	public function update(dt: Float) {
		animation.update(dt);
		refreshTile();
	}

	inline function set_originX(o:Int) {
		if (o != originX)
			dirty = true;
		return originX = o;
	}

	public function remove() {
		this.spriteGroup.removeSprite(this);
	}

	inline function set_originY(o:Int) {
		if (o != originY)
			dirty = true;
		return originY = o;
	}

	public inline function syncWith(parent:Sprite) {
		originX = parent.originX;
		originY = parent.originY;

		if (animation.currentFrame != parent.animation.currentFrame) {
			dirty = true;
		}

		animation.currentFrame = parent.animation.currentFrame;
	}
}