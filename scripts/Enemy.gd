extends Area3D
class_name Enemy

## Enemy fighter ship with dogfighting AI
## States: APPROACH → STRAFE → ATTACK → BREAKAWAY
## Destroyed when hit by player bullets - escaped enemies damage the carrier

signal enemy_killed(enemy: Enemy, by_player: bool)
signal enemy_escaped(enemy: Enemy)

enum State { APPROACH, STRAFE, ATTACK, BREAKAWAY, DEAD }

# Movement settings
@export var base_speed: float = 12.0
@export var strafe_speed: float = 8.0
@export var breakaway_speed: float = 18.0

# Combat settings  
@export var score_value: int = 100
@export var hit_points: int = 1
@export var damage_if_escapes: int = 5
@export var explosion_scene: PackedScene

# Firing settings
@export var fire_interval: float = 1.2
@export var fire_spread: float = 0.12  # Radians
@export var bullets_per_burst: int = 2
@export var bullet_scene: PackedScene

# State transition distances
@export var strafe_enter_distance: float = 35.0  # Start strafing when this close
@export var attack_range: float = 50.0  # Max range to fire
@export var escape_z_threshold: float = 20.0  # Z position behind player to escape

# State machine
var state: State = State.APPROACH
var _state_timer: float = 0.0
var _fire_timer: float = 0.0

# Movement state
var _strafe_side: float = 1.0  # 1 = right, -1 = left
var _strafe_switch_timer: float = 0.0
var _wobble_offset: float = 0.0

# References
var _player: Node3D = null
var _game_controller: Node = null
var _is_dead: bool = false

# Speed multiplier (set by spawner)
var _speed_mult: float = 1.0

func _ready() -> void:
	add_to_group("enemy")
	
	# Random offsets for variety
	_wobble_offset = randf() * TAU
	_strafe_side = [-1.0, 1.0].pick_random()
	_fire_timer = randf_range(0.0, fire_interval * 0.5)  # Stagger first shots
	
	# Connect collision signals
	body_entered.connect(_on_body_entered)
	
	# Find references
	_player = get_tree().get_first_node_in_group("player")
	_game_controller = get_tree().get_first_node_in_group("game_controller")
	
	# Load bullet scene if not set
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
		State.STRAFE:
			_update_strafe(delta)
		State.ATTACK:
			_update_attack(delta)
		State.BREAKAWAY:
			_update_breakaway(delta)
	
	# Visual rotation based on movement
	_update_visual_rotation(delta)

## STATE: APPROACH - Move toward player from spawn
func _update_approach(delta: float) -> void:
	var to_player = _player.global_position - global_position
	var dist_z = abs(to_player.z)
	
	# Move toward a point slightly ahead of the player
	var target = _player.global_position + Vector3(0, 0, -10)
	var dir = (target - global_position).normalized()
	
	# Add slight wobble for visual interest
	var wobble = sin(Time.get_ticks_msec() * 0.002 + _wobble_offset) * 2.0
	
	global_position += dir * base_speed * _speed_mult * delta
	global_position.x += wobble * delta
	
	# Transition to STRAFE when close enough
	if dist_z < strafe_enter_distance:
		_change_state(State.STRAFE)

## STATE: STRAFE - Circle/zig-zag around player
func _update_strafe(delta: float) -> void:
	_strafe_switch_timer -= delta
	_fire_timer -= delta
	
	# Occasionally switch strafe direction
	if _strafe_switch_timer <= 0:
		_strafe_side *= -1
		_strafe_switch_timer = randf_range(1.0, 2.5)
	
	# Target position offset from player
	var time_factor = Time.get_ticks_msec() * 0.001
	var target_offset = Vector3(
		_strafe_side * 10.0,
		sin(time_factor * 2.0 + _wobble_offset) * 3.0,
		-15.0  # Stay ahead of player
	)
	var target = _player.global_position + target_offset
	
	# Lerp toward target
	global_position = global_position.lerp(target, strafe_speed * delta * 0.3)
	
	# Match player's forward movement somewhat
	global_position.z = lerp(global_position.z, _player.global_position.z - 20.0, delta * 2.0)
	
	# Can fire during late strafe phase
	if _state_timer > 1.0 and _fire_timer <= 0:
		_try_fire()
	
	# Transition to ATTACK after timer
	if _state_timer > randf_range(2.0, 3.5):
		_change_state(State.ATTACK)

