extends Control
class_name HUD

## In-game HUD displaying shield, score, crosshair, and chatter
## Stays crisp (not affected by CRT shader)

@onready var shield_label: Label = $MarginContainer/VBoxContainer/ShieldLabel
@onready var score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var game_over_label: Label = $GameOverLabel
@onready var crosshair: Control = $Crosshair
@onready var chatter_label: Label = $ChatterContainer/ChatterLabel

func _ready() -> void:
	if game_over_label:
		game_over_label.visible = false
	if chatter_label:
		chatter_label.text = ""

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

func update_score(value: int) -> void:
	if score_label:
		score_label.text = "SCORE: %04d" % value

func show_game_over() -> void:
	if game_over_label:
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
