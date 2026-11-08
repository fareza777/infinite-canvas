shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform vec4 base_color : source_color = vec4(0.96, 0.95, 0.91, 1.0);
uniform vec4 accent : source_color = vec4(0.357, 0.905, 1.0, 1.0);
uniform vec4 border_color : source_color = vec4(0.06, 0.09, 0.13, 1.0);
uniform vec2 rect_size = vec2(5.6, 3.2);
uniform float radius = 0.22;
uniform float header_height = 0.82;
uniform float footer_height = 0.42;
uniform float dark = 0.0;
uniform float grain = 0.0;
uniform float left_bar = 0.0;

varying vec2 lp;

float sd_round(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - (b - vec2(r));
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
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
	float v = clamp((lp.y + half_size.y) / rect_size.y, 0.0, 1.0);
	vec3 col = base_color.rgb;
	if (dark > 0.5) {
		col = mix(col * 0.72, col * 1.16, v);
		col += accent.rgb * 0.03 * (1.0 - abs(v - 0.5) * 2.0);
	} else {
		col = mix(col * 0.962, col * 1.018, v);
	}
	float head_bottom = half_size.y - header_height;
	float head = step(head_bottom, lp.y);
	float head_amount = (dark > 0.5) ? 0.10 : 0.075;
	col = mix(col, accent.rgb, head * head_amount);
	float top_line = smoothstep(half_size.y - 0.035, half_size.y, lp.y);
	col = mix(col, accent.rgb, top_line * 0.82);
	if (left_bar > 0.5) {
		float bar = 1.0 - smoothstep(0.035, 0.05, abs(lp.x + half_size.x - 0.075));
		col = mix(col, accent.rgb, bar * 0.75);
	}
	float foot = 1.0 - smoothstep(0.0, 0.012, abs(lp.y + half_size.y - footer_height));
	col = mix(col, accent.rgb, foot * 0.22);
	if (grain > 0.0) {
		float n = hash(floor((lp + half_size) * 145.0)) - 0.5;
		col += vec3(n) * 0.022 * grain;
	}
	float border = smoothstep(-0.018 - aa, -0.018 + aa, d);
	float border_strength = (dark > 0.5) ? 0.5 : 0.28;
	col = mix(col, border_color.rgb, border * border_strength);
	ALBEDO = col;
}
