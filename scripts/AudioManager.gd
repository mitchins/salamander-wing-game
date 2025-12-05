extends Node
class_name AudioManager

## Central audio manager for all game sounds
## Handles SFX pooling, music playback, and comms voice with ducking

const SFX_PATHS := {
	"player_laser": "res://audio/sfx/player_laser.mp3",
	"enemy_laser": "res://audio/sfx/enemy_laser.mp3",
	"explosion_small": "res://audio/sfx/explosion_small.mp3",
	"explosion_large": "res://audio/sfx/explosion_large.mp3",
	"shield_hit": "res://audio/sfx/shield_hit.mp3",
	"carrier_hit": "res://audio/sfx/carrier_hit.mp3",
	"ui_blip": "res://audio/sfx/ui_blip.mp3",
	"alarm_low_carrier": "res://audio/sfx/alarm_low_carrier.mp3"
}

const MUSIC_PATHS := {
	"sortie": "res://audio/music/loop_sortie.mp3"
}

var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _comms_player: AudioStreamPlayer
var _sfx_cache: Dictionary = {}
var _music_cache: Dictionary = {}

# Ducking state
var _is_ducking: bool = false
var _duck_tween: Tween = null

func _ready() -> void:
	# Create pool of SFX players for overlapping sounds
	for i in range(8):
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_players.append(p)
	
	# Music player
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	_music_player.autoplay = false
	add_child(_music_player)
	
	# Comms voice player (radio-filtered)
	_comms_player = AudioStreamPlayer.new()
	_comms_player.bus = "Comms"
	add_child(_comms_player)

## Play a sound effect by ID
func play_sfx(id: String, volume_db: float = 0.0) -> void:
	if not SFX_PATHS.has(id):
		push_warning("AudioManager: Unknown SFX id '%s'" % id)
		return
	
	var stream := _load_sfx(SFX_PATHS[id])
	if stream == null:
		return
	
	# Find an available player from the pool
	for p in _sfx_players:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.play()
			return
	
	# All players busy - use first one (will cut off oldest sound)
	_sfx_players[0].stream = stream
	_sfx_players[0].volume_db = volume_db
	_sfx_players[0].play()

## Play a sound effect with pitch variation for variety
func play_sfx_varied(id: String, pitch_min: float = 0.95, pitch_max: float = 1.05) -> void:
	if not SFX_PATHS.has(id):
		push_warning("AudioManager: Unknown SFX id '%s'" % id)
		return
	
	var stream := _load_sfx(SFX_PATHS[id])
	if stream == null:
		return
	
	for p in _sfx_players:
		if not p.playing:
			p.stream = stream
			p.pitch_scale = randf_range(pitch_min, pitch_max)
			p.play()
			return
	
	_sfx_players[0].stream = stream
	_sfx_players[0].pitch_scale = randf_range(pitch_min, pitch_max)
	_sfx_players[0].play()

## Start playing music track
func play_music(id: String) -> void:
	if not MUSIC_PATHS.has(id):
		push_warning("AudioManager: Unknown music id '%s'" % id)
		return
	
	var stream := _load_music(MUSIC_PATHS[id])
	if stream == null:
		return
	
	# Don't restart if same track already playing
	if _music_player.stream == stream and _music_player.playing:
		return
	
	_music_player.stream = stream
	_music_player.play()

## Stop music
func stop_music() -> void:
	_music_player.stop()

## Fade out music over duration
func fade_out_music(duration: float = 1.0) -> void:
	if not _music_player.playing:
		return
	
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", -40.0, duration)
	tween.tween_callback(_music_player.stop)
	tween.tween_callback(func(): _music_player.volume_db = 0.0)

## Play voice clip through Comms bus (radio-filtered)
func play_comms_voice(stream: AudioStream) -> void:
	if stream == null:
		return
	
	# Stop any current voice
	if _comms_player.playing:
		_comms_player.stop()
	
	_comms_player.stream = stream
	_comms_player.play()
	
	# Duck music while voice plays
	_duck_music(true)
	
	# Restore music when done
	if not _comms_player.finished.is_connected(_on_comms_finished):
		_comms_player.finished.connect(_on_comms_finished, CONNECT_ONE_SHOT)

func _on_comms_finished() -> void:
	_duck_music(false)

## Duck/unduck music for voice clarity
func _duck_music(active: bool) -> void:
	var bus_idx := AudioServer.get_bus_index("Music")
	if bus_idx < 0:
		return
	
	var target_db := -10.0 if active else 0.0
	
	# Cancel any existing duck tween
	if _duck_tween and _duck_tween.is_valid():
		_duck_tween.kill()
	
	# Smooth transition
	_duck_tween = create_tween()
	var current_db := AudioServer.get_bus_volume_db(bus_idx)
	_duck_tween.tween_method(
		func(db: float): AudioServer.set_bus_volume_db(bus_idx, db),
		current_db,
		target_db,
		0.15
	)
	_is_ducking = active

## Load and cache SFX
func _load_sfx(path: String) -> AudioStream:
	if _sfx_cache.has(path):
		return _sfx_cache[path]
	
	if not ResourceLoader.exists(path):
		push_warning("AudioManager: Missing SFX at '%s'" % path)
		return null
	
	var s: AudioStream = load(path)
	_sfx_cache[path] = s
	return s

## Load and cache music
func _load_music(path: String) -> AudioStream:
	if _music_cache.has(path):
		return _music_cache[path]
	
	if not ResourceLoader.exists(path):
		push_warning("AudioManager: Missing music at '%s'" % path)
		return null
	
	var m: AudioStream = load(path)
	# Enable looping for music
	if m is AudioStreamOggVorbis:
		m.loop = true
	_music_cache[path] = m
	return m
