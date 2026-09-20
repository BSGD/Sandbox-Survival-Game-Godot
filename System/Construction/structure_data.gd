extends RecipeData
class_name StructureData

@export_group("Placement")
@export var mesh_scale: Vector3 = Vector3.ONE
## Extra Y offset applied on top of the blueprint's position, in case a
## model's origin isn't at its base.
@export var y_offset: float = 0.0

@export_group("Collision")
## Half-extents of a simple box collider generated for the placed structure.
## Tune per structure until real collision meshes are authored.
@export var collision_half_extents: Vector3 = Vector3(0.5, 0.5, 0.5)
