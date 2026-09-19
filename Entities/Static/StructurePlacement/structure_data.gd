extends Resource
class_name StructureData

## Data-only definition of one placeable structure (e.g. Anvil, Grindstone).
## Assign one of these .tres resources per structure and list them in a
## Blueprint's `available_structures` export to offer them in the E menu.
## Mirrors the TreeData pattern: content lives in resources, not code.

@export var display_name: String = "Structure"

@export_group("Appearance")
@export var icon: Texture2D
@export var structure_scene: PackedScene  # e.g. res://Assets/Structures/anvil.fbx

@export_group("Placement")
@export var mesh_scale: Vector3 = Vector3.ONE
## Extra Y offset applied on top of the blueprint's position, in case a
## model's origin isn't at its base.
@export var y_offset: float = 0.0

@export_group("Collision")
## Half-extents of a simple box collider generated for the placed structure.
## Tune per structure until real collision meshes are authored.
@export var collision_half_extents: Vector3 = Vector3(0.5, 0.5, 0.5)

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
