package elke.math;

/**
 * Ray circle intersection
 * @param x ray start x
 * @param y ray start y
 * @param toX ray end x
 * @param toY ray end y
 * @param cx circle x
 * @param cy circle y
 * @param r radius
 * @return Float, -1 if no hit, 0-1 if hit
 */
function rayCircleIntersection(x: Float, y: Float, toX: Float, toY: Float, cx: Float, cy: Float, r: Float): Float {
	var dx = x - toX;
	var dy = y - toY; 

	var fx = toX - cx;
	var fy = toY - cy;

	var a = dx * dx + dy * dy;
	var b = 2 * (fx * dx + fy * dy);
	var c = (fx * fx + fy * fy) - r * r;

	var discriminant = b * b - 4 * a * c;
	if (discriminant < 0) {
		return -1.;
	} 

	discriminant = Math.sqrt( discriminant );

	var t2 = (-b + discriminant)/(2*a);
	t2 = 1 - t2;
	if (t2 >= 0 && t2 <= 1.0) {
		return t2;
	}

	return -1.;
}
