extends Area3D
class_name EnemyBullet

## Enemy projectile - damages player and wingman when hit
## Slower than player bullets for dodge opportunity

@export var speed: float = 28.0  # Slower to allow dodging
@export var damage: int = 8
@export var lifetime: float = 3.5

var _direction: Vector3 = Vector3.FORWARD
var _life_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemy_bullet")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	global_position += _direction * speed * delta
	_life_timer += delta
	if _life_timer > lifetime:
		queue_free()

func set_direction(dir: Vector3) -> void:
	_direction = dir.normalized()
	if _direction.length_squared() > 0.001:
		look_at(global_position + _direction, Vector3.UP)

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		body.take_damage(damage)
		queue_free()

func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("wingman"):
		if area.has_method("take_damage"):
			area.take_damage(1)
		queue_free()
