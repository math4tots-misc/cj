package cj

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

    def new(self: JSON): JSON

    def parse(string: String): JSON

    @generic def _unsafeCast[T](x: T): JSON
    def _fromUnit(unit: Unit): JSON
    def _fromList(list: List[JSON]): JSON
    def _fromMap(map: Map[String, JSON]): JSON

    @variadic def object(pairs: List[Tuple[String, JSON]]): JSON

    def __getitem(self: Self, key: Self): Self
    def __setitem(self: Self, key: Self, value: Self)
    def repr(self: Self): String
    def type(self: Self): Type

    def __eq(self: Self, other: Self): Bool

    def isNull(self: Self): Bool
    def isBool(self: Self): Bool
    def getBool(self: Self): Bool
    def isNumber(self: Self): Bool
    def getInt(self: Self): Int
    def getDouble(self: Self): Double
    def isString(self: Self): Bool
    def getString(self: Self): String
    def isList(self: Self): Bool
    def isObject(self: Self): Bool

    def toFloat32Array(self): Float32Array
    def toFloat64Array(self): Float64Array
}
