package cjx.js.web

import cjx.js.web.HTMLCanvasElement
import www.JSWrapper

trait CanvasRenderingContext : JSWrapper {
    def _getFromCanvas(canvas: HTMLCanvasElement): Self
}
