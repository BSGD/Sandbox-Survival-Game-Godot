extends Resource
class_name RecipeData

@export var display_name: String = "Structure"

@export_group("Appearance")
@export var icon: Texture2D
@export var output_scene: PackedScene  # e.g. res://Assets/Structures/anvil.fbx

@export_group("Cost")
## Items required to build this structure - checked against the player's
## held item plus anything loose nearby (see ItemGathering). Empty means
## free, same as before.
@export var cost: Array[ItemCost] = []

## Menu button label: "Anvil (1x Iron)", or just "Anvil" if free.
func label() -> String:
	if cost.is_empty():
		return display_name
	var cost_parts: Array[String] = []
	for c in cost:
		cost_parts.append(c.label())
	return "%s (%s)" % [display_name, ", ".join(cost_parts)]
