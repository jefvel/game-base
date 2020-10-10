package;

import elke.Game;
import gamestates.ExampleGameState;

class Main {
    static var game : Game;
	static function main() {
        game = new Game(new ExampleGameState());
	}
}
