extends Node
class_name Main

## Main scene that sets up the game
## Contains SubViewport for low-res rendering with CRT filter
## Implements CINEMATIC → QTE → COMBAT state machine

enum State { CINEMATIC, QTE, COMBAT }

@onready var game_viewport: SubViewport = $SubViewportContainer/GameViewport
@onready var player: Player = $SubViewportContainer/GameViewport/Player
@onready var game_controller: GameController = $GameController
@onready var enemy_spawner: EnemySpawner = $SubViewportContainer/GameViewport/EnemySpawner
@onready var hud: Control = $HUDLayer/HUD

# State machine
var state: State = State.CINEMATIC
var state_time: float = 0.0

# QTE settings
var last_qte_choice: String = ""
var _qte_overlay: Control = null
const QTE_OVERLAY_SCENE = preload("res://ui/QTEOverlay.tscn")

# Timing settings (tweak these for pacing)
@export var cinematic_duration: float = 8.0
@export var qte_timeout: float = 4.0
@export var combat_duration: float = 20.0

# Chatter lines for cinematic segments
var _chatter_lines: Array[String] = [
	"RAZOR: Alright Rider, stay sharp out there.",
	"RIDER: Copy that. Sensors picking up movement ahead.",
	"RAZOR: Don't get cocky. These bogeys are fast.",
	"RIDER: Contact in 5... 4... 3...",
]
var _chatter_index: int = 0
var _chatter_timer: float = 0.0

func _ready() -> void:
	# Set up connections
	game_controller.setup_hud(hud)
	
	# Add player to group for easy finding
	player.add_to_group("player")
	
	# Start in cinematic mode
	enter_state(State.CINEMATIC)

func _process(delta: float) -> void:
	if game_controller.game_over:
		return
	
	state_time += delta
	
	match state:
		State.CINEMATIC:
			_update_cinematic(delta)
		State.QTE:
			_update_qte(delta)
		State.COMBAT:
			_update_combat(delta)

## State management

func enter_state(new_state: State) -> void:
	# Exit current state
	_exit_state(state)
	
	# Enter new state
	state = new_state
	state_time = 0.0
	
	match new_state:
		State.CINEMATIC:
			_enter_cinematic()
		State.QTE:
			_enter_qte()
		State.COMBAT:
			_enter_combat()

func _exit_state(old_state: State) -> void:
	match old_state:
		State.QTE:
			# Clean up QTE overlay if it exists
			if _qte_overlay and is_instance_valid(_qte_overlay):
				_qte_overlay.queue_free()
				_qte_overlay = null
		State.COMBAT:
			# Clear remaining enemies when exiting combat
			_clear_enemies()

## CINEMATIC state

func _enter_cinematic() -> void:
	print("[STATE] Entering CINEMATIC")
	player.input_enabled = false
	enemy_spawner.spawning_enabled = false
	_chatter_index = 0
	_chatter_timer = 0.0
	hud.hide_crosshair()
	hud.show_chatter("")

func _update_cinematic(delta: float) -> void:
	# Display chatter lines periodically
	_chatter_timer += delta
	var chatter_interval = cinematic_duration / (_chatter_lines.size() + 1)
	
	if _chatter_index < _chatter_lines.size():
		if _chatter_timer > chatter_interval:
			_chatter_timer = 0.0
			hud.show_chatter(_chatter_lines[_chatter_index])
			_chatter_index += 1
	
	# Transition to QTE after duration
	if state_time > cinematic_duration:
		hud.show_chatter("")
		trigger_qte()

## QTE state

func _enter_qte() -> void:
	print("[STATE] Entering QTE")
	player.input_enabled = false
	enemy_spawner.spawning_enabled = false
	
	# Spawn QTE overlay
	_qte_overlay = QTE_OVERLAY_SCENE.instantiate()
	$HUDLayer.add_child(_qte_overlay)
	_qte_overlay.choice_made.connect(_on_qte_choice)
	_qte_overlay.start_countdown(qte_timeout)

func _update_qte(_delta: float) -> void:
	# Timeout - auto-pick "hold" if no choice made
	if state_time > qte_timeout:
		if _qte_overlay and is_instance_valid(_qte_overlay):
			print("[QTE] Timeout - defaulting to HOLD")
			_on_qte_choice("hold")

func trigger_qte() -> void:
	enter_state(State.QTE)

func _on_qte_choice(choice_id: String) -> void:
	print("[QTE] Choice made: %s" % choice_id)
	last_qte_choice = choice_id
	
	# Configure combat based on choice
	match choice_id:
		"evade":
			# Fewer enemies, but take a small hit
			enemy_spawner.spawn_interval = 2.5
			enemy_spawner.max_enemies = 6
			game_controller.player_hit(10)  # Scripted graze damage
			hud.show_chatter("RIDER: Breaking hard! Took a scrape...")
		"hold":
			# More enemies, higher risk/reward
			enemy_spawner.spawn_interval = 1.2
			enemy_spawner.max_enemies = 12
			hud.show_chatter("RIDER: Holding course. Here they come!")
	
	enter_state(State.COMBAT)

## COMBAT state

func _enter_combat() -> void:
	print("[STATE] Entering COMBAT")
	player.input_enabled = true
	enemy_spawner.spawning_enabled = true
	hud.show_crosshair()
	
	# Clear chatter after a moment
	await get_tree().create_timer(2.0).timeout
	if state == State.COMBAT:
		hud.show_chatter("")

func _update_combat(_delta: float) -> void:
	# End combat window after duration
	if state_time > combat_duration:
		_end_combat_window()

func _end_combat_window() -> void:
	print("[COMBAT] Window ended")
	hud.show_chatter("RAZOR: Good work, Rider. Returning to formation.")
	enter_state(State.CINEMATIC)

func _clear_enemies() -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		enemy.queue_free()
