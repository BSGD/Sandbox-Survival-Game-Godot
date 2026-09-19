extends Item
class_name BlueprintItem

## Held, tossable item (small, like any other Item) that places the large
## ground Blueprint. 

@export var blueprint_scene: PackedScene  # res://Entities/Static/StructurePlacement/blueprint.tscn

func use() -> bool:
	return false
