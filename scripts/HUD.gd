extends Control
class_name HUD

## In-game HUD displaying shield, score, and crosshair
## Stays crisp (not affected by CRT shader)

@onready var shield_label: Label = $MarginContainer/VBoxContainer/ShieldLabel
@onready var score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var game_over_label: Label = $GameOverLabel

func _ready() -> void:
	if game_over_label:
		game_over_label.visible = false

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
