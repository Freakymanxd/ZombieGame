extends CharacterBody2D

## Normal running speed
const SPEED := 500.0

## Speed while walking backwards
const BACK_SPEED := 400.0

## 1.0 = same speed in all directions, 0.5 = 2:1 isometric vertical squash.
@export var iso_y_scale: float = 1.0

## Seconds the legs wait (while idle) before turning to face the body.
@export var idle_correct_delay: float = 0.2

## How far apart (in 45° steps) legs and body must be before correcting while idle.
## 4 = only exactly opposite, 3 = also the two diagonals next to opposite.
@export_range(1, 4) var min_turn_steps: int = 3

## How far apart (in 45° steps) the movement and the body's aim must be to walk backwards.
## 4 = only exactly opposite, 3 = also the diagonals next to opposite.
@export_range(1, 4) var back_min_steps: int = 3

## false: run_back_X uses the direction the character FACES (the aim direction).
## true:  run_back_X uses the direction the character is MOVING.
@export var back_name_uses_move_direction: bool = false

## Point the body aims from, relative to this node (same as pivot_offset on the body script).
@export var body_pivot_offset: Vector2 = Vector2.ZERO

@onready var leg: AnimatedSprite2D = $Leg

# Order matches angle steps: 0 = E, then clockwise on screen
const DIRECTIONS: Array[String] = ["e", "se", "s", "sw", "w", "nw", "n", "ne"]

# Directions drawn by mirroring another one
const MIRROR := {
	"se": "sw",
	"ne": "nw",
	"e": "w",
}

# If an animation doesn't exist yet, try this direction instead
const FALLBACKS := {
	"nw": "n",
	"w": "sw",
}

var facing: String = "s"        # direction the legs face
var mismatch_time: float = 0.0  # how long legs have been idle and facing away from the body


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING


func _physics_process(delta: float) -> void:
	var input := Vector2(
		Input.get_axis("A", "D"),
		Input.get_axis("W", "S")
	)

	if input == Vector2.ZERO:
		velocity = Vector2.ZERO
		_auto_correct_legs(delta)
		_play("idle", facing)
	else:
		mismatch_time = 0.0
		input = input.normalized()

		var move_step: int = _angle_to_step(input.angle())
		var aim_step: int = _aim_step()

		var backwards := false
		if aim_step != -1:
			backwards = _step_diff(aim_step, move_step) >= back_min_steps

		var speed: float = SPEED
		if backwards:
			speed = BACK_SPEED
			# Legs face the body's direction while moving the other way
			facing = DIRECTIONS[aim_step]
			var anim_step: int = move_step if back_name_uses_move_direction else aim_step
			_play("run_back", DIRECTIONS[anim_step])
		else:
			facing = DIRECTIONS[move_step]
			_play("run", facing)

		velocity = Vector2(input.x, input.y * iso_y_scale) * speed

	move_and_slide()


func _auto_correct_legs(delta: float) -> void:
	var body_step: int = _aim_step()
	if body_step == -1:
		return

	var leg_step: int = DIRECTIONS.find(facing)
	if _step_diff(body_step, leg_step) >= min_turn_steps:
		mismatch_time += delta
		if mismatch_time >= idle_correct_delay:
			facing = DIRECTIONS[body_step]
			mismatch_time = 0.0
	else:
		mismatch_time = 0.0


# Direction (0..7) the body is aiming at, or -1 if the mouse is on top of the character
func _aim_step() -> int:
	var to_mouse: Vector2 = get_global_mouse_position() - to_global(body_pivot_offset)
	if to_mouse.length_squared() < 1.0:
		return -1
	return _angle_to_step(to_mouse.angle())


# Shortest distance between two direction steps, 0..4
func _step_diff(a: int, b: int) -> int:
	var d: int = posmod(a - b, 8)
	return mini(d, 8 - d)


func _angle_to_step(angle: float) -> int:
	return roundi(fposmod(angle, TAU) / (TAU / 8.0)) % 8


func _play(prefix: String, direction: String) -> void:
	var suffix := direction
	var flip := false

	if MIRROR.has(suffix):
		suffix = MIRROR[suffix]
		flip = true

	# Try the exact animation, then its fallback direction.
	# For run_back, also fall back to the normal run animation if it isn't drawn yet.
	var prefixes: Array[String] = [prefix]
	if prefix == "run_back":
		prefixes.append("run")

	var anim_name := ""
	var used_suffix := suffix
	for p in prefixes:
		var candidates: Array[String] = [suffix]
		if FALLBACKS.has(suffix):
			candidates.append(FALLBACKS[suffix])
		for s in candidates:
			if leg.sprite_frames.has_animation(p + "_" + s):
				anim_name = p + "_" + s
				used_suffix = s
				break
		if anim_name != "":
			break

	if anim_name == "":
		return

	# North and south are symmetrical, so they never need flipping
	leg.flip_h = flip and used_suffix != "n" and used_suffix != "s"

	if leg.animation != anim_name or not leg.is_playing():
		leg.play(anim_name)
