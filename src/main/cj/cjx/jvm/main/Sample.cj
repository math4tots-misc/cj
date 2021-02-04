package cjx.jvm.main

import cj.BigInt
import cj.Argv
import cj.FS
import cj.Buffer

## Generate a sample JVM class file.
## References:
##   - https://docs.oracle.com/javase/specs/jvms/se7/html/jvms-4.html
##   - https://en.wikipedia.org/wiki/Java_class_file
class Sample {

    ## Constant pool tags
    static val cUtf8 = 1
    static val cInteger = 3
    static val cFloat = 4
    static val cLong = 5
    static val cDouble = 6
    static val cClassref = 7
    static val cString = 8
    static val cFieldref = 9
    static val cMethodref = 10
    static val cInterfaceMethodref = 11
    static val cNameAndType = 12

    ## Access flags
    static val cACC_PUBLIC = 0x0001
    static val cACC_PRIVATE = 0x0002
    static val cACC_PROTECTED = 0x0004
    static val cACC_STATIC = 0x0008
    static val cACC_FINAL = 0x0010
    static val cACC_SUPER = 0x0020 # treat superclass methods specially w/invokespecial
    static val cACC_INTERFACE = 0x0200 # interface, not a class
    static val cACC_ABSTRACT = 0x0400
    static val cACC_SYNTHETIC = 0x1000 # synthetic; not present in the source code
    static val cACC_ANNOTATION = 0x2000 # annotation type
    static val cACC_ENUM = 0x4000

    def main() {
        val path = Argv()[0]
        val fullClassName = Argv()[1]

        Assert.withMessage("." not in fullClassName, "Use '/' instead of '.' in class names")

        val ctx = Context()
        val thisClass = ctx.classref(fullClassName)
        val superClass = ctx.classref("java/lang/Object")

        {
            val code = ctx.code(1)
            code.vreturn()
            val mainMethod = ctx.method(
                cACC_PUBLIC | cACC_STATIC,
                "main",
                "([Ljava/lang/String;)V")
            mainMethod.add(code)
        }

        val b = Buffer.empty()
        b.useLittleEndian(false)
        b.addU32(0xCAFEBABE) # magic
        b.addU16(0x00) # minor version
        b.addU16(0x33) # major version (Java SE 7)
        ctx.cp.emit(b) # constantPoolCount and constantPool[]
        b.addU16(cACC_PUBLIC | cACC_SUPER) # access flags
        b.addU16(thisClass)
        b.addU16(superClass)
        b.addU16(0) # interfacesCount (none for now)
        b.addU16(0) # fieldsCount (none for now)
        ctx.emitMethods(b)
        b.addU16(0) # attribuesCount (none for now)
        FS.writeFileBytes(path, b)
    }

    @derive(new)
    class Context {
        val cp: ConstantPool = Default()
        val methods: List[MethodInfo] = []

        def classref(self, fullClassName: String): Int = cp.classref(fullClassName)

        def method(self, accessFlags: Int, name: String, descriptor: String): MethodInfo = {
            val method = MethodInfo(accessFlags, cp.utf8(name), cp.utf8(descriptor))
            methods.add(method)
            method
        }

        def code(self, argc: Int): Code = Code(self, argc)

        def emitMethods(self, out: Buffer) {
            out.addU16(methods.size())
            for method in methods {
                method.emit(out)
            }
        }
    }

    @derive(new, default)
    class ConstantPool {
        val infos: List[CpInfo] = []
        val classrefMap: Map[String, Int] = Map()

        ## Gets the constantPoolCount value as required by the class file spec
        def count(self): Int = {
            1 + infos.map(i -> when i {
                case long(i) = 2
                case double(f) = 2
                else = 1
            }).fold(0, (a, b) -> a + b)
        }

        def emit(self, out: Buffer) {
            out.addU16(count()) # constantPoolCount
            for info in infos {
                info.emit(out)
            }
        }

        def add(self, info: CpInfo): Int {
            val id = infos.size() + 1
            infos.add(info)
            id
        }

        def utf8(self, data: String): Int = add(CpInfo.utf8(data))

        def classref(self, fullName: String): Int = {
            if fullName not in classrefMap {
                classrefMap[fullName] = add(CpInfo.classref(utf8(fullName)))
            }
            classrefMap[fullName]
        }
    }

    union CpInfo {
        ## Raw utf-8 string data
        case utf8(String)

        ## 32-bit integer constant
        case integer(Int)

        ## 32-bit float constant (IEEE 754)
        case float(Double)

        ## 64-bit integer constant
        case long(BigInt)

        ## 64-bit float constant (IEEE 754)
        case double(Double)

        ## (name-index)
        case classref(Int)

        ## (utf8-index)
        case string(Int)

        ## (class-index, name-and-type-index)
        case fieldref(Int, Int)

        ## (class-index, name-and-type-index)
        case methodref(Int, Int)

