package elke.utils;

class SpatialBuckets<T> {
	public var bucketSize(default, null) = 100;
	public var width = 2000.;
	public var height = 2000.;
	
	var columns = 0;

	var buckets = new Map<Int, Array<T>>();

	public function new(bucketSize = 100, width = 2000., height = 2000.) {
		this.bucketSize = bucketSize;
		resize(width, height);
	}

	function resize(width, height) {
		var oldColumns = this.columns;

		this.width = width;
		this.height = height;

		columns = Std.int(Math.ceil(bucketSize / width));

		var oldBuckets = buckets;
		buckets = new Map<Int, Array<T>>();

		for (key => bucket in oldBuckets) {
			var row = Std.int(key / oldColumns);
			var col = key - row * columns;

			var newKey = row * columns + col;
			for (object in bucket) {
				addToBucket(newKey, object);
			}
		}
	}

	inline function addToBucket(key: Int, object: T) {
		if (!buckets.exists(key)) {
			buckets[key] = [];
		}

		var b = buckets[key];
		if (!b.contains(object)) {
			b.push(object);
		}
	}

	public function add(object: T, x: Float, y: Float, w: Float, h: Float) {
		var xmin = Std.int(x / bucketSize);
		var xmax = Std.int((x + w) / bucketSize) + 1;
		var ymin = Std.int(y / bucketSize);
		var ymax = Std.int((y + h) / bucketSize) + 1;
		for (x in xmin...xmax) {
			for (y in ymin...ymax) {
				var key = x + y * columns;
				addToBucket(key, object);
			}
		}

		return null;
	}

	public function getPotentialCollisions(x:Float, y: Float, w: Float, h: Float) {
		var res: Array<T> = null;

		var xmin = Std.int(x / bucketSize);
		var xmax = Std.int((x + w) / bucketSize) + 1;
		var ymin = Std.int(y / bucketSize);
		var ymax = Std.int((y + h) / bucketSize) + 1;

		for (x in xmin...xmax) {
			for (y in ymin...ymax) {
				var key = x + y * columns;
				var b = buckets[key];
				if (b == null) {
					continue;
				}

				for (o in b) {
					if (res == null) res = [];
					if (!res.contains(o)) {
						res.push(o);
					}
				}
			}
		}

		return res;
	}

	public function getPotentialCollisionsCircle(x: Float, y: Float, r: Float) {
		return getPotentialCollisions(x - r, y - r, r * 2, r * 2);
	}

	public function addSphere(object: T, x: Float, y: Float, r: Float) {
		return add(object, x - r, y - r, r * 2, r * 2);
	}

	public function clear() {
		buckets.clear();
	}
}