package elke.entity;

import h3d.scene.Object;
import h3d.Vector;

class Entity3D implements BaseEntity extends h3d.scene.Object {
	public var id:Int;

	public var maxSpeed = 0.0;

	public var vx = 0.0;
	public var vy = 0.0;
	public var vz = 0.0;

	public var friction = 0.98;
	public var gravitation = -0.06;

	public function new(?parent) {
		id = Entities._NEXT_ID++;
		super(parent);
	}

	override function onAdd() {
		super.onAdd();
		@:privateAccess
		Entities.getInstance().add(this);
	}

	override function onRemove() {
		super.onRemove();
		@:privateAccess
		Entities.getInstance().remove(this);
	}

	public function update(dt:Float) {
		// Clamp max speed
		var v = new Vector(vx, vy, vz);
		if (v.lengthSq() > this.maxSpeed * this.maxSpeed) {
			v.normalize();
			v.scale3(this.maxSpeed);
			this.vx = v.x;
			this.vy = v.y;
			this.vz = v.z;
		}

		this.x += vx;
		this.y += vy;
		this.z += vz;

		this.vx *= friction;
		this.vy *= friction;
		this.vz *= friction;

		vz += gravitation;
	}
}
