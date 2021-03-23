package cj

import cj.Error
import cj.Int16Array
import cj.Float64Array
import cj.Float32Array

@implicit(Unit, _fromUnit)
@implicit(Bool, _unsafeCast)
@implicit(Int, _unsafeCast)
@implicit(Double, _unsafeCast)
@implicit(String, _unsafeCast)
@implicit(List, _fromList)
@implicit(Map, _fromMap)
@nullable
native class JSON : Repr, Eq {

    union Type {
        case number # 0
        case string # 1
        case bool # 2
        case nil # 3 (aka null)
        case array # 4
        case object # 5
    }

    def(self: JSON): JSON = self

    def parse(string: String): JSON = js!(Self, "JSON.parse(", string, ")")

    @generic def _unsafeCast[T](x: T): JSON = js!(Self, x)

    def _fromUnit(unit: Unit): JSON = js!(Self, "null")
    def _fromList(list: List[JSON]): JSON = js!(Self, list)
    def _fromMap(map: Map[String, JSON]): JSON {
        val obj = js!(JSON, "Object.create(null)")
        for (k, v) in map.pairs() {
            js!(Unit, obj, "[", k, "]=", v)
        }
        obj
    }

    def __getitem(self: Self, key: Self): Self = js!(Self, self, "[", key, "]")
    def __setitem(self: Self, key: Self, value: Self) = js!(
        Self, self, "[", key, "]=", value)
    def repr(self: Self): String = js!(String, "JSON.stringify(", self, ")")
    def type(self: Self): Type = switch js!(String, "typeof ", self) {
        case "number" = Type.number
        case "string" = Type.string
        case "boolean" = Type.bool
        case "object" {
            if js!(Bool, self, "===null") {
                Type.nil
            } else if js!(Bool, "Array.isArray(", self, ")") {
                Type.array
            } else {
                Type.object
            }
        }
        case "undefined" = Type.nil
        else = Type.object
    }

    def __eq(self: Self, other: Self): Bool = {
        self is other or switch js!(String, "typeof ", self) {
            case "number"; case "string"; case "boolean" = false
            case "object" {
                js!(Bool, self, "!==null") and ((
                    js!(Bool, "Array.isArray(", self, ")") and
                    js!(Bool, "Array.isArray(", other, ")") and
                    js!(Bool, self, ".length===", other, ".length") and {
                        val len = js!(Int, self, ".length")
                        for i = 0; i < len; i++ {
                            if js!(Self, self, "[", i, "]") != js!(Self, other, "[", i, "]") {
                                return false
                            }
                        }
                        true
                    }
                ) or {
                    val keys = js!(List[String], "Object.keys(", self, ").sort()")
                    val otherKeys = js!(List[String], "Object.keys(", other, ").sort()")
                    if keys.size() != otherKeys.size() { return false }
                    val len = keys.size()
                    for i = 0; i < len; i++ {
                        if keys[i] != otherKeys[i] {
                            return false
                        }
                    }
                    for i = 0; i < len; i++ {
                        val key = keys[i]
                        if self[key] != other[key] {
                            return false
                        }
                    }
                    true
                })
            }
            else = false
        }
    }

    def isNull(self: Self): Bool = js!(Bool, self, "===null")
    def isBool(self: Self): Bool = js!(Bool, "typeof ", self, "==='boolean'")
    def getBool(self: Self): Bool {
        if not isBool() { throw Error("JSON.getBool on non-Bool (" + self + ")") }
        js!(Bool, self)
    }
    def isNumber(self: Self): Bool = js!(Bool, "typeof ", self, "==='number'")
    def getInt(self: Self): Int {
        if not isNumber() { throw Error("JSON.getInt on non-number") }
        js!(Int, self, "|0")
    }
    def getDouble(self: Self): Double {
        if not isNumber() { throw Error("JSON.getDouble on non-number") }
        js!(Double, self)
    }
    def isString(self: Self): Bool = js!(Bool, "typeof ", self, "==='string'")
    def getString(self: Self): String {
        if not isString() { throw Error("JSON.getString on non-number") }
        js!(String, self)
    }
    def isList(self: Self): Bool = js!(Bool, "Array.isArray(", self, ")")
    def isObject(self: Self): Bool = js!(
        Bool, "typeof ", self, "==='object'&&!Array.isArray(", self, ")")

    def toFloat32Array(self): Float32Array = js!(Float32Array, "Float32Array.from(", self, ")")
    def toFloat64Array(self): Float64Array = js!(Float64Array, "Float64Array.from(", self, ")")
    def toInt16Array(self): Int16Array = js!(Int16Array, "Int16Array.from(", self, ")")
}
