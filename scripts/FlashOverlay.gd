extends ColorRect
class_name FlashOverlay

## Full-screen flash effect for damage feedback
## Call flash() to trigger a flash with custom color and intensity

func _ready() -> void:
	# Start fully transparent
	color = Color(1, 1, 1, 0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## Flash the screen with a color
## color_val: The flash color (alpha is ignored, max_alpha is used instead)
## max_alpha: Peak opacity of the flash (0.0 - 1.0)
## duration: Total flash duration in seconds
func flash(color_val: Color, max_alpha: float = 0.3, duration: float = 0.2) -> void:
	# Set flash color with 0 alpha to start
	color = Color(color_val.r, color_val.g, color_val.b, 0.0)
	
	# Create flash tween
	var tween := create_tween()
	
	# Quick fade in to max alpha
	tween.tween_property(self, "color:a", max_alpha, duration * 0.3)
	
	# Slower fade out
	tween.tween_property(self, "color:a", 0.0, duration * 0.7)

## Convenience methods for common flash types
func flash_damage() -> void:
	flash(Color(0.2, 0.6, 0.8), 0.25, 0.2)  # Blue/teal for shield hit

func flash_carrier_damage() -> void:
	flash(Color(1.0, 0.4, 0.1), 0.35, 0.25)  # Orange/red for carrier damage

func flash_critical() -> void:
	flash(Color(1.0, 0.1, 0.1), 0.5, 0.3)  # Red for critical events

func flash_success() -> void:
	flash(Color(0.2, 1.0, 0.3), 0.2, 0.3)  # Green for positive events
