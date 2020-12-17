package elke.graphics;

@:access(h2d.Tile)
class Sprite extends h2d.Bitmap {
	public var animation:Animation;

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

	public function new(anim, ?parent) {
		super(null, parent);
		animation = anim;
	}

	var lastTile:h2d.Tile;

	function refreshTile() {
		var frame = animation.getCurrentFrame();
		var t = frame.tile;

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

	override function sync(ctx:h2d.RenderContext) {
		animation.update(ctx.elapsedTime);

		if (this.parent == null) {
			return;
		}

		refreshTile();
		super.sync(ctx);
	}

	inline function set_originX(o:Int) {
		if (o != originX)
			dirty = true;
		return originX = o;
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