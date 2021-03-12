package cjx.jvm.main

import cj.DynamicBuffer
import cj.Error
import cj.FS
import cjx.jvm.JVMClass
import cj.Argv

## Like cjx.jvm.main.Dump, but uses the JVMClass class to parse and dump
class Dump {
    def main() {
        var includeConstantPool = false
        for path in Argv() {
            IO.println("=== " + path + " ===")
            val writer = JVMClass.Writer()
            writer.includeConstantPool = includeConstantPool
            val buffer = FS.readFileBytes(path)
            val cls = JVMClass.fromBuffer(DynamicBuffer(buffer))
            cls.dumpstr(writer)
            IO.println(writer.sb.toString())
        }
    }
}
