package cjx.jvm.main

import cj.DataView
import cj.Endian
import cj.Error
import cj.StringBuilder
import cj.BigInt
import cj.Argv
import cj.BufferReader
import cj.DynamicBuffer
import cj.FS

## Load and dump the contents of a JVM class file
class OldDump {

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

    val path: String
    val reader: BufferReader

    ## Maps utf8 ids to their utf8 values
    val utf8Map: Map[Int, String] = Map([])

    ## Maps classref ids to utf8 ids
    val classrefMap: Map[Int, Int] = Map([])

    ## Maps fieldref, methodref, interfacemethodref ids to (class-ids, name-and-type-ids)
    val memberrefMap: Map[Int, Tuple[Int, Int]] = Map([])

    ## Maps nameAndType ids to (name-utf8-ids, descriptor-utf8-ids)
    val nameAndTypeMap: Map[Int, Tuple[Int, Int]] = Map([])

    ## Maps string constant ids to utf8 ids
    val stringMap: Map[Int, Int] = Map([])

    ## Maps int, float, long, double literal values to a string representation
    ## of their values
    val primitiveMap: Map[Int, String] = Map([])

    ## Caches the entries into the constant pool when requested as a value
    val constCache: Map[Int, String] = Map([])

    var depth = 0

    def main() {
        val path = Argv()[0]
        val buffer = FS.readFileBytes(path)
        val reader = BufferReader(buffer)
        reader.endian = Endian.big
        __malloc(path, reader).run()
    }

    def print0(self, s: String) {
        IO.print("  " * depth + s)
    }

    def println(self, line: String) {
        IO.println("  " * depth + line)
    }

    def enter(self) {
        depth = depth + 1
    }

    def exit(self) {
        depth = depth - 1
    }

    def run(self) {
        println("Reading file " + path)

        # Check magic
        val magic = BigInt(reader.getUint32())
        Assert.equal(magic.hex(), "CAFEBABE")
        println("magic " + magic.hex())

        println("minor version = " + reader.getUint16())

        val major = reader.getUint16()
        val majorStr = switch major {
            case 0x3D = "Java SE 17"
            case 0x3C = "Java SE 16"
            case 0x3B = "Java SE 15"
            case 0x3A = "Java SE 14"
            case 0x39 = "Java SE 13"
            case 0x38 = "Java SE 12"
            case 0x37 = "Java SE 11"
            case 0x36 = "Java SE 10"
            case 0x35 = "Java SE 9"
            case 0x34 = "Java SE 8"
            case 0x33 = "Java SE 7"
            case 0x32 = "Java SE 6.0"
            case 0x31 = "Java SE 5.0"
            case 0x30 = "Java SE 1.4"
            case 0x2F = "Java SE 1.3"
            case 0x2E = "Java SE 1.2"
            case 0x2D = "Java SE 1.1"
            else = "Unknown " + major
        }
        println("major version = " + majorStr + " (" + major.hex() + ")")

        val constantPoolSize = reader.getUint16()
        println("constantPoolSize = " + constantPoolSize + " - 1")

        # Look ahead in constant info to be able to print nicer looking
        # information
        val save = reader.i
        for i = 1; i < constantPoolSize; i += fillConstantInfo(i) {}
        reader.i = save

        for i = 1; i < constantPoolSize; i += dumpConstantInfo(i) {}

        val accessFlags = reader.getUint16()
        println("accessFlags = " + translateFlags(accessFlags))

        val thisClass = reader.getUint16()
        println("thisClass = " + classref(thisClass))

        val superClass = reader.getUint16()
        println("superClass = " + classref(superClass))

        val interfacesCount = reader.getUint16()
        println("interfacesCount = " + interfacesCount)
        Assert.equal(interfacesCount, 0) # TODO

        val fieldsCount = reader.getUint16()
        println("fieldsCount = " + fieldsCount)
        Assert.equal(fieldsCount, 0) # TODO

        val methodsCount = reader.getUint16()
        println("methodsCount = " + methodsCount)
        for i = 0; i < methodsCount; i++ {
            dumpMethodInfo()
        }

        println("class attributes...")
        dumpAttributeList()
    }

