extends Node

var score: int = 0
var is_game_over: bool = false

func start_new_game() -> void:
	score = 0
	is_game_over = false
	EventBus.score_changed.emit(score)

func add_score(amount: int) -> void:
	if is_game_over:
		return
	score += amount
	EventBus.score_changed.emit(score)
func end_game() -> void:
	if is_game_over:
		return
	is_game_over = true
	EventBus.game_over.emit(score)
