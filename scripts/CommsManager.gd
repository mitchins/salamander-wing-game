extends Node
class_name CommsManager

## Global Comms Manager - Wing Commander-style talking head system
## Usage: Comms.say("RAZOR", "Line of dialogue", 3.0)
##
## Character registry with callsigns, display names, colors, and portrait paths.
## VO clips can be added later via the audio_id parameter.

const DEFAULT_DURATION := 3.5

## Character registry - add new characters here
const CHARACTERS := {
	"RIDER": {
		"display_name": "Rider",
		"portrait_path": "res://portraits/rider.png",
		"color": Color(0.7, 1.0, 0.7)  # Soft green - player character
	},
	"RAZOR": {
		"display_name": "Razor",
		"portrait_path": "res://portraits/razor.png",
		"color": Color(1.0, 0.85, 0.3)  # Amber/gold - wingman
	},
	"SPARKS": {
		"display_name": "Sparks",
		"portrait_path": "res://portraits/sparks.png",
		"color": Color(0.5, 0.9, 1.0)  # Cyan - tech/mechanic
	},
	"VERA": {
		"display_name": "Lt. Kane",
		"portrait_path": "res://portraits/vera.png",
		"color": Color(1.0, 0.6, 0.4)  # Orange - ops officer
	},
	"STONE": {
		"display_name": "Col. Stone",
		"portrait_path": "res://portraits/stone.png",
		"color": Color(1.0, 0.75, 0.75)  # Pinkish - commander
	}
}

var _panel: Node = null  # CommsPanel instance
var _portraits_cache: Dictionary = {}
var _message_queue: Array = []  # Queue of pending messages
var _voice_player: AudioStreamPlayer = null

const COMMS_PANEL_SCENE = preload("res://ui/CommsPanel.tscn")

func _ready() -> void:
	# Instantiate CommsPanel and add to scene tree
	_panel = COMMS_PANEL_SCENE.instantiate()
	get_tree().root.call_deferred("add_child", _panel)
	
	# Set up voice player for future VO support
	_voice_player = AudioStreamPlayer.new()
	_voice_player.bus = "Master"  # Change to "VO" or "SFX" if those buses exist
	add_child(_voice_player)

func _process(_delta: float) -> void:
	# Process message queue
	if _panel and not _panel.is_showing() and _message_queue.size() > 0:
		var next_msg = _message_queue.pop_front()
		_show_message(next_msg.speaker_id, next_msg.text, next_msg.duration, next_msg.audio_id)

## Main API - call this from anywhere to show a comms message
## speaker_id: Character key from CHARACTERS dictionary (e.g., "RAZOR")
## text: Dialogue line to display
## duration: How long to show (default 3.5 seconds)
## audio_id: Optional voice clip filename (without path/extension)
func say(speaker_id: String, text: String, duration: float = DEFAULT_DURATION, audio_id: String = "") -> void:
	if not CHARACTERS.has(speaker_id):
		push_warning("CommsManager: Unknown speaker_id '%s'" % speaker_id)
		return
	
	# If panel is currently showing, queue this message
	if _panel and _panel.is_showing():
		_message_queue.append({
			"speaker_id": speaker_id,
			"text": text,
			"duration": duration,
			"audio_id": audio_id
		})
	else:
		_show_message(speaker_id, text, duration, audio_id)

## Immediately show a message (bypasses queue, interrupts current)
func say_immediate(speaker_id: String, text: String, duration: float = DEFAULT_DURATION, audio_id: String = "") -> void:
	if not CHARACTERS.has(speaker_id):
		push_warning("CommsManager: Unknown speaker_id '%s'" % speaker_id)
		return
	
	# Clear queue and show immediately
	_message_queue.clear()
	_show_message(speaker_id, text, duration, audio_id)

## Clear the message queue and hide current message
func clear() -> void:
	_message_queue.clear()
	if _panel:
		_panel.hide_message()

func _show_message(speaker_id: String, text: String, duration: float, audio_id: String) -> void:
	var char_data = CHARACTERS[speaker_id]
	var portrait := _get_portrait(char_data.get("portrait_path", ""))
	var display_name: String = char_data.get("display_name", speaker_id)
	var color: Color = char_data.get("color", Color.WHITE)
	
	if _panel:
		_panel.show_message(portrait, display_name, text, color, duration)
	
	_play_voice(audio_id)

func _get_portrait(path: String) -> Texture2D:
	if path == "":
		return null
	
	# Check cache first
	if _portraits_cache.has(path):
		return _portraits_cache[path]
	
	# Load and cache
	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path)
		_portraits_cache[path] = tex
		return tex
	else:
		# Create a placeholder texture if file doesn't exist
		var placeholder := _create_placeholder_portrait(path)
		_portraits_cache[path] = placeholder
		return placeholder

func _create_placeholder_portrait(path: String) -> ImageTexture:
	# Determine color based on character name in path
	var color := Color(0.3, 0.3, 0.35)  # Default grey
	if "rider" in path.to_lower():
		color = Color(0.3, 0.5, 0.35)
	elif "razor" in path.to_lower():
		color = Color(0.5, 0.45, 0.2)
	elif "sparks" in path.to_lower():
		color = Color(0.2, 0.4, 0.5)
	elif "vera" in path.to_lower():
		color = Color(0.5, 0.35, 0.25)
	elif "stone" in path.to_lower():
		color = Color(0.45, 0.35, 0.35)
	
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(color)
	
	# Simple border
	for x in range(64):
		for y in range(64):
			if x < 2 or x > 61 or y < 2 or y > 61:
				img.set_pixel(x, y, color.lightened(0.4))
	
	# Inner "face" area
	for x in range(16, 48):
		for y in range(12, 52):
			var current := img.get_pixel(x, y)
			img.set_pixel(x, y, current.darkened(0.2))
	
	var tex := ImageTexture.create_from_image(img)
	return tex

func _play_voice(audio_id: String) -> void:
	if audio_id == "":
		return
	
	var path := "res://vo/%s.ogg" % audio_id
	if ResourceLoader.exists(path):
		_voice_player.stream = load(path)
		_voice_player.play()
