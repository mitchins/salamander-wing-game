extends Node3D
class_name Explosion

## Simple explosion effect using GPUParticles3D
## Auto-destroys after particles finish

@export var lifetime: float = 1.0

var _time_alive: float = 0.0
var _initial_light_energy: float = 0.0
@onready var light: OmniLight3D = $OmniLight3D

func _ready() -> void:
	# Start particle emission
	$GPUParticles3D.emitting = true
	
	# Store initial light energy for fading
	if light:
		_initial_light_energy = light.light_energy
	
	# Queue free after lifetime
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)

func _process(delta: float) -> void:
	_time_alive += delta
	
	# Fade out the light
	if light and _initial_light_energy > 0:
		var t := _time_alive / lifetime
		light.light_energy = _initial_light_energy * (1.0 - t * t)  # Quadratic falloff

