# Heaps Turbo Game Base

A very barebones heaps game template.

Some current features:

* Possibility to set 2d pixel size for the screen.

* A HTML template file that gets exported along with the js output. Build and zip it

* The release JS build uses the Google closure js minifier.

* Automatic aseprite file tilesheet generation. (Generates a png plus a .tilesheet file)

* The .tilesheet file can be accessed using the resource system:

```haxe
hxd.Res.img.testcharacter_tilesheet.toSprite(); // Creates a h2d.Bitmap type object with animation support
hxd.Res.img.testcharacter_tilesheet.toSprite3D(); // Creates a 3D billboard type mesh for h3d.
```
