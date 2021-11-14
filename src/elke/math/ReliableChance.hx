package elke.math;

/**
 * A more reliable percentage chance
 * it feels more fair than just trying for Math.random, 
 * it guarantees to succeed at least the amount of times for the percentage assigned.
 * example: percentage = 0.01, guarantees a success every 100 times
 */
class ReliableChance {
	public var percentage(default, set) = 0.;
	var tries = 0;
	var successEvery = 0;

	public function new(percentage = 0.) {
		this.percentage = percentage;
	}

	public function tryRoll() {
		if (percentage == 0 || successEvery == 0) {
			return false;
		}

		tries ++;

		if (tries >= successEvery) {
			tries = 0;
			return true;
		}

		return Math.random() < percentage;
	}

	function set_percentage(p: Float) {
		if (p == 0) {
			successEvery = 0;
		} else {
			successEvery = Std.int(1. / p);
		}

		return this.percentage = p;
	}
}