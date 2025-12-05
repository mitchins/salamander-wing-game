extends Node3D
class_name Starfield

## Procedural starfield that follows the player
## Creates parallax effect for depth

@export var star_count: int = 100
@export var field_size: Vector3 = Vector3(30, 20, 100)
@export var star_speed: float = 0.5  # Relative to player

var _stars: Array[MeshInstance3D] = []
var _player: Node3D = null

func _ready() -> void:
	_create_stars()
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("player")

func _create_stars() -> void:
	var star_mesh = BoxMesh.new()
	star_mesh.size = Vector3(0.1, 0.1, 0.1)
	
	var star_material = StandardMaterial3D.new()
	star_material.albedo_color = Color.WHITE
	star_material.emission_enabled = true
	star_material.emission = Color(1, 1, 0.9)
	star_material.emission_energy_multiplier = 2.0
	
	for i in range(star_count):
		var star = MeshInstance3D.new()
		star.mesh = star_mesh
		star.material_override = star_material.duplicate()
		
		# Random position in field
		star.position = Vector3(
			randf_range(-field_size.x, field_size.x),
			randf_range(-field_size.y, field_size.y),
			randf_range(-field_size.z, 0)
		)
		
		# Random brightness
		var brightness = randf_range(0.3, 1.0)
		star.material_override.emission_energy_multiplier = brightness * 2.0
		
		# Random size
		star.scale = Vector3.ONE * randf_range(0.5, 1.5)
		
		add_child(star)
		_stars.append(star)

func _process(delta: float) -> void:
	if _player == null:
		return
	
	# Move stars relative to player movement
	var player_z = _player.global_position.z
	
	for star in _stars:
		# Wrap stars that fall behind
		if star.global_position.z > player_z + 10:
			star.global_position.z = player_z - field_size.z
			star.global_position.x = randf_range(-field_size.x, field_size.x)
			star.global_position.y = randf_range(-field_size.y, field_size.y)
