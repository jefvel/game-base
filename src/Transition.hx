import h3d.pass.ScreenFx;
import h2d.filter.Filter;
import h2d.filter.Mask;
import h2d.Interactive;
import h2d.col.Point;
import h2d.Graphics;
import h2d.RenderContext;
import h2d.Bitmap;
import h2d.Tile;
import h2d.Object;
import hxd.Math;

class DissolveShader extends h3d.shader.ScreenShader {
	static var SRC = {
		@param var t:Float;
		@param var screenSize:Vec2;
		function fragment() {
			var uv = (input.uv - 0.5) * 2.0;

			var d = length(vec2(1.0, (screenSize.y / screenSize.x)));
			var p = length(vec2(uv.x, uv.y * (screenSize.y / screenSize.x)));

			var sign = clamp((2 * floor(t)) - 1., -1, 1);
			var mult = (1.0 - floor(t));

			var tMod = mod(t, 1);
			tMod -= 0.01;

			var p2 = tMod * d;

			var l = mult + sign * clamp((p - p2) * 99.9, 0, 1);

			var c = vec3(0.019, 0.09, 0.16);
			c *= l;

			output.color = vec4(c, l);
		}
	};
}

class DissolveFx extends ScreenFx<DissolveShader> {
	public function new() {
		super(new DissolveShader());
	}
}

class TransitionFilter extends Filter {
	public var progress:Float;

	var pass = new DissolveFx();

	public function new() {
		super();
	}

	override function sync(ctx, s) {
		super.sync(ctx, s);
		pass.shader.screenSize.set(ctx.scene.width, ctx.scene.height);
		pass.shader.t = progress;
	}

	override function draw(ctx:RenderContext, t:h2d.Tile) {
		pass.render();
		return t;
	}
}

class Transition extends Interactive {
	var circGraphics:Bitmap;
	var f:TransitionFilter;

	public function new(?parent) {
		super(1, 1, parent);
		circGraphics = new Bitmap(Tile.fromColor(0), this);
		f = new TransitionFilter();
		circGraphics.filter = f;
		cursor = Default;
	}

	var scalingIn = false;
	var scalingOut = false;

	override function draw(ctx:RenderContext) {
		super.draw(ctx);
		parent.addChild(this);
	}

	var inTime = .3;
	var outTime = .3;

	var t = 0.0;

	override function sync(ctx:RenderContext) {
		super.sync(ctx);
		var s = Game.getInstance().s2d;
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

		eased = T.smootherStepInOut(Math.min(1, Math.max(0, t)));
		if (scalingOut) {
			eased = 1 + (1 - eased);
		}

		// var steps = 37;
		// eased = Math.round(T.clamp(eased, 0, 1) * steps) / steps;

		circGraphics.width = width;
		circGraphics.height = height;
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

	public static function to(onFinish:Void->Void) {
		var t = new Transition(Game.getInstance().s2d);
		t.show(onFinish);
		return t;
	}
}
