extends Resource
class_name TreeData

## Data-only definition of one "kind" of tree: what it looks like, how
## tough it is, and what it drops. Assign one of these .tres resources to
## a Tree node's `tree_data` export to reskin/retune it from the Inspector
## without touching the Tree scene or script.

@export var display_name: String = "Tree"

@export_group("Appearance")
@export var mesh_scene: PackedScene  # e.g. res://Assets/Environment/Tree_1_A_Color1.fbx
@export var mesh_scale: Vector3 = Vector3.ONE

@export_group("Collision")
@export var trunk_radius: float = 0.4
@export var trunk_height: float = 4.0

@export_group("Chopping")
@export var hits_to_fell: int = 3
@export var log_scene: PackedScene  # e.g. res://Entities/Items/Resources/log.tscn
@export var min_logs: int = 2
@export var max_logs: int = 4

@export_group("Effects")
@export var chop_sound: AudioStream
@export var fall_sound: AudioStream
