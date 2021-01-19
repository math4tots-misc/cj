package cj

native class Range {
    def of(start: Int, end: Int): Iterator[Int]
    def inclusive(start: Int, end: Int): Iterator[Int]
    def upto(end: Int): Iterator[Int]
    def withStep(start: Int, end: Int, step: Int): Iterator[Int]
}
