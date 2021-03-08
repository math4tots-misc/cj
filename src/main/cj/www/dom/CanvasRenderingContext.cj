package www.dom

import www.dom.HTMLCanvasElement
import www.JSWrapper

trait CanvasRenderingContext : JSWrapper {
    def _getFromCanvas(canvas: HTMLCanvasElement): Self
}
