shader_type canvas_item;

// CRT Shader for authentic 1994 low-poly look
// Tweak these uniforms to adjust the effect intensity

// Geometry distortion
uniform float barrel_distortion : hint_range(0.0, 0.3) = 0.06;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.2;

// Scanlines
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.18;
uniform float scanline_count : hint_range(100.0, 800.0) = 320.0;

// Color banding / posterization (1994 feel)
uniform float color_depth : hint_range(2.0, 32.0) = 16.0;
uniform float dither_strength : hint_range(0.0, 1.0) = 0.02;

// Film grain
uniform float noise_intensity : hint_range(0.0, 0.15) = 0.02;

// Color adjustments
uniform float brightness : hint_range(0.8, 1.2) = 1.0;
uniform float saturation : hint_range(0.5, 1.5) = 1.05;
uniform float contrast : hint_range(0.8, 1.3) = 1.05;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float dither4x4(vec2 pos) {
	int x = int(mod(pos.x, 4.0));
	int y = int(mod(pos.y, 4.0));
	int index = x + y * 4;
	float dither[16] = float[16](
0.0, 8.0, 2.0, 10.0,
12.0, 4.0, 14.0, 6.0,
3.0, 11.0, 1.0, 9.0,
15.0, 7.0, 13.0, 5.0
);
	return dither[index] / 16.0 - 0.5;
}

vec2 barrel_distort(vec2 uv) {
	vec2 centered = uv - 0.5;
	float dist = dot(centered, centered);
	vec2 distorted = centered * (1.0 + barrel_distortion * dist);
	return distorted + 0.5;
}

vec3 posterize(vec3 color, float levels, float dither) {
	vec3 c = color + dither * dither_strength / levels;
	return floor(c * levels + 0.5) / levels;
}

void fragment() {
	vec2 uv = barrel_distort(UV);
	
	// Black outside distorted area
	bool out_of_bounds = uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0;
	
	vec4 final_color = vec4(0.0, 0.0, 0.0, 1.0);
	
	if (!out_of_bounds) {
		vec4 color = texture(TEXTURE, uv);
		
		// Contrast
		color.rgb = ((color.rgb - 0.5) * contrast) + 0.5;
		
		// Scanlines
		float scanline = sin(uv.y * scanline_count * 3.14159) * 0.5 + 0.5;
		scanline = pow(scanline, 1.5);
		scanline = mix(1.0, scanline, scanline_intensity);
		color.rgb *= scanline;
		
		// Posterization with dithering
		vec2 pixel_pos = uv * vec2(480.0, 320.0);
		float dither_value = dither4x4(pixel_pos);
		color.rgb = posterize(color.rgb, color_depth, dither_value);
		
		// Noise/grain
		float noise = hash(uv * 800.0 + TIME * 5.0);
		noise = (noise - 0.5) * noise_intensity;
		color.rgb += noise;
		
		// Vignette
		vec2 vignette_uv = uv - 0.5;
		float vignette = 1.0 - dot(vignette_uv, vignette_uv) * vignette_intensity * 2.0;
		vignette = clamp(vignette, 0.0, 1.0);
		color.rgb *= vignette;
		
		// Brightness
		color.rgb *= brightness;
		
		// Saturation
		float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
		color.rgb = mix(vec3(gray), color.rgb, saturation);
		
		color.rgb = clamp(color.rgb, 0.0, 1.0);
		final_color = color;
	}
	
	COLOR = final_color;
}
