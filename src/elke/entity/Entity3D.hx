package elke.entity;

import h3d.scene.Object;
import h3d.Vector;

class Entity3D implements BaseEntity extends h3d.scene.Object {
	public var id:Int;

	public var maxSpeed = 0.0;

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
	}
}
