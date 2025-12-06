extends Node
class_name Main

## Main scene that sets up the game
## Contains SubViewport for low-res rendering with CRT filter
## Implements CINEMATIC → QTE → COMBAT state machine

enum State { CINEMATIC, QTE, COMBAT }

@onready var game_viewport: SubViewport = $SubViewportContainer/GameViewport
@onready var player: Player = $SubViewportContainer/GameViewport/Player
@onready var wingman: Wingman = $SubViewportContainer/GameViewport/Wingman
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
@export var combat_duration: float = 18.0
@export var summary_duration: float = 3.0

# Combat results tracking
var _combat_kills: int = 0
var _combat_damage_taken: int = 0
var _pre_combat_score: int = 0
var _pre_combat_shield: int = 0
var _pre_combat_carrier: int = 0

# Kill streak tracking for comms
var _kill_streak: int = 0
var _last_kill_time: float = 0.0
const KILL_STREAK_WINDOW: float = 2.0  # Seconds between kills for streak

# Cinematic comms sequence (speaker_id, text, duration, vo_id)
var _cinematic_comms: Array = [
	["STONE", "Convoy Omega is all we've got left. You lose it, we lose the war.", 3.5, "stone_brief_01"],
	["RAZOR", "Try not to shoot the friendlies this time, Rider.", 2.5, "razor_snark_01"],
	["RIDER", "Contact in five... four... three...", 2.5, "rider_countdown_01"],
]
var _comms_index: int = 0
var _comms_timer: float = 0.0

func _ready() -> void:

	# Set up connections
	game_controller.setup_hud(hud)
	
	# Add player to group for easy finding
	player.add_to_group("player")
	
	# Connect game controller signals for comms
	game_controller.enemy_killed_signal.connect(_on_enemy_killed)
	game_controller.enemy_escaped_signal.connect(_on_enemy_escaped)
	game_controller.carrier_threshold_crossed.connect(_on_carrier_threshold)
	
	# Connect wingman death
	if wingman:
		wingman.wingman_killed.connect(_on_wingman_killed)
	
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
	_comms_index = 0
	_comms_timer = 0.0
	hud.hide_crosshair()
	hud.show_chatter("")  # Clear old chatter label
	Comms.clear()  # Clear any pending comms

func _update_cinematic(delta: float) -> void:
	# Display comms messages periodically
	_comms_timer += delta
	var comms_interval = cinematic_duration / (_cinematic_comms.size() + 1)
	
	if _comms_index < _cinematic_comms.size():
		if _comms_timer > comms_interval:
			_comms_timer = 0.0
			var msg = _cinematic_comms[_comms_index]
			# Support both old format (3 elements) and new format (4 elements with vo_id)
			var vo_id := ""
			if msg.size() > 3:
				vo_id = msg[3]
			Comms.say(msg[0], msg[1], msg[2], vo_id)
			_comms_index += 1
	
	# Transition to QTE after duration
	if state_time > cinematic_duration:
		hud.show_chatter("")
		trigger_qte()

## QTE state

func _enter_qte() -> void:
	print("[STATE] Entering QTE")
	player.input_enabled = false
	enemy_spawner.spawning_enabled = false
	
	# Slow time for dramatic effect
	Engine.time_scale = 0.7
	
	# Comms: Vera announces incoming threat (with VO)
	Comms.say_immediate("VERA", "Incoming threat detected. Stand by for tactical options.", 3.0, "vera_contact_01")
	
	# Spawn QTE overlay
	_qte_overlay = QTE_OVERLAY_SCENE.instantiate()
	$HUDLayer.add_child(_qte_overlay)
	_qte_overlay.choice_made.connect(_on_qte_choice)
	_qte_overlay.start_countdown(qte_timeout)
	
	# Play UI blip for QTE popup
	if has_node("/root/Audio"):
		get_node("/root/Audio").play_sfx("ui_blip")

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
	
	# Restore normal time
	Engine.time_scale = 1.0
	
	# Configure combat based on choice
	match choice_id:
		"evade":
			# Fewer enemies, but take a small scripted hit
			enemy_spawner.configure_wave("evade")
			game_controller.player_hit(10)  # Scripted graze damage
			Comms.say_immediate("VERA", "Evading. You'll be alone out front for a few seconds.", 2.5, "vera_qte_evade_01")
			player.trigger_camera_shake(0.3, 0.15)
		"hold":
			# More enemies, higher risk/reward
			enemy_spawner.configure_wave("hold")
			Comms.say_immediate("VERA", "Holding course. Expect heavy intercept in your lane.", 2.5, "vera_qte_held_01")
	
	enter_state(State.COMBAT)

## COMBAT state

func _enter_combat() -> void:
	print("[STATE] Entering COMBAT")
	player.input_enabled = true
	enemy_spawner.spawning_enabled = true
	hud.show_crosshair()
	
	# Start combat music
	if has_node("/root/Audio"):
		get_node("/root/Audio").play_music("sortie")
	
	# Enable wingman combat
	if wingman and wingman.is_alive:
		wingman.set_combat_enabled(true)
	
	# Reset combat tracking
	game_controller.reset_combat_tracking()
	_kill_streak = 0
	
	# Track combat stats
	_combat_kills = 0
	_combat_damage_taken = 0
	_pre_combat_score = game_controller.score
	_pre_combat_shield = game_controller.shield
	_pre_combat_carrier = game_controller.carrier_integrity
	
	# Clear any pending comms after a moment
	await get_tree().create_timer(2.5).timeout
	if state == State.COMBAT:
		hud.show_chatter("")

