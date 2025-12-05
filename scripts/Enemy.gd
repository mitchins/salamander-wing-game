extends Area3D
class_name Enemy

## Simple enemy ship that moves toward the player
## Destroyed when hit by player bullets

@export var drift_speed: float = 5.0
@export var score_value: int = 100
@export var explosion_scene: PackedScene

# Movement pattern
var _move_direction: Vector3 = Vector3.ZERO
var _wobble_offset: float = 0.0
var _wobble_speed: float = 2.0

var _game_controller: Node = null

func _ready() -> void:
	add_to_group("enemy")
	
	# Random wobble offset for variety
	_wobble_offset = randf() * TAU
	_wobble_speed = randf_range(1.5, 3.0)
	
	# Set initial drift direction (slightly toward center with some randomness)
	_move_direction = Vector3(
		randf_range(-0.3, 0.3),
		randf_range(-0.2, 0.2),
		1.0  # Move toward player (positive Z)
	).normalized()
	
	# Connect collision signals
	body_entered.connect(_on_body_entered)
	
	# Find game controller
	_game_controller = get_tree().get_first_node_in_group("game_controller")

func _physics_process(delta: float) -> void:
	if _game_controller and _game_controller.game_over:
		return
	
	# Wobble movement for more interesting patterns
	var wobble = sin(Time.get_ticks_msec() * 0.001 * _wobble_speed + _wobble_offset)
	
	# Move toward player with wobble
	var movement = _move_direction * drift_speed * delta
	movement.x += wobble * 2.0 * delta
	
	position += movement
	
	# Slight rotation for visual interest
	rotation.z = wobble * 0.2
	rotation.y += delta * 0.5
	
	# Remove if too far behind player (passed them)
	if position.z > 20.0:
		queue_free()

func take_damage() -> void:
	# Spawn explosion
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		get_tree().current_scene.add_child(explosion)
		explosion.global_position = global_position
	
	# Add score
	if _game_controller:
		_game_controller.add_score(score_value)
	
	# Destroy self
	queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		body.take_damage(15)
		# Also destroy self on collision
		take_damage()
