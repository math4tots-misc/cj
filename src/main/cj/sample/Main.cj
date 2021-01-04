package sample

import sample.SampleUnion
import cj.IO

class Main {
    def main() = {
        IO.println("Hello world!")

        IO.println(Int.__add(4, 17))
        IO.println((4).__add(71))
        IO.println(4 + 71)

        {
            val x = 12
            IO.println(x)
        }

        {
            var x = SampleUnion.one(24)
            union x {
                case one(a) = IO.println("a: " + a)
                case two(a, b) = ()
                case three(s) = ()
            }
        }
    }
}
