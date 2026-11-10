class_name SheetAnimations
extends RefCounted

const FRAME_SIZE: Vector2i = Vector2i(16, 24)
# Sheet columns, left to right.
const COLUMN_DIRECTIONS: Array[String] = ["n", "ne", "e", "se", "s", "sw", "w", "nw"]
const WALK_FPS: float = 8.0


# first_row = the sheet row of a character's first frame row.
# Zombie = 1, Player = 5, third character = 9.
static func build(texture: Texture2D, first_row: int) -> SpriteFrames:
	var frames: SpriteFrames = SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	for col in COLUMN_DIRECTIONS.size():
		var dir: String = COLUMN_DIRECTIONS[col]

		var idle_name: String = "idle_" + dir
		frames.add_animation(idle_name)
		frames.set_animation_loop(idle_name, true)
		frames.set_animation_speed(idle_name, 1.0)
		frames.add_frame(idle_name, _frame(texture, col, first_row + 1))

		var walk_name: String = "walk_" + dir
		frames.add_animation(walk_name)
		frames.set_animation_loop(walk_name, true)
		frames.set_animation_speed(walk_name, WALK_FPS)
		for r in [0, 1, 2, 1]:
			frames.add_frame(walk_name, _frame(texture, col, first_row + r))

	return frames


static func _frame(texture: Texture2D, col: int, row: int) -> AtlasTexture:
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(col * FRAME_SIZE.x, row * FRAME_SIZE.y, FRAME_SIZE.x, FRAME_SIZE.y)
	return atlas
