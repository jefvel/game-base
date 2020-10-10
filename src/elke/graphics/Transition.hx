package elke.graphics;

import h3d.pass.ScreenFx;
import h2d.filter.Filter;
import h2d.Interactive;
import h2d.RenderContext;
import h2d.Bitmap;
import h2d.Tile;
import hxd.Math;

class WipeShader extends h3d.shader.ScreenShader {
	static var SRC = {
		/**
		 * t goes from 0-1 (fading in) to 1-2 (fading out)
		 */
		@param var t:Float;
		@param var screenSize:Vec2;
		@param var wipeColor:Vec3;
		function fragment() {
			var c = vec4(wipeColor, 0.0);
			var a = 1.0 - abs(t - 1.0);
			c.a = a;
			output.color = c;
		}
	};
}

class CircleWipeShader extends WipeShader {
	static var SRC = {
		function fragment() {
			var uv = (input.uv - 0.5) * 2.0;

			var d = length(vec2(1.0, (screenSize.y / screenSize.x)));
			var p = length(vec2(uv.x, uv.y * (screenSize.y / screenSize.x)));

			var sign = clamp((2 * floor(t)) - 1., -1, 1);
			var mult = (1.0 - floor(t));

			var tMod = mod(t, 1);
			tMod -= 0.01;

			var p2 = tMod * d;
			p2 *= 1.02;

			var l = mult + sign * clamp((p - p2) * 129.9, 0, 1);

			var c = wipeColor;
			c *= l;

			output.color = vec4(c, l);
		}
	};
}

class SideWipeShader extends WipeShader {
	static var SRC = {
		function fragment() {
			var uv = (input.uv - 0.5) * 2.0;

			var d = length(vec2(1.0, (screenSize.y / screenSize.x)));

			var sign = clamp((2 * floor(t)) - 1., -1, 1);
			var mult = (1.0 - floor(t));

			var tMod = mod(t, 1);
			tMod -= 0.01;

			var p2 = tMod * d;
			p2 *= 1.02;

			var l = mult + sign * clamp(((input.uv.x + input.uv.y * 0.1) - tMod * 1.2) * 229.9, 0, 1);

			var c = wipeColor;
			c *= l;

			output.color = vec4(c, l);
		}
	};
}

class TransitionFilter extends Filter {
	/**
	 * Progress goes from 0-1 (fading in) to 1-2 (fading out)
	 */
	public var progress:Float;

	var pass:ScreenFx<WipeShader>;

	public function new() {
		super();
		pass = new ScreenFx<WipeShader>(new WipeShader());
	}

	override function draw(ctx:RenderContext, t:h2d.Tile) {
		pass.shader.screenSize.set(ctx.scene.width, ctx.scene.height);
		pass.shader.t = progress;
		pass.render();
		return t;
	}
}

class Transition extends Interactive {
	var graphics:Bitmap;
	var f:TransitionFilter;

	var alphaFade = false;

	function new(?parent) {
		super(1, 1, parent);
		graphics = new Bitmap(Tile.fromColor(0), this);
		if (!alphaFade) {
			f = new TransitionFilter();
			graphics.filter = f;
		}

		cursor = Default;
	}

	var scalingIn = false;
	var scalingOut = false;

	override function draw(ctx:RenderContext) {
		super.draw(ctx);
		parent.addChild(this);
	}

	public var inTime = .5;
	public var outTime = .6;

	var t = 0.0;

	override function sync(ctx:RenderContext) {
		super.sync(ctx);

		var s = Game.instance.s2d;
		width = s.width;
		height = s.height;

		var eased = 0.0;

		if (scalingIn) {
			t += ctx.elapsedTime / inTime;
			if (t >= 1) {
				scalingIn = false;
				var finish = onFinish;
				onFinish = null;
				if (finish != null) {
					finish();
				}
				if (auto) {
					t = 2.3;
					scalingOut = true;
				}
			}
		} else if (scalingOut) {
			t -= ctx.elapsedTime / outTime;
			if (t <= 0) {
				scalingOut = false;
				remove();
				if (onFinish != null) {
					onFinish();
				}
			}
		}

		eased = elke.T.smootherStepInOut(Math.min(1, Math.max(0, t)));
		if (scalingOut) {
			if (alphaFade) {
				eased = (eased);
			} else {
				eased = 1 + (1 - eased);
			}
		}

		graphics.width = width;
		graphics.height = height;

		f.progress = eased;
	}

	var onFinish:Void->Void;
	var auto = true;

	public function show(?onFinish:Void->Void, auto = true) {
		scalingIn = true;
		this.auto = auto;
		this.onFinish = onFinish;
	}

	public function hide(?onFinish:Void->Void) {
		this.onFinish = onFinish;
		scalingOut = true;
	}

	public static function to(onFinish:Void->Void, inTime = 0.5, outTime = 0.6) {
		var t = new Transition(Game.instance.s2d);
		t.inTime = inTime;
		t.outTime = outTime;
		t.show(onFinish);
		return t;
	}
}
