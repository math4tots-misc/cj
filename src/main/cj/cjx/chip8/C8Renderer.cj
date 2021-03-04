package cjx.chip8

import cjx.js.web.HTMLCanvasElement
import cjx.js.web.CanvasRenderingContext2D
import cj.Uint8Array

class C8Renderer {
    static val cols = 64
    static val rows = 32

    val scale: Double
    val ctx: CanvasRenderingContext2D
    val display: Uint8Array = Uint8Array.withSize(rows * cols)

    def(scale: Double, ctx: CanvasRenderingContext2D): Self {
        val self = __malloc(scale, ctx)
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
        val pos = x + y * cols
        display[pos] = display[pos] ^ 1
        not display[pos]
    }

    def clear(self) {
        for i = 0; i < rows * cols; i++ {
            display[i] = 0
        }
    }

    def __get_canvas(self): HTMLCanvasElement = ctx.canvas.get()

    def render(self) {
        ctx.clearRect(0, 0, canvas.width, canvas.height)
        for i = 0; i < display.size(); i++ {
            val x = ((i % cols).toDouble() * scale).toInt()
            val y = ((i // cols).toDouble() * scale).toInt()
            if display[i] {
                ctx.fillStyle = "#000"
                ctx.fillRect(x, y, scale, scale)
            }
        }
    }
}
