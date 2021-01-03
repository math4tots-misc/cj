package sample

import cj.IO

class Main {
    def main() = {
        IO.println[String]("Hello world!")

        IO.println[Int](Int.__add(4, 17))

        {
            val x = 12
            IO.println[Int](x)
        }
    }
}
