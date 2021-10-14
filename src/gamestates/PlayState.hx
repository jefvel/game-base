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

	var sdfText : Text;

	var uiContainer: Object;

	override function onEnter() {
		super.onEnter();
		container = new Object(game.s2d);
		uiContainer = new Object(game.uiScene);

		var fontSize = 128;
		var t = new Text(hxd.Res.fonts.static_regular.toSdfFont(fontSize, MultiChannel), uiContainer);
		t.textColor = 0xFFFFFF;
		t.text = "Hello World";
		t.textAlign = Center;

		sdfText = t;
	}

	override function onEvent(e:Event) {
		if (e.kind == EPush) {
			// game.sound.playWobble(hxd.Res.sound.click, .1);
			var t = Transition.to(() -> {}, 0.8, 0.8);
			var s = new SideWipeShader();
			s.wipeColor.set(0.2, 0.2, 0.2, 1);
			t.f.setWipeShader(s);
		}
	}

	var time = 0.0;

	override function update(dt:Float) {
		super.update(dt);
		time += dt;

		var s = sdfText.getScene();
		sdfText.x = s.width >> 1;
		sdfText.y = s.height * 0.5 + Math.sin(time) * 15 - sdfText.textHeight;
	}

	override function onLeave() {
		super.onLeave();
		container.remove();
		uiContainer.remove();
	}
}