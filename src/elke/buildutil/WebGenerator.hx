package elke.buildutil;

class WebGenerator {
	#if hscript
	static macro function generate() {
		var templates = [];
		function getRec(path) {
			for (f in sys.FileSystem.readDirectory(path)) {
				var file = path + "/" + f;
				if (sys.FileSystem.isDirectory(file)) {
					getRec(file);
					continue;
				}
				var tmpl = file.substr(10);
				templates.push({file: tmpl, data: sys.io.File.getContent(file)});
			}
		}
		getRec("templates");

		function val(name) {
			return haxe.macro.Context.definedValue(name);
		}

		final windowTitle = haxe.macro.Context.definedValue("windowTitle");
		final name = "web";

		var context = {
			windowTitle: val("windowTitle"),
			gameFile: "game.js",
			additionalCss: "",
			twitterSite: val("twitterSite"),
			twitterCreator: val("twitterCreator"),
			ogUrl: val("ogUrl"),
			ogDescription: val("ogDescription"),
			ogImage: val("ogImage"),
		};

		final fixedWindow = haxe.macro.Context.definedValue("windowFixed");

		if (fixedWindow != null) {
			final sizes = haxe.macro.Context.definedValue("windowSize");
			if (sizes == null) {
				throw "windowFixed defined without setting windowSize";
			}

			var wh = sizes.split("x");
			var width = wh[0];
			var height = wh[1];

			context.additionalCss += '
			<style>
                canvas#webgl { width: ${width}px !important; height: ${height}px !important; }
				body { display: flex; justify-content: center; align-items: center; }
			</style>
            ';
		}

		var templateableFiles = [".hx", ".html", ".css", ".js", ".json", ".txt"];
		var ignoredFiles = ["bullet.js"];

		var interp = new hscript.Interp();
		for (f in Reflect.fields(context))
			interp.variables.set(f, Reflect.field(context, f));
		for (t in templates) {
			var templateable = false;
			for (templateExtension in templateableFiles) {
				if (StringTools.endsWith(t.file, templateExtension)) {
					templateable = true;
					break;
				}
			}

			for (ignored in ignoredFiles) {
				if (t.file == ignored) {
					templateable = false;
					break;
				}
			}

			var data:String;
			if (templateable) {
				data = ~/::([^:]+)::/g.map(t.data, function(r) {
					var script = r.matched(1);
					var expr = new hscript.Parser().parseString(script);
					return "" + interp.execute(expr);
				});
			} else {
				data = t.data;
			}

			var file = t.file.split("__name").join(name);
			var dir = file.split("/");
			dir.pop();
			try
				sys.FileSystem.createDirectory("build/" + name + "/" + dir.join("/"))
			catch (e:Dynamic) {};
			sys.io.File.saveContent("build/" + name + "/" + file, data);
		}

		return null;
	}
	#end
}