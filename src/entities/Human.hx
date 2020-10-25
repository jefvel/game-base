package entities;

import h3d.Matrix;
import h3d.col.Point;
import h3d.anim.Animation;
import h3d.anim.SimpleBlend;
import hxd.Key;
import h3d.scene.RenderContext;
import elke.graphics.Sprite3D;
import elke.Game;
import h3d.scene.Object;
import elke.entity.Entity3D;

enum abstract BodyPartName(String) to String {
	var Head = "Head";
	var Body = "Body";
	var Hip = "Hip";
	// Left side
	var LeftForearm = "Forearm.Left";
	var LeftUpperArm = "Upperarm.Left";
	var LeftHand = "Hand.Left";
	var LeftThigh = "Thigh.Left";
	var LeftShin = "Shin.Left";
	var LeftFoot = "Foot.Left";
	// Right side
	var RightForearm = "Forearm.Right";
	var RightUpperArm = "Upperarm.Right";
	var RightHand = "Hand.Right";
	var RightThigh = "Thigh.Right";
	var RightShin = "Shin.Right";
	var RightFoot = "Foot.Right";
	var Hat = "Hat";
	var ShoulderItem1 = "ShoulderItem1";
	var ShoulderItem2 = "ShoulderItem2";
	var Pocket1 = "Pocket1";
	var Pocket2 = "Pocket2";
	var RightHandItem = "HandItem.Right";
	var LeftHandItem = "HandItem.Left";
}

class Human extends Entity3D {
	var bones:Object;

	var headSprite:Sprite3D;
	var torsoSprite:Sprite3D;
	var ual:Sprite3D;

	var itemSprites:Array<Sprite3D>;
	var hatSprite:Sprite3D;

	public function new(?parent) {
		super(parent);
		bones = Game.instance.modelCache.loadModel(hxd.Res.models.human);
		itemSprites = [];

		addChild(bones);

		var anims = ["Human|Idle", "Human|Sit", "Human|Walk"];

		// var animName = anims[Std.int(Math.random() * anims.length)];
		// var anim = Game.instance.modelCache.loadAnimation(hxd.Res.models.human, animName);

		for (m in bones.getMaterials()) {
			m.shadows = false;
		}

		// bones.playAnimation(anim);
		// bones.currentAnimation.setFrame(anim.frameCount * Math.random());

		headSprite = hxd.Res.img.head_tilesheet.toSprite3D(this);
		headSprite.animation.play("Idle");
		headSprite.originX = 7;
		headSprite.originY = 16;
		attachPart(headSprite, Head);

		var leftHand = new Sprite3D(hxd.Res.img.hand.toTile(), this);
		leftHand.originX = leftHand.originY = 1;
		attachPart(leftHand, LeftHand);

		var rightHand = new Sprite3D(leftHand.tile, this);
		rightHand.originX = leftHand.originY = 1;
		attachPart(rightHand, RightHand);

		torsoSprite = new Sprite3D(hxd.Res.img.torso.toTile(), this);
		torsoSprite.originX = 8;
		torsoSprite.originY = 1;
		attachPart(torsoSprite, Body);

		var shotgun = new Sprite3D(hxd.Res.img.shotgun.toTile(), this);
		shotgun.originX = 6;
		shotgun.originY = 3;
		shotgun.faceCamX = shotgun.faceCamY = true;
		shotgun.rotation = -Math.PI * 0.5;
		attachPart(shotgun, ShoulderItem1);

		if (true) {
			var pistol = hxd.Res.img.pistol_tilesheet.toSprite3D(this);
			pistol.originX = 2;
			pistol.originY = 5;
			// attachPart(pistol, Pocket1);
			pistol.rotation = -Math.PI * 0.5;
			// itemSprites.push(pistol);
			// attachPart(pistol, Pocket1);
			// holdItem = pistol;
			equipItem(pistol);
		}

		// itemSprites.push(shotgun);

		var hats = [null, hxd.Res.img.crown, hxd.Res.img.hat];
		var hat = hats[Std.int(Math.random() * hats.length)];

		if (Math.random() > 0.) {
			var shotgun = new Sprite3D(hxd.Res.img.kalash.toTile(), this);
			shotgun.originX = 4;
			shotgun.originY = 8;
			attachPart(shotgun, ShoulderItem2);
			itemSprites.push(shotgun);
		}

		if (hat != null) {
			var crown = new Sprite3D(hat.toTile(), this);
			crown.originX = 8;
			crown.originY = 19;
			attachPart(crown, Hat);
			hatSprite = crown;
		}
	}

	public function shoot() {
		if (!aiming) {
			return;
		}

		var pos = bones.getObjectByName(RightHand).getAbsPos().getPosition().toPoint();
		var dir = new Point(-Math.cos(rotation), -Math.sin(rotation), 0);
		dir.normalize();
		var o = 0.05;

		pos.x += dir.x * 0.15;
		pos.y += dir.y * 0.15;
		pos.z += dir.z * 0.15;
		pos.z += 0.04;

		dir.x += Math.random() * o * 2 - o;
		dir.y += Math.random() * o * 2 - o;
		dir.z += Math.random() * o * 2 - o;
		var proj = new Projectile(parent, pos, dir);
	}

	function equipItem(item:Sprite3D) {
		attachPart(item, RightHandItem);
		holdItem = item;
	}

	public var rotation = 0.0;

