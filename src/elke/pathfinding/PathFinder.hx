package elke.pathfinding;

import h2d.Graphics;
import elke.utils.CellGraph;
import elke.pathfinding.PathPool;

@:allow(elke.pathfinding.PathFinder)
class PathFindingQuery {
	public var path: Array<GraphNode> = null;
	public var fromX = 0.;
	public var fromY = 0.;
	public var toX = 0.;
	public var toY = 0.;
	public var complete = false;
	public var debounce(default, set) = 0.;

	public var immediate = false;

	var _dbnc = 0.;

	var pathNodes: Array<PathNode> = [];
	var open : Array<PathNode> = [];

	var startNode:GraphNode;
	var endNode: GraphNode;
	var inProgress = false;

	public function new(debounce = 0.) {
		this.debounce = debounce;
		reset();
	}

	function set_debounce(d) {
		_dbnc = d;
		return this.debounce = d;
	}

	public function reset() {
		_dbnc = debounce;
		complete = false;
		inProgress = false;
		open = [];
		pathNodes = [];
		startNode = null;
		endNode = null;
	}
}

class PathFinder {
	var pathPool: PathPool;
	var graph: CellGraph;

	var pathfindingQueries: Array<PathFindingQuery> = [];

	var pathCache: Map<Int, Array<GraphNode>>;
	var debugGraphics: Graphics;

	#if (target.threaded) 
	var processingThread: sys.thread.Thread;
	var running = false;
	var accessMutex: sys.thread.Mutex;
	#end

	var threaded = false;

	public function new(graph: CellGraph, debugGraphics: Graphics) {
		pathPool = new PathPool();
		this.graph = graph;
		this.debugGraphics = debugGraphics;

		pathCache = new Map();
		#if (target.threaded)
		if (threaded) {
			accessMutex = new sys.thread.Mutex();
			processingThread = sys.thread.Thread.create(threadProcess);
			running = true;
		}
		#end
	}

	function getCached(fromCell:GraphNode, toCell: GraphNode) {
		var p = pathCache[toCell.id];
		if (p == null) {
			return null;
		}

		var i = 0;
		for (n in p) {
			if (n.id == fromCell.id) {
				return p.slice(i);
			}
			i++;
		}

		return null;
	}

	#if (target.threaded)
	var lastTime = 0.;
	function threadProcess() {
		while(running) {
			var newTime = haxe.Timer.stamp();
			var dt = newTime - lastTime;
			lastTime = newTime;
			process(dt, 1.0);
			Sys.sleep(1 / 60);
		}
	}
	#end

	var accum = 0.;
	public function process(dt: Float, maxProcessingTime: Float) {
		accum -= dt;
		if (accum > 0) {
			return;
		}

		acquire();

		var stamp = haxe.Timer.stamp();

		var maxTime = maxProcessingTime;//1 / 166.;//Const.TICK_RATE * 0.5;
		final individualTime = maxTime * 0.5;

		var i = 0;
		while (true) {
			var q = pathfindingQueries[i];
			if (q == null) {
				break;
			}

			q._dbnc -= dt;
			if (q._dbnc > 0) {
				i ++;
				continue;
			}


			var time = haxe.Timer.stamp();
			q = processPathQuery(q, individualTime);
			time = haxe.Timer.stamp() - time;
			accum += time;

			if (q.complete) {
				pathfindingQueries.remove(q);
			}

			i++;

			if (haxe.Timer.stamp() - stamp >= maxTime) {
				break;
			}
		}

		release();

	}

	inline function acquire() {

		#if (target.threaded)
		if (threaded) {
			accessMutex.acquire();
		}
		#end
	}

	inline function release() {

		#if (target.threaded)
		if (threaded) {
			accessMutex.release();
		}
		#end
	}

	public function findPathDelayed(x: Float, y: Float, toX: Float, toY: Float, ?existing: PathFindingQuery) : PathFindingQuery {
		acquire();

		if (existing == null) {
			existing = new PathFindingQuery();
		} else {
			pathfindingQueries.remove(existing);
		}

		existing.fromX = x;
		existing.fromY = y;
		existing.toX = toX;
		existing.toY = toY;
		existing.reset();

		pathfindingQueries.push(existing);

		release();

		return existing;
	}

	public function findPath(x: Float, y: Float, toX: Float, toY: Float, ?path: Array<GraphNode>, quick = false) {
		var q = new PathFindingQuery();
		q.fromX = x;
		q.fromY = y;
		q.toX = toX;
		q.toY = toY;
		q.immediate = true;
		return processPathQuery(q);
	}

