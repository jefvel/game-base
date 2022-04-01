package elke.utils;

class AABB {
	public var x(default, set) = 0.;
	public var y(default, set) = 0.;
	public var width(default, set) = 0.;
	public var height(default, set) = 0.;

	var dirty = false;
	public var centerX = 0.;
	public var centerY = 0.;
	public var halfWidth = 0.;
	public var halfHeight = 0.;

	public function new(x = 0., y = 0., w = 1., h = 1.) {
		this.x = x;
		this.y = y;

		this.width = w;
		this.height = h;

		refreshCenter();
	}

	function refreshCenter() {
		halfWidth = width * 0.5;
		halfHeight = height * 0.5;
		centerX = x + halfWidth;
		centerY = y + halfHeight;
		dirty = false;
	}

	public function testRect(x: Float, y: Float, w: Float, h: Float) {
		if (dirty) {
			refreshCenter();
		}

		var hw2 = w * 0.5;
		var hh2 = h * 0.5;
		var cx2 = x + hw2; 
		var cy2 = y + hh2;

		if (Math.abs(centerX - cx2) > halfWidth + hw2) return false;
		if (Math.abs(centerY - cy2) > halfHeight + hh2) return false;

		//if (x > this.x + this.width || x + width < this.x) return false;
		//if (y > this.y + this.height || y + height < this.y) return false;

		return true;
	}

	public function testCircle(x: Float, y: Float, r: Float) {
		return testRect(x - r, y - r, r * 2, r * 2);
	}

	public function toString() {
		return '${x}, ${y} - (${width}/${height})';
	}

	function set_x(x) {
		dirty = true;
		return this.x = x;
	}

	function set_y(x) {
		dirty = true;
		return this.y = x;
	}
	function set_width(x) {
		dirty = true;
		return this.width = x;
	}
	function set_height(x) {
		dirty = true;
		return this.height = x;
	}
}
