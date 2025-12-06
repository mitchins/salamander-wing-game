extends Node3D
class_name BackgroundRoot

## BackgroundRoot - Parallax background system with gas giant, moon, and ring
## Follows player camera with parallax offset for depth

@export var parallax_scale: float = 0.02
@export var rotation_speed: float = 0.001

@onready var gas_giant: MeshInstance3D = $GasGiant
@onready var moon: MeshInstance3D = $Moon
@onready var ring: MeshInstance3D = $Ring

var _player_camera: Camera3D = null
var _initial_positions: Dictionary = {}

func _ready() -> void:
	# Store initial positions for parallax calculation
	if gas_giant:
		_initial_positions["gas_giant"] = gas_giant.position
	if moon:
		_initial_positions["moon"] = moon.position
	if ring:
		_initial_positions["ring"] = ring.position
	
	# Find player camera
	await get_tree().process_frame
	_find_player_camera()

func _find_player_camera() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_node("Camera3D"):
		_player_camera = player.get_node("Camera3D")

func _process(delta: float) -> void:
	# Slow rotation for atmosphere
	if gas_giant:
		gas_giant.rotate_y(rotation_speed * delta)
	if ring:
		ring.rotate_y(rotation_speed * 0.5 * delta)
	
	# Parallax following
	if _player_camera:
		_apply_parallax()

func _apply_parallax() -> void:
	var cam_pos := _player_camera.global_position
	
	# Gas giant - far background, minimal movement
	if gas_giant and _initial_positions.has("gas_giant"):
		var base_pos: Vector3 = _initial_positions["gas_giant"]
		gas_giant.position.x = base_pos.x + cam_pos.x * parallax_scale * 0.3
		gas_giant.position.y = base_pos.y + cam_pos.y * parallax_scale * 0.3
	
	# Moon - mid background
	if moon and _initial_positions.has("moon"):
		var base_pos: Vector3 = _initial_positions["moon"]
		moon.position.x = base_pos.x + cam_pos.x * parallax_scale * 0.5
		moon.position.y = base_pos.y + cam_pos.y * parallax_scale * 0.5
	
	# Ring - closer, more movement
	if ring and _initial_positions.has("ring"):
		var base_pos: Vector3 = _initial_positions["ring"]
		ring.position.x = base_pos.x + cam_pos.x * parallax_scale * 0.7
		ring.position.y = base_pos.y + cam_pos.y * parallax_scale * 0.7
