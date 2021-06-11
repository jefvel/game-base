package elke.buildutil;

import sys.io.File;
import sys.FileSystem;
import haxe.io.Path;

typedef AseLayerInfo = {
    name : String,
    group : String,
}

typedef AseOptions = {
    ?layers : Array<String>,
    ?hideLayers : Array<String>,
    ?padding : Null<Int>,
    ?sheet : Null<Bool>,
    ?trim : Null<Bool>,
}

class AsepriteConverter {
    static final defaultAsePath = "C:/Program Files/Aseprite/Aseprite.exe";
    static var asePath = defaultAsePath;
    static final ext = ".aseprite";
    static final loaders = "⠇⠏⠹⠸⠼⠧";
    function new() {
    }

    public static function doNothing() {}

    public static function exportTileSheets() {
        Sys.println("Generating assets...");
        var startTime = Sys.time();
        #if macro
        var def = haxe.macro.Context.definedValue("asepritePath");
        #else
        var def : String = null;
        #end

        if (def != null) {
            asePath = def;
        } else {
            switch (Sys.systemName()) {
                case "Windows": asePath = defaultAsePath;
                case "Mac": asePath = "/Applications/Aseprite.app/Contents/MacOS/aseprite";
                case "Linux": asePath = "aseprite";
                default: asePath = defaultAsePath;
            }
        }

        recursiveLook("res/");

        var duration = ("" + (Sys.time() - startTime)).substr(0, 4);

        Sys.println('\u001b[1A\u001b[2K\u001b[32mFinished\u001b[0m [${duration}s]');
    }

    static function recursiveLook(directory) {
        if (sys.FileSystem.exists(directory)) {
            var files = sys.FileSystem.readDirectory(directory);
            for (file in files) {
                if (file == ".tmp") continue;
                var path = haxe.io.Path.join([directory, file]);
                if (!sys.FileSystem.isDirectory(path)) {
                    if (StringTools.endsWith(path, ext)) {
                        var absolutePath = FileSystem.absolutePath(path);
                        var p = new Path(absolutePath);
                        var input = p.toString();

                        var output = input.substr(0, input.length - ext.length);

                        generateNormalAseFile(input, output);
                    }
                } else {
                    var directory = haxe.io.Path.addTrailingSlash(path);
                    recursiveLook(directory);
                }
            }
        }
    }

    static function generateNormalAseFile(aseFilePath : String, destPath : String) {
      var bytes = new haxe.io.BytesInput(sys.io.File.getBytes(aseFilePath));

      var size = bytes.readInt32();
      var num = bytes.readUInt16() == 0xA5E0;
      var frames = bytes.readUInt16();

      if (frames == 1) {
        convertAseFile(aseFilePath, destPath, { sheet: false });
      } else {
        convertAseFile(aseFilePath, destPath);
      }
    }

    static var l = 0;

    static function convertAseFile(filePath : String, destPath : String, ?options : AseOptions = null) {
        var spacing = 1;

        var input = '-b $filePath';
        var jsonOutput = '--data $destPath.tilesheet';
        var pngOutput = '--sheet $destPath.png';
        var format = '--format json-array';
        var type = '--sheet-type packed';
        var pack = '--sheet-pack';
        var listTags = '--list-tags';
        var padding = '--shape-padding $spacing';
		var trim = '--trim';
        var slices = '--list-slices';

        var ignoreLayers = '';
        var layers = '';

        if (options != null) {
            if (options.layers != null) {
                for (layer in options.layers) {
                    layers += ' --layer $layer';
                }
            }
            if (options.hideLayers != null) {
                for (layer in options.hideLayers) {
                    ignoreLayers += ' --ignore-layer $layer';
                }
            }
            if (options.sheet != null) {
              if (!options.sheet) {
                jsonOutput = '';
                pngOutput = '';
                input += ' --save-as $destPath.png';
                pack = '';
                listTags = '';
                trim = '';
                format = '';
                type = '';
              }
            }
        }

        var cmd = '"$asePath" $jsonOutput $pngOutput $format $type $pack $padding $slices $listTags $trim $layers $ignoreLayers';
        cmd += ' $input';

        l = ++l % loaders.length;
        Sys.println('\u001b[1A\u001b[2K\u001b[35m${loaders.charAt(l)}\u001b[0m Generating $destPath');
        Sys.command(cmd);
    }

    static function getAsepriteLayerData(aseFilePath : String) {
        var tmpFile = Sys.getCwd() + "tmp.tmp";
        var cmd = '"$asePath" -b --list-layers --all-layers $aseFilePath --data $tmpFile';
        Sys.command(cmd);
        var text = File.getContent(tmpFile).toString();
        var c : elke.graphics.AsepriteResource.AseFile = haxe.Json.parse(text);
        FileSystem.deleteFile(tmpFile);
        return c.meta.layers;
    }
}
