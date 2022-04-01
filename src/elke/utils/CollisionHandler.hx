package elke.utils;

import h2d.col.Point;

interface CollisionObject {
	var x: Float;
	var y: Float;
	var vx: Float;
	var vy: Float;
	var rotation: Float;
	var radius: Float;
	var mass: Float;
	var uncollidable: Bool;
	var filterGroup: Int;
}

/**
 * resolves collisions between an array of circles
 */
class CollisionHandler {
    public function new() {
    }

	public var useBuckets = true;
	public var bucketSize = 100;
	public var width = 2000.;
	public var height = 2000.;
    public function resolve(objects:Array<CollisionObject>) {
		var buckets = new Map<Int, Array<CollisionObject>>();
		var columns = Std.int(Math.ceil(bucketSize / width));
		var d = new Point();

		inline function doResolve(m: CollisionObject, m2: CollisionObject) {
			d.set(m.x - m2.x, m.y - m2.y);
			var r = m.radius + m2.radius;
			var r2 = r * r;

			var d2 = d.lengthSq();
			if (d2 < r2) {
				d.normalize();
				var dist = Math.sqrt(d2);
				d.scale(r - dist);

				var totalMass = m.mass + m2.mass;
				if (totalMass > 0) {
					var move1 = m.mass / totalMass;
					var move2 = m2.mass / totalMass;

					if (m.mass == 0) {
						move1 = 1;
						move2 = 0;
					}

					if (m2.mass == 0) {
						move1 = 0;
						move2 = 1;
					}

					var vx1 = d.x * move2;
					var vy1 = d.y * move2;

					m.x += vx1;
					m.y += vy1;
					m.vx += vx1 * 0.5;
					m.vy += vy1 * 0.5;

					var vx2 = d.x * move1;
					var vy2 = d.y * move1;

					m2.x -= vx2;
					m2.y -= vy2;
					m2.vx -= vx2 * 0.5;
					m2.vy -= vy2 * 0.5;
				}
			}
		}

		if (useBuckets) {
			for (m in objects) {
				if (m.uncollidable) {
					continue;
				}

				var xmin = Std.int((m.x - m.radius) / bucketSize);
				var xmax = Std.int((m.x + m.radius) / bucketSize) + 1;
				var ymin = Std.int((m.y - m.radius) / bucketSize);
				var ymax = Std.int((m.y + m.radius) / bucketSize) + 1;
				for (x in xmin...xmax) {
					for (y in ymin...ymax) {
						var key = x + y * columns;
						if (!buckets.exists(key)) {
							buckets[key] = [];
						}

						var b = buckets[key];
						for (m2 in b) {
							if (m2 == null) {
								continue;
							}
							if (m2.filterGroup != 0 && m2.filterGroup == m.filterGroup) {
								continue;
							}
							if (m == m2)
								continue;

							doResolve(m, m2);
						}

						b.push(m);
					}
				}
			}
		} else {
			for (m in objects) {
				if (m.uncollidable) {
					continue;
				}

				for (m2 in objects) {
					if (m2 == null) {
						break;
					}

					if (m2.uncollidable) {
						continue;
					}

					if (m2.filterGroup != 0 && m2.filterGroup == m.filterGroup) {
						continue;
					}
					
					if (m == m2) {
						continue;
					}

					doResolve(m, m2);
				}
			}
		}
    }
}