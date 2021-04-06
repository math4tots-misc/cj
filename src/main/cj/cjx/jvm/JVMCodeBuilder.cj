package cjx.jvm

import cj.Endian
import cj.Error
import cj.BufferReader
import cjx.jvm.JVMConstValue
import cj.DynamicBuffer
import cjx.jvm.Opcode
import cjx.jvm.JVMClass
import cjx.jvm.JVMClass.ExceptionTableEntry
import cjx.jvm.JVMClass.LineNumberTableEntry
import cjx.jvm.JVMClass.LocalVariableTableEntry
import cjx.jvm.JVMClass.CodeAttribute
import cjx.jvm.JVMClass.AttributeInfo
import cjx.jvm.JVMClass.AttributeInfoData

class JVMCodeBuilder {
    val methodBuilder: JVMClass.MethodBuilder
    var maxLocals: Int = 0
    val code: DynamicBuffer = {
        val b = DynamicBuffer.empty()
        b.endian = Endian.big
        b
    }
    val exceptionTable: List[ExceptionTableEntry] = []
    val lineNumberTable: List[LineNumberTableEntry] = []
    val localVariableTable: List[LocalVariableTableEntry] = []

    def __get_cls(self): JVMClass = methodBuilder.cls

    def __get_cp(self): JVMClass.ConstantPool = cls.cp

    def markLine(self, lineNumber: Int) {
        if not (lineNumberTable and lineNumberTable.last().lineNumber == lineNumber) {
            lineNumberTable.add(LineNumberTableEntry(code.size(), lineNumber))
        }
    }

    private def computeMaxStackSize(self): Int {
        # val methodName = cp.getUtf8(methodBuilder.nameIndex)
        # IO.println("=== computeMaxStackSize " + cls.name + "." + methodName + " ===")
        var maxStack = 0
        val seen = Set[Int].empty()
        val todo = [(0, 0)]

        # also take into account all the places you can end up, due to
        # exceptions.
        for entry in exceptionTable {
            todo.add((entry.handlerPc, 1))
        }

        while todo {
            val (pc, stackSize) = todo.pop()
            if stackSize > maxStack {
                maxStack = stackSize
            }
            if stackSize < 0 {
                throw Error("stack underflow")
            }
            val opcode = code.getUint8(pc)
            val instructionSize = Opcode.instructionSize(code, pc)
            val nextPc = pc + instructionSize
            # IO.println("  pc=0x" + pc.hex() + "  opcode=0x" +
            # opcode.hex().lpad(2, "0") + " stack=" + stackSize)
            if pc in seen {
                # already handled
            } else {
                seen.add(pc)
                if val stackChange = Opcode.simpleStackChangeOpcodes.getOrNull(opcode) {
                    val newStackSize = stackSize + stackChange
                    todo.add((nextPc, newStackSize))
                } else if opcode in Opcode.terminalStackChangeOpcodes {
                    # nothing more to do -- these opcodes don't "continue"
                } else if opcode in Opcode.ifZeroCmp {
                    # these pop an int from the top of the stack, does a comparison
                    # and potentially branches
                    val newStackSize = stackSize - 1
                    todo.add((nextPc, newStackSize))
                    todo.add((pc + code.getInt16(pc + 1), newStackSize))
                } else if opcode in Opcode.ifICmp {
                    # these pop two ints from the stack, does a comparison
                    # and potentially branches
                    val newStackSize = stackSize - 2
                    todo.add((nextPc, newStackSize))
                    todo.add((pc + code.getInt16(pc + 1), newStackSize))
                } else {
                    switch opcode {
                        case Opcode.goto = {
                            # 0xa7
                            # unconditional branching
                            todo.add((pc + code.getInt16(pc + 1), stackSize))
                        }
                        case Opcode.getstatic = {
                            # 0xb2
                            val newStackSize = stackSize + slotSizeForType(
                                cp.getMemberDescriptor(code.getUint16(pc + 1)))
                            todo.add((nextPc, newStackSize))
                        }
                        case Opcode.putstatic = {
                            # 0xb3
                            val newStackSize = stackSize - slotSizeForType(
                                cp.getMemberDescriptor(code.getUint16(pc + 1)))
                            todo.add((nextPc, newStackSize))
                        }
                        case Opcode.getfield = {
                            # 0xb4
                            val newStackSize = stackSize - 1 + slotSizeForType(
                                cp.getMemberDescriptor(code.getUint16(pc + 1)))
                            todo.add((nextPc, newStackSize))
                        }
                        case Opcode.putfield = {
                            # 0xb5
                            val newStackSize = stackSize - 1 - slotSizeForType(
                                cp.getMemberDescriptor(code.getUint16(pc + 1)))
                            todo.add((nextPc, stackSize))
                        }
                        case Opcode.invokevirtual
                        case Opcode.invokespecial
                        case Opcode.invokeinterface = {
                            # 0xb6 invokevirtual
                            # 0xb7 invokespecial
                            # 0xb9 invokeinterface
                            val newStackSize = stackSize - 1 + slotChangeForFunction(
                                cp.getMemberDescriptor(code.getUint16(pc + 1)))
                            todo.add((nextPc, newStackSize))
                        }
                        case Opcode.invokestatic = {
                            # 0xb8
                            val newStackSize = stackSize + slotChangeForFunction(
                                cp.getMemberDescriptor(code.getUint16(pc + 1)))
                            todo.add((nextPc, newStackSize))
                        }
                        else = {
                            throw Error("TODO computeMaxStackSize 0x" + opcode.hex().lpad(2, "0"))
                        }
                    }
                }
            }
        }

        val missing = Set[Int].empty()
        for i = 0; i < code.size(); i += Opcode.instructionSize(code, i) {
            if i not in seen {
                missing.add(i)
            }
        }
        # if missing {
        #     val methodName = cp.getUtf8(methodBuilder.nameIndex)
        #     throw Error("unreachable code in " + cls.name + "." + methodName + " " + missing)
        # }

        maxStack
    }

