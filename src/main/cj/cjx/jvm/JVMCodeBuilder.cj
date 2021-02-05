package cjx.jvm

import cj.Buffer
import cjx.jvm.Opcode
import cjx.jvm.JVMClass
import cjx.jvm.JVMClass.ExceptionTableEntry
import cjx.jvm.JVMClass.LineNumberTableEntry
import cjx.jvm.JVMClass.CodeAttribute
import cjx.jvm.JVMClass.AttributeInfo
import cjx.jvm.JVMClass.AttributeInfoData
import cjx.jvm.JVMClass.LineNumberTableAttribute

@derive(new)
class JVMCodeBuilder {
        val methodBuilder: JVMClass.MethodBuilder
        var maxStack: Int = 0
        var maxLocals: Int = 0
        val code: Buffer = {
            val b = Buffer.empty()
            b.useLittleEndian(false)
            b
        }
        val exceptionTable: List[ExceptionTableEntry] = []
        val lineNumberTable: List[LineNumberTableEntry] = []

        def __get_cls(self): JVMClass = methodBuilder.cls

        def markLine(self, lineNumber: Int) {
            lineNumberTable.add(LineNumberTableEntry(code.size(), lineNumber))
        }

        def return_(self) {
            code.addU8(Opcode.return_)
        }

        ## Load a constant string onto the stack
        def ldstr(self, string: String) {
            ldc(cls.cp.string(string))
        }

        ## Load a constant onto the stack given its index in the constant pool
        def ldc(self, index: Int) {
            if index < 128 {
                code.addU8(Opcode.ldc)
                code.addU8(index)
            } else {
                code.addU8(Opcode.ldc_w)
                code.addU16(index)
            }
        }

        def getstatic(self, className: String, fieldName: String, type: String) {
            val index = cls.cp.fieldref(className, fieldName, type)
            code.addU8(Opcode.getstatic)
            code.addU16(index)
        }

        def invokevirtual(self, className: String, methodName: String, type: String) {
            val index = cls.cp.methodref(className, methodName, type)
            code.addU8(Opcode.invokevirtual)
            code.addU16(index)
        }

        def invokestatic(self, className: String, methodName: String, type: String) {
            val index = cls.cp.methodref(className, methodName, type)
            code.addU8(Opcode.invokestatic)
            code.addU16(index)
        }

        def build(self) : CodeAttribute {
            val cattr = CodeAttribute(maxStack, maxLocals, code, exceptionTable, [])
            if lineNumberTable {
                cattr.attributes.add(AttributeInfo(
                    cls.cp.utf8("LineNumberTable"),
                    AttributeInfoData.lineNumberTable(
                        LineNumberTableAttribute(lineNumberTable))))
            }
            cattr
        }
}
