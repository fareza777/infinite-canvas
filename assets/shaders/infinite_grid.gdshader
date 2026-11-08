shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 bg_top : source_color = vec4(0.024, 0.035, 0.06, 1.0);
uniform vec4 bg_bottom : source_color = vec4(0.055, 0.075, 0.115, 1.0);
uniform vec4 line_color : source_color = vec4(0.42, 0.62, 0.85, 0.30);
uniform vec4 accent : source_color = vec4(0.357, 0.905, 1.0, 1.0);
uniform vec2 focus = vec2(0.0, 0.0);
uniform float view_height = 13.0;
uniform float grid_enabled = 1.0;
uniform float dots_only = 0.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float line_mask(vec2 p, float step_size, float width_px) {
	vec2 q = p / step_size;
	vec2 d = abs(fract(q - 0.5) - 0.5);
	vec2 aa = fwidth(q) * width_px + vec2(1e-6);
	vec2 m = 1.0 - smoothstep(vec2(0.0), aa, d);
	return max(m.x, m.y);
}

void fragment() {
	vec2 p = world_pos.xy;
	vec2 uv = UV;
	vec3 col = mix(bg_top.rgb, bg_bottom.rgb, clamp(uv.y * 0.75 + 0.12, 0.0, 1.0));
	float focus_dist = length(p - focus) / max(1.0, view_height);
	col += accent.rgb * 0.045 * exp(-focus_dist * 1.4);
	float aurora = sin(p.x * 0.035 + p.y * 0.021) * sin(p.y * 0.048 - p.x * 0.014);
	col += accent.rgb * 0.012 * smoothstep(0.15, 1.0, aurora);
	float wave = sin(p.x * 0.12 + p.y * 0.09 + TIME * 0.22);
	col += vec3(0.22, 0.32, 0.52) * 0.006 * smoothstep(0.4, 1.0, wave);

	if (grid_enabled > 0.5) {
		float px_per_unit = 1.0 / max(fwidth(p.x), fwidth(p.y));
		if (dots_only > 0.5) {
			vec2 q = p;
			vec2 d = abs(fract(q - 0.5) - 0.5);
			float dot_dist = length(d);
			float aa = length(fwidth(p)) * 0.9 + 1e-6;
			float dots = (1.0 - smoothstep(0.0, aa * 2.2, dot_dist)) * smoothstep(9.0, 26.0, px_per_unit);
			vec2 cq = p / 10.0;
			vec2 cd = abs(fract(cq - 0.5) - 0.5);
			float coarse_dot = 1.0 - smoothstep(0.0, 2.0, length(cd / max(fwidth(cq), vec2(1e-5))));
			col = mix(col, line_color.rgb, clamp(dots * 0.34 + coarse_dot * 0.18, 0.0, 0.5));
		} else {
			float w1 = smoothstep(7.0, 28.0, px_per_unit);
			float w2 = smoothstep(7.0, 28.0, px_per_unit * 10.0);
			float w3 = smoothstep(7.0, 28.0, px_per_unit * 100.0);
			float w4 = smoothstep(7.0, 28.0, px_per_unit * 1000.0);
			float g = line_mask(p, 1.0, 0.7) * w1 * 0.11
				+ line_mask(p, 10.0, 0.85) * w2 * 0.17
				+ line_mask(p, 100.0, 1.0) * w3 * 0.22
				+ line_mask(p, 1000.0, 1.2) * w4 * 0.25;
			col = mix(col, line_color.rgb, clamp(g, 0.0, 0.45));
			float dots = 0.0;
			vec2 grid_px = abs(fract(p / 10.0 - 0.5) - 0.5) / max(fwidth(p / 10.0), vec2(1e-5));
			dots = (1.0 - smoothstep(0.0, 1.3, length(grid_px))) * smoothstep(18.0, 50.0, px_per_unit * 10.0);
			col = mix(col, accent.rgb, dots * 0.20);
		}
		float axis_x = 1.0 - smoothstep(0.0, 1.6, abs(p.x) / max(fwidth(p.x), 1e-5));
		float axis_y = 1.0 - smoothstep(0.0, 1.6, abs(p.y) / max(fwidth(p.y), 1e-5));
		col = mix(col, accent.rgb, max(axis_x, axis_y) * 0.22);
	}

	vec2 centered = uv - 0.5;
	float vignette = smoothstep(0.28, 0.78, length(centered));
	col *= 1.0 - vignette * 0.28;
	ALBEDO = col;
}
