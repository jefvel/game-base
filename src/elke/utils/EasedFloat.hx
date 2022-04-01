package elke.utils;

class EasedFloat {
	public var value(get, set): Float;

	public var easeTime = 0.3;
	public var easeFunction: (Float) -> Float = T.expoOut;

	var target = 0.;
	var from = 0.;

	var changeTime = 0.;

	var internalValue = 0.;

	public function new(initial: Float = 0., easeTime = 0.3) {
		this.easeTime = easeTime;
		setImmediate(initial);
	}

	public function setImmediate(value: Float) {
		target = from = value;
		changeTime = easeTime;
	}

	function set_value(v) {
		if (v == target) {
			return v;
		}

		from = target;
		target = v;

		changeTime = hxd.Timer.lastTimeStamp;

		return v;
	}

	function get_value() {
		var t = hxd.Timer.lastTimeStamp - changeTime;

		if (t > easeTime) {
			return target;
		}

		var r = Math.min(1, t / easeTime);
		var p = easeFunction != null ? easeFunction(r) : r;
		return from + p * (target - from);
	}
}