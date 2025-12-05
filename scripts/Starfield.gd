extends Node3D
class_name Starfield

## Procedural starfield that acts as an infinite skybox
## Stars are placed on a sphere around the camera and rotate slowly
## Never zooms in/out - purely rotational parallax

@export var star_count: int = 150
@export var sphere_radius: float = 80.0  # Distance from camera
@export var rotation_speed: float = 0.02  # Slow rotation for parallax feel
@export var second_layer_count: int = 80  # Fainter distant layer
@export var second_layer_radius: float = 120.0

var _stars_layer1: Array[MeshInstance3D] = []
var _stars_layer2: Array[MeshInstance3D] = []
var _camera: Camera3D = null
var _base_rotation: float = 0.0

# Star material - flat, emissive, no PBR
var _star_material: StandardMaterial3D

func _ready() -> void:
	_create_star_material()
	_create_stars_on_sphere(_stars_layer1, star_count, sphere_radius, 1.0)
	_create_stars_on_sphere(_stars_layer2, second_layer_count, second_layer_radius, 0.5)
	
	await get_tree().process_frame
	_find_camera()

func _create_star_material() -> void:
	_star_material = StandardMaterial3D.new()
	_star_material.albedo_color = Color(0.9, 0.9, 0.8)
	_star_material.emission_enabled = true
	_star_material.emission = Color(0.95, 0.95, 0.85)
	_star_material.emission_energy_multiplier = 1.5
	_star_material.metallic = 0.0
	_star_material.roughness = 1.0
	# Billboard so stars always face camera
	_star_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED

func _create_stars_on_sphere(star_array: Array[MeshInstance3D], count: int, radius: float, brightness_mult: float) -> void:
	var star_mesh = BoxMesh.new()
	star_mesh.size = Vector3(0.15, 0.15, 0.15)
	
	for i in range(count):
		var star = MeshInstance3D.new()
		star.mesh = star_mesh
		
		# Create unique material per star for brightness variation
		var mat = _star_material.duplicate()
		var brightness = randf_range(0.3, 1.0) * brightness_mult
		mat.emission_energy_multiplier = brightness * 1.5
		mat.albedo_color = Color(0.9, 0.9, 0.8) * brightness
		star.material_override = mat
		
		# Random position on sphere using spherical coordinates
		var theta = randf() * TAU  # Azimuthal angle (0 to 2π)
		var phi = acos(2.0 * randf() - 1.0)  # Polar angle (uniform distribution)
		
		star.position = Vector3(
			radius * sin(phi) * cos(theta),
			radius * sin(phi) * sin(theta),
			radius * cos(phi)
		)
		
		# Random size variation
		star.scale = Vector3.ONE * randf_range(0.5, 1.2)
		
		add_child(star)
		star_array.append(star)

func _find_camera() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		_camera = player.get_node_or_null("Camera3D")

func _process(delta: float) -> void:
	# Keep starfield centered on camera
	if _camera:
		global_position = _camera.global_position
	else:
		_find_camera()
	
	# Slow rotation for parallax feel (stars drift slowly)
	_base_rotation += rotation_speed * delta
	rotation.y = _base_rotation
	
	# Second layer rotates slightly slower for depth
	# (We handle this by having different radii instead)
