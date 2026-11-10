class_name Bullet
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 700.0
var damage: int = 10
var max_distance: float = 600.0

var _travelled: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	var step: float = speed * delta
	position += direction * step
	_travelled += step
	if _travelled >= max_distance:
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.9, 0.2))


# Solid world objects stop the bullet.
func _on_body_entered(_body: Node) -> void:
	queue_free()


# Zombie hurtboxes take the damage.
func _on_area_entered(area: Area2D) -> void:
	var target: Node = area.get_parent()
	if target != null and target.has_method("take_damage"):
		target.take_damage(damage)
		queue_free()
