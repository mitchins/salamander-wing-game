extends Area3D
class_name Bullet

## Player bullet projectile
## Travels forward and destroys enemies on contact

@export var speed: float = 50.0
@export var lifetime: float = 3.0

var _player_forward_speed: float = 0.0
var _time_alive: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	# Move forward (negative Z is forward in Godot)
	position.z -= (speed + _player_forward_speed) * delta
	
	# Lifetime check
	_time_alive += delta
	if _time_alive >= lifetime:
		queue_free()

func set_forward_speed(player_speed: float) -> void:
	# Add player's forward speed so bullets always move faster than player
	_player_forward_speed = player_speed

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("enemy"):
		body.take_damage()
		queue_free()

func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("enemy"):
		area.take_damage()
		queue_free()
