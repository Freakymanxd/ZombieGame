class_name Zombie
extends CharacterBody2D

enum State { IDLE, CHASE }

const IDLE_CHECK_INTERVAL: float = 0.3

@export var sheet: Texture2D
@export var sheet_first_row: int = 1
@export var speed: float = 90.0
@export var damage: int = 10
@export var attack_range: float = 70.0
@export var attack_cooldown: float = 1.0
@export var score_value: int = 10
@export var aggro_radius: float = 1400.0

var _state: State = State.IDLE
var _target: Player
var _attack_timer: float = 0.0
var _check_timer: float = 0.0
var _dead: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health: HealthComponent = $Health


func _ready() -> void:
	add_to_group("zombies")
	sprite.sprite_frames = SheetAnimations.build(sheet, sheet_first_row)
	sprite.play("idle_" + Direction8.NAMES[randi() % 8])
	health.died.connect(_on_died)
	# Spread the idle checks over time so all zombies don't check on the same frame.
	_check_timer = randf() * IDLE_CHECK_INTERVAL


func _physics_process(delta: float) -> void:
	if _dead:
		return
	if _target == null or not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group("player") as Player
		if _target == null:
			return

	if _state == State.IDLE:
		_check_timer -= delta
		if _check_timer <= 0.0:
			_check_timer = IDLE_CHECK_INTERVAL
			var dist_sq: float = global_position.distance_squared_to(_target.global_position)
			if dist_sq <= aggro_radius * aggro_radius:
				_state = State.CHASE
		return

	_attack_timer = maxf(_attack_timer - delta, 0.0)
	var to_target: Vector2 = _target.global_position - global_position
	var ground_distance: float = Vector2(to_target.x, to_target.y / Player.ISO_Y_SCALE).length()
	var moving: bool = false

	if GameState.is_game_over:
		velocity = Vector2.ZERO
	elif ground_distance > attack_range:
		velocity = _to_iso_velocity(to_target.normalized())
		moving = true
	else:
		velocity = Vector2.ZERO
		if _attack_timer <= 0.0:
			_attack_timer = attack_cooldown
			_target.take_damage(damage)

	move_and_slide()
	_update_animation(to_target, moving)


func _to_iso_velocity(dir: Vector2) -> Vector2:
	var iso_factor: float = Vector2(dir.x, dir.y * Player.ISO_Y_SCALE).length()
	return dir * iso_factor * speed


func _update_animation(to_target: Vector2, moving: bool) -> void:
	var dir_name: String = Direction8.name_from_vector(to_target)
	if dir_name == "":
		return
	var prefix: String = "walk_" if moving else "idle_"
	var anim_name: String = prefix + dir_name
	if sprite.animation != anim_name:
		sprite.play(anim_name)


func take_damage(amount: int) -> void:
	if _dead:
		return
	# Being shot wakes a zombie up, even from outside the aggro radius.
	_state = State.CHASE
	health.take_damage(amount)
	if not _dead:
		_flash()


func _flash() -> void:
	sprite.modulate = Color(1.0, 0.4, 0.4)
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.12)


func _on_died() -> void:
	_dead = true
	remove_from_group("zombies")
	GameState.add_score(score_value)
	EventBus.zombie_killed.emit(global_position)
	$CollisionShape2D.set_deferred("disabled", true)
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)
	$Hurtbox/CollisionShape2D.set_deferred("disabled", true)
