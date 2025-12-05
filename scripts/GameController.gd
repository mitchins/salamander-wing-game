extends Node
class_name GameController

## Central game state manager
## Tracks score, shield, carrier integrity, and handles game over

signal score_changed(new_score: int)
signal shield_changed(new_shield: int)
signal carrier_integrity_changed(new_integrity: int)
signal carrier_threshold_crossed(threshold: int)  # Emits at 75, 50, 25
signal enemy_killed_signal(enemy: Enemy)
signal enemy_escaped_signal(enemy: Enemy)
signal game_over_triggered

@export var starting_shield: int = 100
@export var starting_carrier_integrity: int = 100
@export var restart_delay: float = 3.0

var score: int = 0
var shield: int = 100
var carrier_integrity: int = 100
var game_over: bool = false

# Combat tracking
var enemies_killed_this_combat: int = 0
var enemies_escaped_this_combat: int = 0
var _last_carrier_threshold: int = 100  # Track which thresholds we've crossed

var _hud: Control = null

func _ready() -> void:
	add_to_group("game_controller")
	shield = starting_shield
	carrier_integrity = starting_carrier_integrity
	score = 0
	game_over = false
	_last_carrier_threshold = 100

func setup_hud(hud: Control) -> void:
	_hud = hud
	_update_hud()

func reset_combat_tracking() -> void:
	## Call at start of each combat phase
	enemies_killed_this_combat = 0
	enemies_escaped_this_combat = 0

func add_score(points: int) -> void:
	if game_over:
		return
	score += points
	score_changed.emit(score)
	_update_hud()

func on_enemy_killed(enemy: Enemy) -> void:
	## Called when player kills an enemy
	if game_over:
		return
	enemies_killed_this_combat += 1
	enemy_killed_signal.emit(enemy)
	print("[GAME] Enemy killed! Total this combat: %d" % enemies_killed_this_combat)

func on_enemy_escaped(enemy: Enemy) -> void:
	## Called when an enemy escapes past the player
	if game_over:
		return
	enemies_escaped_this_combat += 1
	
	# Damage carrier
	var damage = enemy.damage_if_escapes
	carrier_integrity = max(0, carrier_integrity - damage)
	carrier_integrity_changed.emit(carrier_integrity)
	
	# Check threshold crossings (75, 50, 25)
	_check_carrier_thresholds()
	
	# Update HUD with flash effect
	if _hud and _hud.has_method("flash_carrier_damage"):
		_hud.flash_carrier_damage()
	_update_hud()
	
	enemy_escaped_signal.emit(enemy)
	print("[GAME] Enemy escaped! Carrier integrity: %d (-%d)" % [carrier_integrity, damage])
	
	# Check for carrier destruction
	if carrier_integrity <= 0:
		_trigger_carrier_destroyed()

func _check_carrier_thresholds() -> void:
	## Emit signals when crossing 75%, 50%, 25% thresholds
	var thresholds = [75, 50, 25]
	for threshold in thresholds:
		if _last_carrier_threshold > threshold and carrier_integrity <= threshold:
			carrier_threshold_crossed.emit(threshold)
			_last_carrier_threshold = threshold
			print("[GAME] Carrier threshold crossed: %d%%" % threshold)

func _trigger_carrier_destroyed() -> void:
	## Carrier destroyed = mission failed
	print("[GAME] CARRIER DESTROYED - MISSION FAILED")
	game_over = true
	game_over_triggered.emit()
	
	if _hud:
		_hud.show_carrier_destroyed()
	
	# Restart after delay
	await get_tree().create_timer(restart_delay + 1.0).timeout
	get_tree().reload_current_scene()

func player_hit(damage: int) -> void:
	if game_over:
		return
	
	shield = max(0, shield - damage)
	shield_changed.emit(shield)
	_update_hud()
	
	if shield <= 0:
		_trigger_game_over()

func _trigger_game_over() -> void:
	game_over = true
	game_over_triggered.emit()
	
	if _hud:
		_hud.show_game_over()
	
	# Restart after delay
	await get_tree().create_timer(restart_delay).timeout
	get_tree().reload_current_scene()

func _update_hud() -> void:
	if _hud:
		_hud.update_score(score)
		_hud.update_shield(shield)
		if _hud.has_method("update_carrier_integrity"):
			_hud.update_carrier_integrity(carrier_integrity)
