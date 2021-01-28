package sample.net

import cj.Argv
import cj.net.HTTP

class Download {
    def main() = amain().done()

    async def amain(): Promise[Unit] {
        val out = HTTP.get(Argv()[0]).await
        IO.println(out)
    }
}
