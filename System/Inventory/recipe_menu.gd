extends Control

@onready var list_container: VBoxContainer = \
	$Panel/MarginContainer/OuterVBox/VBoxContainer
@onready var title_label: Label = \
	$Panel/MarginContainer/OuterVBox/Title
	
var current_holder: ItemHolder
var current_recipes: Array = []
var selection_callback: Callable


func _ready() -> void:
	visible = false


func open(
	recipes: Array,
	holder: ItemHolder,
	on_selected: Callable,
	title: String = "Recipes"
) -> void:
	current_recipes = recipes.duplicate()
	current_holder = holder
	selection_callback = on_selected
	title_label.text = title
	
	_populate()
	visible = true
	_get_camera().release_for_ui()


func close() -> void:
	visible = false
	current_recipes.clear()
	current_holder = null
	selection_callback = Callable()
	_get_camera().restore_for_ui()


func _populate() -> void:
	for child in list_container.get_children():
		child.queue_free()

	for raw_recipe in current_recipes:
		var recipe: RecipeData = raw_recipe as RecipeData
		if not recipe:
			continue

		var button := Button.new()
		button.text = recipe.label()
		button.icon = recipe.icon

		var can_afford := ItemGathering.can_afford(
			recipe.cost,
			current_holder
		)

		button.disabled = not can_afford

		if not can_afford:
			button.tooltip_text = "Missing required items"

		button.pressed.connect(
			_on_recipe_selected.bind(recipe)
		)

		list_container.add_child(button)


func _on_recipe_selected(recipe: RecipeData) -> void:
	if not selection_callback.is_valid():
		return

	var accepted: bool = selection_callback.call(recipe)

	if accepted != false:
		close()


func _get_camera() -> Node:
	var player := get_tree().get_first_node_in_group("player")
	return player.get_node("Camera")


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
