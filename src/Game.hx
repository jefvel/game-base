package;

import gamestate.GameStateHandler;

class Game extends hxd.App {
    static var instance : Game;
    public static inline function getInstance() {
        return instance;
    }

    public var paused : Bool;

    /**
     * the width of the screen in scaled pixels
     */
    public var screenWidth : Int;
    /**
     * the height of the screen in scaled pixels
     */
    public var screenHeight : Int;

    var entities : entity.Entities;
    var states : gamestate.GameStateHandler;

    override function init() {
        super.init();
        initResources();

        initEntities();
        configRenderer();

        states = new GameStateHandler(this);
        states.setState(new example.ExampleGameState());
    }

    function initEntities() {
        entities = new entity.Entities();
    }

    function configRenderer() {
        // Image filtering set to nearest sharp pixel graphics
        hxd.res.Image.DEFAULT_FILTER = Nearest;

        engine.backgroundColor = 0xFEFEFE;
        engine.autoResize = true;

        if (Const.PIXEL_SIZE > 1) {
            s2d.filter = new h2d.filter.Nothing();
        }

        hxd.Window.getInstance().addResizeEvent(onResizeEvent);
        onResizeEvent();
    }

    var timeAccumulator = 0.0;
    override function update(dt:Float) {
        super.update(dt);

        if (paused) {
            return;
        }

        var maxTicksPerUpdate = 3;

        timeAccumulator += dt;
        while (timeAccumulator > Const.TICK_TIME && maxTicksPerUpdate > 0) {
            timeAccumulator -= dt;
            states.update(Const.TICK_TIME);
            entities.update(Const.TICK_TIME);
            maxTicksPerUpdate --;
        }
    }

    function onResizeEvent() {
        var s = hxd.Window.getInstance();

        var w = Std.int(s.width / Const.PIXEL_SIZE);
        var h = Std.int(s.height / Const.PIXEL_SIZE);

        this.screenWidth = w;
        this.screenHeight = h;

        s2d.scaleMode = ScaleMode.Stretch(w, h);
    }

    static function initResources() {
#if usepak
        hxd.Res.initPak("data");
#elseif (debug && hl)
        hxd.Res.initLocal();
        hxd.res.Resource.LIVE_UPDATE = true;
#else
        hxd.Res.initEmbed();
#end
    }

    static function main() {
        instance = new Game();
    }
}
