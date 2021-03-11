package www.dom

import www.dom.MouseEvent
import www.dom.CanvasRenderingContext
import www.dom.WebGL2RenderingContext
import www.dom.CanvasRenderingContext2D
import www.JSObject
import www.dom.HTMLElement

class HTMLCanvasElement : HTMLElement {
    static val tagName = "canvas"
    val _obj :  JSObject
    def cls() : JSObject = js!(JSObject, "HTMLCanvasElement")

    def __get_width(self: Self): Int = self.field("width").unsafeCast()
    def __set_width(self: Self, value: Int) = self.setField("width", value)
    def __get_height(self: Self): Int = self.field("height").unsafeCast()
    def __set_height(self: Self, value: Int) = self.setField("height", value)

    def getContext[C: CanvasRenderingContext](self): C = C._getFromCanvas(self)

    def getContext2D(self: Self): CanvasRenderingContext2D = (
        self.call("getContext", "2d").unsafeCast())

    def getContextWebGL(self: Self): WebGL2RenderingContext = (
        self.call("getContext", "webgl2").unsafeCast())

    ## Given a mouse event, get the adjusted (x, y) coordinates into its content
    def getCoordinatesFromMouseEvent(self, event: MouseEvent): Tuple[Double, Double] {
        val borderWidth = (clientWidth - offsetWidth) / 2
        val borderHeight = (clientWidth - offsetWidth) / 2
        val rect = getBoundingClientRect()
        val x = event.clientX + borderWidth - rect.left
        val y = event.clientY + borderHeight - rect.top
        (x, y)
    }
}
