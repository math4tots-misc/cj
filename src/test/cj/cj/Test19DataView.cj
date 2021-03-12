package cj

import cj.Endian
import cj.Uint8Array
import cj.DataView
import cj.ArrayBuffer

class Test19DataView {

    @test
    def misc() {
        {
            val abuf = ArrayBuffer(16)
            val dv0 = DataView(abuf)
            val dv1 = DataView.fromParts(abuf, 4, 4, Endian.big)
            dv1.setUint16(0, 5)
            Assert.equal(dv0.getUint32(0), 0)
            Assert.equal(dv0.getUint32(4), 327680)
            Assert.equal(dv0.getUint32(4), dv1.getUint32(0))
            Assert.equal(dv0.getUint16(4), 5)
            dv0.endian = Endian.little
            Assert.equal(dv0.getUint32(4), 1280)
        }
    }

    @test
    def slice() {
        {
            val abuf = ArrayBuffer(5)
            val dv = DataView(abuf)
            for i = 0; i < dv.byteLength; i++ {
                dv.setUint8(i, i * 3)
            }
            Assert.equal(abuf, ArrayBuffer([0, 3, 6, 9, 12]))
            Assert.equal(abuf[2:], ArrayBuffer([6, 9, 12]))
            Assert.equal(abuf[:2], ArrayBuffer([0, 3]))
            val dv2 = DataView.fromParts(abuf, 2, abuf.byteLength - 2, Endian.big)
            Assert.equal(dv2.byteLength, 3)
            Assert.equal(ArrayBuffer(dv2).byteLength, 3)
            Assert.equal(ArrayBuffer(dv2), ArrayBuffer([6, 9, 12]))
        }
    }
}
