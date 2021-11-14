package elke.graphics;

class WobbleShader extends hxsl.Shader {
    static var SRC = {
        @:import h3d.shader.Base2d;
        
        @param var texture : Sampler2D;
        @param var speed : Float;
        @param var frequency : Float;
        @param var amplitude : Float;
		@param var offset : Float;
        
        function fragment() {
            calculatedUV.x += sin(calculatedUV.y * frequency + time * speed + offset) * amplitude; // wave deform
			if (calculatedUV.x < 0 || calculatedUV.x > 1) discard;
            calculatedUV.y += cos(calculatedUV.y * frequency + time * speed + offset) * amplitude; // wave deform
            pixelColor = texture.get(calculatedUV);
        }
    }
}