package cj

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
}
