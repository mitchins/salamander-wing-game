extends Control
class_name QTEOverlay

## QTE (Quick Time Event) overlay for decision moments
## Displays two big buttons with keyboard shortcuts

signal choice_made(choice_id: String)

@onready var countdown_label: Label = $CenterContainer/VBoxContainer/CountdownLabel
@onready var evade_button: Button = $CenterContainer/VBoxContainer/EvadeButton
@onready var hold_button: Button = $CenterContainer/VBoxContainer/HoldButton

var _countdown: float = 4.0
var _choice_made: bool = false

func _ready() -> void:
	evade_button.pressed.connect(_on_evade_pressed)
	hold_button.pressed.connect(_on_hold_pressed)
	
	# Focus first button for gamepad support
	evade_button.grab_focus()

func _process(delta: float) -> void:
	if _choice_made:
		return
	
	_countdown -= delta
	if _countdown > 0:
		countdown_label.text = "DECIDE: %.1f" % _countdown
	else:
		countdown_label.text = "TIME'S UP!"

func _unhandled_input(event: InputEvent) -> void:
	if _choice_made:
		return
	
	# Keyboard shortcuts
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_on_evade_pressed()
				get_viewport().set_input_as_handled()
			KEY_2:
				_on_hold_pressed()
				get_viewport().set_input_as_handled()

func start_countdown(duration: float) -> void:
	_countdown = duration

func _on_evade_pressed() -> void:
	if _choice_made:
		return
	_choice_made = true
	_play_ui_sound()
	choice_made.emit("evade")
	queue_free()

func _on_hold_pressed() -> void:
	if _choice_made:
		return
	_choice_made = true
	_play_ui_sound()
	choice_made.emit("hold")
	queue_free()

func _play_ui_sound() -> void:
	if has_node("/root/Audio"):
		get_node("/root/Audio").play_sfx("ui_blip")