func _update_combat(_delta: float) -> void:
	# End combat window after duration
	if state_time > combat_duration:
		_end_combat_window()

func _end_combat_window() -> void:
	print("[COMBAT] Window ended")
	
	# Disable player input immediately
	player.input_enabled = false
	enemy_spawner.spawning_enabled = false
	hud.hide_crosshair()
	
	# Disable wingman combat
	if wingman and wingman.is_alive:
		wingman.set_combat_enabled(false)
	
	# Calculate combat results
	var score_gained = game_controller.score - _pre_combat_score
	var damage_taken = _pre_combat_shield - game_controller.shield
	var carrier_damage = _pre_combat_carrier - game_controller.carrier_integrity
	var kills = game_controller.enemies_killed_this_combat
	var escapes = game_controller.enemies_escaped_this_combat
	
	# Show combat summary based on QTE choice
	var summary_text: String
	match last_qte_choice:
		"evade":
			summary_text = "EVADE MANEUVER COMPLETE\nKills: %d | Escaped: %d\nDamage: %d | Carrier: -%d | Score: +%d" % [kills, escapes, damage_taken, carrier_damage, score_gained]
		"hold":
			summary_text = "HELD THE LINE\nKills: %d | Escaped: %d\nDamage: %d | Carrier: -%d | Score: +%d" % [kills, escapes, damage_taken, carrier_damage, score_gained]
		_:
			summary_text = "ENGAGEMENT COMPLETE\nKills: %d | Escaped: %d\nDamage: %d | Carrier: -%d | Score: +%d" % [kills, escapes, damage_taken, carrier_damage, score_gained]
	
	hud.show_combat_summary(summary_text)
	
	# Wait for summary to display, then continue
	await get_tree().create_timer(summary_duration).timeout
	
	hud.hide_combat_summary()
	
	# Post-combat comms based on performance (with VO)
	if escapes > 3:
		Comms.say("STONE", "Too many bogeys passing us. Focus your fire, Lieutenant!", 3.0, "stone_chewout_01")
	elif kills > 8:
		Comms.say("SPARKS", "Minimal scorch marks. I can work with this.", 3.0, "sparks_post_ok_01")
	elif damage_taken > 30:
		Comms.say("SPARKS", "Next time you want vent art, ask before you shred the hull.", 3.0, "sparks_post_bad_01")
	else:
		Comms.say("SPARKS", "Minimal scorch marks. I can work with this.", 3.0, "sparks_post_ok_01")
	
	# Fade music at end of combat
	if has_node("/root/Audio"):
		get_node("/root/Audio").fade_out_music(2.0)
	
	# Small delay before returning to cinematic
	await get_tree().create_timer(2.0).timeout
	
	if wingman and wingman.is_alive:
		Comms.say("RAZOR", "Not terrible. For you.", 2.5, "razor_praise_01")
	else:
		Comms.say("STONE", "Razor's gone. Stay focused, Rider.", 2.5)
	
	await get_tree().create_timer(1.5).timeout
	
	enter_state(State.CINEMATIC)

func _clear_enemies() -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		enemy.queue_free()

## Event handlers for comms

func _on_enemy_killed(_enemy: Enemy) -> void:
	# Track kill streaks
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - _last_kill_time < KILL_STREAK_WINDOW:
		_kill_streak += 1
	else:
		_kill_streak = 1
	_last_kill_time = current_time
	
	# Comms for kill streaks (only during combat to avoid spam)
	if state == State.COMBAT:
		if _kill_streak == 3:
			Comms.say("RAZOR", "Nice shooting, Rider!", 1.5)
		elif _kill_streak == 5:
			Comms.say("SPARKS", "Five in a row! Keep it up!", 1.5)
		elif _kill_streak >= 7:
			Comms.say("VERA", "Impressive kill streak detected.", 1.5)

func _on_enemy_escaped(_enemy: Enemy) -> void:
	# Reset kill streak on escape
	_kill_streak = 0
	
	# Comms for escapes (limited to avoid spam)
	if state == State.COMBAT:
		var escapes = game_controller.enemies_escaped_this_combat
		if escapes == 2:
			Comms.say("RAZOR", "They're getting through! Watch your six!", 2.0)
		elif escapes == 4:
			Comms.say("STONE", "Too many bogeys passing us. Focus fire!", 2.0)
	
	# Camera shake on carrier damage
	player.trigger_camera_shake(0.15, 0.1)

func _on_carrier_threshold(threshold: int) -> void:
	# Major comms warnings at carrier damage thresholds
	match threshold:
		75:
			Comms.say_immediate("VERA", "Warning: Carrier integrity at 75 percent.", 2.5)
		50:
			Comms.say_immediate("STONE", "Too many bogeys passing us. Focus your fire, Lieutenant!", 3.0, "stone_chewout_01")
			player.trigger_camera_shake(0.3, 0.2)
		25:
			Comms.say_immediate("VERA", "CRITICAL: Carrier integrity failing. Recommend immediate defensive action.", 3.5)
			player.trigger_camera_shake(0.5, 0.3)

func _on_wingman_killed() -> void:
	# Already handled in Wingman.gd with Comms, but we can add player shake
	player.trigger_camera_shake(0.6, 0.4)
