package cjx.chip8

trait C8Renderer {
    def __get_cols(): Int = 64
    def __get_rows(): Int = 32

    def __get__pixels(self): List[Int]
    def __set__pixels(self, pixels: List[Int])

    def togglePixel(self, var x: Int, var y: Int) = {
        if x >= cols { x -= cols } else if x < 0 { x += cols }
        if y >= rows { y -= rows } else if y < 0 { y += rows }
        val pos = x + y * cols
        val before = _pixels[pos]
        _pixels[pos] = _pixels[pos] ^ 1
    }

    def clear(self) {
        _pixels = [0] * cols * rows
    }

    def render(self)
}
