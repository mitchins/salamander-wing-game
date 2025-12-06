extends SubViewportContainer

## Dynamic integer-scaling system that maximizes screen usage on all monitor sizes.
## Computes internal resolution based on window size divided by integer scale.
## Keeps the retro look by constraining internal height to 180-480px range.

const MIN_INTERNAL_HEIGHT := 180  # Minimum retro resolution
const MAX_INTERNAL_HEIGHT := 480  # Maximum retro resolution (keeps low-res look)
const MAX_SCALE := 8              # Maximum integer scale factor

@onready var subviewport := $GameViewport as SubViewport

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stretch = true

	_update_render_scale()
	var root := get_viewport()
	if root:
		root.size_changed.connect(_update_render_scale)

func _update_render_scale() -> void:
	var win: Vector2 = Vector2(DisplayServer.window_get_size())

	var best_internal := Vector2i(320, 240)
	var best_scale := 1

	# Calculate maximum possible scale that still meets minimum height
	var max_possible_scale: int = min(MAX_SCALE, int(floor(win.y / float(MIN_INTERNAL_HEIGHT))))
	if max_possible_scale < 1:
		max_possible_scale = 1

	# Try scales from largest to smallest, pick first that fits retro constraints
	for s in range(max_possible_scale, 0, -1):
		var internal := Vector2i(
			int(floor(win.x / s)),
			int(floor(win.y / s))
		)

		# Check if this internal resolution is in the retro sweet spot
		if internal.y < MIN_INTERNAL_HEIGHT:
			continue
		if internal.y > MAX_INTERNAL_HEIGHT:
			continue

		best_internal = internal
		best_scale = s
		break

	# Fallback for very small windows or if no scale satisfied constraints
	if best_scale == 1 and best_internal == Vector2i(320, 240):
		var s: int = max(1, int(floor(win.y / float(MAX_INTERNAL_HEIGHT))))
		var internal := Vector2i(
			int(floor(win.x / s)),
			int(floor(win.y / s))
		)
		best_internal = internal
		best_scale = s

	# Apply the computed resolution to SubViewport
	if subviewport:
		subviewport.size = best_internal

	# Scale and center the display
	var scaled_size: Vector2 = Vector2(best_internal) * float(best_scale)
	size = scaled_size
	position = (win - scaled_size) * 0.5

	# Keep children layout stable
	set_anchors_preset(Control.PRESET_TOP_LEFT)

	# Update shader parameter for internal resolution (if used by CRT shader)
	if material and material is ShaderMaterial:
		var shader_mat := material as ShaderMaterial
		shader_mat.set_shader_parameter("internal_resolution", Vector2(best_internal))
