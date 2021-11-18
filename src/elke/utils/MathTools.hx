package elke.utils;


class MathTools {
	static public function clamp(a:Float, min: Float, max: Float):Float {
		if (a < min) {
			return min;
		}
		if (a > max) {
			return max;
		}
		return a;
	}

	static public function angleBetween(radian: Float, toRadian: Float): Float {
		var diff = ( toRadian - radian + Math.PI ) % (Math.PI * 2) - Math.PI;
		diff = diff < -Math.PI ? diff + Math.PI * 2 : diff;
		diff *= 0.5;
		return diff;
	}
}
