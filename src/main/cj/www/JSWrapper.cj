package www

import www.JSObject

@implicit(JSObject, _fromAny)
trait JSWrapper {
    def __get__obj(self: Self): JSObject
    def __malloc(obj: JSObject): Self

    def cls(): JSObject

    def _fromAny[T?](t: T): Self = JSObject._jsCast(t, Self.cls())

    @variadic def new(self: Self, args: List[JSObject]) = self._obj.new1(args)
    def field(self: Self, key: String): JSObject = self._obj.field(key)
    def setField[T](self: Self, key: String, value: T) = self._obj.setField(key, value)
    @variadic def call(self: Self, methodName: String, args: List[JSObject]): JSObject = (
        self._obj.call1(methodName, args))
}
