extends StaticBody3D
class_name ChoppableTree

## Reusable choppable tree. Cosmetic appearance and gameplay tuning both
## come from `tree_data` (a TreeData resource) so one scene covers every
## tree type in the game - swap the resource in the Inspector to reskin.
##
## Hooks into the existing weapon-swing damage flow the same way Enemy
## does: Weapon's AttackHitboxArea checks `body.has_method("take_damage")`
## and calls it directly, so no changes were needed to weapon.gd.

@export var tree_data: TreeData:
	set(value):
		tree_data = value
		if is_inside_tree():
			_apply_tree_data()

@onready var mesh_root: Node3D = $MeshRoot
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var current_hits: int = 0
var felled: bool = false

func _ready() -> void:
	add_to_group("trees")
	_apply_tree_data()

func _apply_tree_data() -> void:
	if not tree_data:
		return

	# Swap the visible mesh instance for whichever model TreeData points at.
	for child in mesh_root.get_children():
		child.queue_free()
	if tree_data.mesh_scene:
		var mesh_instance: Node3D = tree_data.mesh_scene.instantiate()
		mesh_root.add_child(mesh_instance)
		mesh_instance.scale = tree_data.mesh_scale

	# Rebuild the trunk collider to match this tree type's size.
	var shape := CylinderShape3D.new()
	shape.radius = tree_data.trunk_radius
	shape.height = tree_data.trunk_height
	collision_shape.shape = shape
	collision_shape.position.y = tree_data.trunk_height / 2.0

## Called by Weapon (via duck-typed has_method("take_damage") check) when
## the axe's swing hitbox connects, same as Enemy.take_damage.
func take_damage(attack: DamageSystem.Attack, source: Node = null) -> void:
	if felled or not tree_data:
		return

	current_hits += 1

	if tree_data.chop_sound:
		_play_sound_at(tree_data.chop_sound, global_position)

	if current_hits >= tree_data.hits_to_fell:
		_fell()

func _fell() -> void:
	felled = true

	if tree_data.fall_sound:
		_play_sound_at(tree_data.fall_sound, global_position)

	_drop_logs()
	queue_free()

func _drop_logs() -> void:
	if not tree_data.log_scene:
		return

	var count := randi_range(tree_data.min_logs, tree_data.max_logs)
	var parent := get_tree().current_scene
	for i in count:
		var log_instance: RigidBody3D = tree_data.log_scene.instantiate()
		parent.add_child(log_instance)
		log_instance.global_position = global_position + Vector3(
			randf_range(-0.4, 0.4), 1.0, randf_range(-0.4, 0.4)
		)
		log_instance.apply_impulse(
			Vector3(randf_range(-1.5, 1.5), 2.5, randf_range(-1.5, 1.5))
		)

## Standalone AudioStreamPlayer3D so the sound survives the tree being
## queue_free()'d mid-playback (e.g. the felling sound on the last hit).
func _play_sound_at(stream: AudioStream, at_position: Vector3) -> void:
	var player := AudioStreamPlayer3D.new()
	get_tree().current_scene.add_child(player)
	player.stream = stream
	player.global_position = at_position
	player.play()
	player.finished.connect(player.queue_free)
