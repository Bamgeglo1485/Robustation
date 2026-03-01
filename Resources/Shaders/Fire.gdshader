//  Procedural Torch & Candle Shader (Fire + Smoke + Sparks)
//  Author: CaptainLaptop
//  License: CC0 / MIT
//  Engine: Godot 4.x
//
//  Description:
//  A fully procedural, particle-free fire simulation that
//  generates animated flames, sparks, and smoke using only math.
//
//  Ideal for candles, torches, and other small light sources.
//  Avoid large full-screen use as it can be fillrate-heavy.
//
//  Controls include flicker, wind, hue shift, color, and size.

/* USAGE:
1. Apply this shader to a CanvasItem (e.g., a ColorRect or a Sprite2D).
2. The effect is drawn from the center of the node, growing upwards (Y-axis inverted).
3. Adjust 'aspectRatio' to match your node's width/height ratio if not 1:1.
*/
shader_type canvas_item;



// =============================================================================
// GLOBAL CONTROL UNIFORMS
// =============================================================================

// Controls the overall speed of particle movement and animation
uniform float speed : hint_range(0.1, 5.0) = 1.0;
// Defines the size of the 'pixels' or blocks the fire is rendered in
uniform float pixelSize : hint_range(0.001, 0.1) = 0.015;
// Overall intensity multiplier for the colors
uniform float alpha : hint_range(0.0, 1.0) = 0.95; 
// Strength of the overall light flicker effect
uniform float flickerStrength : hint_range(0.0, 0.5) = 0.15; 

// =============================================================================
// COLOR & HUE UNIFORMS
// =============================================================================

// Color near the top (smoke/darker)
uniform vec3 toColor : source_color = vec3(0.4, 0.35, 0.2);  
// Color near the base (hottest/brightest)
uniform vec3 fromColor : source_color = vec3(0.9, 0.2, 0.1); 

// Shifts the base color hue (HSV 'H' value)
uniform float hueShift : hint_range(-1.0, 1.0) = 0.0; 
// Multiplier for saturation (HSV 'S' value)
uniform float saturationFactor : hint_range(0.0, 2.0) = 1.0; 

// =============================================================================
// FIRE SIMULATION UNIFORMS
// =============================================================================

// The number of individual fire particles calculated
uniform float particleCount : hint_range(16.0, 512.0) = 128.0;
// Base light brightness applied to particles
uniform float brightness : hint_range(0.0001, 0.01) = 0.001;

// Horizontal influence of particle noise, determines flame width
uniform float fireShift : hint_range(0.0, 0.5) = 0.15;
// Frequency of the noise wave for horizontal flickering/wobble
uniform float fireShiftFrequency : hint_range(1.0, 10.0) = 5.0;

// x: Max horizontal span, y: Max vertical height of the fire
uniform vec2 size = vec2(0.05, 0.75);
// x: inner glow start, y: outer glow end (used in smoothstep for falloff)
uniform vec2 glow = vec2(0.001, 0.04); 

// =============================================================================
// SPARKS UNIFORMS
// =============================================================================

uniform float sparkCount : hint_range(1.0, 50.0) = 18.0; 
uniform float sparkSize : hint_range(0.0005, 0.005) = 0.004; 
uniform float sparkSpeed : hint_range(0.1, 3.0) = 0.15; 
uniform vec3 sparkColor : source_color = vec3(1.0, 0.7, 0.0); 

// =============================================================================
// SMOKE UNIFORMS
// =============================================================================

uniform float smokeCount : hint_range(5.0, 50.0) = 20.0;
uniform float smokeSize : hint_range(0.001, 0.05) = 0.015; 
uniform float smokeDrift : hint_range(0.0, 0.5) = 0.2; 
uniform vec3 smokeColor : source_color = vec3(0.05, 0.05, 0.05); 

// =============================================================================
// ENVIRONMENT UNIFORMS
// =============================================================================

// Constant horizontal force applied to all particles (wind)
uniform float windForce : hint_range(-0.5, 0.5) = 0.0; 
// Node's Width/Height ratio for correct aspect correction
uniform float aspectRatio : hint_range(0.01, 5.0) = 1.0; 
// Position offset (shifts the origin of the flame source)
uniform vec2 posOffset = vec2(0.0, -0.5); 


// =============================================================================
// HELPER FUNCTIONS
// =============================================================================

// 1D Hash function for generating particle randomness
float Hash1(float t) {
    return fract(cos(t * 124.97) * 248.842) - 0.5;
}

// Equivalent to GLSL's 'saturate' (clamps between 0.0 and 1.0)
float saturate(float x) {
    return clamp(x, 0.0, 1.0);
}

// --- HSV Utility Functions (Custom implementation for portability) ---

// Converts RGB color space to HSV color space
vec3 rgb_to_hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.w - q.y) / (6.0 * d + e) + q.z, d / (q.x + e), q.x);
}

// Converts HSV color space to RGB color space
vec3 hsv_to_rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.w);
    return c.z * mix(K.xxx, clamp(p - K.x, 0.0, 1.0), c.y);
}


// =============================================================================
// PARTICLE SIMULATION FUNCTIONS
// =============================================================================

