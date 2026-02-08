shader_type canvas_item;

// Jittery motion parameters
uniform float jitter_strength : hint_range(0.0, 20.0) = 2.0;
uniform float jitter_speed : hint_range(0.1, 20.0) = 8.0;
uniform float jitter_frequency : hint_range(0.1, 50.0) = 12.0;
uniform bool separate_xy = true;
uniform float time_offset : hint_range(0.0, 100.0) = 0.0;

// Dynamic rotation parameters
uniform bool enable_rotation = true;
uniform float rotation_strength : hint_range(0.0, 45.0) = 5.0;
uniform float rotation_speed : hint_range(0.1, 10.0) = 3.0;
uniform float rotation_frequency : hint_range(0.1, 20.0) = 4.0;

// Dynamic scale parameters
uniform bool enable_scaling = true;
uniform float scale_strength : hint_range(0.0, 0.5) = 0.1;
uniform float scale_speed : hint_range(0.1, 10.0) = 2.5;
uniform float scale_frequency : hint_range(0.1, 20.0) = 6.0;
uniform float base_scale : hint_range(0.5, 2.0) = 1.0;

// Text effect parameters
uniform vec4 text_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform bool use_custom_color = false;
uniform float shake_intensity : hint_range(0.0, 1.0) = 0.5;

// Adaptive pixel art effect parameters
uniform bool enable_pixelation = true;
uniform float pixel_size : hint_range(1.0, 32.0) = 4.0;
uniform bool adaptive_pixels = true; // New parameter for adaptive pixel sizing
uniform bool enable_outline = true;
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_thickness : hint_range(0.5, 3.0) = 1.0;

// Optional chromatic aberration for extra effect
uniform bool chromatic_aberration = false;
uniform float aberration_strength : hint_range(0.0, 5.0) = 1.0;

// Random function for generating noise
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// Smooth noise function
float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// 2D rotation matrix
mat2 rotate2D(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(vec2(c, -s), vec2(s, c));
}

void vertex() {
    float time_adjusted = TIME * jitter_speed + time_offset;
    
    // Calculate center of the vertex for rotation and scaling
    vec2 center = vec2(0.5, 0.5);
    vec2 vertex_pos = VERTEX;
    
    // Apply dynamic scaling
    if (enable_scaling) {
        float scale_time = TIME * scale_speed + time_offset;
        float scale_noise = noise(vec2(scale_time * scale_frequency, vertex_pos.x * 0.1));
        float scale_factor = base_scale + (scale_noise - 0.5) * scale_strength;
        vertex_pos = (vertex_pos - center) * scale_factor + center;
    }
    
    // Apply dynamic rotation
    if (enable_rotation) {
        float rotation_time = TIME * rotation_speed + time_offset;
        float rotation_noise = noise(vec2(rotation_time * rotation_frequency, vertex_pos.y * 0.1));
        float rotation_factor = (rotation_noise - 0.5) * rotation_strength;
        float rotation_angle = rotation_factor * 0.017453; // Convert to radians
        
        vec2 rotated_pos = vertex_pos - center;
        rotated_pos = rotate2D(rotation_angle) * rotated_pos;
        vertex_pos = rotated_pos + center;
    }
    
    // Apply jitter effect
    vec2 jitter_offset;
    if (separate_xy) {
        // Separate jitter for X and Y axes
        float jitter_x = noise(vec2(time_adjusted * jitter_frequency, vertex_pos.x * 0.05)) - 0.5;
        float jitter_y = noise(vec2(vertex_pos.y * 0.05, time_adjusted * jitter_frequency + 17.3)) - 0.5;
        jitter_offset = vec2(jitter_x, jitter_y) * jitter_strength;
    } else {
        // Combined jitter
        float jitter_value = noise(vec2(time_adjusted * jitter_frequency, length(vertex_pos) * 0.1)) - 0.5;
        jitter_offset = vec2(jitter_value) * jitter_strength;
    }
    
    // Apply all transformations
    VERTEX = vertex_pos + jitter_offset * shake_intensity;
}

varying float v_scale_factor;
varying float v_rotation_factor;

