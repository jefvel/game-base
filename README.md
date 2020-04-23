# Heaps Turbo Game Base

A very barebones heaps game template, a bit inspired by https://github.com/deepnight/gameBase

and https://github.com/Yanrishatum/heeps (based my 3D sprite implementation on the one that exists here).

Some current features:

* Possibility to set 2D pixel size for the screen.

* Extremely simple entity system with fixed timestep updates.

* A HTML template file that gets exported along with the js output. Build and zip it and you're done.

* The release JS build uses the Google closure js minifier.

* Automatic aseprite file tilesheet generation. (Generates a png plus a .tilesheet file)

* The .tilesheet file can be accessed using the resource system:

```haxe
hxd.Res.img.testcharacter_tilesheet.toSprite(); // Creates a h2d.Bitmap type object with animation support
hxd.Res.img.testcharacter_tilesheet.toSprite3D(); // Creates a 3D billboard type mesh for h3d.
```

I will write more about this later
