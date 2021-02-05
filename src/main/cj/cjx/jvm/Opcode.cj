package cjx.jvm


## Information about various opcodes
class Opcode {
    static val iload = 0x15
    static val lload = 0x16
    static val fload = 0x17
    static val dload = 0x18
    static val aload = 0x19
    static val istore = 0x36
    static val lstore = 0x37
    static val fstore = 0x38
    static val dstore = 0x39
    static val astore = 0x3a
    static val ret = 0xa9
    static val ldc = 0x12
    static val ldc_w = 0x13
    static val ldc2_w = 0x14
    static val getstatic = 0xb2
    static val putstatic = 0xb3
    static val getfield = 0xb4
    static val putfield = 0xb5
    static val invokevirtual = 0xb6
    static val invokespecial = 0xb7
    static val invokestatic = 0xb8
    static val new_ = 0xbb
    static val anewarray = 0xbd
    static val checkcast = 0xc0
    static val instanceof = 0xc1
    static val ifeq = 0x99
    static val ifne = 0x9a
    static val iflt = 0x9b
    static val ifge = 0x9c
    static val ifgt = 0x9d
    static val ifle = 0x9e
    static val if_icmpeq = 0x9f
    static val if_icmpne = 0xa0
    static val if_icmplt = 0xa1
    static val if_icmpge = 0xa2
    static val if_icmpgt = 0xa3
    static val if_icmple = 0xa4
    static val if_acmpeq = 0xa5
    static val if_acmpne = 0xa6
    static val goto = 0xa7
    static val jsr = 0xa8
    static val ifnull = 0xc6
    static val ifnonnull = 0xc7
    static val nop = 0x00
    static val aconst_null = 0x01
    static val iconst_m1 = 0x02
    static val iconst_0 = 0x03
    static val iconst_1 = 0x04
    static val iconst_2 = 0x05
    static val iconst_3 = 0x06
    static val iconst_4 = 0x07
    static val iconst_5 = 0x08
    static val lconst_0 = 0x09
    static val lconst_1 = 0x0a
    static val fconst_0 = 0x0b
    static val fconst_1 = 0x0c
    static val fconst_2 = 0x0d
    static val dconst_0 = 0x0e
    static val dconst_1 = 0x0f
    static val iload_0 = 0x1a
    static val iload_1 = 0x1b
    static val iload_2 = 0x1c
    static val iload_3 = 0x1d
    static val lload_0 = 0x1e
    static val lload_1 = 0x1f
    static val lload_2 = 0x20
    static val lload_3 = 0x21
    static val fload_0 = 0x22
    static val fload_1 = 0x23
    static val fload_2 = 0x24
    static val fload_3 = 0x25
    static val dload_0 = 0x26
    static val dload_1 = 0x27
    static val dload_2 = 0x28
    static val dload_3 = 0x29
    static val aload_0 = 0x2a
    static val aload_1 = 0x2b
    static val aload_2 = 0x2c
    static val aload_3 = 0x2d
    static val iaload = 0x2e
    static val laload = 0x2f
    static val faload = 0x30
    static val daload = 0x31
    static val aaload = 0x32
    static val baload = 0x33
    static val caload = 0x34
    static val saload = 0x35
    static val istore_0 = 0x3b
    static val istore_1 = 0x3c
    static val istore_2 = 0x3d
    static val istore_3 = 0x3e
    static val lstore_0 = 0x3f
    static val lstore_1 = 0x40
    static val lstore_2 = 0x41
    static val lstore_3 = 0x42
    static val fstore_0 = 0x43
    static val fstore_1 = 0x44
    static val fstore_2 = 0x45
    static val fstore_3 = 0x46
    static val dstore_0 = 0x47
    static val dstore_1 = 0x48
    static val dstore_2 = 0x49
    static val dstore_3 = 0x4a
    static val astore_0 = 0x4b
    static val astore_1 = 0x4c
    static val astore_2 = 0x4d
    static val astore_3 = 0x4e
    static val iastore = 0x4f
    static val lastore = 0x50
    static val fastore = 0x51
    static val dastore = 0x52
    static val aastore = 0x53
    static val bastore = 0x54
    static val castore = 0x55
    static val sastore = 0x56
    static val pop = 0x57
    static val pop2 = 0x58
    static val dup = 0x59
    static val dup_x1 = 0x5a
    static val dup_x2 = 0x5b
    static val dup2 = 0x5c
    static val dup2_x1 = 0x5d
    static val dup2_x2 = 0x5e
    static val swap = 0x5f
    static val iadd = 0x60
    static val ladd = 0x61
    static val fadd = 0x62
    static val dadd = 0x63
    static val isub = 0x64
    static val lsub = 0x65
    static val fsub = 0x66
    static val dsub = 0x67
    static val imul = 0x68
    static val lmul = 0x69
    static val fmul = 0x6a
    static val dmul = 0x6b
    static val idiv = 0x6c
    static val ldiv = 0x6d
    static val fdiv = 0x6e
    static val ddiv = 0x6f
    static val irem = 0x70
    static val lrem = 0x71
    static val frem = 0x72
    static val drem = 0x73
    static val ineg = 0x74
    static val lneg = 0x75
    static val fneg = 0x76
    static val dneg = 0x77
    static val ishl = 0x78
    static val lshl = 0x79
    static val ishr = 0x7a
    static val lshr = 0x7b
    static val iushr = 0x7c
    static val lushr = 0x7d
    static val iand = 0x7e
    static val land = 0x7f
    static val ior = 0x80
    static val lor = 0x81
    static val ixor = 0x82
    static val lxor = 0x83
    static val i2l = 0x85
    static val i2f = 0x86
    static val i2d = 0x87
    static val l2i = 0x88
    static val l2f = 0x89
    static val l2d = 0x8a
    static val f2i = 0x8b
    static val f2l = 0x8c
    static val f2d = 0x8d
    static val d2i = 0x8e
    static val d2l = 0x8f
    static val d2f = 0x90
    static val i2b = 0x91
    static val i2c = 0x92
    static val i2s = 0x93
    static val lcmp = 0x94
    static val fcmpl = 0x95
    static val fcmpg = 0x96
    static val dcmpl = 0x97
    static val dcmpg = 0x98
    static val ireturn = 0xac
    static val lreturn = 0xad
    static val freturn = 0xae
    static val dreturn = 0xaf
    static val areturn = 0xb0
    static val return_ = 0xb1
    static val arraylength = 0xbe
    static val athrow = 0xbf
    static val monitorenter = 0xc2
    static val monitorexit = 0xc3
    static val breakpoint = 0xca
    static val impdep1 = 0xfe
    static val impdep2 = 0xff

