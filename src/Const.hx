import hxd.impl.UInt16;

class Const {
    // Pixel scaling for the 2d scene
	public static inline final PIXEL_SIZE = 2;

    // Pixels per unit, in 3d space
    public static inline final PIXEL_SIZE_WORLD = 32;
    public static inline final PPU = 1.0 / PIXEL_SIZE_WORLD;

	public static inline final TICK_RATE = 60;

    // change this to 
    public static inline final SAVE_NAMESPACE = haxe.macro.Compiler.getDefine("saveNamespace");
    // Newgrounds stuff
    public static inline final NEWGROUNDS_APP_ID = haxe.macro.Compiler.getDefine("newgroundsAppId");
    public static inline final NEWGROUNDS_ENCRYPTION_KEY_RC4 = haxe.macro.Compiler.getDefine("newgroundsEncryptionKey");
}