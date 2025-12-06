extends Area3D
class_name Bullet

## Player bullet projectile
## Travels along set direction and destroys enemies on contact

@export var speed: float = 50.0
@export var lifetime: float = 3.0

var _direction: Vector3 = Vector3.FORWARD
var _player_forward_speed: float = 0.0
var _time_alive: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	# Move along direction
	global_position += _direction * (speed + _player_forward_speed) * delta
	
	# Lifetime check
	_time_alive += delta
	if _time_alive >= lifetime:
		queue_free()

func set_direction(dir: Vector3) -> void:
	_direction = dir.normalized()
	# Rotate bullet to face movement direction
	if _direction.length_squared() > 0.001:
		look_at(global_position + _direction, Vector3.UP)

func set_forward_speed(player_speed: float) -> void:
	_player_forward_speed = player_speed

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage()
		queue_free()

func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("enemy"):
		if area.has_method("take_damage"):
			area.take_damage()
		queue_free()
