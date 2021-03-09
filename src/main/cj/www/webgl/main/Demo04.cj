package www.webgl.main

import cjx.bmp.Color
import www.webgl.WebGLColorGridRenderer
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

class Demo04 {
    static var modulo = 5
    static var remainder = 0
    static val nrows = 45
    static val ncols = 60
    static val window: Window = Window.get()
    static val document: Document = Document.get()
    static val canvas: HTMLCanvasElement = document.getElementBydId("canvas")
    static val renderer: WebGLColorGridRenderer = WebGLColorGridRenderer(canvas, nrows, ncols)

    def main() {
        # Don't make initial state pitch black -- set all colors to be grey
        renderer.setAllPixels((0.2, 0.4, 0.2))

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

    def togglePixelGroup(m: Int, i: Int) {
        updatePixelGroup(m, i, color -> color.invert())
    }

    def updatePixelGroup(m: Int, i: Int, f: Fn[Color, Color]) {
        for r = 0; r < nrows; r++ {
            for c = 0; c < ncols; c++ {
                if (r + c) % m == i {
                    renderer.setPixel(r, c, f.call(renderer.getPixel(r, c)))
                }
            }
        }
    }
}
