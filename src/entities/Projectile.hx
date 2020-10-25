package entities;

import h3d.scene.Object;
import elke.Game;
import elke.entity.Entity3D;
import h3d.col.Point;
import h3d.scene.Graphics;

class Projectile extends Entity3D {
    var p : Graphics;
    var startPos: Point;
    var direction: Point;
    var endPos :Point;
    public function new(?parent, pos, dir) {
        super(parent);
        startPos = pos;
        direction = dir;
        endPos = pos.clone();

        dir.normalize();

        p = new Graphics(this);
        muzzleFlash = Game.instance.modelCache.loadModel(hxd.Res.models.muzzleflare);

        addChild(muzzleFlash);
        for (m in muzzleFlash.getMaterials()) {
            m.textureShader.killAlpha = true;
            m.castShadows = false;
            m.mainPass.culling = None;
        }

        muzzleFlash.setPosition(pos.x, pos.y, pos.z);
        muzzleFlash.setDirection(dir.toVector());
    }

    var muzzleFlash: Object;

    var d = 0.02;


    override function update(dt:Float) {
        super.update(dt);
        if (muzzleFlash != null) {
            d -= dt;
            if (d <= 0) {
                muzzleFlash.remove();
                muzzleFlash = null;
            }
        }

        var s = 1;

        endPos.x += direction.x * s;
        endPos.y += direction.y * s;
        endPos.z += direction.z * s;

        p.clear();
        p.lineStyle(2, 0xFFFFFF);
        var p2 = endPos.clone();
        p2.x -= direction.x;
        p2.y -= direction.y;
        p2.z -= direction.z;
        p.drawLine(p2, endPos);
    }
}
