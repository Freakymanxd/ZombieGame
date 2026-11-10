extends Node2D


func _ready() -> void:
	GameState.start_new_game()
	Inventory.reset()
	print("Game started.")
