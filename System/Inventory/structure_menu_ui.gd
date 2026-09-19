extends Control

## Popup list of buildable structures, opened when the player interacts
## with a Blueprint. Autoloaded as a singleton named "StructureMenuUI" in
## Project Settings, so it's reachable globally by that name without a
## scene-tree lookup (e.g. StructureMenuUI.open(blueprint) from anywhere).
## No class_name here on purpose - it would collide with the autoload's
## own global name. Reachable via get_tree().root.get_node("StructureMenuUI").

@onready var list_container: VBoxContainer = $Panel/MarginContainer/OuterVBox/VBoxContainer

var current_blueprint: Blueprint = null
var current_holder: ItemHolder = null

func _ready() -> void:
	visible = false

## `holder` is the ItemHolder that interacted with the blueprint - needed
## so building a structure with a cost can check/consume the player's
## held + nearby items (see ItemGathering).
func open(blueprint: Blueprint, holder: ItemHolder) -> void:
	current_blueprint = blueprint
	current_holder = holder
	_populate(blueprint.available_structures)
	visible = true
	_get_camera().release_for_ui()

func close() -> void:
	visible = false
	current_blueprint = null
	current_holder = null
	_get_camera().restore_for_ui()


func _get_camera() -> Node:
	var player := get_tree().get_first_node_in_group("player")
	return player.get_node("Camera")

func _populate(structures: Array[StructureData]) -> void:
	for child in list_container.get_children():
		child.queue_free()

	for structure_data in structures:
		var button := Button.new()
		button.text = structure_data.label()
		if structure_data.icon:
			button.icon = structure_data.icon
		if not structure_data.cost.is_empty() and not ItemGathering.can_afford(structure_data.cost, current_holder):
			button.disabled = true
			button.tooltip_text = "Missing required items"
		button.pressed.connect(_on_structure_selected.bind(structure_data))
		list_container.add_child(button)

func _on_structure_selected(structure_data: StructureData) -> void:
	if current_blueprint:
		if not current_blueprint.build(structure_data, current_holder):
			return
	close()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
