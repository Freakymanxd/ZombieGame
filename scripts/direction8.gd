class_name Direction8
extends RefCounted

# Screen-space compass names. Index 0 = east, clockwise on screen.
const NAMES: Array[String] = ["e", "se", "s", "sw", "w", "nw", "n", "ne"]

# Pass the raw joystick/aim vector, before any isometric Y scaling.
static func name_from_vector(v: Vector2) -> String:
	if v == Vector2.ZERO:
		return ""
	var index: int = int(round(v.angle() / (TAU / 8.0)))
	return NAMES[posmod(index, 8)]
