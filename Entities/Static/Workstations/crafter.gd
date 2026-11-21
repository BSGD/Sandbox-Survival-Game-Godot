extends StaticBody3D

@export var available_crafting_recipies: Array[ItemData] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func interact(holder: Node3D) -> void:
	if available_crafting_recipies.is_empty():
		return
	var menu := get_tree().root.get_node("RecipeMenu")
	#menu.open(self, holder as ItemHolder)
	menu.open(
		available_crafting_recipies,
		holder as ItemHolder,
		func(recipe: RecipeData) -> bool:
			var item_data := recipe as ItemData
			if not item_data:
				return false

			return build(item_data, holder),
		"Craft Item"
	)

func build(item_data: ItemData, holder: ItemHolder) -> bool:
	if not item_data or not item_data.output_scene:
		return false

	if not item_data.cost.is_empty():
		if not holder or not ItemGathering.can_afford(item_data.cost, holder):
			return false
		ItemGathering.consume(item_data.cost, holder)

	var product = item_data.output_scene.instantiate()
	get_tree().current_scene.add_child(product)
	
	return true


func is_interactable() -> bool:
	return true
