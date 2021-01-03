package sample

import cj.IO

class Main {
    def main() = {
        IO.println[String]("Hello world!")

        {
            val x = 12
            IO.println[Int](x)
        }
    }
}
