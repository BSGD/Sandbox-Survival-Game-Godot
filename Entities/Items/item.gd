extends RigidBody3D
class_name Item

@export var item_name: String = "Default Item"

## Would pressing E while holding this item actually do something (a
## weapon swing, eating food)? False means "nothing to use here", which
## tells ItemHolder to let E fall through to whatever's under the
## crosshair instead (e.g. opening a Blueprint's build menu while carrying
## the iron it needs). Set true in the Inspector on items whose use()
## does something - Weapon, Food; leave false for raw materials
## (Iron/Gold/Copper/Silver/Log) and anything else with no use() behavior.
@export var has_use: bool = false

var picked_up: bool = false

func pick_up(holder: Node3D):
	if picked_up:
		return
	self.freeze = true   # disable physics while held
	reparent(holder)
	global_transform = holder.global_transform
	picked_up = true

	# Disable collisions while held
	for child in get_children():
		if child is CollisionShape3D:
			child.disabled = true
			
func toss(world_parent: Node, force: Vector3):
	if not picked_up:
		return
	reparent(world_parent)
	self.freeze = false    # re-enable physics
	picked_up = false

	# Re-enable collisions
	for child in get_children():
		if child is CollisionShape3D:
			child.disabled = false
	# fling it
	apply_central_impulse(force)

## Override in subclasses. Return true if the item is consumed/destroyed by
## this use (e.g. food), so the holder knows to drop its reference. Return
## false for reusable items (e.g. weapons) that stay held after use.
func use() -> bool:
	return false
