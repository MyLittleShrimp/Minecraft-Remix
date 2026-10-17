shader_type canvas_item;
uniform vec4 cap_color : source_color = vec4(0.95,0.35,0.6,1.0);
void fragment() {
    vec4 pixel = COLOR;
    // Recolor the existing detailed red cap; retain cream spots/stem and ink.
    if (pixel.r > 0.2 && pixel.r > pixel.g * 1.45 && pixel.r > pixel.b * 1.2) {
        pixel.rgb = cap_color.rgb * pixel.r;
    }
    COLOR = pixel;
}
