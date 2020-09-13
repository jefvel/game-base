package;

/**
 * transitions
 */
class T {
    public static inline function smoothstep(from : Float, to : Float, x : Float) {
        x = clamp((x - from) / (to - from), 0., 1.);
        return x * x * (3. - 2. * x);
    }

    public static inline function smootherstep(from : Float, to : Float, x : Float) {
        x = clamp((x - from) / (to - from), 0., 1.);
        return x * x * x * (x * (x * 6. - 15.) + 10.);
    }

    public static inline function tickLerp(from : Float, to : Float, sharpness = 0.3, dt = Const.TICK_TIME) {
        var d = to - from;
        var s = sharpness;
        if (dt != Const.TICK_TIME) 
            s = 1.0 - Math.pow(1.0 - sharpness, dt / Const.TICK_TIME);

        return from + d * s;
    }

    public static inline function clamp(x : Float, lower, upper) {
        if (x < lower) return lower;
        if (x > upper) return upper;
        return x;
    }
}