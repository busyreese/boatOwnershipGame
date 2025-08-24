shader_type canvas_item;

uniform float pixel_size = 4.0;

void fragment() {
    vec2 pos = UV / pixel_size;
    vec2 pixel = floor(pos);
    pos = pixel * pixel_size;
    
    vec4 color = texture(TEXTURE, pos);
    COLOR = color;
}