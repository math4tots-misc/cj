package cjx.emu.chip8

import cjx.webgl.WebGLGridRenderer
import cjx.js.web.HTMLCanvasElement
import cjx.js.web.CanvasRenderingContext2D
import cj.Uint8Array

class C8Renderer {
    static val cols = 64
    static val rows = 32

    val scale: Double
    val canvas: HTMLCanvasElement
    val renderer: WebGLGridRenderer

    def(scale: Double, canvas: HTMLCanvasElement): Self {
        val self = __malloc(scale, canvas, WebGLGridRenderer(canvas, rows, cols))
        canvas.width = (cols.toDouble() * scale).toInt()
        canvas.height = (rows.toDouble() * scale).toInt()
        self
    }

    def togglePixel(self, var x: Int, var y: Int): Bool {
        # TODO: Figure out the proper wrapping rules
        # It seems that the pixels at the edges might actually just
        # be clipped instead of being wrapped
        # (http://www.emulator101.com/chip-8-sprites.html)
        if y == rows {
            return false
        }
        if x >= cols { x -= cols } else if x < 0 { x += cols }
        if y >= rows { y -= rows } else if y < 0 { y += rows }
        val pixel = renderer.getPixel(y, x)
        renderer.togglePixel(y, x)
        pixel > 0.5
    }

    def clear(self) {
        renderer.setAllPixels(0.0)
    }

    def render(self) {
        renderer.draw()
    }
}