	public function processPathQuery(q: PathFindingQuery, maxProcessingTime = 1.0): PathFindingQuery {
		var path = [];
		var quick = false;

		var stamp = haxe.Timer.stamp();

		PathNode.nex = 0;

		var pathNodes: Array<PathNode> = q.pathNodes;
		var open : Array<PathNode> = q.open;

		if (q.startNode == null) {
			q.startNode = graph.getClosestCell(q.fromX, q.fromY);
		}
		if (q.endNode == null) {
			q.endNode = graph.getClosestCell(q.toX, q.toY);
		}

		var startNode = q.startNode;
		var endNode = q.endNode;

		if (!q.inProgress) {
			if (startNode == null || endNode == null) {
				q.complete = true;
				q.path = null;
				return q;
			}

			//path.push(startNode);
			if (startNode == endNode) {
				path.push(startNode);
				q.path = path;
				q.complete = true;
				return q;
			}

			var cached = getCached(startNode, endNode);
			if (cached != null) {
				q.path = cached;
				q.complete = true;
				return q;
			}
		}

		inline function H(n: GraphNode) {
			var dx = endNode.centerX - n.centerX;
			var dy = endNode.centerY - n.centerY;
			return Math.abs(dx) + Math.abs(dy);
		}

		inline function G(n: GraphNode, from: PathNode) {
			var cx = q.fromX;
			var cy = q.fromY;
			if (from != null) {
				cx = from.val.centerX;
				cy = from.val.centerY;
			}

			var dx = q.fromX - n.centerX;
			var dy = q.fromY - n.centerY;

			return (Math.abs(dx) + Math.abs(dy)) * 1. + from.G;
			//return (dx * dx + dy * dy);
		}

		inline function getPathNode(n: GraphNode) {
			var res = null;
			for (c in pathNodes) {
				if (c.val == n) {
					res = c;
					break;
				}
			}
			return res;
		}

		inline function getLowestCostNode() {
			return open.shift();
		}

		inline function addToOpenList(n: PathNode, replace = false) {
			if (replace) open.remove(n);
			var inserted = false;
			for (i in 0...open.length) {
				if (n.F < open[i].F) {
					open.insert(i, n);
					inserted = true;
					break;
				}
			}

			if (!inserted) {
				open.push(n);
			}
		}

		var curPathNode: PathNode = null;
		if (!q.inProgress) {
			curPathNode = new PathNode(null, startNode, 0, H(startNode));
			addToOpenList(curPathNode);
			pathNodes.push(curPathNode);
		}

		var dx = 0.;
		var dy = 0.;

		var tries = 0;

		var found = false;

		q.inProgress = true;

		var needsMoreProcessing = false; 
		while(open.length > 0) {
			curPathNode = getLowestCostNode();
			if (curPathNode == null) {
				break;
			}

			if (curPathNode.val == endNode) {
				found = true;
				break;
			}

			for (c in curPathNode.val.neighbors) {
				dx = endNode.centerX - c.centerX;
				dy = endNode.centerY - c.centerY; 
				var o = getPathNode(c);
				if (o == null) {
					var newG = curPathNode.G;
					if (!quick) {
						newG = G(c, curPathNode);
					}

					o = new PathNode(curPathNode, c, newG, H(c));
					o.pathLength = curPathNode.pathLength + 1;
					addToOpenList(o);

					pathNodes.push(o);
				} else {
					if (o.closed) continue;

					var pLen = curPathNode.pathLength;
					var cG = G(c, curPathNode);

					if (cG < o.G) {
						o.G = cG;
						o.parent = curPathNode;
						o.pathLength = pLen;
						addToOpenList(o, true);
					}
				}

				if (o.val == endNode) {
					found = true;
					break;
				}
			}

			curPathNode.closed = true;
			open.remove(curPathNode);

			if (tries > 10 && !q.immediate) {
				if (haxe.Timer.stamp() - stamp >= maxProcessingTime) {
					needsMoreProcessing = true;
					break;
				}
			}

			tries ++;
		}

		if (needsMoreProcessing) {
			return q;
		} else {
			q.complete = true;
		}

		if (curPathNode == null || curPathNode.val != endNode) {
			q.path = null;
			return q;
		}

		while (true) {
			if (curPathNode == null) break;
			path.push(curPathNode.val);
			curPathNode = curPathNode.parent;
			if (curPathNode == null) {
				break;
			}
		};

		path.reverse();

		pathCache[endNode.id] = path;

		q.path = path;

		/*
		debugGraphics.clear();
		for (c in pathNodes) {
			if (c.closed) {
				debugGraphics.lineStyle(1, 0xff0000);
			} else {
				debugGraphics.lineStyle(1, 0x00FF00);
			}
			debugGraphics.drawRect(c.val.centerX - 2, c.val.centerY - 2, 4, 4);
		}
		*/

		return q;
	}
}