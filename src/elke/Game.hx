package elke;

import elke.gamestate.GameState;
import elke.sound.Sounds;
import elke.gamestate.GameStateHandler;
import elke.entity.Entities;

class Game extends hxd.App {
    public static var instance(default, null):Game;
    
    public var paused : Bool;

    /**
     * the width of the screen in scaled pixels
     */
    public var screenWidth : Int;
    /**
     * the height of the screen in scaled pixels
     */
    public var screenHeight : Int;

	public var entities:Entities;
	public var states:GameStateHandler;

    public var sound:Sounds;
    
	/**
	 *  mouse x in scaled screen pixels
     */
	public var mouseX:Int;
	/**
	 *  mouse y in scaled screen pixels
     */
    public var mouseY:Int;
    
    /**
     * size of window pixels. scale of window.
     */
    public var pixelSize(default, set):Int;

    function set_pixelSize(size) {
        if (s2d != null) {
            if (size > 1) {
                if (s2d.filter == null) {
                    s2d.filter = new h2d.filter.Nothing();
                }
            } else {
                s2d.filter = null;
            }
        }

        pixelSize = size;
        onResize();

        return pixelSize = size;
    }

    /**
     * updates per second
     */
    public var tickRate(default, set) = 60;
    var tickTime : Float = 1 / 60.;
    function set_tickRate(r : Int) {
        tickTime = 1. / 60.;
        return tickRate = r;
    }

    var initialState : GameState;
    public function new(initialState : GameState = null) {
        super();
        this.initialState = initialState;
    }

    override function init() {
        super.init();
        instance = this;

        initResources();

        initEntities();
        configRenderer();

		sound = new Sounds();

        states = new GameStateHandler(this);
        
        if (initialState != null) {
            states.setState(initialState);
            initialState = null;
        }
    }

    function initEntities() {
        entities = new Entities();
    }

    var processes:Array<elke.process.Process> = [];
    public function addProcess(p) {
        processes.push(p);
        p.onStart();
    }
    public function removeProcess(p) {
        if (processes.remove(p)) {
            p.onFinish();
        }
    }

    function configRenderer() {
        // Image filtering set to nearest sharp pixel graphics
        hxd.res.Image.DEFAULT_FILTER = Nearest;

        engine.autoResize = true;

        onResize();
    }

    var timeAccumulator = 0.0;
    override function update(dt:Float) {
        super.update(dt);

        if (paused) {
            return;
        }

        var maxTicksPerUpdate = 3;

        timeAccumulator += dt;
        while (timeAccumulator > tickTime && maxTicksPerUpdate > 0) {
            timeAccumulator -= tickTime;
			for (p in processes) {
				p.update(dt);
			}

            states.update(tickTime);
            entities.update(tickTime);

            maxTicksPerUpdate --;
        }
    }

    override function onResize() {
        var s = hxd.Window.getInstance();

        var w = Std.int(s.width / pixelSize);
        var h = Std.int(s.height / pixelSize);

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
}