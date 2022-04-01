package elke.pathfinding;

import haxe.ds.Vector;
import pool.Poolable;
import h2d.col.Point;


class Path implements Poolable {
	final maxLength = 128;
	public var points : Vector<Point>;
	public var index: Int;
	public var length = 0;

	var _nextEmptyIndex = 0;

	@:allow(pool.Pool)
	@:allow(elke.pathfinding.PathPool)
	private function new() {
		this.index = 0;
		this.points = new Vector<Point>(maxLength);
	}

	public function push(x: Float, y: Float) {
		if (points[_nextEmptyIndex] == null) {
			points[_nextEmptyIndex] = new Point();
		}

		points[_nextEmptyIndex].set(x, y);
		_nextEmptyIndex ++;
	}

	public function pop() {
		if (_nextEmptyIndex <= 0) {
			return null;
		}

		_nextEmptyIndex --;
		if (index >= _nextEmptyIndex) {
			index = _nextEmptyIndex - 1;
		}

		return points[_nextEmptyIndex];
	}

	public function reset() {
		length = 0;
		index = 0;
	}
}
