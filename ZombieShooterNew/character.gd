extends AnimatedSprite2D

@export var animation_name: StringName = &"default"
## The frame number whose character is aiming straight RIGHT on screen
@export var right_facing_frame: int = 20
## Clockwise: frame numbers increase as the character turns right -> down -> left -> up
@export_enum("Clockwise:1", "Counter-clockwise:-1") var frame_direction: int = 1
## Local point the character aims from (relative to this sprite)
@export var pivot_offset: Vector2 = Vector2.ZERO
@export var debug_print: bool = false


func _ready() -> void:
	animation = animation_name
	stop()
	speed_scale = 0.0


func _process(_delta: float) -> void:
	var dir: Vector2 = get_global_mouse_position() - to_global(pivot_offset)
	if dir.length_squared() < 1.0:
		return

	# 0 = right, increasing clockwise on screen (Godot's Y points down)
	var angle_deg: float = fposmod(rad_to_deg(dir.angle()), 360.0)

	var frame_count: int = sprite_frames.get_frame_count(animation_name)
	var steps: int = roundi(angle_deg / 360.0 * frame_count)
	var index: int = posmod(right_facing_frame + steps * frame_direction, frame_count)
	frame = index

	if debug_print:
		print("angle %.1f -> frame %d" % [angle_deg, index])
