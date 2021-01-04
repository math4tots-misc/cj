package sample

import cj.IO

class Main {
    def main() = {
        IO.println("Hello world!")

        IO.println(Int.__add(4, 17))
        IO.println((4).__add(71))

        {
            val x = 12
            IO.println(x)
        }
    }
}
