extends StaticBody3D
class_name NuggetSpawner

## Testing/debug interactable

@export var enemy_scene: PackedScene  # res://Entities/Enemies/enemy.tscn
@export var spawn_offset: Vector3 = Vector3(0, 1.5, 0)
## Simple cooldown so mashing E doesn't flood the scene with enemies.
@export var spawn_cooldown: float = 1.0

var _last_spawn_time: float = -999.0

## Called by ItemHolder when the player is looking at/near this spawner
## and presses E.
func interact(_player: Node3D) -> void:
	if not enemy_scene:
		return

	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_spawn_time < spawn_cooldown:
		return
	_last_spawn_time = now

	var enemy: Node3D = enemy_scene.instantiate()
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = global_position + spawn_offset

func is_interactable() -> bool:
	return true
