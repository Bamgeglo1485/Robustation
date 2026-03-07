shader_type canvas_item;

uniform float wave_amplitude = 0.25;
uniform float wave_frequency = 40.0;
uniform float wave_speed = 9.0;

uniform float left_falloff = 1.0;
uniform float right_falloff = 1.0;
uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    float dist_left = clamp(0.5 - UV.x, 0.0, 0.5) * 2.0;
    float dist_right = clamp(UV.x - 0.5, 0.0, 0.5) * 2.0;

    float falloff_left = pow(1.0 - dist_left, left_falloff);
    float falloff_right = pow(1.0 - dist_right, right_falloff);

    float center_falloff = (UV.x <= 0.5) ? falloff_left : falloff_right;

    float amp = wave_amplitude * center_falloff;
    float y = 0.5 + sin(UV.x * wave_frequency + TIME * wave_speed) * amp;

    float thickness = 0.03;
    float dist = abs(UV.y - y);

    float alpha = smoothstep(thickness, 0.0, dist);
    
    COLOR = vec4(color.rgb, alpha * color.a);
}
