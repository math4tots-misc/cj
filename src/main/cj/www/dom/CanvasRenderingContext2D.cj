package www.dom

import www.dom.CanvasImageSource
import www.dom.ImageData
import www.dom.CanvasRenderingContext
import www.dom.HTMLCanvasElement
import www.JSObject
import www.JSWrapper

class CanvasRenderingContext2D : CanvasRenderingContext {
    def _getFromCanvas(canvas: HTMLCanvasElement): Self = canvas.getContext2D()

    val _obj :  JSObject
    def cls() : JSObject = js!(JSObject, "CanvasRenderingContext2D")

    def __get_canvas(self): HTMLCanvasElement? = js0!(self, ".canvas")

    def __get_lineWidth(self: Self): Double = js0!(self, ".lineWidth")
    def __set_lineWidth(self: Self, value: Double) =  js0!(self, ".lineWidth=", value)

    def __get_fillStyle(self: Self): String = js0!(self, ".fillStyle")
    def __set_fillStyle(self: Self, style: String) =  js0!(self, ".fillStyle=", style)

    def fillRect(self: Self, x: Double, y: Double, width: Double, height: Double) = (
        jsm0!(self, "fillRect", x, y, width, height))

    def strokeRect(self: Self, x: Double, y: Double, width: Double, height: Double) = (
        jsm0!(self, "strokeRect", x, y, width, height))

    def clearRect(self: Self, x: Double, y: Double, width: Double, height: Double) = (
        jsm0!(self, "clearRect", x, y, width, height))

    def beginPath(self: Self) = jsm0!(self, "beginPath")
    def closePath(self: Self) = jsm0!(self, "closePath")
    def stroke(self: Self) = jsm0!(self, "stroke")
    def moveTo(self: Self, x: Double, y: Double) = jsm0!(self, "moveTo", x, y)
    def lineTo(self: Self, x: Double, y: Double) = jsm0!(self, "lineTo", x, y)

    def drawImage[S: CanvasImageSource](self, src: S, dx: Double, dy: Double) {
        jsm0!(self, "drawImage", src, dx, dy)
    }

    def getImageData(self, sx: Double, sy: Double, sw: Double, sh: Double): ImageData {
        jsm0!(self, "getImageData", sx, sy, sw, sh)
    }

    def putImageData(self, data: ImageData, dx: Double, dy: Double) {
        jsm0!(self, "putImageData", data, dx, dy)
    }
}
