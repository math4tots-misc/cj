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

    def __get_width(self): Int = js0!(self, ".width")
    def __set_width(self, value: Int) =  js0!(self, ".width=", value)
    def __get_height(self): Int = js0!(self, ".height")
    def __set_height(self, value: Int) =  js0!(self, ".height=", value)

    def getContext[C: CanvasRenderingContext](self): C = C._getFromCanvas(self)

    def getContext2D(self): CanvasRenderingContext2D = js0!(self, ".getContext(\"2d\")")

    def getContextWebGL(self): WebGL2RenderingContext = js0!(self, ".getContext(\"webgl2\")")

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
