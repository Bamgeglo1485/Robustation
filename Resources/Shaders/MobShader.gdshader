shader_type canvas_item;

/* ================= BLOOD EFFECT UNIFORMS ================= */
uniform sampler2D blood_noise : repeat_enable;
uniform float blood_noise_shading = 1.0;
uniform float blood_intensity : hint_range(0.0, 1.0) = 0.0; 
uniform vec4 blood_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float blood_pixel_scale : hint_range(1.0, 100.0) = 10.0;

/* ================= DYNAMIC OUTLINE UNIFORMS ================= */
uniform float aura_max_line_width: hint_range(0.0, 100.0) = 10.0;
uniform float aura_min_line_width: hint_range(0.0, 100.0) = 5.0;
uniform float aura_speed: hint_range(0.0, 10.0) = 1.0;
uniform float aura_block_size: hint_range(0.001, 100.0) = 20.0;
uniform vec4 aura_outline_color: source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float aura_outline_tolerance: hint_range(0.0, 0.999) = 0.0;
uniform float aura_opacity: hint_range(0.0, 1.0) = 1.0;

/* ================= FLASH EFFECT UNIFORMS ================= */
uniform vec4 flash_color : source_color = vec4(1., 1., 0., 1);
uniform float flash_intensity : hint_range(0.0, 1.0) = 1.0;

/* ================= GLITCH EFFECT UNIFORMS ================= */
uniform float glitch_chance : hint_range(0.0, 1.0) = 0.2;
uniform float glitch_speed = 7.0;
uniform float glitch_slice_density = 14.0;
uniform float glitch_slice_strength = 0.38;
uniform float glitch_shake_strength = 0.02;
uniform float glitch_chroma_offset = 0.016;
uniform float glitch_noise_strength = 0.2;
uniform float glitch_color_flash_strength = 0.4;
uniform float glitch_scanline_strength = 0.18;
uniform float glitch_local_warp_strength = 0.14;
uniform float glitch_flip_chance : hint_range(0.0,1.0) = 0.15;

/* ================= VERTEX SHADER ================= */
void vertex() {
	float max_width = max(aura_max_line_width, aura_min_line_width);
	VERTEX = vec2(VERTEX.x * (1.0 + TEXTURE_PIXEL_SIZE.x * max_width * 2.0), 
				  VERTEX.y * (1.0 + TEXTURE_PIXEL_SIZE.y * max_width * 2.0));
}

/* ================= UTILITY FUNCTIONS ================= */
bool border(vec2 uv) {
	vec2 uvBorder = abs(uv - vec2(0.5));
	return max(step(0.5, uvBorder.x), step(0.5, uvBorder.y)) > 0.0;
}

float get_alpha(sampler2D tex, vec2 uv) {
	float res = 0.0;
	if (!border(uv)) {
		res = texture(tex, uv).a;
	}
	return res;
}

float hash(vec2 p, float s) {
	return fract(35.1 * sin(dot(vec3(112.3, 459.2, 753.2), vec3(p, s))));
}

float noise(vec2 p, float s) {
	vec2 d = vec2(0, 1);
	vec2 b = floor(p);
	vec2 f = fract(p);
	return mix(
		mix(hash(b + d.xx, s), hash(b + d.yx, s), f.x),
		mix(hash(b + d.xy, s), hash(b + d.yy, s), f.x), f.y);
}

float get_line_width(vec2 p, float s) {
	p /= aura_block_size;
	float w = 0.0;
	float intensity = 1.0;
	for (int i = 0; i < 3; i++) {
		w = mix(w, noise(p, s), intensity);
		p /= 2.0;
		intensity /= 2.0;
	}
	
	return mix(aura_max_line_width, aura_min_line_width, w);
}

float in_range(vec2 size, sampler2D tex, vec2 uv) {
	float res = 0.0;
	for (float i = -1.0; i < 2.0; i += 2.0) {
		res += get_alpha(tex, uv + vec2(i * size.x, 0.0));
		res += get_alpha(tex, uv + vec2(0.0, i * size.y));
		for (float j = -1.0; j < 2.0; j += 2.0) {
			res += get_alpha(tex, uv + vec2(i * size.x, j * size.y));
			res += get_alpha(tex, uv + vec2(i * size.x, j * size.y * 0.5));
		}
	}
	return res;
}

/* ================= GLITCH RANDOM FUNCTIONS ================= */
float glitch_rand(float x) { 
	return fract(sin(x * 143758.5453) * 43758.5453); 
}

float glitch_rand2(vec2 p) { 
	return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); 
}

