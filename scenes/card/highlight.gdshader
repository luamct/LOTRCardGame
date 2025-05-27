shader_type spatial;
render_mode unshaded;

uniform vec4 aura_color : source_color = vec4(0.5, 1.0, 1.0, 1.0);
uniform float glow_strength = 2.0;

void fragment() {
    ALBEDO = aura_color.rgb;
    EMISSION = aura_color.rgb * glow_strength;
    ALPHA = aura_color.a;
}
