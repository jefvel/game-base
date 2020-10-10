package elke.gamestate;

class GameState {
	@:allow(elke.gamestate.GameStateHandler)
	var game:elke.Game;

	public var name:String;

	public function onEvent(e:hxd.Event):Void {}

	public function onEnter():Void {}

	public function onLeave():Void {}

	public function update(dt:Float):Void {}

	public function onRender(e:h3d.Engine):Void {}
}