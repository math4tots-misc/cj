package cj

native class Math {
    # -- some constants --
    def __get_e(): Double
    def __get_pi(): Double
    def __get_tau(): Double
    def __get_infinity(): Double

    def combineHash(h1: Int, h2: Int): Int

    ## Returns a random number between 0 and 1
    ## (inclusive of 0, but not 1)
    def random(): Double

    def floor(x: Double): Int
    def ceil(x: Double): Int

    # -- trig functions (all in radians unless otherwise specified) --
    def sin(rad: Double): Double
    def cos(rad: Double): Double
    def tan(rad: Double): Double
    def asin(r: Double): Double
    def acos(r: Double): Double
    def atan(r: Double): Double
    def atan2(y: Double, x: Double): Double

    def min[X: Ord](a: X, b: X): X
    def max[X: Ord](a: X, b: X): X
}
