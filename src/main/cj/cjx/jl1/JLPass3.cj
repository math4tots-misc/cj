package cjx.jl1

import cjx.jl1.JLContext
import cjx.jl1.JLToken
import cjx.jl1.JLIRMethodRef
import cjx.jl1.JLPass2
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
class JLPass3 {
    val ctx: JLContext

    def run(self, ircls: JLIRClass) {
        val lctx = JLIRLocalContext(ctx, ctx.typeMapMap[ircls.id], ircls.name, "")
        val astcls = ctx.astClassMap[ircls.id]
        val thisType = JLType.klass(ircls)
        for astMember in lctx.listMembers(ircls) {
            when astMember {
                case field(astField) = ()
                case method(astMethod) = {
                    if not astMethod.templateParameters and astMethod.body.isPresent() {
                        val irMethod = ircls.getDeclaredMethod(astMethod.mark, astMethod.name)
                        val astBody = astMethod.body.get()
                        val mlctx = JLIRLocalContext(
                            lctx.ctx,
                            lctx.typeMap,
                            lctx.className,
                            astMethod.name)
                        val esolver = JLIRExpressionSolver(mlctx)
                        val irBody = esolver.solveExpression(
                            astBody, null(irMethod.returnType))
                        irMethod.body = null(irBody)
                    }
                }
            }
        }
    }
}
