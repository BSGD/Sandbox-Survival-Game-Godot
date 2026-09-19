extends StaticBody3D
class_name Blueprint

## The large ground blueprin
@export var available_structures: Array[StructureData] = []

## Footprint size (X/Z) this blueprint occupies on the ground
@export var footprint_size: Vector2 = Vector2(2.5, 2.5)

@onready var mesh_root: Node3D = $MeshRoot

var built: bool = false

func _ready() -> void:
	add_to_group("blueprints")

## Check whether a footprint at `at_transform`
## would overlap this (or any) placed blueprint/structure.
func overlaps(at_transform: Transform3D, size: Vector2) -> bool:
	var half := Vector3(size.x, 4.0, size.y) / 2.0
	var to_local := global_transform.affine_inverse() * at_transform
	var other_half := Vector3(footprint_size.x, 4.0, footprint_size.y) / 2.0
	# Simple AABB overlap
	var offset := to_local.origin
	return abs(offset.x) < (half.x + other_half.x) and abs(offset.z) < (half.z + other_half.z)


func interact(holder: Node3D) -> void:
	if built or available_structures.is_empty():
		return
	var menu := get_tree().root.get_node("StructureMenuUI")
	menu.open(self, holder as ItemHolder)

func build(structure_data: StructureData, holder: ItemHolder) -> bool:
	if built or not structure_data or not structure_data.structure_scene:
		return false

	if not structure_data.cost.is_empty():
		if not holder or not ItemGathering.can_afford(structure_data.cost, holder):
			return false
		ItemGathering.consume(structure_data.cost, holder)

	built = true

	var structure := StaticBody3D.new()
	structure.name = structure_data.display_name.replace(" ", "")
	structure.add_to_group("structures")
	get_parent().add_child(structure)
	structure.global_transform = global_transform
	structure.global_position.y += structure_data.y_offset

	var mesh_instance: Node3D = structure_data.structure_scene.instantiate()
	structure.add_child(mesh_instance)
	mesh_instance.scale = structure_data.mesh_scale

	var collision_shape := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = structure_data.collision_half_extents * 2.0
	collision_shape.shape = shape
	collision_shape.position.y = structure_data.collision_half_extents.y
	structure.add_child(collision_shape)

	queue_free()
	return true


func is_interactable() -> bool:
	return not built

## Static helper
static func would_overlap(tree: SceneTree, at_transform: Transform3D, size: Vector2) -> bool:
	for bp in tree.get_nodes_in_group("blueprints"):
		if bp is Blueprint and bp.overlaps(at_transform, size):
			return true

	var half := Vector3(size.x, 4.0, size.y) / 2.0
	for structure in tree.get_nodes_in_group("structures"):
		var offset: Vector3 = at_transform.affine_inverse() * structure.global_position
		# Rough 1x1 footprint per structure - fine for v1's simple AABB check.
		if abs(offset.x) < (half.x + 0.5) and abs(offset.z) < (half.z + 0.5):
			return true

	return false
