shader_type canvas_item;

uniform float threshold : hint_range(0.0, 1.0) = 0.5;
uniform float smoothness : hint_range(0.0, 0.5) = 0.05;
uniform vec4 bg_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 fg_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform bool invert = false;
uniform float intensity : hint_range(0.0, 1.0) = 1.0;
uniform float mask_softness : hint_range(-2.0, 2.0) = 1.4;
uniform float mask_threshold : hint_range(0.0, 1.0) = 0.6;
uniform float sort : hint_range(0.0, 2.0) = 0.0;

uniform sampler2D noise: repeat_enable;
uniform vec4 line_color: source_color;
uniform float line_count: hint_range(0.0, 2.0, 0.05) = 0.5;
uniform float line_density: hint_range(0.0, 1.0) = 0.5;
uniform float line_faloff: hint_range(0.0, 10.0) = 0.25;
uniform float mask_size: hint_range(0.0, 1.0) = 0.1;
uniform float mask_edge: hint_range(0.0, 1.0) = 0.5;
uniform float animation_speed: hint_range(1.0, 20.0) = 0.5;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

float inv_lerp(float from, float to, float value){
    return (value - from) / (to - from);
}

vec2 polar_coordinates(vec2 uv, vec2 center, float zoom, float repeat) {
    vec2 dir = uv - center;
    float radius = length(dir) * 2.0;
    float angle = atan(dir.y, dir.x) * 1.0/(3.14159 * 2.0);
    return mod(vec2(radius * zoom, angle * repeat), 1.0);
}

vec2 rotate_uv(vec2 uv, vec2 pivot, float rotation) {
    float cosa = cos(rotation);
    float sina = sin(rotation);
    uv -= pivot;
    return vec2(
        cosa * uv.x - sina * uv.y,
        cosa * uv.y + sina * uv.x 
    ) + pivot;
}

void fragment(){
    vec2 uv = FRAGCOORD.xy / (1.0 / SCREEN_PIXEL_SIZE).xy;
    vec4 screen_color = texture(SCREEN_TEXTURE, uv);
    
    float average = (screen_color.r + screen_color.g + screen_color.b) / 3.0;
    
    float f = abs(mask_softness) / 2.0;
    float a = mask_threshold - f;
    float b = mask_threshold + f;
    
    float mask;
    if (mask_softness >= 0.0) {
        mask = smoothstep(a, b, average);
    } else {
        mask = 1.0 - smoothstep(a, b, average);
    }
    
    float turbulance = fract(sin(dot(vec2(uv.x), vec2(12.9, 78.2))) * 437.5);
    
    vec2 distorted_uv = uv;
    distorted_uv.y += pow(sort, 2.0 + (sort * 2.0)) * mask * turbulance;
    
    vec4 melted_color = texture(SCREEN_TEXTURE, distorted_uv);
    
    vec4 sorted_color;
    float sort_threshold = 1.0 - clamp(sort / 2.6, 0.0, 1.0);
    vec2 sort_uv = vec2(uv.x, sort_threshold);
    
    if (distorted_uv.y > 1.0) {
        sorted_color = texture(SCREEN_TEXTURE, sort_uv);
    } else {
        sorted_color = texture(SCREEN_TEXTURE, uv);
    }
    
    vec4 effect_color = melted_color;
    if (distorted_uv.y > 1.0) {
        effect_color = sorted_color;
    }
    
    float effect_luminance = dot(effect_color.rgb, vec3(0.299, 0.587, 0.114));
    
    float bin_value = smoothstep(threshold - smoothness, threshold + smoothness, effect_luminance);
    
    vec4 binarized_color;
    if (invert) {
        binarized_color = mix(fg_color, bg_color, bin_value);
    } else {
        binarized_color = mix(bg_color, fg_color, bin_value);
    }
    
    vec4 base_color = mix(effect_color, binarized_color, intensity);
    
    vec2 polar_uv = polar_coordinates(rotate_uv(UV, vec2(0.5), floor(fract(TIME) * animation_speed)), vec2(0.5), 0.01, line_count);
    vec3 lines = texture(noise, polar_uv).rgb;
    
    float mask_value = length(UV - vec2(0.5));
    float line_mask = inv_lerp(mask_size, mask_edge, mask_value);
    float result = 1.0 - (line_mask * line_density);
    
    result = smoothstep(result, result + line_faloff, lines.r);
    
    vec4 line_result = vec4(line_color.rgb, min(line_color.a, result));
   
    vec4 final_color = base_color;
    if (line_result.a > 0.0) {
        final_color.rgb = mix(base_color.rgb, line_result.rgb, line_result.a);
        final_color.a = max(base_color.a, line_result.a);
    }
    
    COLOR = final_color;
}