package elke.utils;

class ArrayTools {
	static public function randomElement<T>(a:Array<T>):T {
		if (a.length == 0) {
			return null;
		}
		return a[Std.int(Math.random() * a.length)];
	}
}
