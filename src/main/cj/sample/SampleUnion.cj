package sample

union SampleUnion {
    static var sampleStaticField: Int = 10

    case one(Int)
    case two(Int, Int)
    case three(String)
}