// Core fire particle simulation
vec3 Simulate(vec2 uv, float t) {
    vec3 res = vec3(0.0);
    
    for (float i = 0.0; i < particleCount; i++) {
        // ct: Current time through the particle's lifecycle (0.0 to 1.0)
        float ct = fract(t + (i + 1.0) / particleCount);
        
        // seed: Unique randomness based on ID and current cycle
        float seed = Hash1((i + 1.0) * (t - ct));
        
        // dir: Base direction vector. WindForce affects X (horizontal).
        vec2 dir = vec2(0.0, size.y); 
        dir.x += windForce; 
        
        // Fire wobble/flicker (Horizontal noise based on time and seed)
        dir.x += (cos(t * seed) * sin(ct * fireShiftFrequency)) * mix(0.0, fireShift, log(ct));
        
        // cb: Current brightness, fading out as particle ages (ct increases)
        float cb = saturate(mix(brightness, 0.0, ct));
        
        // off: Initial horizontal offset randomized by seed
        vec2 off = vec2(seed * size.x, 0.0); 
        
        // Accumulate color: mix base color to top color based on age (ct)
        res += mix(fromColor * abs(seed), toColor, ct) 
               // Apply glow/falloff using smoothstep on inverse distance
               * smoothstep(glow.x, glow.y, cb / length((uv - off - (dir * ct))));
    }
    
    return res;
}

// Simulation for sharp, fast-moving sparks
vec3 SimulateSparks(vec2 uv, float t) {
    vec3 sparkRes = vec3(0.0);
    
    t *= sparkSpeed; // Adjust time scale for spark speed
    
    for (float i = 0.0; i < sparkCount; i++) {
        float particleId = (i + 1.0) * 133.0; 
        float ct = fract(t + particleId / 100.0); // Lifecycle time
        float seed = Hash1(particleId); 
        
        // High vertical velocity (2.5x flame height)
        vec2 dir = vec2(seed * 0.4, size.y * 2.5); 
        dir.x += windForce * 2.0; // Sparks are pushed harder by wind
        
        // Current particle center position
        vec2 particle_center = vec2(seed * size.x * 0.3, 0.0) + (dir * ct); 
        
        float dist = length(uv - particle_center);
        
        // Create an extremely sharp, localized glow
        float particle_influence = saturate(1.0 - dist / (sparkSize * 5.0)); 
        float glow_falloff = pow(particle_influence, 15.0); // High power = sharp falloff
        float lifespan_fade = saturate(1.0 - ct * 2.0); 

        // Add contribution (boost intensity for visibility)
        sparkRes += sparkColor * glow_falloff * lifespan_fade * 100.0; 
    }
    return sparkRes;
}

// Simulation for slow-moving, diffuse smoke
vec3 SimulateSmoke(vec2 uv, float t) {
    vec3 smokeRes = vec3(0.0);
    
    for (float i = 0.0; i < smokeCount; i++) {
        float particleId = (i + 1.0) * 111.0;  
        float ct = fract(t * 0.5 + particleId / 100.0); // Slower cycle
        float seed = Hash1(particleId); 
        
        // Slower vertical velocity than fire, with horizontal drift
        vec2 dir = vec2(seed * smokeDrift, size.y * 1.5); 
        dir.x += windForce * 0.8; // Smoke is pushed by wind
        
        float cb = saturate(mix(brightness * 10.0, 0.0, ct * 1.5)); 
        
        // Starts near the top of the fire/smoke base
        vec2 off = vec2(seed * size.x * 0.5, size.y * 0.6); 

        // Add contribution: uses a larger smoothstep range for a diffused look
        smokeRes += smokeColor * smoothstep(smokeSize, smokeSize * 2.0,
            cb / length((uv - off - (dir * ct))));
    }
    return smokeRes;
}


// =============================================================================
// FRAGMENT MAIN
// =============================================================================

void fragment() {
    // 1. Coordinate Setup
    vec2 frag_coords = UV * 2.0 - 1.0; // [-1, 1] range
    frag_coords.x *= aspectRatio;      // Correct X-axis for aspect ratio
    frag_coords.y *= -1.0;             // Invert Y so fire grows upwards
    frag_coords -= posOffset;          // Apply source offset
    
    // 2. Pixelation effect
    vec2 pixelated_frag = floor(frag_coords / pixelSize) * pixelSize;
    
    // 3. Run Simulations
    float base_time = TIME + 100.0;
    
    vec3 fire_color = Simulate(pixelated_frag, base_time * speed);
    vec3 spark_color = SimulateSparks(pixelated_frag, base_time);
    vec3 smoke_color = SimulateSmoke(pixelated_frag, base_time);

    vec3 result_color = fire_color + spark_color + smoke_color; 
    
    // 4. Hue & Saturation Control
    vec3 hsv = rgb_to_hsv(result_color);
    
    hsv.x = fract(hsv.x + hueShift); // Apply hue shift (wrap around)
    hsv.y *= saturationFactor;       // Apply saturation factor
    
    result_color = hsv_to_rgb(hsv);
    
    // 5. Apply Flicker
    float flicker = (Hash1(base_time * 5.0) + 0.5) * flickerStrength; 
    float intensity_mod = 1.0 + flicker; 
    vec3 final_color = result_color * intensity_mod;

    // 6. Alpha Calculation
    // Use the max color channel intensity to define alpha (transparency)
    float intensity = max(max(result_color.r, result_color.g), result_color.b);
    
    // Smoothstep ensures sharp cut-off on edges
    float final_alpha = smoothstep(0.01, 0.5, intensity) * alpha;
    
    // Final output color
    COLOR = vec4(final_color * alpha, final_alpha);
}
