package cjx.chip8

import cjx.chip8.C8CPU
import cjx.chip8.C8Speaker
import cjx.chip8.C8Keyboard
import cjx.js.web.HTMLCanvasElement
import cj.Time
import cjx.js.web.Window
import cjx.chip8.C8Renderer

class Chip8 {
    static val window: Window = Window.get()
    static val fpsInterval: Double = 1.0 / 60.0
    val renderer: C8Renderer
    val keyboard: C8Keyboard
    val speaker: C8Speaker
    val cpu: C8CPU
    var then: Double = 0

    def(canvas: HTMLCanvasElement): Self = {
        val renderer = C8Renderer(10, canvas.getContext())
        val keyboard = C8Keyboard()
        val speaker = C8Speaker()
        val cpu = C8CPU(renderer, keyboard, speaker)
        __malloc(renderer, keyboard, speaker, cpu)
    }

    def init(self) {
        then = Time.now()

        # Just to see something on the screen
        # renderer.togglePixel(0, 0)
        # renderer.togglePixel(5, 2)

        cpu.loadSpritesIntoMemory()
        cpu.loadRom("BLITZ").then(u ->
            window.requestAnimationFrame(ts -> step())).done()
    }

    def step(self) {
        val now = Time.now()
        if now - then > fpsInterval {
            then = now
            cpu.cycle()
            renderer.render()
        }
        window.requestAnimationFrame(ts -> step())
    }
}
