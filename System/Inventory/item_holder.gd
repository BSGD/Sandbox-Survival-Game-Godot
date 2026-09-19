extends Node3D
class_name ItemHolder

@onready var player: Player = self.get_parent()
@onready var cambase = player.get_node("Camera")
@onready var raycast: RayCast3D = cambase.get_node("PitchPivot/CamArm/Raycast")
@onready var camera = cambase.get_node("PitchPivot")
@onready var ui = get_tree().current_scene.get_node("ItemInteractUI")

@export var max_pickup_distance: float = 5.0
@export var max_toss_force: float = 40.0   # adjust for balance
@export var toss_charge_rate: float = 10.0  # how fast toss force builds

@export var blueprint_ghost_scene: PackedScene  # res://Entities/Static/StructurePlacement/blueprint_ghost.tscn
@export var max_placement_distance: float = 6.0

var held_item: Item = null
var charging_toss: bool = false
var toss_charge: float = 0.0

var _ghost: Node3D = null
var _ghost_valid: bool = false
var _ghost_transform: Transform3D

func _ready() -> void:
	# Exclude player from raycast
	raycast.add_exception(player)

# ------------ ITEM SELECTION ------------

func get_items_in_range(radius: float = 5.0) -> Array:
	var shape = SphereShape3D.new()
	shape.radius = radius
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(), get_parent().global_position)
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var results = get_world_3d().direct_space_state.intersect_shape(query, 64)
	var items: Array = []
	for res in results:
		var obj = res.collider
		if obj is Item:
			items.append(obj)
	return items

func get_crosshair_hit_point() -> Vector3:
	if raycast.is_colliding():
		return raycast.get_collision_point()
	return get_parent().global_position

func has_line_of_sight(item: Item, max_distance: float) -> bool:
	var player_pos = get_parent().global_position
	if item.global_position.distance_to(player_pos) > max_distance:
		return false

	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(item.global_position, player_pos)
	query.exclude = [item.get_rid()]
	var result = space.intersect_ray(query)
	return result.is_empty() or result.collider == get_parent()

func get_best_item() -> Item:
	var items = get_items_in_range(max_pickup_distance)
	if items.is_empty():
		return null

	var hit_point = get_crosshair_hit_point()
	items.sort_custom(func(a, b):
		return hit_point.distance_to(a.global_position) < hit_point.distance_to(b.global_position)
	)

	for item in items:
		if has_line_of_sight(item, max_pickup_distance):
			return item
	return null

func get_interactables_in_range(radius: float = 5.0) -> Array:
	var shape = SphereShape3D.new()
	shape.radius = radius
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(), get_parent().global_position)
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var results = get_world_3d().direct_space_state.intersect_shape(query, 64)
	var interactables: Array = []
	for res in results:
		var obj = res.collider
		if obj and obj.has_method("interact"):
			var interactable_check = not obj.has_method("is_interactable") or obj.is_interactable()
			if interactable_check:
				interactables.append(obj)
	return interactables

func get_best_interactable() -> Node3D:
	var interactables = get_interactables_in_range(max_pickup_distance)
	if interactables.is_empty():
		return null

	var hit_point = get_crosshair_hit_point()
	interactables.sort_custom(func(a, b):
		return hit_point.distance_to(a.global_position) < hit_point.distance_to(b.global_position)
	)
	return interactables[0]

func get_best_target() -> Node3D:
	var hit_point = get_crosshair_hit_point()

	var best_item := get_best_item()
	var best_interactable := get_best_interactable()

	if best_item and best_interactable:
		if hit_point.distance_to(best_item.global_position) <= hit_point.distance_to(best_interactable.global_position):
			return best_item
		return best_interactable

	if best_item:
		return best_item
	return best_interactable

# ------------ PICKUP / DROP / THROW ------------

func try_pick_up():
	var best_item = get_best_item()
	if best_item:
		best_item.pick_up(self)
		held_item = best_item