    private def slotSizeForType(type: String): Int = switch type.charAt(0) {
        case 'V' = 0
        case 'J'
        case 'D' = 2
        case '(' = throw Error("Funciton descriptor provided to slotSizeForType " + type)
        else = 1
    }

    private def slotSizeForReturnType(descriptor: String): Int = slotSizeForType(
        descriptor[descriptor.indexOf(")") + 1:])

    private def slotChangeForFunction(descriptor: String): Int = (
        slotSizeForReturnType(descriptor) - computeArgumentSlotCount(descriptor))

    private def computeArgumentSlotCount(descriptor: String): Int {
        var argc = 0
        var i = 1
        while i < descriptor.size() and descriptor.charAt(i) != ')' {

            # long and double take 2 slots
            switch descriptor.charAt(i) {
                case 'D'
                case 'J' = { argc += 2 }
                else = { argc++ }
            }

            while descriptor.charAt(i) == '[' {
                i++
            }

            if descriptor.charAt(i) == 'L' {
                while i < descriptor.size() and descriptor.charAt(i) != ';' {
                    i += descriptor.charAt(i).size()
                }
            }

            if i >= descriptor.size() {
                throw Error("Bad descriptor " + descriptor)
            }

            i += descriptor.charAt(i).size()
        }
        argc
    }

    def build(self) : CodeAttribute {
        val cattr = CodeAttribute(computeMaxStackSize(), maxLocals, code, exceptionTable, [])
        if lineNumberTable {
            cattr.attributes.add(AttributeInfo(
                cls.cp.utf8("LineNumberTable"),
                AttributeInfoData.lineNumberTable(lineNumberTable)))
        }
        if localVariableTable {
            cattr.attributes.add(AttributeInfo(
                cls.cp.utf8("LocalVariableTable"),
                AttributeInfoData.localVariableTable(localVariableTable)))
        }
        cattr
    }

    ## Load a constant onto the stack given its index in the constant pool
    def _ldc(self, index: Int) {
        if index < 128 {
            code.addUint8(Opcode.ldc)
            code.addUint8(index)
        } else {
            code.addUint8(Opcode.ldc_w)
            code.addUint16(index)
        }
    }

    def _ldc2_w(self, index: Int) {
        code.addUint8(Opcode.ldc2_w)
        code.addUint16(index)
    }

    def new_(self, className: String) {
        val index = cp.classref(className)
        code.addUint8(Opcode.new_)
        code.addUint16(index)
    }

    def anewarray(self, className: String) {
        val index = cp.classref(className)
        code.addUint8(Opcode.anewarray)
        code.addUint16(index)
    }

