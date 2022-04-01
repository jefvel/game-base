package elke.graphics;

class SineDeformShader extends hxsl.Shader {
    static var SRC = {
        @:import h3d.shader.Base2d;
        
        @param var texture : Sampler2D;
        @param var speed : Float;
        @param var frequency : Float;
        @param var amplitude : Float;
        
        function fragment() {
            calculatedUV.y += sin(calculatedUV.y * frequency + time * speed) * amplitude; // wave deform
            pixelColor = texture.get(calculatedUV);
        }
    }
}