## STATE: ATTACK - Aggressive intercept and fire
func _update_attack(delta: float) -> void:
	_fire_timer -= delta
	
	# Move on intercept course toward player
	var intercept = _player.global_position + Vector3(0, 0, 5)  # Aim slightly behind
	var dir = (intercept - global_position).normalized()
	
	# Aggressive forward movement
	global_position += dir * base_speed * _speed_mult * 1.3 * delta
	
	# Fire at player
	if _fire_timer <= 0:
		_try_fire()
	
	# Check if we've passed the player (time to break away)
	var relative_z = global_position.z - _player.global_position.z
	if relative_z > 5.0 or _state_timer > randf_range(2.5, 4.0):
		_change_state(State.BREAKAWAY)

## STATE: BREAKAWAY - Escape past player, damage carrier
func _update_breakaway(delta: float) -> void:
	# Throttle up and fly past/behind player
	var escape_dir = Vector3(
		_strafe_side * 0.3,  # Slight lateral movement
		0.1,
		1.0  # Positive Z = away from combat
	).normalized()
	
	global_position += escape_dir * breakaway_speed * _speed_mult * delta
	
	# Check if escaped far enough
	if global_position.z > _player.global_position.z + escape_z_threshold:
		_on_escaped()

func _change_state(new_state: State) -> void:
	state = new_state
	_state_timer = 0.0
	
	# State entry logic
	match new_state:
		State.STRAFE:
			_strafe_switch_timer = randf_range(0.5, 1.5)
		State.ATTACK:
			_fire_timer = randf_range(0.0, 0.3)  # Quick first shot
		State.BREAKAWAY:
			pass

func _try_fire() -> void:
	if not _player or not bullet_scene:
		return
	
	var dist = global_position.distance_to(_player.global_position)
	if dist > attack_range:
		return
	
	# Reset fire timer with some randomness
	_fire_timer = fire_interval + randf_range(-0.3, 0.3)
	
	# Fire bullet(s)
	_fire_bullet()
	if bullets_per_burst > 1:
		# Schedule additional bullets in burst
		get_tree().create_timer(0.08).timeout.connect(func(): 
			if is_instance_valid(self) and not _is_dead:
				_fire_bullet()
		)
	
	# Play enemy fire SFX
	if has_node("/root/Audio"):
		get_node("/root/Audio").play_sfx_varied("enemy_laser", 0.85, 0.95)

func _fire_bullet() -> void:
	if not is_instance_valid(_player) or not bullet_scene:
		return
	
	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position + Vector3(0, 0, 0.5)
	
	# Calculate direction toward player with spread
	var base_dir = (_player.global_position - global_position).normalized()
	
	# Apply random spread
	var spread_yaw = randf_range(-fire_spread, fire_spread)
	var spread_pitch = randf_range(-fire_spread, fire_spread)
	
	# Rotate direction by spread angles
	var spread_basis = Basis()
	spread_basis = spread_basis.rotated(Vector3.UP, spread_yaw)
	spread_basis = spread_basis.rotated(Vector3.RIGHT, spread_pitch)
	var final_dir = spread_basis * base_dir
	
	bullet.set_direction(final_dir)

func _update_visual_rotation(delta: float) -> void:
	# Face roughly toward movement/player
	if _player:
		var look_dir = _player.global_position - global_position
		if look_dir.length_squared() > 0.1:
			var target_y = atan2(look_dir.x, -look_dir.z)
			rotation.y = lerp_angle(rotation.y, target_y, 3.0 * delta)
	
	# Slight banking based on strafe
	rotation.z = lerp(rotation.z, -_strafe_side * 0.3, 2.0 * delta)

func take_damage(amount: int = 1) -> void:
	if _is_dead:
		return
	
	hit_points -= amount
	
	if hit_points <= 0:
		_die(true)  # Killed by player
	else:
		# Spawn hit spark for non-lethal hit
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
	
	# Spawn explosion
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		get_tree().current_scene.add_child(explosion)
		explosion.global_position = global_position
	
	# Play explosion SFX
	if has_node("/root/Audio"):
		get_node("/root/Audio").play_sfx_varied("explosion_small", 0.9, 1.1)
	
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
	state = State.DEAD
	
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
	_speed_mult = mult

## Called by spawner to set initial approach behavior
func set_spawn_offset(offset: Vector3) -> void:
	# Adjust strafe side based on spawn position
	if offset.x < 0:
		_strafe_side = -1.0
	else:
		_strafe_side = 1.0
