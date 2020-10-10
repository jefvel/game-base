package elke.entity;

import elke.entity.BaseEntity;

class Entity2D implements BaseEntity extends h2d.Object {
	public var id:Int;

	public function new(?parent) {
		id = Entities._NEXT_ID++;
		super(parent);
	}

	public function update(dt:Float) {}

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
}
