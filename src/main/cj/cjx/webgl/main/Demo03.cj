package cjx.webgl.main

import cjx.webgl.WebGLGridRenderer
import cjx.js.web.Window
import cjx.js.web.WebGLUniformLocation
import cjx.js.web.WebGLProgram
import cjx.js.web.WebGLVertexArrayObject
import cj.Float32Array
import cjx.js.web.WebGLBuffer
import cjx.js.web.WebGL2RenderingContext
import cjx.js.web.Document
import cjx.js.web.HTMLCanvasElement
import cjx.webgl.WebGLHelper

class Demo03 {
    static var modulo = 5
    static var remainder = 0
    static val nrows = 45
    static val ncols = 60
    static val window: Window = Window.get()
    static val document: Document = Document.get()
    static val canvas: HTMLCanvasElement = document.getElementBydId("canvas")
    static val renderer: WebGLGridRenderer = WebGLGridRenderer(canvas, nrows, ncols)

    def main() {
        # Don't make initial state pitch black -- set all colors to be grey
        renderer.setAllPixels(0.2)

        togglePixelGroup(3, 0)
        renderer.draw()

        var lastRem1 = 0
        var lastRem2 = modulo // 2 + 3
        var lastTimeStampMs = 0.0

        var tick: Fn[Double, Unit] = tsMs -> ()
        tick = tsMs -> {
            val elapsed = (tsMs - lastTimeStampMs) / 1000
            if elapsed > 0.5 {
                lastTimeStampMs = tsMs
                togglePixelGroup(modulo, remainder % modulo)
                if modulo < 11 {
                    modulo++
                }
                remainder = (remainder + 1) % modulo
                renderer.draw()
            }
            window.requestAnimationFrame(tsMs -> tick.call(tsMs))
        }
        tick.call(0)
    }

    def togglePixel(r: Int, c: Int) {
        renderer.setPixel(r, c, 1.0 - renderer.getPixel(r, c))
    }

    def togglePixelGroup(m: Int, i: Int) {
        for r = 0; r < nrows; r++ {
            for c = 0; c < ncols; c++ {
                if (r + c) % m == i {
                    togglePixel(r, c)
                }
            }
        }
    }
}
