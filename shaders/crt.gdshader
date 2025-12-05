shader_type canvas_item;

// CRT Shader for retro 90s look
// Tweak these uniforms to adjust the effect intensity

uniform float barrel_distortion : hint_range(0.0, 0.3) = 0.1;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.15;
uniform float scanline_count : hint_range(100.0, 800.0) = 320.0;
uniform float noise_intensity : hint_range(0.0, 0.2) = 0.03;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float brightness : hint_range(0.8, 1.2) = 1.0;
uniform float saturation : hint_range(0.5, 1.5) = 1.1;

// Simple hash function for noise
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// Barrel distortion function
vec2 barrel_distort(vec2 uv) {
	vec2 centered = uv - 0.5;
	float dist = dot(centered, centered);
	vec2 distorted = centered * (1.0 + barrel_distortion * dist);
	return distorted + 0.5;
}

void fragment() {
	// Apply barrel distortion
	vec2 uv = barrel_distort(UV);
	
	// Check if we're outside the texture after distortion
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
		return;
	}
	
	// Sample the texture
	vec4 color = texture(TEXTURE, uv);
	
	// Apply scanlines
	float scanline = sin(uv.y * scanline_count * 3.14159) * 0.5 + 0.5;
	scanline = mix(1.0, scanline, scanline_intensity);
	color.rgb *= scanline;
	
	// Apply noise/grain
	float noise = hash(uv * 1000.0 + TIME * 10.0);
	noise = (noise - 0.5) * noise_intensity;
	color.rgb += noise;
	
	// Apply vignette
	vec2 vignette_uv = uv - 0.5;
	float vignette = 1.0 - dot(vignette_uv, vignette_uv) * vignette_intensity * 2.0;
	vignette = clamp(vignette, 0.0, 1.0);
	color.rgb *= vignette;
	
	// Adjust brightness
	color.rgb *= brightness;
	
	// Adjust saturation
	float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	color.rgb = mix(vec3(gray), color.rgb, saturation);
	
	// Slight color bleed / chromatic aberration (subtle)
	float aberration = 0.001;
	float r = texture(TEXTURE, barrel_distort(UV + vec2(aberration, 0.0))).r;
	float b = texture(TEXTURE, barrel_distort(UV - vec2(aberration, 0.0))).b;
	color.r = mix(color.r, r, 0.5);
	color.b = mix(color.b, b, 0.5);
	
	COLOR = color;
}
