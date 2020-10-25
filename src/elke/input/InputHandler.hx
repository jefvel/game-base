package elke.input;

import elke.entity.BaseEntity;
import hxd.Event.EventKind;
import hxd.Key;

enum CommandType {
    Press;
    Continous;
    Release;
}

typedef CommandName = String;
typedef KeyName = String;

typedef CommandBinding = {
    var command : CommandName;
    var type : CommandType;
};

enum CommandKind {
    Start;
    Update;
    End;
    OneTime;
}
typedef CommandEvent = {
    kind : CommandKind,
    name : CommandName,
    force : Float,
    ?pad : GamePad,
}

class InputHandler {
    var commands : Map<CommandName, InputCommand>;
    var bindings : Map<KeyName, Array<CommandBinding>>;

    var activeCommands : Map<String, InputCommand>;

    var game : Game;

    public var focusedEntity (default, set): BaseEntity;

    public var usingController : Bool = false;

    public var pointerX : Int;
    public var pointerY : Int;

    public var pointerWorld (default, null) : h3d.col.Point;

    /**
     * stops inputs from being handled. useful for cutscenes or when the user shouldn't interfere
     */
    public var pauseInputs = false;

    public function new(game : Game) {
        this.game = game;
        pointerWorld = new h3d.col.Point();
        commands = new Map<CommandName, InputCommand>();
        bindings = new Map<KeyName, Array<CommandBinding>>();
        activeCommands = new Map<String, InputCommand>();
        registerConsoleCommands();
#if !noGamepads
        initGamePads();
#end
        pointerX = hxd.Window.getInstance().mouseX;
        pointerY = hxd.Window.getInstance().mouseY;
    }

    var gamePads : Array<GamePad>;
    function initGamePads() {
        gamePads = [];
        hxd.Pad.wait(onGamePad);
    }

    function onGamePad(pad : hxd.Pad) {
        if (!pad.connected) {
            return;
        }

        var p = new GamePad(pad, this);
        gamePads.push(p);
        pad.onDisconnect = () -> {
            p.onDisconnect();
            gamePads.remove(p);
        };
    }

    public function registerCommand(commandName : CommandName, cmd : InputCommand, defaultBinding : KeyName = null) {
        @:privateAccess
        cmd.game = this.game;

        commandName = normalize(commandName);

        commands[commandName] = cmd;
        if (defaultBinding != null) {
          bindCommand(defaultBinding, commandName);
        }
    }

    inline function normalize(s : String) {
        return s.toLowerCase();
    }

    function getAllCommandNames() {
      var sortedCommands = [];
      for (name => command in commands) {
          sortedCommands.push({ name: name, command: command });
      }

      sortedCommands.sort((a, b) -> {
          if (a.name < b.name) {
              return -1;
          }
          return 1;
      });

      return sortedCommands;
    }

    function logAvailableCommands() {
      var console = game.console;
      console.log("Available Input Commands:", 0x00DD00);
      for (command in getAllCommandNames()) {
        if (command.command.description != null) {
          console.log('${command.name}:  ${command.command.description}');
        } else {
          console.log(command.name);
        }
      }
    }

    public function executeCommand(commandName : CommandName) {
        var cmd = commands[normalize(commandName)];
        if (cmd == null) {
            return;
        }

        cmd.execute();
    }

    function registerConsoleCommands() {
      var c = game.console;

      c.addCommand("bind", "Binds input key to command", [
        {
            t : AString,
            name : "key",
            availableOptions: hxd.Key.getKeyNames(),
        },
        {
            t : AString,
            name : "command",
            resolveOptions: e -> getAllCommandNames().map(r -> r.name),
        },
      ], bindCommand);

      c.addCommand("unbind", "Unbinds key", [
        { 
            t : AString,
            name : "key",
            availableOptions: hxd.Key.getKeyNames(),
        },
        { t : AString, name : "command", opt : true },
      ], unbindCommand);

      c.addCommand("listCommands", "Displays all available bindable input commands", [],
        logAvailableCommands);
    }

    public function bindCommand(key : String, commandName : String) {
        key = normalize(key);
        commandName = normalize(commandName);
        var continous = false;
        if (commandName.charAt(0) == "+") {
            continous = true;
            commandName = commandName.substr(1);
        }

        if (bindings[key] == null) {
            bindings[key] = [];
        }

        if (!bindingExists(key, commandName)){
            bindings[key].push({
                type: continous ? Continous : Press,
                command: commandName,
            });
        }
    }

    function bindingExists(key, commandName) {
        if (bindings[key] == null) {
            return false;
        }

        for (c in bindings[key]) {
            if (c.command == commandName) {
                return true;
            }
        }

        return false;
    }

    // Unbinds key, if only key is specified all commands are unbound
    public function unbindCommand(key : KeyName, ?commandName : CommandName) {
        var commands = bindings[normalize(key)];
        if (commands == null) {
            return;
        }

        if (commandName == null) {
            bindings[normalize(key)] = null;
        } else {
            for (cmd in commands) {
                if (cmd.command == commandName) {
                    commands.remove(cmd);
                    return;
                }
            }
        }
    }

