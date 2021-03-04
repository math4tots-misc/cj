package cjx.chip8

import cjx.js.web.HTMLCanvasElement
import cjx.js.web.CanvasRenderingContext2D
import cjx.js.JSObject
import cjx.chip8.C8Renderer

class C8CanvasRenderer : C8Renderer {
    val scale: Double
    var ctx: CanvasRenderingContext2D
    var _pixels: List[Int] = [0] * rows * cols

    def(scale: Double, ctx: CanvasRenderingContext2D): Self {
        val self = __malloc(scale, ctx)
        canvas.width = (cols.toDouble() * scale).toInt()
        canvas.height = (rows.toDouble() * scale).toInt()
        self
    }

    def __get_canvas(self): HTMLCanvasElement = ctx.canvas.get()

    def render(self) {
        ctx.clearRect(0, 0, canvas.width, canvas.height)
        for i = 0; i < cols * rows; i++ {
            val x = ((i % cols).toDouble() * scale).toInt()
            val y = ((i / cols).toDouble() * scale).toInt()
            if _pixels[i] {
                ctx.fillStyle = "#000"
                ctx.fillRect(x, y, scale, scale)
            }
        }
    }
}
