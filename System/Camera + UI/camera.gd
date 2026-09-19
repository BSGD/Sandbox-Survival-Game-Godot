extends Node3D

# sensitivities
@export var mouse_cam_sensitivity = 0.005
@export var joystick_cam_sensitivity = 0.1

@onready var arm = $PitchPivot/CamArm   # adjust path to your actual camera
@onready var from_camera = $PitchPivot/FromCamera 
@onready var player = self.get_parent()
@onready var raycast = $PitchPivot/CamArm/Raycast

# internal rotation values
var twist_input := 0.0
var pitch_input := 0.0
# state
var camera_captured := true  # starts in captured mode
var zoom_distance := 3.0
# pivots
@onready var twist_pivot := self
@onready var pitch_pivot := $PitchPivot

# zoom settings
@export var zoom_speed: float = 0.5
@export var min_zoom: float = 2.0
@export var max_zoom: float = 10.0

# for uncaptured right-drag
var last_mouse_pos := Vector2.ZERO
var right_dragging := false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	from_camera.add_exception(player)

## Called by UI (e.g. StructureMenuUI) that needs the mouse visible
func release_for_ui() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

## Restores whatever mouse mode the player's own camera_captured state
func restore_for_ui() -> void:
	if camera_captured:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta):
	# joystick input
	var input_dir = Input.get_vector("look_left", "look_right", "look_up", "look_down")
	twist_pivot.rotate_y(-input_dir.x * joystick_cam_sensitivity)
	pitch_pivot.rotate_x(-input_dir.y * joystick_cam_sensitivity)

	# apply mouse input
	twist_pivot.rotate_y(twist_input)
	pitch_pivot.rotate_x(pitch_input)

	# clamp pitch
	pitch_pivot.rotation.x = clamp(
		pitch_pivot.rotation.x,
		deg_to_rad(-90),
		deg_to_rad(45)
	)

	# reset per-frame inputs
	twist_input = 0.0
	pitch_input = 0.0
		
	update_camera_position()

func _input(event):
	# Ignore camera input entirely while a UI (e.g. the structure build
	# menu) has taken the mouse 
	var structure_menu := get_tree().root.get_node_or_null("StructureMenuUI")
	if structure_menu and structure_menu.visible:
		return

	# toggle camera mode
	if event.is_action_pressed("toggle_camera_mode"):
		camera_captured = !camera_captured
		if camera_captured:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# scroll wheel zoom
	if event is InputEventMouseButton:
		match event.button_index:
			4:
				zoom_camera(zoom_speed)
			5:
				zoom_camera(-zoom_speed)

	# mouse motion
	if event is InputEventMouseMotion:
		if camera_captured:
			# normal captured mode
			twist_input = -event.relative.x * mouse_cam_sensitivity
			pitch_input = -event.relative.y * mouse_cam_sensitivity
		else:
			# uncaptured mode: only rotate when right button held
			if Input.is_mouse_button_pressed(2):
				twist_input = -event.relative.x * mouse_cam_sensitivity
				pitch_input = -event.relative.y * mouse_cam_sensitivity

func zoom_camera(amount: float) -> void:
	# Update zoom distance
	zoom_distance = clamp(zoom_distance - amount, min_zoom, max_zoom)

func update_camera_position() -> void:
	var pivot_pos = pitch_pivot.global_transform.origin
	var target_position = Vector3.ZERO

	if from_camera.is_colliding():
		var collision_point = from_camera.get_collision_point()
		target_position = pivot_pos.direction_to(collision_point) * (pivot_pos.distance_to(collision_point) - 0.2) + pivot_pos
	else:
		# Always calculate direction from pivot to current arm
		var direction = (arm.global_transform.origin - pivot_pos).normalized()
		if direction.length() == 0:
			# fallback if arm is exactly at pivot
			direction = -pitch_pivot.global_transform.basis.z
		target_position = pivot_pos + direction * zoom_distance

	arm.global_transform.origin = target_position
