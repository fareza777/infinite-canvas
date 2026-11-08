shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque, blend_mix;
uniform vec4 fill_color : source_color = vec4(0.357, 0.905, 1.0, 0.15);
uniform vec4 border_color : source_color = vec4(0.357, 0.905, 1.0, 1.0);
uniform vec2 rect_size = vec2(3.0, 2.0);
uniform float radius = 0.2;
uniform float border_width = 0.035;
uniform float filled = 1.0;

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
	float aa = max(0.0025, fwidth(d) * 0.9);
	if (d > aa) {
		discard;
	}
	float edge = smoothstep(-border_width - aa, -border_width + aa, d);
	vec4 col = mix(fill_color, border_color, edge);
	col.a = mix(fill_color.a, border_color.a, edge);
	if (filled < 0.5) {
		if (d < -border_width) {
			discard;
		}
	}
	ALBEDO = col.rgb;
	ALPHA = col.a;
}
