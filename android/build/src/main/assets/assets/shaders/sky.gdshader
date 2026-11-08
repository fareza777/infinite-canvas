shader_type sky;

uniform vec4 top_color : source_color = vec4(0.014, 0.022, 0.045, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.043, 0.055, 0.09, 1.0);
uniform vec4 accent_one : source_color = vec4(0.357, 0.905, 1.0, 1.0);
uniform vec4 accent_two : source_color = vec4(0.654, 0.545, 0.98, 1.0);

float hash(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.1, 0.2, 0.3));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

void sky() {
	float h = EYEDIR.y;
	vec3 col = mix(bottom_color.rgb, top_color.rgb, smoothstep(-0.55, 0.65, h));
	float n = sin(EYEDIR.x * 2.4 + EYEDIR.y * 3.7) * sin(EYEDIR.z * 2.0 - EYEDIR.y * 1.2);
	col += accent_two.rgb * 0.018 * smoothstep(0.35, 1.0, n) * smoothstep(-0.4, 0.8, h);
	float horizon = exp(-abs(h) * 9.0);
	col += accent_one.rgb * 0.035 * horizon;
	vec3 cell = floor(EYEDIR * 260.0);
	float star = hash(cell);
	float twinkle = 0.65 + 0.35 * sin(TIME * 0.8 + star * 40.0);
	if (star > 0.9975 && h > -0.1) {
		col += vec3(0.7, 0.85, 1.0) * (star - 0.9975) * 180.0 * twinkle * 0.45;
	}
	COLOR = col;
}
