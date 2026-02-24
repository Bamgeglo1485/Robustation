// CC0, shadecore_dev

shader_type canvas_item;

/* Color for the outline. */
uniform vec4 outline_color : source_color = vec4(1.0);

/* Outline alpha reduction at the start of the progress. Leave at 1.0 to disable fading. */
uniform float fade_minimum_alpha : hint_range(0.0, 1.0)  = 0.5;

/* Outline fill progress. */
uniform float progress : hint_range(0.0, 1.0) = 1.0;

/* Rotation of the progress effect. */
uniform float rotation : hint_range(0.0, 6.28318530718) = 0.0;

/* Draw pixel outline on the borders of the sprite. */
uniform bool draw_border = true;

uniform int fill_style : hint_enum("Clock", "Center Fill", "Bottom Fill") = 0;

void fragment() {
	vec2 pixel_size = TEXTURE_PIXEL_SIZE;
	bool within = texture(TEXTURE, UV + pixel_size * vec2(1.0, 0.0)).a > 0.0;
	within = within || texture(TEXTURE, UV + pixel_size * vec2(0.0, -1.0)).a > 0.0;
	within = within || texture(TEXTURE, UV + pixel_size * vec2(0.0, 1.0)).a > 0.0;
	within = within || texture(TEXTURE, UV + pixel_size * vec2(-1.0, 0.0)).a > 0.0;

	bool outline = (within && (texture(TEXTURE, UV).a == 0.0)) ||
			(
				draw_border && (
					abs(UV.x - 0.5) >= 0.5 - pixel_size.x ||
					abs(UV.y - 0.5) >= 0.5 - pixel_size.y
				)
			);

	float fill;
	switch (fill_style){
		case 0:
			fill = (
				(
					atan(
						floor((UV.x - 0.5) / pixel_size.x) * cos(rotation) + floor((UV.y - 0.5) / pixel_size.y) * sin(rotation),
						floor((UV.y - 0.5) / pixel_size.y) * cos(rotation) - floor((UV.x - 0.5) / pixel_size.x) * sin(rotation)
					) - PI
				) / -TAU <= progress ? 1.0 : 0.0
			);
			break;
		case 1:
			fill = float(distance(vec2(
				floor((UV.x - 0.5) / pixel_size.x),
				floor((UV.y - 0.5) / pixel_size.y)
			) * pixel_size, vec2(0.0, 0.0)) <= progress * 0.70710678118);
			break;
		case 2:
			fill = float(
				(
					0.5 - (floor((UV.y - 0.5) / pixel_size.y) * cos(rotation) * pixel_size.y - floor((UV.x - 0.5) / pixel_size.x) * sin(rotation) * pixel_size.x)
				) <= progress
			);
			break;
	}

	COLOR = float(!outline) * COLOR +
		float(outline) *
		outline_color *
		fill *
		(fade_minimum_alpha + progress * (1.0 - fade_minimum_alpha));
}