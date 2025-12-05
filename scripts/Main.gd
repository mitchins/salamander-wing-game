extends Node
class_name Main

## Main scene that sets up the game
## Contains SubViewport for low-res rendering with CRT filter

@onready var game_viewport: SubViewport = $SubViewportContainer/GameViewport
@onready var player: Player = $SubViewportContainer/GameViewport/Player
@onready var game_controller: GameController = $GameController
@onready var enemy_spawner: EnemySpawner = $SubViewportContainer/GameViewport/EnemySpawner
@onready var hud: Control = $HUDLayer/HUD

func _ready() -> void:
	# Set up connections
	game_controller.setup_hud(hud)
	
	# Add player to group for easy finding
	player.add_to_group("player")
