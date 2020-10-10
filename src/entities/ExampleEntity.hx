package entities;

import elke.entity.Entity3D;

class ExampleEntity extends Entity3D {
	var sprite:elke.graphics.Sprite3D;

	public function new(?parent) {
		super(parent);

		sprite = hxd.Res.img.boom_tilesheet.toSprite3D(this);
		sprite.originX = 16;
		sprite.originY = 16;
		sprite.animation.play("Explosion", true, false, Math.random());
	}
}