    def translateFlags(flags: Int): String {
        val sb = StringBuilder()
        if flags & cACC_PUBLIC {
            sb.add("public ")
        }
        if flags & cACC_PRIVATE {
            sb.add("private ")
        }
        if flags & cACC_PROTECTED {
            sb.add("protected ")
        }
        if flags & cACC_STATIC {
            sb.add("static ")
        }
        if flags & cACC_FINAL {
            sb.add("final ")
        }
        if flags & cACC_SUPER {
            sb.add("super ")
        }
        if flags & cACC_INTERFACE {
            sb.add("interface ")
        }
        if flags & cACC_ABSTRACT {
            sb.add("abstract ")
        }
        if flags & cACC_SYNTHETIC {
            sb.add("synthetic ")
        }
        if flags & cACC_ANNOTATION {
            sb.add("annotation ")
        }
        if flags & cACC_ENUM {
            sb.add("enum ")
        }
        sb.toString()
    }

    ## Lookup the utf8 value for the given id
    def utf8(self, id: Int): String = utf8Map[id]

    ## Looks up the name of the referenced class
    def classref(self, id: Int): String = utf8(classrefMap[id])

    def member(self, id: Int): String = {
        val (classid, nameAndTypeId) = memberrefMap[id]
        val (name, descriptor) = nameAndType(nameAndTypeId)
        val cls = classref(classid)
        cls + "." + name + ":" + descriptor
    }

    def nameAndType(self, id: Int): Tuple[String, String] = {
        val (nameId, descriptorId) = nameAndTypeMap[id]
        (utf8(nameId), utf8(descriptorId))
    }

    def const(self, id: Int): String = {
        if id not in constCache {
            constCache[id] = constNoCache(id)
        }
        constCache[id]
    }

    def constNoCache(self, id: Int): String = {
        if id in stringMap {
            "string(" + utf8(stringMap[id]).repr() + ")"
        } else if id in classrefMap {
            "class(" + classref(id) + ")"
        } else {
            primitiveMap[id]
        }
    }

    def fillConstantInfo(self, i: Int): Int {
        val tag = reader.getUint8()
        switch tag {
            case cUtf8 = {
                val length = reader.getUint16()
                val string = reader.getUTF8(length)
                Assert.equal(length, string.size())
                utf8Map[i] = string
            }
            case cInteger = {
                val value = reader.getInt32()
                primitiveMap[i] = "int(" + value + ")"
            }
            case cFloat = {
                val value = reader.getFloat32()
                primitiveMap[i] = "float(" + value + ")"
            }
            case cLong = {
                val value = reader.getBigInt64()
                primitiveMap[i] = "long(" + value + ")"
            }
            case cDouble = {
                val value = reader.getFloat64()
                primitiveMap[i] = "double(" + value + ")"
            }
            case cClassref = {
                val utf8id = reader.getUint16()
                classrefMap[i] = utf8id
            }
            case cString = {
                stringMap[i] = reader.getUint16()
            }
            case cFieldref
            case cMethodref
            case cInterfaceMethodref = {
                val classIndex = reader.getUint16()
                val nameAndTypeIndex = reader.getUint16()
                memberrefMap[i] = (classIndex, nameAndTypeIndex)
            }
            case cNameAndType = {
                val nameUtf8Index = reader.getUint16()
                val descriptorUtf8Index = reader.getUint16()
                nameAndTypeMap[i] = (nameUtf8Index, descriptorUtf8Index)
            }
            else = throw Error("Unrecognized cpinfo tag (during lookahead): " + tag)
        }
        switch tag {
            case cLong
            case cDouble = 2
            else = 1
        }
    }

    def dumpConstantInfo(self, i: Int): Int {
        print0("  #" + i.toString().lpad(5, " ") + " ")
        val tag = reader.getUint8()
        switch tag {
            case cUtf8 = {
                IO.print("Utf8 ".rpad(16, " "))
                val length = reader.getUint16()
                val string = reader.getUTF8(length)
                IO.println(string.repr())
            }
            case cInteger = {
                IO.print("Integer ".rpad(16, " "))
                val value = reader.getInt32()
                IO.println(value)
            }
            case cFloat = {
                IO.print("Float ".rpad(16, " "))
                val value = reader.getFloat32()
                IO.println(value)
            }
            case cLong = {
                IO.print("Long ".rpad(16, " "))
                val value = reader.getBigInt64()
                IO.println(value)
            }
            case cDouble = {
                IO.print("Double ".rpad(16, " "))
                val value = reader.getFloat64()
                IO.println(value)
            }
            case cClassref = {
                IO.print("Class ".rpad(16, " "))
                val utf8id = reader.getUint16()
                IO.println("" + utf8(utf8id))
            }
            case cString = {
                IO.print("String ".rpad(16, " "))
                val utf8id = reader.getUint16()
                IO.println("" + utf8(utf8id))
            }
            case cFieldref = {
                IO.print("Fieldref ".rpad(16, " "))
                val classIndex = reader.getUint16()
                val nameAndTypeIndex = reader.getUint16()
                IO.println("" + member(i))
            }
            case cMethodref = {
                IO.print("Methodref ".rpad(16, " "))
                val classIndex = reader.getUint16()
                val nameAndTypeIndex = reader.getUint16()
                IO.println("" + member(i))
            }
            case cInterfaceMethodref = {
                IO.print("InterfaceMethodref ".rpad(16, " "))
                val classIndex = reader.getUint16()
                val nameAndTypeIndex = reader.getUint16()
                IO.println("" + member(i))
            }
            case cNameAndType = {
                IO.print("NameAndType ".rpad(16, " "))
                val nameUtf8Index = reader.getUint16()
                val descriptorUtf8Index = reader.getUint16()
                IO.println(utf8(nameUtf8Index) + ":" + utf8(descriptorUtf8Index))
            }
            else = throw Error("Unrecognized cpinfo tag: " + tag)
        }
        switch tag {
            case cLong
            case cDouble = 2
            else = 1
        }
    }

