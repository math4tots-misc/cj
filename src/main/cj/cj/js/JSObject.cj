package cj.js

import cj.FromAny

native class JSObject : FromAny {
    def field(self: Self, key: String): JSObject
    @generic def setField[T](self: Self, key: String, value: T)
    @variadic def call(self: Self, methodName: String, args: List[JSObject]): JSObject
    def call1(self: Self, methodName: String, args: List[JSObject]): JSObject
    @generic def fromAny[T](t: T): Self
    def instanceof(self: Self, cls: JSObject): Bool

    ## Returns t as R, as long as (t instanceof cls)
    ##
    ## NOTE: this method is unsafe in the sense that if cls does not ensure
    ## that t is actually R, this method might succeed and return an invalid value.
    ##
    @generic def _jsCast[T?, R?](t: T, cls: JSObject): R

    @generic def unsafeCast[T?](self: Self): T
}
