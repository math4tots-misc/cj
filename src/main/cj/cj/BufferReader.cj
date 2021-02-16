package cj

import cj.Buffer

class BufferReader : ToBool {
    val buffer: Buffer
    var i = 0

    def toBool(self): Bool = i < buffer.size()

    def skip(self, n: Int) {
        i = i + n
    }

    def skipToMultipleOf(self, n: Int) {
        if i % n != 0 {
            i = i + (n - (i % n))
        }
    }

    def peekUTF8(self, len: Int): String = buffer.getUTF8(i, i + len)
    def peekBuffer(self, len: Int): Buffer = buffer.cut(i, i + len)
    def peekI8(self): Int = buffer.getI8(i)
    def peekU8(self): Int = buffer.getU8(i)
    def peekI16(self): Int = buffer.getI16(i)
    def peekU16(self): Int = buffer.getU16(i)
    def peekI32(self): Int = buffer.getI32(i)
    def peekU32(self): Double = buffer.getU32(i)
    def peekI64(self): BigInt = buffer.getI64(i)
    def peekU64(self): BigInt = buffer.getU64(i)
    def peekF32(self): Double = buffer.getF32(i)
    def peekF64(self): Double = buffer.getF64(i)

    def getUTF8(self, len: Int): String = {
        val ret = buffer.getUTF8(i, i + len)
        i = i + len
        ret
    }
    def getBuffer(self, len: Int): Buffer = {
        val ret = buffer.cut(i, i + len)
        i = i + len
        ret
    }
    def getI8(self): Int = {
        val ret = buffer.getI8(i)
        i = i + 1
        ret
    }
    def getU8(self): Int = {
        val ret = buffer.getU8(i)
        i = i + 1
        ret
    }
    def getI16(self): Int = {
        val ret = buffer.getI16(i)
        i = i + 2
        ret
    }
    def getU16(self): Int = {
        val ret = buffer.getU16(i)
        i = i + 2
        ret
    }
    def getI32(self): Int = {
        val ret = buffer.getI32(i)
        i = i + 4
        ret
    }
    def getU32(self): Double = {
        val ret = buffer.getU32(i)
        i = i + 4
        ret
    }
    def getI64(self): BigInt = {
        val ret = buffer.getI64(i)
        i = i + 8
        ret
    }
    def getU64(self): BigInt = {
        val ret = buffer.getU64(i)
        i = i + 8
        ret
    }
    def getF32(self): Double = {
        val ret = buffer.getF32(i)
        i = i + 4
        ret
    }
    def getF64(self): Double = {
        val ret = buffer.getF64(i)
        i = i + 8
        ret
    }
}
