package entities;

import elke.entity.Entity2D;

class ExampleEntity extends Entity2D {
	var sprite:elke.graphics.Sprite;

	public function new(?parent) {
		super(parent);

		sprite = hxd.Res.img.boom_tilesheet.toSprite2D(this);
		sprite.originX = 16;
		sprite.originY = 16;
		// sprite.scaleX = -1;
		sprite.animation.play("Explosion", true, false, Math.random());
	}
}