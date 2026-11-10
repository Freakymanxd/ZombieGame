class_name ZombieSpawner
extends Node

const ZOMBIE_SCENE: PackedScene = preload("res://Scenes/Zombie.tscn")
const WORLD_MASK: int = 4

# Where the spawner finds the map (change only if your node names differ).
@export var ground_layer_path: NodePath = ^"../Level/Ground"
@export var objects_path: NodePath = ^"../Level/Objects"
# Used only if the ground layer isn't found.
@export var fallback_area: Rect2 = Rect2(-3000, -1500, 6000, 3000)

# MAX ZOMBIES ALIVE AT ONCE. Spawning pauses while the count is at this limit.
@export var max_alive: int = 40
# How many zombies exist when the game starts.
@export var initial_count: int = 25

# Size of each burst (a "wave"), picked randomly between these two numbers.
@export var burst_min: int = 6
@export var burst_max: int = 10
# Seconds between zombies inside one burst.
@export var burst_spawn_gap_min: float = 0.3
@export var burst_spawn_gap_max: float = 0.9

# SECONDS OF REST BETWEEN WAVES, picked randomly between these two numbers.
@export var rest_time_min: float = 25.0
@export var rest_time_max: float = 40.0

# Spawn distances from the player, in pixels.
@export var min_distance_from_player: float = 950.0
@export var burst_max_distance: float = 1800.0

var _ground: TileMapLayer
var _objects: Node
var _cells: Array[Vector2i] = []
var _player: Node2D


func _ready() -> void:
	_ground = get_node_or_null(ground_layer_path) as TileMapLayer
	_objects = get_node_or_null(objects_path)
	if _objects == null:
		push_warning("ZombieSpawner: Objects node not found, spawning into the parent.")
		_objects = get_parent()
	if _ground != null:
		_cells = _ground.get_used_cells()
		print("ZombieSpawner: using ground layer with ", _cells.size(), " cells.")
	else:
		print("ZombieSpawner: ground layer not found, using fallback area.")
	_run()


func _run() -> void:
	# Wait two physics frames so every obstacle is registered in the physics world.
	await get_tree().physics_frame
	await get_tree().physics_frame
	_player = get_tree().get_first_node_in_group("player") as Node2D
	if _player == null:
		push_warning("ZombieSpawner: no player found.")
		return

	for i in mini(initial_count, max_alive):
		_spawn_one(false)

	# A burst only starts if there is room for at least a minimum-size burst.
	var room_needed: int = mini(burst_min, max_alive)
	while not GameState.is_game_over:
		if _alive_count() > max_alive - room_needed:
			await get_tree().create_timer(5.0).timeout
			continue
		await _spawn_burst()
		await get_tree().create_timer(randf_range(rest_time_min, rest_time_max)).timeout


func _spawn_burst() -> void:
	var wanted: int = randi_range(burst_min, burst_max)
	for i in wanted:
		if GameState.is_game_over or _alive_count() >= max_alive:
			return
		_spawn_one(true)
		await get_tree().create_timer(randf_range(burst_spawn_gap_min, burst_spawn_gap_max)).timeout


func _alive_count() -> int:
	return get_tree().get_nodes_in_group("zombies").size()


func _spawn_one(near_player: bool) -> void:
	var zombie: Zombie = ZOMBIE_SCENE.instantiate()
	_objects.add_child(zombie)
	zombie.global_position = _pick_point(near_player)


func _pick_point(near_player: bool) -> Vector2:
	var player_pos: Vector2 = _player.global_position
	var farthest: Vector2 = _random_point()
	var farthest_dist: float = farthest.distance_to(player_pos)

	for i in 40:
		var p: Vector2 = _random_point()
		var d: float = p.distance_to(player_pos)
		if d > farthest_dist and _is_free(p):
			farthest = p
			farthest_dist = d
		if d < min_distance_from_player:
			continue
		if near_player and d > burst_max_distance:
			continue
		if not _is_free(p):
			continue
		return p
	return farthest


func _random_point() -> Vector2:
	if _ground != null and not _cells.is_empty():
		var cell: Vector2i = _cells[randi() % _cells.size()]
		return _ground.to_global(_ground.map_to_local(cell))
	return Vector2(
		randf_range(fallback_area.position.x, fallback_area.end.x),
		randf_range(fallback_area.position.y, fallback_area.end.y)
	)


# True if no obstacle (trees, cars, solid tiles) covers this point.
func _is_free(p: Vector2) -> bool:
	var query: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
	query.position = p
	query.collision_mask = WORLD_MASK
	var hits: Array[Dictionary] = get_viewport().world_2d.direct_space_state.intersect_point(query, 1)
	return hits.is_empty()
