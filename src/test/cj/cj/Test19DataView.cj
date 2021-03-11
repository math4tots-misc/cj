package cj

import cj.Uint8Array
import cj.DataView
import cj.ArrayBuffer

class Test19DataView {

    @test
    def misc() {
        {
            val abuf = ArrayBuffer(16)
            val dv0 = DataView(abuf, false)
            val dv1 = DataView.fromParts(abuf, 4, 4)
            dv1.setUint16(0, 5)
            Assert.equal(dv0.getUint32(0), 0)
            Assert.equal(dv0.getUint32(4), 327680)
            Assert.equal(dv0.getUint32(4), dv1.getUint32(0))
            Assert.equal(dv0.getUint16(4), 5)
            dv0.useLittleEndian(true)
            Assert.equal(dv0.getUint32(4), 1280)
        }
    }

    @test
    def slice() {
        {
            val abuf = ArrayBuffer(5)
            val dv = DataView(abuf, false)
            for i = 0; i < dv.byteLength; i++ {
                dv.setUint8(i, i * 3)
            }
            Assert.equal(abuf, Uint8Array(0, 3, 6, 9, 12).buffer)
            Assert.equal(abuf[2:], Uint8Array(6, 9, 12).buffer)
        }
    }
}
