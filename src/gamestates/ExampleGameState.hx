package gamestates;

import h3d.col.Plane;
import entities.Human;
import h3d.prim.ModelCache;
import entities.ExampleEntity;
import h2d.Object;
import h3d.scene.World;
import elke.process.Timeout;
import hxd.snd.effect.ReverbPreset;
import elke.graphics.Transition;
import h2d.Text;
import hxd.Event;

class ExampleGameState extends elke.gamestate.GameState {
	var coolEntity:Array<entities.ExampleEntity>;
	var container:Object;

	public function new() {}
	var e:ExampleEntity;

	var text:Text;

	var cache:ModelCache;

	override function onEnter() {
		super.onEnter();

		container = new Object(game.s2d);

		game.s3d.lightSystem.ambientLight.set(1, 1, 1);

		coolEntity = [];
		for (_ in 0...1) {
			e = new entities.ExampleEntity(container);
			var s = 10;
			e.x = e.y = 32;
			// e.x = Math.random() * s * 2 - s;
			// e.z = Math.random() * s * 2 - s;
			// e.y = Math.random() * s * 2 - s;
		}

		var t = new Text(hxd.Res.fonts.futilepro_medium_12.toFont(), game.s2d);
		t.text = "Hello";
		t.textAlign = Center;
		t.textColor = 0x000000;
		t.x = t.y = 32;
		t.dropShadow = {
			dx: 0,
			dy: 1,
			color: 0x333333,
			alpha: 0.2,
		}

		text = t;
		text.scale(2);

		var p = ReverbPreset.CITY_ABANDONED;
		game.sound.sfxChannel.addEffect(new hxd.snd.effect.Reverb(p));
		cache = new ModelCache();

		var p = cache.loadModel(hxd.Res.models.plane);
		game.s3d.addChild(p);

		characters = [];
		var s = 0;
		var c = 1;
		for (i in 0...c) {
			human = new Human(game.s3d);
			human.x = Math.random() * s * 2 - s;
			human.y = Math.random() * s * 2 - s;
			characters.push(human);
		}

	}

	var characters:Array<Human>;

	var human:Human;

	override function onEvent(e:Event) {
		if (e.kind == EPush) {
			if (e.button == 0) {
				characters[0].shoot();
			}
			return;
			game.sound.playWobble(hxd.Res.sound.click, .1);
			Transition.to(() -> {}, 0.4, 0.4);
		}
	}

	var time = 0.0;

	override function update(dt:Float) {
		super.update(dt);
		time += dt;
		var tt = time * 0.0;
		var dist = 9;
		game.s3d.camera.pos.set(0 + Math.cos(tt) * dist, Math.sin(tt) * dist, 3 + Math.cos(time * 0.8) * 0.1);
		text.x = Math.round(game.s2d.width * 0.2);
		text.y = 32 + Math.round(Math.sin(time * 4.3) * 2);
		text.rotation = Math.cos(time * 1.6) * 0.1;
		var r = game.s3d.camera.rayFromScreen(game.mouseX * 2, game.mouseY * 2);
		var p = r.intersect(Plane.Z(0));
		for (human in characters) {
			if (!human.aiming) {
				continue;
			}
			var dx = human.x - p.x; // (game.s2d.width - game.mouseX) * 0.5;
			var dy = human.y - p.y; // (game.s2d.height - game.mouseY) * 0.5;
			human.rotation = Math.atan2(dy, dx);
		}
	}

	override function onLeave() {
		super.onLeave();
	}
}