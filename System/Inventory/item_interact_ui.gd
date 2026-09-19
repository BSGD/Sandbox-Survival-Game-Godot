extends Label3D
class_name ItemInteractUI

func show_prompt(item: Node3D):
	var pos = item.global_position + Vector3.UP * 1.5
	self.position = pos
	self.visible = true

func hide_prompt():
	self.visible = false
