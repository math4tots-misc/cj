package cjx.chip8

import cjx.chip8.C8Renderer

@implicit(C8Renderer, _fromC8Renderer)
class C8Renderer_ : C8Renderer {
    static def _fromC8Renderer[R: C8Renderer](r: R): Self = Self(
        () -> r._pixels, pixels -> { r._pixels = pixels}, () -> r.render())

    val _getPixels: Fn[List[Int]]
    val _setPixels: Fn[List[Int], Unit]
    val _render: Fn[Unit]
    def __get__pixels(self): List[Int] = _getPixels.call()
    def __set__pixels(self, pixels: List[Int]) = _setPixels.call(pixels)
    def render(self) = _render.call()
}
