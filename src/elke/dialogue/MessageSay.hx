package elke.dialogue;

import h2d.RenderContext;
import h2d.Object;

class MessageSay extends DialogueItem {
    var msg : String;

    var txt : h2d.Text;
    var onFinish : Void -> Void;
    var finished = false;
    var l = 0;

    var voiceSpeed = 0.;
    var sounds : Array<hxd.res.Sound>;

    var auto = false;

    var dialogue : Dialogue;
    public function new (messageNode : Xml, onFinish : Void -> Void, ?parent, d: Dialogue) {
        super(parent);
        this.dialogue = d;

        msg = messageNode.firstChild().nodeValue;

        if (messageNode.exists("auto")) auto = true;

        this.onFinish = onFinish;
        txt = new h2d.Text(hxd.Res.fonts.equipmentpro_medium_12.toFont(), this);
        txt.maxWidth = d.maxWidth;
        txt.text = "";
        if (dialogue.type == Character) {
            sounds = [
                hxd.Res.sound.voices.woodman._1,
                hxd.Res.sound.voices.woodman._2,
                hxd.Res.sound.voices.woodman._3,
                hxd.Res.sound.voices.woodman._4,
                hxd.Res.sound.voices.woodman._5,
                hxd.Res.sound.voices.woodman._6,
            ];
        } else {
            txt.color.set(0.8, 0.8, 0.8);
            sounds = [
                hxd.Res.sound.ui.pop,
            ];
        }
    }

    var t = 0.0;
    override function tick(dt : Float) {
        if (l < msg.length) {
            voiceSpeed -= dt;
            if (voiceSpeed < 0) {
                voiceSpeed = 0.1;
                var snd = sounds[Std.int(Math.random() * sounds.length)];
                if (talker != null) {
                    talker.playSound(snd, 1.0, 20.0);
                }
            }
            l ++;
            txt.text = msg.substr(0, l);
            return;
        }

        if (auto) {
            if (!finished) {
                finished = true;
                onFinish();
            }
        }
    }

    public override function onNavigate(direction : inputcommands.MoveCommand.Direction) : Void {
    }

    public override function onUIAction(action : inputcommands.UIActionCommand.UIAction) : Void {
        if (finished) {
            return;
        }

        if (auto) {
            return;
        }

        if (action == Use || action == Click) {
            if (l == msg.length) {
                finished = true;
                onFinish();
            } else {
                l = msg.length - 1;
            }
        }
    }
}
