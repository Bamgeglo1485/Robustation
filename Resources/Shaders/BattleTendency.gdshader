shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float red_factor : hint_range(0.0, 2.0) = 1.0;
uniform float green_factor : hint_range(0.0, 2.0) = 1.0;
uniform float blue_factor : hint_range(0.0, 2.0) = 1.0;

uniform float saturation : hint_range(0.0, 2.0) = 1.0;
uniform float brightness : hint_range(-1.0, 1.0) = 0.0;
uniform float contrast : hint_range(0.0, 2.0) = 1.0;
uniform float hue_shift : hint_range(-1.0, 1.0) = 0.0;
uniform float gamma : hint_range(0.1, 3.0) = 1.0;

uniform float alpha : hint_range(0.0, 1.0) = 1.0;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.0;

uniform float chromatic_aberration_strength : hint_range(0.0, 0.05) = 0.0;

vec3 rgb2hsl(vec3 color) {
    float max_color = max(max(color.r, color.g), color.b);
    float min_color = min(min(color.r, color.g), color.b);
    float delta = max_color - min_color;

    float lightness = (max_color + min_color) * 0.5;
    
    if (delta < 0.00001) {
        return vec3(0.0, 0.0, lightness);
    }
    
    float sat = lightness < 0.5 ? delta / (max_color + min_color) : delta / (2.0 - max_color - min_color);
    
    float hue;
    if (max_color == color.r) {
        hue = (color.g - color.b) / delta + (color.g < color.b ? 6.0 : 0.0);
    } else if (max_color == color.g) {
        hue = (color.b - color.r) / delta + 2.0;
    } else {
        hue = (color.r - color.g) / delta + 4.0;
    }

    return vec3(hue / 6.0, sat, lightness);
}

vec3 hsl2rgb(vec3 hsl) {
    float hue = hsl.x;
    float sat = hsl.y;
    float lightness = hsl.z;

    if (sat < 0.00001) {
        return vec3(lightness);
    }
    
    float chroma = (1.0 - abs(2.0 * lightness - 1.0)) * sat;
    float h = hue * 6.0;
    float x = chroma * (1.0 - abs(mod(h, 2.0) - 1.0));
    float m = lightness - chroma * 0.5;

    vec3 result;
    float h_int = floor(h);
    
    if (h_int == 0.0) {
        result = vec3(chroma, x, 0.0);
    } else if (h_int == 1.0) {
        result = vec3(x, chroma, 0.0);
    } else if (h_int == 2.0) {
        result = vec3(0.0, chroma, x);
    } else if (h_int == 3.0) {
        result = vec3(0.0, x, chroma);
    } else if (h_int == 4.0) {
        result = vec3(x, 0.0, chroma);
    } else {
        result = vec3(chroma, 0.0, x);
    }

    return result + m;
}

vec3 apply_color_correction(vec3 color) {
    color *= vec3(red_factor, green_factor, blue_factor);
    
    vec3 hsl = rgb2hsl(color);
    hsl.x = mod(hsl.x + hue_shift, 1.0);
    hsl.y = clamp(hsl.y * saturation, 0.0, 1.0);
    hsl.z = clamp(hsl.z, 0.0, 1.0);
    
    color = hsl2rgb(hsl);
    color = clamp(color * contrast + brightness, 0.0, 1.0);
    color = pow(color, vec3(gamma));
    
    return color;
}

void fragment() {
    vec2 uv = SCREEN_UV;
    vec4 final_color;
    
    if (chromatic_aberration_strength > 0.0) {
        vec2 offset = (uv - 0.5) * chromatic_aberration_strength;
        
        float r = texture(SCREEN_TEXTURE, uv + offset).r;
        vec4 center_sample = texture(SCREEN_TEXTURE, uv);
        float b = texture(SCREEN_TEXTURE, uv - offset).b;
        
        vec3 color = apply_color_correction(vec3(r, center_sample.g, b));
        final_color = vec4(color, center_sample.a);
    } else {
        vec4 tex_color = texture(SCREEN_TEXTURE, uv);
        final_color = vec4(apply_color_correction(tex_color.rgb), tex_color.a);
    }
    
    if (vignette_strength > 0.0) {
        vec2 vignette_uv = uv * 2.0 - 1.0;
        float vignette = 1.0 - dot(vignette_uv, vignette_uv) * vignette_strength;
        final_color.rgb *= clamp(vignette, 0.0, 1.0);
    }
    
    final_color.a *= alpha;
    COLOR = final_color;
}