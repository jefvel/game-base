package graphics;

@:access(h2d.Tile)
class Sprite extends h2d.Bitmap {

    public var animation : Animation;

    var dirty = false;

    public var flipX (default, set) : Bool;
    public var flipY (default, set) : Bool;

    /**
     *  Horizontal origin of sprite, in pixels.
     *  0 = left, 1 = right
     */
    public var originX (default, set) : Int;
    /**
     *  Vertical origin of sprite, in pixels. 
     *  0 = top, 1 = bottom 
     */
    public var originY (default, set) : Int;
    

    var pixelateShader : hxsl.Shader;

    var tiles : Array<h2d.Tile>;

    public function new(tileSheet : TileSheetData, ?parent) {
        super(null, parent);
        animation = new Animation(tileSheet);
    }

    var lastTile : h2d.Tile;
    function refreshTile() {
        var t = animation.getCurrentTile();

        if (!dirty && t == lastTile) {
            return;
        }

        dirty = false;
        lastTile = t;

        this.tile = t;
    }

    override function sync(ctx:h2d.RenderContext) {
        animation.update(ctx.elapsedTime);

        if (this.parent == null) {
            return;
        }

        refreshTile();
        super.sync(ctx);
    }
    
    inline function set_flipX(f : Bool) {
        if (f != flipX) dirty = true;
        return flipX = f;
    }

    inline function set_flipY(f : Bool) {
        if (f != flipY) dirty = true;
        return flipY = f;
    }

    inline function set_originX(o : Int) {
        if (o != originX) dirty = true;
        return originX = o;
    }

    inline function set_originY(o : Int) {
        if (o != originY) dirty = true;
        return originY = o;
    }

    public inline function syncWith(parent : Sprite) {
        originX = parent.originX;
        originY = parent.originY;
        flipX = parent.flipX;

        if (animation.currentFrame != parent.animation.currentFrame) {
            dirty = true;
        }

        animation.currentFrame = parent.animation.currentFrame;
    }
}