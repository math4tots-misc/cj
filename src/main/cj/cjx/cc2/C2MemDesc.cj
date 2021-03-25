package cjx.cc2

import cj.DataView

## Memory descriptor
class C2MemDesc {
    val init: Int
    val max: Int
    val dataOffset: Int
    val data: DataView
}
