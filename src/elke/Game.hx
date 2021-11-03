package elke;

import haxe.Timer;
import h3d.Engine;
import h2d.Scene;
import elke.gamestate.GameState;
import elke.sound.Sounds;
import elke.gamestate.GameStateHandler;
import elke.entity.Entities;

typedef GameInitConf = {
	?initialState:GameState,
	?pixelSize:Int,
	?tickRate:Int,
	?onInit:Void->Void,
	?backgroundColor:Int,
}

class Game extends hxd.App {
    public static var instance(default, null):Game;
    
    public var paused(default, set) : Bool;

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
	public var tickTime:Float = 1 / 60.;
    function set_tickRate(r : Int) {
		tickTime = 1. / r;
        return tickRate = r;
    }

    var initialState : GameState;
	var onInit:Void->Void;

	var conf:GameInitConf;

	public function new(?conf:GameInitConf) {
        super();
		this.conf = conf;
    }

    override function init() {
        super.init();
        instance = this;

        initResources();

        initEntities();
        configRenderer();

		sound = new Sounds();

        states = new GameStateHandler(this);
        
		runInitConf();

        onResize();
	}

	function runInitConf() {
		if (conf == null) {
			return;
		}

		if (conf.onInit != null) {
			conf.onInit();
		}

		if (conf.pixelSize != null) {
			pixelSize = conf.pixelSize;
		}

		if (conf.tickRate != null) {
			tickRate = conf.tickRate;
		}

		if (conf.backgroundColor != null) {
			engine.backgroundColor = conf.backgroundColor;
		}

		if (conf.initialState != null) {
			states.setState(conf.initialState);
            initialState = null;
        }

		conf = null;
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

    public var uiScene: Scene;
    override function render(e:Engine) {
		s3d.render(e);
		s2d.render(e);
        states.onRender(e);
        uiScene.render(e);
    }

    function configRenderer() {
        // Image filtering set to nearest sharp pixel graphics.
        // If you don't want crisp pixel graphics you can just
        // remove this
        hxd.res.Image.DEFAULT_FILTER = Nearest;

		#if js
        // This causes the game to not be super small on high DPI mobile screens
		hxd.Window.getInstance().useScreenPixels = false;
		#end

        engine.autoResize = true;
        uiScene = new Scene();
    }

    var freezeFrames = 0;
    public function freeze(frames) {
        freezeFrames = frames;
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
            if (freezeFrames > 0) {
                freezeFrames--;
                continue;
            }

			for (p in processes) {
				p.update(tickTime);
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
        uiScene.scaleMode = ScaleMode.Resize;
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
        // Load CastleDB data.
        Data.load(hxd.Res.data.entry.getText());
    }

    function set_paused(p) {
        if (p != this.paused) {
            if (p) {
                states.onPause();
            } else {
                states.onUnpause();
            }
        }

        return this.paused = p;
    }

    public function vibrate(duration: Int) {
        #if js
        if (js.Browser.navigator.vibrate != null) {
		    js.Browser.navigator.vibrate(duration);
        }
        #end
    }

    /**
     * Checks whether or not the game can be added to the
     * home screen on mobile devices.
     */
    public function canBeAddedAsPWA() {
        #if js
		var d: Dynamic = js.Browser.window;
		return d.installPWAPrompt != null;
        #end

        return false;
    }

    /**
     * shows the build in prompt for installing the game
     * as a PWA on mobiles/desktops
     * @param onAccept happens when the user accepts the prompt
     * @param onDecline happens if the user declines, or the prompt couldn't be shown
     */
    public function promptAddAsPWA(?onAccept: Void -> Void, ?onDecline: Void -> Void) {
        #if js
        var d: Dynamic = js.Browser.window;
        var deferredInstall = null;
        if (d.installPWAPrompt != null) {
            deferredInstall = d.installPWAPrompt;
        }
        if (deferredInstall != null) {
            deferredInstall.prompt();
            deferredInstall.userChoice.then((choiceResult) -> {
                if (choiceResult.outcome == 'accepted') {
                    var d: Dynamic = js.Browser.window;
                    d.installPWAPrompt = null;
                    if (onAccept != null) {
                        onAccept();
                    }
                } else {
                    if (onDecline != null) {
                        onDecline();
                    }
                }
            });
        } else {
            if (onDecline != null) {
                onDecline();
            }
        }
        #end

        if (onDecline != null) {
            onDecline();
        }
    }

}
