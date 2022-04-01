package elke.gamestate;

import h3d.Engine;
import elke.Game;

class GameStateHandler {
	static var instance:GameStateHandler;

	public static inline function getInstance() {
		return instance;
	}

	var currentState:GameState;

	var game:Game;

	public function new(g:Game) {
		instance = this;
		game = g;
	}

	public function update(dt: Float, timeUntilTick: Float) {
		if (currentState != null) {
			currentState.update(dt, timeUntilTick);
		}
	}

	public function tick(dt:Float) {
		if (currentState != null) {
			currentState.tick(dt);
		}
	}

	public function onEvent(e:hxd.Event) {
		if (currentState != null) {
			currentState.onEvent(e);
		}
	}

	public function onPause() {
		if (currentState != null) {
			currentState.onPause();
		}
	}

	public function onUnpause() {
		if (currentState != null) {
			currentState.onUnpause();
		}
	}

	public function onRender(e: Engine) {
		if (currentState != null) {
			currentState.onRender(e);
		}
	}

	public function setState(s:GameState) {
		if (currentState != null) {
			currentState.onLeave();
		}

		s.game = game;

		currentState = s;
		s.onEnter();
	}
}