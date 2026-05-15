shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float sweep_width : hint_range(0.01, 0.3) = 0.08;

void fragment() {
	float diag = (UV.x + UV.y) * 0.5;
	vec4 tex_color = texture(TEXTURE, UV);

	if (diag <= progress - sweep_width) {
		COLOR = tex_color;
	} else if (diag <= progress) {
		float t = (diag - (progress - sweep_width)) / sweep_width;
		float glow = 1.0 - t;
		COLOR = mix(tex_color, vec4(1.0, 1.0, 1.0, 1.0), glow * glow);
	} else if (diag <= progress + sweep_width * 0.5) {
		float t = (diag - progress) / (sweep_width * 0.5);
		float alpha = 1.0 - t;
		COLOR = vec4(tex_color.rgb, tex_color.a * alpha);
	} else {
		COLOR = vec4(0.0);
	}
}
