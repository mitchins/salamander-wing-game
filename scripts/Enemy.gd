extends Area3D
class_name Enemy

## Enemy fighter with dogfight AI
## States: APPROACH → ATTACK → BREAKAWAY → DEAD
## Enemies make threatening passes in front of the player

signal enemy_killed(enemy: Enemy, by_player: bool)
signal enemy_escaped(enemy: Enemy)

enum State { APPROACH, ATTACK, BREAKAWAY, DEAD }

# Movement settings
@export var approach_speed: float = 30.0
@export var attack_speed: float = 18.0
@export var breakaway_speed: float = 35.0

# Combat settings
@export var score_value: int = 100
@export var hit_points: int = 1
@export var damage_if_escapes: int = 5
@export var explosion_scene: PackedScene

# Attack settings
@export var engagement_distance: float = 25.0  # Distance to enter ATTACK
@export var attack_duration: float = 2.0  # Seconds in attack window
@export var fire_interval: float = 0.7  # Faster firing during attack
@export var fire_spread: float = 0.12  # Radians - tighter spread
@export var bullet_scene: PackedScene

# Breakaway settings
@export var breakaway_distance: float = 20.0  # Distance behind player to escape

# State machine
var state: State = State.APPROACH
var _state_timer: float = 0.0
var _fire_timer: float = 0.0

# Movement state
var _attack_offset: Vector3 = Vector3.ZERO  # Offset within player's cone during attack
var _strafe_side: float = 1.0

# References
var _player: Node3D = null
var _game_controller: Node = null
var _is_dead: bool = false
var _speed_mult: float = 1.0

func _ready() -> void:
	add_to_group("enemy")
	
	# Random variety
	_strafe_side = [-1.0, 1.0].pick_random()
	_fire_timer = randf_range(0.0, fire_interval * 0.3)
	
	# Random attack offset within player's cone
	_attack_offset = Vector3(
		randf_range(-8, 8),
		randf_range(-4, 4),
		0
	)
	
	body_entered.connect(_on_body_entered)
	_player = get_tree().get_first_node_in_group("player")
	_game_controller = get_tree().get_first_node_in_group("game_controller")
	
	if bullet_scene == null:
		bullet_scene = load("res://scenes/EnemyBullet.tscn")

func _physics_process(delta: float) -> void:
	if _is_dead:
		return
	
	if _game_controller and _game_controller.game_over:
		return
	
	if not _player:
		_player = get_tree().get_first_node_in_group("player")
		if not _player:
			return
	
	_state_timer += delta
	
	match state:
		State.APPROACH:
			_update_approach(delta)
		State.ATTACK:
			_update_attack(delta)
		State.BREAKAWAY:
			_update_breakaway(delta)
	
	_update_visual_rotation(delta)

func _update_approach(delta: float) -> void:
	# Move toward engagement position in front of player (negative Z direction)
	var target = _player.global_position + Vector3(_attack_offset.x * 0.5, _attack_offset.y * 0.5, -engagement_distance)
	var to_target = target - global_position
	var dist = to_target.length()
	
	if dist > 1.0:
		var dir = to_target.normalized()
		global_position += dir * approach_speed * _speed_mult * delta
	
	# Check if close enough to engage (Z distance primarily)
	var z_dist = abs(global_position.z - _player.global_position.z)
	if z_dist < engagement_distance + 8.0:
		_change_state(State.ATTACK)

func _update_attack(delta: float) -> void:
	_fire_timer -= delta
	
	# Stay within player's forward cone during attack
	# Target a position ahead of player (negative Z) but offset to sides
	var target_z = _player.global_position.z - 12.0  # Stay ahead of player
	var target = Vector3(
		_player.global_position.x + _attack_offset.x,
		_player.global_position.y + _attack_offset.y,
		target_z
	)
	
	# Smooth movement toward target position
	global_position = global_position.lerp(target, attack_speed * delta * 0.12)
	
	# Keep pace with player's forward movement (player moves -Z)
	global_position.z = lerp(global_position.z, target_z, 3.0 * delta)
	
	# Slowly drift attack offset for variety
	_attack_offset.x += _strafe_side * delta * 2.5
	if abs(_attack_offset.x) > 8.0:
		_strafe_side *= -1
	
	# Fire at player during attack window
	if _fire_timer <= 0:
		_fire_at_player()
		_fire_timer = fire_interval + randf_range(-0.15, 0.15)
	
	# Transition to breakaway after attack duration
	if _state_timer > attack_duration:
		_change_state(State.BREAKAWAY)

