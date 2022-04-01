package elke.utils;

class Neighbor {
	public var node: GraphNode;
	public var cost: Float;
}

class GraphNode {
	public var x = 0.;
	public var y = 0.;
	public var width = 0.;
	public var height = 0.;
	public var neighbors: Array<GraphNode>;

	public var centerX = 0.;
	public var centerY = 0.;
	public var halfWidth = 0.;
	public var halfHeight = 0.;

	public var cY = 0;
	public var cX = 0;
	public var cW = 1;
	public var cH = 1;

	public var id = 0;
	static var _next = 0;

	public function new(x = 0., y = 0., w = 0., h = 0.) {
		this.x = x;
		this.y = y;
		this.width = w;
		this.height = h;
		id = _next ++;

		halfWidth = width * 0.5;
		halfHeight = height * 0.5;
		centerX = x + halfWidth;
		centerY = y += halfHeight;

		neighbors = [];
	}

	public function getCenterX() {
		return x + width * 0.5;
	}
	public function getCenterY() {
		return y + height * 0.5;
	}

	public function hasNeighbor(cell: GraphNode) {
		for (c in neighbors) {
			if (c == cell) return true;
		}

		return false;
	}
}

class CellGraph {
	/*
	var intGrid: Map<Int, Int>;
	var tileSize: Int;
	var width: Int;
	var height: Int;
	var filter : Int;
	*/

	var maxCSize = 1;

	var cellPxSize = 32;

	public var cells: Array<GraphNode> = [];
	var bucket:SpatialBuckets<GraphNode>;

	public function new(tileSize = 32) {
		/*
		this.intGrid = intGrid;
		this.width = width;
		this.height = height;
		this.tileSize = tileSize;
		this.filter = filter;
		*/

		bucket = new SpatialBuckets(maxCSize * tileSize, 64 * tileSize, 64 * tileSize);
	}

	var tempAABB = new AABB();
	public function cellAtPos(x: Float, y: Float, radius = 4.) {
		var cs = bucket.getPotentialCollisionsCircle(x, y, radius);

		tempAABB.x = x - radius;
		tempAABB.y = y - radius;
		tempAABB.width = radius * 2;
		tempAABB.height = radius * 2;
		for (g in cs) {
			if (tempAABB.testRect(g.x, g.y, g.width, g.height)) {
				return g;
			}
		}

		return null;
	}

	public function getClosestCell(x: Float, y: Float, maxDistance = 100.) {
		var cs = bucket.getPotentialCollisionsCircle(x, y, maxDistance * 0.5);
		var minLenSq = Math.POSITIVE_INFINITY;
		var dx = 0.;
		var dy = 0.;
		var closest = null;
		for (g in cs) {
			dx = x - g.centerX;
			dy = y - g.centerY;
			var lSq = dx * dx + dy * dy;
			if (lSq < minLenSq) {
				closest = g;
				minLenSq = lSq;
			}
		}

		return closest;
	}

	public function tilemapToGraph(intGrid: Map<Int, Int>, tileSize: Int, width: Int, height: Int, filter = 0) {
		inline function getCoordId(cx,cy) return cx+cy*width;
		inline function isCoordValid(cx,cy) {
			return cx>=0 && cx<width && cy>=0 && cy<height;
		}
		inline function getInt(cx:Int, cy:Int) {
			return !isCoordValid(cx,cy) || !intGrid.exists( getCoordId(cx,cy) ) ? 0 : intGrid.get( getCoordId(cx,cy) );
		}

		var cells: Array<GraphNode> = [];
		var a = new AABB();

		inline function addCell(cx, cy, cw, ch) {
			cells.push(new GraphNode(cx * tileSize, cy * tileSize, cw * tileSize, ch * tileSize));
		}

		a.width = a.height = tileSize - 2;

		for (y in 0...height) {
			for (x in 0...width) {
				if (getInt(x, y) != filter) {
					continue;
				}

				a.x = tileSize * x + 1;
				a.y = tileSize * y + 1;

				var exists = false;
				for (c in cells) {
					if (a.testRect(c.x, c.y, c.width, c.height)) {
						exists = true;
						break;
					}
				}

				if (exists) {
					continue;
				}

				var availableH = 0;
				var availableV = 0;
				
				var broken = false;
				while(!broken && availableH < maxCSize) {
					if (!isCoordValid(x + availableH + 1, y) || getInt(x + availableH + 1, y) != filter) {
						broken = true;
						break;
					}

					availableH ++;
				}

				broken = false;
				while(!broken && availableV < maxCSize) {
					if (!isCoordValid(x, y + availableV) || getInt(x, y + availableV) != filter) {
						broken = true;
						break;
					}

					availableV ++;
				}


				var expandX = true;//availableV > availableH;
				// Expand square horizontally
				if (expandX) {
					availableH = 0;
					broken = false;
					while (!broken && availableH < maxCSize) {
						var nx = x + availableH + 1;
						for (ny in y...(y + availableV)) {

							a.x = nx * tileSize + 1;
							a.y = ny * tileSize + 1;
							for (c in cells) {
								if (a.testRect(c.x, c.y, c.width, c.height)) {
									broken = true;
									break;
								}
							}

							if (broken) break;

							if (!isCoordValid(nx, ny) || getInt(nx, ny) != filter) {
								broken = true;
								break;
							}
						}

						if (!broken) {
							availableH ++;
						}
					}

					//availableH += 1;

				} else { // Expand vertically
					availableV = 0;
					broken = false;
					while (!broken) {
						var ny = y + availableV + 1;
						for (nx in x...(x + availableH)) {
							a.x = nx * tileSize + 1;
							a.y = ny * tileSize + 1;
							for (c in cells) {
								if (a.testRect(c.x, c.y, c.width, c.height)) {
									broken = true;
									break;
								}
							}

							if (broken) break;

							if (!isCoordValid(nx, ny) || getInt(nx, ny) != filter) {
								broken = true;
								break;
							}
						}

						if (!broken) {
							availableV ++;
						}
					}

					availableV += 1;
				}

				if (availableV == 0) availableV = 1;
				if (availableH == 0) availableH = 1;

				addCell(x, y, availableH, availableV);
			}
		}
		
		this.cells = cells;
		
		connectCells(cells, tileSize);

		for (c in cells) {
			bucket.add(c, c.x, c.y, c.width, c.height);
		}

		return cells;
	}

	function connectCells(cells: Array<GraphNode>, tileSize) {
		var a = new AABB();

		for (c in cells) {
			a.x = c.x;
			a.y = c.y;
			a.width = c.width;
			a.height = c.height;

			for (c2 in cells) {
				if (c == c2) continue;
				if (c2.hasNeighbor(c)) {
					continue;
				}

				// Remove diagonal connections
				if (Math.abs(Math.abs(c.centerX - c2.centerX) - Math.abs(c.centerY - c2.centerY)) < tileSize) {
					continue;
				}

				if (a.testRect(c2.x, c2.y, c2.width, c2.height)) {
					c.neighbors.push(c2);
					c2.neighbors.push(c);
				}
			}
		}
	}
}