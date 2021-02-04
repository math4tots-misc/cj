package cjx.jvm

import cj.StringBuilder
import cj.BigInt
import cj.Error
import cj.Buffer
import cj.BufferReader

@derive(new)
class JVMClass {

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

    static val magic: BigInt = 0xCAFEBABE

    var path: String = "<unknown>"
    var minorVersion: Int = 0
    var majorVersion: Int = 0x33 # Java SE 7
    var cp: ConstantPool = ConstantPool()
    var accessFlags: Int = cACC_PUBLIC
    var thisClass: Int = 0 # must be filled in
    var superClass: Int = 0 # must be filled in
    var interfaces: List[Int] = []
    var fields: List[FieldInfo] = []
    var methods: List[MethodInfo] = []
    var attributes: List[AttributeInfo] = []

    def fromBuffer(buffer: Buffer): Self {
        val parser = Parser(buffer)
        parser.parseJVMClass()
    }

    ## Return the contents of this JVM class as a human readable multi-line string
    def inspect(self): String {
        val out = Writer()
        dumpstr(out)
        out.sb.toString()
    }

    def dumpstr(self, out: Writer) {
        out.line("Inspecting " + path)
        out.indent()
        out.line("minor version = " + minorVersion)
        out.line(
            "major version = " +
            majorVersionToString(majorVersion) +
            " (" + majorVersion.hex() + ")")
        val constantPoolSize = cp.count()
        out.line("constantPoolSize = " + constantPoolSize + " - 1")
        out.indent()
        for i = 1; i < constantPoolSize; i++ {
            dumpCpInfo(out, i, cp.infos[i - 1])
        }
        out.dedent()
        out.line("accessFlags = " + translateFlags(accessFlags))
        out.line("thisClass = " + cp.getClassref(thisClass))
        out.line("superClass = " + cp.getClassref(superClass))
        out.line("interfacesCount = " + interfaces.size())
        out.indent()
        for interfaceIndex in interfaces {
            out.line(cp.getClassref(interfaceIndex))
        }
        out.dedent()
        dumpFieldList(out, fields)
        dumpMethodList(out, methods)
        dumpAttributeList(out, attributes)
        out.dedent()
    }

