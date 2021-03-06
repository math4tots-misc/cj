package cjx.emu.chip8.main

import cjx.js.web.HTMLStyleElement
import cjx.js.web.HTMLInputElement
import cj.Time
import cjx.emu.chip8.C8Renderer
import cjx.js.web.CanvasRenderingContext2D
import cjx.js.web.HTMLCanvasElement
import cjx.js.web.Window
import cjx.js.web.Document

class RendererDemo {
    static val window: Window = Window.get()
    static val document: Document = Document.get()
    static val canvas: HTMLCanvasElement = document.createElement()
    static val renderer: C8Renderer = C8Renderer(6, canvas)
    static var lastToggleTime: Double = Time.now()
    static var remainder = 0
    static val moduloInputElement: HTMLInputElement = {
        val el: HTMLInputElement = document.createElement()
        el.value = "5"
        el
    }

    def main() {
        document.body.appendChild(canvas)
        document.body.appendChild(moduloInputElement)

        val style: HTMLStyleElement = document.createElement()
        style.innerText = (
            "canvas { border-style: solid; position: absolute; " +
            "top: 50%; left: 50%; transform: translate(-50%, -50%); }")
        document.body.appendChild(style)

        togglePixels(2, 0)
        animate()
    }

    def togglePixels(modulo: Int, parity: Int) {
        for y = 0; y < C8Renderer.rows; y++ {
            for x = 0; x < C8Renderer.cols; x++ {
                if (x + y) % modulo == parity {
                    renderer.togglePixel(x, y)
                }
            }
        }
    }

    def animate() {
        window.requestAnimationFrame(ts -> animate())
        val now = Time.now()
        if now - lastToggleTime > 0.5 {
            val modulo = Int(moduloInputElement.value)
            togglePixels(modulo, remainder)
            if modulo < 9 {
                moduloInputElement.value = (modulo + 1).toString()
            }
            remainder = (remainder + 1) % modulo
            lastToggleTime = now
        }
        renderer.render()
    }
}
