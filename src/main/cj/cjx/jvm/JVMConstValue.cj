package cjx.jvm

import cj.BigInt


@implicit(Int, _fromInt)
@implicit(BigInt, _fromBigInt)
@implicit(Double, _fromDouble)
@implicit(String, _fromString)
union JVMConstValue {
    case int(Int)
    case long(BigInt)
    case float(Double)
    case double(Double)
    case string(String)

    def _fromInt(i: Int): Self = int(i)
    def _fromBigInt(i: BigInt): Self = long(i)
    def _fromDouble(f: Double): Self = double(f)
    def _fromString(s: String): Self = string(s)
}
