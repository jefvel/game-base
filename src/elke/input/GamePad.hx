package elke.input;

import elke.input.InputHandler;
import elke.input.InputHandler.CommandEvent;

import hxd.Pad;

@:allow(elke.input.InputHandler)
class GamePad {
    var pad : Pad;
    var handler : InputHandler;

    static var conf = hxd.Pad.DEFAULT_CONFIG;
    static var buttonNames = [
        "CtlA" => conf.A,
        "CtlB" => conf.B,
        "CtlX" => conf.X,
        "CtlY" => conf.Y,
        "CtlRightBumper" => conf.RB,
        "CtlLeftBumper" => conf.LB,
        "CtlLeftTrigger" => conf.LT,
        "CtlRightTrigger" => conf.RT,

        "CtlStart" => conf.start,
        "CtlBack" => conf.back,

        "CtlAnalogClick" => conf.analogClick,
        "CtlRightAnalogClick" => conf.ranalogClick,

        "CtlDpadLeft" => conf.dpadLeft,
        "CtlDpadRight" => conf.dpadRight,
        "CtlDpadDown" => conf.dpadDown,
        "CtlDpadUp" => conf.dpadUp,
    ];

    public function new(pad : Pad, inputHandler : InputHandler) {
        this.pad = pad;
        this.handler = inputHandler;
    }

    var lAnalogLeftPressed = false;
    var lAnalogRightPressed = false;
    var lAnalogDownPressed = false;
    var lAnalogUpPressed = false;

    /**
     * Defines the zone analog sticks can be at before triggering movement events. 0 = very sensitive, 1 = doesn't respond at all
     */
    public static var DEAD_ZONE = 0.3;

    inline function sendCommand(e : CommandEvent) {
        handler.usingController = true;
        handler.processCommandEvent(e);
    }

    function update() {
        var w = hxd.Window.getInstance();
        var isFocused = w.isFocused;
        for (btnName => btn in buttonNames) {
            if (isFocused && pad.isPressed(btn)) {
                sendCommand({
                    pad : this,
                    kind: Start,
                    name: btnName,
                    force: 1.0,
                });
            } else if(pad.isReleased(btn)) {
                sendCommand({
                    pad : this,
                    kind: End,
                    name: btnName,
                    force: 1.0,
                });
            }
        }
        
        var dx = pad.values[conf.analogX];

        var active = Math.abs(dx) > DEAD_ZONE;
        var force = (Math.abs(dx) - DEAD_ZONE) * (1 / (1 - DEAD_ZONE)) * 1.1;
        force = Math.min(force, 1.0);

        if (!active) {
            if (lAnalogRightPressed) {
                lAnalogRightPressed = false;
                sendCommand({
                    pad : this,
                    kind: End,
                    name: "CtlAnalogRight",
                    force: force,
                });
            }
            if (lAnalogLeftPressed) {
                lAnalogLeftPressed = false;
                sendCommand({
                    pad : this,
                    kind: End,
                    name: "CtlAnalogLeft",
                    force: force,
                });
            }
        } else if (isFocused) {
            if (dx > DEAD_ZONE) {
                lAnalogRightPressed = true;
                sendCommand({
                    pad : this,
                    kind: Update,
                    name: "CtlAnalogRight",
                    force: force,
                });
            } else if (dx < -DEAD_ZONE) {
                lAnalogLeftPressed = true;
                sendCommand({
                    pad : this,
                    kind: Update,
                    name: "CtlAnalogLeft",
                    force: force,
                });
            }
        }

        var dy = pad.values[conf.analogY];
        active = Math.abs(dy) > DEAD_ZONE;
        force = (Math.abs(dy) - DEAD_ZONE) * (1 / (1 - DEAD_ZONE)) * 1.1;
        force = Math.min(force, 1.0);

        if (!active) {
            if (lAnalogUpPressed) {
                lAnalogUpPressed = false;
                sendCommand({
                    pad : this,
                    kind: End,
                    name: "CtlAnalogUp",
                    force: force,
                });
            }
            if (lAnalogDownPressed) {
                lAnalogDownPressed = false;
                sendCommand({
                    pad : this,
                    kind: End,
                    name: "CtlAnalogDown",
                    force: force,
                });
            }
        } else if (isFocused) {
            if (dy > DEAD_ZONE) {
                lAnalogUpPressed = true;
                sendCommand({
                    pad : this,
                    kind: Update,
                    name: "CtlAnalogUp",
                    force: force,
                });
            } else if (dy < -DEAD_ZONE) {
                lAnalogDownPressed = true;
                sendCommand({
                    pad : this,
                    kind: Update,
                    name: "CtlAnalogDown",
                    force: force,
                });
            }
        }
    }

    public function getRightStickX() : Float {
        var v = pad.values[conf.ranalogX];
        if (Math.abs(v) < DEAD_ZONE) {
            return 0.0;
        }

        var neg = v < 0;

        var force = (Math.abs(v) - DEAD_ZONE) * (1 / (1 - DEAD_ZONE));
        if (neg) {
            return -force;
        }
        return force;
    }

    public function getRightStickY() : Float {
        var v = pad.values[conf.ranalogY];
        if (Math.abs(v) < DEAD_ZONE) {
            return 0.0;
        }

        var neg = v < 0;

        var force = (Math.abs(v) - DEAD_ZONE) * (1 / (1 - DEAD_ZONE));
        if (neg) {
            return -force;
        }
        return force;
    }

    public function onDisconnect() {

    }
}