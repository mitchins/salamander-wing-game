extends CharacterBody3D
class_name Player

## Player ship for rail shooter
## Moves in a bounded area while constantly moving forward

# Movement settings - tweak these for feel
@export var move_speed: float = 8.0
@export var forward_speed: float = 20.0

# Movement bounds (player is clamped to this area)
@export var bounds_x: float = 5.0
@export var bounds_y: float = 3.0

# Firing settings
@export var fire_rate: float = 0.15  # Seconds between shots
@export var bullet_scene: PackedScene

# Input control - set by Main.gd based on game state
var input_enabled: bool = true

# Internal state
var _fire_cooldown: float = 0.0
var _game_controller: Node = null

@onready var bullet_spawn_point: Marker3D = $BulletSpawnPoint
@onready var ship_mesh: Node3D = $ShipMesh

func _ready() -> void:
	# Find game controller in parent hierarchy
	_game_controller = get_tree().get_first_node_in_group("game_controller")

func _physics_process(delta: float) -> void:
	if _game_controller and _game_controller.game_over:
		return
	
	# Get input only if enabled (COMBAT state)
	var input_dir := Vector2.ZERO
	if input_enabled:
		input_dir.x = Input.get_axis("move_left", "move_right")
		input_dir.y = Input.get_axis("move_down", "move_up")
	
	# Calculate velocity - always move forward, lateral only with input
	velocity.x = input_dir.x * move_speed
	velocity.y = input_dir.y * move_speed
	velocity.z = forward_speed
	
	# Move
	move_and_slide()
	
	# Clamp position to bounds
	position.x = clamp(position.x, -bounds_x, bounds_x)
	position.y = clamp(position.y, -bounds_y, bounds_y)
	
	# Slight ship tilt based on movement for visual feedback
	if ship_mesh:
		var target_rotation := Vector3.ZERO
		target_rotation.z = -input_dir.x * 0.4  # Roll when moving left/right
		target_rotation.x = -input_dir.y * 0.2  # Pitch when moving up/down
		ship_mesh.rotation = ship_mesh.rotation.lerp(target_rotation, 10.0 * delta)
	
	# Handle firing only if input enabled
	_fire_cooldown -= delta
	if input_enabled and Input.is_action_pressed("fire") and _fire_cooldown <= 0.0:
		_fire()
		_fire_cooldown = fire_rate

func _fire() -> void:
	if bullet_scene == null:
		push_warning("Player: No bullet scene assigned!")
		return
	
	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = bullet_spawn_point.global_position
	bullet.set_forward_speed(forward_speed)

func take_damage(amount: int = 10) -> void:
	if _game_controller:
		_game_controller.player_hit(amount)
	
	# Visual feedback - flash the ship
	if ship_mesh:
		_flash_damage()

func _flash_damage() -> void:
	# Quick red flash on damage
	var tween = create_tween()
	for child in ship_mesh.get_children():
		if child is MeshInstance3D:
			var mat = child.get_surface_override_material(0)
			if mat == null:
				mat = child.mesh.surface_get_material(0)
			if mat and mat is StandardMaterial3D:
				var original_emission = mat.emission
				mat.emission_enabled = true
				mat.emission = Color.RED
				tween.tween_callback(func(): mat.emission = original_emission).set_delay(0.1)
