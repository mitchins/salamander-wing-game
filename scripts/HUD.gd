extends Control
class_name HUD

## In-game HUD displaying shield, score, carrier integrity, crosshair, and combat summary
## Stays crisp (not affected by CRT shader)

const MAX_CHAIN: int = 16
const CHAIN_DECAY_TIME: float = 2.0

@onready var shield_label: Label = $MarginContainer/VBoxContainer/ShieldLabel
@onready var score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var carrier_label: Label = $MarginContainer/VBoxContainer/CarrierLabel
@onready var game_over_label: Label = $GameOverLabel
@onready var crosshair: Control = $Crosshair
@onready var chatter_label: Label = $ChatterContainer/ChatterLabel
@onready var combat_summary_container: PanelContainer = $CombatSummaryContainer
@onready var combat_summary_label: Label = $CombatSummaryContainer/CombatSummaryLabel
@onready var flash_overlay: ColorRect = $FlashOverlay

# Mission Director HUD elements
@onready var objective_label: Label = $ObjectiveLabel
@onready var kills_label: Label = $StatsPanel/KillsLabel
@onready var chain_label: Label = $StatsPanel/ChainLabel
@onready var freighters_label: Label = $StatsPanel/FreightersLabel
@onready var threat_ring: Control = $ThreatRing

var _carrier_flash_timer: float = 0.0
var _carrier_flash_duration: float = 0.3
var _chain: int = 1
var _chain_timer: float = 0.0

func _ready() -> void:
	if game_over_label:
		game_over_label.visible = false
	if chatter_label:
		chatter_label.text = ""
	if combat_summary_container:
		combat_summary_container.visible = false
	# Initialize mission director HUD elements
	if objective_label:
		objective_label.text = ""
	if kills_label:
		kills_label.text = "KILLS: 000"
	if chain_label:
		chain_label.visible = false
	if freighters_label:
		freighters_label.text = "FREIGHTERS: 3/3"

func _process(delta: float) -> void:
	# Handle carrier damage flash effect
	if _carrier_flash_timer > 0:
		_carrier_flash_timer -= delta
		if _carrier_flash_timer <= 0:
			if carrier_label:
				# Reset to appropriate color based on value
				_update_carrier_color(int(carrier_label.text.replace("CARRIER: ", "")))
	
	# Chain decay
	if _chain > 1:
		_chain_timer += delta
		if _chain_timer >= CHAIN_DECAY_TIME:
			_chain = 1
			_chain_timer = 0.0
			_update_chain_display()

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

## Screen flash effects
func flash_screen_damage() -> void:
	if flash_overlay:
		flash_overlay.flash_damage()

func flash_screen_carrier() -> void:
	if flash_overlay:
		flash_overlay.flash_carrier_damage()

func flash_screen_critical() -> void:
	if flash_overlay:
		flash_overlay.flash_critical()

## Mission Director HUD updates
func update_objective(text: String) -> void:
	if objective_label:
		objective_label.text = text

func update_kills(count: int) -> void:
	if kills_label:
		kills_label.text = "KILLS: %03d" % count
		# Add a chain kill
		_chain += 1
		_chain = mini(_chain, MAX_CHAIN)
		_chain_timer = 0.0
		_update_chain_display()

func update_chain(multiplier: int) -> void:
	_chain = clampi(multiplier, 1, MAX_CHAIN)
	_chain_timer = 0.0
	_update_chain_display()

func _update_chain_display() -> void:
	if chain_label:
		if _chain > 1:
			chain_label.text = "CHAIN x%d!" % _chain
			chain_label.visible = true
			# Flash effect for high chains
			if _chain >= 8:
				chain_label.modulate = Color(1, 0.3, 0.3)
			elif _chain >= 4:
				chain_label.modulate = Color(1, 1, 0.3)
			else:
				chain_label.modulate = Color.WHITE
		else:
			chain_label.visible = false

func update_freighters(current: int, total: int) -> void:
	if freighters_label:
		freighters_label.text = "FREIGHTERS: %d/%d" % [current, total]
		# Color based on status
		if current == 0:
			freighters_label.modulate = Color(1, 0.3, 0.3)  # Red - all lost
		elif current < total:
			freighters_label.modulate = Color(1, 1, 0.3)  # Yellow - some lost
		else:
			freighters_label.modulate = Color(0.3, 1, 0.3)  # Green - all safe

func update_threat_ring(enemies: Array[Node3D], friendlies: Array[Node3D], player: Node3D) -> void:
	if threat_ring:
		threat_ring.player_ref = player
		threat_ring.enemies = enemies
		threat_ring.friendlies = friendlies