    def newarray(self, typeName: String) {
        val typeCode = switch typeName {
            case "bool" = 4
            case "char" = 5
            case "float" = 6
            case "double" = 7
            case "byte" = 8
            case "short" = 9
            case "int" = 10
            case "long" = 11
            else = throw Error("Invalid newarray type name: " + typeName)
        }
        code.addUint8(Opcode.newarray)
        code.addUint8(typeCode)
    }

    def getstatic(self, className: String, fieldName: String, type: String) {
        val index = cls.cp.fieldref(className, fieldName, type)
        code.addUint8(Opcode.getstatic)
        code.addUint16(index)
    }

    def putstatic(self, className: String, fieldName: String, type: String) {
        val index = cls.cp.fieldref(className, fieldName, type)
        code.addUint8(Opcode.putstatic)
        code.addUint16(index)
    }

    def getfield(self, className: String, fieldName: String, type: String) {
        val index = cls.cp.fieldref(className, fieldName, type)
        code.addUint8(Opcode.getfield)
        code.addUint16(index)
    }

    def putfield(self, className: String, fieldName: String, type: String) {
        val index = cls.cp.fieldref(className, fieldName, type)
        code.addUint8(Opcode.putfield)
        code.addUint16(index)
    }

    def invokevirtual(self, className: String, methodName: String, type: String) {
        val index = cls.cp.methodref(className, methodName, type)
        code.addUint8(Opcode.invokevirtual)
        code.addUint16(index)
    }

    def invokespecial(self, className: String, methodName: String, type: String) {
        val index = cls.cp.methodref(className, methodName, type)
        code.addUint8(Opcode.invokespecial)
        code.addUint16(index)
    }

    def invokeinterface(self, interfaceName: String, methodName: String, type: String) {
        val index = cls.cp.interfaceMethodref(interfaceName, methodName, type)
        val argc = 1 + computeArgumentSlotCount(type)
        code.addUint8(Opcode.invokeinterface)
        code.addUint16(index)
        code.addUint8(argc)
        code.addUint8(0)
    }

    def invokestatic(self, className: String, methodName: String, type: String) {
        val index = cls.cp.methodref(className, methodName, type)
        code.addUint8(Opcode.invokestatic)
        code.addUint16(index)
    }

    ## Load an immediate constant value onto the stack
    def ldc(self, cv: JVMConstValue) {
        when cv {
            case int(i) = switch i {
                case -1 = code.addUint8(Opcode.iconst_m1)
                case 0 = code.addUint8(Opcode.iconst_0)
                case 1 = code.addUint8(Opcode.iconst_1)
                case 2 = code.addUint8(Opcode.iconst_2)
                case 3 = code.addUint8(Opcode.iconst_3)
                case 4 = code.addUint8(Opcode.iconst_4)
                case 5 = code.addUint8(Opcode.iconst_5)
                else = _ldc(cls.cp.integer(i))
            }
            case long(i) = switch i.toInt() {
                case 0 = code.addUint8(Opcode.lconst_0)
                case 1 = code.addUint8(Opcode.lconst_1)
                else = _ldc2_w(cls.cp.long(i))
            }
            case float(f) = if f == 0 {
                    code.addUint8(Opcode.fconst_0)
                } else if f == 1 {
                    code.addUint8(Opcode.fconst_1)
                } else if f == 2 {
                    code.addUint8(Opcode.fconst_2)
                } else {
                    _ldc(cls.cp.float(f))
                }
            case double(f) = if f == 0 {
                    code.addUint8(Opcode.dconst_0)
                } else if f == 1 {
                    code.addUint8(Opcode.dconst_1)
                } else {
                    _ldc2_w(cls.cp.double(f))
                }
            case string(s) = _ldc(cls.cp.string(s))
        }
    }

    def bipush(self, byte: Int) {
        code.addUint8(Opcode.bipush)
        code.addInt8(byte)
    }

    def sipush(self, value: Int) {
        code.addUint8(Opcode.sipush)
        code.addInt16(value)
    }

    def checkcast(self, className: String) {
        val index = cp.classref(className)
        code.addUint8(Opcode.checkcast)
        code.addUint16(index)
    }

    # ======================================================
    # variable load/store opcodes
    # ======================================================

    def iinc(self, index: Int, incr: Int) {
        Assert.that(index < 128)
        Assert.that(incr >= -128 and incr < 128)
        code.addUint8(Opcode.iinc)
        code.addUint8(index)
        code.addInt8(incr)
    }

