#version 300 es
precision mediump float;

in float vVertexData;
out vec4 fragColor;

void main(void) {
    fragColor = vec4(vVertexData, vVertexData, vVertexData, 1.0);
}
