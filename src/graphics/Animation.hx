package graphics;

class Animation {
    public var tileSheet : TileSheetData;
    public var playing : Bool;
    public var looping : Bool;
    public var finished : Bool;

    public var currentFrame : Int = 0;
    public var currentAnimationName : String;

    var elapsedTime : Float;
    var totalElapsed : Float;

    public function new(tileSheet) {
        this.tileSheet = tileSheet;
    }

	public function play(?animation : String, ?loop : Bool = true, ?force = false, ?percentage = 0.0) {
		if (!force) {
			if (playing && animation == currentAnimationName && !finished) {
				return;
			}
        }

		currentFrame = 0;
		finished = false;
		looping = loop;
		elapsedTime = 0.0;
        totalElapsed = 0.0;
        
        var anim = tileSheet.getAnimation(animation);
        if (animation != null && anim == null) {
            //throw "Could not find animation " + animation + " in sheet " + tileSheet.name;
        } else if (anim != null) {
            currentFrame = anim.from;
        }

		currentAnimationName = animation;
		playing = true;

        if (percentage > 0 && percentage < 1.0) {
            if (anim == null) {
                elapsedTime = tileSheet.totalLength / 1000.0 * percentage;
            } else {
                elapsedTime = anim.totalLength / 1000.0 * percentage;
            }
            var f = getCurrentFrame();
            var s = 0;
            while (elapsedTime * 1000 >= f.duration) {
                elapsedTime -= f.duration / 1000.0;
                totalElapsed += f.duration / 1000.0;
                currentFrame ++;
                f = getCurrentFrame();
                s ++;
            }
        }
    }

    inline function getCurrentFrame() {
		return tileSheet.frames[currentFrame];
    }

	public function getCurrentTile() : h2d.Tile {
        return getCurrentFrame().tile;
    }

    public inline function getCurrentAnimation() {
        return this.tileSheet.getAnimation(currentAnimationName);
    }

    // Returns value between 0 - 1 of animation progress
    public function animationProgress() : Float {
        var anim = tileSheet.getAnimation(currentAnimationName);
        return (totalElapsed * 1000) / anim.totalLength;
    }

	public function stop() {
        playing = false;
        var a = getCurrentAnimation();
        if (a == null) {
            currentFrame = 0;
        } else {
            currentFrame = a.from;
        }
	}

	public function pause() {
		playing = false;
	}

	public function update(dt : Float) {
        if (!playing) {
            return;
        }

		var anim = tileSheet.getAnimation(currentAnimationName);

        var from = 0;
        var to = tileSheet.frames.length - 1;

        if (anim != null) {
            from = anim.from;
            to = anim.to;
        }

		var frame = tileSheet.frames[currentFrame];

		elapsedTime += dt;
        totalElapsed += dt;

		if (elapsedTime * 1000 > frame.duration) {
			elapsedTime -= frame.duration / 1000.0;

			currentFrame++;

			if (looping) {
                if (currentFrame > to) {
                    currentFrame = from;
                }
			} else {
				if (currentFrame > to) {
                    currentFrame = to - 1;
					finished = true;
				}
			}
		}
	}
}