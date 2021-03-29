package www

import cj.Error


@implicit(Any, _fromAny)
native class JSObject : Repr, ToBool {
    @variadic def new(self, args: List[JSObject]): JSObject = js!(Self, "new ", self, "(...", args, ")")
    def new1(self, args: List[JSObject]): JSObject = js!(Self, "new ", self, "(...", args, ")")
    def field(self: Self, key: String): JSObject = js!(Self, self, "[", key, "]")
    @generic def setField[T](self: Self, key: String, value: T) = js!(Self, self, "[", key, "]=", value)
    @variadic def call(self: Self, methodName: String, args: List[JSObject]): JSObject = js!(
        JSObject, self, "[", methodName, "](...", args, ")")
    def call1(self: Self, methodName: String, args: List[JSObject]): JSObject = js!(
        JSObject, self, "[", methodName, "](...", args, ")")
    @generic def _fromAny[T?](t: T): Self = js!(Self, t)

    ## Returns t as R, as long as (t instanceof cls)
    ##
    ## NOTE: this method is unsafe in the sense that if cls does not ensure
    ## that t is actually R, this method might succeed and return an invalid value.
    ##
    @generic def _jsCast[T?, R?](t: T, cls: JSObject): R {
        if not js!(Bool, t, " instanceof ", cls) {
            throw Error("Expected " + js!(String, cls, ".name"))
        }
        js!(R, t)
    }

    @generic def unsafeCast[T?](self: Self): T = js!(T, self)

    def repr(self: Self): String = js!(String, "JSON.stringify(", self, ")")

    def isString(self: Self): Bool = js!(Bool, "typeof ", self, "==='string'")

    ## returns self if self is a string. Throws otherwise
    def toString(self: Self): String {
        if isString() {
            js!(String, self)
        } else {
            throw Error("JSObject.toString on non-string (" + self + ")")
        }
    }

    def isInt(self: Self): Bool = isDouble() and js!(Bool, self, "|0===", self)

    ## returns self if self is a number (doubles are truncated). Throws otherwise
    def toInt(self: Self): Int {
        if isDouble() {
            js!(Int, self, "|0")
        } else {
            throw Error("JSObject.toInt on non-number (" + self + ")")
        }
    }

    def isDouble(self: Self): Bool = js!(Bool, "typeof ", self, "==='number'")

    ## return self if self is a number. Throws otherwise
    def toDouble(self: Self): Double {
        if isDouble() {
            js!(Int, self)
        } else {
            throw Error("JSObject.toDouble on non-number (" + self + ")")
        }
    }

    def toBool(self): Bool = js!(Bool, "!!", self)
}
