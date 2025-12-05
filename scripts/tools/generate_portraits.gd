@tool
extends EditorScript

## Run this script in the Godot editor (Script → Run) to generate placeholder portraits.
## Creates simple colored rectangles with initials for each character.

func _run() -> void:
	var characters := {
		"rider": Color(0.3, 0.5, 0.35),   # Green
		"razor": Color(0.5, 0.45, 0.2),   # Gold/brown
		"sparks": Color(0.2, 0.4, 0.5),   # Cyan/blue
		"vera": Color(0.5, 0.35, 0.25),   # Orange/brown
		"stone": Color(0.45, 0.35, 0.35)  # Pinkish grey
	}
	
	for char_name in characters:
		var color: Color = characters[char_name]
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		
		# Fill with character color
		img.fill(color)
		
		# Add a simple border
		for x in range(64):
			for y in range(64):
				if x < 2 or x > 61 or y < 2 or y > 61:
					img.set_pixel(x, y, color.lightened(0.3))
		
		# Add a darker inner square to suggest a face area
		for x in range(16, 48):
			for y in range(12, 52):
				var current := img.get_pixel(x, y)
				img.set_pixel(x, y, current.darkened(0.15))
		
		# Save
		var path := "res://portraits/%s.png" % char_name
		img.save_png(path)
		print("Created: %s" % path)
	
	print("Done! Placeholder portraits created.")
