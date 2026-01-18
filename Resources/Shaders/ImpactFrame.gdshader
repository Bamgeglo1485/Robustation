shader_type canvas_item;

uniform float threshold : hint_range(0.0, 1.0) = 0.5;
uniform float smoothness : hint_range(0.0, 0.5) = 0.05;
uniform vec4 bg_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 fg_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform bool invert = false;
uniform float intensity : hint_range(0.0, 1.0) = 1.0;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);
    
    float luminance = dot(screen_color.rgb, vec3(0.299, 0.587, 0.114));
    
    float value = smoothstep(threshold - smoothness, threshold + smoothness, luminance);
    
    vec4 final_color;
    if (invert) {
        final_color = mix(fg_color, bg_color, value);
    } else {
        final_color = mix(bg_color, fg_color, value);
    }
    
    final_color = mix(screen_color, final_color, intensity);
    
    COLOR = final_color;
}