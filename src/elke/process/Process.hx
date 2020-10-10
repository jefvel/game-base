package elke.process;

class Process {
	public function update(dt:Float) {
		if (updateFn != null) {
			updateFn(dt);
		}
	}

	public function onStart() {}

	public function onFinish() {}

	public var updateFn:Float->Void;

	public function new(onUpdate:Float->Void = null) {
		this.updateFn = onUpdate;
		Game.instance.addProcess(this);
	}

	public function remove() {
		Game.instance.removeProcess(this);
	}
}