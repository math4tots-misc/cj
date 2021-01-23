package sample.web

import cj.js.web.HTMLCanvasElement
import cj.js.web.Document

class Sample2 {
    def main() = {
        val document = Document.get()
        document.title = "Canvas demo"

        val canvas : HTMLCanvasElement = document.getElementBydId("canvas")
        val ctx = canvas.getContext2D()
        ctx.fillStyle = "green"
        ctx.fillRect(20, 10, 150, 100)
    }
}