    ## Opcodes with one 8-bit local variable argument
    static val oneU8LocalArgOpcode: Map[Int, String] = Map(
        0x15: "iload",
        0x16: "lload",
        0x17: "fload",
        0x18: "dload",
        0x19: "aload",
        0x36: "istore",
        0x37: "lstore",
        0x38: "fstore",
        0x39: "dstore",
        0x3a: "astore",
        0xa9: "ret",
    )

    ## Opcodes with one 16-bit index argument to entry in the constant pool
    static val oneU16ConstArgOpcode: Map[Int, String] = Map(
        0x13: "ldc_w",
        0x14: "ldc2_w",
        0xb2: "getstatic",
        0xb3: "putstatic",
        0xb4: "getfield",
        0xb5: "putfield",
        0xb6: "invokevirtual",
        0xb7: "invokespecial",
        0xb8: "invokestatic",
        0xbb: "new",
        0xbd: "anewarray",
        0xc0: "checkcast",
        0xc1: "instanceof",
    )

    ## Opcodes with one 16-bit branch offset argument
    static val oneU16BranchArgOpcode: Map[Int, String] = Map(
        0x99: "ifeq",
        0x9a: "ifne",
        0x9b: "iflt",
        0x9c: "ifge",
        0x9d: "ifgt",
        0x9e: "ifle",
        0x9f: "if_icmpeq",
        0xa0: "if_icmpne",
        0xa1: "if_icmplt",
        0xa2: "if_icmpge",
        0xa3: "if_icmpgt",
        0xa4: "if_icmple",
        0xa5: "if_acmpeq",
        0xa6: "if_acmpne",
        0xa7: "goto",
        0xa8: "jsr",
        0xc6: "ifnull",
        0xc7: "ifnonnull",
    )

