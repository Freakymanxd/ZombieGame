extends Node

# --- Assign these in the Inspector ---
@export var body: AnimatedSprite2D
@export var fire1: AnimatedSprite2D
@export var fire2: AnimatedSprite2D
@export var shot1: AudioStreamPlayer2D
@export var shot2: AudioStreamPlayer2D

# --- Must match your Body script ---
@export var right_facing_frame: int = 20
@export_enum("Clockwise:1", "Counter-clockwise:-1") var frame_direction: int = 1

# --- Tuning ---
@export var orbit_y_scale: float = 1.0
@export var flash_duration: float = 0.06
@export var pitch_variation: float = 0.08

## Body frame where you placed Fire1/Fire2 on the muzzles in the editor
@export var reference_frame: int = 0

## Tick to tune muzzle positions in-game (arrows = nudge, Shift = 5px, Tab = switch gun, Enter = print)
@export var calibrate: bool = false

# Paste the printed calibration results here {frame: Vector2}, relative to Body
var positions1: Dictionary = {}
var positions2: Dictionary = {}

var ref_offset: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var next_gun: int = 0
var flash_end: Array[float] = [0.0, 0.0]
var cal_gun: int = 0


func _ready() -> void:
	if body == null or fire1 == null or fire2 == null:
		push_error("Weapon: assign Body, Fire1 and Fire2 in the Inspector.")
		set_process(false)
		set_process_unhandled_input(false)
		return

	# Positions you placed in the editor become the starting muzzle positions
	ref_offset[0] = body.to_local(fire1.global_position)
	ref_offset[1] = body.to_local(fire2.global_position)

	for f in [fire1, fire2]:
		f.stop()
		f.speed_scale = 0.0
		f.visible = false


func _unhandled_input(event: InputEvent) -> void:
	# Alternate pistols on each left click
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		flash_end[next_gun] = _now() + flash_duration
		_play_shot(next_gun)
		next_gun = 1 - next_gun

	# Calibration controls
	if calibrate and event is InputEventKey and event.pressed and not event.echo:
		var step := 5.0 if event.shift_pressed else 1.0
		var nudge := Vector2.ZERO
		match event.keycode:
			KEY_LEFT: nudge = Vector2(-step, 0)
			KEY_RIGHT: nudge = Vector2(step, 0)
			KEY_UP: nudge = Vector2(0, -step)
			KEY_DOWN: nudge = Vector2(0, step)
			KEY_TAB:
				cal_gun = 1 - cal_gun
				print("Calibrating gun ", cal_gun + 1)
			KEY_ENTER:
				_print_table()
		if nudge != Vector2.ZERO:
			var table: Dictionary = positions1 if cal_gun == 0 else positions2
			table[body.frame] = _offset_for(cal_gun, body.frame) + nudge


func _process(_delta: float) -> void:
	_update_flash(fire1, 0)
	_update_flash(fire2, 1)


func _update_flash(flash: AnimatedSprite2D, gun: int) -> void:
	var is_on: bool = _now() < flash_end[gun] or (calibrate and cal_gun == gun)
	flash.visible = is_on
	if not is_on:
		return
	flash.frame = body.frame
	flash.global_position = body.to_global(_offset_for(gun, body.frame))


func _play_shot(gun: int) -> void:
	var player: AudioStreamPlayer2D = shot1 if gun == 0 else shot2
	if player == null:
		return
	player.global_position = (fire1 if gun == 0 else fire2).global_position
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	player.play()


# Recorded value if it exists, otherwise a smooth estimate
func _offset_for(gun: int, frame: int) -> Vector2:
	var table: Dictionary = positions1 if gun == 0 else positions2
	if table.has(frame):
		return table[frame]

	var base := _model_offset(gun, frame)
	if table.is_empty():
		return base

	# Blend the corrections of the nearest recorded frames on each side
	var count: int = body.sprite_frames.get_frame_count(body.animation)
	var prev_f := -1
	var next_f := -1
	var prev_d := 0
	var next_d := 0
	for d in range(1, count):
		if prev_f == -1 and table.has(posmod(frame - d, count)):
			prev_f = posmod(frame - d, count)
			prev_d = d
		if next_f == -1 and table.has(posmod(frame + d, count)):
			next_f = posmod(frame + d, count)
			next_d = d
		if prev_f != -1 and next_f != -1:
			break

	var prev_delta: Vector2 = table[prev_f] - _model_offset(gun, prev_f)
	var next_delta: Vector2 = table[next_f] - _model_offset(gun, next_f)
	var t: float = float(prev_d) / float(prev_d + next_d)
	return base + prev_delta.lerp(next_delta, t)


# Basic circular estimate from the editor-placed position
func _model_offset(gun: int, frame: int) -> Vector2:
	var count: int = body.sprite_frames.get_frame_count(body.animation)
	var ref_steps: int = posmod((reference_frame - right_facing_frame) * frame_direction, count)
	var steps: int = posmod((frame - right_facing_frame) * frame_direction, count)
	var turn: float = (steps - ref_steps) * TAU / count

	var v: Vector2 = ref_offset[gun]
	v.y /= orbit_y_scale
	v = v.rotated(turn)
	v.y *= orbit_y_scale
	return v


func _print_table() -> void:
	var table: Dictionary = positions1 if cal_gun == 0 else positions2
	var keys := table.keys()
	keys.sort()
	var text := "var positions%d: Dictionary = {" % (cal_gun + 1)
	for k in keys:
		var v: Vector2 = table[k]
		text += "%d: Vector2(%.0f, %.0f), " % [k, v.x, v.y]
	text += "}"
	print(text)


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