    ## load int from a local variable
    def iload(self, index: Int) = _localvarOp(
        index, Opcode.iload_0, Opcode.iload_1, Opcode.iload_2, Opcode.iload_3, Opcode.iload)

    ## load long from a local variable
    def lload(self, index: Int) = _localvarOp(
        index, Opcode.lload_0, Opcode.lload_1, Opcode.lload_2, Opcode.lload_3, Opcode.lload)

    ## load float from a local variable
    def fload(self, index: Int) = _localvarOp(
        index, Opcode.fload_0, Opcode.fload_1, Opcode.fload_2, Opcode.fload_3, Opcode.fload)

    ## load double from a local variable
    def dload(self, index: Int) = _localvarOp(
        index, Opcode.dload_0, Opcode.dload_1, Opcode.dload_2, Opcode.dload_3, Opcode.dload)

    ## load a reference from a local variable
    def aload(self, index: Int) = _localvarOp(
        index, Opcode.aload_0, Opcode.aload_1, Opcode.aload_2, Opcode.aload_3, Opcode.aload)

    ## store int to a local variable
    def istore(self, index: Int) = _localvarOp(
        index, Opcode.istore_0, Opcode.istore_1, Opcode.istore_2, Opcode.istore_3, Opcode.istore)

    ## store long to a local variable
    def lstore(self, index: Int) = _localvarOp(
        index, Opcode.lstore_0, Opcode.lstore_1, Opcode.lstore_2, Opcode.lstore_3, Opcode.lstore)

    ## store float to a local variable
    def fstore(self, index: Int) = _localvarOp(
        index, Opcode.fstore_0, Opcode.fstore_1, Opcode.fstore_2, Opcode.fstore_3, Opcode.fstore)

    ## store double to a local variable
    def dstore(self, index: Int) = _localvarOp(
        index, Opcode.dstore_0, Opcode.dstore_1, Opcode.dstore_2, Opcode.dstore_3, Opcode.dstore)

    ## store a reference to a local variable
    def astore(self, index: Int) = _localvarOp(
        index, Opcode.astore_0, Opcode.astore_1, Opcode.astore_2, Opcode.astore_3, Opcode.astore)

    private def _localvarOp(self, index: Int, op0: Int, op1: Int, op2: Int, op3: Int, op: Int) {
        switch index {
            case 0 = code.addUint8(op0)
            case 1 = code.addUint8(op1)
            case 2 = code.addUint8(op2)
            case 3 = code.addUint8(op3)
            else = if index < 128 {
                code.addUint8(op)
                code.addUint8(index)
            } else {
                code.addUint8(Opcode.wide)
                code.addUint8(op)
                code.addUint16(index)
            }
        }
    }

    # ======================================================
    # one u16 branch argument opcodes
    # ======================================================

    def ifeq(self, offset: Int) {
        code.addUint8(Opcode.ifeq)
        code.addUint16(offset)
    }

    def ifne(self, offset: Int) {
        code.addUint8(Opcode.ifne)
        code.addUint16(offset)
    }

    def iflt(self, offset: Int) {
        code.addUint8(Opcode.iflt)
        code.addUint16(offset)
    }

    def ifge(self, offset: Int) {
        code.addUint8(Opcode.ifge)
        code.addUint16(offset)
    }

    def ifgt(self, offset: Int) {
        code.addUint8(Opcode.ifgt)
        code.addUint16(offset)
    }

    def ifle(self, offset: Int) {
        code.addUint8(Opcode.ifle)
        code.addUint16(offset)
    }

    def if_icmpeq(self, offset: Int) {
        code.addUint8(Opcode.if_icmpeq)
        code.addUint16(offset)
    }

    def if_icmpne(self, offset: Int) {
        code.addUint8(Opcode.if_icmpne)
        code.addUint16(offset)
    }

    def if_icmplt(self, offset: Int) {
        code.addUint8(Opcode.if_icmplt)
        code.addUint16(offset)
    }

    def if_icmpge(self, offset: Int) {
        code.addUint8(Opcode.if_icmpge)
        code.addUint16(offset)
    }

    def if_icmpgt(self, offset: Int) {
        code.addUint8(Opcode.if_icmpgt)
        code.addUint16(offset)
    }

    def if_icmple(self, offset: Int) {
        code.addUint8(Opcode.if_icmple)
        code.addUint16(offset)
    }

    def if_acmpeq(self, offset: Int) {
        code.addUint8(Opcode.if_acmpeq)
        code.addUint16(offset)
    }

