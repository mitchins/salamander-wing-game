extends Node
class_name DogfightWaveController

## Manages enemy waves during the COMBAT phase
## Spawns enemies in patterns: head_on, flank, arc

signal wave_started(wave_number: int)
signal wave_cleared(wave_number: int)
signal all_waves_cleared

@export var enemy_scene: PackedScene
@export var total_waves: int = 3
@export var enemies_per_wave: int = 4
@export var spawn_distance: float = 55.0  # Closer spawn for faster engagement
@export var spawn_spread: float = 10.0

var current_wave: int = 0
var enemies_alive: int = 0
var _spawning_enabled: bool = false
var _wave_in_progress: bool = false
var _player: Node3D = null
var _spawn_timer: float = 0.0

enum SpawnPattern { HEAD_ON, FLANK, ARC }

func _ready() -> void:
	if enemy_scene == null:
		enemy_scene = load("res://scenes/Enemy.tscn")
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("player")

func _process(delta: float) -> void:
	if not _spawning_enabled:
		return
	if not _wave_in_progress and current_wave < total_waves:
		_spawn_timer += delta
		if _spawn_timer > 2.0:
			_start_next_wave()

func start_spawning() -> void:
	_spawning_enabled = true
	current_wave = 0
	enemies_alive = 0
	_wave_in_progress = false
	_spawn_timer = 0.0

func stop_spawning() -> void:
	_spawning_enabled = false
	_wave_in_progress = false

func _start_next_wave() -> void:
	current_wave += 1
	_wave_in_progress = true
	_spawn_timer = 0.0
	wave_started.emit(current_wave)
	var pattern: SpawnPattern
	match current_wave:
		1:
			pattern = SpawnPattern.HEAD_ON
		2:
			pattern = SpawnPattern.FLANK
		3:
			pattern = SpawnPattern.ARC
		_:
			pattern = [SpawnPattern.HEAD_ON, SpawnPattern.FLANK, SpawnPattern.ARC].pick_random()
	_spawn_wave(pattern)
	if has_node("/root/Comms"):
		if current_wave == 1:
			get_node("/root/Comms").say("VERA", "Contacts inbound. Engaging.", 2.0)
		elif current_wave == 2:
			get_node("/root/Comms").say("VERA", "Second wave detected.", 2.0)
		elif current_wave == 3:
			get_node("/root/Comms").say("VERA", "Final wave incoming. Stay sharp.", 2.0)

func _spawn_wave(pattern: SpawnPattern) -> void:
	if not _player:
		_player = get_tree().get_first_node_in_group("player")
	if not _player:
		return
	var spawn_positions: Array[Vector3] = []
	var player_z = _player.global_position.z
	match pattern:
		SpawnPattern.HEAD_ON:
			spawn_positions = _get_head_on_positions(player_z)
		SpawnPattern.FLANK:
			spawn_positions = _get_flank_positions(player_z)
		SpawnPattern.ARC:
			spawn_positions = _get_arc_positions(player_z)
	for i in range(spawn_positions.size()):
		var pos = spawn_positions[i]
		get_tree().create_timer(i * 0.3).timeout.connect(func():
			_spawn_enemy(pos)
		)

func _get_head_on_positions(player_z: float) -> Array[Vector3]:
	var positions: Array[Vector3] = []
	var base_z = player_z - spawn_distance
	for i in range(enemies_per_wave):
		var x_offset = (i - (enemies_per_wave - 1) / 2.0) * spawn_spread * 0.5
		var y_offset = randf_range(-2, 2)
		positions.append(Vector3(x_offset, y_offset, base_z))
	return positions

func _get_flank_positions(player_z: float) -> Array[Vector3]:
	var positions: Array[Vector3] = []
	var base_z = player_z - spawn_distance * 0.7
	for i in range(enemies_per_wave):
		var side = -1.0 if i % 2 == 0 else 1.0
		var x_offset = side * (spawn_spread + randf_range(0, 5))
		var z_offset = randf_range(-5, 5)
		var y_offset = randf_range(-2, 2)
		positions.append(Vector3(x_offset, y_offset, base_z + z_offset))
	return positions

func _get_arc_positions(player_z: float) -> Array[Vector3]:
	var positions: Array[Vector3] = []
	var base_z = player_z - spawn_distance
	for i in range(enemies_per_wave):
		var angle = PI * (0.3 + 0.4 * float(i) / float(enemies_per_wave - 1)) if enemies_per_wave > 1 else PI * 0.5
		var x_offset = cos(angle) * spawn_spread
		var z_depth = sin(angle) * spawn_spread * 0.5
		var y_offset = randf_range(-1, 1)
		positions.append(Vector3(x_offset, y_offset, base_z - z_depth))
	return positions

func _spawn_enemy(pos: Vector3) -> void:
	if not enemy_scene:
		return
	var enemy = enemy_scene.instantiate()
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = pos
	if enemy.has_signal("enemy_killed"):
		enemy.enemy_killed.connect(_on_enemy_killed)
	if enemy.has_signal("enemy_escaped"):
		enemy.enemy_escaped.connect(_on_enemy_escaped)
	if enemy.has_method("set_spawn_offset"):
		enemy.set_spawn_offset(pos)
	enemies_alive += 1

func _on_enemy_killed(_enemy: Enemy, _by_player: bool) -> void:
	enemies_alive -= 1
	_check_wave_clear()

func _on_enemy_escaped(_enemy: Enemy) -> void:
	enemies_alive -= 1
	_check_wave_clear()

func _check_wave_clear() -> void:
	if enemies_alive <= 0 and _wave_in_progress:
		_wave_in_progress = false
		wave_cleared.emit(current_wave)
		if current_wave >= total_waves:
			all_waves_cleared.emit()
			if has_node("/root/Comms"):
				get_node("/root/Comms").say("VERA", "All waves neutralized.", 2.0)

func on_razor_kill() -> void:
	pass

func get_enemies_remaining() -> int:
	return enemies_alive