/* ================= FRAGMENT SHADER ================= */
void fragment() {
	vec2 glitch_uv = UV;
	vec2 outline_uv = UV;
	
	// ================= GLITCH EFFECT =================
	float glitch_active = step(1.0 - glitch_chance, glitch_rand(floor(TIME * glitch_speed)));
	
	/* ----- SLICES EFFECT ----- */
	float slice_id = floor(glitch_uv.y * glitch_slice_density + glitch_rand(floor(TIME)));
	float slice_rand = glitch_rand(slice_id + floor(TIME * glitch_speed));
	float slice_mask = step(0.5, slice_rand) * glitch_active;
	
	if(glitch_rand(slice_id * TIME) < glitch_flip_chance) {
		glitch_uv.x = 1.0 - glitch_uv.x;
	}
	
	glitch_uv.x += (slice_rand - 0.5) * glitch_slice_strength * slice_mask;
	
	/* ----- MICRO JITTER ----- */
	float jitter = step(0.85, glitch_rand(TIME * 12.0)) * glitch_active;
	glitch_uv.x += (glitch_rand(TIME * 3.0) - 0.5) * 0.08 * jitter;
	
	/* ----- LOCAL WARP ----- */
	float warp_zone = step(0.65, glitch_rand2(vec2(slice_id, TIME)));
	glitch_uv += (vec2(glitch_rand2(glitch_uv + TIME), glitch_rand2(glitch_uv - TIME)) - 0.5) 
				 * glitch_local_warp_strength * warp_zone * glitch_active;
	
	/* ----- GLOBAL SHAKE ----- */
	glitch_uv += vec2(
		glitch_rand(TIME * 1.3) - 0.5,
		glitch_rand(TIME * 1.7) - 0.5
	) * glitch_shake_strength * glitch_active;
	
	// ================= ORIGINAL TEXTURE WITH GLITCH =================
	vec4 glitch_base = texture(TEXTURE, glitch_uv);
	
	/* ----- COLOR SPLIT ----- */
	float r = texture(TEXTURE, glitch_uv + vec2(glitch_chroma_offset * glitch_active, 0.0)).r;
	float b = texture(TEXTURE, glitch_uv - vec2(glitch_chroma_offset * glitch_active, 0.0)).b;
	vec3 glitch_color = vec3(r, glitch_base.g, b);
	
	/* ----- DIGITAL NOISE ----- */
	glitch_color += (glitch_rand2(glitch_uv * TIME * 1.5) - 0.5) * glitch_noise_strength * glitch_active;
	
	/* ----- SCANLINE DROP ----- */
	float scan = step(0.9, glitch_rand(glitch_uv.y * 100.0 + TIME * 10.0));
	glitch_color *= 1.0 - scan * glitch_scanline_strength * glitch_active;
	
	/* ----- COLOR FLASH ----- */
	vec3 glitch_flash_color = vec3(
		step(0.5, glitch_rand(TIME + 0.1)),
		step(0.5, glitch_rand(TIME + 3.1)),
		step(0.5, glitch_rand(TIME + 6.1))
	);
	glitch_color = mix(glitch_color, glitch_flash_color, 
					   glitch_rand(TIME * 4.0) * glitch_color_flash_strength * glitch_active);
	
	vec4 originalColor = vec4(glitch_color, glitch_base.a);
	vec4 newColor = originalColor;
	
	// ================= DYNAMIC OUTLINE EFFECT =================
	float max_width = max(aura_max_line_width, aura_min_line_width);
	if (max_width > 0.0 && aura_opacity > 0.0) {
		if (!border(outline_uv)) {
			float timeStep = floor(TIME * aura_speed);
			vec2 size = TEXTURE_PIXEL_SIZE;
			size *= get_line_width(outline_uv / TEXTURE_PIXEL_SIZE, timeStep);
			float outline_alpha = step(1.0 - aura_outline_tolerance, in_range(size, TEXTURE, outline_uv));
			
			if (outline_alpha > 0.0 && originalColor.a <= aura_outline_tolerance) {
				vec4 aura_color_with_opacity = aura_outline_color;
				aura_color_with_opacity.a *= aura_opacity * outline_alpha;
				newColor = aura_color_with_opacity;
			}
		}
	}
	
	// ================= BLOOD EFFECT =================
	vec2 pixel_size = vec2(1.0) / TEXTURE_PIXEL_SIZE;
	vec2 pixelated_uv = floor(outline_uv * pixel_size / blood_pixel_scale) * (blood_pixel_scale / pixel_size);
	
	vec4 noise_texture = texture(blood_noise, pixelated_uv);
	
	float blood_mask = 1.0 - step(noise_texture.r, blood_intensity);
	
	vec3 blood_color_final = blood_color.rgb * mix(vec3(1.0), noise_texture.rgb, blood_noise_shading);
	vec3 final_color = newColor.rgb;
	
	if (blood_mask > 0.0) {
		final_color = mix(final_color, blood_color_final, blood_color.a * blood_mask);
	}
	
	// ================= FLASH EFFECT =================
	if (flash_color.a > 0.0) {
		float flash_strength = flash_color.a * flash_intensity;
		if (flash_strength > 0.0) {
			vec3 flash_final = mix(final_color, flash_color.rgb, flash_strength);
			final_color = flash_final;
		}
	}
	
	// ================= FINAL COLOR =================
	float final_alpha = max(originalColor.a, newColor.a);
	COLOR = vec4(final_color, final_alpha);
}