        ## (class-index, name-and-type-index)
        case interfaceMethodref(Int, Int)

        ## (name-index, descriptor-index (index to utf8 entry))
        case nameAndType(Int, Int)

        def __get_tag(self): Int = when self {
            case utf8(data) = Sample.cUtf8
            case integer(i) = Sample.cInteger
            case float(f) = Sample.cFloat
            case long(i) = Sample.cLong
            case double(f) = Sample.cDouble
            case classref(nameIndex) = Sample.cClassref
            case string(utf8Index) = Sample.cString
            case fieldref(ci, nti) = Sample.cFieldref
            case methodref(ci, nti) = Sample.cMethodref
            case interfaceMethodref(ci, nti) = Sample.cInterfaceMethodref
            case nameAndType(ni, di) = Sample.cNameAndType
        }

        def emit(self, out: Buffer) {
            out.addU8(tag)
            when self {
                case utf8(string) = {
                    val utf8 = Buffer.fromUTF8(string)
                    out.addU16(utf8.size())
                    out.addBuffer(utf8)
                }
                case integer(i) = out.addI32(i)
                case float(f) = out.addF32(f)
                case long(i) = out.addI64(i)
                case double(f) = out.addF64(f)
                case classref(nameIndex) = {
                    out.addU16(nameIndex)
                }
                case string(utf8Index) = {
                    out.addU16(utf8Index)
                }
                case fieldref(classIndex, nameAndTypeIndex) = {
                    out.addU16(classIndex)
                    out.addU16(nameAndTypeIndex)
                }
                case methodref(classIndex, nameAndTypeIndex) = {
                    out.addU16(classIndex)
                    out.addU16(nameAndTypeIndex)
                }
                case interfaceMethodref(classIndex, nameAndTypeIndex) = {
                    out.addU16(classIndex)
                    out.addU16(nameAndTypeIndex)
                }
                case nameAndType(nameIndex, descriptorIndex) = {
                    out.addU16(nameIndex)
                    out.addU16(descriptorIndex)
                }
            }
        }
    }

    @derive(new)
    class MethodInfo {
        val accessFlags: Int
        val nameIndex: Int
        val descriptorIndex: Int
        val attributes: List[AttributeInfo] = []

        def emit(self, out: Buffer) {
            out.addU16(accessFlags)
            out.addU16(nameIndex)
            out.addU16(descriptorIndex)
            out.addU16(attributes.size())
            for attribute in attributes {
                attribute.emit(out)
            }
        }

        def add[C: ToAttribute](self, c: C) {
            self.attributes.add(c.toAttribute())
        }
    }

    trait ToAttribute {
        def toAttribute(self): AttributeInfo
    }

    @derive(new)
    class AttributeInfo {
        val attributeNameIndex: Int
        val data: AttributeInfoData

        def emit(self, out: Buffer) {
            out.addU16(attributeNameIndex)
            val updatePos = out.size()
            out.addU32(0)
            val startPos = out.size()
            data.emit(out)
            val endPos = out.size()
            out.setU32(updatePos, endPos - startPos)
        }
    }

    union AttributeInfoData {
        case code(CodeAttribute)
        def emit(self, out: Buffer) = when self {
            case code(code) = code.emit(out)
        }
    }

    @derive(new)
    class CodeAttribute {
        val maxStack: Int
        val maxLocals: Int
        val code: Buffer
        val exceptionTable: List[ExceptionTableEntry] = []
        val attributes: List[AttributeInfo] = []

        def emit(self, out: Buffer) {
            out.addU16(maxStack)
            out.addU16(maxLocals)
            out.addU32(code.size())
            {
                val start = out.size()
                out.addBuffer(code)
                val end = out.size()
                Assert.equal(code.size(), end - start)
            }
            Assert.equal(exceptionTable.size(), 0) # TODO
            out.addU16(exceptionTable.size())
            for entry in exceptionTable {
                entry.emit(out)
            }
            Assert.equal(attributes.size(), 0) # TODO
            out.addU16(attributes.size())
            for attribute in attributes {
                attribute.emit(out)
            }
        }
    }

    class ExceptionTableEntry {
        val startPc: Int
        val endPc: Int
        val handlerPc: Int
        val catchType: Int

        def emit(self, out: Buffer) {
            throw "TODO"
        }
    }

    ## Bytecode builder
    @derive(new)
    class Code : ToAttribute {
        val ctx: Context
        var maxLocals : Int
        var maxStack = 0
        val buffer: Buffer = Buffer.empty()

        def vreturn(self) {
            buffer.addU8(0xb1)
        }

        def toCodeAttribute(self): CodeAttribute = {
            CodeAttribute(maxStack, maxLocals, buffer)
        }

        def toAttribute(self): AttributeInfo = AttributeInfo(
            ctx.cp.utf8("Code"),
            AttributeInfoData.code(toCodeAttribute()))
    }
}
