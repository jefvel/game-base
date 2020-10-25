package elke.dialogue;

import elke.entity.Entity2D;
import hxd.res.Image;
import h2d.RenderContext;
import h2d.Bitmap;
import hxd.res.Resource;

enum DialogueType {
    Character;
    Info;
}

enum DialogAction {
    Up;
    Down;
    Left;
    Right;

    Select;
    Cancel;
    ScrollUp;
    ScrollDown;
}

class Dialogue extends Entity2D {

    public var flags : Map<String, Dynamic>;
    public var type : DialogueType = Character;

    var current : Xml;
    var tree : Xml;

    var game : Game;

    var nonParentable = [ "choice" ];
    var items : Array<DialogueItem>;

    var lastIfWasFalse = false;

    var maxHeight = 140;
    public var maxWidth = 200;
    var marginX = 16;
    var marginY = 14;
    var scrollBack = 0.0;

    var itemsContainer : h2d.Object;

    static var registeredElements = new Map<String, MessageNode>();

    var bg : h2d.Bitmap;

    var talkerName : h2d.Text;
    var talkerNameBg : h2d.Bitmap;

    var delayedStart = 0.44;

    public function new(resPath : String, ?parent) {
        items = [];

        game = Game.instance;

        var contents = hxd.Res.loader.loadCache(resPath, Resource).entry.getText();
        var data = Xml.parse(contents).firstElement();
        tree = data;

        if (tree.exists("type")) {
            switch (tree.get("type")) {
                case "character": this.type = Character;
                case "info": this.type = Info;
            }
        }

        current = tree.firstElement();

        itemsContainer = new h2d.Object();

        super(parent);

        var t = h2d.Tile.fromColor(0x000000, 0.8);
        bg = new Bitmap(t, this);
        bg.width = maxWidth + marginX * 2;
        bg.height = maxHeight + marginY * 2;
        bg.x = -marginX;

        addChild(itemsContainer);

        /*
        scriptContext = game.scripts.newInterpreter();
        scriptContext.variables.set("locals", new Map<String, Dynamic>());
        */

        itemsContainer.filter = new h2d.filter.Mask(bg, true);
    }

    var justAdded = true;
    var waitTime = 0.0;
    var onWaitNode = false;
    public function tick(dt : Float) {
        justAdded = false;
        if (delayedStart > 0) {
            delayedStart -= dt;
            if (delayedStart <= 0) {
                runNode();
            }
        }

        for (i in items) {
            i.tick(dt);
        }

        if (onWaitNode) {
            waitTime -= dt;
            if (waitTime < 0) {
                onWaitNode = false;
                waitTime = 0;
                jumpToNextNode();
            }
        }
    }

    override function sync(ctx:RenderContext) {
        this.x = Math.floor((game.screenWidth - maxWidth) * 0.3);
        this.y = Math.floor((game.screenHeight - bg.height) * 0.75);
        realignItems();
        super.sync(ctx);
    }

    var scriptContext : hscript.Interp;

    override function onAdd() {
        super.onAdd();
    }

    override function onRemove() {
        super.onRemove();
    }

    function getNodeById(id : String, el : Xml = null) {
        if (el == null) el = tree;
        for (e in el.elements()) {
            if (e.nodeType != Element) {
                continue;
            }

            if (e.exists("id") && e.get("id") == id) {
                return e;
            }
            var childFind = getNodeById(id, e);
            if (childFind != null) {
                return childFind;
            }
        }

        return null;
    }

    inline function nodeCond(node : Xml) {
        if (node.nodeType != Element) {
            return true;
        }

        if (!node.exists("condition")) {
            return true;
        }

        var cond = node.get("condition");
        return game.scripts.runScript(cond, scriptContext);
    }

    function messageFinished() {
        jumpToNextNode();
    }

    function onChoiceSelect(index : Int) {
        var i = 0;

        var chosenNode = null;
        for (el in current.elementsNamed("choice")) {
            if (i == index) {
                chosenNode = el;
                break;
            }
            i++;
        }

        if (chosenNode != null) {
            current = chosenNode.firstElement();
            runNode();
            return;
        }
        
        game.console.log("Dialogue error on node" + current);

        jumpToNextNode();
    }


    public function onNavigate(direction : Direction, justPressed) : Void {
        if (justAdded) return;
        var i = items[items.length - 1];
        if (i != null) {
            i.onNavigate(direction);
        }

        scrollBack = 0;
    }

