extends CanvasLayer
class_name CommsPanel

## Wing Commander-style talking head / comms panel
## Shows character portrait, name, and dialogue text
## Controlled via CommsManager.say() API

@onready var panel_container: PanelContainer = $PanelContainer
@onready var portrait_rect: TextureRect = $PanelContainer/MarginContainer/HBoxContainer/Portrait
@onready var name_label: Label = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/NameLabel
@onready var text_label: Label = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/TextLabel

var _hide_timer: float = 0.0
var _visible_duration: float = 0.0
var _is_showing: bool = false

func _ready() -> void:
	layer = 11  # Above HUD layer (10)
	visible = false

func show_message(portrait: Texture2D, char_name: String, text: String, color: Color, duration: float) -> void:
	if portrait_rect:
		portrait_rect.texture = portrait
	if name_label:
		name_label.text = char_name
		name_label.modulate = color
	if text_label:
		text_label.text = text
	
	_visible_duration = duration
	_hide_timer = 0.0
	_is_showing = true
	visible = true

func hide_message() -> void:
	_is_showing = false
	visible = false

func is_showing() -> bool:
	return _is_showing

func _process(delta: float) -> void:
	if not _is_showing:
		return
	
	_hide_timer += delta
	if _hide_timer >= _visible_duration:
		hide_message()
