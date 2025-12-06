extends CharacterBody3D
class_name Player

## Player ship for rail shooter
## 4-DOF steering: yaw/pitch control with visual banking
## Forward movement on rail, no lateral strafe

# Steering settings - 4-DOF control
@export var yaw_speed: float = 2.0  # Radians per second at full input
@export var pitch_speed: float = 1.5
@export var max_yaw: float = 0.785  # ~45 degrees
@export var max_pitch: float = 0.524  # ~30 degrees
@export var return_speed: float = 2.5  # How fast yaw/pitch return to center
@export var bank_factor: float = 0.4  # Visual roll from yaw

# Forward movement (rail)
@export var forward_speed: float = 20.0

# Small screen-space offset derived from steering (parallax feel)
@export var parallax_factor: float = 2.0

# Firing settings
@export var fire_rate: float = 0.15
@export var bullet_scene: PackedScene

# Input control - set by Main.gd based on game state
var input_enabled: bool = true

# Steering state
var _yaw: float = 0.0
var _pitch: float = 0.0

# Camera shake
var _shake_intensity: float = 0.0
var _shake_duration: float = 0.0
var _shake_timer: float = 0.0
var _original_camera_offset: Vector3 = Vector3.ZERO

# Internal state
var _fire_cooldown: float = 0.0
var _game_controller: Node = null

@onready var bullet_spawn_point: Marker3D = $BulletSpawnPoint
@onready var ship_mesh: Node3D = $ShipMesh
@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	add_to_group("player")
	_game_controller = get_tree().get_first_node_in_group("game_controller")
	if camera:
		_original_camera_offset = camera.position

func _physics_process(delta: float) -> void:
	if _game_controller and _game_controller.game_over:
		return
	
	# Get steering input
	var input_dir := Vector2.ZERO
	if input_enabled:
		input_dir.x = Input.get_axis("move_left", "move_right")
		input_dir.y = Input.get_axis("move_down", "move_up")
	
	# Update yaw and pitch based on input
	_update_steering(input_dir, delta)
	
	# Apply rotation to ship
	_apply_rotation(delta)
	
	# Forward movement only (rail) - always move along negative Z
	velocity = Vector3(0, 0, -forward_speed)  # Move along -Z (into screen)
	move_and_slide()
	
	# Small parallax offset based on steering
	_apply_parallax_offset()
	
	# Handle firing
	_fire_cooldown -= delta
	if input_enabled and Input.is_action_pressed("fire") and _fire_cooldown <= 0.0:
		_fire()
		_fire_cooldown = fire_rate
	
	# Update camera shake
	_update_camera_shake(delta)

func _update_steering(input_dir: Vector2, delta: float) -> void:
	# Apply input to yaw/pitch
	if abs(input_dir.x) > 0.1:
		_yaw += input_dir.x * yaw_speed * delta
		_yaw = clamp(_yaw, -max_yaw, max_yaw)
	else:
		# Return to center when no input
		_yaw = lerp(_yaw, 0.0, return_speed * delta)
	
	if abs(input_dir.y) > 0.1:
		_pitch += input_dir.y * pitch_speed * delta
		_pitch = clamp(_pitch, -max_pitch, max_pitch)
	else:
		_pitch = lerp(_pitch, 0.0, return_speed * delta)

func _apply_rotation(delta: float) -> void:
	# Apply yaw (turn left/right) and pitch (nose up/down)
	rotation.y = _yaw
	rotation.x = -_pitch  # Negative because up input = nose up = negative X rotation
	
	# Visual banking based on yaw
	var target_bank = -_yaw * bank_factor
	if ship_mesh:
		# Ship mesh gets additional visual tilt
		ship_mesh.rotation.z = lerp(ship_mesh.rotation.z, target_bank, 8.0 * delta)
		# Slight extra pitch tilt for responsiveness
		ship_mesh.rotation.x = lerp(ship_mesh.rotation.x, _pitch * 0.3, 8.0 * delta)

func _apply_parallax_offset() -> void:
	# Small screen-space position offset for parallax feel
	# Derived from rotation, not separate strafe
	if ship_mesh:
		var offset_x = sin(_yaw) * parallax_factor
		var offset_y = sin(_pitch) * parallax_factor * 0.7
		ship_mesh.position.x = offset_x
		ship_mesh.position.y = offset_y

func _fire() -> void:
	if bullet_scene == null:
		push_warning("Player: No bullet scene assigned!")
		return
	
	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = bullet_spawn_point.global_position
	
	# Fire along ship's current forward direction
	var forward_dir = -global_transform.basis.z
	bullet.set_direction(forward_dir)
	bullet.set_forward_speed(forward_speed)
	
	# Play laser SFX
	if has_node("/root/Audio"):
		get_node("/root/Audio").play_sfx_varied("player_laser", 0.95, 1.05)

func take_damage(amount: int = 10) -> void:
	if _game_controller:
		_game_controller.player_hit(amount)
	
	if ship_mesh:
		_flash_damage()
	
	trigger_camera_shake(0.4, 0.2)
	
	if has_node("/root/Audio"):
		get_node("/root/Audio").play_sfx("shield_hit")

func trigger_camera_shake(intensity: float, duration: float) -> void:
	_shake_intensity = intensity
	_shake_duration = duration
	_shake_timer = 0.0

func _update_camera_shake(delta: float) -> void:
	if not camera:
		return
	
	# Base camera position follows ship with slight offset based on steering
	var base_offset = _original_camera_offset
	base_offset.x += _yaw * 0.5  # Slight camera lag behind yaw
	base_offset.y += _pitch * 0.3
	
	# Mild camera roll for bank feel (max ~10 degrees)
	var camera_roll = -_yaw * 0.15
	camera.rotation.z = lerp(camera.rotation.z, camera_roll, 5.0 * delta)
	
	if _shake_timer < _shake_duration:
		_shake_timer += delta
		var shake_progress = _shake_timer / _shake_duration
		var current_intensity = _shake_intensity * (1.0 - shake_progress)
		
		var offset = Vector3(
			randf_range(-current_intensity, current_intensity),
			randf_range(-current_intensity, current_intensity),
			0
		)
		camera.position = base_offset + offset
	else:
		camera.position = base_offset

func _flash_damage() -> void:
	var tween = create_tween()
	for child in ship_mesh.get_children():
		if child is MeshInstance3D:
			var mat = child.get_surface_override_material(0)
			if mat == null and child.mesh:
				mat = child.mesh.surface_get_material(0)
			if mat and mat is StandardMaterial3D:
				var original_emission = mat.emission
				mat.emission_enabled = true
				mat.emission = Color.RED
				tween.tween_callback(func(): mat.emission = original_emission).set_delay(0.1)

## Get current forward direction for other systems
func get_forward_direction() -> Vector3:
	return -global_transform.basis.z

## Get current yaw for systems that need it
func get_current_yaw() -> float:
	return _yaw

## Get current pitch for systems that need it  
func get_current_pitch() -> float:
	return _pitch
