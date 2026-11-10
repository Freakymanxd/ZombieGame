class_name WeaponHolder
extends Node

const BULLET_SCENE: PackedScene = preload("res://scenes/bullet.tscn")

@export var weapon: WeaponData

var ammo: int = 0

var _cooldown: float = 0.0
var _reload_left: float = 0.0
var _player: Player


func _ready() -> void:
	_player = get_parent() as Player
	equip(weapon)


func equip(new_weapon: WeaponData) -> void:
	weapon = new_weapon
	ammo = weapon.magazine_size
	_cooldown = 0.0
	_reload_left = 0.0
	EventBus.weapon_changed.emit(weapon.weapon_name)
	EventBus.ammo_changed.emit(ammo, weapon.magazine_size)


func _physics_process(delta: float) -> void:
	if GameState.is_game_over:
		return
	_cooldown = maxf(_cooldown - delta, 0.0)

	if _reload_left > 0.0:
		_reload_left -= delta
		if _reload_left <= 0.0:
			ammo = weapon.magazine_size
			EventBus.ammo_changed.emit(ammo, weapon.magazine_size)
		return

	if Input.is_action_just_pressed("reload"):
		start_reload()
		return

	var wants_fire: bool = false
	if weapon.automatic:
		wants_fire = Input.is_action_pressed("fire")
	else:
		wants_fire = Input.is_action_just_pressed("fire")
	if wants_fire:
		_try_fire()


func start_reload() -> void:
	if _reload_left > 0.0 or ammo == weapon.magazine_size:
		return
	_reload_left = weapon.reload_time


func _try_fire() -> void:
	if _cooldown > 0.0:
		return
	if ammo <= 0:
		start_reload()
		return
	ammo -= 1
	_cooldown = 1.0 / weapon.fire_rate
	_spawn_bullet()
	EventBus.ammo_changed.emit(ammo, weapon.magazine_size)
	if ammo == 0:
		start_reload()


func _spawn_bullet() -> void:
	_player.register_shot()
	var bullet: Bullet = BULLET_SCENE.instantiate()
	bullet.direction = _player.aim_vector
	bullet.speed = weapon.bullet_speed
	bullet.damage = weapon.damage
	
	bullet.max_distance = weapon.bullet_range
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = _player.global_position + _player.center_offset + _player.aim_vector * 24.0
