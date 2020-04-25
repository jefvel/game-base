package gamestate;

class GameState {
    @:allow(gamestate.GameStateHandler)
    var game : Game;

    public var name : String;

    public function onEvent(e: hxd.Event): Void {}

    public function onEnter(): Void {}
    public function onLeave(): Void {}
    public function update(dt: Float): Void {}
    public function onRender(e : h3d.Engine) : Void {}
}