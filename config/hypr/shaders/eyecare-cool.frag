// Eye comfort shader: subtle / cool
#version 300 es
precision mediump float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

void main() {
    vec4 pixColor = texture(tex, v_texcoord);
    pixColor.r *= 1.00;
    pixColor.g *= 0.97;
    pixColor.b *= 0.90;
    fragColor = pixColor;
}
