class_name Pickup
extends Area2D

enum Kind { RESOURCE, HEALTH }

@export var kind: Kind = Kind.RESOURCE
@export var item_id: String = "scrap"
@export var display_name: String = "Scrap"
@export var amount: int = 1
@export var color: Color = Color(0.75, 0.75, 0.75)
@export var lifetime: float = 30.0
@export var blink_time: float = 5.0

var _age: float = 0.0
var _collected: bool = false


func _physics_process(delta: float) -> void:
	if _collected or GameState.is_game_over:
		return
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	for body in get_overlapping_bodies():
		if body is Player:
			_try_collect(body as Player)
			return


func _process(_delta: float) -> void:
	var remaining: float = lifetime - _age
	if remaining < blink_time:
		modulate.a = 0.35 if int(_age * 6.0) % 2 == 0 else 1.0
	queue_redraw()


func _try_collect(player: Player) -> void:
	match kind:
		Kind.RESOURCE:
			Inventory.add_resource(item_id, amount)
			EventBus.message_posted.emit("+%d %s" % [amount, display_name])
		Kind.HEALTH:
			# Leave it on the ground while health is full.
			if player.health.current_health >= player.health.max_health:
				return
			player.heal(amount)
			EventBus.message_posted.emit("+%d Health" % amount)
	_collected = true
	queue_free()


func _draw() -> void:
	var bob: float = sin(_age * 4.0) * 4.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, 16.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var pts: PackedVector2Array = PackedVector2Array([
		Vector2(0, -38 + bob), Vector2(14, -24 + bob), Vector2(0, -10 + bob), Vector2(-14, -24 + bob)
	])
	draw_colored_polygon(pts, color)
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), Color.WHITE, 2.0)
