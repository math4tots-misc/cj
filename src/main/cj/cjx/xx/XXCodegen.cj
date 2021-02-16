package cjx.xx

import cj.StringBuilder
import cjx.xx.llir.XXLLIRMethod
import cjx.jvm.JVMConstValue
import cjx.xx.llir.XXLLIRType
import cjx.xx.llir.XXLLIRLocals
import cjx.xx.llir.XXLLIRExpr
import cjx.jvm.JVMCodeBuilder
import cj.FS
import cjx.jvm.JVMClass
import cjx.xx.llir.XXLLIRClass

@derive(new)
class XXCodegen {
    static val sep = "/"
    val outdir: String

    def emitClass(self, cls: XXLLIRClass) {
        if cls.isNative() {
            return ()
        }

        val jvmcls = JVMClass()
        jvmcls.thisClass = jvmcls.cp.classref(toJVMClassName(cls.name))
        jvmcls.superClass = jvmcls.cp.classref(toJVMClassName(cls.superClass))
        jvmcls.attributes.add(JVMClass.AttributeInfo(
            jvmcls.cp.utf8("SourceFile"),
            JVMClass.AttributeInfoData.sourceFile(
                JVMClass.SourceFileAttribute(
                    jvmcls.cp.utf8(cls.mark.filename)))))

        for field in cls.fields {
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

        for method in cls.methods {
            jvmcls.addMethod(jvmmethod -> {
                jvmmethod.accessFlags = JVMClass.cACC_PUBLIC
                if method.isStatic() {
                    jvmmethod.accessFlags = jvmmethod.accessFlags | JVMClass.cACC_STATIC
                }
                if method.body.isEmpty() {
                    jvmmethod.accessFlags = jvmmethod.accessFlags | JVMClass.cACC_ABSTRACT
                }
                jvmmethod.name = method.name
                jvmmethod.descriptor = toJVMMethodType2(method)

                if null(body) = method.body {
                    jvmmethod.addCode(jvmcode -> {
                        val exprgen = ExprGen(
                            jvmcode,
                            method.locals)
                        if not method.isStatic() {
                            Assert.equal(method.locals.list[0].name, "this")
                            exprgen.declare(0)
                        }
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

    def toJVMClassName(className: String): String {
        className.replace(".", "/")
    }

    def toJVMType(type: XXLLIRType): String = when type {
        case noreturn = "V"
        case void = "V"
        case bool = "Z"
        case int = "I"
        case double = "D"
        case klass(clsname) = "L" + toJVMClassName(clsname) + ";"
    }

    def toJVMMethodType(parameterTypes: List[XXLLIRType], returnType: XXLLIRType): String {
        val sb = StringBuilder()
        sb.add("(")
        for parameterType in parameterTypes {
            sb.add(toJVMType(parameterType))
        }
        sb.add(")")
        sb.add(toJVMType(returnType))
        sb.toString()
    }

    def toJVMMethodType2(method: XXLLIRMethod): String {
        toJVMMethodType(
            method.parameters.map(p -> method.locals.list[p].type),
            method.returnType)
    }

    @derive(new)
    class ExprGen {
        val jvmcode: JVMCodeBuilder
        val locals: XXLLIRLocals
        var maxLocals = 0
        var localsSize = 0
        val localsSizeStack: List[Int] = []

        def pushScope(self) {
            localsSizeStack.add(localsSize)
        }

        def popScope(self) {
            localsSize = localsSizeStack.pop()
        }

        def declare(self, localsIndex: Int) {
            val slotSize = slotSizeOfType(locals.list[localsIndex].type)
            localsSize = localsSize + slotSize
            if localsSize > maxLocals {
                maxLocals = localsSize
            }
        }

        def top(self, expr: XXLLIRExpr) {
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

        def emit(self, expr: XXLLIRExpr) {
            when expr.data {
                case int(i) = jvmcode.ldc(JVMConstValue.int(i))
                case block(subexprs) = {
                    pushScope()
                    for subexpr in subexprs {
                        emit(subexpr)
                    }
                    popScope()
                }
            }
        }

        def slotSizeOfType(type: XXLLIRType): Int = when type {
            case noreturn = 0
            case void = 0
            case bool = 1
            case int = 1
            case double = 2
            case klass(cls) = 1
        }
    }
}
