package cjx.cc

import cjx.cc.C2MemDesc
import cj.Uint8Array

class C2Code {
    val binary: Uint8Array
    val memDesc: C2MemDesc
    val names: List[String]  # for debugging/stacktrace
}