void fragment() {
    vec2 uv = UV;
    
    // Apply adaptive pixelation effect if enabled
    if (enable_pixelation) {
        vec2 texture_size = 1.0 / TEXTURE_PIXEL_SIZE;
        
        // Calculate adaptive pixel size based on transformations
        float adaptive_pixel_size = pixel_size;
        
        if (adaptive_pixels) {
            // Calculate current transformation factors for this fragment
            float current_scale_factor = base_scale;
            float current_rotation_factor = 0.0;
            
            if (enable_scaling) {
                float scale_time = TIME * scale_speed + time_offset;
                float scale_noise = noise(vec2(scale_time * scale_frequency, uv.x * 10.0));
                current_scale_factor = base_scale + (scale_noise - 0.5) * scale_strength;
                adaptive_pixel_size *= current_scale_factor;
            }
            
            if (enable_rotation) {
                float rotation_time = TIME * rotation_speed + time_offset;
                float rotation_noise = noise(vec2(rotation_time * rotation_frequency, uv.y * 10.0));
                current_rotation_factor = abs((rotation_noise - 0.5) * rotation_strength);
                adaptive_pixel_size *= (1.0 + current_rotation_factor * 0.02);
            }
        }
        
        // Ensure minimum pixel size to avoid artifacts
        adaptive_pixel_size = max(adaptive_pixel_size, 1.0);
        
        vec2 pixel_uv = floor(uv * texture_size / adaptive_pixel_size) * adaptive_pixel_size / texture_size;
        pixel_uv += (adaptive_pixel_size / texture_size) * 0.5; // Center the pixel
        uv = pixel_uv;
    }
    
    vec4 base_color = texture(TEXTURE, uv);
    
    // Create pixel art outline effect
    if (enable_outline && base_color.a > 0.1) {
        vec2 texture_size = 1.0 / TEXTURE_PIXEL_SIZE;
        float outline_step = outline_thickness / max(texture_size.x, texture_size.y);
        
        // Sample surrounding pixels for outline
        float outline_alpha = 0.0;
        for (float x = -outline_step; x <= outline_step; x += outline_step) {
            for (float y = -outline_step; y <= outline_step; y += outline_step) {
                if (x == 0.0 && y == 0.0) continue;
                vec2 offset_uv = uv + vec2(x, y);
                if (enable_pixelation) {
                    offset_uv = floor(offset_uv * texture_size / pixel_size) * pixel_size / texture_size;
                    offset_uv += (pixel_size / texture_size) * 0.5;
                }
                float sample_alpha = texture(TEXTURE, offset_uv).a;
                outline_alpha = max(outline_alpha, sample_alpha);
            }
        }
        
        // Apply outline where there's no text but outline should be
        if (base_color.a < 0.1 && outline_alpha > 0.1) {
            base_color = outline_color;
        }
    }
    
    // Enhanced chromatic aberration effect with dynamic intensity
    if (chromatic_aberration && base_color.a > 0.1) {
        float time_adjusted = TIME * jitter_speed + time_offset;
        float aberration_intensity = noise(vec2(time_adjusted * 0.5)) * aberration_strength;
        
        vec2 aberration_offset = vec2(
            noise(vec2(time_adjusted * jitter_frequency * 2.0, uv.x * 10.0)) - 0.5,
            noise(vec2(uv.y * 10.0, time_adjusted * jitter_frequency * 2.0 + 23.7)) - 0.5
        ) * aberration_intensity * 0.01;
        
        vec2 r_uv = uv + aberration_offset;
        vec2 b_uv = uv - aberration_offset;
        
        if (enable_pixelation) {
            vec2 texture_size = 1.0 / TEXTURE_PIXEL_SIZE;
            r_uv = floor(r_uv * texture_size / pixel_size) * pixel_size / texture_size;
            r_uv += (pixel_size / texture_size) * 0.5;
            b_uv = floor(b_uv * texture_size / pixel_size) * pixel_size / texture_size;
            b_uv += (pixel_size / texture_size) * 0.5;
        }
        
        float r = texture(TEXTURE, r_uv).r;
        float g = base_color.g;
        float b = texture(TEXTURE, b_uv).b;
        
        base_color.rgb = vec3(r, g, b);
    }
    
    // Apply custom color if enabled
    if (use_custom_color) {
        COLOR = vec4(text_color.rgb, base_color.a * text_color.a);
    } else {
        COLOR = base_color;
    }
}