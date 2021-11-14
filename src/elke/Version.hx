package elke;

macro function GetBuildID():haxe.macro.Expr.ExprOf<String> {
	#if !display
	var process = new sys.io.Process('git', ['rev-parse', 'HEAD']);
	if (process.exitCode() != 0) {
		var message = process.stderr.readAll().toString();
		var pos = haxe.macro.Context.currentPos();
		haxe.macro.Context.error("Cannot execute `git rev-parse HEAD`. " + message, pos);
	}

	// read the output of the process
	var commitHash:String = process.stdout.readLine();

	var buildTime = Date.now().toString().substr(0, 10);

	var str = '$buildTime - ${commitHash.substr(0, 8)}';

	// Generates a string expression
	return macro $v{str};
	#else
	// `#if display` is used for code completion. In this case returning an
	// empty string is good enough; We don't want to call git on every hint.
	var commitHash:String = "";
	return macro $v{commitHash.substr(0, 8)};
	#end
}
