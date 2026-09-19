extends Item
class_name Weapon

@export var weapon_name: String = "Default Weapon"
@export var damage: float = 50.0  # High damage to kill the enemy
@export var damage_type: int = DamageSystem.DamageType.PHYSICAL
@export var ap: float = 0.0  # Armor penetration

# Weapon swing area for damage - uses the hand-placed AttackHitbox in the scene
@onready var damage_area: Area3D = $AttackHitboxArea
var swing_arc: float = 1.5  # Radians (~86 degrees)
var swing_duration: float = 0.3

var is_swinging: bool = false

func _ready() -> void:
	# Connect to damage signals
	damage_area.body_entered.connect(_on_damage_area_body_entered)

func get_attack() -> DamageSystem.Attack:
	# Returns an attack when the weapon hits something
	return DamageSystem.Attack.new(damage, damage_type, ap)

func use() -> bool:
	if is_swinging:
		return false

	# Start swing animation/attack
	is_swinging = true
	_swing_async()
	return false  # weapon stays held after swinging

func _swing_async() -> void:
	# Visual swing effect (rotate weapon)
	var start_rotation = rotation
	var swing_time = 0.0

	while swing_time < swing_duration:
		swing_time += get_physics_process_delta_time()
		# Simple swing animation (rotate around X axis)
		rotation.x = lerp(start_rotation.x, start_rotation.x - deg_to_rad(90), swing_time / swing_duration)
		await get_tree().physics_frame

	# Check for hits during swing (we check in _physics_process too)
	check_hits()

	# Smoothly return to rest instead of snapping back instantly
	var return_duration = 0.15
	var return_time = 0.0
	var swung_rotation = rotation
	while return_time < return_duration:
		return_time += get_physics_process_delta_time()
		rotation.x = lerp(swung_rotation.x, start_rotation.x, return_time / return_duration)
		await get_tree().physics_frame

	rotation = start_rotation
	is_swinging = false

func check_hits() -> void:
	# Get all bodies in damage area
	var bodies = damage_area.get_overlapping_bodies()
	for body in bodies:
		_try_hit(body)

func _on_damage_area_body_entered(body: Node) -> void:
	if is_swinging:
		_try_hit(body)

## Duck-typed hit: works on anything with take_damage(attack, source),
## which covers both Enemy and Tree without this script needing to know
## about either class specifically.
func _try_hit(body: Node) -> void:
	var alive_check = not body.has_method("is_alive_for_damage") or body.is_alive_for_damage()
	if body.has_method("take_damage") and alive_check:
		var attack = get_attack()
		body.take_damage(attack, self)
		print("💥 Weapon hit", body.name, "with", attack.damage, "damage")
