import hxd.Save;

/**
 * you can fill this with whatever data needs saving,
 * then you can just use GameSaveData.getCurrent() to get an instance of save data
 * and save it using save()
 */
class GameSaveData {

	public function new() {}

	#if debug
	static inline final hash = false;
	static inline final saveName = '${Const.SAVE_NAMESPACE}_debug';
	#else
	static inline final hash = true;
	static inline final saveName = Const.SAVE_NAMESPACE;
	#end

	public function save() {
		try {
			Save.save(current, saveName, hash);
		} catch (e) {
			trace(e);
		}
	}

	public static function load() {
		current = Save.load(null, saveName, hash);

		if (current == null) {
			current = new GameSaveData();
		}
	}

	static var current: GameSaveData;
	public static function reset() {
		current = null;
		return getCurrent();
	}

	public static function getCurrent() {
		if (current == null) {
			load();
		}

		return current;
	}
}