package cjx.jvm

import cjx.jvm.OpcodeInfo
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
    static val cMethodHandle = 15
    static val cMethodType = 16
    static val cInvokeDynamic = 18

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

        if out.includeConstantPool {
            out.line("constantPoolSize = " + constantPoolSize + " - 1")
            out.indent()
            for i = 1; i < constantPoolSize; i++ {
                dumpCpInfo(out, i, cp.infos[i - 1])
            }
            out.dedent()
        }

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
            case empty = ()
            case classref(i) = out.end("Class ".rpad(16, " ") + cp.getUtf8(i))
            case string(i) = out.end("String ".rpad(16, " ") + cp.getUtf8(i).repr())
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
            case methodHandle(x, y) = out.end("MethodHandle " + x + " " + y) # TODO
            case methodType(x) = out.end("MethodType " + x) # TODO
            case invokeDynamic(x, y) = out.end("InvokeDynamic " + x + " " + y) # TODO
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
            case constantValue(cvattr) = {
                out.line("  value = " + cp.getConst(cvattr.constantValueIndex))
            }
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
            case lineNumberTable(lntattr) = {
                out.line("lineNumberTableLength = " + lntattr.lineNumberTable.size())
                out.indent()
                for entry in lntattr.lineNumberTable {
                    out.line("startPc = 0x" + entry.startPc + ", lineNumber = " + entry.lineNumber)
                }
                out.dedent()
            }
            case unknown(buffer) = out.line("  (unknown)")
        }
    }

    def dumpCode(self, out: Writer, code: Buffer) {
        var encounteredUnrecognizedOpcode = false
        out.indent()
        val reader = BufferReader(code)
        while reader {
            val pos = reader.i
            out.start(pos.hex().rpad(6, " ") + ": ")
            val opcode = reader.getU8()
            if encounteredUnrecognizedOpcode {
                # It's not safe to assume the rest of the code is properly interpreted
                # Just dump the bytes from here on out
                out.end(opcode.hex())
            } else {
                switch opcode {
                    case 0x10 = {
                        # Push byte as integer value
                        # This is the only opcode that has a direct i8 argument
                        val value = reader.getI8()
                        out.end("10 bipush " + value)
                    }
                    case 0x11 = {
                        # Push short as integer value
                        # This is the only opcode that has a direct i16 value
                        val value = reader.getI16()
                        out.end("11 sipush " + value)
                    }
                    case 0x12 = {
                        # Load a constant
                        # This is the only opcode that has an 8-bit cp-index argument
                        val index = reader.getU8()
                        out.end("12 ldc " + cp.getConst(index))
                    }
                    case 0x84 = {
                        # iinc - increment
                        # this is the only opcode that has this signature
                        val index = reader.getU8()
                        val value = reader.getI8()
                        out.end("84 iinc " + index + " " + value)
                    }
                    case 0xAA = {
                        # tableswitch
                        reader.skipToMultipleOf(4) # padding
                        val default = reader.getI32()
                        val low = reader.getI32()
                        val high = reader.getI32()
                        out.end("AA tableswitch " + " " + low + " - " + high)
                        out.indent()
                        out.line("default = " + default + " -> 0x" + (pos + default).hex())
                        for i = low; i <= high; i++ {
                            val offset = reader.getI32()
                            val target = pos + offset
                            out.line(
                                "" + i.repr().lpad(8, " ") +
                                ": offset=" + offset +
                                " -> 0x" + target.hex())
                        }
                        out.dedent()
                    }
                    case 0xAB = {
                        # lookupswitch
                        reader.skipToMultipleOf(4) # padding
                        val default = reader.getI32()
                        val npairs = reader.getI32()
                        out.end("AB lookupswitch npairs=" + npairs)
                        out.indent()
                        out.line("default = " + default + " -> 0x" + (pos + default).hex())
                        for i = 0; i < npairs; i++ {
                            val match = reader.getI32()
                            val offset = reader.getI32()
                            val target = pos + offset
                            out.line(
                                "" + match.repr().lpad(8, " ") +
                                ": offset=" + offset +
                                " -> 0x" + target.hex())
                        }
                        out.dedent()
                    }
                    case 0xB9 = {
                        # invokeinterface -- has a funky signature
                        # in that it duplicates the invocation arg length in
                        # its opcode argument (in addition to its descriptor)
                        val index = reader.getU16()
                        val argc = reader.getU8()
                        Assert.equal(reader.getU8(), 0)
                        out.end("B9 invokeinterface " + cp.getConst(index) + " " + argc)
                    }
                    case 0xBA = {
                        # invokedynamic -- requires 2 extra 0 bytes for some reason
                        val index = reader.getU16()
                        Assert.equal(reader.getU16(), 0)
                        out.end("BA invokedynamic " + cp.getConst(index))
                    }
                    case 0xBC = {
                        # create new primitive array
                        val atype = reader.getU8()
                        val atypeName = switch atype {
                            case 4 = "boolean"
                            case 5 = "char"
                            case 6 = "float"
                            case 7 = "double"
                            case 8 = "byte"
                            case 9 = "short"
                            case 10 = "int"
                            case 11 = "long"
                            else = "unknown(" + atype + ")"
                        }
                        out.end("BC newarray " + atypeName + " (atype=" + atype + ")")
                    }
                    case 0xc4 = {
                        # wide modifier for local variable opcodes
                        val nextOpcode = reader.getU8()
                        if nextOpcode == 0x84 {
                            # i.e. modified iinc
                            val index = reader.getU16()
                            val value = reader.getI16()
                            out.end("c4 84 iinc_w " + index + " " + value)
                        } else {
                            val opcodeName = OpcodeInfo.oneU8LocalArgOpcode[nextOpcode] + "_w"
                            val index = reader.getU16()
                            out.end(
                                "c4 " + nextOpcode.hex().lpad(2, "0") + " " +
                                opcodeName + " " + index)
                        }
                    }
                    else = {
                        val opcodeHex = opcode.hex().lpad(2, "0")
                        if opcode in OpcodeInfo.zeroArgOpcodes {
                            val opcodeName = OpcodeInfo.zeroArgOpcodes[opcode]
                            out.end(opcodeHex + " " + opcodeName)
                        } else if opcode in OpcodeInfo.oneU16BranchArgOpcode {
                            val opcodeName = OpcodeInfo.oneU16BranchArgOpcode[opcode]
                            val offset = reader.getI16()
                            val dest = pos + offset
                            val destHex = dest.hex()
                            out.end(
                                opcodeHex + " " + opcodeName +
                                " offset=" + offset +
                                " -> " + destHex)
                        } else if opcode in OpcodeInfo.oneU16ConstArgOpcode {
                            val opcodeName = OpcodeInfo.oneU16ConstArgOpcode[opcode]
                            val index = reader.getU16()
                            out.end(opcodeHex + " " + opcodeName + " " + cp.getConst(index))
                        } else if opcode in OpcodeInfo.oneU8LocalArgOpcode {
                            val opcodeName = OpcodeInfo.oneU8LocalArgOpcode[opcode]
                            val index = reader.getU8()
                            out.end(opcodeHex + " " + opcodeName + " " + index)
                        } else {
                            out.end("Unrecognized opcode: 0x" + opcodeHex)
                            encounteredUnrecognizedOpcode = true
                        }
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

    ## Write out the contents of this class file into a Buffer
    def toBuffer(self): Buffer {
        val out = Buffer.empty()
        out.useLittleEndian(false)
        emit(out)
        out
    }

    def emit(self, out: Buffer) {
        out.addU32(0xCAFEBABE)
        out.addU16(minorVersion)
        out.addU16(majorVersion)
        cp.emit(out)
        out.addU16(accessFlags)
        out.addU16(thisClass)
        out.addU16(superClass)
        out.addU16(interfaces.size())
        for iface in interfaces {
            out.addU16(iface)
        }
        out.addU16(fields.size())
        for field in fields {
            emitField(out, field)
        }
        out.addU16(methods.size())
        for method in methods {
            emitMethod(out, method)
        }
        emitAttributeList(out, attributes)
    }

    def emitField(self, out: Buffer, field: FieldInfo) {
        out.addU16(field.accessFlags)
        out.addU16(field.nameIndex)
        out.addU16(field.descriptorIndex)
        emitAttributeList(out, field.attributes)
    }

    def emitMethod(self, out: Buffer, method: MethodInfo) {
        out.addU16(method.accessFlags)
        out.addU16(method.nameIndex)
        out.addU16(method.descriptorIndex)
        emitAttributeList(out, method.attributes)
    }

    def emitAttributeList(self, out: Buffer, attributes: List[AttributeInfo]) {
        out.addU16(attributes.size())
        for attribute in attributes {
            emitAttribute(out, attribute)
        }
    }

    def emitAttribute(self, out: Buffer, attribute: AttributeInfo) {
        out.addU16(attribute.attributeNameIndex)
        val attributeLengthPosition = out.size()
        out.addI32(0) # attributeLength
        val attributeBodyStart = out.size()
        when attribute.data {
            case constantValue(cvattr) = out.addU16(cvattr.constantValueIndex)
            case code(cattr) = {
                out.addU16(cattr.maxStack)
                out.addU16(cattr.maxLocals)
                out.addI32(cattr.code.size())
                out.addBuffer(cattr.code)
                out.addU16(cattr.exceptionTable.size())
                for entry in cattr.exceptionTable {
                    out.addU16(entry.startPc)
                    out.addU16(entry.endPc)
                    out.addU16(entry.handlerPc)
                    out.addU16(entry.catchType)
                }
                emitAttributeList(out, cattr.attributes)
            }
            case lineNumberTable(lntattr) = {
                out.addU16(lntattr.lineNumberTable.size())
                for entry in lntattr.lineNumberTable {
                    out.addU16(entry.startPc)
                    out.addU16(entry.lineNumber)
                }
            }
            case unknown(data) = out.addBuffer(data)
        }
        val attributeBodyEnd = out.size()
        out.setI32(attributeLengthPosition, attributeBodyEnd - attributeBodyStart)
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
                case (JVMClass.cMethodHandle) = {
                    val referenceKind = reader.getU8()
                    val referenceIndex = reader.getU16()
                    CpInfo.methodHandle(referenceKind, referenceIndex)
                }
                case (JVMClass.cMethodType) = {
                    val descriptorIndex = reader.getU16()
                    CpInfo.methodType(descriptorIndex)
                }
                case (JVMClass.cInvokeDynamic) = {
                    val bootstrapMethodAttrIndex = reader.getU16()
                    val nameAndTypeIndex = reader.getU16()
                    CpInfo.invokeDynamic(bootstrapMethodAttrIndex, nameAndTypeIndex)
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
                case "ConstantValue" = AttributeInfoData.constantValue(
                    parseConstantValueAttribute())
                case "Code" = AttributeInfoData.code(parseCodeAttribute())
                case "LineNumberTable" = AttributeInfoData.lineNumberTable(
                    parseLineNumberTableAttribute())
                else = AttributeInfoData.unknown(reader.getBuffer(length))
            }
            AttributeInfo(attributeNameIndex, data)
        }

        def parseConstantValueAttribute(self): ConstantValueAttribute {
            val constantValueIndex = reader.getU16()
            ConstantValueAttribute(constantValueIndex)
        }

        def parseCodeAttribute(self): CodeAttribute {
            val maxStack = reader.getU16()
            val maxLocals = reader.getU16()
            val codeLength = reader.getI32()
            val code = reader.getBuffer(codeLength)
            code.useLittleEndian(false)
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

        def parseLineNumberTableAttribute(self): LineNumberTableAttribute {
            val lineNumberTableLength = reader.getU16()
            val entries: List[LineNumberTableEntry] = []
            for i = 0; i < lineNumberTableLength; i++ {
                val startPc = reader.getU16()
                val lineNumber = reader.getU16()
                entries.add(LineNumberTableEntry(startPc, lineNumber))
            }
            LineNumberTableAttribute(entries)
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
            when info {
                case double(f) = infos.add(CpInfo.empty())
                case long(f) = infos.add(CpInfo.empty())
                else = {}
            }
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
            case integer(i) = "int(" + i + ")"
            case float(f) = "float(" + f + ")"
            case long(i) = "long(" + i + ")"
            case double(f) = "double(" + f + ")"
            case empty() = "empty()"
            case classref(c) = "class(" + getUtf8(c) + ")"
            case string(i) = "string(" + getUtf8(i).repr() + ")"
            case fieldref(ci, nti) = getMember(index)
            case methodref(ci, nti) = getMember(index)
            case interfaceMethodref(ci, nti) = getMember(index)
            case nameAndType(ni, ti) = "nameAndType(" + getUtf8(ni) + ", " + getUtf8(ti) + ")"
            case methodHandle(rk, ri) = "methodHandle(" + rk + ", " + ri + ")"
            case methodType(di) = "methodType(" + getUtf8(di) + ")"
            case invokeDynamic(bi, nti) = "invokeDynamic(" + bi + ", " + getConst(nti) + ")"
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

        ## Empty slots for long and double slots
        case empty()

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

        ## (reference-kind (u1), reference-index)
        case methodHandle(Int, Int)

        ## (descriptor-index)
        case methodType(Int)

        ## (bootstrap-method-attr-index, name-and-type-index)
        case invokeDynamic(Int, Int)

        def __get_tag(self): Int = when self {
            case utf8(data) = JVMClass.cUtf8
            case integer(i) = JVMClass.cInteger
            case float(f) = JVMClass.cFloat
            case long(i) = JVMClass.cLong
            case double(f) = JVMClass.cDouble
            case empty() = throw Error("Tried to get tag on empty CpInfo")
            case classref(nameIndex) = JVMClass.cClassref
            case string(utf8Index) = JVMClass.cString
            case fieldref(ci, nti) = JVMClass.cFieldref
            case methodref(ci, nti) = JVMClass.cMethodref
            case interfaceMethodref(ci, nti) = JVMClass.cInterfaceMethodref
            case nameAndType(ni, di) = JVMClass.cNameAndType
            case methodHandle(rk, ri) = JVMClass.cMethodHandle
            case methodType(di) = JVMClass.cMethodType
            case invokeDynamic(bmai, nati) = JVMClass.cInvokeDynamic
        }

        def emit(self, out: Buffer) {
            when self {
                case empty() = return ()
                else = ()
            }
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
                case empty() = ()
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
                case methodHandle(referenceKind, referenceIndex) = {
                    out.addU8(referenceKind)
                    out.addU16(referenceIndex)
                }
                case methodType(descriptorIndex) = {
                    out.addU16(descriptorIndex)
                }
                case invokeDynamic(bootstrapMethodAttrIndex, nameAndTypeIndex) = {
                    out.addU16(bootstrapMethodAttrIndex)
                    out.addU16(nameAndTypeIndex)
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
        case constantValue(ConstantValueAttribute)
        case code(CodeAttribute)
        case lineNumberTable(LineNumberTableAttribute)
        case unknown(Buffer)
    }

    @derive(new)
    class ConstantValueAttribute {
        val constantValueIndex: Int
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
    class LineNumberTableAttribute {
        val lineNumberTable: List[LineNumberTableEntry]
    }

    @derive(new)
    class LineNumberTableEntry {
        val startPc: Int
        val lineNumber: Int
    }

    def addField(self, f: Fn[FieldBuilder, Unit]) {
        val fieldBuilder = FieldBuilder(self)
        f.call(fieldBuilder)
        fields.add(fieldBuilder.build())
    }

    @derive(new)
    class FieldBuilder {
        val cls: JVMClass
        var accessFlags: Int = ?
        var nameIndex: Int = ?
        var descriptorIndex: Int = ?

        def __set_name(self, name: String) {
            nameIndex = cls.cp.utf8(name)
        }

        def __set_descriptor(self, descriptor: String) {
            descriptorIndex = cls.cp.utf8(descriptor)
        }

        def build(self): FieldInfo {
            FieldInfo(accessFlags, nameIndex, descriptorIndex, [])
        }
    }

    def addMethod(self, f: Fn[MethodBuilder, Unit]) {
        val methodBuilder = MethodBuilder(self)
        f.call(methodBuilder)
        methods.add(methodBuilder.build())
    }

    @derive(new)
    class MethodBuilder {
        val cls: JVMClass
        var accessFlags: Int = ?
        var nameIndex: Int = ?
        var descriptorIndex: Int = ?
        var code: Nullable[CodeAttribute] = null

        def __set_name(self, name: String) {
            nameIndex = cls.cp.utf8(name)
        }

        def __set_descriptor(self, descriptor: String) {
            descriptorIndex = cls.cp.utf8(descriptor)
        }

        def addCode(self, f: Fn[CodeBuilder, Unit]) {
            val codeBuilder = CodeBuilder(self)
            f.call(codeBuilder)
            code = null(codeBuilder.build())
        }

        def build(self): MethodInfo {
            val attributes: List[AttributeInfo] = []
            if null(cattr) = code {
                attributes.add(AttributeInfo(
                    cls.cp.utf8("Code"),
                    AttributeInfoData.code(cattr)))
            }
            MethodInfo(accessFlags, nameIndex, descriptorIndex, attributes)
        }
    }

    @derive(new)
    class CodeBuilder {
        val methodBuilder: MethodBuilder
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
            code.addU8(OpcodeInfo.return_)
        }

        ## Load a constant string onto the stack
        def ldstr(self, string: String) {
            ldc(cls.cp.string(string))
        }

        ## Load a constant onto the stack given its index in the constant pool
        def ldc(self, index: Int) {
            if index < 128 {
                code.addU8(OpcodeInfo.ldc)
                code.addU8(index)
            } else {
                code.addU8(OpcodeInfo.ldc_w)
                code.addU16(index)
            }
        }

        def getstatic(self, className: String, fieldName: String, type: String) {
            val index = cls.cp.fieldref(className, fieldName, type)
            code.addU8(OpcodeInfo.getstatic)
            code.addU16(index)
        }

        def invokevirtual(self, className: String, methodName: String, type: String) {
            val index = cls.cp.methodref(className, methodName, type)
            code.addU8(OpcodeInfo.invokevirtual)
            code.addU16(index)
        }

        def invokestatic(self, className: String, methodName: String, type: String) {
            val index = cls.cp.methodref(className, methodName, type)
            code.addU8(OpcodeInfo.invokestatic)
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

    @derive(new)
    class Writer {
        val sb: StringBuilder = StringBuilder()
        var depth = 0
        var includeConstantPool = true

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
