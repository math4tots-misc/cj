package cjx.jvm.main

import cj.FS
import cjx.jvm.JVMClass
import cj.Argv

## Like cjx.jvm.main.Dump, but uses the JVMClass class to parse and dump
class Dump2 {
    def main() {
        val path = Argv()[0]
        val buffer = FS.readFileBytes(path)
        val cls = JVMClass.fromBuffer(buffer)
        cls.path = path
        IO.println(cls.inspect())
    }
}
