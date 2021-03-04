package cjx.js.web

import cjx.js.web.HTMLCanvasElement
import cjx.js.JSWrapper

trait CanvasRenderingContext : JSWrapper {
    def _getFromCanvas(canvas: HTMLCanvasElement): Self
}
