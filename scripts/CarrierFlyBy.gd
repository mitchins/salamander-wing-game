extends Node3D
class_name CarrierFlyBy

## CarrierFlyBy - Scripted setpiece for dramatic carrier flyby
## Animates a large carrier passing overhead

signal flyby_started()
signal flyby_complete()

@export var fly_duration: float = 8.0
@export var start_offset: Vector3 = Vector3(50, 30, -150)
@export var end_offset: Vector3 = Vector3(-80, 20, 100)
@export var avoid_ring: bool = true
@export var ring_avoidance_height: float = 40.0
@export var ring_safe_margin: float = 10.0
@export var ring_test_steps: int = 16
@export var ring_thickness: float = 15.0

@onready var carrier_mesh: MeshInstance3D = $CarrierMesh

var _is_playing: bool = false
var _tween: Tween = null

func _ready() -> void:
    if carrier_mesh:
        carrier_mesh.visible = false

func start_flyby(player_position: Vector3 = Vector3.ZERO) -> void:
    if _is_playing:
        return

    _is_playing = true
    flyby_started.emit()

    if carrier_mesh:
        # Compute world positions for the path and check for ring intersections if configured
        var world_start: Vector3 = player_position + start_offset
        var world_end: Vector3 = player_position + end_offset
        if avoid_ring and _path_intersects_ring(world_start, world_end):
            var adjusted := _adjust_path_for_ring(world_start, world_end)
            world_start = adjusted[0]
            world_end = adjusted[1]
            print("CarrierFlyBy: Adjusted path to avoid ring (start=%s end=%s)" % [world_start, world_end])

        carrier_mesh.visible = true
        carrier_mesh.global_position = world_start

        # Create tween animation
        _tween = create_tween()
        _tween.set_ease(Tween.EASE_IN_OUT)
        _tween.set_trans(Tween.TRANS_SINE)

        # Move from start to end
        _tween.tween_property(carrier_mesh, "global_position", world_end, fly_duration)

        # Slight rotation during flyby
        _tween.parallel().tween_property(carrier_mesh, "rotation_degrees:y", -15.0, fly_duration)

        _tween.tween_callback(_on_flyby_complete)

func _on_flyby_complete() -> void:
    _is_playing = false
    if carrier_mesh:
        carrier_mesh.visible = false
    flyby_complete.emit()

func stop_flyby() -> void:
    if _tween:
        _tween.kill()
    _is_playing = false
    if carrier_mesh:
        carrier_mesh.visible = false

## Helper utilities for ring avoidance
func _find_ring_node() -> Node3D:
    # Prefer nodes in 'background_ring' group; fallback to finding node named "Ring"
    var group_nodes: Array = get_tree().get_nodes_in_group("background_ring")
    var ring = null
    if group_nodes.size() > 0:
        ring = group_nodes[0]
    else:
        ring = get_tree().get_root().find_node("Ring", true, false)
    return ring

func _path_intersects_ring(start_world: Vector3, end_world: Vector3) -> bool:
    var ring = _find_ring_node()
    if ring == null:
        return false
    var ring_mesh = ring.mesh
    var inner_radius: float = 100.0
    var outer_radius: float = 150.0
    if ring_mesh != null and ring_mesh is TorusMesh:
        inner_radius = ring_mesh.inner_radius
        outer_radius = ring_mesh.outer_radius

    var inv = ring.global_transform.affine_inverse()
    for i in range(max(1, ring_test_steps)):
        var t: float = float(i) / float(max(1, ring_test_steps - 1))
        var p: Vector3 = start_world.lerp(end_world, t)
        var local_p: Vector3 = inv.xform(p)
        var planar_dist: float = sqrt(local_p.x * local_p.x + local_p.z * local_p.z)
        var vertical_dist: float = abs(local_p.y)
        if planar_dist >= inner_radius and planar_dist <= outer_radius and vertical_dist <= ring_thickness:
            return true
    return false

func _adjust_path_for_ring(start_world: Vector3, end_world: Vector3) -> Array:
    var ring = _find_ring_node()
    if ring == null:
        return [start_world, end_world]
    var ring_mesh = ring.mesh
    var outer_radius: float = 150.0
    if ring_mesh != null and ring_mesh is TorusMesh:
        outer_radius = ring_mesh.outer_radius

    # Raise start/end to be above the ring's outer radius + margin
    var desired_y: float = ring.global_position.y + outer_radius + ring_safe_margin
    var new_start: Vector3 = start_world
    var new_end: Vector3 = end_world
    if new_start.y < desired_y:
        new_start.y = desired_y + ring_avoidance_height
    if new_end.y < desired_y:
        new_end.y = desired_y + ring_avoidance_height
    return [new_start, new_end]

func debug_check(player_position: Vector3 = Vector3.ZERO) -> void:
    var world_start: Vector3 = player_position + start_offset
    var world_end: Vector3 = player_position + end_offset
    var intersects = _path_intersects_ring(world_start, world_end)
    print("CarrierFlyBy debug - start=%s end=%s intersects=%s" % [world_start, world_end, intersects])
