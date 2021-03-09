package cjx.bmp

@implicit(Tuple3, _fromRGB)
@implicit(Tuple4, _fromRGBA)
@derive(hash)
class Color : Repr {
    val r : Double
    val g : Double
    val b : Double
    val a : Double

    def invert(self): Self = (1.0 - r, 1.0 - g, 1.0 - b, a)

    private def _floatToIntChannel(x: Double): Int = {
        val i = (x * 256).toInt()
        if i < 0 { 0 } else if i > 255 { 255 } else { i }
    }

    private def _intToFloatChannel(x: Int): Double = if x < 0 { 0 } else if x >= 255 { 1.0 } else {
        x.toDouble() / 256
    }

    private def _fromRGB(rgb: Tuple[Double, Double, Double]): Self = (
        Self.__malloc(rgb.get0(), rgb.get1(), rgb.get2(), 1))

    private def _fromRGBA(rgba: Tuple[Double, Double, Double, Double]): Self = (
        Self.__malloc(rgba.get0(), rgba.get1(), rgba.get2(), rgba.get3()))

    def fromI32RGBA(rgba: Int): Self = {
        val (ri, gi, bi, ai) = _split(rgba)
        Self.__malloc(
            _intToFloatChannel(ri),
            _intToFloatChannel(gi),
            _intToFloatChannel(bi),
            _intToFloatChannel(ai))
    }

    private def _split(x: Int): Tuple[Int, Int, Int, Int] = (
        (x >>> 24) & 0xFF, (x >>> 16) & 0xFF, (x >>> 8) & 0xFF, x & 0xFF)

    private def _combine(a: Int, b: Int, c: Int, d: Int): Int = (
        (a << 24) | (b << 16) | (c << 8) | d)

    private def _combineFloats(a: Double, b: Double, c: Double, d: Double): Int = _combine(
        _floatToIntChannel(a),
        _floatToIntChannel(b),
        _floatToIntChannel(c),
        _floatToIntChannel(d))

    def toI32RGBA(self: Self): Int = _combineFloats(r, g, b, a)
    def toI32ARGB(self: Self): Int = _combineFloats(a, r, g, b)

    def repr(self: Self): String = "Color(" + r + ", " + g + ", " + b + ", " + a + ")"
}
