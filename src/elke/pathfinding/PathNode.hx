package elke.pathfinding;

import pool.Poolable;
import elke.utils.CellGraph.GraphNode;

class PathNode implements Poolable {
	public var parent: PathNode = null;
	public var val: GraphNode = null;
	public var G: Float = 0.;
	public var H: Float = 0.;
	public var F(get, null): Float;

	public var closed = false;
	public var index = 0;
	public static var nex = 0;
	public var pathLength = 0;

	public function new(p: PathNode, v: GraphNode, g: Float, h:Float) {
		parent = p;
		val = v;

		G = g;
		H = h;
		index = nex++;
	}

	function get_F() {
		return G + H;
	}
}
