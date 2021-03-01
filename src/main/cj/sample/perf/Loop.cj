package sample.perf

class Loop {

    def main() {
        var total = 0
        val limit = (10 ** 8).toInt()
        for i = 0; i < limit; i++ {
            total += i
        }
        IO.println("total = " + total)
    }
}
