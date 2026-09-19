extends CharacterBody3D
class_name Enemy

@export var speed: float = 5.0          # Enemy moves faster than player
@export var attack_damage: float = 15.0
@export var attack_range: float = 1.5
@export var attack_cooldown: float = 1.2   # Minimum time between attacks
@export var attack_speed: float = 0.5      # Time enemy pauses before hitting

var player: Player
var last_attack_time: float = -999.0
var attacking: bool = false               # True while winding up attack
var health_component: DamageSystem.HealthComponent
var max_hp: float = 30.0  # Low HP so a weapon can kill it
var alive: bool = true
var damage_area: Area3D
var weapon_range: float = 2.0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as Player
	if not player:
		print("⚠️ No player found in scene")

	# Initialize health component
	health_component = DamageSystem.HealthComponent.new(
		max_hp,
		0.0,          # no shield
		0.0,          # no shield regen
		0.0,          # no hp regen
		{             # armor dictionary
			DamageSystem.DamageType.PHYSICAL: 0,
			DamageSystem.DamageType.FIRE: 0
		},
		-1,           # use max_hp
		-1            # no shield
	)

	# Create damage area for weapon attacks
	damage_area = Area3D.new()
	add_child(damage_area)

	# Set up collision for damage area
	var shape = BoxShape3D.new()
	shape.size = Vector3(weapon_range, 3.0, weapon_range)
	var cs = CollisionShape3D.new()
	cs.shape = shape
	damage_area.add_child(cs)
	# cs.owner = damage_area # Removed this line as it might be causing issues or is not necessary for basic functionality

	damage_area.body_entered.connect(_on_damage_area_body_entered)

func _physics_process(delta: float) -> void:
	if not player or not alive:
		return

	# --- GRAVITY --- (was never applied before - enemy just floated)
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.1

	var to_player = player.global_position - global_position

	# Ignore vertical difference so enemy stays on ground
	to_player.y = 0

	var distance = to_player.length()

	look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)

	if distance > attack_range or attacking:
		# Move toward player only if not winding up
		if not attacking:
			velocity.x = to_player.normalized().x * speed
			velocity.z = to_player.normalized().z * speed
		else:
			velocity.x = 0
			velocity.z = 0
		move_and_slide()
	else:
		# Stop moving while winding up attack
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		# Check for attack cooldown
		var now = Time.get_ticks_msec() / 1000.0
		if not attacking and now - last_attack_time >= attack_cooldown:
			start_attack()


func start_attack() -> void:
	attacking = true
	last_attack_time = Time.get_ticks_msec() / 1000.0   # mark cooldown start
	_attack_async()

func _attack_async() -> void:
	await get_tree().create_timer(attack_speed).timeout
	do_attack()
	attacking = false

func do_attack() -> void:
	# Only apply damage if player is still in range
	if player and alive and global_position.distance_to(player.global_position) <= attack_range:
		var attack = DamageSystem.Attack.new(attack_damage, DamageSystem.DamageType.PHYSICAL, 0)
		player.take_damage(attack)
		print("💥 Enemy hit player with", attack.damage, "damage")

func _on_damage_area_body_entered(body: Node) -> void:
	if not alive or not body is Player:
		return

	# Check if this is a weapon item
	if body.has_method("get_attack"):
		var attack = body.get_attack()
		if attack != null:
			take_damage(attack, body)

func is_alive_for_damage() -> bool:
	return alive

func take_damage(attack: DamageSystem.Attack, source: Node = null) -> void:
	if not alive:
		return

	health_component.apply_attack(attack)
	print("💥 Enemy took", attack.damage, "damage (HP:", health_component.hp, ")")

	if health_component.hp <= 0:
		die()

func die() -> void:
	alive = false
	print("☠️ Enemy died.")
	queue_free()
