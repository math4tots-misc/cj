package cj

## The untyped companion class to List[T]
native class List_ {
    @generic def empty[T?](): List[T]
    @generic def ofSize[T?](size: Int, f: Fn[Int, T]): List[T]
}
