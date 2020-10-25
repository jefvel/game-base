package elke.input;

import elke.entity.BaseEntity;


@:allow(elke.input.InputHandler)
class InputCommand {
    var game : Game;

    // If command was made by a controller, this will be set to it.
    var pad : GamePad;

    // Number between 0 and 1 (For pressure sensitive buttons and joypads)
    var inputForce : Float = 1.0;

    // If command is bound to a stick, these will be between -1 and 1
    var rightStickX : Float = 0.0;
    var rightStickY : Float = 0.0;

    // InputCommand is available in all menus and when game is paused
    public var alwaysAvailable : Bool = false;
    public var description : String;

    public var active = false;

    /**
     * When toggle is enabled, the command will be executed when button is pressed,
     * and then stopped once the button is pressed again.
     */
    public var toggle : Bool = false;

    private inline function getTargetEntity() : BaseEntity {
        return game.inputHandler.focusedEntity;
    }

    /**
     * cancel finishes the command, it will call finishExecute
     */
    public function cancel() {
        this.finishExecute();
        active = false;
    }

    public function new() {}
    // Ran when command is activated
    public function execute() {}
    // Ran every frame when command is active
    public function continousExecute(dt : Float) {}
    // When continous command finishes
    public function finishExecute() {}
    public function undo() {}
}