func use_item():
	if held_item:
		var consumed: bool = held_item.use()
		if consumed:
			held_item = null

func toss_item(force: Vector3):
	if held_item:
		held_item.toss(get_tree().current_scene, force)
		held_item = null

# ------------ BLUEPRINT PLACEMENT ------------

func _is_holding_blueprint_item() -> bool:
	return held_item is BlueprintItem

func _update_placement_ghost() -> void:
	var blueprint_item := held_item as BlueprintItem
	if not blueprint_item or not blueprint_item.blueprint_scene:
		return

	if not _ghost:
		var ghost_scene := blueprint_ghost_scene
		if not ghost_scene:
			return
		_ghost = ghost_scene.instantiate()
		get_tree().current_scene.add_child(_ghost)

	if not raycast.is_colliding() or get_crosshair_hit_point().distance_to(player.global_position) > max_placement_distance:
		_ghost.visible = false
		return

	_ghost.visible = true

	var hit_point := raycast.get_collision_point()
	var yaw: float = player.rotation.y
	var basis := Basis(Vector3.UP, yaw)
	_ghost_transform = Transform3D(basis, hit_point)
	_ghost.global_transform = _ghost_transform

	var footprint: Vector2 = _placement_footprint_size()
	_ghost_valid = not Blueprint.would_overlap(get_tree(), _ghost_transform, footprint)
	_ghost.set_valid(_ghost_valid)

func _placement_footprint_size() -> Vector2:
	# Mirrors Blueprint's default footprint_size,
	# kept as a constant here since the ghost is shown before any Blueprint
	# instance exists to read it from.
	return Vector2(6, 6)

func _clear_placement_ghost() -> void:
	if _ghost:
		_ghost.queue_free()
		_ghost = null

func try_place_blueprint() -> void:
	var blueprint_item := held_item as BlueprintItem
	if not blueprint_item or not blueprint_item.blueprint_scene or not _ghost or not _ghost.visible:
		return
	if not _ghost_valid:
		return

	var placed: Node3D = blueprint_item.blueprint_scene.instantiate()
	get_tree().current_scene.add_child(placed)
	placed.global_transform = _ghost_transform

	blueprint_item.queue_free()
	held_item = null
	_clear_placement_ghost()

# ------------ UI ------------
func update_ui():
	if held_item and held_item.has_use:
		ui.hide_prompt()
		return
	var target = get_best_target()
	if target and (not (target is Item) or not held_item):
		ui.show_prompt(target)
	else:
		ui.hide_prompt()
# ------------ PROCESS LOOP ------------

func _process(delta):
	var structure_menu = get_tree().root.get_node("StructureMenuUI")
	if structure_menu and structure_menu.visible:
		return

	if _is_holding_blueprint_item():
		_update_placement_ghost()

		if Input.is_action_just_pressed("grab"): # E
			try_place_blueprint()
	else:
		_clear_placement_ghost()
		update_ui()

	# PICKUP / INTERACT (E while placing a blueprint is handled above instead)
	if Input.is_action_just_pressed("grab") and not _is_holding_blueprint_item(): # E
		if held_item and held_item.has_use:
			use_item()
		else:
			var target = get_best_target()
			if target is Item and not held_item:
				try_pick_up()
			elif target and not target is Item:
				target.interact(self)

	# TOSS / DROP (Q key mapped as "toss")
	if held_item:
		if Input.is_action_just_pressed("toss"):
			toss_charge = 0.0
			charging_toss = true

		if Input.is_action_pressed("toss") and charging_toss:
			toss_charge = clamp(toss_charge + delta * toss_charge_rate, 0, max_toss_force)

		if Input.is_action_just_released("toss") and charging_toss:
			if toss_charge < 1.0:
				toss_charge = 0

			var forward = cambase.global_transform.basis.z * -1
			var toss_velocity = forward * toss_charge + player.velocity

			toss_item(toss_velocity)
			charging_toss = false
