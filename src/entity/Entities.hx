package entity;

import entity.Entity3D.BaseEntity;

class Entities {
	@:allow(entity.Entity3D, entity.Entity2D)
	static var _NEXT_ID = 0;
	static var instance:Entities;

	public static inline function getInstance() {
		return instance;
	}

	var entities:Array<BaseEntity>;

	public function new() {
		instance = this;
		entities = [];
	}

	function add(e:BaseEntity) {
		entities.push(e);
	}

	function remove(e:BaseEntity) {
		entities.remove(e);
	}

	public function update(dt:Float) {
		for (e in entities) {
			e.update(dt);
		}
	}
}
