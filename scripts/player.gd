class_name Player
extends CharacterBody2D

enum MoveMode { MOUSE, WASD }

# Isometric tiles are about twice as wide as tall, so vertical speed is reduced.
const ISO_Y_SCALE: float = 0.5
const FLASH_SHADER_CODE: String = """
shader_type canvas_item;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	COLOR = vec4(mix(tex.rgb, vec3(1.0, 0.0, 0.0), flash), tex.a * COLOR.a);
}
"""

@export var move_mode: MoveMode = MoveMode.MOUSE
@export var speed: float = 220.0
@export var mouse_requires_button: bool = false
@export var dead_zone: float = 40.0
@export var full_speed_distance: float = 160.0
@export var shoot_face_time: float = 0.4
@export var center_offset: Vector2 = Vector2(0, -16)
@export var sheet: Texture2D
@export var sheet_first_row: int = 5
@export_group("Hit feedback")
@export var hit_stop_time: float = 0.15
@export var shake_strength: float = 14.0
@export var shake_time: float = 0.35
@export var flash_fade_time: float = 0.25

var move_vector: Vector2 = Vector2.ZERO
var aim_vector: Vector2 = Vector2.DOWN
var facing_name: String = "s"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health: HealthComponent = $Health
@onready var camera: Camera2D = $Camera2D
var _warned: Dictionary = {}
var _aim_timer: float = 0.0
var _flash_material: ShaderMaterial
var _flash_tween: Tween
var _freezing: bool = false
var _shake_left: float = 0.0
var _shake_total: float = 0.0
var _shake_power: float = 0.0

func _ready() -> void:
	add_to_group("player")
	var shader: Shader = Shader.new()
	shader.code = FLASH_SHADER_CODE
	_flash_material = ShaderMaterial.new()
	_flash_material.shader = shader
	sprite.material = _flash_material
	sprite.sprite_frames = SheetAnimations.build(sheet, sheet_first_row)
	sprite.play("idle_s")
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_died)
	EventBus.player_health_changed.emit(health.current_health, health.max_health)

func _process(delta: float) -> void:
	if _shake_left > 0.0:
		_shake_left -= delta
		var fade: float = clampf(_shake_left / _shake_total, 0.0, 1.0)
		camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_power * fade
		if _shake_left <= 0.0:
			camera.offset = Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	
	if event.is_action_pressed("toggle_move_mode"):
		if move_mode == MoveMode.MOUSE:
			move_mode = MoveMode.WASD
		else:
			move_mode = MoveMode.MOUSE
		print("Move mode: ", MoveMode.keys()[move_mode])


func _physics_process(delta: float) -> void:
	_aim_timer = maxf(_aim_timer - delta, 0.0)
	if GameState.is_game_over:
		velocity = Vector2.ZERO
		move_vector = Vector2.ZERO
		_update_animation()
		return
	var to_mouse: Vector2 = get_global_mouse_position() - (global_position + center_offset)
	if to_mouse != Vector2.ZERO:
		aim_vector = to_mouse.normalized()

	if move_mode == MoveMode.WASD:
		move_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	else:
		move_vector = _mouse_move_vector(to_mouse)

	velocity = _to_iso_velocity(move_vector)
	move_and_slide()
	_update_animation()


func _mouse_move_vector(to_mouse: Vector2) -> Vector2:
	if mouse_requires_button and not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		return Vector2.ZERO
	var distance: float = to_mouse.length()
	if distance < dead_zone:
		return Vector2.ZERO
	var strength: float = clampf((distance - dead_zone) / (full_speed_distance - dead_zone), 0.0, 1.0)
	return to_mouse.normalized() * strength


# Keeps the walking direction exactly as input, but slows vertical motion.
func _to_iso_velocity(v: Vector2) -> Vector2:
	if v == Vector2.ZERO:
		return Vector2.ZERO
	var dir: Vector2 = v.normalized()
	var iso_factor: float = Vector2(dir.x, dir.y * ISO_Y_SCALE).length()
	return v * iso_factor * speed


func _update_animation() -> void:
	var face_vector: Vector2 = Vector2.ZERO
	if _aim_timer > 0.0:
		face_vector = aim_vector
	elif move_vector != Vector2.ZERO:
		face_vector = move_vector
	if face_vector != Vector2.ZERO:
		facing_name = Direction8.name_from_vector(face_vector)
	var action: String = "walk" if move_vector != Vector2.ZERO else "idle"
	var anim_name: String = action + "_" + facing_name

	if sprite.sprite_frames.has_animation(anim_name):
		if sprite.animation != anim_name:
			sprite.play(anim_name)
	elif not _warned.has(anim_name):
		_warned[anim_name] = true
		push_warning("Missing animation: " + anim_name)
func take_damage(amount: int, heavy: bool = true) -> void:
	if GameState.is_game_over:
		return
	health.take_damage(amount)
	_hit_feedback(heavy)


func _hit_feedback(heavy: bool) -> void:
	_set_flash(1.0)
	if not heavy:
		_fade_flash(flash_fade_time * 0.5)
		return
	if _freezing:
		return
	_freezing = true
	var tree: SceneTree = get_tree()
	tree.paused = true
	await tree.create_timer(hit_stop_time, true, false, true).timeout
	tree.paused = false
	_freezing = false
	_shake_total = shake_time
	_shake_left = shake_time
	_shake_power = shake_strength
	_fade_flash(flash_fade_time)


func _set_flash(value: float) -> void:
	if _flash_tween != null:
		_flash_tween.kill()
	_flash_material.set_shader_parameter("flash", value)


func _fade_flash(duration: float) -> void:
	if GameState.is_game_over:
		return
	if _flash_tween != null:
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_property(_flash_material, "shader_parameter/flash", 0.0, duration)


func _on_health_changed(current: int, maximum: int) -> void:
	EventBus.player_health_changed.emit(current, maximum)


func _on_died() -> void:
	EventBus.player_died.emit()
	GameState.end_game()


func register_shot() -> void:
	_aim_timer = shoot_face_time
	
func heal(amount: int) -> void:
	health.heal(amount)
