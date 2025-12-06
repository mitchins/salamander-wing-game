extends SubViewportContainer

## Integer scales the SubViewport to fill window while preserving crisp pixels.
const INTERNAL_SIZE := Vector2i(400, 300)

func _ready() -> void:
    # Ensure SubViewport has intended internal size
    var vp := $GameViewport as SubViewport
    if vp:
        vp.size = INTERNAL_SIZE

    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    stretch = true

    _update_scale()
    var root := get_viewport()
    if root:
        root.size_changed.connect(_update_scale)

func _update_scale() -> void:
    var win_px: Vector2i = DisplayServer.window_get_size()
    var win_size: Vector2 = Vector2(win_px)
    var scale_x = floor(win_size.x / float(INTERNAL_SIZE.x))
    var scale_y = floor(win_size.y / float(INTERNAL_SIZE.y))
    var scale_factor: int = max(1, int(min(scale_x, scale_y)))

    var target_size: Vector2 = Vector2(INTERNAL_SIZE) * float(scale_factor)
    size = target_size
    position = (win_size - target_size) * 0.5

    # Keep children layout stable
    set_anchors_preset(Control.PRESET_TOP_LEFT)
