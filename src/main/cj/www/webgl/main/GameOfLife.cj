package www.webgl.main

import www.dom.HTMLInputElement
import www.dom.DOMUtil
import cj.Math
import www.dom.HTMLButtonElement
import cj.Uint8Array
import www.dom.Window
import www.webgl.WebGLGridRenderer
import www.dom.Document
import www.dom.HTMLCanvasElement

class GameOfLife {
    def __get_window(): Window = Window.get()
    def __get_document(): Document = Document.get()
    static val onColor = 0.8
    static val offColor = 0.2
    static val nrows = 45
    static val ncols = 60
    static val canvas: HTMLCanvasElement = document.getElementById("canvas")
    static val renderer: WebGLGridRenderer = WebGLGridRenderer(canvas, nrows, ncols)
    static var running = true
    static var lastUpdate = 0.0
    static var speed = 20.0
    static var randomizeLiveRate = 0.2

    def main() {
        canvas.onclick(event -> {
            val (x, y) = canvas.getCoordinatesFromMouseEvent(event)
            val (r, c) = xy2rc(x, y)
            renderer.togglePixel(r, c)
        })

        document.body.appendChild(DOMUtil.button("STEP", e -> step()))
        document.body.appendChild(DOMUtil.button("RANDOMIZE", e -> randomize()))
        document.body.appendChild(DOMUtil.button("CLEAR", e -> clear()))
        document.body.appendChild(DOMUtil.div(
            DOMUtil.text("running?"),
            DOMUtil.checkbox(running, (ev, checked) -> { running = checked })))
        document.body.appendChild(DOMUtil.div(
            DOMUtil.text("speed (Hz):"),
            DOMUtil.textinput("" + speed, (ev, text) -> {
                if text { speed = Double(text) }
                if speed <= 0.0 { speed = 2.0 }
            })))
        document.body.appendChild(DOMUtil.div(
            DOMUtil.text("random-live ratio"),
            DOMUtil.textinput("" + randomizeLiveRate, (ev, text) -> {
                if text { randomizeLiveRate = Double(text) }
            })
        ))

        initWithGlider()
        window.requestAnimationFrame(ts -> tick(ts))
    }

    def tick(ts: Double) {
        if running and ts / 1000 - lastUpdate > 1 / speed {
            step()
            lastUpdate = ts / 1000
        }
        renderer.draw()
        window.requestAnimationFrame(ts -> tick(ts))
    }

    ## Converts (x, y) coordinates to (row, col)
    def xy2rc(x: Double, y: Double): Tuple[Int, Int] {
        val cellWidth = canvas.width / ncols
        val cellHeight = canvas.height / nrows
        val r = y // cellHeight
        val c = x // cellWidth
        (r, c)
    }

    def randomize() {
        for r = 0; r < nrows; r++ {
            for c = 0; c < ncols; c++ {
                val pixel = if Math.random() < randomizeLiveRate { onColor } else { offColor }
                renderer.setPixel(r, c, pixel)
            }
        }
    }

    def initWithGlider() {
        clear()
        val positions = [
            (5, 5),
            (20, 10),
            (31, 7),
            (20, 40),
            (27, 50),
        ]
        for (r, c) in positions {
            setGliderAt(r, c)
        }
    }

    def setGliderAt(r: Int, c: Int) {
        val positions = [
            (r + 1, c    ),
            (r + 2, c + 1),
            (r + 2, c + 2),
            (r + 1, c + 2),
            (r    , c + 2),
        ]
        for (cellR, cellC) in positions {
            renderer.setPixel(cellR, cellC, onColor)
        }
    }

    def clear() {
        renderer.setAllPixels(offColor)
    }

    def step() {
        val old = Uint8Array.withSize(nrows * ncols)
        val new = Uint8Array.withSize(nrows * ncols)
        for r = 0; r < nrows; r++ {
            for c = 0; c < ncols; c++ {
                if renderer.getPixel(r, c) > 0.5 {
                    old[r * ncols + c] = 1
                }
            }
        }
        for r = 0; r < nrows; r++ {
            for c = 0; c < ncols; c++ {
                var neighborCount = 0
                for dr = -1; dr <= 1; dr++ {
                    for dc = -1; dc <= 1; dc++ {
                        var nr = r + dr
                        var nc = c + dc
                        if nr < 0 { nr += nrows }
                        if nc < 0 { nc += ncols }
                        if nr >= nrows { nr -= nrows }
                        if nc >= ncols { nc -= ncols }
                        if (dr, dc) != (0, 0) {
                            neighborCount += old[nr * ncols + nc]
                        }
                    }
                }
                new[r * ncols + c] = switch neighborCount {
                    case 2 = old[r * ncols + c]
                    case 3 = 1
                    else = 0
                }
            }
        }
        for r = 0; r < nrows; r++ {
            for c = 0; c < ncols; c++ {
                renderer.setPixel(r, c, if new[r * ncols + c] { onColor } else { offColor })
            }
        }
    }
}
