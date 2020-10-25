package elke.dialogue;

class MessageInfo extends DialogueItem {
    var txt : h2d.Text;

    public function new (infoText, ?parent) {
        super(parent);
        txt = new h2d.Text(hxd.Res.fonts.m5x7_medium_12.toFont(), this);
        txt.color.set(0.5, 0.5, 0.5);
        txt.maxWidth = 290;
        txt.text = infoText;
        txt.y = 3;
    }

    override function tick(dt : Float) {
    }

    public override function onNavigate(direction : inputcommands.MoveCommand.Direction) : Void {
    }

    public override function onUIAction(action : inputcommands.UIActionCommand.UIAction) : Void {
    }
}
