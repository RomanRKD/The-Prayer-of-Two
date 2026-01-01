shader_type canvas_item;

// Base timing
uniform float speed = 1.09;

// Base lock + shaping (your defaults)
uniform float base_lock : hint_range(0.0, 1.0) = 0.139;
uniform float canopy_start : hint_range(0.0, 1.0) = 0.043;
uniform float canopy_curve : hint_range(0.5, 8.0) = 0.5;

// Per-sprite phase offset
uniform float offset = 0.0;

// --- NEW: Dynamic wind amplitude (in pixels) ---
uniform float amp_min : hint_range(0.0, 50.0) = 14.0;   // common low
uniform float amp_max : hint_range(0.0, 50.0) = 20.0;   // common high
uniform float amp_rare_min : hint_range(0.0, 50.0) = 6.5; // occasional dip
uniform float amp_speed : hint_range(0.0, 5.0) = 0.18;  // how fast strength changes

// --- NEW: Vertical compensation to reduce “stretching” look ---
uniform float y_comp : hint_range(0.0, 1.0) = 0.12; // 0.08–0.18 is typical

float hash11(float n) { return fract(sin(n) * 43758.5453123); }

// Smooth 1D value noise (no harsh jumps)
float vnoise1(float x) {
	float i = floor(x);
	float f = fract(x);
	float a = hash11(i + 10.0);
	float b = hash11(i + 11.0);
	float u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u);
}

void vertex() {
	// 0 bottom -> 1 top
	float h = 1.0 - UV.y;

	float w = 0.0;
	if (h > base_lock) {
		float h2 = (h - base_lock) / max(0.0001, 1.0 - base_lock);
		w = clamp((h2 - canopy_start) / max(0.0001, 1.0 - canopy_start), 0.0, 1.0);
		w = pow(w, canopy_curve);
	}

	// --- Dynamic amplitude: mostly 14–20, sometimes dips to ~6–7 ---
	float n_main = vnoise1(TIME * amp_speed + offset * 3.7);            // 0..1
	float n_rare = vnoise1(TIME * (amp_speed * 0.45) + 100.0 + offset); // 0..1

	// Base band 14–20
	float amp = mix(amp_min, amp_max, n_main);

	// Rare dips: when n_rare is low, blend down toward amp_rare_min
	// Smooth gate so it *sometimes* dips, not constantly.
	float dip_gate = smoothstep(0.22, 0.0, n_rare); // 0 most of the time, 1 when rare low
	amp = mix(amp, amp_rare_min, dip_gate);

	// Actual sway motion
	float t = TIME * speed + offset;
	float sway = sin(t) * amp * w;

	// Horizontal bend
	VERTEX.x += sway;

	// Vertical compensation: makes top follow a slight arc instead of “stretching”
	// Uses sway^2 so it always drops a little regardless of left/right direction.
	// Kept subtle and weighted toward the top.
	VERTEX.y += - (sway * sway) * y_comp * 0.01;
}
