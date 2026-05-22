shader_type canvas_item;

uniform vec3 color = vec3(1.0);
uniform float intensity : hint_range(0.1, 3.0) = 1.0;

void fragment() {
	vec2 center = UV - 0.5;
	float dist = length(center);
	float glow = exp(-dist * dist * 8.0) * intensity;
	COLOR = vec4(color * glow, glow);
}
