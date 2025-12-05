extends Node3D
class_name EnemySpawner

## Spawns enemies ahead of the player at regular intervals
## Keeps track of active enemies to prevent overcrowding
## Controlled by Main.gd state machine via spawning_enabled

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 1.5  # Seconds between spawns
@export var max_enemies: int = 12
@export var spawn_distance: float = 80.0  # How far ahead to spawn
@export var spawn_range_x: float = 6.0  # Horizontal spawn range
@export var spawn_range_y: float = 4.0  # Vertical spawn range

# Enemy behavior modifiers (set by configure_wave)
var enemy_speed_multiplier: float = 1.0

# Controlled by Main.gd based on game state
var spawning_enabled: bool = false

var _spawn_timer: float = 0.0
var _player: Node3D = null
var _game_controller: Node = null

func _ready() -> void:
	# Find player - will be set up when Main scene loads
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("player")
	_game_controller = get_tree().get_first_node_in_group("game_controller")

func _process(delta: float) -> void:
	if _game_controller and _game_controller.game_over:
		return
	
	# Only spawn during COMBAT state
	if not spawning_enabled:
		return
	
	_spawn_timer += delta
	
	if _spawn_timer >= spawn_interval:
		_spawn_timer = 0.0
		_try_spawn_enemy()

## Configure wave difficulty based on QTE choice
func configure_wave(mode: String) -> void:
	match mode:
		"evade":
			# Fewer, slower enemies - player took evasive action
			spawn_interval = 2.5
			max_enemies = 5
			enemy_speed_multiplier = 0.7
			print("[SPAWNER] Wave configured: EVADE (fewer/slower enemies)")
		"hold":
			# More, faster enemies - player engaged head-on
			spawn_interval = 1.0
			max_enemies = 12
			enemy_speed_multiplier = 1.2
			print("[SPAWNER] Wave configured: HOLD (more/faster enemies)")
		_:
			# Default
			spawn_interval = 1.5
			max_enemies = 8
			enemy_speed_multiplier = 1.0
	
	# Reset spawn timer to start spawning immediately
	_spawn_timer = spawn_interval

func _try_spawn_enemy() -> void:
	# Check enemy count
	var current_enemies = get_tree().get_nodes_in_group("enemy").size()
	if current_enemies >= max_enemies:
		return
	
	if enemy_scene == null:
		push_warning("EnemySpawner: No enemy scene assigned!")
		return
	
	# Calculate spawn position ahead of player
	var spawn_pos = Vector3.ZERO
	if _player:
		spawn_pos.z = _player.global_position.z - spawn_distance
	else:
		spawn_pos.z = -spawn_distance
	
	spawn_pos.x = randf_range(-spawn_range_x, spawn_range_x)
	spawn_pos.y = randf_range(-spawn_range_y, spawn_range_y)
	
	# Spawn enemy
	var enemy = enemy_scene.instantiate()
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = spawn_pos
	
	# Apply speed multiplier from wave config
	if enemy.has_method("set_speed_multiplier"):
		enemy.set_speed_multiplier(enemy_speed_multiplier)
	else:
		enemy.drift_speed *= enemy_speed_multiplier
	
	# Random initial rotation for variety
	enemy.rotation.y = randf_range(-0.5, 0.5)

func set_difficulty(multiplier: float) -> void:
	## Adjust spawn rate based on difficulty/score
	spawn_interval = max(0.5, 1.5 / multiplier)
