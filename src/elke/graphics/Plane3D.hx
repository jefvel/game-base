package elke.graphics;

import h3d.col.Bounds;

class Plane3D extends h3d.prim.Primitive {
	var width:Float = 1.0;
	var height:Float = 1.0;

	public function new(width = 1.0, height = 1.0) {
		this.width = width;
		this.height = height;
	}

	override function triCount() {
		return 2;
	}

	override function vertexCount() {
		return 4;
	}

	override function alloc(engine:h3d.Engine) {
		var v = new hxd.FloatBuffer();
		// Pos
		v.push(-width * 0.);
		v.push(0);
		v.push(-height * 0.);

		// Norm
		v.push(0);
		v.push(1);
		v.push(0);

		// UV
		v.push(0);
		v.push(1);

		// Pos
		v.push(-width * 0.);
		v.push(0);
		v.push(height * 1);
		// Norm
		v.push(0);
		v.push(1);
		v.push(0);
		// UV
		v.push(0);
		v.push(0);

		// Pos
		v.push(width * 1);
		v.push(0);
		v.push(-height * 0.);
		// Norm
		v.push(0);
		v.push(1);
		v.push(0);
		// UV
		v.push(1);
		v.push(1);

		// Pos
		v.push(width * 1);
		v.push(0);
		v.push(height * 1);
		// Norm
		v.push(0);
		v.push(1);
		v.push(0);
		// UV
		v.push(1);
		v.push(0);

		buffer = h3d.Buffer.ofFloats(v, 8, [Quads, RawFormat]);
	}

	override function getBounds():Bounds {
		var b = new h3d.col.Bounds();
		b.addPos(-1, 0, -1);
		b.addPos(1, 0, 1);
		return b;
	}

	public static function get() {
		var engine = h3d.Engine.getCurrent();
		var inst = @:privateAccess engine.resCache.get(Plane3D);
		if (inst == null) {
			inst = new Plane3D();
			@:privateAccess engine.resCache.set(Plane3D, inst);
		}
		return inst;
	}
}