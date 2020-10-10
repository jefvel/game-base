package;

import elke.Game;
import gamestates.ExampleGameState;

class Main {
	static var game:Game;

	static function main() {
		game = new Game({
			initialState: new ExampleGameState(),
			onInit: () -> {},
			tickRate: Const.TICK_RATE,
			pixelSize: Const.PIXEL_SIZE,
			backgroundColor: 0xFFFFFF,
		});
	}
}
