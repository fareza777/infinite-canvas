shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix, shadows_disabled;

uniform vec2 rect_size = vec2(5.6, 3.2);
uniform float radius = 0.24;
uniform float opacity = 0.55;
uniform float softness = 0.22;
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

varying vec2 lp;

float sd_round(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - (b - vec2(r));
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

void vertex() {
	lp = VERTEX.xy;
}

void fragment() {
	vec2 half_size = rect_size * 0.5;
	float d = sd_round(lp, half_size, radius);
	float a = 1.0 - smoothstep(-softness * 0.2, softness, d);
	ALBEDO = shadow_color.rgb;
	ALPHA = a * opacity;
}
