shader_type canvas_item;

uniform float speed = 0.8;

// Overall sway strength (in pixels at your game resolution)
uniform float amplitude_px = 1.2;

// Where sway starts (0 = bottom, 1 = top). Higher = less trunk movement.
uniform float height_offset : hint_range(0.0, 1.0) = 0.28;

// Small “alive” variation
uniform float messiness_px = 0.5;
uniform float messiness_speed = 1.2;

// Occasional gentle gust
uniform float gust_strength_px = 0.4;
uniform float gust_speed = 0.25;

// Noise scale controls how “chunky” the variation is across the sprite
uniform float noise_scale = 0.18;

// Per-instance offset so multiple trees don’t sync
uniform float offset = 0.0;

// Make edges move more than center
uniform float edge_boost = 2.0;

// Quantize motion to pixel steps (1.0 = per-pixel)
uniform float pixel_step = 1.0;

// --- NEW: explicit fragmentation controls ---
uniform float fragment_rows : hint_range(1.0, 128.0) = 32.0; // MORE = more fragments
uniform float fragment_phase_amount = 1.6;                  // how out-of-sync each band is
uniform float fragment_amp_jitter = 0.35;                   // per-band amplitude variation (0..1-ish)

float ease_out(float x) { return 1.0 - pow(1.0 - x, 2.2); }

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 345.45));
	p += dot(p, p + 34.345);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void vertex() {
	// Height influence: top moves more than bottom
	float y = 1.0 - UV.y;
	float height_inf = clamp((y - height_offset) / max(0.0001, 1.0 - height_offset), 0.0, 1.0);
	height_inf = ease_out(height_inf);

	// Edge influence: edges move more than center
	float x01 = abs(UV.x - 0.5) * 2.0; // 0..1
	float edge_shape = pow(x01, 1.6);
	float edge_mult = mix(1.0, edge_boost, edge_shape);

	// --- Fragment banding (more rows = more fragments) ---
	float rows = max(1.0, fragment_rows);
	float band_f = floor(UV.y * rows);                  // 0..rows-1 (horizontal strips)
	float band_u = (band_f + 0.5) / rows;               // stable per-band coordinate

	// Stable per-band randoms
	float band_r1 = hash21(vec2(band_f + 13.0, offset * 0.37));
	float band_r2 = hash21(vec2(band_f + 71.0, 9.0 + offset));

	// Per-band phase + amplitude jitter (creates the “pieces moving at different times”)
	float band_phase = (band_r1 - 0.5) * fragment_phase_amount;
	float band_amp   = 1.0 + (band_r2 - 0.5) * 2.0 * fragment_amp_jitter;

	// Time with per-band phase offset
	float t = TIME * speed + offset + band_phase;

	// Optional: keep some spatial noise so it doesn't look too uniform
	float n1 = vnoise(vec2(band_u * rows, 0.0) * noise_scale + vec2(offset, offset * 0.37));
	float n2 = vnoise(vec2(band_u * rows, 5.0) * (noise_scale * 2.0) + vec2(17.0 + offset, 9.0));

	float global_sway = sin(t) * amplitude_px * height_inf;
	float gust = sin(TIME * gust_speed + offset * 0.13 + band_phase * 0.5) * gust_strength_px * height_inf;

	float phase = n1 * 6.2831853;
	float local_move = sin(t * messiness_speed + phase) * messiness_px * height_inf;
	local_move += (n2 - 0.5) * messiness_px * 0.35 * height_inf;

	float x_move = (global_sway + gust + local_move) * edge_mult * band_amp;

	// Pixel-step snap (per-pixel motion)
	if (pixel_step > 0.0) {
		x_move = floor(x_move / pixel_step + 0.5) * pixel_step;
	}

	VERTEX.x += x_move;
}
