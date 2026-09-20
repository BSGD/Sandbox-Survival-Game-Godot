# System/UI/popup_menu.gd
extends Control
class_name GamePopupMenu

# this is dead code for now

func _ready() -> void:
	visible = false

func open_menu() -> void:
	visible = true
	_get_camera().release_for_ui()

func close_menu() -> void:
	visible = false
	_get_camera().restore_for_ui()

func _get_camera() -> Node:
	var player := get_tree().get_first_node_in_group("player")
	return player.get_node("Camera")
