package elke.graphics;

import h3d.mat.Pass;
import h3d.Matrix;
import h3d.scene.RenderContext;
import h3d.mat.Material;
import h3d.scene.Object;
import h3d.scene.Mesh;

class SpriteShader extends hxsl.Shader {
	static var SRC = {
		// Sprite size in world coords
		@param var spriteSize:Vec2;
		// Upper and lower uv coords
		@param var uvs:Vec4;
		// xy = origin, zw = tile offset
		@param var offset:Vec4;
		@param var tileSize:Vec2;
		@input var input:{
			var position:Vec3;
			var normal:Vec3;
			var uv:Vec2;
		};
		var relativePosition:Vec3;
		var transformedPosition:Vec3;
		var calculatedUV:Vec2;
		var pixelColor:Vec4;
		function __init__() {
			relativePosition.xz *= tileSize;
			relativePosition.xz += offset.zw;
		}
		function vertex() {
			var uv1 = uvs.xy;
			var uv2 = uvs.zw;
			var d = uv2 - uv1;
			calculatedUV = vec2(input.uv * d + uv1);
		}
		function fragment() {
			// pixelColor.rg = calculatedUV;
		}
	};
}

@:access(h2d.Tile)
class Sprite3D extends Mesh {
	public var animation:Animation;

	public var faceCamera:Bool;

	/**
		If true, will track camera on Z axis, otherwise only X and Y coordinates will be adjusted, and sprite will look forward at all times. (default: true)
	**/
	public var faceZAxis:Bool;

	var plane:Plane3D;

	var dirty = false;

	public var flipX(default, set):Bool = false;
	public var flipY(default, set):Bool = false;

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

	var ppu:Float = Const.PPU;

	public var removeAfterFinish = false;

	var onEvent:(String) -> Void;

	var mat:h3d.mat.Material;

	public function new(anim:Animation, ?parent:Object) {
		this.animation = anim;

		this.faceCamera = false;
		this.faceZAxis = true;
		this.plane = Plane3D.get();

		mat = Material.create(anim.tileSheet.image.getTexture());
		mat.textureShader.killAlpha = true;
		mat.mainPass.addShader(new SpriteShader());
		super(plane, mat, parent);
	}

	var lastTile:h2d.Tile;

	function refreshTile() {
		var t = animation.getCurrentTile();

		if (!dirty && t == lastTile) {
			return;
		}

		dirty = false;
		lastTile = t;

		var u = !flipX ? t.u : t.u2;
		var u2 = !flipX ? t.u2 : t.u;
		var v = !flipY ? t.v : t.v2;
		var v2 = !flipY ? t.v2 : t.v;

		var ox = t.dx;
		var oy = t.dy;

		var tileSheet = animation.tileSheet;

		if (flipX) {
			ox = tileSheet.width - t.width - ox;
			ox -= tileSheet.width - originX;
		} else {
			ox -= originX;
		}

		if (!flipY) {
			oy = tileSheet.height - t.height - oy;
			oy -= tileSheet.height - originY;
		} else {
			oy -= originY;
		}

		var s = mat.mainPass.getShader(SpriteShader);
		s.uvs.set(u, v, u2, v2);
		s.offset.set((originX) * ppu, (tileSheet.height - originY) * ppu, // Origin X and Y
			ox * ppu, oy * ppu);

		s.spriteSize.set(tileSheet.width * ppu, tileSheet.height * ppu);
		s.tileSize.set(t.width * ppu, t.height * ppu);

		material.texture = t.getTexture();
	}

	override private function syncRec(ctx:RenderContext) {
		if (animation != null) {
			animation.update(ctx.elapsedTime);
		}

		if (this.parent == null) {
			return;
		}

		refreshTile();
		if (faceCamera) {
			var up = ctx.scene.camera.up;
			var vec = ctx.scene.camera.pos.sub(ctx.scene.camera.target);
			if (!faceZAxis)
				vec.z = 0;
			var oldX = qRot.x;
			var oldY = qRot.y;
			var oldZ = qRot.z;
			var oldW = qRot.w;
			qRot.initRotateMatrix(Matrix.lookAtX(vec, up));
			if (oldX != qRot.x || oldY != qRot.y || oldZ != qRot.z || oldW != qRot.w)
				this.posChanged = true;
		}
		super.syncRec(ctx);
	}

	inline function set_flipX(f:Bool) {
		if (f != flipX)
			dirty = true;
		return flipX = f;
	}

	inline function set_flipY(f:Bool) {
		if (f != flipY)
			dirty = true;
		return flipY = f;
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

	public inline function syncWith(parent:Sprite3D) {
		originX = parent.originX;
		originY = parent.originY;
		flipX = parent.flipX;

		if (animation.currentFrame != parent.animation.currentFrame) {
			dirty = true;
		}

		animation.currentFrame = parent.animation.currentFrame;
	}
}