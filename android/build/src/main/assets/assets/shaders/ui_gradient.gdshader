shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec4 color_a : source_color = vec4(0.357, 0.905, 1.0, 1.0);
uniform vec4 color_b : source_color = vec4(0.545, 0.361, 0.965, 1.0);
uniform vec4 color_c : source_color = vec4(0.106, 0.165, 0.29, 1.0);
uniform float radius = 18.0;
uniform vec2 rect_size = vec2(200.0, 56.0);
uniform float border_width = 0.0;
uniform vec4 border_color : source_color = vec4(1.0, 1.0, 1.0, 0.12);
uniform float sheen = 0.5;

float rounded_sdf(vec2 p, vec2 half_size, float r) {
	vec2 q = abs(p - half_size) - (half_size - vec2(r));
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	vec2 p = UV * rect_size;
	vec2 half_size = rect_size * 0.5;
	float r = min(radius, min(half_size.x, half_size.y));
	float d = rounded_sdf(p, half_size, r);
	float aa = max(0.75, fwidth(d) * 0.9);
	float inside = 1.0 - smoothstep(-aa, aa, d);
	vec3 col = mix(color_a.rgb, color_b.rgb, clamp(UV.x * 0.35 + UV.y * 0.9, 0.0, 1.0));
	col = mix(col, color_c.rgb, 0.22 * (1.0 - UV.y));
	float highlight = smoothstep(0.0, 0.8, UV.x * 0.55 + (1.0 - UV.y) * 0.6);
	col += vec3(0.12, 0.16, 0.22) * highlight * sheen;
	float edge = smoothstep(-1.6, 0.0, d) - smoothstep(-0.6, 0.8, d);
	col = mix(col, border_color.rgb, edge * border_color.a);
	if (border_width > 0.0) {
		float band = smoothstep(-border_width - aa, -border_width + aa, d);
		col = mix(col, border_color.rgb, band * border_color.a * 0.55);
	}
	COLOR = vec4(col, inside);
}
