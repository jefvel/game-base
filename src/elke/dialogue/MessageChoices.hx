package elke.dialogue;

import h3d.Matrix;
import h2d.filter.DropShadow;
import h2d.filter.ColorMatrix;
import hxd.System;
import hxd.res.Sound;
import h2d.Bitmap;
import h2d.TileGroup;

typedef MessageChoice = {
    text: String,
    id: Int,
};

class MessageChoices extends DialogueItem {
    var choices : Array<MessageChoice>;
    var onSelect : Int -> Void;
    var selected = false;

    var items : Array<h2d.Interactive>;
    var selectedItem : h2d.Interactive;
    
    var frame : h2d.Bitmap;
    var cursor : h2d.Bitmap;

    final marginY = 8.;
    final marginX = 16.;

    var selectedIndex = 0;

    var selectSound : Sound;
    var vol = 0.6;

    public function new (choices : Array<MessageChoice>, onChoiceSelect: Int -> Void, ?parent) {
        super(parent);
        this.choices = choices;
        this.onSelect = onChoiceSelect;
        var fnt = hxd.Res.fonts.equipmentpro_medium_12.toFont();
        var y = marginY;
        items = [];
        var index = 0;
        selectSound = hxd.Res.sound.ui.choice_select;

        for (c in choices) {
            var b = new h2d.Text(fnt);
            b.text = c.text;

            var i = new h2d.Interactive(b.calcTextWidth(b.text), b.textHeight, this);
            i.y = y;
            i.x = 9;
            i.addChild(b);
            i.backgroundColor = 0x444444;
            var id = index;
            i.onClick = e -> {
                selectItem(id);
                System.setCursor(Default);
            }

            i.onOver = e -> {
                if (selected) {
                    return;
                }

                if (selectedIndex != id) {
                    playSelectSound();
                }

                selectedIndex = id;
            }

            i.onPush = e -> {
                if (selected) return;
                i.alpha = 0.7;
            }

            i.onRelease = i.onReleaseOutside = e-> {
                if (selected) return;
                i.alpha = 1.0;
            }

            y += i.height + 8;
            items.push(i);
            index ++;
        }

        var b = this.getBounds();
        var tile = h2d.Tile.fromColor(0x000000, Std.int(b.width + marginX * 2), Std.int(b.height + marginY * 2), 0.3);
        frame = new h2d.Bitmap(tile);
        addChildAt(frame, 0);

        cursor = new Bitmap(hxd.Res.img.ui.choice_cursor.toTile(), this);
        cursor.x = -2;
        
        Game.instance().audio.playUI(hxd.Res.sound.ui.choice_prompt, 0.4);

        /*
        var m = Matrix.I();
        m._11 = m._22 = m._33 = -1;
        m._43 = 1.0;
        m._44 = 1.0;
        m._41 = m._42 = m._43 = 1.0;
        this.filter = new ColorMatrix(m);
        */

    }

    function playSelectSound() {
        Game.instance().audio.playUI(selectSound, vol);
    }

    override function tick(dt:Float) {
        if (selected) {
            for (i in items) {
                //i.y *= 0.6;
                if (i != selectedItem) {
                    i.alpha *= 0.56;
                    i.alpha = Math.max(0.1, i.alpha);
                }
            }
            cursor.alpha *= 0.7;
            cursor.x *= 0.9;
        }

        cursor.y = items[selectedIndex].y + 4;
    }

    function selectItem(index : Int) {
        if (selected) return;
        selected = true;
        selectedIndex = index;
        selectedItem = items[index];
        Game.instance().audio.playUI(hxd.Res.sound.ui.choice_confirm, vol);
        onSelect(choices[index].id);
        for (i in items) {
            i.cursor = Default;
        }
    }

    public override function onNavigate(direction : inputcommands.MoveCommand.Direction) : Void {
        if (direction == Up) {
            selectedIndex --;
            if (selectedIndex < 0) selectedIndex = items.length - 1;
            playSelectSound();
        }

        if (direction == Down) {
            selectedIndex ++;
            if (selectedIndex >= items.length) selectedIndex = 0;
            playSelectSound();
        }
    }

    public override function onUIAction(action : inputcommands.UIActionCommand.UIAction) : Void {
        if (action == Use) {
            selectItem(selectedIndex);
        }
    }
}
