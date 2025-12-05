extends Node
class_name GameController

## Central game state manager
## Tracks score, shield, and handles game over

signal score_changed(new_score: int)
signal shield_changed(new_shield: int)
signal game_over_triggered

@export var starting_shield: int = 100
@export var restart_delay: float = 3.0

var score: int = 0
var shield: int = 100
var game_over: bool = false

var _hud: Control = null

func _ready() -> void:
	add_to_group("game_controller")
	shield = starting_shield
	score = 0
	game_over = false

func setup_hud(hud: Control) -> void:
	_hud = hud
	_update_hud()

func add_score(points: int) -> void:
	if game_over:
		return
	score += points
	score_changed.emit(score)
	_update_hud()

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
