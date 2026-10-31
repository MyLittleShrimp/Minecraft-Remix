shader_type canvas_item;
render_mode blend_add, unshaded;

uniform vec4 glow_color : source_color = vec4(0.18, 0.72, 1.0, 0.85);
varying float inherited_alpha;

void vertex() {
    // Fragment COLOR already includes texture alpha; that would clip the halo to the core.
    inherited_alpha = COLOR.a;
}

float coverage(sampler2D tex, vec2 uv, vec2 lo, vec2 hi) {
    return texture(tex, clamp(uv, lo, hi)).a;
}

void fragment() {
    float opacity = inherited_alpha;
    vec2 pixel = TEXTURE_PIXEL_SIZE;
    // Each sheet has 96px-wide cells. Clamp all taps to the current frame.
    float cell_x = floor((UV.x / pixel.x) / 96.0) * 96.0;
    vec2 lo = vec2((cell_x + 0.5) * pixel.x, 0.5 * pixel.y);
    vec2 hi = vec2((cell_x + 95.5) * pixel.x, 1.0 - 0.5 * pixel.y);
    float halo = 0.0;
    float weight = 0.0;
    for (int x = -8; x <= 8; x++) {
        float w = exp(-float(x * x) / 20.0);
        halo += coverage(TEXTURE, UV + vec2(float(x), 0.0) * pixel, lo, hi) * w;
        weight += w;
    }
    for (int y = -2; y <= 2; y++) {
        float w = 0.3 * exp(-float(y * y) / 2.0);
        halo += coverage(TEXTURE, UV + vec2(0.0, float(y) * 2.0) * pixel, lo, hi) * w;
        weight += w;
    }
    COLOR = vec4(glow_color.rgb, halo / weight * glow_color.a * opacity);
}
