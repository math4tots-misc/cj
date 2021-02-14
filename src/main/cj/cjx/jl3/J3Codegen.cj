package cjx.jl3

import cjx.jvm.JVMConstValue
import cjx.jvm.JVMCodeBuilder
import cjx.jl3.J3Expr
import cjx.jl3.J3Type
import cj.FS
import cjx.jvm.JVMClass
import cjx.jl3.J3Class

@derive(new)
class J3Codegen {
    static val sep: String = "/"
    val outdir: String

    def emitClass(self, ircls: J3Class) {
        val jvmcls = JVMClass()
        jvmcls.thisClass = jvmcls.cp.classref(jvmName(ircls))
        jvmcls.superClass = jvmcls.cp.classref(if null(scls) = ircls.superClass {
            jvmName(scls) } else { "java/lang/Object" })
        jvmcls.attributes.add(JVMClass.AttributeInfo(
            jvmcls.cp.utf8("SourceFile"),
            JVMClass.AttributeInfoData.sourceFile(
                JVMClass.SourceFileAttribute(
                    jvmcls.cp.utf8(ircls.mark.filename)))))
        for irfield in ircls.fields {
            jvmcls.addField(jvmfield -> {
                for modifier in irfield.modifiers {
                    var accessFlags = JVMClass.cACC_PUBLIC
                    var mutable = false
                    switch modifier {
                        case "static" = { accessFlags = accessFlags | JVMClass.cACC_STATIC }
                        case "var" = { mutable = true }
                        else = ()
                    }
                    if not mutable {
                        accessFlags = accessFlags | JVMClass.cACC_FINAL
                    }
                    jvmfield.accessFlags = accessFlags
                    jvmfield.name = irfield.name
                    jvmfield.descriptor = jvmType(irfield.type)
                }
            })
        }
        for irmethod in ircls.methods {
            jvmcls.addMethod(jvmmethod -> {
                for modifier in irmethod.modifiers {
                    var accessFlags = JVMClass.cACC_PUBLIC
                    switch modifier {
                        case "static" = { accessFlags = accessFlags | JVMClass.cACC_STATIC }
                        else = ()
                    }
                    jvmmethod.accessFlags = accessFlags
                    jvmmethod.name = irmethod.name
                    jvmmethod.descriptor = jvmType(irmethod.returnType)
                    if null(body) = irmethod.body {
                        jvmmethod.addCode(jvmcode -> {
                            val egen = ExprGen(jvmcode)
                            egen.top(body)
                        })
                    }
                }
            })
        }
        FS.writeFileBytes(
            ircls.name.replace(".", sep) + ".class",
            jvmcls.toBuffer())
    }

    def jvmName(cls: J3Class): String = cls.name.replace(".", "/")
    def jvmType(t: J3Type): String = when t {
        case noreturn = "V"
        case void = "V"
        case bool = "Z"
        case int = "I"
        case double = "D"
        case klass(cls) = "L" + jvmName(cls) + ";"
    }

    @derive(new)
    class ExprGen {
        val jvmcode: JVMCodeBuilder

        def top(self, expr: J3Expr) {
            emit(expr)
            if not expr.terminatesFlow {
                when expr.type {
                    case noreturn = ()
                    case void = jvmcode.return_()
                    case bool = jvmcode.ireturn()
                    case int = jvmcode.ireturn()
                    case double = jvmcode.dreturn()
                    case klass(cls) = jvmcode.areturn()
                }
            }
        }

        def emit(self, expr: J3Expr) {
            when expr.data {
                case int(i) = jvmcode.ldc(JVMConstValue.int(i))
            }
        }
    }
}
