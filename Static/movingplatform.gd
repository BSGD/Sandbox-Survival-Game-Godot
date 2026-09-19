extends AnimatableBody3D

@export var point_a: Vector3
@export var point_b: Vector3
@export var speed: float = 5.0

var target_point: Vector3
var direction: Vector3

func _ready():
	target_point = point_b
	direction = (target_point - global_transform.origin).normalized()

func _physics_process(delta):
	var current_position = global_transform.origin
	var distance_to_target = current_position.distance_to(target_point)

	if distance_to_target > 0.1:
		var movement = direction * speed * delta
		if movement.length() > distance_to_target:
			movement = direction * distance_to_target
		translate(movement)
	else:
		# Swap target points
		if target_point == point_b:
			target_point = point_a
		else:
			target_point = point_b
		direction = (target_point - global_transform.origin).normalized()
