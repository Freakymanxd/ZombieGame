extends Node

signal score_changed(new_score: int)
signal player_health_changed(current: int, maximum: int)
signal player_died
signal zombie_killed(position: Vector2)
signal resource_changed(resource_id: String, new_amount: int)
signal weapon_changed(weapon_name: String)
signal ammo_changed(current: int, maximum: int)

signal game_over(final_score: int)
signal message_posted(text: String)
