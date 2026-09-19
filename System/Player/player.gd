extends CharacterBody3D
class_name Player
signal health_changed

# --- NODES ---
@onready var cam_pivot: Node3D = $Camera  # horizontal camera pivot (child of player)
# --- SETTINGS ---
@export var speed: float = 6.0        # max run speed
@export var accel: float = 30.0       # acceleration
@export var deaccel: float = 20.0     # deceleration
@export var push_strength: float = 0.2# for physics
@export var max_hp = 10.0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# --- STATE ---
var camera_captured := true             # sync with camera script
var health_component: DamageSystem.HealthComponent

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Initialize the health component using your DamageSystem
	health_component = DamageSystem.HealthComponent.new(
		100.0,        # max_hp
		15.0,         # max_shield
		0.0,          # shield_regen
		1.0,          # hp_regen
		{             # armor dictionary
			DamageSystem.DamageType.PHYSICAL: 0,
			DamageSystem.DamageType.FIRE: 0
		},
		-1,           # optional starting HP (use -1 to default to max_hp)
		-1            # optional starting Shield (use -1 to default to max_shield)
	)

	add_to_group("player")  # helps enemies find the player

	emit_signal("health_changed", health_component.hp, 100.0)

func _physics_process(delta: float) -> void:
	# --- HEALTH ---
	health_component.regen(delta)
	
	# --- INPUT ---
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_backward", "move_forward")
	var target_velocity: Vector3 = Vector3.ZERO

	# --- CAMERA RELATIVE MOVEMENT ---
	var cam_forward: Vector3 = -cam_pivot.global_transform.basis.z
	cam_forward.y = 0
	cam_forward = cam_forward.normalized()

	var cam_right: Vector3 = cam_pivot.global_transform.basis.x
	cam_right.y = 0
	cam_right = cam_right.normalized()

	var move_dir: Vector3 = (cam_right * input_dir.x + cam_forward * input_dir.y).normalized()
	target_velocity = move_dir * speed

	# --- PLAYER ROTATION ---
	camera_captured = cam_pivot.camera_captured

	if camera_captured:
		# --- LOCKED MODE ---
		# Align player yaw exactly with camera pivot's local yaw
		var cam_global_yaw = cam_pivot.global_transform.basis.get_euler().y
		rotate_player(cam_global_yaw)
	else:
		# --- FREE-LOOK MODE ---
		if move_dir.length() > 0:
			# Compute target yaw based on movement direction
			var target_yaw = atan2(-move_dir.x, -move_dir.z)
			# Smoothly interpolate toward the target
			var new_yaw = lerp_angle(rotation.y, target_yaw, 10 * delta)
			rotate_player(new_yaw)

	# --- SMOOTH VELOCITY ---
	velocity.x = move_toward(velocity.x, target_velocity.x, (accel if target_velocity.length() > 0.01 else deaccel) * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, (accel if target_velocity.length() > 0.01 else deaccel) * delta)

	# --- GRAVITY ---
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.1
		# --- JUMP INPUT ---
		if Input.is_action_just_pressed("jump") and is_on_floor():
			# Set Y velocity to jump strength
			velocity.y = 8.0  # tweak this value for higher/lower jumps

	# --- MOVE ---
	move_and_slide()
	push_rigidbodies()

func push_rigidbodies():
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		# KinematicCollision3D exposes collider/position as methods, not
		# properties, in Godot 4 - collision.collider / collision.position
		# would throw "Invalid access to property or key".
		var body = collision.get_collider()
		if body is RigidBody3D:
			# Push the rigid body in the direction of player movement
			var push_dir = velocity
			if push_dir.length() > 0:
				push_dir = push_dir.normalized()
				# Apply impulse at the collision point
				# apply_impulse(impulse, position) - impulse vector first, then
				# the offset (in global coords, relative to the body's origin)
				# where it's applied.
				body.apply_impulse(push_dir * push_strength, collision.get_position() - body.global_transform.origin)

func rotate_player(target_yaw: float) -> void:
	# Compute how much the player needs to rotate
	var yaw_delta = target_yaw - rotation.y
	
	# Rotate player to the absolute target yaw
	rotation.y = target_yaw
	
	# Rotate camera pivot in opposite direction to cancel visual effect
	cam_pivot.rotation.y -= yaw_delta

func take_damage(attack: DamageSystem.Attack, _source: Node = null) -> void:
	health_component.apply_attack(attack)
	emit_signal("health_changed", health_component.hp, 100.0)

	print("💢 Player took", attack.damage, "damage (HP:", health_component.hp, ", Shield:", health_component.shield, ")")

	if health_component.hp <= 0:
		die()

func die() -> void:
	print("☠️ Player died.")
	queue_free()  # or trigger a death animation

func heal(amount: float) -> void:
	health_component.heal(amount)
	emit_signal("health_changed", health_component.hp, 100.0)

	print("🍖 Player healed", amount, "HP (HP:", health_component.hp, ")")
