extends CanvasLayer

@onready var info: Label = $Info
@onready var game_over_label: Label = $GameOverLabel

var _hp: String = "-"
var _ammo: String = "-"
var _score: int = 0


func _ready() -> void:
	game_over_label.visible = false
	EventBus.player_health_changed.connect(_on_health)
	EventBus.ammo_changed.connect(_on_ammo)
	EventBus.score_changed.connect(_on_score)
	EventBus.game_over.connect(_on_game_over)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if GameState.is_game_over and event.is_action_pressed("reload"):
		get_tree().reload_current_scene()


func _on_health(current: int, maximum: int) -> void:
	_hp = "%d/%d" % [current, maximum]
	_refresh()


func _on_ammo(current: int, maximum: int) -> void:
	_ammo = "%d/%d" % [current, maximum]
	_refresh()


func _on_score(new_score: int) -> void:
	_score = new_score
	_refresh()


func _on_game_over(final_score: int) -> void:
	game_over_label.text = "GAME OVER\nScore: %d\nPress R to restart" % final_score
	game_over_label.visible = true


func _refresh() -> void:
	info.text = "HP: %s    Ammo: %s    Score: %d" % [_hp, _ammo, _score]
