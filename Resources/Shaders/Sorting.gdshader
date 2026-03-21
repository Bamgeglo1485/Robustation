shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float mask_softness = 1.4; // negative values result in mask being inverted
uniform float mask_threshold = 0.6;

uniform float sort :hint_range(0.0, 2.0)= 0.0;

void fragment(){
	vec2 uv = FRAGCOORD.xy / (1.0 / SCREEN_PIXEL_SIZE).xy;
	vec4 tex = texture(SCREEN_TEXTURE, uv);
	
	// Masking
	float f = mask_softness / 2.0;
	float a = mask_threshold - f;
	float b = mask_threshold + f;
	float average = (tex.x + tex.y + tex.z) / 3.0;
	float mask = smoothstep(a, b, average);
	
	// Pseudo Pixel Sorting
	float sort_threshold = 1.0 - clamp(sort / 2.6, 0.0, 1.0);
	vec2 sort_uv = vec2(uv.x, sort_threshold);
	
	// Curved melting transition
	vec2 transition_uv = uv;
	float turbulance = fract(sin(dot(vec2(transition_uv.x), vec2(12.9, 78.2)))* 437.5);
	transition_uv.y += pow(sort, 2.0 + (sort * 2.0)) * mask * turbulance;
	COLOR = texture(SCREEN_TEXTURE, transition_uv);
	
	// Draw pixel sorting effect behind the melting transition
	if(transition_uv.y > 1.){
		COLOR = texture(SCREEN_TEXTURE, sort_uv);
	}else{
		COLOR = texture(SCREEN_TEXTURE, uv);
	}
	
//	COLOR = vec4(mask, mask, mask, 1.0); // Uncomment this to check mask
}