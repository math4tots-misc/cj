package cjx.chip8

import cjx.chip8.C8Keyboard
import cjx.js.web.HTMLCanvasElement
import cj.Time
import cjx.js.web.Window
import cjx.chip8.C8Renderer

class Chip8 {
    static val window: Window = Window.get()
    static val fpsInterval: Double = 1.0 / 60.0
    val renderer: C8Renderer
    val keyboard: C8Keyboard = C8Keyboard()
    var then: Double = 0

    def(canvas: HTMLCanvasElement): Self = __malloc(
        C8Renderer(10, canvas.getContext()))

    def init(self) {
        then = Time.now()

        # Just to see something on the screen
        renderer.togglePixel(0, 0)
        renderer.togglePixel(5, 2)

        window.requestAnimationFrame(ts -> step())
    }

    def step(self) {
        val now = Time.now()
        if now - then > fpsInterval {
            # TODO: Cycle CPU
            then = now
            renderer.render()
        }
        window.requestAnimationFrame(ts -> step())
    }
}
