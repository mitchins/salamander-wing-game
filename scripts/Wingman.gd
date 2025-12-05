extends Area3D
class_name Wingman

## Wingman AI - Razor
## Follows the player at an offset and shoots at enemies
## Can be killed by enemies if they collide

signal wingman_killed

@export var follow_offset: Vector3 = Vector3(-3.0, -0.5, 2.0)  # Left and slightly behind
@export var follow_speed: float = 5.0
@export var fire_rate: float = 0.8
@export var bullet_scene: PackedScene
@export var explosion_scene: PackedScene
@export var hit_points: int = 3
@export var targeting_range: float = 60.0  # Max range to target enemies

var is_alive: bool = true
var combat_enabled: bool = false  # Only shoot during combat

var _player: Node3D = null
var _fire_cooldown: float = 0.0
var _current_target: Node3D = null
var _game_controller: Node = null
var _bullet_spawn_point: Marker3D = null

func _ready() -> void:
	add_to_group("wingman")
	
	# Connect collision
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Find references
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("player")
	_game_controller = get_tree().get_first_node_in_group("game_controller")
	
	# Create bullet spawn point
	_bullet_spawn_point = Marker3D.new()
	_bullet_spawn_point.position = Vector3(0, 0, -1.5)
	add_child(_bullet_spawn_point)

func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	
	if _game_controller and _game_controller.game_over:
		return
	
	# Follow player with offset
	_update_follow(delta)
	
	# Handle targeting and firing
	if combat_enabled:
		_fire_cooldown -= delta
		_update_targeting()
		_try_fire()

func _update_follow(delta: float) -> void:
	if not _player:
		return
	
	# Calculate target position relative to player
	var target_pos = _player.global_position + follow_offset
	
	# Smooth follow
	global_position = global_position.lerp(target_pos, follow_speed * delta)
	
	# Match player's forward movement
	position.z = _player.position.z + follow_offset.z
	
	# Slight banking based on horizontal offset from ideal position
	var offset_diff = target_pos.x - global_position.x
	rotation.z = clamp(offset_diff * 0.1, -0.3, 0.3)

func _update_targeting() -> void:
	# Find closest enemy in range
	_current_target = null
	var closest_dist = targeting_range
	
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		
		var dist = global_position.distance_to(enemy.global_position)
		# Only target enemies ahead of us
		if enemy.global_position.z < global_position.z and dist < closest_dist:
			closest_dist = dist
			_current_target = enemy
	
	# Look at target (slight)
	if _current_target and is_instance_valid(_current_target):
		var look_dir = (_current_target.global_position - global_position).normalized()
		# Only slightly rotate toward target
		rotation.y = lerp_angle(rotation.y, atan2(look_dir.x, -look_dir.z), 0.1)

func _try_fire() -> void:
	if _fire_cooldown > 0:
		return
	
	if not _current_target or not is_instance_valid(_current_target):
		return
	
	if bullet_scene == null:
		return
	
	# Fire at target
	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = _bullet_spawn_point.global_position
	
	# Set bullet direction toward target (with some lead)
	if bullet.has_method("set_forward_speed") and _player:
		bullet.set_forward_speed(_player.forward_speed)
	
	_fire_cooldown = fire_rate
	
	# Slight chance to announce kill if enemy is low HP
	# (enemies are typically 1 HP so this fires on kill)

func take_damage(amount: int = 1) -> void:
	if not is_alive:
		return
	
	hit_points -= amount
	
	if hit_points <= 0:
		_die()
	else:
		# Flash damage effect
		_flash_damage()
		Comms.say("RAZOR", "Taking hits! Cover me, Rider!", 2.0)

func _die() -> void:
	if not is_alive:
		return
	
	is_alive = false
	
	# Spawn explosion
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		get_tree().current_scene.add_child(explosion)
		explosion.global_position = global_position
		# Scale up explosion for wingman death
		explosion.scale = Vector3(2.0, 2.0, 2.0)
	
	# Comms announcement
	Comms.say_immediate("VERA", "Razor is down! Repeat, Razor is DOWN!", 3.0)
	
	# Emit signal
	wingman_killed.emit()
	
	# Hide (don't destroy - might need reference)
	visible = false
	set_physics_process(false)

func _flash_damage() -> void:
	# Quick flash effect using material emission
	var ship_mesh = get_node_or_null("ShipMesh")
	if ship_mesh:
		var tween = create_tween()
		for child in ship_mesh.get_children():
			if child is MeshInstance3D:
				var mat = child.get_surface_override_material(0)
				if mat == null and child.mesh:
					mat = child.mesh.surface_get_material(0)
				if mat and mat is StandardMaterial3D:
					var original_emission = mat.emission
					mat.emission_enabled = true
					mat.emission = Color.RED
					tween.tween_callback(func(): 
						mat.emission = original_emission
						mat.emission_enabled = false
					).set_delay(0.15)

func _on_body_entered(body: Node3D) -> void:
	# Collision with player or enemy
	if body is Player:
		return  # Don't damage from player collision
	
func _on_area_entered(area: Area3D) -> void:
	# Hit by enemy (collision)
	if area.is_in_group("enemy"):
		take_damage(1)

func set_combat_enabled(enabled: bool) -> void:
	combat_enabled = enabled
	if enabled:
		_fire_cooldown = randf_range(0.0, fire_rate)  # Randomize first shot
