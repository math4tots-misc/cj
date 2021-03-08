package cjx.books.webgl.main

import cj.Math
import www.dom.KeyboardEvent
import www.dom.WebGL2RenderingContext
import www.dom.Window
import www.dom.HTMLCanvasElement
import www.dom.Document

class Ch01s03 {
    def main() = {
        val window = Window.get()
        val document = Document.get()
        document.title = "WebGL2 demo"
        val canvas : HTMLCanvasElement = document.getElementBydId("canvas")
        val gl = canvas.getContextWebGL()
        window.onkeydown(event -> Self.checkKey(gl, event))
    }

    def updateClearColor(gl: WebGL2RenderingContext, r: Double, g: Double, b: Double, a: Double) = {
        gl.clearColor(r, g, b, a)
        gl.clear(gl.cCOLOR_BUFFER_BIT)
        gl.viewport(0, 0, 0, 0)
    }

    def checkKey(gl: WebGL2RenderingContext, event: KeyboardEvent) = {
        switch event.key {
            case "1" = updateClearColor(gl, 0.2, 0.8, 0.2, 1.0) # green
            case "2" = updateClearColor(gl, 0.2, 0.2, 0.8, 1.0) # blue
            case "3" = (
                # Random color
                updateClearColor(gl, Math.random(), Math.random(), Math.random(), 1.0))
            case "4" = {
                # Get color
                val color = gl.pCOLOR_CLEAR_VALUE
                Window.get().alert(
                    "clearColor = (" +
                    color[0].toFixed(1) + ", " +
                    color[1].toFixed(1) + ", " +
                    color[2].toFixed(1) + ")")
            }
            else = {
                IO.println("key = " + event.key)
            }
        }
    }
}
