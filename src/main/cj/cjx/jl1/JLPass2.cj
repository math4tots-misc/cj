package cjx.jl1

import cjx.jl1.JLContext
import cjx.jl1.JLAstLocal
import cjx.jl1.JLAstType
import cjx.jl1.JLAstMethod
import cjx.jl1.JLAstExpr
import cjx.jl1.JLAstTemplateParameter
import cjx.jl1.JLIRExpressionSolver
import cjx.jl1.JLIRMethod
import cjx.jl1.JLIRLocal
import cjx.jl1.JLIRField
import cj.Error
import cjx.jl1.JLAstFile
import cjx.jl1.JLIRLocalContext
import cj.StringBuilder
import cjx.jl1.JLIRTemplateArgument
import cjx.jl1.JLAstClass
import cjx.jl1.JLError
import cjx.jl1.JLMark
import cjx.jl1.JLType
import cjx.jl1.JLIRClass

@derive(new)
class JLPass2 {
    val ctx: JLContext

    def run(self, ircls: JLIRClass) {
        val lctx = JLIRLocalContext(ctx, ctx.typeMapMap[ircls.id], ircls.name, "")
        val astcls = ctx.astClassMap[ircls.id]
        val thisType = JLType.klass(ircls)

        addSynthesizedInit(astcls)
        addSynthesizedClinit(astcls)

        for astMember in astcls.members {
            when astMember {
                case klass(innercls) = ()
                case field(astField) = {
                    val fieldtype = if null(ftype) = astField.type {
                        ftype
                    } else if null(init) = astField.init {
                        if null(ftype) = simpleInferExpressionType(init) {
                            ftype
                        } else {
                            throw JLError("Could not infer field type", [astField.mark])
                        }
                    } else {
                        throw JLError("Field type is not specified", [astField.mark])
                    }
                    val irField = JLIRField(
                        astField.mark,
                        astField.comment,
                        astField.modifiers,
                        astField.name,
                        lctx.solveFieldType(fieldtype))
                    ircls.addField(irField)
                }
                case method(astMethod) = {
                    val parameters: List[JLIRLocal] = []
                    for astLocal in astMethod.parameters {
                        Assert.that(astLocal.init.isEmpty())
                        val irLocal = JLIRLocal(
                            astLocal.mark,
                            parameters.size(),
                            astLocal.modifiers,
                            astLocal.name,
                            if astLocal.name == "this" {
                                Assert.that(astLocal.type.isEmpty())
                                thisType
                            } else {
                                lctx.solveFieldType(astLocal.type.get())
                            })
                        parameters.add(irLocal)
                    }
                    val irMethod = JLIRMethod(
                        astMethod.mark,
                        astMethod.comment,
                        astMethod.modifiers,
                        astMethod.name,
                        parameters,
                        lctx.solveType(astMethod.returnType),
                        parameters.clone())
                    ircls.addMethod(irMethod)
                }
            }
        }
    }

    private def simpleInferExpressionType(self, expr: JLAstExpr): Nullable[JLAstType] {
        val nullableData = when expr.data {
            case int(i) = null(JLAstType.Data.int())
            case string(s) = null(JLAstType.Data.klass("java.lang.String", []))
            else = null
        }
        if null(data) = nullableData {
            null(JLAstType(expr.mark, data))
        } else {
            null
        }
    }

    private def addSynthesizedInit(self, astcls: JLAstClass) {
        if astcls.isInterface() {
            # Interfaces don't have <init> methods
            return ()
        }

        val mark = astcls.mark
        val parameters = [JLAstLocal(mark, [], "this", null, null)]
        val bodyexprs = [
            # start by calling the super constructor
            JLAstExpr(mark, JLAstExpr.Data.calljava(
                "special",
                JLAstType(mark, JLAstType.Data.void()),
                "java/lang/Object", "<init>", "()V", [JLAstExpr(mark, JLAstExpr.Data.this())],
            )),
        ]
        for field in astcls.fields.filter(f -> not f.isStatic()) {
            bodyexprs.add(JLAstExpr(mark, JLAstExpr.Data.initfield(
                field.name,
                if field.init.isPresent() {
                    field.init.get()
                } else {
                    if field.type.isEmpty() {
                        throw JLError(
                            "A field without an initializer must provide a type", [field.mark])
                    }
                    val fieldtype = field.type.get()
                    val parameterName = "p$" + field.name
                    parameters.add(JLAstLocal(mark, [], parameterName, null(fieldtype), null))
                    JLAstExpr(mark, JLAstExpr.Data.getvar(parameterName))
                }
            )))
        }
        val body = JLAstExpr(mark, JLAstExpr.Data.block(bodyexprs))
        astcls.members.add(JLAstClass.Member.method(JLAstMethod(
            mark,
            null,
            ["private"],
            "<init>",
            parameters,
            JLAstType(mark, JLAstType.Data.void()),
            null(body))))
    }

    private def addSynthesizedClinit(self, astcls: JLAstClass) {
        val mark = astcls.mark
        val parameters: List[JLAstLocal] = []
        val bodyexprs: List[JLAstExpr] = []
        for field in astcls.fields.filter(f -> f.isStatic()) {
            bodyexprs.add(JLAstExpr(mark, JLAstExpr.Data.initfield(
                field.name,
                if field.init.isPresent() {
                    field.init.get()
                } else {
                    if field.type.isEmpty() {
                        throw JLError(
                            "A field without an initializer must provide a type", [field.mark])
                    }
                    val fieldtype = field.type.get()
                    val parameterName = "p$" + field.name
                    parameters.add(JLAstLocal(mark, [], parameterName, null(fieldtype), null))
                    JLAstExpr(mark, JLAstExpr.Data.getvar(parameterName))
                }
            )))
        }
        val body = JLAstExpr(mark, JLAstExpr.Data.block(bodyexprs))
        astcls.members.add(JLAstClass.Member.method(JLAstMethod(
            mark,
            null,
            [],
            "<clinit>",
            parameters,
            JLAstType(mark, JLAstType.Data.void()),
            null(body))))
    }
}
