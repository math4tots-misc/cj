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

## Toggle rgbs of each pixels in a stagger to get a variety of colors
class Demo05 {
    static val cycles: List[Tuple[Int, Int, Fn[Color, Color]]] = [
        (0, 5, color -> (1.0 - color.r, color.g, color.b)),
        (0, 7, color -> (color.r, 1.0 - color.g, color.b)),
        (0, 11, color -> (color.r, color.g, 1.0 - color.b)),
    ]
    static val nrows = 45
    static val ncols = 60
    static val window: Window = Window.get()
    static val document: Document = Document.get()
    static val canvas: HTMLCanvasElement = document.getElementBydId("canvas")
    static val renderer: WebGLColorGridRenderer = WebGLColorGridRenderer(canvas, nrows, ncols)

    def main() {
        # Don't make initial state pitch black -- set all colors to be grey
        renderer.setAllPixels((0.2, 0.2, 0.2))

        togglePixelGroup(3, 0)
        renderer.draw()

        var lastTimeStampMs = 0.0

        var tick: Fn[Double, Unit] = tsMs -> ()
        tick = tsMs -> {
            val elapsed = (tsMs - lastTimeStampMs) / 1000
            if elapsed > 0.5 {
                lastTimeStampMs = tsMs
                for i = 0; i < cycles.size(); i++ {
                    val (j, m, f) = cycles[i]
                    updatePixelGroup(m, j, f)
                    cycles[i] = ((j + 1) % m, m, f)
                }
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
