package cj

import cj.Endian
import cj.DataView
import cj.DynamicBuffer

class BufferReader : ToBool {
    val view: DataView
    var i = 0

    def(conv: DataView.Convertible): Self = __malloc(conv.x)

    def __get_endian(self): Endian = view.endian
    def __set_endian(self, endian: Endian) { view.endian = endian }

    def toBool(self): Bool = i < view.size()

    def skip(self, n: Int) {
        i = i + n
    }

    def skipToMultipleOf(self, n: Int) {
        if i % n != 0 {
            i = i + (n - (i % n))
        }
    }

    def peekUTF8(self, len: Int): String = view.getUTF8(i, i + len)
    def peekBuffer(self, len: Int): DataView = view[i:i + len]
    def peekI8(self): Int = view.getInt8(i)
    def peekU8(self): Int = view.getUint8(i)
    def peekI16(self): Int = view.getInt16(i)
    def peekU16(self): Int = view.getUint16(i)
    def peekI32(self): Int = view.getInt32(i)
    def peekU32(self): Double = view.getUint32(i)
    def peekI64(self): BigInt = view.getBigInt64(i)
    def peekU64(self): BigInt = view.getBigUint64(i)
    def peekF32(self): Double = view.getFloat32(i)
    def peekF64(self): Double = view.getFloat64(i)

    def getUTF8(self, len: Int): String = {
        val ret = view.getUTF8(i, i + len)
        i = i + len
        ret
    }
    def getBuffer(self, len: Int): DataView = {
        val ret = view[i:i + len]
        i = i + len
        ret
    }
    def getInt8(self): Int = {
        val ret = view.getInt8(i)
        i = i + 1
        ret
    }
    def getUint8(self): Int = {
        val ret = view.getUint8(i)
        i = i + 1
        ret
    }
    def getInt16(self): Int = {
        val ret = view.getInt16(i)
        i = i + 2
        ret
    }
    def getUint16(self): Int = {
        val ret = view.getUint16(i)
        i = i + 2
        ret
    }
    def getInt32(self): Int = {
        val ret = view.getInt32(i)
        i = i + 4
        ret
    }
    def getUint32(self): Double = {
        val ret = view.getUint32(i)
        i = i + 4
        ret
    }
    def getBigInt64(self): BigInt = {
        val ret = view.getBigInt64(i)
        i = i + 8
        ret
    }
    def getBigUint64(self): BigInt = {
        val ret = view.getBigUint64(i)
        i = i + 8
        ret
    }
    def getFloat32(self): Double = {
        val ret = view.getFloat32(i)
        i = i + 4
        ret
    }
    def getFloat64(self): Double = {
        val ret = view.getFloat64(i)
        i = i + 8
        ret
    }
}
