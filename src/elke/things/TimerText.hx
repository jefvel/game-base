package elke.things;

import h2d.RenderContext;
import h2d.Text;

class TimerText extends Text {
	/**
	 * @time in seconds
	 */
	public var time: Float = 0.;
	public function new(font, ?p) {
		super(font, p);
		dropShadow = {
			dx: 1,
			dy: 1,
			color: 0x111111,
			alpha: 0.4,
		};
	}

	override function sync(ctx:RenderContext) {
		super.sync(ctx);
		var minutes = Math.floor(time / 60);
		var seconds = time - minutes * 60;
		var extraZero = minutes < 10 ? '0' : '';
		var extraSecondZero = seconds < 10 ? '0' : '';
		var hundredsSplit = '${seconds}'.split('.');
		var hundreds = "000";
		if (hundredsSplit.length > 1) {
			hundreds = '${hundredsSplit[1].substr(0, 3)}';
			while(hundreds.length < 3){
				hundreds = "0" + hundreds;
			}
		}

		text = '$extraZero$minutes:$extraSecondZero${Math.floor(seconds)}:$hundreds';
	}
}