extends Node
class_name MissionDirector

## MissionDirector - JSON-driven timeline choreography system
## Manages mission phases, beats, and event dispatching

signal cue_vo(speaker: String, line: String)
signal cue_spawn_wave(wave_id: String, count: int, pattern: String)
signal cue_qte(qte_type: String, difficulty: String)
signal cue_music(track: String, action: String)
signal cue_objective(text: String)
signal phase_changed(phase_name: String)
signal mission_complete()
signal mission_failed()

@export_file("*.json") var mission_file: String = ""

var mission_data: Dictionary = {}
var current_phase: Dictionary = {}
var current_phase_name: String = ""
var phase_timer: float = 0.0
var beats_queue: Array = []
var is_running: bool = false
var _pending_beats: Array = []

func _ready() -> void:
	if mission_file != "":
		load_mission(mission_file)

func load_mission(path: String) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("MissionDirector: Failed to load mission file: %s" % path)
		return false
	
	var json := JSON.new()
	var parse_result := json.parse(file.get_as_text())
	file.close()
	
	if parse_result != OK:
		push_error("MissionDirector: JSON parse error: %s" % json.get_error_message())
		return false
	
	mission_data = json.data
	print("MissionDirector: Loaded mission '%s'" % mission_data.get("mission_name", "Unknown"))
	return true

func start_mission() -> void:
	if mission_data.is_empty():
		push_error("MissionDirector: No mission data loaded")
		return
	
	var phases: Array = mission_data.get("phases", [])
	if phases.is_empty():
		push_error("MissionDirector: Mission has no phases")
		return
	
	is_running = true
	_enter_phase(phases[0].get("name", ""))

func stop_mission() -> void:
	is_running = false
	current_phase = {}
	current_phase_name = ""
	_pending_beats.clear()

func _process(delta: float) -> void:
	if not is_running or current_phase.is_empty():
		return
	
	phase_timer += delta
	_process_beats()
	
	# Check phase duration
	var duration: float = current_phase.get("duration", -1.0)
	if duration > 0 and phase_timer >= duration:
		_exit_current_phase()

func _enter_phase(phase_name: String) -> void:
	var phases: Array = mission_data.get("phases", [])
	for phase in phases:
		if phase.get("name", "") == phase_name:
			current_phase = phase
			current_phase_name = phase_name
			phase_timer = 0.0
			
			# Queue beats for this phase
			_pending_beats = phase.get("beats", []).duplicate(true)
			
			# Execute on_enter events
			var on_enter: Array = phase.get("on_enter", [])
			for event in on_enter:
				_dispatch_beat(event)
			
			phase_changed.emit(phase_name)
			print("MissionDirector: Entered phase '%s'" % phase_name)
			return
	
	push_error("MissionDirector: Phase '%s' not found" % phase_name)

func _exit_current_phase() -> void:
	var exit_to: String = current_phase.get("exit_to", "")
	
	if exit_to == "mission_complete":
		is_running = false
		mission_complete.emit()
		print("MissionDirector: Mission complete!")
	elif exit_to == "mission_failed":
		is_running = false
		mission_failed.emit()
		print("MissionDirector: Mission failed!")
	elif exit_to != "":
		_enter_phase(exit_to)
	else:
		# No exit defined, try next phase in sequence
		var phases: Array = mission_data.get("phases", [])
		for i in range(phases.size()):
			if phases[i].get("name", "") == current_phase_name:
				if i + 1 < phases.size():
					_enter_phase(phases[i + 1].get("name", ""))
				else:
					is_running = false
					mission_complete.emit()
				return

func _process_beats() -> void:
	var beats_to_remove: Array = []
	
	for beat in _pending_beats:
		var trigger_time: float = beat.get("time", 0.0)
		if phase_timer >= trigger_time:
			_dispatch_beat(beat)
			beats_to_remove.append(beat)
	
	for beat in beats_to_remove:
		_pending_beats.erase(beat)

func _dispatch_beat(beat: Dictionary) -> void:
	var beat_type: String = beat.get("type", "")
	
	match beat_type:
		"vo":
			var speaker: String = beat.get("speaker", "")
			var line: String = beat.get("line", "")
			cue_vo.emit(speaker, line)
		
		"spawn_wave":
			var wave_id: String = beat.get("wave_id", "")
			var count: int = beat.get("count", 3)
			var pattern: String = beat.get("pattern", "frontal")
			cue_spawn_wave.emit(wave_id, count, pattern)
		
		"qte":
			var qte_type: String = beat.get("qte_type", "dodge")
			var difficulty: String = beat.get("difficulty", "normal")
			cue_qte.emit(qte_type, difficulty)
		
		"music":
			var track: String = beat.get("track", "")
			var action: String = beat.get("action", "play")
			cue_music.emit(track, action)
		
		"objective":
			var text: String = beat.get("text", "")
			cue_objective.emit(text)
		
		_:
			print("MissionDirector: Unknown beat type '%s'" % beat_type)

## External triggers to advance phases
func trigger_phase(phase_name: String) -> void:
	if is_running:
		_enter_phase(phase_name)

func trigger_next_phase() -> void:
	if is_running:
		_exit_current_phase()

## Query functions
func get_current_phase() -> String:
	return current_phase_name

func get_phase_progress() -> float:
	var duration: float = current_phase.get("duration", -1.0)
	if duration <= 0:
		return 0.0
	return clampf(phase_timer / duration, 0.0, 1.0)
