package sample.web

import www.dom.HTMLCanvasElement
import www.dom.Document

class Sample2 {
    def main() = {
        val document = Document.get()
        document.title = "Canvas demo"

        val canvas : HTMLCanvasElement = document.getElementBydId("canvas")
        val ctx = canvas.getContext2D()
        ctx.fillStyle = "green"
        ctx.fillRect(20, 10, 150, 100)

        ctx.lineWidth = 10

        # Wall
        ctx.strokeRect(75, 140, 150, 110)

        # Door
        ctx.fillRect(130, 190, 40, 60)

        # Roof
        ctx.beginPath()
        ctx.moveTo(50, 140)
        ctx.lineTo(150, 60)
        ctx.lineTo(250, 140)
        ctx.closePath()
        ctx.stroke()
    }
}
