extends Node

var resources: Dictionary = {}

func get_amount(id: String) -> int:
	return resources.get(id, 0)

func add_resource(id: String, amount: int) -> void:
	resources[id] = get_amount(id) + amount
	EventBus.resource_changed.emit(id, resources[id])

func has_resources(cost: Dictionary) -> bool:
	for id in cost:
		if get_amount(id) < cost[id]:
			return false
	return true

func spend(cost: Dictionary) -> bool:
	if not has_resources(cost):
		return false
	for id in cost:
		resources[id] -= cost[id]
		EventBus.resource_changed.emit(id, resources[id])
	return true

func reset() -> void:
	resources.clear()