	function attachPart(part:Object, name:BodyPartName) {
		var p = bones.getObjectByName(name);
		if (p == null) {
			return;
		}
		part.followPositionOnly = true;
		part.follow = p;
	}

	var holdItem:Sprite3D;

	override function sync(ctx:RenderContext) {
		super.sync(ctx);
		var rot = Math.PI * 0.5 + rotation;
		setRotationAxis(0, 0, 1, rot);

		// rotation += ctx.elapsedTime; // var p = ctx.camera.getViewDirection(1, 0, 0);
		var p = ctx.camera.getViewDirection(-Math.sin(rot), Math.cos(rot), 0);
		headSprite.flipX = p.x < 0;
		if (hatSprite != null) {
			hatSprite.flipX = headSprite.flipX;
		}

		torsoSprite.flipX = p.y < 0;

		if (holdItem != null) {
			holdItem.flipX = p.x < 0;
			if (aiming) {
				if (p.z < -0.7)
					holdItem.animation.play("Front");
				else if (p.z > 0.7)
					holdItem.animation.play("Back");
				else
					holdItem.animation.play("Side");
			} else {
				holdItem.animation.play("Side");
			}
		}

		for (s in itemSprites) {
			s.flipX = !torsoSprite.flipX;
		}

		if (p.z > 0.01) {
			headSprite.animation.play("IdleBehind");
		} else {
			if (aiming) {
				headSprite.animation.play("Aim");
			} else {
				headSprite.animation.play("Idle");
			}
		}
	}

	var b:SimpleBlend;

	var vx = 0.;
	var vy = 0.;

	public var aiming = false;

	var ax = 0.;
	var ay = 0.;

	override function update(dt:Float) {
		super.update(dt);
		var dx = getScene().camera.getViewDirection(1, 0, 0);
		var dy = getScene().camera.getViewDirection(0, 1, 0);

		if (Key.isDown(Key.A)) {
			vx = -1.;
		}
		if (Key.isDown(Key.D)) {
			vx = 1.;
		}

		if (Key.isDown(Key.W)) {
			vy = 1.;
		}
		if (Key.isDown(Key.S)) {
			vy = -1.;
		}

		vx = Math.min(1.0, Math.max(-1, vx));
		vy = Math.min(1.0, Math.max(-1, vy));
		var crouching = hxd.Key.isDown(Key.CTRL);

		var speed = 0.03;
		if (crouching) {
			speed *= 0.4;
		}

		var mx = Math.max(Math.abs(vx), Math.abs(vy));

		ax += (vx - ax) * 0.2;
		ay += (vy - ay) * 0.2;
		ax = Math.min(1.0, Math.max(ax, -1));
		ay = Math.min(1.0, Math.max(ay, -1));

		x += dx.x * ax * speed;
		y += dx.z * ax * speed;

		x += dy.x * ay * speed;
		y += dy.z * ay * speed;

		var friction = 0.8;
		vx *= friction;
		vy *= friction;
		var walking = vx * vx + vy * vy > 0.1 * 0.1;

		aiming = hxd.Key.isDown(Key.MOUSE_RIGHT);
		if (aiming) {
			holdItem.rotation = 0;
		} else {
			holdItem.rotation = -Math.PI * 0.2;
		}

		if (crouching) {
			var anim = Game.instance.modelCache.loadAnimation(hxd.Res.models.human, "Human|Sit");
			if (walking) {
				anim = Game.instance.modelCache.loadAnimation(hxd.Res.models.human, "Human|CrouchWalk");
			}
			if (aiming) {
				var anim2 = Game.instance.modelCache.loadAnimation(hxd.Res.models.human, "Human|Aim");
				var objs = new Map<String, Bool>();
				objs[LeftUpperArm] = objs[RightUpperArm] = objs[RightForearm] = objs[LeftForearm] = true;
				b = new SimpleBlend(anim, anim2, objs);
				anim = b;
			}

			if (bones.currentAnimation == null || bones.currentAnimation.name != anim.name) {
				bones.playAnimation(anim);
				bones.currentAnimation.setFrame(anim.frameCount * Math.random());
			}
		} else {
			var anim:Animation = null;
			if (aiming) {
				anim = Game.instance.modelCache.loadAnimation(hxd.Res.models.human, "Human|Idle");
				if (walking) {
					anim = Game.instance.modelCache.loadAnimation(hxd.Res.models.human, "Human|Walk");
				}
				var anim2 = Game.instance.modelCache.loadAnimation(hxd.Res.models.human, "Human|Aim");
				var objs = new Map<String, Bool>();
				objs[LeftUpperArm] = objs[RightUpperArm] = objs[RightForearm] = objs[LeftForearm] = objs[Head] = true;
				b = new SimpleBlend(anim, anim2, objs);
				anim = b;
			} else {
				anim = Game.instance.modelCache.loadAnimation(hxd.Res.models.human, "Human|Idle");
				if (walking) {
					anim = Game.instance.modelCache.loadAnimation(hxd.Res.models.human, "Human|Walk");
				}
			}

			if (bones.currentAnimation == null || bones.currentAnimation.name != anim.name) {
				bones.playAnimation(anim);
			}
		}

		if (walking && !aiming) {
			var a = getScene().camera.getViewDirection(-vx, -vy, 0);
			rotation = Math.atan2(a.z, a.x);
		}
	}
}