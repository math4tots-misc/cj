package cjx.ez

import cj.StringBuilder
import cj.FS
import cjx.jvm.JVMCodeBuilder
import cjx.ez.EZError
import cjx.jvm.JVMConstValue
import cjx.jvm.JVMClass
import cjx.ez.EZIR

class EZCodegen {
    static val sep = "/"
    val outdir: String

    def emitClass(self, cls: EZIR.Class) {
        if cls.isNative() {
            return ()
        }

        val jvmcls = JVMClass()
        jvmcls.thisClass = jvmcls.cp.classref(toJVMClassName(cls.name))
        jvmcls.superClass = jvmcls.cp.classref("java/lang/Object")
        jvmcls.attributes.add(JVMClass.AttributeInfo(
            jvmcls.cp.utf8("SourceFile"),
            JVMClass.AttributeInfoData.sourceFile(
                JVMClass.SourceFileAttribute(
                    jvmcls.cp.utf8(cls.mark.filename)))))

        for field in cls._fields {
            jvmcls.addField(jvmfield -> {
                jvmfield.accessFlags = JVMClass.cACC_PUBLIC
                if field.isStatic() {
                    jvmfield.accessFlags = jvmfield.accessFlags | JVMClass.cACC_STATIC
                }
                if not field.isMutable() {
                    jvmfield.accessFlags = jvmfield.accessFlags | JVMClass.cACC_FINAL
                }
                jvmfield.name = field.name
                jvmfield.descriptor = toJVMType(field.type)
            })
        }

        for method in cls._methods {
            jvmcls.addMethod(jvmmethod -> {
                jvmmethod.accessFlags = JVMClass.cACC_PUBLIC | JVMClass.cACC_STATIC
                jvmmethod.name = method.name
                jvmmethod.descriptor = toJVMMethodType2(method)
                if val body = method.body {
                    jvmmethod.addCode(jvmcode -> {
                        val exprgen = ExprGen(jvmcode)
                        for parameter in method.parameters {
                            exprgen.declare(parameter)
                        }
                        exprgen.top(body)
                        jvmcode.maxLocals = exprgen.maxLocals
                    })
                }
            })
        }

        val relpath = cls.name.replace(".", sep) + ".class"
        val outpath = outdir + sep + relpath
        val jvmbuffer = jvmcls.toBuffer()
        FS.writeFileBytes(outpath, jvmbuffer)
    }

    def toJVMMethodType(parameterTypes: List[EZIR.Type], returnType: EZIR.Type): String {
        val sb = StringBuilder()
        sb.add("(")
        for parameterType in parameterTypes {
            sb.add(toJVMType(parameterType))
        }
        sb.add(")")
        sb.add(toJVMType(returnType))
        sb.toString()
    }

    def toJVMMethodType2(method: EZIR.Method): String {
        toJVMMethodType(
            method.parameters.map(p -> p.type),
            method.returnType)
    }

    def toJVMMethodType3(methodType: EZIR.MethodType): String {
        toJVMMethodType(
            methodType.parameterTypes,
            methodType.returnType)
    }

    def toJVMClassName(className: String): String {
        className.replace(".", "/")
    }

    def toJVMClassName2(type: EZIR.Type): String {
        when type {
            case klass(clsname) = switch clsname {
                case "jl1.NoReturn"
                case "jl1.Unit"
                case "jl1.Bool"
                case "jl1.Int"
                case "jl1.Double" = throw EZError(clsname + " is a primitive type", [])
                else = toJVMClassName(clsname)
            }
        }
    }

    def toJVMType(type: EZIR.Type): String = when type {
        case klass(clsname) = switch clsname {
            case "jl1.NoReturn" = "V"
            case "jl1.Unit" = "I"
            case "jl1.Bool" = "Z"
            case "jl1.Int" = "I"
            case "jl1.Double" = "D"
            else = "L" + toJVMClassName(clsname) + ";"
        }
    }

    class ExprGen {
        val jvmcode: JVMCodeBuilder
        var maxLocals = 0
        var localsSize = 0
        val localsSizeStack: List[Int] = []

        def pushScope(self) {
            localsSizeStack.add(localsSize)
        }

        def popScope(self) {
            localsSize = localsSizeStack.pop()
        }

        def declare(self, local: EZIR.Local) {
            val slotSize = slotSizeOfType(local.type)
            localsSize = localsSize + slotSize
            if localsSize > maxLocals {
                maxLocals = localsSize
            }
        }

        def top(self, expr: EZIR.Expr) {
            emit(expr)
            if not expr.terminatesFlow {
                when expr.type {
                    case klass(clsname) = switch clsname {
                        case "jl1.NoReturn" = ()
                        case "jl1.Unit"
                        case "jl1.Bool"
                        case "jl1.Int" = jvmcode.ireturn()
                        case "jl1.Long" = jvmcode.lreturn()
                        case "jl1.Double" = jvmcode.dreturn()
                        else = jvmcode.areturn()
                    }
                }
            }
        }

        def emit(self, expr: EZIR.Expr) {
            when expr.data {
                case unit() = jvmcode.ldc(JVMConstValue.int(1))
                case int(i) = jvmcode.ldc(JVMConstValue.int(i))
                case string(s) = jvmcode.ldc(JVMConstValue.string(s))
                case block(subexprs) = {
                    pushScope()
                    for subexpr in subexprs {
                        emit(subexpr)
                    }
                    popScope()
                }
                case call(ownerType, methodName, methodType, args) = {
                    for arg in args {
                        emit(arg)
                    }
                    val key = "" + ownerType + "." + methodName
                    switch key {
                        else = jvmcode.invokestatic(
                            EZCodegen.toJVMClassName2(ownerType),
                            methodName,
                            EZCodegen.toJVMMethodType3(methodType))
                    }
                }
                case java(op) = when op {
                    case getstatic(clsname, fieldName, descriptor) = (
                        jvmcode.getstatic(clsname, fieldName, descriptor))
                    case callinstance(clsname, methodName, descriptor, args) = {
                        for arg in args {
                            emit(arg)
                        }
                        jvmcode.invokevirtual(clsname, methodName, descriptor)
                    }
                }
            }
        }

        def slotSizeOfType(type: EZIR.Type): Int = when type {
            case klass(clsname) = switch clsname {
                case "jl1.NoReturn" = 0
                case "jl1.Double"
                case "jl1.Long" = 2
                else = 1
            }
        }
    }
}
