extends Area3D
class_name Enemy

## Enemy fighter ship with HP, scoring, and escape damage
## Destroyed when hit by player bullets - escaped enemies damage the carrier

signal enemy_killed(enemy: Enemy, by_player: bool)
signal enemy_escaped(enemy: Enemy)

@export var drift_speed: float = 5.0
@export var score_value: int = 100
@export var hit_points: int = 1
@export var damage_if_escapes: int = 5
@export var explosion_scene: PackedScene
@export var escape_z_threshold: float = 15.0  # How far past player before "escaped"

# Movement pattern
var _move_direction: Vector3 = Vector3.ZERO
var _wobble_offset: float = 0.0
var _wobble_speed: float = 2.0

var _game_controller: Node = null
var _is_dead: bool = false

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
	if _is_dead:
		return
	
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
	
	# Check if enemy has escaped (passed the player)
	if position.z > escape_z_threshold:
		_on_escaped()

func take_damage(amount: int = 1) -> void:
	if _is_dead:
		return
	
	hit_points -= amount
	
	if hit_points <= 0:
		_die(true)  # Killed by player

func _die(killed_by_player: bool) -> void:
	if _is_dead:
		return
	_is_dead = true
	
	# Spawn explosion
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		get_tree().current_scene.add_child(explosion)
		explosion.global_position = global_position
	
	# Add score if killed by player
	if killed_by_player and _game_controller:
		_game_controller.add_score(score_value)
		_game_controller.on_enemy_killed(self)
	
	# Emit signal
	enemy_killed.emit(self, killed_by_player)
	
	# Destroy self
	queue_free()

func _on_escaped() -> void:
	if _is_dead:
		return
	_is_dead = true
	
	# Notify game controller of escape (damages carrier)
	if _game_controller:
		_game_controller.on_enemy_escaped(self)
	
	# Emit signal
	enemy_escaped.emit(self)
	
	# Silently remove (no explosion - they got away)
	queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		body.take_damage(15)
		# Also destroy self on collision (not a "kill" - kamikaze)
		_die(false)

func set_speed_multiplier(mult: float) -> void:
	drift_speed *= mult
