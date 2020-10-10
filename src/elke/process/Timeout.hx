package elke.process;

class Timeout extends Process {
	public var duration:Float;

	var elapsed:Float;

	var onRun:Void->Void;

	public function new(time:Float, run:Void->Void) {
		duration = time;
		elapsed = 0.0;
		this.onRun = run;
		super();
	}

	override function update(dt:Float) {
		elapsed += dt;
		if (elapsed >= duration) {
			onRun();
			this.remove();
		}
	}

	public function reset() {
		elapsed = 0.0;
	}
}