    def if_acmpne(self, offset: Int) {
        code.addUint8(Opcode.if_acmpne)
        code.addUint16(offset)
    }

    def goto(self, offset: Int) {
        code.addUint8(Opcode.goto)
        code.addUint16(offset)
    }

    def jsr(self, offset: Int) {
        code.addUint8(Opcode.jsr)
        code.addUint16(offset)
    }

    def ifnull(self, offset: Int) {
        code.addUint8(Opcode.ifnull)
        code.addUint16(offset)
    }

    def ifnonnull(self, offset: Int) {
        code.addUint8(Opcode.ifnonnull)
        code.addUint16(offset)
    }

    # ======================================================
    # zero argument opcodes
    # ======================================================

    def nop(self) {
        code.addUint8(Opcode.nop)
    }

    def iconst_0(self) {
        code.addUint8(Opcode.iconst_0)
    }

    def iconst_1(self) {
        code.addUint8(Opcode.iconst_1)
    }

    def lconst_0(self) {
        code.addUint8(Opcode.lconst_0)
    }

    def fconst_0(self) {
        code.addUint8(Opcode.fconst_0)
    }

    def dconst_0(self) {
        code.addUint8(Opcode.dconst_0)
    }

    def aconst_null(self) {
        code.addUint8(Opcode.aconst_null)
    }

    def iaload(self) {
        code.addUint8(Opcode.iaload)
    }

    def laload(self) {
        code.addUint8(Opcode.laload)
    }

    def faload(self) {
        code.addUint8(Opcode.faload)
    }

    def daload(self) {
        code.addUint8(Opcode.daload)
    }

    def aaload(self) {
        code.addUint8(Opcode.aaload)
    }

    def baload(self) {
        code.addUint8(Opcode.baload)
    }

    def caload(self) {
        code.addUint8(Opcode.caload)
    }

    def saload(self) {
        code.addUint8(Opcode.saload)
    }

    def iastore(self) {
        code.addUint8(Opcode.iastore)
    }

    def lastore(self) {
        code.addUint8(Opcode.lastore)
    }

    def fastore(self) {
        code.addUint8(Opcode.fastore)
    }

    def dastore(self) {
        code.addUint8(Opcode.dastore)
    }

    def aastore(self) {
        code.addUint8(Opcode.aastore)
    }

    def bastore(self) {
        code.addUint8(Opcode.bastore)
    }

    def castore(self) {
        code.addUint8(Opcode.castore)
    }

    def sastore(self) {
        code.addUint8(Opcode.sastore)
    }

    def pop(self) {
        code.addUint8(Opcode.pop)
    }

    def pop2(self) {
        code.addUint8(Opcode.pop2)
    }

    def dup(self) {
        code.addUint8(Opcode.dup)
    }

    def dup_x1(self) {
        code.addUint8(Opcode.dup_x1)
    }

    def dup_x2(self) {
        code.addUint8(Opcode.dup_x2)
    }

    def dup2(self) {
        code.addUint8(Opcode.dup2)
    }

    def dup2_x1(self) {
        code.addUint8(Opcode.dup2_x1)
    }

    def dup2_x2(self) {
        code.addUint8(Opcode.dup2_x2)
    }

    def swap(self) {
        code.addUint8(Opcode.swap)
    }

    def iadd(self) {
        code.addUint8(Opcode.iadd)
    }

    def ladd(self) {
        code.addUint8(Opcode.ladd)
    }

    def fadd(self) {
        code.addUint8(Opcode.fadd)
    }

    def dadd(self) {
        code.addUint8(Opcode.dadd)
    }

    def isub(self) {
        code.addUint8(Opcode.isub)
    }

    def lsub(self) {
        code.addUint8(Opcode.lsub)
    }

    def fsub(self) {
        code.addUint8(Opcode.fsub)
    }

    def dsub(self) {
        code.addUint8(Opcode.dsub)
    }

    def imul(self) {
        code.addUint8(Opcode.imul)
    }

    def lmul(self) {
        code.addUint8(Opcode.lmul)
    }

    def fmul(self) {
        code.addUint8(Opcode.fmul)
    }

    def dmul(self) {
        code.addUint8(Opcode.dmul)
    }

    def idiv(self) {
        code.addUint8(Opcode.idiv)
    }

    def ldiv(self) {
        code.addUint8(Opcode.ldiv)
    }

