package www.webgl.main

import www.webgl.WebGLGridRenderer
import www.dom.Window
import www.dom.WebGLUniformLocation
import www.dom.WebGLProgram
import www.dom.WebGLVertexArrayObject
import cj.Float32Array
import www.dom.WebGLBuffer
import www.dom.WebGL2RenderingContext
import www.dom.Document
import www.dom.HTMLCanvasElement
import www.webgl.WebGLHelper

class Demo03 {
    static var modulo = 5
    static var remainder = 0
    static val nrows = 45
    static val ncols = 60
    static val window: Window = Window.get()
    static val document: Document = Document.get()
    static val canvas: HTMLCanvasElement = document.getElementById("canvas")
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
