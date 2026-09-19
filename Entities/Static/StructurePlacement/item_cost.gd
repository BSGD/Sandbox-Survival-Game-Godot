extends Resource
class_name ItemCost

## One entry in a crafting/building cost list: "N of this item". Matched
## primarily by item_scene identity (the exact PackedScene an Item instance
## was made from, e.g. iron.tscn) since that's unambiguous; item_name is
## kept as a fallback/display label for items that don't carry a matching
## scene reference at runtime.

@export var item_scene: PackedScene  # e.g. res://Entities/Items/Resources/iron.tscn
@export var item_name: String = ""   # display fallback, e.g. "Iron"
@export var quantity: int = 1

## Human-readable label for menu buttons, e.g. "1x Iron".
func label() -> String:
	var name_str := item_name if item_name != "" else "Item"
	return "%dx %s" % [quantity, name_str]
