package cj.js

import cj.js.JSObject

@implicit(JSWrapper, _fromAny)
@implicit(JSObject, _fromAny)
trait JSWrapper {
    def cls(): JSObject
    def obj(self: Self): JSObject

    def _fromAny[T?](t: T): Self = JSObject._jsCast(t, Self.cls())

    def field(self: Self, key: String): JSObject = self.obj().field(key)
    def setField[T](self: Self, key: String, value: T) = self.obj().setField(key, value)
    @variadic def call(self: Self, methodName: String, args: List[JSObject]): JSObject = (
        self.obj().call1(methodName, args))
}
