package cjx.chip8.main

import cjx.js.web.HTMLStyleElement
import cjx.chip8.Chip8
import cjx.js.web.HTMLCanvasElement
import cjx.js.web.Document

class Demo {
    def main() {
        IO.println("START")
        val document = Document.get()

        val canvas: HTMLCanvasElement = document.createElement()
        document.body.appendChild(canvas)

        val style: HTMLStyleElement = document.createElement()
        style.innerText = (
            "canvas { border-style: solid; position: absolute; "
            + "top: 50%; left: 50%; transform: translate(-50%, -50%); }")
        document.body.appendChild(style)

        val chip8 = Chip8(canvas)
        chip8.init()
    }
}
