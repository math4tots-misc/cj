package www.emu.chip8.main

import www.dom.HTMLOptionElement
import www.dom.HTMLSelectElement
import cj.Uint8Array
import www.JSObject
import www.dom.Window
import www.dom.HTMLInputElement
import www.dom.HTMLDivElement
import www.dom.HTMLButtonElement
import www.dom.HTMLStyleElement
import www.emu.chip8.Chip8
import www.dom.HTMLCanvasElement
import www.dom.Document

class Demo {
    def main() {
        js!(Unit, "nw.Window.get().showDevTools()")
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
        chip8.cpu.speed = 40
        speedInput.value = "" + chip8.cpu.speed
        speedButton.innerText = "update speed"
        document.body.appendChild(speedDiv)
        speedDiv.appendChild(speedInput)
        speedDiv.appendChild(speedButton)
        speedButton.onclick(event -> { chip8.cpu.speed = Int(speedInput.value) })

        val loaderDiv: HTMLDivElement = document.createElement()
        val loaderSelect: HTMLSelectElement = document.createElement()
        val loaderButton: HTMLButtonElement = document.createElement()
        loaderButton.innerText = "load ROM"
        for name in listdir!("../roms").sorted() {
            val optionElement: HTMLOptionElement = document.createElement()
            optionElement.value = name
            optionElement.innerText = name
            loaderSelect.appendChild(optionElement)
        }
        document.body.appendChild(loaderDiv)
        loaderDiv.appendChild(loaderSelect)
        loaderDiv.appendChild(loaderButton)
        loaderButton.onclick(event -> { chip8.runRom(loaderSelect.value).done() })

        val dropDiv: HTMLDivElement = document.createElement()
        dropDiv.innerText = "Drag and drop ROM files here"
        dropDiv.style.width = "100px"
        dropDiv.style.height = "60px"
        dropDiv.style.padding = "20px 0"
        dropDiv.style.borderStyle = "solid"
        dropDiv.style.textAlign = "center"
        dropDiv.style.fontWeight = "bold"
        document.body.appendChild(dropDiv)

        # NOTE: despite the drop div box,
        # we allow dropping the file anywhere within the page
        Window.get().ondrop(event -> {
            event.preventDefault()
            val dataTransfer = event.field("dataTransfer")
            val files = dataTransfer.field("files")
            if files.field("length").unsafeCast[Int]() > 0 {
                val file = files.call("item", 0)
                val callback: Fn[JSObject, Unit] = arraybuf -> {
                    val program: Uint8Array = Window.get().field(
                        "Uint8Array").new(arraybuf).unsafeCast()
                    chip8.stopAndRunNewProgram(program)
                }
                file.call("arrayBuffer").call("then", callback)
            }
            IO.println("drop event~")
        })
        Window.get().ondragover(event -> event.preventDefault())

        chip8.runRom("BLITZ").done()
    }
}
