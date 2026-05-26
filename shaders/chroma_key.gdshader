shader_type canvas_item;

// 白色背景透明 + 圆形遮罩 shader
// 抠除白色背景，并裁剪为圆形（中心为圆心，半径256像素）

uniform float threshold : hint_range(0.5, 1.0) = 0.85;
uniform float smoothness : hint_range(0.0, 0.5) = 0.1;
uniform float radius : hint_range(0.0, 512.0) = 256.0;
uniform float edge_smooth : hint_range(0.0, 50.0) = 4.0;

void fragment() {
	vec4 color = texture(TEXTURE, UV);

	// 白色背景抠像
	//float luminance = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
	//float chroma_alpha = 1.0 - smoothstep(threshold - smoothness, threshold, luminance);

	// 圆形遮罩：UV坐标转换为像素坐标，计算到中心的距离
	vec2 pixel_pos = UV * vec2(512.0, 512.0);
	float dist = distance(pixel_pos, vec2(256.0, 256.0));
	float circle_alpha = 1.0 - smoothstep(radius - edge_smooth, radius, dist);

	// 合并两个 alpha
	//color.a = chroma_alpha * circle_alpha;
	color.a = circle_alpha;
	color.rgb *= color.a;
	COLOR = color;
}
