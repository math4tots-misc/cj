package cj

## Special trait for class that can be converted from any value.
##
## For types that can be constructed from any value (e.g. JSObject)
##
trait FromAny {
    def fromAny[T?](t: T): Self
}
