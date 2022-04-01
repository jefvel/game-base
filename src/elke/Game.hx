package elke;

import hxd.Window;
import elke.input.GamePadHandler;
import elke.process.Command;
import h2d.Text;
import elke.process.Timeout;
import h3d.impl.Benchmark;
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

enum InputMethod {
	KeyboardAndMouse;
	Touch;
	Gamepad;
}

class Game extends hxd.App {
	public static var instance(default, null):Game;

	public var paused(default, set):Bool;

	/**
	 * when touch controls are enabled, this is true
	 * Whenever a non touch input happens, it will be disabled
	 */
	public var inputMethod:InputMethod = KeyboardAndMouse;

	public var usingTouch(get, null) = false;

	function get_usingTouch() {
		return inputMethod == Touch;
	}

	/**
	 * the width of the screen in scaled pixels
	 */
	public var screenWidth:Int;

	/**
	 * the height of the screen in scaled pixels
	 */
	public var screenHeight:Int;

	public var entities:Entities;
	public var states:GameStateHandler;

	public var sound:Sounds;

	public var time = 0.;

	/**
	 *  mouse x in scaled screen pixels
	 */
	public var mouseX:Int;

	/**
	 *  mouse y in scaled screen pixels
	 */
	public var mouseY:Int;

	public var gamepads:GamePadHandler = null;

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

	public var timeScale = 1.0;

	function set_tickRate(r:Int) {
		tickTime = 1. / r;
		return tickRate = r;
	}

	var initialState:GameState;
	var onInit:Void->Void;

	var conf:GameInitConf;

	public var benchmark:Benchmark;

	var drawCallsText:Text;

	public function new(?conf:GameInitConf) {
		super();
		#if (hl && !debug)
		hl.UI.closeConsole();
		#end

		this.conf = conf;
	}

	override function init() {
		super.init();
		instance = this;

		initResources();

		initEntities();
		configRenderer();

		hxd.Window.getInstance().addEventTarget(onEvent);

		sound = new Sounds();

		states = new GameStateHandler(this);

		onResize();

		runInitConf();

		initiateGamepads();

		/*
			benchmark = new Benchmark(uiScene);
			benchmark.measureCpu = true;
			benchmark.enable = true;
		 */

		#if debug
		drawCallsText = new Text(hxd.Res.fonts.minecraftiaOutline.toFont(), s2d);
		#end
	}

	function onEvent(e:hxd.Event) {
		#if js
		if (e.kind == EPush) {
			if (e.touchId != null) {
				inputMethod = Touch;
			} else {
				inputMethod = KeyboardAndMouse;
			}
		}
		if (e.kind == EKeyDown) {
			inputMethod = KeyboardAndMouse;
		}
		#else
		if (e.kind == EPush || e.kind == EKeyDown) {
			inputMethod = KeyboardAndMouse;
		}
		#end

		if (e.kind == EMove) {
			mouseX = Std.int(e.relX / pixelSize);
			mouseY = Std.int(e.relY / pixelSize);
		}

		if (e.kind == EFocusLost) {
			gamepads.inFocus = false;
		}
		if (e.kind == EFocus) {
			gamepads.inFocus = true;
		}

		states.onEvent(e);
	}

	function initiateGamepads() {
		gamepads = new GamePadHandler();
		new Timeout(0.1, () -> {
			gamepads.init();
		});
	}

	public function vibrate(duration:Int) {
		if (inputMethod == Gamepad) {
			if (gamepads.vibrate(duration)) {
				return;
			}
		}

		#if js
		if (js.Browser.navigator.vibrate != null) {
			js.Browser.navigator.vibrate(duration);
		}
		#end
	}

	public function canBeAddedAsPWA() {
		#if js
		var d:Dynamic = js.Browser.window;
		return d.installPWAPrompt != null;
		#end

		return false;
	}

	public function promptAddAsPWA(?onAccept:Void->Void, ?onDecline:Void->Void) {
		#if js
		var d:Dynamic = js.Browser.window;
		var deferredInstall = null;
		if (d.installPWAPrompt != null) {
			deferredInstall = d.installPWAPrompt;
		}
		if (deferredInstall != null) {
			deferredInstall.prompt();
			deferredInstall.userChoice.then((choiceResult) -> {
				if (choiceResult.outcome == 'accepted') {
					var d:Dynamic = js.Browser.window;
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

	public var uiScene:Scene;

	override function render(e:Engine) {
		s3d.render(e);
		s2d.render(e);
		states.onRender(e);
		uiScene.render(e);

		#if debug
		s2d.addChild(drawCallsText);
		drawCallsText.x = 2;
		drawCallsText.text = '${e.drawCalls}';
		#end
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

	var commands:Array<Command> = [];

	public function dispatchCommand(c:Command) {
		commands.push(c);
	}

	var timeAccumulator = 0.0;

	override function update(dt:Float) {
		// benchmark.begin();

		var maxTicksPerUpdate = 3;

		// Check if gamepad is pressed
		if (gamepads.anyButtonPressed()) {
			inputMethod = Gamepad;
		}

		timeAccumulator += dt;

		var timeUntilTick = Math.max(tickTime - timeAccumulator, 0);

		states.update(dt, timeUntilTick);

		while (timeAccumulator > tickTime * timeScale && maxTicksPerUpdate > 0) {

			if (commands.length > 0) {
				for (c in commands)
					c();
				commands.splice(0, commands.length);
			}

			timeAccumulator -= tickTime * timeScale;
			if (freezeFrames > 0) {
				freezeFrames--;
				continue;
			}


			// States are still updated, to make sure pause menus and such work
			if (paused) {
				return;
			}

			time += tickTime;

			states.tick(tickTime * timeScale);

			for (p in processes) {
				p.update(tickTime * timeScale);
			}

			entities.update(tickTime * timeScale);

			maxTicksPerUpdate--;
		}
		// benchmark.end();
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
}
