extends RefCounted
class_name ItemGathering

## Shared "does the player have the materials, and can we take them"
## helper for anything that consumes nearby/held items to build or craft
## something

## Matches an Item instance against one ItemCost entry: prefers comparing
## the scene each was instantiated from (reliable, no naming required);
## falls back to item_name if the cost entry has no item_scene set.
static func _matches(item: Item, cost: ItemCost) -> bool:
	if cost.item_scene:
		return item.scene_file_path == cost.item_scene.resource_path
	return cost.item_name != "" and item.item_name == cost.item_name

## Finds up to `quantity` Item instances satisfying one cost entry, player's
## held item first (so "use what's in your hand" always works even if nothing
## matching is loose nearby), then loose items within search_radius of the
## player - closest first.
static func _find_matches(cost: ItemCost, holder: ItemHolder, search_radius: float) -> Array[Item]:
	var found: Array[Item] = []

	if holder.held_item and _matches(holder.held_item, cost):
		found.append(holder.held_item)

	if found.size() < cost.quantity:
		var nearby := holder.get_items_in_range(search_radius)
		var player_pos: Vector3 = holder.player.global_position
		nearby.sort_custom(func(a, b):
			return player_pos.distance_to(a.global_position) < player_pos.distance_to(b.global_position)
		)
		for obj in nearby:
			if found.size() >= cost.quantity:
				break
			if obj is Item and obj != holder.held_item and _matches(obj, cost):
				found.append(obj)

	return found

## True if every entry in `costs` can be fully satisfied (held item +
## nearby items combined) without actually consuming anything yet.
static func can_afford(costs: Array[ItemCost], holder: ItemHolder, search_radius: float = 5.0) -> bool:
	if not holder:
		return false
	for cost in costs:
		if _find_matches(cost, holder, search_radius).size() < cost.quantity:
			return false
	return true

## Consumes (frees) the items satisfying `costs`
static func consume(costs: Array[ItemCost], holder: ItemHolder, search_radius: float = 5.0) -> void:
	for cost in costs:
		var matches := _find_matches(cost, holder, search_radius)
		for item in matches:
			if item == holder.held_item:
				holder.held_item = null
			item.queue_free()
