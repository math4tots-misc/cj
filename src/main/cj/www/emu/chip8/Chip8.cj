package www.emu.chip8

import cj.AIO
import cj.Uint8Array
import cj.net.HTTP
import www.emu.chip8.C8CPU
import www.emu.chip8.C8Speaker
import www.emu.chip8.C8Keyboard
import cjx.js.web.HTMLCanvasElement
import cj.Time
import cjx.js.web.Window
import www.emu.chip8.C8Renderer

class Chip8 {
    static val window: Window = Window.get()
    static val fpsInterval: Double = 1.0 / 60.0
    val renderer: C8Renderer
    val keyboard: C8Keyboard
    val speaker: C8Speaker
    val cpu: C8CPU
    var then: Double = 0
    var running = false

    def(canvas: HTMLCanvasElement): Self {
        val renderer = C8Renderer(10, canvas)
        val keyboard = C8Keyboard()
        val speaker = C8Speaker()
        val cpu = C8CPU(renderer, keyboard, speaker)
        __malloc(renderer, keyboard, speaker, cpu)
    }

    def runRom(self, romName: String): Promise[Unit] {
        IO.println("loading rom " + romName)
        running = false
        HTTP.getUint8Array("roms/" + romName).map(program ->
            runProgram(program))
    }

    def runProgram(self, program: Uint8Array): Bool {
        if not running {
            IO.println("starting program")
            then = Time.now()
            renderer.clear()
            cpu.reset()
            cpu.loadSpritesIntoMemory()
            cpu.loadProgramIntoMemory(program)
            running = true
            step()
            true
        } else { false }
    }

    def stop(self) { running = false }

    def stopAndRunNewProgram(self, program: Uint8Array) {
        running = false
        AIO.wait(0.01).then(u -> runProgram(program)).done()
    }

    private def step(self) {
        val now = Time.now()
        if now - then > fpsInterval {
            then = now
            cpu.cycle()
            renderer.render()
        }
        if running { window.requestAnimationFrame(ts -> step()) }
    }
}
