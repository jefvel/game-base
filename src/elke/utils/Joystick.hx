package elke.utils;

import h2d.col.Point;
import elke.T;
import h2d.Graphics;
import elke.entity.Entity2D;

class Joystick extends Entity2D {
	var bg: Graphics;
	var dot: Graphics;
	var r = 54.;
	var maxR = 72;
	#if js
	public var touchId = null;
	#else
	public var touchId = 0;
	#end
	public var active = false;

	public var mx = 0.;
	public var my = 0.;

	public var magnitude = 0.0;

	public function new(?p) {
		super(p);
		bg = new Graphics(this);
		bg.beginFill(0x111111, 0.4);
		bg.drawCircle(0, 0, r);
		dot = new Graphics(this);
		dot.beginFill(0x111111, 0.9);
		dot.drawCircle(0, 0, r * 0.3);
		visible = false;
	}

	public function handleEvent(e: hxd.Event) {
		#if js
		var s2d = getScene();
		var g = s2d.globalToLocal(new Point(e.relX, e.relY));
		g.x /= Game.instance.pixelSize;
		g.y /= Game.instance.pixelSize;

		if (e.kind == EPush) {
			if (g.x < s2d.width * 0.5) {
				if (e.touchId != null && !active) {
					start(g.x, g.y, e.touchId);
					return true;
				}
			}
		}

		if (e.kind == EMove) {
			if (e.touchId != null && e.touchId == touchId) {
				movement(g.x, g.y);
				return true;
			}
		}

		if (e.kind == ERelease || e.kind == EReleaseOutside) {
			if (e.touchId == touchId && active) {
				end();
				return true;
			}
		}

		return false;
		#end
	}

	var disabled = false;
	public function disable() {
		disabled = true;
		active = false;
		visible = false;
		mx = my = magnitude = 0;
	}

	public function start(x, y, touchID) {
		if (disabled) {
			return;
		}

		this.x = x;
		this.y = y;
		this.touchId = touchID;
		mx = my = 0;
		dot.x = dot.y = 0;
		visible = true;
		active = true;
	}

	public function movement(tx: Float, ty: Float) {
		if (disabled) {
			return;
		}

		var dx = tx - x;
		var dy = ty - y;
		var l = Math.sqrt(dx * dx + dy * dy);

		if (l > maxR) {
			var fx = dx / l;
			var fy = dy / l;
			fx *= (maxR - l);
			fy *= (maxR - l);
			x -= fx;
			y -= fy;

			dx = tx - x;
			dy = ty - y;
			l = Math.sqrt(dx * dx + dy * dy);
		}

		if (l > 0) {
			mx = dx / l;
			my = dy / l;

			if (l > r) {
				dx = mx * r;
				dy = my * r;
			}
		} else {
			mx = my = dx = dy = 0;
		}


		magnitude = l / r;

		mx *= l / r;
		my *= l / r;

		if (magnitude < 0.5) {
			mx *= (1 - 2 * (0.5 - magnitude));
			my *= (1 - 2 * (0.5 - magnitude));
		}

		if (magnitude < 0.2) {
			mx = my = 0;
		}

		dot.x = Math.round(dx);
		dot.y = Math.round(dy);
	}

	var dz = 0.5;
	public function goingLeft() {
		return active && mx < -dz;
	}
	public function goingRight() {
		return active && mx > dz;
	}
	public function goingUp() {
		return active && my < -dz;
	}
	public function goingDown() {
		return active && my > dz;
	}

	public function end() {
		visible = false;
		active = false;
		#if js
		touchId = null;
		#else
		touchId = 0;
		#end
	}
}