    ## Opcodes with no arguments
    static val zeroArgOpcodes: Map[Int, String] = Map(
        0x00: "nop",
        0x01: "aconst_null",
        0x02: "iconst_m1",
        0x03: "iconst_0",
        0x04: "iconst_1",
        0x05: "iconst_2",
        0x06: "iconst_3",
        0x07: "iconst_4",
        0x08: "iconst_5",
        0x09: "lconst_0",
        0x0a: "lconst_1",
        0x0b: "fconst_0",
        0x0c: "fconst_1",
        0x0d: "fconst_2",
        0x0e: "dconst_0",
        0x0f: "dconst_1",
        0x1a: "iload_0",
        0x1b: "iload_1",
        0x1c: "iload_2",
        0x1d: "iload_3",
        0x1e: "lload_0",
        0x1f: "lload_1",
        0x20: "lload_2",
        0x21: "lload_3",
        0x22: "fload_0",
        0x23: "fload_1",
        0x24: "fload_2",
        0x25: "fload_3",
        0x26: "dload_0",
        0x27: "dload_1",
        0x28: "dload_2",
        0x29: "dload_3",
        0x2a: "aload_0",
        0x2b: "aload_1",
        0x2c: "aload_2",
        0x2d: "aload_3",
        0x2e: "iaload",
        0x2f: "laload",
        0x30: "faload",
        0x31: "daload",
        0x32: "aaload",
        0x33: "baload",
        0x34: "caload",
        0x35: "saload",
        0x3b: "istore_0",
        0x3c: "istore_1",
        0x3d: "istore_2",
        0x3e: "istore_3",
        0x3f: "lstore_0",
        0x40: "lstore_1",
        0x41: "lstore_2",
        0x42: "lstore_3",
        0x43: "fstore_0",
        0x44: "fstore_1",
        0x45: "fstore_2",
        0x46: "fstore_3",
        0x47: "dstore_0",
        0x48: "dstore_1",
        0x49: "dstore_2",
        0x4a: "dstore_3",
        0x4b: "astore_0",
        0x4c: "astore_1",
        0x4d: "astore_2",
        0x4e: "astore_3",
        0x4f: "iastore",
        0x50: "lastore",
        0x51: "fastore",
        0x52: "dastore",
        0x53: "aastore",
        0x54: "bastore",
        0x55: "castore",
        0x56: "sastore",
        0x57: "pop",
        0x58: "pop2",
        0x59: "dup",
        0x5a: "dup_x1",
        0x5b: "dup_x2",
        0x5c: "dup2",
        0x5d: "dup2_x1",
        0x5e: "dup2_x2",
        0x5f: "swap",
        0x60: "iadd",
        0x61: "ladd",
        0x62: "fadd",
        0x63: "dadd",
        0x64: "isub",
        0x65: "lsub",
        0x66: "fsub",
        0x67: "dsub",
        0x68: "imul",
        0x69: "lmul",
        0x6a: "fmul",
        0x6b: "dmul",
        0x6c: "idiv",
        0x6d: "ldiv",
        0x6e: "fdiv",
        0x6f: "ddiv",
        0x70: "irem",
        0x71: "lrem",
        0x72: "frem",
        0x73: "drem",
        0x74: "ineg",
        0x75: "lneg",
        0x76: "fneg",
        0x77: "dneg",
        0x78: "ishl",
        0x79: "lshl",
        0x7a: "ishr",
        0x7b: "lshr",
        0x7c: "iushr",
        0x7d: "lushr",
        0x7e: "iand",
        0x7f: "land",
        0x80: "ior",
        0x81: "lor",
        0x82: "ixor",
        0x83: "lxor",
        0x85: "i2l",
        0x86: "i2f",
        0x87: "i2d",
        0x88: "l2i",
        0x89: "l2f",
        0x8a: "l2d",
        0x8b: "f2i",
        0x8c: "f2l",
        0x8d: "f2d",
        0x8e: "d2i",
        0x8f: "d2l",
        0x90: "d2f",
        0x91: "i2b",
        0x92: "i2c",
        0x93: "i2s",
        0x94: "lcmp",
        0x95: "fcmpl",
        0x96: "fcmpg",
        0x97: "dcmpl",
        0x98: "dcmpg",
        0xac: "ireturn",
        0xad: "lreturn",
        0xae: "freturn",
        0xaf: "dreturn",
        0xb0: "areturn",
        0xb1: "return",
        0xbe: "arraylength",
        0xbf: "athrow",
        0xc2: "monitorenter",
        0xc3: "monitorexit",
        0xca: "breakpoint",
        0xfe: "impdep1",
        0xff: "impdep2",
    )
}
