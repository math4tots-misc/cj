package cjx.js


@implicit(Any, _fromAny)
native class JSObject : Repr, ToBool {
    @variadic def new(self, args: List[JSObject]): JSObject
    def new1(self, args: List[JSObject]): JSObject
    def field(self: Self, key: String): JSObject
    @generic def setField[T](self: Self, key: String, value: T)
    @variadic def call(self: Self, methodName: String, args: List[JSObject]): JSObject
    def call1(self: Self, methodName: String, args: List[JSObject]): JSObject
    @generic def _fromAny[T?](t: T): Self
    def instanceof(self: Self, cls: JSObject): Bool

    ## Returns t as R, as long as (t instanceof cls)
    ##
    ## NOTE: this method is unsafe in the sense that if cls does not ensure
    ## that t is actually R, this method might succeed and return an invalid value.
    ##
    @generic def _jsCast[T?, R?](t: T, cls: JSObject): R

    @generic def _jsCastNullable[T?, R](t: T, cls: JSObject): Nullable[R]

    @generic def unsafeCast[T?](self: Self): T

    def repr(self: Self): String

    def isString(self: Self): Bool

    ## returns self if self is a string. Throws otherwise
    def toString(self: Self): String

    def isInt(self: Self): Int

    ## returns self if self is a number (doubles are truncated). Throws otherwise
    def toInt(self: Self): Int

    def isDouble(self: Self): Double

    ## return self if self is a number. Throws otherwise
    def toDouble(self: Self): Double

    def toBool(self): Bool
}
