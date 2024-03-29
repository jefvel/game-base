package elke.graphics;

import h2d.Tile;
import elke.res.TileSheetRes;

typedef AnimationEvent = {
	frame:Int,
	type:String,
	name:String,
}

class Animation {
	public var tileSheet:TileSheetRes;
	public var playing:Bool;
	public var looping:Bool;
	public var finished:Bool;

	public var currentFrame:Int = 0;
	public var currentAnimationName:AnimationId;

	var elapsedTime:Float;
	var totalElapsed:Float;

	public var events:Array<AnimationEvent>;

	public var animationSpeed = 1.0;

	var onFinish : String -> Void;

	public function new(tileSheet) {
		this.tileSheet = tileSheet;
		events = [];
	}

	public function play(?animation:AnimationId, ?loop:Bool = true, ?force = false, ?percentage = 0.0, ?onFinish: String->Void) {
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

		this.onFinish = onFinish;

		var anim = tileSheet.getAnimation(animation);
		if (animation != null && anim == null) {
			// throw "Could not find animation " + animation + " in sheet " + tileSheet.name;
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
				currentFrame++;
				f = getCurrentFrame();
				s++;
			}
		}
	}
	
	/**
	 * Returns the starting frame of a tag
	 * @param tag 
	 */
	public function getFrameByTagName(tag: String) {
		var t = tileSheet.getAnimation(tag);
		if (t == null) {
			return null;
		}

		return tileSheet.frames[t.from];
	}

	public function getTilesByTagName(tag): Array<Tile> {
		var t = tileSheet.getAnimation(tag);
		if (t == null) {
			return null;
		}

		var res = [];
		for (i in t.from...t.to + 1) {
			res.push(tileSheet.frames[i].tile);
		}

		return res;
	}

	public function getSlice(name: String) {
		var f = getCurrentFrame();
		if (f.slices == null) {
			return null;
		}

		return f.slices[name];

		/*
		var s = tileSheet.slices[name];
		if (s == null) {
			return null;
		}

		for (k in s.keys) {
			if (k.frame == currentFrame) {
				return k.bounds;
			}
		}

		return null;
		*/
	}

	public function frameCount() {
		return tileSheet.frames.length;
	}

	public function getCurrentFrame() {
		return tileSheet.frames[currentFrame];
	}

	public function getCurrentTile():h2d.Tile {
		return getCurrentFrame().tile;
	}

	public inline function getCurrentAnimation() {
		return this.tileSheet.getAnimation(currentAnimationName);
	}

	// Returns value between 0 - 1 of animation progress
	public function animationProgress():Float {
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

	public function unpause() {
		playing = true;
	}

	public function update(dt:Float) {
		if (!playing) {
			return;
		}

		if (Game.instance.paused) {
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

		elapsedTime += dt * animationSpeed;
		totalElapsed += dt * animationSpeed;

		if (elapsedTime * 1000 > frame.duration) {
			elapsedTime -= frame.duration / 1000.0;

			currentFrame++;

			if (looping) {
				if (currentFrame > to) {
					currentFrame = from;
				}
			} else {
				if (currentFrame > to) {
					currentFrame = to;
					finished = true;
					if (onFinish != null) {
						onFinish(currentAnimationName);
						onFinish = null;
					}
				}
			}
		}
	}
}