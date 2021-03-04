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
        val speedLabel: HTMLDivElement = document.createElement()
        val speedInput: HTMLInputElement = document.createElement()
        speedInput.value = "10"
        speedLabel.innerText = "speed"
        document.body.appendChild(speedDiv)
        speedDiv.appendChild(speedLabel)
        speedDiv.appendChild(speedInput)
        speedInput.onchange(event -> {
            chip8.cpu.speed = Int(speedInput.value)
        })

        chip8.init()
    }
}
