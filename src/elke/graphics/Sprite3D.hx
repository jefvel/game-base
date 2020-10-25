package elke.graphics;

import h2d.Tile;
import h3d.mat.Texture;
import h3d.mat.Pass;
import h3d.Matrix;
import h3d.scene.RenderContext;
import h3d.mat.Material;
import h3d.scene.Object;
import h3d.scene.Mesh;

class SpriteShader extends h3d.shader.BaseMesh {
	static var SRC = {
        // Sprite size in world coords
		@param var spriteSize:Vec2;
        // Upper and lower uv coords
		@param var uvs:Vec4;
        // xy = origin, zw = tile offset
		@param var offset:Vec4;
		@param var tileSize:Vec2;
		@param var camUp:Vec3;
		@param var camRight:Vec3;
		@param var axisLock:Vec2;
		@param var rotation:Float;
		@input var spriteInput:{
			var position:Vec3;
			var normal:Vec3;
			var uv:Vec2;
		};
		var localPos:Vec4;
		var calculatedUV:Vec2;
		var axisX:Vec3;
		var axisY:Vec3;
		function rotate2d(angle:Float):Mat2 {
			return mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
		}
		function rotateAxis(axis:Vec3, angle:Float):Mat4 {
			axis = normalize(axis);
			var s = sin(angle);
			var c = cos(angle);
			var oc = 1.0 - c;

			return mat4(vec4(oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s, oc * axis.z * axis.x + axis.y * s, 0.0),
				vec4(oc * axis.x * axis.y + axis.z * s, oc * axis.y * axis.y + c, oc * axis.y * axis.z - axis.x * s, 0.0),
				vec4(oc * axis.z * axis.x - axis.y * s, oc * axis.y * axis.z + axis.x * s, oc * axis.z * axis.z + c, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
		}

		function __init__() {
			// var mv = global.modelView;
			if (false) {
                relativePosition.xz *= tileSize;
                relativePosition.xz += offset.zw;
			} else {
				relativePosition = vec3(0.0, 0.0, 0.0);
				transformedPosition = relativePosition * global.modelView.mat3x4();
				#if hldx
				transformedPosition += mix(vec3(camera.view[0][0], camera.view[1][0], camera.view[2][0]), vec3(1, 0, 0),
					axisLock.x) * (input.position.x * tileSize.x + offset.z);

				transformedPosition += mix(vec3(camera.view[0][1], camera.view[1][1], camera.view[2][1]), vec3(0, 0, 1.0),
					axisLock.y) * (input.position.z * tileSize.y + offset.w);
				#else
				localPos = vec4(0, 0, 0, 0);
				axisX = mix(vec3(camera.view[0][0], camera.view[0][1], camera.view[0][2]), vec3(1, 0, 0), axisLock.x);
				localPos.xyz += axisX * (input.position.x * tileSize.x + offset.z);

				axisY = mix(vec3(camera.view[1][0], camera.view[1][1], camera.view[1][2]), vec3(0, 0, 1), axisLock.y);
				localPos.xyz += axisY * (input.position.z * tileSize.y + offset.w);

				localPos = localPos * rotateAxis(cross(axisX, axisY), rotation);
				#end

				transformedPosition += localPos.xyz;

				projectedPosition = vec4(transformedPosition, 1) * camera.viewProj;
				// projectedPosition.z -= camera.viewProj[2][0];
				transformedNormal = (input.normal * global.modelView.mat3()).normalize();
			}
		}

        function vertex() {
            var uv1 = uvs.xy;
            var uv2 = uvs.zw;
            var d = uv2 - uv1;
			calculatedUV = vec2(spriteInput.uv * d + uv1);

			output.position = projectedPosition * vec4(1, camera.projFlip, 1, 1);
			pixelTransformedPosition = transformedPosition;
		}
	};
}

@:access(h2d.Tile)
class Sprite3D extends Mesh {
	public var animation:Animation;

	public var faceCamX(default, set):Bool = true;
	public var faceCamY(default, set):Bool = true;

	var plane:Plane3D;

	var dirty = false;

	public var flipX(default, set):Bool;
	public var flipY(default, set):Bool;

	public var rotation = 0.0;

	/**
	 *  Horizontal origin of sprite, in pixels.
	 *  0 = left, 1 = right
	 */
	public var originX(default, set):Int;

	/**
	 *  Vertical origin of sprite, in pixels.
	 *  0 = top, 1 = bottom
	 */
	public var originY(default, set):Int;

	var ppu:Float = Const.PPU;

	public var removeAfterFinish = false;

	var onEvent:(String) -> Void;

	var mat:h3d.mat.Material;

	var spriteShader:SpriteShader;

	public function new(?anim:Animation, ?tile:Tile, ?parent:Object) {
		this.animation = anim;

		this.plane = Plane3D.get();

		mat = Material.create(Texture.defaultCubeTexture());
		
		mat.textureShader.killAlpha = true;
		spriteShader = new SpriteShader();
		mat.mainPass.addShader(spriteShader);
		if (animation != null) {
			mat.texture = animation.tileSheet.image.getTexture();
		} else if (tile != null) {
			this.tile = tile;
		}

		super(plane, mat, parent);
	}

	public var tile(get, set):h2d.Tile;

	function get_tile() {
		return lastTile;
	}

	function set_tile(t) {
		refreshTile(t);
		return t;
	}

	var lastTile:h2d.Tile;

	function refreshTile(t:h2d.Tile = null) {
		if (t == null) {
			if (animation != null) {
				t = animation.getCurrentTile();
			} else {
				t = lastTile;
			}
		}

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

		var tex = t.getTexture(); // animation.tileSheet;
		if (tex != mat.texture) {
			mat.texture = tex;
		}

		if (flipX) {
			ox = tex.width - t.width - ox;
			ox -= tex.width - originX;
		} else {
			ox -= originX;
		}

		if (!flipY) {
			oy = tex.height - t.height - oy;
			oy -= tex.height - originY;
		} else {
			oy -= originY;
		}

		var s = spriteShader;
		s.uvs.set(u, v, u2, v2);
		s.offset.set((originX) * ppu, (tex.height - originY) * ppu, // Origin X and Y
			ox * ppu, oy * ppu);

		s.spriteSize.set(tex.width * ppu, tex.height * ppu);
		s.tileSize.set(t.width * ppu, t.height * ppu);
	}

	override private function syncRec(ctx:RenderContext) {
		if (animation != null) {
			animation.update(ctx.elapsedTime);
		}

		if (this.parent == null) {
			return;
		}

		refreshTile();
		super.syncRec(ctx);
	}

	override function sync(ctx:RenderContext) {
		super.sync(ctx);
		if (flipX) {
			spriteShader.rotation = -rotation;
		} else {
			spriteShader.rotation = rotation;
		}
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
	function set_faceCamY(b) {
		if (b) {
			spriteShader.axisLock.x = 0.0;
		} else {
			spriteShader.axisLock.x = 1.0;
		}

		return faceCamY = b;
	}

	function set_faceCamX(b) {
		if (b) {
			spriteShader.axisLock.y = 0.0;
		} else {
			spriteShader.axisLock.y = 1.0;
		}

		return faceCamX = b;
	}
}