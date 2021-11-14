package elke.process;

class Timeout extends Process {
	public var duration:Float = 0.;

	var elapsed:Float = 0.;

	var onRun:Void->Void;

	public function new(time:Float = 0., run:Void->Void) {
		duration = time;
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