    def fdiv(self) {
        code.addUint8(Opcode.fdiv)
    }

    def ddiv(self) {
        code.addUint8(Opcode.ddiv)
    }

    def irem(self) {
        code.addUint8(Opcode.irem)
    }

    def lrem(self) {
        code.addUint8(Opcode.lrem)
    }

    def frem(self) {
        code.addUint8(Opcode.frem)
    }

    def drem(self) {
        code.addUint8(Opcode.drem)
    }

    def ineg(self) {
        code.addUint8(Opcode.ineg)
    }

    def lneg(self) {
        code.addUint8(Opcode.lneg)
    }

    def fneg(self) {
        code.addUint8(Opcode.fneg)
    }

    def dneg(self) {
        code.addUint8(Opcode.dneg)
    }

    def ishl(self) {
        code.addUint8(Opcode.ishl)
    }

    def lshl(self) {
        code.addUint8(Opcode.lshl)
    }

    def ishr(self) {
        code.addUint8(Opcode.ishr)
    }

    def lshr(self) {
        code.addUint8(Opcode.lshr)
    }

    def iushr(self) {
        code.addUint8(Opcode.iushr)
    }

    def lushr(self) {
        code.addUint8(Opcode.lushr)
    }

    def iand(self) {
        code.addUint8(Opcode.iand)
    }

    def land(self) {
        code.addUint8(Opcode.land)
    }

    def ior(self) {
        code.addUint8(Opcode.ior)
    }

    def lor(self) {
        code.addUint8(Opcode.lor)
    }

    def ixor(self) {
        code.addUint8(Opcode.ixor)
    }

    def lxor(self) {
        code.addUint8(Opcode.lxor)
    }

    def i2l(self) {
        code.addUint8(Opcode.i2l)
    }

    def i2f(self) {
        code.addUint8(Opcode.i2f)
    }

    def i2d(self) {
        code.addUint8(Opcode.i2d)
    }

    def l2i(self) {
        code.addUint8(Opcode.l2i)
    }

    def l2f(self) {
        code.addUint8(Opcode.l2f)
    }

    def l2d(self) {
        code.addUint8(Opcode.l2d)
    }

    def f2i(self) {
        code.addUint8(Opcode.f2i)
    }

    def f2l(self) {
        code.addUint8(Opcode.f2l)
    }

    def f2d(self) {
        code.addUint8(Opcode.f2d)
    }

    def d2i(self) {
        code.addUint8(Opcode.d2i)
    }

    def d2l(self) {
        code.addUint8(Opcode.d2l)
    }

    def d2f(self) {
        code.addUint8(Opcode.d2f)
    }

    def i2b(self) {
        code.addUint8(Opcode.i2b)
    }

    def i2c(self) {
        code.addUint8(Opcode.i2c)
    }

    def i2s(self) {
        code.addUint8(Opcode.i2s)
    }

    def lcmp(self) {
        code.addUint8(Opcode.lcmp)
    }

    def fcmpl(self) {
        code.addUint8(Opcode.fcmpl)
    }

    def fcmpg(self) {
        code.addUint8(Opcode.fcmpg)
    }

    def dcmpl(self) {
        code.addUint8(Opcode.dcmpl)
    }

    def dcmpg(self) {
        code.addUint8(Opcode.dcmpg)
    }

    def ireturn(self) {
        code.addUint8(Opcode.ireturn)
    }

    def lreturn(self) {
        code.addUint8(Opcode.lreturn)
    }

    def freturn(self) {
        code.addUint8(Opcode.freturn)
    }

    def dreturn(self) {
        code.addUint8(Opcode.dreturn)
    }

    def areturn(self) {
        code.addUint8(Opcode.areturn)
    }

    def return_(self) {
        code.addUint8(Opcode.return_)
    }

    def arraylength(self) {
        code.addUint8(Opcode.arraylength)
    }

    def athrow(self) {
        code.addUint8(Opcode.athrow)
    }

    def monitorenter(self) {
        code.addUint8(Opcode.monitorenter)
    }

    def monitorexit(self) {
        code.addUint8(Opcode.monitorexit)
    }

    def breakpoint(self) {
        code.addUint8(Opcode.breakpoint)
    }

    def impdep1(self) {
        code.addUint8(Opcode.impdep1)
    }

    def impdep2(self) {
        code.addUint8(Opcode.impdep2)
    }
}