    public function pollControls() {
        for (pad in gamePads) {
            pad.update();
        }
    }

    public function update(dt : Float) : Void {
        if (pauseInputs) return;

        if (!game.paused && !game.console.isActive() && queuedEvents.length > 0) {
            for (e in queuedEvents) {
                processCommandEvent(e);
            }
            queuedEvents.resize(0);
        }

        for (cmd in activeCommands) {
            if (!cmd.alwaysAvailable) {
                if (game.paused || game.console.isActive()) {
                    continue;
                }
            }

            if (cmd.active) {
                cmd.continousExecute(dt);
            }
        }

        // Get cursor in world space
        /*
        var r = game.s3d.camera.rayFromScreen(pointerX, pointerY);
        var p1 = new h3d.col.Point(r.px, r.py, r.pz);
        var dist = 100;
        var p2 = new h3d.col.Point(p1.x + r.lx * dist, p1.y + r.ly * dist, p1.z + r.lz * dist);

        game.world.rayTest(p1, p2, Const.AllGroup ^ Const.PlayerGroup);

        pointerWorld.x = p2.x;
        pointerWorld.y = p2.y;
        pointerWorld.z = p2.z;
        */
    }

    function canBeContinous(eventKind : EventKind) : Bool {
        switch (eventKind) {
            case EKeyDown, EKeyUp: return true;
            case EPush, ERelease: return true;
            default: return false;
        }
    }

    function isCommandEnd(eventType : EventKind) {
        switch (eventType) {
            case EKeyDown, EPush: return false;
            default: return true;
        }
    }

    var queuedEvents = [];

    public function processCommandEvent(e : CommandEvent) {
        var commandBindings : Array<CommandBinding> = null;
        commandBindings = bindings[normalize(e.name)];
        if (commandBindings == null) {
            return;
        }
        for (commandBinding in commandBindings) {
            if (commandBinding != null) {
                var cmd = commands[commandBinding.command];
                if (cmd == null) {
                    return;
                }

                cmd.pad = e.pad;
                if (e.kind == End) {
                    if (!cmd.alwaysAvailable) {
                        if (game.paused) {
                            queuedEvents.push(e);
                            return;
                        }
                    }

                    if (cmd.active) {
                        cmd.finishExecute();
                    }

                    cmd.active = false;
                    activeCommands.remove(commandBinding.command);

                } else {
                    if (!cmd.alwaysAvailable) {
                        if (game.paused || game.console.isActive() || pauseInputs) {
                            return;
                        }
                    }

                    cmd.inputForce = e.force;

                    if (e.kind == Start || e.kind == Update) {
                        if (activeCommands[commandBinding.command] != cmd) {
                            cmd.execute();
                            cmd.active = true;
                            activeCommands[commandBinding.command] = cmd;
                        }
                    } else if (e.kind == OneTime) {
                        cmd.execute();
                        cmd.finishExecute();
                    }
                }
            }
        }
    }

    public function rumblePad(force : Float, time : Float) {
        if (!usingController) {
            return;
        }
        for (pad in gamePads) {
            pad.pad.rumble(force, time);
        }
    }

    public function handleEvent(event: hxd.Event) {
        usingController = false;

        var commandEnd = isCommandEnd(event.kind);

        var name : String = null;

        if (event.kind == EMove) {
            var w = hxd.Window.getInstance();
            pointerX = w.mouseX;
            pointerY = w.mouseY;
        }

        if (event.kind == EKeyDown || event.kind == EKeyUp) {
            name = Key.getKeyName(event.keyCode);
        }

        if (event.kind == EPush || event.kind == ERelease || event.kind == EReleaseOutside) {
            switch (event.button) {
                case Key.MOUSE_LEFT: name = "MouseLeft";
                case Key.MOUSE_RIGHT: name = "MouseRight";
                case Key.MOUSE_MIDDLE: name = "MouseMiddle";
                case Key.MOUSE_BACK: name = "Mouse3";
                case Key.MOUSE_FORWARD: name = "Mouse4";
            }

            switch(event.kind) {
                case EPush: commandEnd = false;
                case ERelease, EReleaseOutside: commandEnd = true;
                default: true;
            }
        }

        if (event.kind == EWheel) {
            commandEnd = false;
            if (event.wheelDelta < 0) name = "MouseWheelUp";
            if (event.wheelDelta > 0) name = "MouseWheelDown";
        }

        if (name == null) {
            return;
        }

        var kind = End;
        if (!commandEnd) {
            if (canBeContinous(event.kind)) {
                kind = Start;
            } else {
                kind = OneTime;
            }
        }

        processCommandEvent({
            name : name,
            kind : kind,
            force : 1.0,
        });
    }

    function set_focusedEntity(e : BaseEntity) {
		return focusedEntity = e;
    }
}
