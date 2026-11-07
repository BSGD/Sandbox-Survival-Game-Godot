extends Node3D

@export var chicken_scene: PackedScene
@export var max_chickens: int = 10
@export var spawn_radius: float = 300.0

@onready var spawn_timer: Timer = $SpawnTimer


func _ready() -> void:
	spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	var chicken_count := get_tree().get_nodes_in_group("PassiveMobs").size()

	if chicken_count >= max_chickens:
		return

	var chicken := chicken_scene.instantiate() as Node3D

	var angle := randf_range(0.0, TAU)
	var distance := sqrt(randf()) * spawn_radius

	var offset := Vector3(
		cos(angle) * distance,
		0.0,
		sin(angle) * distance
	)

	get_tree().current_scene.add_child(chicken)
	chicken.global_position = global_position + offset
