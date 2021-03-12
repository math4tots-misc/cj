package cj

native class Math {
    # -- some constants --
    def __get_e(): Double = js!(Double, "Math.E")
    def __get_pi(): Double = js!(Double, "Math.PI")
    def __get_tau(): Double = js!(Double, "2*Math.PI")
    def __get_infinity(): Double = js!(Double, "Infinity")

    def combineHash(h1: Int, h2: Int): Int = ((31 * h1) + h2)

    ## Returns a random number between 0 and 1
    ## (inclusive of 0, but not 1)
    def random(): Double = js!(Double, "Math.random()")

    def floor(x: Double): Int = js!(Int, "Math.floor(", x, ")")
    def ceil(x: Double): Int = js!(Int, "Math.ceil(", x, ")")

    # -- trig functions (all in radians unless otherwise specified) --
    def sin(rad: Double): Double = js!(Double, "Math.sin(", rad, ")")
    def cos(rad: Double): Double = js!(Double, "Math.cos(", rad, ")")
    def tan(rad: Double): Double = js!(Double, "Math.tan(", rad, ")")
    def asin(r: Double): Double = js!(Double, "Math.asin(", r, ")")
    def acos(r: Double): Double = js!(Double, "Math.acos(", r, ")")
    def atan(r: Double): Double = js!(Double, "Math.atan(", r, ")")
    def atan2(y: Double, x: Double): Double = js!(Double, "Math.atan2(", y, ",", x, ")")

    def min[X: Ord](a: X, b: X): X = if a < b { a } else { b }
    def max[X: Ord](a: X, b: X): X = if a < b { b } else { a }
}
