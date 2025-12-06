extends Node3D
class_name Freighter

## Freighter - Damageable convoy ship
## Emits signals when damaged or destroyed

signal damaged(freighter: Freighter, amount: int)
signal destroyed(freighter: Freighter)

@export var max_hp: int = 50
@export var freighter_name: String = "Freighter Alpha"

var current_hp: int = 50

func _ready() -> void:
	current_hp = max_hp
	add_to_group("freighters")

func take_damage(amount: int) -> void:
	current_hp -= amount
	damaged.emit(self, amount)
	
	# Flash effect
	_flash_damage()
	
	if current_hp <= 0:
		current_hp = 0
		_explode()

func _flash_damage() -> void:
	var mesh := get_node_or_null("Mesh") as MeshInstance3D
	if mesh and mesh.material_override:
		var original_color: Color = mesh.material_override.albedo_color
		mesh.material_override.albedo_color = Color.WHITE
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(mesh) and mesh.material_override:
			mesh.material_override.albedo_color = original_color

func _explode() -> void:
	destroyed.emit(self)
	
	# Spawn explosion effect if available
	var explosion_scene := load("res://scenes/Explosion.tscn")
	if explosion_scene:
		var explosion := explosion_scene.instantiate()
		explosion.global_position = global_position
		explosion.scale = Vector3(3, 3, 3)  # Larger explosion for freighter
		get_parent().add_child(explosion)
	
	queue_free()

func get_hp_percent() -> float:
	return float(current_hp) / float(max_hp)