    private def translateFlags(flags: Int): String {
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

    private def dumpCpInfo(self, out: Writer, i: Int, info: CpInfo) {
        out.start(i.toString().lpad(5, " ") + " ")
        when info {
            case utf8(string) = out.end("Utf8 ".rpad(16, " ") + string.repr())
            case integer(i) = out.end("Integer ".rpad(16, " ") + i)
            case float(f) = out.end("Float ".rpad(16, " ") + f)
            case long(i) = out.end("Long ".rpad(16, " ") + i)
            case double(f) = out.end("Double ".rpad(16, " ") + f)
            case classref(i) = out.end("Class ".rpad(16, " ") + cp.getUtf8(i))
            case string(i) = out.end("String ".rpad(16, " ") + cp.getUtf8(i))
            case fieldref(classIndex, nameAndTypeIndex) = {
                val className = cp.getClassref(classIndex)
                val (name, type) = cp.getNameAndType(nameAndTypeIndex)
                out.end("Fieldref ".rpad(16, " ") + className + "." + name + ":" + type)
            }
            case methodref(classIndex, nameAndTypeIndex) = {
                val className = cp.getClassref(classIndex)
                val (name, type) = cp.getNameAndType(nameAndTypeIndex)
                out.end("Methodref ".rpad(16, " ") + className + "." + name + ":" + type)
            }
            case interfaceMethodref(classIndex, nameAndTypeIndex) = {
                val className = cp.getClassref(classIndex)
                val (name, type) = cp.getNameAndType(nameAndTypeIndex)
                out.end("InterfaceMethodref ".rpad(16, " ") + className + "." + name + ":" + type)
            }
            case nameAndType(nameIndex, descriptorIndex) = {
                val name = cp.getUtf8(nameIndex)
                val descriptor = cp.getUtf8(descriptorIndex)
                out.end("NameAndType ".rpad(16, " ") + name + ":" + descriptor)
            }
        }
    }

    private def dumpFieldList(self, out: Writer, fields: List[FieldInfo]) {
        out.line("fieldsCount = " + fields.size())
        out.indent()
        var first = true
        for field in fields {
            if not first {
                out.line("")
            }
            dumpField(out, field)
            first = false
        }
        out.dedent()
    }

    private def dumpField(self, out: Writer, field: FieldInfo) {
        out.line("accessFlags = " + translateFlags(field.accessFlags))
        out.line("name = " + cp.getUtf8(field.nameIndex))
        out.line("descriptor = " + cp.getUtf8(field.descriptorIndex))
        dumpAttributeList(out, field.attributes)
    }

    private def dumpMethodList(self, out: Writer, methods: List[MethodInfo]) {
        out.line("methodsCount = " + methods.size())
        out.indent()
        var first = true
        for method in methods {
            if not first {
                out.line("")
            }
            dumpMethod(out, method)
            first = false
        }
        out.dedent()
    }

    private def dumpMethod(self, out: Writer, method: MethodInfo) {
        out.line("accessFlags = " + translateFlags(method.accessFlags))
        out.line("name = " + cp.getUtf8(method.nameIndex))
        out.line("descriptor = " + cp.getUtf8(method.descriptorIndex))
        dumpAttributeList(out, method.attributes)
    }

    private def dumpAttributeList(self, out: Writer, attributes: List[AttributeInfo]) {
        out.line("attributesCount = " + attributes.size())
        out.indent()
        for attribute in attributes {
            dumpAttribute(out, attribute)
        }
        out.dedent()
    }

    private def dumpAttribute(self, out: Writer, attribute: AttributeInfo) {
        val attributeName = cp.getUtf8(attribute.attributeNameIndex)
        out.line("Attribute " + attributeName)
        when attribute.data {
            case code(cattr) = {
                out.line("maxStack = " + cattr.maxStack)
                out.line("maxLocals = " + cattr.maxLocals)
                out.line("codeLength = " + cattr.code.size())
                dumpCode(out, cattr.code)
                out.line("exceptionTableLength = " + cattr.exceptionTable.size())
                out.indent()
                for entry in cattr.exceptionTable {
                    out.line(
                        "startPc = " + entry.startPc +
                        ", endPc = " + entry.endPc +
                        ", handlerPc = " + entry.handlerPc +
                        ", catchType = " + cp.getClassref(entry.catchType))
                }
                out.dedent()
                dumpAttributeList(out, cattr.attributes)
            }
            case unknown(buffer) = out.line("  (unknown)")
        }
    }

    def dumpCode(self, out: Writer, code: Buffer) {
        var encounteredUnrecognizedOpcode = false
        out.indent()
        val reader = BufferReader(code)
        while reader {
            val position = reader.i.hex().rpad(6, " ")
            out.start(position + ": ")
            val opcode = reader.getU8()
            if encounteredUnrecognizedOpcode {
                # It's not safe to assume the rest of the code is properly interpreted
                # Just dump the bytes from here on out
                out.end(opcode.hex())
            } else {
                switch opcode {
                    case 0x00 = out.end("00 nop")
                    case 0x01 = out.end("01 aconst_null")
                    case 0x02 = out.end("02 iconst_m1")
                    case 0x03 = out.end("03 iconst_0")
                    case 0x04 = out.end("04 iconst_1")
                    case 0x05 = out.end("05 iconst_2")
                    case 0x06 = out.end("06 iconst_3")
                    case 0x07 = out.end("07 iconst_4")
                    case 0x08 = out.end("08 iconst_5")
                    case 0x12 = {
                        val index = reader.getU8()
                        out.end("12 ldc " + cp.getConst(index))
                    }
                    case 0x13 = {
                        # Note, long or double not allowed with ldc or ldc_w
                        val index = reader.getU16()
                        out.end("13 ldc_w " + cp.getConst(index))
                    }
                    case 0x14 = {
                        # Like ldc_w, but for long or double
                        val index = reader.getU16()
                        out.end("14 ldc2_w" + cp.getConst(index))
                    }
                    case 0x2A = out.end("2A aload_0")
                    case 0xB2 = {
                        val fieldrefIndex = reader.getU16()
                        val fieldref = cp.getMember(fieldrefIndex)
                        out.end("B2 getstatic " + fieldref)
                    }
                    case 0xB6 = {
                        val index = reader.getU16()
                        val methodref = cp.getMember(index)
                        out.end("B6 invokevirtual " + methodref)
                    }
                    case 0xB7 = {
                        val methodref = cp.getMember(reader.getU16())
                        out.end("B7 invokespecial " + methodref)
                    }
                    case 0xB1 = out.end("B1 return")
                    else = {
                        out.end("Unrecognized opcode: 0x" + opcode.hex().lpad(2, "0"))
                        encounteredUnrecognizedOpcode = true
                    }
                }
            }
        }
        out.dedent()
    }

    def majorVersionToString(version: Int): String = switch version {
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
        else = "Unknown (" + version + ")"
    }

    class Parser {
        val reader: BufferReader
        var cp: ConstantPool = ?

        def new(buffer: Buffer): Self {
            buffer.useLittleEndian(false)
            __malloc(BufferReader(buffer))
        }

        def parseJVMClass(self): JVMClass {
            val cls = JVMClass()
            val magic: BigInt = reader.getU32()
            if magic != JVMClass.magic {
                throw Error("Invalid magic: " + magic.hex())
            }
            cls.minorVersion = reader.getU16()
            cls.majorVersion = reader.getU16()
            cls.cp = parseConstantPool()
            cp = cls.cp
            cls.accessFlags = reader.getU16()
            cls.thisClass = reader.getU16()
            cls.superClass = reader.getU16()
            val interfacesCount = reader.getU16()
            for i = 0; i < interfacesCount; i++ {
                cls.interfaces.add(reader.getU16())
            }
            cls.fields = parseFieldList()
            cls.methods = parseMethodList()
            cls.attributes = parseAttributeList()
            cls
        }

        def parseConstantPool(self): ConstantPool {
            val constantPoolSize = reader.getU16()
            val cp = ConstantPool()
            for i = 1; i < constantPoolSize; i++ {
                cp.add(parseCpInfo())
            }
            cp
        }

        def parseCpInfo(self): CpInfo {
            val tag = reader.getU8()
            switch tag {
                case (JVMClass.cUtf8) = {
                    # TODO: Use the modified UTF-8 encoding as required by the JVM spec
                    val length = reader.getU16()
                    val string = reader.getUTF8(length)
                    Assert.equal(length, string.size())
                    CpInfo.utf8(string)
                }
                case (JVMClass.cInteger) = CpInfo.integer(reader.getI32())
                case (JVMClass.cFloat) = CpInfo.float(reader.getF32())
                case (JVMClass.cLong) = CpInfo.long(reader.getI64())
                case (JVMClass.cDouble) = CpInfo.double(reader.getF64())
                case (JVMClass.cClassref) = CpInfo.classref(reader.getU16())
                case (JVMClass.cString) = CpInfo.string(reader.getU16())
                case (JVMClass.cFieldref) = {
                    val classIndex = reader.getU16()
                    val nameAndTypeIndex = reader.getU16()
                    CpInfo.fieldref(classIndex, nameAndTypeIndex)
                }
                case (JVMClass.cMethodref) = {
                    val classIndex = reader.getU16()
                    val nameAndTypeIndex = reader.getU16()
                    CpInfo.methodref(classIndex, nameAndTypeIndex)
                }
                case (JVMClass.cInterfaceMethodref) = {
                    val classIndex = reader.getU16()
                    val nameAndTypeIndex = reader.getU16()
                    CpInfo.interfaceMethodref(classIndex, nameAndTypeIndex)
                }
                case (JVMClass.cNameAndType) = {
                    val nameIndex = reader.getU16()
                    val descriptorIndex = reader.getU16()
                    CpInfo.nameAndType(nameIndex, descriptorIndex)
                }
                else = throw Error("Unrecognized cpinfo tag: " + tag)
            }
        }

        def parseFieldList(self): List[FieldInfo] {
            val fields: List[FieldInfo] = []
            val fieldsCount = reader.getU16()
            for i = 0; i < fieldsCount; i++ {
                fields.add(parseField())
            }
            fields
        }

        def parseField(self): FieldInfo {
            val accessFlags = reader.getU16()
            val nameIndex = reader.getU16()
            val descriptorIndex = reader.getU16()
            val attributes = parseAttributeList()
            FieldInfo(accessFlags, nameIndex, descriptorIndex, attributes)
        }

        def parseMethodList(self): List[MethodInfo] {
            val methods: List[MethodInfo] = []
            val methodsCount = reader.getU16()
            for i = 0; i < methodsCount; i++ {
                methods.add(parseMethod())
            }
            methods
        }

        def parseMethod(self): MethodInfo {
            val accessFlags = reader.getU16()
            val nameIndex = reader.getU16()
            val descriptorIndex = reader.getU16()
            val attributes = parseAttributeList()
            MethodInfo(accessFlags, nameIndex, descriptorIndex, attributes)
        }

        def parseAttributeList(self): List[AttributeInfo] {
            val attributesCount = reader.getU16()
            val attributes: List[AttributeInfo] = []
            for i = 0; i < attributesCount; i++ {
                attributes.add(parseAttribute())
            }
            attributes
        }

        def parseAttribute(self): AttributeInfo {
            val attributeNameIndex = reader.getU16()
            val length = reader.getI32()
            val attributeName = cp.getUtf8(attributeNameIndex)
            val data = switch attributeName {
                case "Code" = AttributeInfoData.code(parseCodeAttribute())
                else = AttributeInfoData.unknown(reader.getBuffer(length))
            }
            AttributeInfo(attributeNameIndex, data)
        }

        def parseCodeAttribute(self): CodeAttribute {
            val maxStack = reader.getU16()
            val maxLocals = reader.getU16()
            val codeLength = reader.getI32()
            val code = reader.getBuffer(codeLength)
            val exceptionTableLength = reader.getU16()
            val exceptionTable: List[ExceptionTableEntry] = []
            for i = 0; i < exceptionTableLength; i++ {
                exceptionTable.add(parseExceptionTableEntry())
            }
            val attributes = parseAttributeList()
            CodeAttribute(maxStack, maxLocals, code, exceptionTable, attributes)
        }

        def parseExceptionTableEntry(self): ExceptionTableEntry {
            val startPc = reader.getU16()
            val endPc = reader.getU16()
            val handlerPc = reader.getU16()
            val catchType = reader.getU16()
            ExceptionTableEntry(startPc, endPc, handlerPc, catchType)
        }
    }

    @derive(new)
    class ConstantPool {
        val infos: List[CpInfo] = []
        val classrefMap: Map[String, Int] = Map()
        val utf8Map: Map[String, Int] = Map()
        val stringMap: Map[String, Int] = Map()
        val nameAndTypeMap: Map[Tuple[String, String], Int] = Map()
        val methodrefMap: Map[Tuple[String, String, String], Int] = Map()
        val fieldrefMap: Map[Tuple[String, String, String], Int] = Map()
        val interfaceMethodrefMap: Map[Tuple[String, String, String], Int] = Map()
        val constMap: Map[Int, String] = Map()

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

        ## Given an index into some value-like entry, return a string describing that entry
        def getConst(self, index: Int): String = {
            if index not in constMap {
                constMap[index] = getConstNoCache(index)
            }
            constMap[index]
        }

        def getConstNoCache(self, index: Int): String = when infos[index - 1] {
            case utf8(string) = "utf8(" + string.repr() + ")"
            case string(i) = "string(" + getUtf8(i).repr() + ")"
            case integer(i) = "int(" + i + ")"
            case float(f) = "float(" + f + ")"
            case long(i) = "long(" + i + ")"
            case double(f) = "double(" + f + ")"
            case classref(c) = "class(" + getUtf8(c) + ")"
            else = throw Error("Unsupported constant pool index entry " + index)
        }

        def getUtf8(self, index: Int): String = when infos[index - 1] {
            case utf8(string) = string
            else = throw Error("Invalid utf8 constant pool index " + index)
        }

        def utf8(self, data: String): Int = {
            if data not in utf8Map {
                utf8Map[data] = add(CpInfo.utf8(data))
            }
            utf8Map[data]
        }

        def getClassref(self, index: Int): String = when infos[index - 1] {
            case classref(i) = getUtf8(i)
            else = throw Error("Invalid classref constant pool index " + index)
        }

        def classref(self, fullName: String): Int = {
            if fullName not in classrefMap {
                classrefMap[fullName] = add(CpInfo.classref(utf8(fullName)))
            }
            classrefMap[fullName]
        }

        def string(self, data: String): Int = {
            if data not in stringMap {
                val utf8index = utf8(data)
                stringMap[data] = add(CpInfo.string(utf8index))
            }
            stringMap[data]
        }

        def getNameAndType(self, index: Int): Tuple[String, String] = when infos[index - 1] {
            case nameAndType(nameIndex, descriptorIndex) = (
                getUtf8(nameIndex), getUtf8(descriptorIndex))
            else = throw Error("Invalid nameAndType constant pool index " + index)
        }

        def nameAndType(self, name: String, descriptor: String): Int = {
            val key = (name, descriptor)
            if key not in nameAndTypeMap {
                nameAndTypeMap[key] = add(CpInfo.nameAndType(utf8(name), utf8(descriptor)))
            }
            nameAndTypeMap[key]
        }

        def getMemberTriple(self, index: Int): Tuple[String, String, String] = {
            val (i, j) = when infos[index - 1] {
                case fieldref(i, j) = (i, j)
                case methodref(i, j) = (i, j)
                case interfaceMethodref(i, j) = (i, j)
                else = throw Error(
                    "Invalid method/field/interfacemethod constant pool index " + index)
            }
            val className = getClassref(i)
            val (memberName, descriptor) = getNameAndType(j)
            (className, memberName, descriptor)
        }

        def getMember(self, index: Int): String = {
            val (className, memberName, descriptor) = getMemberTriple(index)
            className + "." + memberName + ":" + descriptor
        }

        def methodref(self, className: String, name: String, descriptor: String): Int = {
            val key = (className, name, descriptor)
            if key not in methodrefMap {
                methodrefMap[key] = add(CpInfo.methodref(
                    classref(className), nameAndType(name, descriptor)))
            }
            methodrefMap[key]
        }

        def fieldref(self, className: String, name: String, descriptor: String): Int = {
            val key = (className, name, descriptor)
            if key not in fieldrefMap {
                fieldrefMap[key] = add(CpInfo.fieldref(
                    classref(className), nameAndType(name, descriptor)))
            }
            fieldrefMap[key]
        }

        def interfaceMethodref(self, className: String, name: String, descriptor: String): Int = {
            val key = (className, name, descriptor)
            if key not in interfaceMethodrefMap {
                interfaceMethodrefMap[key] = add(CpInfo.interfaceMethodref(
                    classref(className), nameAndType(name, descriptor)))
            }
            interfaceMethodrefMap[key]
        }
    }

    union CpInfo {
        ## Raw utf-8 string data
        ## TODO: Use the modified UTF-8 encoding as required by the JVM spec
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
            case utf8(data) = JVMClass.cUtf8
            case integer(i) = JVMClass.cInteger
            case float(f) = JVMClass.cFloat
            case long(i) = JVMClass.cLong
            case double(f) = JVMClass.cDouble
            case classref(nameIndex) = JVMClass.cClassref
            case string(utf8Index) = JVMClass.cString
            case fieldref(ci, nti) = JVMClass.cFieldref
            case methodref(ci, nti) = JVMClass.cMethodref
            case interfaceMethodref(ci, nti) = JVMClass.cInterfaceMethodref
            case nameAndType(ni, di) = JVMClass.cNameAndType
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
    class FieldInfo {
        val accessFlags: Int
        val nameIndex: Int
        val descriptorIndex: Int
        val attributes: List[AttributeInfo]
    }

    @derive(new)
    class MethodInfo {
        val accessFlags: Int
        val nameIndex: Int
        val descriptorIndex: Int
        val attributes: List[AttributeInfo]
    }

    @derive(new)
    class AttributeInfo {
        val attributeNameIndex: Int
        val data: AttributeInfoData
    }

    union AttributeInfoData {
        case code(CodeAttribute)
        case unknown(Buffer)
    }

    @derive(new)
    class CodeAttribute {
        val maxStack: Int
        val maxLocals: Int
        val code: Buffer
        val exceptionTable: List[ExceptionTableEntry]
        val attributes: List[AttributeInfo]
    }

    @derive(new)
    class ExceptionTableEntry {
        val startPc: Int
        val endPc: Int
        val handlerPc: Int
        val catchType: Int
    }

    @derive(new)
    class Writer {
        val sb: StringBuilder = StringBuilder()
        var depth = 0

        def indent(self) {
            depth = depth + 1
        }

        def dedent(self) {
            depth = depth - 1
        }

        ## Emit a full line
        def line(self, line: String) {
            sb.add("  " * depth + line + "\n")
        }

        ## Emit the start of a line
        def start(self, s: String) {
            sb.add("  " * depth + s)
        }

        ## Emit the end of a line
        def end(self, s: String) {
            sb.add(s + "\n")
        }

        ## Emit the middle of a line
        def middle(self, s: String) {
            sb.add(s)
        }
    }
}