    var scrollSpeed = 20.;
    public function doAction(action : DialogAction, justPressed) : Void {
        if (justAdded || !justPressed || onWaitNode) return;

        if (action == ScrollUp) {
            scrollBack += scrollSpeed;
            var h = itemsContainer.getBounds().height + marginY;
            if (h < maxHeight) {
                scrollBack = 0;
            } else {
                scrollBack = Math.min(scrollBack, h - maxHeight);
            }
        } else if (action == ScrollDown) {
            scrollBack -= scrollSpeed;
            if (scrollBack < 0) scrollBack = 0;
        } else {
            scrollBack = 0;
        }

        var i = items[items.length - 1];
        if (i != null) {
            i.onUIAction(action);
        }
    }

    function runNode() {
        var lastIfWasFalse = this.lastIfWasFalse;
        if (!nodeCond(current)) {
            jumpToNextNode();
        }

        switch (current.nodeName) {
            case "say":
                items.push(new MessageSay(current, talker, messageFinished, itemsContainer, this));
            case "choices":
                var choices = extractChoices(current);
                items.push(new MessageChoices(choices, onChoiceSelect, itemsContainer));
            case "end":
                endDialogue();
                return;
            case "jump":
                var node = getNodeById(current.get("to"));
                if (node == null) {
                    endDialogue();
                    trace("Could not find node named " + current.get("to"));
                    return;
                }
                current = node;
                runNode();
            case "if":
                var isTrue = true;

                if (current.exists("flag") && current.exists("value")) {
                    var flag = current.get("flag");
                    var value = current.get("value");
                    var f = "" + game.db.flags.get(flag);
                    if (f == "null") {
                        f = "false";
                    }
                    if (f != value) {
                        isTrue = false;
                    }
                }

                if (isTrue) {
                    current = current.firstElement();
                    runNode();
                    this.lastIfWasFalse = false;
                } else {
                    this.lastIfWasFalse = true;
                    jumpToNextNode();
                }
                /*
            case "set":
                var flag = current.get("flag");
                var value = current.get("value");
                if (value == null) {
                    value = current.get("to");
                }
                if (value == "true") {
                    game.db.flags.set(flag, true);
                } else if (value == "false") {
                    game.db.flags.set(flag, false);
                } else {
                    game.db.flags.set(flag, value);
                }
                jumpToNextNode();
            case "script":
                game.scripts.runScript(current.firstChild().nodeValue, scriptContext);
                jumpToNextNode();
                */
            case "wait":
                onWaitNode = true;
                var wTime = Std.parseFloat(current.get("time"));
                if (wTime != Math.NaN)
                    waitTime = wTime;
                else 
                    wTime = 0.01;
                return;
            case "else":
                if (lastIfWasFalse) {
                    current = current.firstElement();
                    runNode();
                } else {
                    jumpToNextNode();
                }
        }
        realignItems();
    }

    var sy = 0.;
    function realignItems() {
        var b = itemsContainer.getBounds();
        //if (b.height > maxHeight) {
        //} else {
            //sy = maxHeight - b.height;
        //}
        sy += ((Std.int(bg.height - marginY) - b.height) - sy) * 0.3;
        var y = sy + scrollBack;
        for (i in items) {
            i.y = y;
            y += i.getBounds().height + 6;
            i.alpha = 1.0 - Math.max(-i.y / 70, 0.0);
        }
    }

    function extractChoices(node : Xml) {
        var choices = [];
        var index = 0;

        for (c in node.elementsNamed("choice")) {
            if (nodeCond(c)) {
                choices.push({ text: c.get("msg"), id: index });
            }

            index ++;
        }

        return choices;
    }

    function endDialogue() {
        this.remove();
    }

    override function draw(ctx:RenderContext) {
        this.clipBounds(ctx, bg.getBounds(this));
        bg.height = Math.floor(Math.min(
            9999.0,
            //itemsContainer.getBounds().height,
            maxHeight) + marginY * 2);
        super.draw(ctx);
    }

    function jumpToNextNode() {
        var p : Xml = current.parent;
        var child = current;

        while(p != null && p.nodeType != Element && nonParentable.contains(p.nodeName)) {
            child = p;
            p = p.parent;
        }

        while (nonParentable.contains(child.nodeName)) {
            child = child.parent;
            p = child.parent;
        }

        if (p == null) {
            endDialogue();
            return;
        }

        var found = false;
        var next : Xml = null;
        for (el in p.elements()) {
            if (found) {
                next = el;
                break;
            }
            if (el == child) {
                found = true;
            }
        }

        if (next != null) {
            current = next;
            runNode();
        } else {
            // if no next node found in current branch, jump up one level unless we're at
            // Document level. If that's the case we've reached the end of the dialogue
            if (p.parent.nodeType != Document) {
                current = p;
                jumpToNextNode();
            } else {
                endDialogue();
            }
        }
    }
}
