extends Node3D
class_name HitSpark

## Quick hit spark VFX - spawns on bullet impact
## Self-destructs after short lifetime

@export var lifetime: float = 0.25
@export var light_energy: float = 2.0

@onready var particles: GPUParticles3D = $Particles
@onready var light: OmniLight3D = $Light

var _time_alive: float = 0.0
var _initial_light_energy: float = 0.0

func _ready() -> void:
	if particles:
		particles.emitting = true
	if light:
		_initial_light_energy = light.light_energy
		light.light_energy = light_energy

func _process(delta: float) -> void:
	_time_alive += delta
	
	# Fade light
	if light:
		var t := _time_alive / lifetime
		light.light_energy = _initial_light_energy * (1.0 - t)
	
	# Self-destruct
	if _time_alive >= lifetime:
		queue_free()
