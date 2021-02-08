package cjx.jl1

import cj.FS
import cjx.jvm.JVMConstValue
import cj.Error
import cjx.jl1.JLIRLocal
import cjx.jvm.JVMCodeBuilder
import cjx.jl1.JLIRExpr
import cjx.jl1.JLIRMethod
import cjx.jvm.JVMClass
import cjx.jl1.JLIRClass
import cjx.jl1.JLContext

## jl1 code generator
@derive(new)
class JLCodegen {
    val ctx: JLContext
    val outdir: String

    def emit(self) {
        for className in ctx.classMap.keys() {
            val cls = ctx.classMap[className]
            if not cls.isNative() {
                val jvmcls = emitClass(cls)
                val relpath = cls.name.replace(".", "/") + ".class"
                val outpath = outdir + "/" + relpath
                val jvmbuffer = jvmcls.toBuffer()
                FS.writeFileBytes(outpath, jvmbuffer)
            }
        }
    }

    def emitClass(self, cls: JLIRClass): JVMClass {
        val jvmcls = JVMClass()
        jvmcls.thisClass = jvmcls.cp.classref(cls.toJVMName())
        jvmcls.superClass = jvmcls.cp.classref("java/lang/Object")
        jvmcls.attributes.add(JVMClass.AttributeInfo(
            jvmcls.cp.utf8("SourceFile"),
            JVMClass.AttributeInfoData.sourceFile(
                JVMClass.SourceFileAttribute(
                    jvmcls.cp.utf8(cls.mark.filename)))))

        for jlfield in cls.fields {
            jvmcls.addField(jvmfield -> {
                jvmfield.accessFlags = JVMClass.cACC_PUBLIC
                if jlfield.isStatic() {
                    jvmfield.accessFlags = jvmfield.accessFlags | JVMClass.cACC_STATIC
                }
                jvmfield.name = jlfield.name
                jvmfield.descriptor = jlfield.type.toJVMString()
            })
        }

        for jlmethod in cls.methods {
            jvmcls.addMethod(jvmmethod -> {
                jvmmethod.accessFlags = JVMClass.cACC_PUBLIC
                if jlmethod.isStatic() {
                    jvmmethod.accessFlags = jvmmethod.accessFlags | JVMClass.cACC_STATIC
                }
                jvmmethod.name = jlmethod.name
                jvmmethod.descriptor = jlmethod.getJVMDescriptor()

                if null(body) = jlmethod.body {
                    jvmmethod.addCode(jvmcode -> {
                        val exprgen = ExprGen(
                            ctx,
                            jvmcls,
                            jvmmethod,
                            jlmethod,
                            jvmcode)
                        exprgen.top(body)
                        jvmcode.maxStack = exprgen.maxStack
                        jvmcode.maxLocals = exprgen.maxLocals
                    })
                }
            })
        }

        jvmcls
    }

    ## Expression code generator
    @derive(new)
    class ExprGen {
        val ctx: JLContext
        val jvmcls: JVMClass
        val jvmmethod: JVMClass.MethodBuilder
        val jlmethod: JLIRMethod
        val jvmcode: JVMCodeBuilder

        ## Maps local variable ids to their JVM local variable slot
        val localMap: Map[Int, Int] = Map()
        var localSize: Int = 0
        var maxLocals: Int = 0 # TODO: compare with JVMCodeBuilder's inferred maxLocals

        var stackSize: Int = 0
        var maxStack: Int = 0

        def stackIncr(self, diff: Int) {
            stackSize = stackSize + diff
            if stackSize > maxStack {
                maxStack = stackSize
            }
        }

        def addLocal(self, localvar: JLIRLocal) {
            Assert.that(localvar.id not in localMap)
            val slot = localSize
            localSize = localSize + localvar.type.getJVMSlotSize()
            if localSize > maxLocals {
                maxLocals = localSize
            }
            localMap[localvar.id] = slot
        }

        ## Emit an expression from the top of the method
        def top(self, expr: JLIRExpr) {
            for parameter in jlmethod.parameters {
                addLocal(parameter)
            }
            emit(expr)
            when jlmethod.returnType {
                case void = jvmcode.return_()
                case bool = jvmcode.ireturn()
                case byte = jvmcode.ireturn()
                case char = jvmcode.ireturn()
                case short = jvmcode.ireturn()
                case int = jvmcode.ireturn()
                case long = jvmcode.lreturn()
                case float = jvmcode.freturn()
                case double = jvmcode.dreturn()
                case array(inner) = jvmcode.areturn()
                case klass(cls) = jvmcode.areturn()
            }
        }

        def emit(self, expr: JLIRExpr) {
            when expr.data {
                case bool(b) = {
                    stackIncr(expr.type.getJVMSlotSize())
                    jvmcode.bipush(if b { 1 } else { 0 })
                }
                case int(i) = {
                    stackIncr(expr.type.getJVMSlotSize())
                    jvmcode.ldc(JVMConstValue.int(i))
                }
                case long(i) = {
                    stackIncr(expr.type.getJVMSlotSize())
                    jvmcode.ldc(JVMConstValue.long(i))
                }
                case float(f) = {
                    stackIncr(expr.type.getJVMSlotSize())
                    jvmcode.ldc(JVMConstValue.float(f))
                }
                case double(f) = {
                    stackIncr(expr.type.getJVMSlotSize())
                    jvmcode.ldc(JVMConstValue.double(f))
                }
                case string(s) = {
                    stackIncr(expr.type.getJVMSlotSize())
                    jvmcode.ldc(JVMConstValue.string(s))
                }
                case block(subexprs) = {
                    for subexpr in subexprs {
                        emit(subexpr)
                    }
                }
                case call(methodref, args) = {
                    for arg in args {
                        emit(arg)
                    }

                    for arg in args {
                        stackIncr(-arg.type.getJVMSlotSize())
                    }
                    stackIncr(expr.type.getJVMSlotSize())

                    jvmcode.markLine(expr.mark.line)
                    if methodref.method.isStatic() {
                        jvmcode.invokestatic(
                            methodref.owner.toJVMName(),
                            methodref.method.name,
                            methodref.method.getJVMDescriptor())
                    } else if methodref.owner.isInterface() {
                        jvmcode.invokeinterface(
                            methodref.owner.toJVMName(),
                            methodref.method.name,
                            methodref.method.getJVMDescriptor())
                    } else {
                        jvmcode.invokevirtual(
                            methodref.owner.toJVMName(),
                            methodref.method.name,
                            methodref.method.getJVMDescriptor())
                    }
                }
                case getstatic(fieldref) = {
                    stackIncr(expr.type.getJVMSlotSize())
                    jvmcode.getstatic(
                        fieldref.owner.toJVMName(),
                        fieldref.field.name,
                        fieldref.field.type.toJVMString())
                }
                else = throw Error("TODO")
            }
        }
    }
}
