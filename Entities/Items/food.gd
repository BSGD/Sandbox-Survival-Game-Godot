extends Item
class_name Food

@export var heal_amount: float = 20.0

func use() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		player.heal(heal_amount)
	queue_free()
	return true
