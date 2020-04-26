package example;

class ExampleGameState extends gamestate.GameState {
    var coolEntity : example.ExampleEntity;
    public function new() {

    }

    override function onEnter() {
        super.onEnter();
        coolEntity = new example.ExampleEntity(game.s3d);
    }

    var time = 0.0;
    override function update(dt:Float) {
        super.update(dt);
        time += dt;
        game.s3d.camera.pos.set(0 + Math.sin(time * 0.5), 4.0 + Math.sin(time * 0.8) * 0.4, 2.0);
    }

    override function onLeave() {
        super.onLeave();
        coolEntity.remove();
    }
}