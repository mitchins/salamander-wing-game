extends Area3D
class_name Wingman

## Wingman AI - Razor
## Follows the player at an offset and actively engages enemies
## Can be killed by enemies if they collide

signal wingman_killed
signal wingman_kill(enemy: Enemy)

@export var follow_offset: Vector3 = Vector3(-3.0, -0.5, 2.0)
@export var follow_speed: float = 5.0
@export var fire_rate: float = 1.8
@export var bullet_scene: PackedScene
@export var explosion_scene: PackedScene
@export var hit_points: int = 3
@export var targeting_range: float = 60.0
@export var targeting_cone: float = 0.8

var is_alive: bool = true
var combat_enabled: bool = false

var _player: Node3D = null
var _fire_cooldown: float = 0.0
var _current_target: Enemy = null
var _game_controller: Node = null
var _bullet_spawn_point: Marker3D = null
var _wave_controller: Node = null
var _kills_this_combat: int = 0

func _ready() -> void:
	add_to_group("wingman")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("player")
	_game_controller = get_tree().get_first_node_in_group("game_controller")
	_bullet_spawn_point = Marker3D.new()
	_bullet_spawn_point.position = Vector3(0, 0, -1.5)
	add_child(_bullet_spawn_point)

func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	if _game_controller and _game_controller.game_over:
		return
	_update_follow(delta)
	if combat_enabled:
		_fire_cooldown -= delta
		_update_targeting()
		_try_fire()

func _update_follow(delta: float) -> void:
	if not _player:
		return
	
	# Calculate offset that accounts for player's steering
	var offset = follow_offset
	if _player.has_method("get_current_yaw"):
		# Bank with player's yaw
		var player_yaw = _player.get_current_yaw()
		offset.x = follow_offset.x + sin(player_yaw) * 1.5
		rotation.y = lerp_angle(rotation.y, player_yaw * 0.5, 3.0 * delta)
	
	var target_pos = _player.global_position + offset
	global_position = global_position.lerp(target_pos, follow_speed * delta)
	position.z = _player.position.z + follow_offset.z
	
	# Visual banking
	var offset_diff = target_pos.x - global_position.x
	rotation.z = lerp(rotation.z, clamp(offset_diff * 0.15, -0.4, 0.4), 4.0 * delta)

func _update_targeting() -> void:
	_current_target = null
	var closest_dist = targeting_range
	var forward = -global_transform.basis.z
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy is Enemy:
			continue
		var to_enemy = enemy.global_position - global_position
		var dist = to_enemy.length()
		if dist > targeting_range:
			continue
		var dir_to_enemy = to_enemy.normalized()
		var dot = forward.dot(dir_to_enemy)
		if dot > targeting_cone and dist < closest_dist:
			closest_dist = dist
			_current_target = enemy
	if _current_target and is_instance_valid(_current_target):
		var look_dir = (_current_target.global_position - global_position).normalized()
		var target_y = atan2(look_dir.x, -look_dir.z)
		rotation.y = lerp_angle(rotation.y, target_y, 0.15)

func _try_fire() -> void:
	if _fire_cooldown > 0:
		return
	if not _current_target or not is_instance_valid(_current_target):
		return
	if bullet_scene == null:
		return
	var to_target = _current_target.global_position - global_position
	var forward = -global_transform.basis.z
	var dot = forward.dot(to_target.normalized())
	if dot < targeting_cone * 0.9:
		return
	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = _bullet_spawn_point.global_position
	if bullet.has_method("set_forward_speed") and _player:
		bullet.set_forward_speed(_player.forward_speed)
	_fire_cooldown = fire_rate + randf_range(-0.3, 0.3)
	if has_node("/root/Audio"):
		get_node("/root/Audio").play_sfx_varied("player_laser", 0.85, 0.95)
	var target_ref = _current_target
	get_tree().create_timer(0.15).timeout.connect(func():
		if is_instance_valid(target_ref) and target_ref is Enemy:
			if randf() < 0.6:
				target_ref.take_damage(1)
				if not is_instance_valid(target_ref) or target_ref.state == Enemy.State.DEAD:
					_on_razor_kill()
	)

func _on_razor_kill() -> void:
	_kills_this_combat += 1
	wingman_kill.emit(_current_target)
	if _wave_controller and _wave_controller.has_method("on_razor_kill"):
		_wave_controller.on_razor_kill()
	if _kills_this_combat == 3:
		if has_node("/root/Comms"):
			get_node("/root/Comms").say("RAZOR", "Try to keep up, Rider.", 2.0)

func take_damage(amount: int = 1) -> void:
	if not is_alive:
		return
	hit_points -= amount
	if hit_points <= 0:
		_die()
	else:
		_flash_damage()
		if has_node("/root/Comms"):
			get_node("/root/Comms").say("RAZOR", "Taking hits! Cover me, Rider!", 2.0)

func _die() -> void:
	if not is_alive:
		return
	is_alive = false
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		get_tree().current_scene.add_child(explosion)
		explosion.global_position = global_position
		explosion.scale = Vector3(2.0, 2.0, 2.0)
	if has_node("/root/Comms"):
		get_node("/root/Comms").say_immediate("VERA", "Razor is down! Repeat, Razor is DOWN!", 3.0)
	wingman_killed.emit()
	visible = false
	set_physics_process(false)

func _flash_damage() -> void:
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
	if body is Player:
		return

func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("enemy"):
		take_damage(1)
	elif area.is_in_group("enemy_bullet"):
		take_damage(1)
		area.queue_free()

func set_combat_enabled(enabled: bool) -> void:
	combat_enabled = enabled
	if enabled:
		_fire_cooldown = randf_range(0.5, fire_rate)
		_kills_this_combat = 0
	else:
		_current_target = null

func set_wave_controller(controller: Node) -> void:
	_wave_controller = controller
