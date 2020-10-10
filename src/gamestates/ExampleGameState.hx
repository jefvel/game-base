package gamestates;

import h3d.scene.Object;
import elke.process.Timeout;
import hxd.snd.effect.ReverbPreset;
import elke.graphics.Transition;
import h2d.Text;
import hxd.Event;

class ExampleGameState extends elke.gamestate.GameState {
	var coolEntity:Array<entities.ExampleEntity>;
	var container:Object;

	public function new() {}

	override function onEnter() {
		super.onEnter();
		game.pixelSize = 2;
		game.engine.backgroundColor = 0xFFFFFF;

		container = new Object(game.s3d);

		game.s3d.lightSystem.ambientLight.set(1, 1, 1);

		coolEntity = [];
		for (_ in 0...10000) {
			var e = new entities.ExampleEntity(container);
			var s = 10;
			e.x = Math.random() * s * 2 - s;
			e.z = Math.random() * s * 2 - s;
			e.y = Math.random() * s * 2 - s;
		}

		var t = new Text(hxd.Res.fonts.futilepro_medium_12.toFont(), game.s2d);
		t.text = "Hello";
		t.textColor = 0x000000;
		t.x = t.y = 32;
		t.dropShadow = {
			dx: 0,
			dy: 1,
			color: 0x333333,
			alpha: 0.2,
		}

		Transition.to(() -> {}, 0, 0.3);
		var p = ReverbPreset.CITY_ABANDONED;
		game.sound.sfxChannel.addEffect(new hxd.snd.effect.Reverb(p));
		new Timeout(5.0, () -> {
			Transition.to(() -> {});
		});
	}

	override function onEvent(e:Event) {
		if (e.kind == EPush) {
			game.sound.playWobble(hxd.Res.sound.click, .1);
		}
	}

	var time = 0.0;

	override function update(dt:Float) {
		super.update(dt);
		time += dt;
		game.s3d.camera.pos.set(0 + Math.sin(time * 0.5), 10.0 + Math.sin(time * 0.8) * 0.4, 2.0);
	}

	override function onLeave() {
		super.onLeave();
	}
}