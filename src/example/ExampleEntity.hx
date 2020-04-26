package example;

import entity.Entity;

class ExampleEntity extends Entity {
    var sprite : graphics.Sprite3D;
    public function new(?parent) {
        super(parent);

        sprite = hxd.Res.img.test_tilesheet.toSprite3D(this);
        sprite.originX = 16;
        sprite.originY = 16;
        sprite.animation.play("Ok");
    }
}