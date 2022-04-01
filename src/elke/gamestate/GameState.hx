package elke.gamestate;

class GameState {
	@:allow(elke.gamestate.GameStateHandler)
	var game:elke.Game;

	public var name:String;

	public function onEvent(e:hxd.Event):Void {}

	public function onPause() {}
	public function onUnpause() {}

	public function onEnter():Void {}

	public function onLeave():Void {}

	/**
	 * tick runs at a fixed timestep
	 * @param dt 
	 */
	public function tick(dt:Float):Void {}

	/**
	 * update runs every frame, at a variable dt
	 * @param dt 
	 * @param timeUntilTick time until current tick ends
	 */
	public function update(dt:Float, timeUntilTick: Float):Void {}

	public function onRender(e:h3d.Engine):Void {}
}