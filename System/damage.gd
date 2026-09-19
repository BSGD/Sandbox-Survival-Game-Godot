extends Area3D

@export var damage: int = 1
@export var damage_interval: float = 0.1

var bodies_inside: Array[Node] = []
var damage_timer := 0.0

func _physics_process(delta: float) -> void:
	damage_timer -= delta

	if damage_timer <= 0.0:
		damage_timer = damage_interval

		for body in bodies_inside:
			var attack = DamageSystem.Attack.new(
				damage,
				DamageSystem.DamageType.PHYSICAL,
				0
			)
			body.take_damage(attack)

func _on_body_entered(body: Node) -> void:
	if body is Player and body not in bodies_inside:
		bodies_inside.append(body)

func _on_body_exited(body: Node) -> void:
	bodies_inside.erase(body)
