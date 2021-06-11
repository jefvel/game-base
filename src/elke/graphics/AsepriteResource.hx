package elke.graphics;

typedef AseFrameData = {
	x:Int,
	y:Int,
	w:Int,
	h:Int,
	duration:Int
}

typedef AseFrame = {
	frame : AseFrameData,
	spriteSourceSize : AseFrameData,
	sourceSize : AseSize,
	duration : Int
}

typedef AseSize = {
	w:Int,
	h:Int
}

typedef AseBound = {
	w: Int,
	h: Int,
	x: Int,
	y: Int,
}

typedef AseAnimation = {
	name:String,
	from:Int,
	to:Int,
	totalLength:Int,
	looping:Bool,
	linearSpeed:Bool,
	frameDuration:Int
}

typedef AseLayer = {
	name : String,
	opacity : Int,
	group : String,
	blendMode : String,
}

typedef AseSlice = {
	name: String,
	color: String,
	keys: Array<AseSliceKey>,
}

typedef AseSliceKey = {
	frame: Int,
	bounds: AseBound,
}

typedef AseMeta = {
	frameTags : Array<AseAnimation>,
	size : AseSize,
	scale : Float,
	layers : Array<AseLayer>,
	slices: Array<AseSlice>,
}

typedef AseFile = {
	frames : Array<AseFrame>,
	meta : AseMeta
}
