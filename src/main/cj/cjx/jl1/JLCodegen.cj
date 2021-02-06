package cjx.jl1

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
                emitClass(cls)
            }
        }
    }

    def emitClass(self, cls: JLIRClass): JVMClass {
        val jvmcls = JVMClass()
        jvmcls.thisClass = jvmcls.cp.classref(cls.toJVMName())
        jvmcls.superClass = jvmcls.cp.classref("java/lang/Object")

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
                    jvmmethod.addCode(jvmcode ->
                        ExprGen(ctx, jvmcls, jvmmethod, jlmethod, jvmcode).top(body))
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

        ## Emit an expression from the top of the method
        def top(self, expr: JLIRExpr) {
        }
    }
}
