extends Node3D
class_name BlueprintGhost

## Semi-transparent preview of where a Blueprint will be placed.

const VALID_COLOR := Color(0.3, 1.0, 0.3, 0.45)
const INVALID_COLOR := Color(1.0, 0.3, 0.3, 0.45)

@onready var mesh_root: Node3D = $MeshRoot

var _materials: Array[StandardMaterial3D] = []

func _ready() -> void:
	_collect_and_ghost_materials(mesh_root)

## Recurse the instantiated mesh, replacing each surface's material with a
## unique transparent override so the whole ghost can be tinted uniformly
## without touching the source asset's materials.
func _collect_and_ghost_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		for i in mesh_instance.get_surface_override_material_count():
			var mat := StandardMaterial3D.new()
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color = VALID_COLOR
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			mesh_instance.set_surface_override_material(i, mat)
			_materials.append(mat)
		# Ensure at least one override exists even if the mesh has surfaces
		# but no override slots were reported yet (common right after
		# instantiate() before the mesh resource is fully ready).
		if mesh_instance.mesh and _materials.is_empty():
			for i in mesh_instance.mesh.get_surface_count():
				var mat := StandardMaterial3D.new()
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				mat.albedo_color = VALID_COLOR
				mat.cull_mode = BaseMaterial3D.CULL_DISABLED
				mesh_instance.set_surface_override_material(i, mat)
				_materials.append(mat)

	for child in node.get_children():
		_collect_and_ghost_materials(child)

func set_valid(is_valid: bool) -> void:
	var color := VALID_COLOR if is_valid else INVALID_COLOR
	for mat in _materials:
		mat.albedo_color = color
