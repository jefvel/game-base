package gamestates;

import entities.ExampleEntity;
import h2d.Object;
import elke.graphics.Transition;
import h2d.Text;
import hxd.Event;

class PlayState extends elke.gamestate.GameState {
	var coolEntity:Array<entities.ExampleEntity>;
	var container:Object;

	public function new() {}

	var e:ExampleEntity;

	var text:Text;

	var uiContainer:Object;

	override function onEnter() {
		super.onEnter();
		container = new Object(game.s2d);
		uiContainer = new Object(game.s2d);

		var fontSize = 128;
		var t = new Text(hxd.Res.fonts.futilepro_medium_12.toFont(), uiContainer);
		t.textColor = 0xFFFFFF;
		t.text = "Hello World";
		t.textAlign = Center;
		game.s2d.filter.useScreenResolution = true;

		var o = new ExampleEntity(game.s2d);
		o.x = o.y = 100;

		text = t;
	}

	override function onEvent(e:Event) {
		if (e.kind == EPush) {
			Transition.to(() -> {}, 0.8, 0.8);
		}
	}

	var time = 0.0;

	override function tick(dt:Float) {
		time += dt;

		var s = text.getScene();
		text.x = s.width >> 1;
		text.y = s.height * 0.5 + Math.sin(time) * 15 - text.textHeight;
	}

	override function onLeave() {
		super.onLeave();
		container.remove();
		uiContainer.remove();
	}
}
