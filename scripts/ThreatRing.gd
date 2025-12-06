@tool
extends Control
class_name ThreatRing

## ThreatRing - 2D radar minimap showing enemy/friendly positions
## Renders as a circular radar with dots for tracked entities

@export var ring_radius: float = 35.0
@export var detection_range: float = 100.0
@export var ring_color: Color = Color(0.2, 0.6, 0.3, 0.5)
@export var enemy_color: Color = Color(1.0, 0.2, 0.2, 1.0)
@export var friendly_color: Color = Color(0.2, 0.8, 1.0, 1.0)
@export var player_color: Color = Color(0.2, 1.0, 0.3, 1.0)
@export var dot_size: float = 3.0

var player_ref: Node3D = null
var enemies: Array[Node3D] = []
var friendlies: Array[Node3D] = []

func _ready() -> void:
	# Ensure redraw on changes
	set_process(true)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var center := size / 2.0
	
	# Draw radar ring
	draw_arc(center, ring_radius, 0, TAU, 32, ring_color, 1.5)
	draw_arc(center, ring_radius * 0.5, 0, TAU, 24, ring_color * 0.5, 1.0)
	
	# Draw crosshairs
	draw_line(center + Vector2(-ring_radius, 0), center + Vector2(ring_radius, 0), ring_color * 0.3, 1.0)
	draw_line(center + Vector2(0, -ring_radius), center + Vector2(0, ring_radius), ring_color * 0.3, 1.0)
	
	# Draw player center dot
	draw_circle(center, dot_size, player_color)
	
	if player_ref == null:
		return
	
	var player_pos := player_ref.global_position
	var player_forward := -player_ref.global_transform.basis.z
	var player_right := player_ref.global_transform.basis.x
	
	# Draw enemies
	for enemy in enemies:
		if is_instance_valid(enemy):
			_draw_entity(center, player_pos, player_forward, player_right, enemy.global_position, enemy_color)
	
	# Draw friendlies
	for friendly in friendlies:
		if is_instance_valid(friendly):
			_draw_entity(center, player_pos, player_forward, player_right, friendly.global_position, friendly_color)

func _draw_entity(center: Vector2, player_pos: Vector3, player_forward: Vector3, player_right: Vector3, entity_pos: Vector3, color: Color) -> void:
	var offset := entity_pos - player_pos
	var distance := offset.length()
	
	if distance > detection_range:
		return
	
	# Project to 2D radar space (top-down view relative to player facing)
	var forward_component := offset.dot(player_forward)
	var right_component := offset.dot(player_right)
	
	# Normalize to radar scale
	var radar_x := (right_component / detection_range) * ring_radius
	var radar_y := (-forward_component / detection_range) * ring_radius  # Negative because forward is up on radar
	
	# Clamp to ring radius
	var radar_pos := Vector2(radar_x, radar_y)
	if radar_pos.length() > ring_radius:
		radar_pos = radar_pos.normalized() * ring_radius
	
	draw_circle(center + radar_pos, dot_size, color)