func _update_breakaway(delta: float) -> void:
	# Accelerate past the player (positive Z = behind player who moves -Z)
	var escape_dir = Vector3(
		_strafe_side * 0.15,
		0.03,
		1.0  # Positive Z = moving away from where player is heading
	).normalized()
	
	global_position += escape_dir * breakaway_speed * _speed_mult * delta
	
	# Check if escaped (enemy Z is greater than player Z by breakaway margin)
	var relative_z = global_position.z - _player.global_position.z
	if relative_z > breakaway_distance:
		_on_escaped()

func _change_state(new_state: State) -> void:
	state = new_state
	_state_timer = 0.0
	
	match new_state:
		State.ATTACK:
			_fire_timer = randf_range(0.1, 0.4)  # Quick first shot
		State.BREAKAWAY:
			pass

func _fire_at_player() -> void:
	if not _player or not bullet_scene:
		return
	
	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position + Vector3(0, 0, 0.5)
	
	# Direction toward player with spread
	var base_dir = (_player.global_position - global_position).normalized()
	
	# Apply spread
	var spread_yaw = randf_range(-fire_spread, fire_spread)
	var spread_pitch = randf_range(-fire_spread, fire_spread)
	var spread_basis = Basis()
	spread_basis = spread_basis.rotated(Vector3.UP, spread_yaw)
	spread_basis = spread_basis.rotated(Vector3.RIGHT, spread_pitch)
	var final_dir = spread_basis * base_dir
	
	bullet.set_direction(final_dir)
	
	if has_node("/root/Audio"):
		get_node("/root/Audio").play_sfx_varied("enemy_laser", 0.85, 0.95)

func _update_visual_rotation(delta: float) -> void:
	if _player:
		var look_dir = _player.global_position - global_position
		if look_dir.length_squared() > 0.1:
			var target_y = atan2(look_dir.x, -look_dir.z)
			rotation.y = lerp_angle(rotation.y, target_y, 4.0 * delta)
	
	# Banking based on movement
	rotation.z = lerp(rotation.z, -_strafe_side * 0.25, 3.0 * delta)

func take_damage(amount: int = 1) -> void:
	if _is_dead:
		return
	
	hit_points -= amount
	
	if hit_points <= 0:
		_die(true)
	else:
		_spawn_hit_spark()

func _spawn_hit_spark() -> void:
	var spark_scene = load("res://vfx/HitSpark.tscn")
	if spark_scene:
		var spark = spark_scene.instantiate()
		get_tree().current_scene.add_child(spark)
		spark.global_position = global_position

func _die(killed_by_player: bool) -> void:
	if _is_dead:
		return
	_is_dead = true
	state = State.DEAD
	
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		get_tree().current_scene.add_child(explosion)
		explosion.global_position = global_position
	
	if has_node("/root/Audio"):
		get_node("/root/Audio").play_sfx_varied("explosion_small", 0.9, 1.1)
	
	if killed_by_player and _game_controller:
		_game_controller.add_score(score_value)
		_game_controller.on_enemy_killed(self)
	
	enemy_killed.emit(self, killed_by_player)
	queue_free()

func _on_escaped() -> void:
	if _is_dead:
		return
	_is_dead = true
	state = State.DEAD
	
	if _game_controller:
		_game_controller.on_enemy_escaped(self)
	
	enemy_escaped.emit(self)
	queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		body.take_damage(15)
		_die(false)

func set_speed_multiplier(mult: float) -> void:
	_speed_mult = mult

func set_spawn_offset(offset: Vector3) -> void:
	if offset.x < 0:
		_strafe_side = -1.0
	else:
		_strafe_side = 1.0
