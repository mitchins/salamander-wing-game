extends Control
class_name HUD

## In-game HUD displaying shield, score, carrier integrity, crosshair, and combat summary
## Stays crisp (not affected by CRT shader)

@onready var shield_label: Label = $MarginContainer/VBoxContainer/ShieldLabel
@onready var score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var carrier_label: Label = $MarginContainer/VBoxContainer/CarrierLabel
@onready var game_over_label: Label = $GameOverLabel
@onready var crosshair: Control = $Crosshair
@onready var chatter_label: Label = $ChatterContainer/ChatterLabel
@onready var combat_summary_container: PanelContainer = $CombatSummaryContainer
@onready var combat_summary_label: Label = $CombatSummaryContainer/CombatSummaryLabel

var _carrier_flash_timer: float = 0.0
var _carrier_flash_duration: float = 0.3

func _ready() -> void:
	if game_over_label:
		game_over_label.visible = false
	if chatter_label:
		chatter_label.text = ""
	if combat_summary_container:
		combat_summary_container.visible = false

func _process(delta: float) -> void:
	# Handle carrier damage flash effect
	if _carrier_flash_timer > 0:
		_carrier_flash_timer -= delta
		if _carrier_flash_timer <= 0:
			if carrier_label:
				# Reset to appropriate color based on value
				_update_carrier_color(int(carrier_label.text.replace("CARRIER: ", "")))

func update_shield(value: int) -> void:
	if shield_label:
		shield_label.text = "SHIELD: %d" % value
		# Color warning when low
		if value <= 25:
			shield_label.modulate = Color.RED
		elif value <= 50:
			shield_label.modulate = Color.YELLOW
		else:
			shield_label.modulate = Color.GREEN

func update_carrier_integrity(value: int) -> void:
	if carrier_label:
		carrier_label.text = "CARRIER: %d" % value
		_update_carrier_color(value)

func _update_carrier_color(value: int) -> void:
	if carrier_label:
		if value <= 25:
			carrier_label.modulate = Color.RED
		elif value <= 50:
			carrier_label.modulate = Color.YELLOW
		else:
			carrier_label.modulate = Color.CYAN

func flash_carrier_damage() -> void:
	## Flash the carrier label white when taking damage
	if carrier_label:
		carrier_label.modulate = Color.WHITE
		_carrier_flash_timer = _carrier_flash_duration

func update_score(value: int) -> void:
	if score_label:
		score_label.text = "SCORE: %04d" % value

func show_game_over() -> void:
	if game_over_label:
		game_over_label.text = "GAME OVER"
		game_over_label.visible = true

func show_carrier_destroyed() -> void:
	if game_over_label:
		game_over_label.text = "CARRIER DESTROYED\nMISSION FAILED"
		game_over_label.visible = true

func show_crosshair() -> void:
	if crosshair:
		crosshair.visible = true

func hide_crosshair() -> void:
	if crosshair:
		crosshair.visible = false

func show_chatter(text: String) -> void:
	if chatter_label:
		chatter_label.text = text

func show_combat_summary(text: String) -> void:
	if combat_summary_label:
		combat_summary_label.text = text
	if combat_summary_container:
		combat_summary_container.visible = true

func hide_combat_summary() -> void:
	if combat_summary_container:
		combat_summary_container.visible = false
