package cjx.chip8.main

import cjx.js.web.HTMLInputElement
import cjx.js.web.HTMLDivElement
import cjx.js.web.HTMLButtonElement
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

        val soundButton: HTMLButtonElement = document.createElement()
        soundButton.innerText = "play sound"
        document.body.appendChild(soundButton)

        val chip8 = Chip8(canvas)

        var playing = false
        soundButton.onclick(event -> {
            if playing {
                chip8.speaker.stop()
                soundButton.innerText = "play sound"
            } else {
                chip8.speaker.play(0)
                soundButton.innerText = "stop sound"
            }
            playing = not playing
        })

        val speedDiv: HTMLDivElement = document.createElement()
        val speedInput: HTMLInputElement = document.createElement()
        val speedButton: HTMLButtonElement = document.createElement()
        speedInput.value = "10"
        speedButton.innerText = "update speed"
        document.body.appendChild(speedDiv)
        speedDiv.appendChild(speedInput)
        speedDiv.appendChild(speedButton)
        speedButton.onclick(event -> { chip8.cpu.speed = Int(speedInput.value) })

        val loaderDiv: HTMLDivElement = document.createElement()
        val loaderInput: HTMLInputElement = document.createElement()
        val loaderButton: HTMLButtonElement = document.createElement()
        loaderButton.innerText = "load ROM"
        document.body.appendChild(loaderDiv)
        loaderDiv.appendChild(loaderInput)
        loaderDiv.appendChild(loaderButton)
        loaderButton.onclick(event -> { chip8.runRom(loaderInput.value).done() })

        chip8.runRom("BLITZ").done()
    }
}
