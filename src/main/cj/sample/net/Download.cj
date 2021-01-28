package sample.net

import cj.Argv
import cj.net.Http

class Download {
    def main() = amain().done()

    async def amain(): Promise[Unit] {
        val out = Http.get(Argv()[0]).await
        IO.println(out)
    }
}
