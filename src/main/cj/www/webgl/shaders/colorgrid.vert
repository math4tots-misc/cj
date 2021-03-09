#version 300 es
precision mediump float;

in vec3 aVertexColor;
out vec3 vColor;
uniform float uNRows;
uniform float uNCols;

// each cell has corners numbered
//
// 0  -  3
// |  \  |
// 1  -  2
//

void main(void) {
    int nrows = int(uNRows);
    int ncols = int(uNCols);
    int corner = gl_VertexID;
    int pixelID = gl_InstanceID;
    int row = pixelID / ncols;
    int col = pixelID % ncols;

    float pixelWidth = 2.0 / uNCols;
    float pixelHeight = 2.0 / uNRows;

    float x = -1.0 + pixelWidth * float(col);
    float y = 1.0 - pixelHeight * float(row);

    if (corner == 2 || corner == 3) {
        x += pixelWidth;
    }

    if (corner == 1 || corner == 2) {
        y -= pixelHeight;
    }

    vColor = aVertexColor;
    gl_PointSize = uNRows + uNCols;
    gl_Position = vec4(x, y, 0.0, 1.0);
}