    def dumpMethodInfo(self) {
        val accessFlags = reader.getUint16()
        val nameIndex = reader.getUint16()
        val descriptorIndex = reader.getUint16()
        val name = utf8(nameIndex)
        val descriptor = utf8(descriptorIndex)
        println("=== Method " + name + " : " + descriptor + " " + translateFlags(accessFlags) + " ===")
        dumpAttributeList()
        println("=== Method " + name + " END ===")
    }

    def dumpAttributeList(self) {
        val attributesCount = reader.getUint16()
        println("attributesCount = " + attributesCount)
        enter()
        for i = 0; i < attributesCount; i++ {
            dumpAttribute()
        }
        exit()
    }

    def dumpAttribute(self) {
        val attributeNameIndex = reader.getUint16()
        val attributeLength = reader.getInt32()
        val attributeName = utf8(attributeNameIndex)
        println("Attribute " + attributeName)
        switch attributeName {
            case "Code" = {
                val maxStack = reader.getUint16()
                val maxLocals = reader.getUint16()
                val codeLength = reader.getInt32()
                println(
                    "maxStack = " + maxStack +
                    ", maxLocals = " + maxLocals +
                    ", codeLength = " + codeLength)
                val code = reader.getBuffer(codeLength)
                dumpCode(code)
                val exceptionTableLength = reader.getUint16()
                for i = 0; i < exceptionTableLength; i++ {
                    val startPc = reader.getUint16()
                    val endPc = reader.getUint16()
                    val handlerPc = reader.getUint16()
                    val catchType = reader.getUint16()
                }
                dumpAttributeList()
            }
            else = {
                println("  Unrecognized attribute... skipping")
                reader.skip(attributeLength)
            }
        }
    }

    def dumpCode(self, code: DataView) {
        enter()
        val reader = BufferReader(code)
        while reader {
            val opcode = reader.getUint8()
            switch opcode {
                case 0x00 = println("00 nop")
                case 0x01 = println("01 aconst_null")
                case 0x02 = println("02 iconst_m1")
                case 0x03 = println("03 iconst_0")
                case 0x04 = println("04 iconst_1")
                case 0x05 = println("05 iconst_2")
                case 0x06 = println("06 iconst_3")
                case 0x07 = println("07 iconst_4")
                case 0x08 = println("08 iconst_5")
                case 0x12 = {
                    val index = reader.getUint8()
                    println("12 ldc " + const(index))
                }
                case 0x13 = {
                    # Note, long or double not allowed with ldc or ldc_w
                    val index = reader.getUint16()
                    println("13 ldc_w " + const(index))
                }
                case 0x14 = {
                    # Like ldc_w, but for long or double
                    val index = reader.getUint16()
                    println("14 ldc2_w" + const(index))
                }
                case 0x2A = println("2A aload_0")
                case 0xB2 = {
                    val fieldrefIndex = reader.getUint16()
                    # IO.println("fieldrefIndex = " + fieldrefIndex)
                    val fieldref = member(fieldrefIndex)
                    println("B2 getstatic " + fieldref)
                }
                case 0xB6 = {
                    val index = reader.getUint16()
                    val methodref = member(index)
                    println("B6 invokevirtual " + methodref)
                }
                case 0xB7 = {
                    val methodref = member(reader.getUint16())
                    println("B7 invokespecial " + methodref)
                }
                case 0xB1 = println("B1 return")
                else = {
                    println("Unrecognized opcode: 0x" + opcode.hex().lpad(2, "0"))
                }
            }
        }
        exit()
    }
}
