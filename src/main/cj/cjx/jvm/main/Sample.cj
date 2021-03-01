package cjx.jvm.main

import cj.FS
import cjx.jvm.JVMClass

## Generates a sample JVM class file.
##
## Kinda like Sample, but uses JVMClass to do the heavy lifting
##
class Sample {
    def main() {
        val cls = JVMClass()
        cls.thisClass = cls.cp.classref("sample/Sample2")
        cls.superClass = cls.cp.classref("java/lang/Object")

        cls.addField(field -> {
            field.accessFlags = JVMClass.cACC_PUBLIC | JVMClass.cACC_STATIC
            field.name = "foo"
            field.descriptor = "I"
        })

        cls.addMethod(method -> {
            method.accessFlags = JVMClass.cACC_PUBLIC | JVMClass.cACC_STATIC
            method.name = "main"
            method.descriptor = "([Ljava/lang/String;)V"
            method.addCode(code -> {
                code.maxLocals = 1

                code.getstatic("java/lang/System", "out", "Ljava/io/PrintStream;")
                code.ldc("Hello worldxxx!")
                code.invokevirtual("java/io/PrintStream", "println", "(Ljava/lang/String;)V")

                code.getstatic("java/lang/System", "out", "Ljava/io/PrintStream;")
                code.getstatic("sample/Sample2", "foo", "I")
                code.invokestatic("java/lang/Integer", "valueOf", "(I)Ljava/lang/Integer;")
                code.invokevirtual("java/lang/Object", "toString", "()Ljava/lang/String;")
                code.invokevirtual("java/io/PrintStream", "println", "(Ljava/lang/String;)V")

                code.return_()
            })
        })

        val buffer = cls.toBuffer()
        FS.writeFileBytes("target/x/sample/Sample2.class", buffer)
    }
}
