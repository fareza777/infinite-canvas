shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform sampler2D image_tex : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec4 accent : source_color = vec4(0.357, 0.905, 1.0, 1.0);
uniform vec2 rect_size = vec2(5.0, 3.0);
uniform float radius = 0.2;
uniform float caption_frac = 0.16;
uniform float dark = 0.0;
uniform float is_pdf = 0.0;

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
	float cap_h = rect_size.y * caption_frac;
	float img_h = rect_size.y - cap_h;
	float img_top = half_size.y;
	float in_image = step(lp.y, img_top) * step(img_top - img_h, lp.y);
	vec2 uv = vec2((lp.x + half_size.x) / rect_size.x, (img_top - lp.y) / max(0.001, img_h));
	vec3 col = vec3(0.035, 0.05, 0.075);
	if (in_image > 0.5) {
		vec3 tex = texture(image_tex, uv).rgb;
		col = tex;
		if (is_pdf > 0.5) {
			col *= 0.97;
		}
	}
	float cap = step(lp.y, img_top - img_h);
	vec3 cap_col = vec3(0.055, 0.075, 0.11);
	if (dark > 0.5) {
		cap_col *= 1.1;
	}
	col = mix(col, cap_col, cap);
	float cap_line = 1.0 - smoothstep(0.0, 0.008, abs(lp.y - (img_top - img_h)));
	col = mix(col, accent.rgb, cap_line * 0.55);
	float border = smoothstep(-0.016 - aa, -0.016 + aa, d);
	col = mix(col, vec3(0.5, 0.62, 0.78), border * 0.4);
	ALBEDO = col;
}
