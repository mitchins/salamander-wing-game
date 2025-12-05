extends Node3D
class_name Explosion

## Simple explosion effect using GPUParticles3D
## Auto-destroys after particles finish

@export var lifetime: float = 1.0

func _ready() -> void:
	# Start particle emission
	$GPUParticles3D.emitting = true
	
	# Queue free after lifetime
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)
