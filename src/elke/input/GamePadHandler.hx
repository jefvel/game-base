package elke.input;

import hxd.Pad;

class GamePadHandler {
	public function new() {
	}

	public function init() {
		#if enableGamepads
		awaitGamepad();
		#end
	}

	public var inFocus = true;

	public var pad: Pad = null;
	public var connected = false;
	function awaitGamepad() {
		Pad.wait(onGamepadConnect);
	}

	public function anyButtonPressed() {
		if (!isActive()) {
			return false;
		}
		for (v in pad.values) {
			if (Math.abs(v) > 0.4) {
				return true;
			}
		}
		return false;
	}

	public function vibrate(duration: Int, strength = 1.0) {
		if (!isActive()) {
			return false;
		}

		pad.rumble(strength, duration / 1000.);

		return true;
	}

	function onGamepadConnect(pad: hxd.Pad) {
		trace("Gamepad connected");
		if (this.pad != null) {
			return;
		}

		this.connected = true;


		this.pad = pad;
		pad.axisDeadZone = 0.2;

		pad.onDisconnect = () -> {
			trace("disconnected");
			this.pad = null;
			this.connected = false;
		}

		awaitGamepad();
	}

	final conf = hxd.Pad.DEFAULT_CONFIG;
	public function isBtnDown(btn) {
		if (!isActive()) {
			return false;
		}

		return pad.isDown(btn);
	}

	public function getStickX() : Float {
		if (!isActive()) {
			return 0;
		}

		return pad.xAxis;
    }

    public function getStickY() : Float {
		if (!isActive()) {
			return 0;
		}

		return pad.yAxis;
    }

	inline function isActive() {
		return pad != null && inFocus;
	}

	final dz = 0.5;
	public function pressingLeft() {
		return isActive() && pad.xAxis < -dz;
	}
	public function pressingRight() {
		return isActive() && pad.xAxis > dz;
	}
	public function pressingUp() {
		return isActive() && pad.yAxis < -dz;
	}
	public function pressingDown() {
		return isActive() && pad.yAxis > dz;
	}
}