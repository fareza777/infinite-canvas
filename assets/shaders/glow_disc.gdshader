shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_add, shadows_disabled;

uniform vec4 glow_color : source_color = vec4(0.357, 0.905, 1.0, 1.0);
uniform float strength = 0.35;
uniform float falloff = 1.6;

void fragment() {
	float d = length(UV - vec2(0.5)) * 2.0;
	float a = pow(max(0.0, 1.0 - clamp(d, 0.0, 1.0)), falloff) * strength;
	ALBEDO = glow_color.rgb;
	ALPHA = a;
}
